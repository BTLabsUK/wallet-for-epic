# SPDX-License-Identifier: Apache-2.0
"""screens-check's pixel goldens: a key screen whose pixels changed against the published release is
a warning in the gate message with its before | after | diff image; other changed screens stay in the
visual diff only; a key screen missing from the catalogue says KEY_SCREENS needs updating."""
import json
import os
import sys
import tempfile
import unittest
import unittest.mock
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "steps"))

import screens_check as sc  # noqa: E402
from PIL import Image  # noqa: E402


def catalogue(root, version, shots):
    d = Path(root) / version
    (d / "img").mkdir(parents=True)
    rows = []
    for code, colour in shots.items():
        f = "img/" + code.replace("/", "_") + ".png"
        Image.new("RGB", (40, 30), colour).save(d / f)
        rows.append(json.dumps({"code": code, "file": f, "text": ["Hello"]}))
    (d / "screens.jsonl").write_text("\n".join(rows) + "\n")
    (d / "manifest.json").write_text("{}")


class KeyScreens(unittest.TestCase):
    def run_check(self, base, cur):
        with tempfile.TemporaryDirectory() as t:
            catalogue(t, "1.0", base)
            catalogue(t, "1.1", cur)
            stage = Path(t) / "stage"
            env = {"SCREENS_ROOT": t, "REL_PREVIOUS_VERSION": "1.0", "REL_RUN": "", "REL_SRC": "",
                   "REL_DRY_RUN": "0", "HOME": t}
            with unittest.mock.patch.dict(os.environ, env), unittest.mock.patch.object(sc, "publish_report", return_value=None):
                rc = sc.main(["screens_check.py", "1.1", str(stage)])
            summary = json.loads((stage / "summary.json").read_text())
            keys = [w for w in summary["warns"] if w["kind"] == "key"]
            for w in keys:
                if w.get("img"):
                    self.assertTrue((stage / "report" / w["img"]).is_file())
            return rc, summary, keys

    def test_a_changed_key_screen_warns_with_its_diff_image(self):
        all_keys = {k: (0, 0, 0) for k in sc.KEY_SCREENS}
        base = {**all_keys, "desktop/send/review-light": (255, 255, 255), "desktop/about/main": (0, 0, 0)}
        cur = {**all_keys, "desktop/send/review-light": (200, 0, 0), "desktop/about/main": (90, 90, 90)}
        rc, summary, keys = self.run_check(base, cur)
        self.assertEqual(rc, 0)
        self.assertEqual([w["code"] for w in keys], ["desktop/send/review-light"])
        self.assertIn("100.0% of pixels", keys[0]["text"])
        self.assertTrue(keys[0]["img"].startswith("img/diff-"))
        self.assertEqual(summary["diff"]["changed"], 2)
        self.assertTrue(any(ln.startswith("warn key (1)") for ln in summary["lines"]))

    def test_a_key_screen_missing_from_the_catalogue_names_the_list(self):
        shots = {k: (0, 0, 0) for k in sc.KEY_SCREENS if k != "phone/home/main"}
        _, _, keys = self.run_check(shots, shots)
        self.assertEqual(len(keys), 1)
        self.assertIn("phone/home/main: not in the catalogue", keys[0]["text"])

    def test_light_variants_count_as_key(self):
        self.assertTrue(sc.is_key("phone/send/review-light"))
        self.assertFalse(sc.is_key("phone/send/review-relay"))


if __name__ == "__main__":
    unittest.main()
