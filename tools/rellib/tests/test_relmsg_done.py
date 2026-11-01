# SPDX-License-Identifier: Apache-2.0
"""The relay release has one life per run: opened with the run id, ended once (ok, failed or
aborted) on every path that ends the run, never on a path that only waits."""
import argparse
import json
import os
import signal
import unittest
from contextlib import redirect_stdout
from io import StringIO

from support import Base
from rellib import cli
from rellib.cli import App, Interrupted
from rellib.relmsg import Relmsg
from rellib.run import Run, write_json


class DyingEngine:
    """An engine whose drive is stopped by a signal."""

    def __init__(self, relmsg, signum=signal.SIGTERM):
        self.relmsg, self.signum = relmsg, signum

    def drive(self, sel):
        raise Interrupted(self.signum)

    def input_hash(self, step):
        return ""


class RelmsgDoneTest(Base):
    def app(self):
        app = App.__new__(App)
        app.args = argparse.Namespace(json=False)
        app.state_root = self.root
        app.pipeline = self.pipeline
        return app

    def dones(self):
        return [l for l in self.relmsg_calls().splitlines() if " done " in f" {l} "]

    def test_start_carries_the_run_id_and_a_second_start_reuses_the_release(self):
        run = self.make_run()
        rm = Relmsg(run, {"bin": self.fake})
        rm.start(["scope"], [])
        rm.start(["scope"], [])
        starts = [l for l in self.relmsg_calls().splitlines() if l.split()[1:2] == ["start"] or " start " in f" {l}"]
        self.assertEqual(len(starts), 1)
        self.assertIn(f"--run-id {run.info['run_id']}", starts[0])
        again = Relmsg(Run(run.path), {"bin": self.fake})  # a resume: a new process reads run.json
        self.assertEqual(again.start(["scope"], []), 7)
        self.assertEqual(len([l for l in self.relmsg_calls().splitlines() if " start " in f" {l}"]), 1)

    def test_done_is_once_and_persisted(self):
        run = self.make_run()
        rm = Relmsg(run, {"bin": self.fake})
        rm.start(["scope"], [])
        self.assertTrue(rm.done("ok"))
        self.assertFalse(rm.done("aborted"))
        self.assertFalse(Relmsg(Run(run.path), {"bin": self.fake}).done("failed"))
        self.assertEqual(len(self.dones()), 1)
        self.assertEqual(Run(run.path).info["relmsg"]["ended"], "ok")

    def test_done_not_recorded_when_the_relay_is_down_so_the_next_exit_asks_again(self):
        run = self.make_run()
        rm = Relmsg(run, {"bin": self.fake})
        rm.start(["scope"], [])
        os.environ["REL_FAKE_DOWN"] = "1"
        self.assertFalse(rm.done("aborted"))
        self.assertIsNone(rm.ended)
        del os.environ["REL_FAKE_DOWN"]
        self.assertTrue(rm.done("aborted"))

    def test_no_release_no_done(self):
        run = self.make_run()
        self.assertFalse(Relmsg(run, {"bin": self.fake}).done("ok"))
        self.assertEqual(self.dones(), [])

    def test_new_run_of_the_version_aborts_the_older_ones(self):
        old = self.make_run()
        Relmsg(old, {"bin": self.fake}).start(["scope"], [])
        pub = self.make_run()
        Relmsg(pub, {"bin": self.fake}).start(["scope"], [])
        write_json(os.path.join(self.root, "published.json"), [{"run_id": pub.info["run_id"], "version": "26.10.25"}])
        ended = self.make_run()
        rm = Relmsg(ended, {"bin": self.fake})
        rm.start(["scope"], [])
        rm.done("ok")
        before = len(self.dones())
        new = self.make_run()
        app = self.app()
        app.supersede(new)
        app.supersede(new)
        self.assertEqual(len(self.dones()) - before, 1)  # the old run only, once; published and ended stay
        self.assertIn(f"done aborted --note superseded by {new.info['run_id']}", self.dones()[-1])
        self.assertEqual(Run(old.path).info["relmsg"]["ended"], "aborted")
        self.assertNotIn("ended", Run(pub.path).info["relmsg"])
        self.assertNotIn("ended", new.info.get("relmsg", {}))

    def test_other_version_is_not_superseded(self):
        other = self.make_run("26.10.24")
        Relmsg(other, {"bin": self.fake}).start(["scope"], [])
        self.app().supersede(self.make_run("26.10.25"))
        self.assertEqual(self.dones(), [])

    def test_killed_while_driving_ends_aborted_and_releases_the_lock(self):
        for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
            run = self.make_run()
            rm = Relmsg(run, {"bin": self.fake})
            rm.start(["scope"], [])
            with self.assertRaises(Interrupted):
                self.app().drive(run, DyingEngine(rm, sig), "build")
            self.assertEqual(Run(run.path).info["relmsg"]["ended"], "aborted")
            self.assertIn(f"stopped by {sig.name}", self.dones()[-1])
            run.lock()  # free again
            run.unlock()
        self.assertEqual(len(self.dones()), 3)

    def test_main_turns_a_signal_into_128_plus_n_and_restores_the_handlers(self):
        before = signal.getsignal(signal.SIGTERM)
        orig = App.cmd_status
        App.cmd_status = lambda self, a: os.kill(os.getpid(), signal.SIGTERM)
        try:
            with redirect_stdout(StringIO()):
                code = cli.main(["--state-root", self.root, "status"])
        finally:
            App.cmd_status = orig
        self.assertEqual(code, 128 + signal.SIGTERM)
        self.assertEqual(signal.getsignal(signal.SIGTERM), before)

    def finished(self, code, run=None):
        run = run or self.make_run()
        rm = Relmsg(run, {"bin": self.fake})
        rm.start(["scope"], [])
        eng = self.engine(run)
        eng.relmsg = rm
        eng.relmsg.run = run
        app = self.app()
        with redirect_stdout(StringIO()):
            app.finish(run, eng, code)
        return run

    def test_exit_codes_that_end_the_run_and_those_that_do_not(self):
        for code, ends in ((0, False), (10, False), (20, False), (30, True), (40, False), (64, False), (75, False)):
            with self.subTest(code=code):
                os.remove(os.path.join(self.tmp, "relmsg.calls")) if os.path.exists(os.path.join(self.tmp, "relmsg.calls")) else None
                self.finished(code)
                self.assertEqual(len(self.dones()), 1 if ends else 0)
                if ends:
                    self.assertIn("done failed", self.dones()[0])

    def test_resume_of_a_run_that_ended_failed_may_end_again_but_aborted_stays_ended(self):
        run = self.finished(30)
        rm = Relmsg(Run(run.path), {"bin": self.fake})
        self.assertEqual(rm.ended, "failed")
        rm.reopen()
        self.assertIsNone(rm.ended)
        self.assertTrue(rm.done("ok"))
        rm.reopen()
        self.assertEqual(rm.ended, "ok")


if __name__ == "__main__":
    unittest.main()
