# SPDX-License-Identifier: Apache-2.0
"""Runs that never publish (--test, tainted) sign their manifests with the test key and check them
against the run's test keyring; a release run uses the real keyring."""
import types
import unittest

import support  # noqa: F401  (puts tools/ on sys.path)
from rellib import builtins, guards
from rellib.engine import Engine
from rellib.graph import Step


def engine(info):
    info = {"run_id": "run-2", "version": "26.11.2", "commit": "c", **info}
    run = types.SimpleNamespace(path="/r", files="/r/files", extra="/r/extra", info=info, step_dir=lambda s: "/r/" + s)
    return types.SimpleNamespace(run=run, info=info, dry=True, hosts={"host": {"signer": {"btlabs_public": "/bp"}}},
                                 pipeline=types.SimpleNamespace(proof={}, manifest_days=lambda: 1))


class TestKeyTest(unittest.TestCase):
    step = Step(id="manifests", base="manifests", kind="command", title="", host="local", lane="l", platforms=[])

    def test_release_run_uses_the_real_keyring(self):
        eng = engine({})
        self.assertFalse(guards.test_key(eng.info))
        env = Engine.base_env(eng, self.step)
        self.assertEqual((env["REL_TEST"], env["REL_TEST_KEY"]), ("0", "0"))
        self.assertEqual(builtins.keyring_for(eng)[0], "/bp/keys/btlabs-keyring.json")

    def test_tainted_run_signs_with_the_test_key_but_stays_a_release_run(self):
        eng = engine({"tainted": [{"at": "t", "reason": "trust-linux-tor ran with unmet needs"}]})
        env = Engine.base_env(eng, self.step)
        self.assertEqual((env["REL_TEST"], env["REL_TEST_KEY"], env["REL_RUN_KIND"]), ("0", "1", "release"))
        self.assertEqual(builtins.keyring_for(eng)[0], "/r/manifests/test-keyring.json")

    def test_test_run_signs_with_the_test_key(self):
        eng = engine({"test": True})
        env = Engine.base_env(eng, self.step)
        self.assertEqual((env["REL_TEST"], env["REL_TEST_KEY"]), ("1", "1"))
        self.assertEqual(builtins.keyring_for(eng)[0], "/r/manifests/test-keyring.json")


if __name__ == "__main__":
    unittest.main()
