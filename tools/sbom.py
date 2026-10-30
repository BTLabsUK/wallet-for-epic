#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Writes a CycloneDX 1.5 SBOM (JSON) of a release from its lockfiles.

  tools/sbom.py --version 26.11.0 [--pubspec-lock app/pubspec.lock]
                [--cargo-lock app/third_party/lepic/Cargo.lock] [--out sbom.cdx.json]

Components: every package in the app's pubspec.lock (pkg:pub, with the lock's sha256 for hosted
packages) and every crate in LEPIC's Cargo.lock (pkg:cargo, with its registry checksum; a git
source keeps its repository and commit). The metadata names the app, its version and the LEPIC and
lepic-flutter pins (tools/lepic.rev, tools/lepic-flutter.rev). The output is deterministic: sorted,
no random serial, and the timestamp is SOURCE_DATE_EPOCH when set, else left out, so two runs on
the same tree give the same bytes. A release ships it next to the files it covers, inside
SHA256SUMS, so the signed checksums cover it too (docs/rebuild-and-compare.md).
"""
import argparse
import datetime as dt
import hashlib
import json
import os
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def pub_packages(text):
    """The packages of a pubspec.lock: [{name, version, source, sha256, url, git}], sorted by name."""
    pkgs, cur, sect = [], None, None
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        key, _, val = line.strip().partition(":")
        val = val.strip().strip('"')
        if indent == 0:
            sect = key
            continue
        if sect != "packages":
            continue
        if indent == 2:
            cur = {"name": key, "version": "", "source": "", "sha256": "", "url": "", "git": ""}
            pkgs.append(cur)
        elif indent == 4 and cur is not None and key in ("version", "source"):
            cur[key] = val
        elif indent == 6 and cur is not None:
            if key == "sha256":
                cur["sha256"] = val
            elif key == "url":
                cur["url"] = val
            elif key == "resolved-ref":
                cur["git"] = val
    return sorted(pkgs, key=lambda p: p["name"])


def cargo_packages(text):
    """The crates of a Cargo.lock, sorted by name and version; local workspace crates are skipped."""
    out = []
    for p in tomllib.loads(text).get("package", []):
        if "source" not in p:
            continue
        out.append({"name": p["name"], "version": p["version"], "source": p["source"],
                    "checksum": p.get("checksum", "")})
    return sorted(out, key=lambda p: (p["name"], p["version"]))


def pub_component(p):
    c = {"type": "library", "name": p["name"], "version": p["version"],
         "purl": f"pkg:pub/{p['name']}@{p['version']}", "bom-ref": f"pub:{p['name']}@{p['version']}"}
    if p["sha256"]:
        c["hashes"] = [{"alg": "SHA-256", "content": p["sha256"]}]
    if p["source"] == "git" and p["url"]:
        c["externalReferences"] = [{"type": "vcs", "url": f"{p['url']}#{p['git']}" if p["git"] else p["url"]}]
    if p["source"] == "sdk":
        c["properties"] = [{"name": "pub:source", "value": "sdk (ships with the pinned Flutter SDK)"}]
    return c


def cargo_component(p):
    ref = f"cargo:{p['name']}@{p['version']}"
    c = {"type": "library", "name": p["name"], "version": p["version"],
         "purl": f"pkg:cargo/{p['name']}@{p['version']}", "bom-ref": ref}
    if p["checksum"]:
        c["hashes"] = [{"alg": "SHA-256", "content": p["checksum"]}]
    if p["source"].startswith("git+"):
        c["externalReferences"] = [{"type": "vcs", "url": p["source"][4:]}]
    return c


def read_pin(name):
    path = ROOT / "tools" / name
    return path.read_text(encoding="utf-8").strip() if path.is_file() else ""


def sbom(version, pub_text, cargo_text, lepic_rev="", binding_rev="", epoch=None):
    comps = [pub_component(p) for p in pub_packages(pub_text)]
    comps += [cargo_component(p) for p in cargo_packages(cargo_text)]
    props = [{"name": "btlabs:lepic.rev", "value": lepic_rev},
             {"name": "btlabs:lepic-flutter.rev", "value": binding_rev}]
    meta = {"component": {"type": "application", "name": "Epic Wallet", "version": version,
                          "bom-ref": f"app:epic-wallet@{version}"},
            "properties": [p for p in props if p["value"]]}
    if epoch is not None:
        meta["timestamp"] = dt.datetime.fromtimestamp(int(epoch), dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    body = {"bomFormat": "CycloneDX", "specVersion": "1.5", "version": 1, "metadata": meta, "components": comps}
    # A serial derived from the content, so it is stable for the same inputs (CycloneDX wants a urn:uuid).
    digest = hashlib.sha256(json.dumps(body, sort_keys=True).encode()).hexdigest()
    body["serialNumber"] = "urn:uuid:{}-{}-5{}-8{}-{}".format(digest[:8], digest[8:12], digest[13:16],
                                                          digest[17:20], digest[20:32])
    return body


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--version", required=True)
    ap.add_argument("--pubspec-lock", default=str(ROOT / "app/pubspec.lock"))
    ap.add_argument("--cargo-lock", default=str(ROOT / "app/third_party/lepic/Cargo.lock"))
    ap.add_argument("--out", default="-")
    a = ap.parse_args(argv)
    if not re.fullmatch(r"\d+\.\d+\.\d+(-r\d+)?", a.version):
        sys.exit(f"sbom: version {a.version!r} is not YY.MM.patch")
    doc = sbom(a.version, Path(a.pubspec_lock).read_text(encoding="utf-8"),
               Path(a.cargo_lock).read_text(encoding="utf-8"), read_pin("lepic.rev"),
               read_pin("lepic-flutter.rev"), os.environ.get("SOURCE_DATE_EPOCH"))
    text = json.dumps(doc, indent=1, sort_keys=True) + "\n"
    if a.out == "-":
        sys.stdout.write(text)
    else:
        Path(a.out).write_text(text, encoding="utf-8")
        print(f"sbom: {len(doc['components'])} components -> {a.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
