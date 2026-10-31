#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The downloads folder's SHA256SUMS as it will stand once the release is live and pruned, so the
signer can sign it before anything is published (docs/RELEASING.md, "Signer").

  server_sums.py write <files dir> <manifests dir> <out>
      this run's files/SHA256SUMS (every release file, provenance.json, sbom.cdx.json) and the
      desktop installers its manifests keep from the live one (manifests/desktop-keep.json, their
      hashes from that verified manifest), sorted by name: the lines the server's
      `ls | grep -vx -e SHA256SUMS -e SHA256SUMS.sig | LC_ALL=C sort | xargs sha256sum` gives
      after prune-downloads.
  server_sums.py verify <SHA256SUMS> <SHA256SUMS.sig> <keyring> <gitlab-release.py>
      the minisign signature against the keyring (gitlab-release.py's own check).
  server_sums.py sign <SHA256SUMS> <run>/signer.json <version> <keyring>
      has the release signer sign it into SHA256SUMS.sig beside it (one approval by the owner), for a
      folder that changed after the manifests step signed it (a run without manifests, a prune
      that left another listing); the label of the keyring's rank-1 key goes in the comment.
Exit: 0 ok; 1 refused (two hashes for one name, a bad signature)."""
import importlib.util
import json
import os
import re
import sys

LINE = re.compile(r"([0-9a-f]{64})  (\S+)\Z")


def read_sums(path):
    out = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = LINE.match(line.rstrip("\n"))
            if not m:
                raise SystemExit(f"{path}: not a SHA256SUMS line: {line.rstrip()!r}")
            out[m.group(2)] = m.group(1)
    return out


def walk(o):
    if isinstance(o, dict):
        yield o
        for v in o.values():
            yield from walk(v)
    elif isinstance(o, list):
        for v in o:
            yield from walk(v)


def write(files, mdir, out):
    sums = read_sums(os.path.join(files, "SHA256SUMS"))
    kp = os.path.join(mdir, "desktop-keep.json")
    if os.path.isfile(kp):
        with open(kp, encoding="utf-8") as f:
            for e in walk(json.load(f)):
                if not isinstance(e.get("url"), str):
                    continue
                name, sha = e["url"].rsplit("/", 1)[-1], e.get("sha256")
                if not isinstance(sha, str) or not re.fullmatch(r"[0-9a-f]{64}", sha):
                    raise SystemExit(f"desktop-keep.json: {name} has no sha256")
                if sums.get(name, sha) != sha:
                    raise SystemExit(f"{name}: two hashes ({sums[name][:12]}…, {sha[:12]}…)")
                sums[name] = sha
    text = "".join(f"{sums[n]}  {n}\n" for n in sorted(sums))
    tmp = out + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, out)
    print(f"{out}: {len(sums)} files")


def verify(sums, sig, keyring, tool):
    spec = importlib.util.spec_from_file_location("gitlab_release", tool)
    gr = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gr)
    from pathlib import Path
    with open(sig, encoding="utf-8") as f, open(sums, "rb") as g:
        entry = gr.minisign_verify(f.read(), g.read(), gr.load_keyring(Path(keyring)))
    print(f"{sig}: signature ok (key {entry.get('label', '?')})")


def comment(version, keyring):
    with open(keyring, encoding="utf-8") as f:
        keys = json.load(f)["keys"]
    label = min(keys, key=lambda k: k["rank"])["label"]
    return f"Epic Cash {version} SHA256SUMS, BT Labs key {label}"


def sign(sums, signer_json, version, keyring):
    with open(signer_json, encoding="utf-8") as f:
        sj = json.load(f)
    os.environ["REL_HOSTS"] = sj["hosts"]
    spec = importlib.util.spec_from_file_location("btsign_client", sj["client"])
    client = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(client)
    job = {"op": "minisign", "file": sums, "out": "SHA256SUMS.sig", "trusted_comment": comment(version, keyring)}
    client.Client().sign(version, [job], os.path.dirname(os.path.abspath(sums)), label=f"Downloads SHA256SUMS {version}")


def main(argv):
    if len(argv) == 4 and argv[0] == "write":
        write(*argv[1:])
    elif len(argv) == 5 and argv[0] == "sign":
        try:
            sign(*argv[1:])
        except Exception as e:  # the signer refused, was unreachable, the owner did not answer
            raise SystemExit(f"{argv[1]}: not signed: {e}") from None
    elif len(argv) == 5 and argv[0] == "verify":
        try:
            verify(*argv[1:])
        except Exception as e:  # gitlab-release.Fail and friends
            raise SystemExit(f"{argv[2]}: {e}") from None
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
