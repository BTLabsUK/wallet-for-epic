#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Merges the desktop invoice strings into the app's ARB files, then runs gen-l10n.

The strings of the desktop invoice screens live in fragments, one per part of the UI, so
several people can add strings at once without editing the ARB files together:

  lib/l10n/desk_invoices/<part>.json        English: "key": "text" and "@key": {description...}
  lib/l10n/desk_invoices/<part>.<locale>.json   de, pl, ru, zh, th: "key": "text" only

Every key starts with `deskInv`. The script drops every `deskInv*` key from app_<locale>.arb
and appends the fragments' keys again, sorted by part then as written, so it can run any number
of times, from anyone, in any order. A key missing from a translation stays out of that ARB;
gen-l10n then falls back to English and test/l10n_test.dart fails, so translate before merging
to main.

Usage: tool/desk_invoices_l10n.py [--no-gen]   (from app/)
"""

import json
import pathlib
import subprocess
import sys

APP = pathlib.Path(__file__).resolve().parent.parent
L10N = APP / "lib" / "l10n"
FRAGMENTS = L10N / "desk_invoices"
LOCALES = ["en", "de", "pl", "ru", "zh", "th"]
PREFIX = "deskInv"


def load(path: pathlib.Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parts = sorted(p for p in FRAGMENTS.glob("*.json") if p.name.count(".") == 1)
    english: dict = {}
    for part in parts:
        for key, value in load(part).items():
            bare = key.lstrip("@")
            if not bare.startswith(PREFIX):
                sys.exit(f"{part.name}: {key} does not start with {PREFIX}")
            if key in english:
                sys.exit(f"{part.name}: {key} is also in another part")
            english[key] = value
    for locale in LOCALES:
        arb = L10N / f"app_{locale}.arb"
        data = {k: v for k, v in load(arb).items() if not k.lstrip("@").startswith(PREFIX)}
        if locale == "en":
            data.update(english)
        else:
            for part in parts:
                tr = FRAGMENTS / f"{part.stem}.{locale}.json"
                if not tr.exists():
                    continue
                for key, value in load(tr).items():
                    if key in english and not key.startswith("@"):
                        data[key] = value
        arb.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    keys = [k for k in english if not k.startswith("@")]
    print(f"desk_invoices_l10n: {len(keys)} keys from {len(parts)} parts")
    if "--no-gen" not in sys.argv:
        subprocess.run(["flutter", "gen-l10n"], cwd=APP, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
