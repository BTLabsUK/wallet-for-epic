# SPDX-License-Identifier: Apache-2.0
"""The lane seeds (drivers/core/lane_seed.py): BIP39 phrases with their checksum, the store's files and
modes, its lock, init/check/scan, the doctor's checks and the leak scan. Every phrase here is made from
fixed entropy (public test vectors or bytes counted up), never a lane's real seed; the store is a
temporary folder (REL_TRUST_SEEDS_ROOT). No network: the node's tip is stubbed."""
import contextlib
import gzip
import io
import json
import os
import shutil
import stat
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "drivers"))

from core import lane_seed as ls  # noqa: E402
from core import lane as lane_mod  # noqa: E402
from core.faults import HarnessFault, ProductFault  # noqa: E402
from core.recover import phrase_screen  # noqa: E402
from core.surface import Node  # noqa: E402

FAKE = ls.encode(bytes(range(32)))      # fixed entropy: a phrase no lane holds
OTHER = ls.encode(bytes(range(32, 64)))


def mode(path):
    return stat.S_IMODE(os.stat(path).st_mode)


class Store(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp(prefix="lane-seeds-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(shutil.rmtree, self.root, True)
        self.env = mock.patch.dict(os.environ, {"REL_TRUST_SEEDS_ROOT": os.path.join(self.root, "seeds")})
        self.env.start()
        self.addCleanup(self.env.stop)

    def run_cli(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err), \
             mock.patch.object(ls, "tip", lambda *a, **k: (123456, "https://node.btlabs.uk")):
            code = ls.main(list(argv))
        return code, out.getvalue() + err.getvalue()

    def assertNoWord(self, text):
        """No 3 consecutive words of any seed in the store (single words of the list are plain English)."""
        held = [s.phrase() for s in map(ls.LaneSeed, ls.LANES) if s.exists()] + [FAKE, OTHER]
        self.assertFalse(ls.Needles(held).in_stream([text.encode()]), "phrase words printed")


class Phrases(Store):
    def test_bip39_vectors(self):
        self.assertEqual(ls.encode(bytes(32)), " ".join(["abandon"] * 23 + ["art"]))
        self.assertEqual(ls.encode(b"\x7f" * 32).split()[-1], "title")
        self.assertEqual(ls.encode(bytes(16)), " ".join(["abandon"] * 11 + ["about"]))
        for p in (ls.encode(bytes(32)), ls.encode(bytes(16)), FAKE, ls.new_phrase()):
            self.assertTrue(ls.validate(p)[0], ls.validate(p)[1])

    def test_bad_phrases_say_why_without_a_word(self):
        ws = FAKE.split()
        swapped = " ".join(ws[:-1] + [ws[0] if ws[-1] != ws[0] else ws[1]])
        for p, why in ((" ".join(ws[:20]), "20 words"), (swapped, "wrong checksum"),
                       (" ".join(ws[:23] + ["notaword"]), "word 24 not in")):
            ok, said = ls.validate(p)
            self.assertFalse(ok)
            self.assertIn(why, said)
            self.assertNoWord(said)

    def test_the_word_list_is_checked(self):
        bad = os.path.join(self.root, "list.txt")
        with open(bad, "w") as f:
            f.write("\n".join(ls.words()[:2047] + ["zzzz"]) + "\n")
        with open(bad) as f:
            self.assertFalse(ls._good(ls._list_of(f.read())))
        self.assertTrue(ls._good(ls.words()))


class Files(Store):
    def test_create_modes_and_meta(self):
        s = ls.LaneSeed("linux-tor")
        s.create(FAKE, 100, "2026-11-03")
        self.assertEqual(mode(os.path.dirname(s.dir)), 0o700)
        self.assertEqual(mode(s.dir), 0o700)
        self.assertEqual(mode(s.phrase_path), 0o600)
        self.assertEqual(mode(s.meta_path), 0o600)
        self.assertEqual(s.phrase(), FAKE)
        self.assertEqual(s.birth(), {"height": 100, "date": "2026-11-03", "month": "2026-11", "method": "tip at creation"})
        with open(s.meta_path) as f:
            meta = f.read()
        self.assertFalse(set(json.dumps(json.loads(meta)).replace('"', " ").split()) & set(FAKE.split()))
        self.assertEqual(sorted(json.loads(meta)), ["birth", "created_at", "fundings", "last"])

    def test_never_overwritten(self):
        s = ls.LaneSeed("linux-tor")
        s.create(FAKE, 100, "2026-11-03")
        with self.assertRaises(FileExistsError):
            s.create(OTHER, 100, "2026-11-03")
        self.assertEqual(s.phrase(), FAKE)

    def test_last_and_fundings(self):
        s = ls.LaneSeed("android-tor")
        s.create(FAKE, 100, "2026-11-03")
        self.assertIsNone(s.last_spendable())
        s.record_last({"spendable": 5600000, "total": 5600000}, "26.11.1-run1")
        s.record_funding("0.05", "26.11.1-run1", "C" * 32)
        m = s.meta()
        self.assertEqual(m["last"]["spendable"], "0.056")
        self.assertEqual(m["last"]["run"], "26.11.1-run1")
        self.assertEqual(s.last_spendable(), 5600000)
        self.assertEqual(m["fundings"][0]["amount"], "0.05")
        self.assertEqual(m["fundings"][0]["slate8"], "C" * 8)
        self.assertEqual(mode(s.meta_path), 0o600)

    def test_missing_or_broken_phrase_is_harness(self):
        s = ls.LaneSeed("windows-tor")
        with self.assertRaises(HarnessFault):
            s.phrase()
        s.create(FAKE, 1, "2026-11-03")
        with open(s.phrase_path, "w") as f:
            f.write(" ".join(FAKE.split()[:23]) + "\n")
        with self.assertRaises(HarnessFault) as c:
            s.phrase()
        self.assertIn("23 words", c.exception.what)


class Lock(Store):
    def test_held_lock_names_the_pid(self):
        a, b = ls.LaneSeed("linux-notor"), ls.LaneSeed("linux-notor")
        a.lock()
        self.addCleanup(a.unlock)
        self.assertEqual(b.lock_holder(), str(os.getpid()))
        with self.assertRaises(HarnessFault) as c:
            b.lock()
        self.assertIn("in use by pid %d" % os.getpid(), c.exception.what)
        a.unlock()
        self.assertIsNone(b.lock_holder())
        b.lock()
        b.unlock()


class Cli(Store):
    def test_init_one_then_all_then_refused(self):
        code, out = self.run_cli("init", "linux-tor")
        self.assertEqual(code, 0, out)
        self.assertIn("birth height 123456 from https://node.btlabs.uk", out)
        self.assertNoWord(out)
        code, out = self.run_cli("init", "all")
        self.assertEqual(code, 1, "linux-tor refused")
        self.assertIn("linux-tor: refused", out)
        self.assertNoWord(out)
        prints = {ls.fingerprint(ls.LaneSeed(x).phrase()) for x in ls.LANES}
        self.assertEqual(len(prints), 6, "all six distinct")
        self.assertEqual(ls.LaneSeed("android-notor").birth()["height"], 123456)
        self.assertTrue(os.path.exists(os.path.join(ls.root(), ls.WORDLIST_NAME)))

    def test_check(self):
        self.run_cli("init", "all")
        code, out = self.run_cli("check")
        self.assertEqual(code, 0, out)
        self.assertIn("ok   lane seed linux-tor: 24 words, checksum good", out)
        self.assertIn("warn lane seed linux-tor: no balance on record", out)
        self.assertIn("warn P's spendable not read", out)
        self.assertNoWord(out)
        os.chmod(ls.LaneSeed("linux-tor").phrase_path, 0o644)
        shutil.copy(ls.LaneSeed("windows-tor").phrase_path, ls.LaneSeed("windows-notor").phrase_path)
        code, out = self.run_cli("check")
        self.assertEqual(code, 1)
        self.assertIn("FAIL lane seed linux-tor: phrase 644 (want 600)", out)
        self.assertIn("FAIL lane seed windows-notor: the same phrase as windows-tor", out)
        self.assertNoWord(out)

    def test_check_without_seeds_fails(self):
        code, out = self.run_cli("check", "android-tor")
        self.assertEqual(code, 1)
        self.assertIn("FAIL lane seed android-tor: none in", out)

    def test_scan_prints_paths_only(self):
        self.run_cli("init", "linux-tor")
        words = ls.LaneSeed("linux-tor").phrase().split()
        d = os.path.join(self.root, "out")
        os.makedirs(d)
        with open(os.path.join(d, "trust.log"), "w") as f:
            f.write("tapped %s-%s %s\n" % tuple(w.upper() for w in words[5:8]))
        with open(os.path.join(d, "clean.log"), "w") as f:
            f.write("nothing here\n")
        code, out = self.run_cli("scan", d)
        self.assertEqual(code, 1)
        self.assertIn(os.path.join(d, "trust.log"), out)
        self.assertNotIn("clean.log", out)
        self.assertNoWord(out)
        os.remove(os.path.join(d, "trust.log"))
        self.assertEqual(self.run_cli("scan", d)[0], 0)


class Scan(Store):
    def setUp(self):
        super().setUp()
        self.d = os.path.join(self.root, "out")
        os.makedirs(self.d)
        self.w = FAKE.split()

    def put(self, name, data, opener=open):
        with opener(os.path.join(self.d, name), "wb") as f:
            f.write(data)

    def hits(self, **kw):
        return sorted(os.path.basename(h) for h in ls.scan([self.d], [FAKE], **kw)[0])

    def test_kinds_of_files(self):
        three = " ".join(self.w[10:13]).encode()
        self.put("text.txt", b"x " + three.upper() + b" y")
        self.put("sep.json", ('["%s", "%s", "%s"]' % tuple(self.w[0:3])).encode())
        self.put("bin.dat", b"\x00\x01\xff" + three.replace(b" ", b"\x00\x07") + b"\xfe")
        self.put("wide.log", ("start " + " ".join(self.w[20:23]) + " end").encode("utf-16-le"))
        self.put("packed.log.gz", b"before " + three + b" after", gzip.open)
        self.put("two.txt", " ".join(self.w[3:5]).encode() + b" and " + self.w[5].encode())
        self.put("apart.txt", (" ".join(self.w[0:2]) + " " + self.w[3]).encode())
        self.assertEqual(self.hits(), ["bin.dat", "packed.log.gz", "sep.json", "text.txt", "wide.log"])

    def test_words_cut_by_a_chunk(self):
        data = b"z" * 10 + b" " + " ".join(self.w[7:10]).encode() + b" "
        self.put("cut.txt", data)
        for size in (12, 13, 15, 17, 4096):
            with mock.patch.object(ls, "CHUNK", size):
                self.assertEqual(self.hits(), ["cut.txt"], size)

    def test_symlinks_and_the_store_skipped(self):
        target = os.path.join(self.root, "elsewhere.txt")
        with open(target, "w") as f:
            f.write(" ".join(self.w))
        os.symlink(target, os.path.join(self.d, "link.txt"))
        inner = os.path.join(self.d, "seeds")
        os.makedirs(inner)
        with open(os.path.join(inner, "phrase"), "w") as f:
            f.write(FAKE)
        self.assertEqual(self.hits(skip=[inner]), [])

    def test_needles_hold_hashes_only(self):
        n = ls.Needles([FAKE])
        self.assertEqual(len(n.hashes), 22)
        self.assertTrue(all(isinstance(h, bytes) and len(h) == 32 for h in n.hashes))
        self.assertTrue(n.in_stream([" ".join(self.w[1:4]).encode()]))
        self.assertFalse(n.in_stream([" ".join(self.w[1:3]).encode()]))


class Doctor(Store):
    def make(self, *lanes, last=None):
        for i, lane in enumerate(lanes):
            s = ls.LaneSeed(lane)
            s.create(ls.encode(bytes([i + 1]) * 32), 1, "2026-11-03")
            if last is not None:
                s.record_last({"spendable": ls.nano(last), "total": ls.nano(last)}, "r1")

    def levels(self, out):
        return [lvl for lvl, _ in out]

    def test_p_covers_the_run(self):
        self.make("linux-tor", "linux-notor", last="0.07")
        # balances above the top-up line: 0.01 each, 0.01 more for the funds lane, a fee per payment
        out = ls.doctor(["linux-tor", "linux-notor"], "0.05", ["linux-tor"])
        self.assertEqual(out[-1][0], "ok", out[-1])
        self.assertIn("covers the lanes' 0.045 EPIC", out[-1][1])
        out = ls.doctor(["linux-tor", "linux-notor"], "0.04", ["linux-tor"])
        self.assertEqual(out[-1][0], "FAIL")
        self.assertNotIn("warn", self.levels(out))

    def test_low_or_unknown_balances_count_the_top_up(self):
        self.make("android-tor")
        out = ls.doctor(["android-tor"], "1", [])
        self.assertIn("warn", self.levels(out))
        self.assertIn("covers the lanes' 0.055 EPIC", out[-1][1])

    def test_lock_held_fails(self):
        self.make("windows-tor")
        s = ls.LaneSeed("windows-tor")
        s.lock()
        self.addCleanup(s.unlock)
        out = ls.doctor(["windows-tor"], None, [])
        self.assertEqual(out[0][0], "FAIL")
        self.assertIn("in use by pid", out[0][1])


class Birth(Store):
    """The birth kept beside each seed: the block before its first output, else the tip when it was made."""

    def legacy(self, lane="linux-tor"):
        s = ls.LaneSeed(lane)
        s.create(FAKE, 3782025, "2026-11-03")
        m = s.meta()
        b = m.pop("birth")
        m.update(birth_height=b["height"], birth_month="2026-11", created_at="2026-11-03T09:00:00")
        s._save_meta(m)
        return s

    def test_a_seed_made_before_birth_reads_as_tip_at_creation(self):
        s = self.legacy()
        self.assertEqual(s.birth(), {"height": 3782025, "date": "2026-11-03", "month": "2026-11", "method": "tip at creation"})

    def test_cli_birth_moves_the_record_and_keeps_the_modes(self):
        self.legacy()
        code, out = self.run_cli("birth", "linux-tor")
        self.assertEqual(code, 0, out)
        self.assertIn("linux-tor: birth height 3782025, date 2026-11-03 (tip at creation)", out)
        self.assertNoWord(out)
        s = ls.LaneSeed("linux-tor")
        self.assertNotIn("birth_height", s.meta())
        self.assertEqual(s.meta()["birth"]["method"], "tip at creation")
        self.assertEqual((mode(s.dir), mode(s.meta_path), mode(s.phrase_path)), (0o700, 0o600, 0o600))

    def test_first_output_wins(self):
        s = self.legacy()
        s.record_funding("0.06", "r1", "AB" * 16)
        s.record_funding("0.01", "r2", "CD" * 16)
        self.assertTrue(s.record_funding_height("CD" * 16, 3790500))
        self.assertTrue(s.record_funding_height("AB" * 16, 3785000))
        self.assertFalse(s.record_funding_height("EF" * 16, 1))
        with mock.patch.object(ls, "block_date", lambda h, nodes=None: "2026-11-04" if h == 3784999 else "?"):
            self.assertEqual(s.birth_from_record(), (3784999, "2026-11-04", "first output"))
            code, out = self.run_cli("birth", "linux-tor")
        self.assertEqual(code, 0, out)
        self.assertEqual(s.birth(), {"height": 3784999, "date": "2026-11-04", "month": "2026-11", "method": "first output"})

    def test_fundings_with_no_height_need_a_scan(self):
        s = self.legacy()
        s.record_funding("0.06", "r1", "AB" * 16)
        with self.assertRaises(HarnessFault) as c:
            s.birth_from_record()
        self.assertIn("needs a scan", c.exception.what)
        code, out = self.run_cli("birth", "all")
        self.assertEqual(code, 1)
        self.assertIn("android-tor: no seed", out)
        self.assertEqual(s.birth()["height"], 3782025)   # left as it was

    def test_doctor_shows_the_birth_and_fails_without_one(self):
        s = self.legacy()
        out = ls.doctor(["linux-tor"], None, [])
        self.assertIn(("ok", "lane seed linux-tor: birth height 3782025, date 2026-11-03 (tip at creation)"), out)
        m = s.meta()
        m.pop("birth_height")
        s._save_meta(m)
        out = ls.doctor(["linux-tor"], None, [])
        self.assertIn("FAIL", [lvl for lvl, line in out if "birth" in line])


class FakePlatform:
    """The lane's platform with no app: digest() answers the balances given, one per read."""
    name, variant, update_method = "linux", "tor", "fake"

    def __init__(self, balances=(), home_fault=False):
        self.balances, self.reads, self.home_fault = list(balances), 0, home_fault

    def prepare(self):
        pass

    def install_candidate_fresh(self):
        pass

    def start(self, which):
        return which

    def digest(self, tag, secrets):
        self.reads += 1
        b = self.balances.pop(0) if len(self.balances) > 1 else self.balances[0]
        return {"balance": {"spendable": b, "total": b}} if b is not None else {}

    def shutdown(self):
        pass


class FakeRecipe:
    def __init__(self, phrase, home_fault):
        self.phrase, self.home_fault, self.d = phrase, home_fault, self

    def create_wallet(self):
        return {"password": "pw-not-a-word", "phrase": self.phrase}

    def _home(self):
        return "home"

    def wait(self, what, timeout):
        if self.home_fault:
            raise ProductFault("home", "the wallet's home never showed")
        return True


class LaneModes(Store):
    def setUp(self):
        super().setUp()
        self.out = os.path.join(self.root, "out")
        os.makedirs(self.out)
        self.logs = []
        for k, v in {"REL_TRUST_RESTORE_WAIT_S": "0", "REL_TRUST_RESTORE_POLL_S": "0", "REL_RUN_ID": "26.11.3-run1",
                     "REL_TRUST_START": "auto", "REL_TRUST_MODE": "update"}.items():
            p = mock.patch.dict(os.environ, {k: v})
            p.start()
            self.addCleanup(p.stop)

    def lane(self, platform, required, recipe=None):
        from core import checks
        return lane_mod.Lane(platform, lambda lane, which, surface: recipe, checks, out=self.out,
                             log=self.logs.append, required=required, funds=False)

    def seeded(self, last=None):
        s = ls.LaneSeed("linux-tor")
        s.create(FAKE, 1, "2026-11-03")
        if last is not None:
            s.record_last({"spendable": last, "total": last}, "26.11.1-run1")
        return s

    def test_no_seed_is_not_applicable(self):
        lane = self.lane(FakePlatform([0]), ["restore_ok"])
        with mock.patch.object(lane_mod.st, "pick", lambda *a, **k: None):
            self.assertIsNone(lane._pick())
        self.assertEqual((lane.mode, lane.results["restore_ok"]), ("fresh", True))
        self.assertIn("not applicable", lane.details["restore_ok"])

    def test_forced_seed_without_one_is_harness(self):
        with mock.patch.dict(os.environ, {"REL_TRUST_START": "seed"}):
            with self.assertRaises(HarnessFault):
                self.lane(FakePlatform([0]), ["restore_ok"])._pick()

    def test_restore_reaches_the_record_then_it_is_kept(self):
        seed = self.seeded(last=6000000)
        p = FakePlatform([None, 2000000, 6100000])
        lane = self.lane(p, ["restore_ok"])
        lane._pick()
        self.assertEqual(lane.mode, "seed")
        with mock.patch.dict(os.environ, {"REL_TRUST_RESTORE_WAIT_S": "60"}):
            lane._restore_ok()
        self.assertTrue(lane.results["restore_ok"], lane.details)
        self.assertEqual(p.reads, 3)
        self.assertIn("reached the 0.06 EPIC on record (run 26.11.1-run1)", lane.details["restore_ok"])
        lane.p.balances = [8100000]
        lane.p.digest("previous", {})
        lane.send_pending = __import__("decimal").Decimal("0.02")
        self.assertEqual(lane._run(lambda: 0), 0)
        # a send not seen confirmed counts as gone, with its fee
        self.assertEqual(seed.meta()["last"], dict(seed.meta()["last"], spendable="0.056", run="26.11.3-run1"))
        self.assertIsNone(seed.lock_holder())

    def test_restore_keeps_the_phrase_for_the_encrypted_store_read(self):
        self.seeded()

        class Restorer:
            def restore_wallet(self, phrase, birth):
                return {"password": "pw-not-a-word"}
        lane = self.lane(FakePlatform([0]), ["restore_ok"], Restorer())
        lane._pick()
        lane._restore()
        # the LEPIC CLI reads a desktop store from 26.10.25 by restoring from the phrase
        self.assertEqual(lane.secrets, {"password": "pw-not-a-word", "phrase": FAKE})

    def test_restore_short_of_the_record_fails_and_keeps_it(self):
        seed = self.seeded(last=6000000)
        lane = self.lane(FakePlatform([1000000]), ["restore_ok"])
        lane._pick()
        lane._restore_ok()
        self.assertFalse(lane.results["restore_ok"])
        self.assertIn("did not reach the 0.06 EPIC on record", lane.details["restore_ok"])
        self.assertEqual(lane._run(lambda: 0), 1)
        self.assertEqual(seed.meta()["last"]["spendable"], "0.06")

    def test_first_run_passes_with_what_it_found(self):
        seed = self.seeded()
        lane = self.lane(FakePlatform([0]), ["restore_ok"])
        lane._pick()
        lane._restore_ok()
        self.assertTrue(lane.results["restore_ok"])
        self.assertIn("first run", lane.details["restore_ok"])
        lane._run(lambda: 0)
        self.assertEqual(seed.meta()["last"]["spendable"], "0")

    def test_words_in_the_evidence_are_a_harness_fault_naming_the_file_only(self):
        self.seeded()
        lane = self.lane(FakePlatform([0]), ["restore_ok"])
        lane._pick()
        lane.seed.lock()
        with open(os.path.join(self.out, "driver.log"), "w") as f:
            f.write("typed: %s\n" % " ".join(FAKE.split()[4:7]))

        def body():
            lane.ok("restore_ok", "fine")
            return 0
        self.assertEqual(lane._run(body), 2)
        with open(os.path.join(self.out, "result.txt")) as f:
            res = f.read()
        self.assertIn("lane seed words found in driver.log", res)
        self.assertNoWord(res)
        with open(os.path.join(self.out, "proof.json")) as f:
            self.assertEqual(json.load(f)["fault"]["kind"], "harness")
        self.assertIsNone(lane.seed.lock_holder())

    def test_create_mode(self):
        with mock.patch.dict(os.environ, {"REL_TRUST_MODE": "create", "REL_PREVIOUS_VERSION": "26.11.2",
                                          "REL_CANDIDATE_VERSION": "26.11.3"}), \
             mock.patch.object(ls, "tip", lambda *a, **k: (3790000, "https://node.btlabs.uk")):
            r = FakeRecipe(OTHER, False)
            lane = self.lane(FakePlatform([0]), ["create_ok"], r)
            self.assertEqual(lane.main(), 0, lane.details)
            self.assertTrue(lane.results["create_ok"])
            self.assertEqual((lane.details["birth"]["height"], lane.details["birth"]["method"]), (3790000, "tip at creation"))
            self.assertIsNone(r.phrase)
            self.assertNotIn("phrase", lane.secrets)
            self.assertNoWord(json.dumps(lane.details))
            with open(os.path.join(self.out, "result.txt")) as f:
                self.assertEqual(f.read(), "PASS linux tor create 26.11.3\n")
            with open(os.path.join(self.out, "proof.json")) as f:
                self.assertIsNone(json.load(f)["previous"])
            bad = " ".join(OTHER.split()[:-1] + [OTHER.split()[0]])
            if not ls.validate(bad)[0]:
                lane = self.lane(FakePlatform([0]), ["create_ok"], FakeRecipe(bad, False))
                self.assertEqual(lane.main(), 1)
                self.assertIn("checksum", lane.details["create_ok"])
            lane = self.lane(FakePlatform([0]), ["create_ok"], FakeRecipe(OTHER, True))
            self.assertEqual(lane.main(), 1)
            self.assertFalse(lane.results["create_ok"])
            self.assertIn("home not reached", lane.details["create_ok"])

    def test_create_mode_without_a_node_still_creates(self):
        def down(*a, **k):
            raise HarnessFault("seed", "no node answered get_tip (tried x)")
        with mock.patch.dict(os.environ, {"REL_TRUST_MODE": "create", "REL_CANDIDATE_VERSION": "26.11.3"}), \
             mock.patch.object(ls, "tip", down):
            lane = self.lane(FakePlatform([0]), ["create_ok"], FakeRecipe(OTHER, False))
            self.assertEqual(lane.main(), 0, lane.details)
            self.assertIsNone(lane.details["birth"]["height"])

    def test_restore_starts_at_the_birth_height(self):
        self.seeded()
        got = []

        class Restorer:
            def restore_wallet(self, phrase, birth):
                got.append(birth)
                return {"password": "pw-not-a-word"}
        lane = self.lane(FakePlatform([0]), ["restore_ok"], Restorer())
        lane._pick()
        lane._restore()
        self.assertEqual(got[0]["height"], 1)
        self.assertEqual(lane.details["birth"], {"height": 1, "date": "2026-11-03", "method": "tip at creation"})

    def test_restore_without_a_birth_height_is_harness(self):
        s = self.seeded()
        m = s.meta()
        m.pop("birth")
        s._save_meta(m)

        class Restorer:
            def restore_wallet(self, phrase, birth):
                raise AssertionError("restored with no start")
        lane = self.lane(FakePlatform([0]), ["restore_ok"], Restorer())
        lane._pick()
        with self.assertRaises(HarnessFault) as c:
            lane._restore()
        self.assertIn("no birth height", c.exception.what)

    def test_a_funding_keeps_its_confirmed_height(self):
        from core import checks
        seed = self.seeded()
        lane = self.lane(FakePlatform([0]), ["restore_ok"])
        lane._pick()
        tx = {"slate": "AB" * 16, "height": None}
        checks._funded(lane, "0.01", tx)
        checks._funded_at(lane, tx, {"txs": [{"slate": "CD" * 16, "height": 5}, dict(tx, height=3790001)]})
        self.assertEqual(seed.meta()["fundings"][0]["height"], 3790001)
        self.assertEqual(mode(seed.meta_path), 0o600)

    def test_unknown_trust_mode_is_harness(self):
        with mock.patch.dict(os.environ, {"REL_TRUST_MODE": "both"}):
            self.assertEqual(self.lane(FakePlatform([0]), ["restore_ok"]).main(), 2)


class PhraseScreen(unittest.TestCase):
    def test_words_typed_into_fields(self):
        ws = FAKE.split()
        fields = [Node(i=i, role="text_field", name="Word %d" % (i + 1), value=w, states=frozenset())
                  for i, w in enumerate(ws[:6])]
        self.assertTrue(phrase_screen(fields))
        self.assertFalse(phrase_screen(fields[:5]))
        pasted = [Node(i=0, role="text_field", name="Recovery phrase", value=" ".join(ws), states=frozenset())]
        self.assertTrue(phrase_screen(pasted))


if __name__ == "__main__":
    unittest.main()
