#!/usr/bin/env python3
"""Merges the desktop strings into the app's ARB files, then runs gen-l10n.

The desktop's strings live in fragments, one per part of the UI, so several people can add
strings at once without editing the ARB files together:

  lib/l10n/desk/<part>.json                  English: "key": "text" and "@key": {description...}
  lib/l10n/desk/<part>.<locale>.json         every other language: "key": "text" only
  lib/l10n/desk_invoices/<part>[.<locale>].json   the same for the invoice screens

Keys in desk/ start with `desk` but not `deskInv`; keys in desk_invoices/ start with `deskInv`.
The script rewrites those keys in app_<locale>.arb in place: a key keeps its place and a new one
is appended. A `desk*` key no fragment has any more is dropped; a `deskInv*` key without a
fragment stays (a few were added to the ARB files directly). Every other key stays as it is, so
the script can run any number of times, from anyone, in any order, and the ARB files are not
reordered (tool/desk_invoices_l10n.py, the older script, re-sorts its keys; use this one). The
languages are the app_<locale>.arb files present. A key missing from a translation stays out of
that ARB; gen-l10n then falls back to English and test/l10n_test.dart fails, so translate before
merging to main.

Usage: tool/desk_l10n.py [--no-gen]   (from app/)
"""

import json
import pathlib
import subprocess
import sys

APP = pathlib.Path(__file__).resolve().parent.parent
L10N = APP / "lib" / "l10n"

# (folder, owns a key, drops an owned key no fragment has)
GROUPS = [
    (L10N / "desk", lambda k: k.startswith("desk") and not k.startswith("deskInv"), True),
    (L10N / "desk_invoices", lambda k: k.startswith("deskInv"), False),
]


def load(path: pathlib.Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def merge(arbs: dict, folder: pathlib.Path, owns, drop: bool) -> int:
    parts = sorted(p for p in folder.glob("*.json") if p.name.count(".") == 1)
    english: dict = {}
    for part in parts:
        for key, value in load(part).items():
            if not owns(key.lstrip("@")):
                sys.exit(f"{folder.name}/{part.name}: {key} does not belong in {folder.name}/")
            if key in english:
                sys.exit(f"{folder.name}/{part.name}: {key} is also in another part")
            english[key] = value
    for locale, data in arbs.items():
        if locale == "en":
            wanted = dict(english)
        else:
            wanted = {}
            for part in parts:
                tr = folder / f"{part.stem}.{locale}.json"
                if not tr.exists():
                    continue
                for key, value in load(tr).items():
                    if key.startswith("@"):
                        continue
                    if key not in english:
                        sys.exit(f"{folder.name}/{tr.name}: {key} is not in {part.name}")
                    wanted[key] = value
        out = {}
        for key, value in data.items():
            if not owns(key.lstrip("@")):
                out[key] = value
            elif key in wanted:
                out[key] = wanted.pop(key)
            elif not drop:
                out[key] = value
        out.update(wanted)
        arbs[locale] = out
    return len([k for k in english if not k.startswith("@")])


def main() -> int:
    locales = sorted(p.stem[len("app_"):] for p in L10N.glob("app_*.arb"))
    arbs = {locale: load(L10N / f"app_{locale}.arb") for locale in locales}
    counts = [f"{merge(arbs, folder, owns, drop)} keys in {folder.name}/" for folder, owns, drop in GROUPS]
    for locale, data in arbs.items():
        text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
        arb = L10N / f"app_{locale}.arb"
        if arb.read_text(encoding="utf-8") != text:
            arb.write_text(text, encoding="utf-8")
    print(f"desk_l10n: {', '.join(counts)}; languages {', '.join(locales)}")
    if "--no-gen" not in sys.argv:
        subprocess.run(["flutter", "gen-l10n"], cwd=APP, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
