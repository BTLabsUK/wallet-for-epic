#!/usr/bin/env python3
"""Merges the desktop strings into the app's ARB files, then runs gen-l10n.

The desktop's strings live in fragments, one per part of the UI, so several people can add
strings at once without editing the ARB files together:

  lib/l10n/desk/<part>.json            English: "key": "text" and "@key": {description...}
  lib/l10n/desk/<part>.<locale>.json   every other language: "key": "text" only

Every key starts with `desk` (the invoice screens keep their own `deskInv` fragments in
lib/l10n/desk_invoices/, merged by tool/desk_invoices_l10n.py). The script rewrites the `desk*`
keys that are not `deskInv*` in app_<locale>.arb: a key keeps its place, a new one is appended,
one no fragment has any more is dropped. Every other key stays as it is, so the script can run
any number of times, from anyone, in any order. The languages are the app_<locale>.arb files
present. A key missing from
a translation stays out of that ARB; gen-l10n then falls back to English and
test/l10n_test.dart fails, so translate before merging to main.

Usage: tool/desk_l10n.py [--no-gen]   (from app/)
"""

import json
import pathlib
import subprocess
import sys

APP = pathlib.Path(__file__).resolve().parent.parent
L10N = APP / "lib" / "l10n"
FRAGMENTS = L10N / "desk"
PREFIX = "desk"
OTHER = "deskInv"


def load(path: pathlib.Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def ours(key: str) -> bool:
    bare = key.lstrip("@")
    return bare.startswith(PREFIX) and not bare.startswith(OTHER)


def main() -> int:
    parts = sorted(p for p in FRAGMENTS.glob("*.json") if p.name.count(".") == 1)
    english: dict = {}
    for part in parts:
        for key, value in load(part).items():
            if not ours(key):
                sys.exit(f"{part.name}: {key} must start with {PREFIX} and not {OTHER}")
            if key in english:
                sys.exit(f"{part.name}: {key} is also in another part")
            english[key] = value
    locales = sorted(p.stem[len("app_"):] for p in L10N.glob("app_*.arb"))
    for locale in locales:
        arb = L10N / f"app_{locale}.arb"
        if locale == "en":
            wanted = dict(english)
        else:
            wanted = {}
            for part in parts:
                tr = FRAGMENTS / f"{part.stem}.{locale}.json"
                if not tr.exists():
                    continue
                for key, value in load(tr).items():
                    if key.startswith("@"):
                        continue
                    if key not in english:
                        sys.exit(f"{tr.name}: {key} is not in {part.name}")
                    wanted[key] = value
        data = {}
        for key, value in load(arb).items():
            if not ours(key):
                data[key] = value
            elif key in wanted:
                data[key] = wanted.pop(key)
        data.update(wanted)
        arb.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    keys = [k for k in english if not k.startswith("@")]
    print(f"desk_l10n: {len(keys)} keys from {len(parts)} parts, languages {', '.join(locales)}")
    if "--no-gen" not in sys.argv:
        subprocess.run(["flutter", "gen-l10n"], cwd=APP, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
