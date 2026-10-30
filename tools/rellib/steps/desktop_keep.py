#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The desktop entries a release without every desktop build keeps from the live manifest.

A desktop reads only its own system's entry, and an entry missing for its system shows "no update
information" (desk_update.dart). So a release that leaves Windows or macOS out (`--only android`, a
Linux fix) must carry those systems' live entries forward unchanged: same version, file, sha256
and size, still served from downloads/ (prune-downloads keeps every file a manifest names).

Reads the live old-format update.json (app/tool/config/old-update.toml), verifies it against the
real keyring (also in a TEST run: the live file is the real one), and writes to <out> the entries
of the systems this run has no file for: {"desktop": {...}, "notor": {"desktop": {...}}}. A system
the live manifest does not offer either stays out. Writes nothing when every system is here.

Usage: desktop_keep.py <src checkout> <files dir> <version> <btlabs-public> <out.json>
Exit: 0 written or not needed; 1 the live manifest could not be read or did not verify."""
import base64
import json
import os
import subprocess
import sys
import tomllib
import urllib.request

FILES = {"windows": "epic-cash-desktop-{v}{n}-windows-x64-setup.exe",
         "linux": "EpicCashDesktop-{v}{n}-x86_64.AppImage",
         "macos": "EpicCashDesktop-{v}{n}-macos.dmg"}


def main(src, files, version, bp, out):
    missing = {n: [s for s, pat in FILES.items()
                   if not os.path.isfile(os.path.join(files, pat.format(v=version, n=n)))]
               for n in ("", "-notor")}
    if not any(missing.values()):
        print("every desktop system has a file in this run: nothing kept from the live manifest")
        return 0
    url = tomllib.load(open(os.path.join(src, "app/tool/config/old-update.toml"), "rb"))["old_update"]["manifest"]
    tmp = out + ".live"
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            open(tmp, "wb").write(r.read())
    except Exception as e:  # noqa: BLE001
        print(f"live manifest {url} unreadable: {e}", file=sys.stderr)
        return 1
    rc = subprocess.run([sys.executable, os.path.join(bp, "tool/btlabs_sign.py"), "verify", "--type", "update",
                         "--keyring", os.path.join(bp, "keys/btlabs-keyring.json"), "--envelope", tmp]).returncode
    if rc != 0:
        print(f"live manifest {url} does not verify against the real keyring: nothing carried", file=sys.stderr)
        return 1
    live = json.loads(base64.b64decode(json.load(open(tmp))["payload"]))
    os.remove(tmp)
    keep = {"desktop": {}, "notor": {"desktop": {}}}
    for n, systems in missing.items():
        have = (live.get("notor") or {}).get("desktop") if n else live.get("desktop")
        dest = keep["notor"]["desktop"] if n else keep["desktop"]
        for s in systems:
            e = (have or {}).get(s)
            if isinstance(e, dict) and e.get("url"):
                dest[s] = e
                print(f"kept from the live manifest (serial {live.get('serial')}): {s}{n} {e.get('version')} {e['url'].rsplit('/', 1)[-1]}")
            else:
                print(f"{s}{n}: no file in this run and none in the live manifest: left out")
    json.dump(keep, open(out, "w"), indent=1)
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 6:
        print(__doc__.split("Usage: ")[1], file=sys.stderr)
        sys.exit(64)
    sys.exit(main(*sys.argv[1:]))
