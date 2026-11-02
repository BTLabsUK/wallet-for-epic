# SPDX-License-Identifier: Apache-2.0
"""tools/l10n sync and check (tlib/l10n.py).
    python3 -m unittest discover -s tools/tlib/tests"""
import json
import os
import shutil
import tempfile
import unittest

import support
from tlib import l10n


def put(root, rel, data):
    support.write(root, rel, json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def text(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def get(root, rel):
    with open(os.path.join(root, rel), encoding="utf-8") as f:
        return json.load(f)


D = "app/lib/l10n"


class SyncTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp(prefix="tlib-l10n-")
        self.addCleanup(shutil.rmtree, self.root)
        put(self.root, f"{D}/app_en.arb", {
            "@@locale": "en", "hello": "Hello {name}", "@hello": {"description": "greeting"},
            "count": "{n, plural, one{{n} item} other{{n} items}}", "newKey": "New text",
            "deskTitle": "Wallet", "@deskTitle": {"description": "t"},
            "deskInvOld": "Invoice"})
        put(self.root, f"{D}/app_de.arb", {
            "@@locale": "de", "hello": "Hallo {name}", "count": "{n, plural, one{{n} Ding} other{{n} Dinge}}",
            "stale": "Alt", "@stale": {"description": "gone"}, "deskTitle": "Wallet-DE", "deskInvOld": "Rechnung"})
        put(self.root, f"{D}/app_pl.arb", {
            "@@locale": "pl", "hello": "Cześć {imie}", "count": "{n, plural, one{{n}} few{{n}} many{{n}} other{{n}}}",
            "newKey": "Nowy tekst", "deskTitle": "Portfel", "deskInvOld": "Faktura"})
        put(self.root, f"{D}/desk/wallet.json", {"deskTitle": "Wallet", "@deskTitle": {"description": "t"},
                                                 "deskSend": "Send", "@deskSend": {"description": "s"}})
        put(self.root, f"{D}/desk/wallet.de.json", {"deskTitle": "Wallet-DE", "deskOld": "x"})
        put(self.root, f"{D}/desk/gone.de.json", {"deskGone": "weg"})
        self.s = l10n.Strings(self.root)

    def test_check_before(self):
        rep = self.s.check()
        self.assertEqual(rep["missing"]["de"], ["newKey"])
        self.assertEqual(rep["extra"]["de"], ["stale"])
        self.assertEqual([(loc, k) for loc, k, _ in rep["placeholders"]], [("pl", "hello")])

    def test_sync(self):
        rep = self.s.sync(gen=False)
        de = get(self.root, f"{D}/app_de.arb")
        en = get(self.root, f"{D}/app_en.arb")
        # the template's keys, in English where missing; stale ones gone, metadata included
        self.assertEqual(de["newKey"], "New text")
        self.assertNotIn("stale", de)
        self.assertNotIn("@stale", de)
        self.assertEqual(de["hello"], "Hallo {name}")  # translated text is never touched
        # desk fragments: the missing key in the fragment (English), the stale one out
        frag = get(self.root, f"{D}/desk/wallet.de.json")
        self.assertEqual(frag, {"deskTitle": "Wallet-DE", "deskSend": "Send"})
        # a translation found only in the ARB file moves into the new fragment
        self.assertEqual(get(self.root, f"{D}/desk/wallet.pl.json"), {"deskTitle": "Portfel", "deskSend": "Send"})
        self.assertFalse(os.path.exists(os.path.join(self.root, D, "desk/gone.de.json")))
        # merged into the ARB files: English gets the fragment's key too, deskInv* without a fragment stays
        self.assertEqual(en["deskSend"], "Send")
        self.assertEqual(de["deskSend"], "Send")
        self.assertEqual(de["deskInvOld"], "Rechnung")
        self.assertEqual(set(k for k in de if not k.startswith("@")), set(k for k in en if not k.startswith("@")))
        # the list of what to translate
        self.assertEqual(get(self.root, f"{D}/untranslated.json"),
                         {"de": ["deskSend", "newKey"], "pl": ["deskSend"]})
        self.assertIn(("pl", "hello"), [(loc, k) for loc, k, _ in rep["placeholders"]])
        lines = l10n.report_lines(self.s, rep)
        self.assertIn("  deskSend -> lib/l10n/desk/wallet.de.json", lines)
        self.assertIn("  newKey -> lib/l10n/app_de.arb", lines)

    def test_sync_again_changes_nothing_and_a_translation_leaves_the_list(self):
        self.s.sync(gen=False)
        before = {p: text(os.path.join(self.root, D, p))
                  for p in ("app_de.arb", "app_pl.arb", "untranslated.json")}
        rep = self.s.sync(gen=False)
        self.assertEqual(rep["changed"], [])
        for p, was in before.items():
            self.assertEqual(text(os.path.join(self.root, D, p)), was, p)
        put(self.root, f"{D}/desk/wallet.de.json", {"deskTitle": "Wallet-DE", "deskSend": "Senden"})
        self.s.sync(gen=False)
        self.assertEqual(get(self.root, f"{D}/untranslated.json")["de"], ["newKey"])
        self.assertEqual(get(self.root, f"{D}/app_de.arb")["deskSend"], "Senden")

    def test_check_after(self):
        self.s.sync(gen=False)
        rep = self.s.check()
        self.assertEqual(rep["missing"], {"de": [], "pl": []})
        self.assertEqual(rep["extra"], {"de": [], "pl": []})
        self.assertEqual(rep["untranslated"]["de"], ["deskSend", "newKey"])

    def test_placeholders(self):
        self.assertEqual(l10n.placeholders("{n, plural, one{{n} item} other{{n} of {total}}}"), {"n", "total"})
        self.assertEqual(l10n.placeholders("Plain {a} and {b}"), {"a", "b"})
        with self.assertRaises(ValueError):
            l10n.placeholders("broken {a")


class RepositoryTest(unittest.TestCase):
    def test_the_repository_is_in_step(self):
        """tools/l10n check on this checkout: nothing missing or stale (what l10n_test checks)."""
        root = os.path.dirname(support.TOOLS)
        if not os.path.exists(os.path.join(root, D, "app_en.arb")):
            self.skipTest("no app here")
        rep = l10n.Strings(root).check()
        for kind in ("missing", "extra"):
            self.assertEqual({k: v for k, v in rep[kind].items() if v}, {}, f"{kind}: run tools/l10n sync")


if __name__ == "__main__":
    unittest.main()
