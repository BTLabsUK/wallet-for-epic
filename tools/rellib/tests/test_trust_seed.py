# SPDX-License-Identifier: Apache-2.0
"""The update-trust seed (drivers/seed.py) changes only the seeded values, in the release's own format."""
import glob
import json
import os
import shutil
import sqlite3
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRIVERS)

import seed  # noqa: E402


class SeedTest(unittest.TestCase):
    def test_desk_settings_of_each_fixture(self):
        fixtures = sorted(glob.glob(os.path.join(DRIVERS, "fixtures", "desk-settings-*.json")))
        self.assertTrue(fixtures)
        for path in fixtures:
            with self.subTest(os.path.basename(path)):
                text = open(path).read().strip()
                out = seed.desk_settings(text, "light", True)
                # nothing to change gives back the release's own text, byte for byte
                tech = "technicalDetails" in json.loads(text)["advanced"]["features"]
                self.assertEqual(seed.desk_settings(text, json.loads(text)["theme"], tech), text)
                before, after = json.loads(text), json.loads(out)
                self.assertEqual(after["theme"], "light")
                self.assertEqual(after["advanced"]["features"].count("technicalDetails"), 1)
                self.assertEqual(list(after), list(before))
                for k in before:
                    if k not in ("theme", "advanced"):
                        self.assertEqual(after[k], before[k], k)
                self.assertEqual({k: v for k, v in after["advanced"].items() if k != "features"},
                                 {k: v for k, v in before["advanced"].items() if k != "features"})
                again = json.loads(seed.desk_settings(out, "light", False))
                self.assertNotIn("technicalDetails", again["advanced"]["features"])

    def test_fresh_file_over_the_fixture(self):
        path, v = seed.fixture_for("26.10.23")
        self.assertEqual(v, "26.10.23")
        self.assertEqual(seed.fixture_for("26.10.24-r2")[1], "26.10.24")  # its own, from the release's deskSettingsToJson
        self.assertEqual(seed.fixture_for("26.10.23.1")[1], "26.10.23")
        self.assertIsNone(seed.fixture_for("26.9.1"))
        template = open(path).read().strip()
        out = json.loads(seed.desk_settings('{"tourSeen":false,"advanced":{"nodeFailover":false}}', "dark", True, template))
        self.assertEqual(list(out), list(json.loads(template)))
        self.assertEqual((out["theme"], out["tourSeen"], out["advanced"]["nodeFailover"]), ("dark", False, False))
        self.assertEqual(out["advanced"]["features"], ["technicalDetails"])
        with self.assertRaises(seed.SeedError):
            seed.desk_settings('{"tourSeen":true}', "light", True)

    def test_unknown_format_is_refused(self):
        for bad in ("[]", "{}", '{"theme": "dark"}', '{"theme": "dark", "advanced": {}}', "not json"):
            with self.assertRaises(seed.SeedError):
                seed.desk_settings(bad, "light", True)
        with self.assertRaises(seed.SeedError):
            seed.desk_wallet('{"created": 1}', "x")
        with self.assertRaises(seed.SeedError):
            seed.wallets_json('{"wallets": [{"id": "a", "label": "A"}]}', "b", "x")

    def test_label_files(self):
        w = seed.wallets_json('{\n  "version": 1,\n  "wallets": [\n    {\n      "id": "a",\n      "label": "Wallet 1"\n    }\n  ]\n}',
                              "a", "Trust é")
        self.assertEqual(json.loads(w)["wallets"][0]["label"], "Trust é")
        self.assertIn('\n  "version": 1,', w)
        self.assertEqual(json.loads(seed.desk_wallet('{"name":"Wallet 1","created":1}', "Trust"))["name"], "Trust")

    def test_wallet_db(self):
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d)
        path = os.path.join(d, "wallet.sqlite3")
        c = sqlite3.connect(path)
        c.execute("pragma journal_mode=wal")
        c.execute("create table settings (key text primary key, value text not null)")
        c.execute("insert into settings values ('wallet.network', 'mainnet')")
        c.commit()
        c.close()
        seed.wallet_db(path, 4)
        seed.wallet_db(path, 5)
        c = sqlite3.connect(path)
        self.assertEqual(dict(c.execute("select key, value from settings")),
                         {"wallet.network": "mainnet", "wallet.minimum_confirmations": "5"})
        c.close()
        with self.assertRaises(seed.SeedError):
            seed.wallet_db(path, 0)


class PreviousReleaseFilesTest(unittest.TestCase):
    def test_contact_added_once_in_the_releases_format(self):
        t = seed.contacts_json('{"version":1,"contacts":[{"id":"x","name":"X"}]}', "k@r")
        t = seed.contacts_json(t, "k2@r")
        d = json.loads(t)
        self.assertEqual([c["id"] for c in d["contacts"]], ["x", seed.CONTACT["id"]])
        self.assertEqual(d["contacts"][1]["epicbox"], "k2@r")
        self.assertEqual(json.loads(seed.contacts_json(None, "k@r"))["version"], 1)
        with self.assertRaises(seed.SeedError):
            seed.contacts_json('{"nope":1}', "k@r")

    def test_note_under_the_row_alias(self):
        d = json.loads(seed.meta_note('{"version":1,"notes":{"a":"b"},"contacts":[]}', 7))
        self.assertEqual(d["notes"], {"a": "b", "l:7": seed.NOTE})
        self.assertEqual(d["contacts"], [])
        with self.assertRaises(seed.SeedError):
            seed.meta_note('{"version":1}', 7)

    def test_lan_nodes_file(self):
        self.assertEqual(seed.lan_nodes_json(["http://b:1", "http://A:1", "c"]), '{"plainHttp":["a:1","b:1","c:80"]}')


if __name__ == "__main__":
    unittest.main()
