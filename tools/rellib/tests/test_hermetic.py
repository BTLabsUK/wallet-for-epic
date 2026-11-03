# SPDX-License-Identifier: Apache-2.0
"""The hermetic services a trust lane reads (drivers/core/hermetic.py): a node and relay offered only
after a recent passing health check and only on loopback; the hosts a lane still touched outside."""
import json
import os
import sys
import tempfile
import unittest

import support  # noqa: F401

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "drivers"))

from core import hermetic  # noqa: E402

NODE = {"url": "http://127.0.0.1:43413", "height": 3782025, "public": 3782026}


class Services(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, d):
        with open(os.path.join(self.dir, "status.json"), "w") as f:
            f.write(d if isinstance(d, str) else json.dumps(d))

    def test_both_healthy(self):
        self.write({"node": NODE, "relay": "127.0.0.1:43423", "updated": 1000})
        self.assertEqual(hermetic.services(self.dir, now=1060),
                         {"node": "http://127.0.0.1:43413", "relay": "127.0.0.1:43423"})

    def test_failed_check_is_none(self):
        self.write({"node": None, "relay": "127.0.0.1:43423", "updated": 1000})
        self.assertEqual(hermetic.services(self.dir, now=1000), {"node": None, "relay": "127.0.0.1:43423"})

    def test_stale_status_is_none(self):
        self.write({"node": NODE, "relay": "127.0.0.1:43423", "updated": 1000})
        self.assertEqual(hermetic.services(self.dir, now=1000 + hermetic.MAX_AGE + 1),
                         {"node": None, "relay": None})

    def test_missing_or_broken_status_is_none(self):
        self.assertEqual(hermetic.services(self.dir), {"node": None, "relay": None})
        self.write("{not json")
        self.assertEqual(hermetic.services(self.dir), {"node": None, "relay": None})
        self.write([1, 2])
        self.assertEqual(hermetic.services(self.dir), {"node": None, "relay": None})
        self.write({"node": NODE, "relay": "127.0.0.1:43423"})  # no updated
        self.assertEqual(hermetic.services(self.dir), {"node": None, "relay": None})

    def test_remote_service_is_never_offered(self):
        self.write({"node": {"url": "https://node.btlabs.uk"}, "relay": "epicbox.example:443", "updated": 1000})
        self.assertEqual(hermetic.services(self.dir, now=1000), {"node": None, "relay": None})

    def test_root_from_environment(self):
        self.write({"node": NODE, "relay": None, "updated": 1000})
        old = os.environ.get("REL_HERMETIC_ROOT")
        os.environ["REL_HERMETIC_ROOT"] = self.dir
        try:
            self.assertEqual(hermetic.services(now=1000)["node"], "http://127.0.0.1:43413")
        finally:
            if old is None:
                del os.environ["REL_HERMETIC_ROOT"]
            else:
                os.environ["REL_HERMETIC_ROOT"] = old


class NonLocal(unittest.TestCase):
    def test_keeps_only_remote_hosts_once(self):
        self.assertEqual(hermetic.non_local([
            "http://127.0.0.1:43413", "127.0.0.1:43423", "localhost", "[::1]:3413", "http://[::1]:1/x",
            "127.8.9.10", "https://node.btlabs.uk/v2/foreign", "epicbox.stackwallet.com:443",
            "NODE.btlabs.uk", "10.0.2.2:43423", "", None,
        ]), ["node.btlabs.uk", "epicbox.stackwallet.com", "10.0.2.2"])

    def test_all_local_is_empty(self):
        self.assertEqual(hermetic.non_local(["127.0.0.1", "localhost:1", "http://localhost:43413"]), [])


if __name__ == "__main__":
    unittest.main()
