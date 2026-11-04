# SPDX-License-Identifier: Apache-2.0
"""The update-trust file-set checks (drivers/migration.py): a migrated folder passes; the previous
release's own folder (the main build, nothing migrated) and a folder still using the plain database fail."""
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "drivers"))

import facts  # noqa: E402
import migration as m  # noqa: E402

W = "wallets/mainnet"
BEFORE = ["contacts.json", "lan_nodes.json", "settings.toml", "wallets.json", W + "/WALLET.txt", W + "/wfe_meta.json",
          W + "/lepic/wallet.sqlite3", W + "/lepic/wallet.sqlite3-shm", W + "/lepic/wallet.sqlite3-wal"]
AFTER = ["contacts.json", "contacts.sealed", "contacts.keys/mainnet.key", "lan_nodes.json", "settings.toml", "wallets.json",
         W + "/WALLET.txt", W + "/wfe_meta.json", W + "/wfe_meta.sealed", W + "/lepic/wallet.enc.sqlite3",
         W + "/lepic/wallet.enc.sqlite3.check", W + "/lepic/wallet.sqlite3.pre-encryption"]
H = {"contacts.json": "a", "lan_nodes.json": "b", W + "/wfe_meta.json": "c"}


class StoreFiles(unittest.TestCase):
    def test_migrated(self):
        ok, why = m.store_files(BEFORE, AFTER)
        self.assertTrue(ok, why)

    def test_main_build_nothing_migrated(self):
        ok, why = m.store_files(BEFORE, BEFORE)
        self.assertFalse(ok)
        self.assertIn("wallet.enc.sqlite3 is missing", why)

    def test_plain_left_in_use(self):
        broken = AFTER + [W + "/lepic/wallet.sqlite3", W + "/lepic/wallet.sqlite3-wal"]
        ok, why = m.store_files(BEFORE, broken)
        self.assertFalse(ok)
        self.assertIn("the plain database is still there", why)

    def test_tmp_left_behind(self):
        ok, why = m.store_files(BEFORE, AFTER + [W + "/lepic/wallet.enc.sqlite3.tmp"])
        self.assertFalse(ok)
        self.assertIn("wallet.enc.sqlite3.tmp", why)

    def test_pre_encryption_required_after_plain(self):
        ok, why = m.store_files(BEFORE, [p for p in AFTER if not p.endswith("pre-encryption")])
        self.assertFalse(ok)
        self.assertIn("wallet.sqlite3.pre-encryption is missing", why)

    def test_retiring_candidate_may_drop_pre_encryption(self):
        ok, why = m.store_files(BEFORE, [p for p in AFTER if not p.endswith("pre-encryption")], retires=True)
        self.assertTrue(ok, why)
        self.assertIn("wallet.sqlite3.pre-encryption retired", why)

    def test_retiring_candidate_says_when_pre_encryption_stays(self):
        ok, why = m.store_files(BEFORE, AFTER, retires=True)
        self.assertTrue(ok, why)
        self.assertIn("not retired", why)

    def test_retiring_candidate_still_needs_encrypted_store(self):
        ok, why = m.store_files(BEFORE, BEFORE, retires=True)
        self.assertFalse(ok)
        self.assertIn("wallet.enc.sqlite3 is missing", why)

    def test_retiring_releases(self):
        self.assertFalse(facts.retires_plain_copy("26.11.1"))
        self.assertTrue(facts.retires_plain_copy("26.11.2"))
        self.assertTrue(facts.retires_plain_copy("26.12.0"))
        self.assertFalse(facts.retires_plain_copy(None))

    def test_encrypted_before_needs_no_pre_encryption(self):
        before = [p for p in AFTER if not p.endswith("pre-encryption")]
        ok, why = m.store_files(before, before)
        self.assertTrue(ok, why)

    def test_windows_separators(self):
        ok, why = m.store_files([p.replace("/", "\\") for p in BEFORE], [p.replace("/", "\\") for p in AFTER])
        self.assertTrue(ok, why)


class AppFiles(unittest.TestCase):
    def test_kept(self):
        ok, why = m.app_files(BEFORE, H, AFTER, H, ["mainnet"])
        self.assertTrue(ok, why)

    def test_plain_changed(self):
        ok, why = m.app_files(BEFORE, H, AFTER, dict(H, **{"contacts.json": "x"}), ["mainnet"])
        self.assertFalse(ok)
        self.assertIn("contacts.json changed", why)

    def test_sealed_and_key_missing(self):
        after = [p for p in AFTER if "sealed" not in p and "keys" not in p]
        ok, why = m.app_files(BEFORE, H, after, H, ["mainnet"])
        self.assertFalse(ok)
        for part in ("wfe_meta.sealed is missing", "contacts.sealed is missing", "contacts.keys/<walletId>.key"):
            self.assertIn(part, why)

    def test_main_build(self):
        ok, why = m.app_files(BEFORE, H, BEFORE, H, ["mainnet"])
        self.assertFalse(ok)

    def test_nothing_to_compare(self):
        ok, why = m.app_files(["settings.toml"], {}, ["settings.toml"], {})
        self.assertFalse(ok)


class LanNodes(unittest.TestCase):
    OLD = json.dumps({"plainHttp": ["http://127.0.0.1:4444"]})

    def toml(self, servers, plain):
        return '[node]\nservers = %s\nplain_http = %s\n' % (json.dumps(servers), json.dumps(plain))

    def test_moved(self):
        ok, why = m.lan_nodes(self.OLD, "b", "b", self.toml(["http://127.0.0.1:4444", "https://n"], ["http://127.0.0.1:4444"]))
        self.assertTrue(ok, why)

    def test_not_moved(self):
        ok, why = m.lan_nodes(self.OLD, "b", "b", self.toml(["http://127.0.0.1:4444"], []))
        self.assertFalse(ok)
        self.assertIn("lacks 127.0.0.1:4444", why)

    def test_old_file_changed_or_gone(self):
        t = self.toml(["http://127.0.0.1:4444"], ["http://127.0.0.1:4444"])
        self.assertFalse(m.lan_nodes(self.OLD, "b", "z", t)[0])
        self.assertFalse(m.lan_nodes(self.OLD, "b", None, t)[0])

    def test_nothing_seeded(self):
        self.assertFalse(m.lan_nodes(None, None, None, "")[0])


class ContactNote(unittest.TestCase):
    def test_kept(self):
        self.assertTrue(m.contact_note("Ann", "rent", H, H, True, True, "ui")[0])

    def test_not_shown(self):
        ok, why = m.contact_note("Ann", "rent", H, H, False, None, "ui")
        self.assertFalse(ok)
        self.assertIn("Ann", why)

    def test_file_changed(self):
        self.assertFalse(m.contact_note("Ann", "rent", H, dict(H, **{W + "/wfe_meta.json": "z"}), None, None, "files")[0])


class Facts(unittest.TestCase):
    def test_gate(self):
        self.assertFalse(facts.encrypts_store("26.10.24"))
        self.assertTrue(facts.encrypts_store("26.10.25"))
        self.assertTrue(facts.encrypts_store("26.11.0"))

    def test_run8_listings_fail_cleanly(self):
        # the main build's real file list (run 8 of 26.10.25): nothing migrated
        listing = ["contacts.json", "settings.toml", "wallets.json", "wallets/mainnet/WALLET.txt", "wallets/mainnet/lepic/wallet.sqlite3",
                   "wallets/mainnet/lepic/wallet.sqlite3-shm", "wallets/mainnet/lepic/wallet.sqlite3-wal", "wallets/mainnet/wfe_meta.json"]
        self.assertFalse(m.store_files(listing, listing)[0])
        self.assertFalse(m.app_files(listing, {}, listing, {}, [])[0])


if __name__ == "__main__":
    unittest.main()
