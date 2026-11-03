# SPDX-License-Identifier: Apache-2.0
"""The update-trust data checks (drivers/core/checks.py over drivers/core/walletdata.py) on fixture data:
a plain wallet.sqlite3 built here, fake files objects, a fake LEPIC CLI and a stub command for the CLI's
standard-input handling. No app, no emulator, no rig, no network."""
import json
import os
import sqlite3
import stat
import sys
import tempfile
import textwrap
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRIVERS)

import facts  # noqa: E402
from core import checks, walletdata as wd  # noqa: E402

NODE, RELAY = "node.test:3413", "relay.test"
CUSTOM_NODE, CUSTOM_RELAY = "10.0.0.5:3413", "box.test"
W = "wallets/mainnet"
SLATE_A, SLATE_B = "A" * 32, "B" * 32


class FakeP:
    """The platform as the checks see it: the lane's chosen servers."""
    name = "linux"
    node, custom_node = NODE, CUSTOM_NODE
    relay, custom_relay = RELAY, CUSTOM_RELAY
    lan_before = None


class FakeLane:
    def __init__(self, required=None, funds=False, mode="fresh"):
        self.p = FakeP()
        self.required = required or ["wallet_opens", "balance_kept", "history_kept", "custom_nodes_kept",
                                     "custom_relays_kept", "settings_kept"]
        self.funds, self.funder, self.mode = funds, None, mode
        self.results, self.details, self.lines = {}, {}, []
        self.out = tempfile.mkdtemp(prefix="lane-")
        # what the driver set on the previous release (the fixtures' settings): its setup took
        self.want_settings = {"theme": "Light", "label": "Trust 1102 1200", "confirmations": 1, "technical_details": True}

    def ok(self, check, why):
        self.results[check] = True
        self.details[check] = why

    def fail(self, check, why):
        self.results[check] = False
        self.details[check] = why

    def log(self, line):
        self.lines.append(line)


def tx(direction="incoming", state="confirmed", amount=3000000, slate=SLATE_A, who="esa57kJmWkZyX8fSkKPW2Gu12ENhFF6MXfdsrsY4gqVK58ZwzB4d@epicbox.test"):
    return dict(id=1, direction=direction, state=state, transport="epicbox", credited=amount if direction == "incoming" else 0,
                debited=0 if direction == "incoming" else amount, fee=None, height=10, counterparty=who, slate=slate)


def digest(total=3000000, txs=None, nodes=None, relays=None, settings=None, source="db", level="3", counterparties=True,
           unread=None, node_in_use=NODE, relay_in_use=RELAY):
    nodes = nodes if nodes is not None else [NODE, CUSTOM_NODE]
    relays = relays if relays is not None else [RELAY, CUSTOM_RELAY]
    s = {"theme": "Light", "technical_details": True, "label": "Trust 1102 1200", "confirmations": 1}
    s.update(settings or {})
    return {"source": source, "wallet": {"id": "w1", "label": "Trust 1102 1200", "dataDir": None}, "wallet_ids": ["w1"],
            "store_dir": W + "/lepic", "balance": {"total": total, "spendable": total, "unconfirmed": 0, "locked": 0},
            "outputs": [{"commit": "AA", "amount": total, "status": "unspent", "height": 10}] if source == "db" else None,
            "txs": txs if txs is not None else [tx()], "counterparties_read": counterparties, "tip": 20,
            "servers": {"node_in_use": node_in_use, "nodes": nodes, "nodes_added": [CUSTOM_NODE],
                        "relay_in_use": relay_in_use, "relays": relays, "relays_added": [CUSTOM_RELAY]},
            "settings_toml": None, "settings": s, "unread": unread or {}, "level": level, "files": [W + "/lepic/wallet.sqlite3"],
            "hashes": {}, "log": None, "address_book": None, "notes": None}


class Compare(unittest.TestCase):
    def setUp(self):
        self.env = dict(os.environ)
        os.environ["REL_CANDIDATE_VERSION"] = "26.10.24"   # keeps the plain database: the migration checks are n/a
        os.environ["REL_PREVIOUS_VERSION"] = "26.10.23"

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.env)

    def run_compare(self, before, after, **kw):
        lane = FakeLane(**kw)
        lane.want_settings = {"theme": "Light", "label": "Trust 1102 1200", "confirmations": 1, "technical_details": True}
        checks.compare(lane, before, after, ([], {}))
        return lane

    def test_all_kept(self):
        lane = self.run_compare(digest(), digest())
        for c in ("wallet_opens", "balance_kept", "history_kept", "custom_nodes_kept", "custom_relays_kept", "settings_kept"):
            self.assertTrue(lane.results[c], "%s: %s" % (c, lane.details[c]))
        for c in checks.MIGRATION_CHECKS:
            self.assertTrue(lane.results[c])
            self.assertIn("not applicable", lane.details[c])

    def test_balance_lost(self):
        after = digest(total=0, txs=[tx()])
        after["outputs"] = []
        lane = self.run_compare(digest(total=3000000), after)
        self.assertFalse(lane.results["balance_kept"])
        self.assertIn("before total 0.03,", lane.details["balance_kept"])
        self.assertIn("after total 0,", lane.details["balance_kept"])
        self.assertIn("unspent outputs 1 -> 0", lane.details["balance_kept"])
        self.assertTrue(lane.results["history_kept"])

    def test_tx_missing(self):
        before = digest(txs=[tx(), tx("outgoing", slate=SLATE_B, amount=100)])
        lane = self.run_compare(before, digest(txs=[tx()]))
        self.assertFalse(lane.results["history_kept"])
        self.assertIn("1 of 2 transactions missing", lane.details["history_kept"])
        self.assertTrue(lane.results["balance_kept"])

    def test_counterparty_lost(self):
        lane = self.run_compare(digest(), digest(txs=[tx(who=None)]))
        self.assertFalse(lane.results["history_kept"])
        self.assertIn("who paid or was paid lost", lane.details["history_kept"])

    def test_server_gone(self):
        lane = self.run_compare(digest(), digest(nodes=[NODE], relays=[RELAY]))
        self.assertFalse(lane.results["custom_nodes_kept"])
        self.assertIn("added node %s gone" % CUSTOM_NODE, lane.details["custom_nodes_kept"])
        self.assertFalse(lane.results["custom_relays_kept"])
        self.assertIn("gone", lane.details["custom_relays_kept"])

    def test_node_in_use_changed(self):
        lane = self.run_compare(digest(), digest(node_in_use="other.test:3413", nodes=["other.test:3413", CUSTOM_NODE]))
        self.assertFalse(lane.results["custom_nodes_kept"])
        self.assertIn("in use was", lane.details["custom_nodes_kept"])

    def test_setting_changed(self):
        lane = self.run_compare(digest(), digest(settings={"theme": "Dark"}))
        self.assertFalse(lane.results["settings_kept"])
        self.assertIn("theme", lane.details["settings_kept"])

    def test_theme_compares_without_case(self):
        lane = self.run_compare(digest(), digest(settings={"theme": "light"}))
        self.assertTrue(lane.results["settings_kept"], lane.details["settings_kept"])

    def test_unread_is_said_not_passed_silently(self):
        s = {"theme": None, "technical_details": None}
        why = {"theme": "keystore", "technical_details": "keystore"}
        lane = self.run_compare(digest(settings=s, unread=why), digest(settings=s, unread=why, level="3"))
        self.assertTrue(lane.results["settings_kept"])
        self.assertIn("NOT read: theme", lane.details["settings_kept"])

    def test_nothing_read_after_fails(self):
        s = {"theme": None, "technical_details": None, "label": None, "confirmations": None}
        lane = self.run_compare(digest(), digest(settings=s))
        self.assertFalse(lane.results["settings_kept"])

    def test_cli_read_says_counterparties_not_compared(self):
        after = digest(source="cli", counterparties=False, txs=[tx(who=None)])
        lane = self.run_compare(digest(), after)
        self.assertTrue(lane.results["history_kept"], lane.details["history_kept"])
        self.assertIn("NOT compared", lane.details["history_kept"])
        self.assertTrue(lane.results["balance_kept"])
        self.assertIn("LEPIC CLI", lane.details["balance_kept"])

    def test_no_wallet_after(self):
        after = digest()
        after["wallet"], after["source"] = None, "none"
        lane = self.run_compare(digest(), after)
        self.assertFalse(lane.results["wallet_opens"])

    def test_phone_one_wallet_without_wallets_json(self):
        phone = [digest(), digest()]
        for d in phone:
            d["wallet"], d["wallet_ids"] = None, []
        lane = self.run_compare(*phone)
        self.assertTrue(lane.results["wallet_opens"], lane.details["wallet_opens"])
        gone = digest()
        gone["wallet"], gone["wallet_ids"] = None, []
        self.assertFalse(self.run_compare(digest(), gone).results["wallet_opens"])  # had wallets.json, lost it
        gone["source"] = "none"
        self.assertFalse(self.run_compare(phone[0], gone).results["wallet_opens"])  # no store read after

    def test_migration_checks_apply_when_candidate_encrypts(self):
        os.environ["REL_CANDIDATE_VERSION"] = "26.10.25"
        os.environ["REL_PREVIOUS_VERSION"] = "26.10.24"
        before = [W + "/lepic/wallet.sqlite3", W + "/lepic/wallet.sqlite3-wal", W + "/wfe_meta.json", "contacts.json", "lan_nodes.json"]
        hashes = {"contacts.json": "a", W + "/wfe_meta.json": "b", "lan_nodes.json": "c"}
        d = digest(source="cli", counterparties=False)
        d["files"] = [W + "/lepic/wallet.sqlite3"]   # the plain database is still there: not migrated
        d["hashes"] = hashes
        lane = FakeLane()
        checks.compare(lane, digest(), d, (before, hashes))
        self.assertFalse(lane.results["store_encrypted"])
        self.assertIn("still there", lane.details["store_encrypted"])
        self.assertFalse(lane.results["app_files_kept"])


class Public(unittest.TestCase):
    def test_no_counterparty_or_hash(self):
        d = digest()
        d["hashes"] = {"contacts.json": "abc"}
        d["address"] = "esa57kJmWkZyX8fSkKPW2Gu12ENhFF6MXfdsrsY4gqVK58ZwzB4d@epicbox.test"
        d["address_book"] = {"source": "contacts.json", "contacts": [{"id": "1", "name": "Ann", "epicbox": "esa57kJmWkZyX8fSkKPW2Gu12ENhFF6MXfdsrsY4gqVK58ZwzB4d@epicbox.test"}]}
        p = checks.public(d)
        text = json.dumps(p)
        self.assertNotIn("esa57kJmWkZyX8fSkKPW2Gu12ENhFF6MXfdsrsY4gqVK58ZwzB4d", text)
        self.assertNotIn("abc", text)
        self.assertEqual(p["balance"]["total"], 3000000)


# ---- walletdata on a plain wallet.sqlite3 -----------------------------------------------------------

def make_data_root(root, outputs, txs, settings=None, toml=None, enc=False):
    d = os.path.join(root, W, "lepic")
    os.makedirs(d)
    with open(os.path.join(root, "wallets.json"), "w") as f:
        json.dump({"lastUsedId": "w1", "wallets": [{"id": "w1", "label": "Trust 1102 1200", "dataDir": "/gone/%s" % W}]}, f)
    if toml:
        with open(os.path.join(root, "settings.toml"), "w") as f:
            f.write(toml)
    if enc:
        for n in (facts.STORE_ENC, facts.STORE_CHECK):
            with open(os.path.join(d, n), "wb") as f:
                f.write(b"x")
        return
    c = sqlite3.connect(os.path.join(d, facts.STORE_PLAIN))
    c.execute("create table outputs (commitment blob, amount integer, status text, height integer)")
    c.execute("create table transactions (id integer, direction text, state text, transport text, amount_credited integer, "
              "amount_debited integer, fee integer, confirmed_height integer, counterparty text, slate_id blob)")
    c.execute("create table settings (key text, value text)")
    for i, (amount, status, height) in enumerate(outputs):
        c.execute("insert into outputs values (?,?,?,?)", (bytes([i + 1]), amount, status, height))
    for t in txs:
        c.execute("insert into transactions values (?,?,?,?,?,?,?,?,?,?)",
                  (t["id"], t["direction"], t["state"], "epicbox", t["credited"], t["debited"], t["fee"], t["height"],
                   t["counterparty"], bytes.fromhex(t["slate"])))
    for k, v in (settings or {}).items():
        c.execute("insert into settings values (?,?)", (k, v))
    c.commit()
    c.close()


class WalletData(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="wd-")
        os.environ["TMPDIR"] = self.tmp

    def tx(self):
        t = tx(slate=SLATE_A)
        t["slate"] = "AA" * 16
        return t

    def test_plain_store(self):
        root = os.path.join(self.tmp, "data")
        make_data_root(root, [(3000000, "unspent", 10)], [self.tx()],
                       {"refresh.last_confirmed_height": "20", "wallet.minimum_confirmations": "1"},
                       toml='[node]\nservers = ["%s", "%s"]\nplain_http = []\n[epicbox]\nservers = ["%s"]\n' % (NODE, CUSTOM_NODE, RELAY))
        d = wd.read(wd.DirFiles(root), {})
        self.assertEqual(d["source"], "db")
        self.assertEqual(d["balance"]["total"], 3000000)
        self.assertEqual(d["balance"]["spendable"], 3000000)
        self.assertEqual(len(d["txs"]), 1)
        self.assertEqual(d["servers"]["nodes"], [NODE, CUSTOM_NODE])
        self.assertEqual(d["servers"]["relay_in_use"], RELAY)
        self.assertEqual(d["settings"]["confirmations"], 1)
        self.assertEqual(d["settings"]["label"], "Trust 1102 1200")
        self.assertIsNone(d["settings"]["theme"])
        self.assertIn("theme", d["unread"])

    def test_locked_outputs_are_not_spendable(self):
        root = os.path.join(self.tmp, "data")
        make_data_root(root, [(1000000, "unspent", 10), (500000, "locked", 10), (200000, "unconfirmed", 20)], [],
                       {"refresh.last_confirmed_height": "20", "wallet.minimum_confirmations": "1"})
        b = wd.read(wd.DirFiles(root), {})["balance"]
        self.assertEqual((b["total"], b["spendable"], b["unconfirmed"], b["locked"]), (1700000, 1000000, 200000, 500000))

    def test_plain_before_and_after_roundtrip(self):
        """walletdata + checks on two real databases: a lost output is a lost balance."""
        a, b = os.path.join(self.tmp, "a"), os.path.join(self.tmp, "b")
        st = {"refresh.last_confirmed_height": "20", "wallet.minimum_confirmations": "1"}
        make_data_root(a, [(3000000, "unspent", 10)], [self.tx()], st)
        make_data_root(b, [], [self.tx()], st)
        os.environ["REL_CANDIDATE_VERSION"], os.environ["REL_PREVIOUS_VERSION"] = "26.10.24", "26.10.23"
        before, after = wd.read(wd.DirFiles(a), {}), wd.read(wd.DirFiles(b), {})
        lane = FakeLane()
        checks.compare(lane, before, after, ([], {}))
        self.assertFalse(lane.results["balance_kept"])
        self.assertTrue(lane.results["history_kept"], lane.details["history_kept"])

    def test_encrypted_store_goes_through_the_cli(self):
        root = os.path.join(self.tmp, "data")
        make_data_root(root, [], [], enc=True)

        class FakeCli:
            def read(self, files, store_dir, secrets, settings_text):
                assert store_dir == W + "/lepic" and secrets["phrase"] == "p" and secrets["password"] == "w"
                return {"info": {"accounts": [{"total": 0.03, "spendable": 0.03, "awaiting_confirmation": 0, "locked": 0}]},
                        "txs": [{"tx_id": 1, "direction": "incoming", "state": "confirmed", "transport": "epicbox",
                                 "amount_credited": 0.03, "amount_debited": 0, "fee": None, "slate_id": "aa-bb"}],
                        "address": "esa@relay"}
        d = wd.read(wd.DirFiles(root), {"phrase": "p", "password": "w"}, migrate=True, cli=FakeCli())
        self.assertEqual(d["source"], "cli")
        self.assertEqual(d["balance"]["total"], 3000000)
        self.assertFalse(d["counterparties_read"])
        self.assertIsNone(d["txs"][0]["counterparty"])
        self.assertIn("level", d["unread"])

    def test_path_escape_refused(self):
        f = wd.DirFiles(self.tmp)
        with self.assertRaises(wd.ReadError):
            f.text("../etc/passwd")


class Cli(unittest.TestCase):
    """The CLI wrapper's stdin handling, on a stub executable: the phrase and password never reach argv or env."""

    def test_secrets_on_stdin_only(self):
        tmp = tempfile.mkdtemp(prefix="cli-")
        os.environ["TMPDIR"] = tmp
        log = os.path.join(tmp, "calls.log")
        stub = os.path.join(tmp, "lepic")
        with open(stub, "w") as f:
            f.write(textwrap.dedent("""\
                #!/bin/sh
                IFS= read -r a
                IFS= read -r b
                printf '%%s|stdin1=%%s|stdin2=%%s\\n' "$*" "$a" "$b" >> '%s'
                case "$*" in
                  *"wallet info"*) echo '{"accounts":[{"total":1.5,"spendable":1.5,"awaiting_confirmation":0,"locked":0}]}';;
                  *"tx list"*) echo '{"transactions":[]}';;
                  *address*) echo '{"address":"esa@relay"}';;
                esac
                """ % log))
        os.chmod(stub, stat.S_IRWXU)
        root = os.path.join(tmp, "data")
        make_data_root(root, [], [], enc=True)
        cli = wd.LepicCli(exe=stub)
        try:
            r = cli.read(wd.DirFiles(root), W + "/lepic", {"phrase": "word one two", "password": "pw-secret"})
        finally:
            cli.close()
        self.assertEqual(wd.cli_shape(r)[0]["total"], 150000000)
        with open(log) as fh:
            calls = fh.read()
        self.assertNotIn("word one two", calls.split("|stdin1")[0])        # not in argv of the first call
        for line in calls.splitlines():
            argv = line.split("|stdin1=")[0]
            self.assertNotIn("pw-secret", argv)
            self.assertNotIn("word one", argv)
        self.assertIn("stdin1=word one two|stdin2=pw-secret", calls)       # the restore: phrase, then password


class Files(unittest.TestCase):
    def test_keyring_item_is_a_json_object(self):
        from linux import files as lf
        self.assertEqual(lf.parse_store('{"app.level": "3"}'), {"app.level": "3"})
        with self.assertRaises(wd.ReadError):
            lf.parse_store("[1]")

    def test_android_note_and_path_guard(self):
        from android import files as af
        f = af.AppFiles("emulator-5554")
        self.assertEqual(f.store(), {})
        self.assertIn("Keystore", f.store_note)
        with self.assertRaises(wd.ReadError):
            f.fetch("../x", "/dev/null")


class ConfirmationsOnScreen(unittest.TestCase):
    """The encrypted store's minimum confirmations are not in the LEPIC CLI's reports: on Windows the lane
    reads them on the app's Settings page instead (lane.ui_settings), before and after the update."""

    def setUp(self):
        self.env = dict(os.environ)
        os.environ["REL_CANDIDATE_VERSION"], os.environ["REL_PREVIOUS_VERSION"] = "26.10.24", "26.10.23"

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.env)

    def run_compare(self, ui):
        why = {"confirmations": "the encrypted store's settings are not in the LEPIC CLI's reports"}
        before = digest(settings={"confirmations": None}, unread=why, source="cli")
        after = digest(settings={"confirmations": None}, unread=why, source="cli")
        lane = FakeLane()
        if ui is not None:
            lane.ui_settings = ui
        checks.compare(lane, before, after, ([], {}))
        return lane, before

    def test_not_read_without_the_screen(self):
        lane, _ = self.run_compare(None)
        self.assertTrue(lane.results["settings_kept"])
        self.assertIn("NOT read: confirmations", lane.details["settings_kept"])

    def test_read_on_screen_and_set_in_the_candidate(self):
        lane, before = self.run_compare({"before": {"confirmations": 1}, "after": {"confirmations": 1},
                                         "set": {"from": 1, "to": 2, "read": 2, "back": 1, "refused": False}})
        d = lane.details["settings_kept"]
        self.assertTrue(lane.results["settings_kept"], d)
        self.assertNotIn("NOT read", d)
        self.assertIn("1 confirmations", d)
        self.assertIn("Settings › Payments page before and after", d)
        self.assertIn("set to 2 and back to 1", d)
        self.assertIsNone(before["settings"]["confirmations"], "the digest itself is left as read")

    def test_changed_by_the_update_on_screen(self):
        lane, _ = self.run_compare({"before": {"confirmations": 1}, "after": {"confirmations": 6}})
        self.assertFalse(lane.results["settings_kept"])
        self.assertIn("'confirmations': (1, 6)", lane.details["settings_kept"])

    def test_a_count_set_in_the_candidate_that_does_not_keep(self):
        lane, _ = self.run_compare({"before": {"confirmations": 1}, "after": {"confirmations": 1},
                                    "set": {"from": 1, "to": 2, "read": 1, "back": 1, "refused": True}})
        self.assertFalse(lane.results["settings_kept"])
        self.assertIn("1 → 2 read back 1", lane.details["settings_kept"])
        self.assertIn("not saved", lane.details["settings_kept"])

    def test_not_set_on_the_previous_release_is_harness(self):
        with self.assertRaises(checks.HarnessFault):
            self.run_compare({"before": {"confirmations": 6}, "after": {"confirmations": 6}})


class SetupNotTaken(unittest.TestCase):
    def test_settings_the_driver_did_not_set_are_harness(self):
        lane = FakeLane()
        lane.want_settings = dict(lane.want_settings, label="Another label")
        with self.assertRaises(checks.HarnessFault):
            checks.compare(lane, digest(), digest(), ([], {}))


class FundsOff(unittest.TestCase):
    """A lane without REL_FUNDS (the notor one) still funds the previous release's wallet, so the update
    has a balance and a history to keep; afterwards the balance goes back to P, not checked."""

    def test_previous_wallet_funded_without_funds(self):
        lane, paid = FakeLane(funds=False), []
        with mock.patch.object(checks, "_digest", lambda *a: digest(total=0, txs=[])), \
             mock.patch.object(checks, "_pay", lambda _l, addr, amount, *a: paid.append((addr, amount)) or (None, {})), \
             mock.patch.object(checks, "wait_spendable", lambda *a, **k: digest()):
            checks.fund_before(lane, "esADDR")
        self.assertEqual(paid, [("esADDR", checks.FUND_IN)])

    def test_balance_returned_without_checks(self):
        lane, back = FakeLane(funds=False), []
        lane.ok("wallet_opens", "x")
        lane.ok("balance_kept", "x")
        with mock.patch.object(checks, "_send_back", lambda _l, pair: back.append(pair)), \
             mock.patch.object(checks, "_pay", lambda *a: self.fail("no receive leg without funds")):
            checks.funds_legs(lane, digest())
        self.assertEqual(back, [None])
        self.assertNotIn("send_ok", lane.results)


if __name__ == "__main__":
    unittest.main()

