# SPDX-License-Identifier: Apache-2.0
"""A version in .tool-pins.toml runs on its own checkout of tools/rel."""
import json
import os
import tempfile
import unittest

from rellib import pin


class ToolPin(unittest.TestCase):
    def setUp(self):
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        self.root = d.name
        for v, n in (("26.11.4", "run-6"), ("26.11.5", "run-1")):
            os.makedirs(os.path.join(self.root, v, n))
            with open(os.path.join(self.root, v, n, "run.json"), "w") as f:
                json.dump({"run_id": f"{v}-{n}"}, f)
        os.utime(os.path.join(self.root, "26.11.5/run-1/run.json"), (1, 1))
        with open(os.path.join(self.root, ".tool-pins.toml"), "w") as f:
            f.write('"26.11.4" = "/pinned"\n')

    def target(self, *argv):
        return pin.target(["--state-root", self.root, *argv])

    def test_a_named_run_follows_its_pin(self):
        for ref in (f"{self.root}/26.11.4/run-6", "26.11.4-run6", "26.11.4"):
            self.assertEqual(self.target("publish", "--run", ref), "/pinned/tools/rel")

    def test_another_version_stays(self):
        self.assertIsNone(self.target("publish", "--run", "26.11.5"))
        self.assertIsNone(self.target("start", "--version", "26.11.5"))

    def test_no_run_means_the_newest(self):
        self.assertEqual(self.target("resume"), "/pinned/tools/rel")
        os.utime(os.path.join(self.root, "26.11.5/run-1/run.json"))
        os.utime(os.path.join(self.root, "26.11.4/run-6/run.json"), (1, 1))
        self.assertIsNone(self.target("resume"))

    def test_no_pins_file(self):
        os.remove(os.path.join(self.root, ".tool-pins.toml"))
        self.assertIsNone(self.target("publish", "--run", "26.11.4"))


if __name__ == "__main__":
    unittest.main()
