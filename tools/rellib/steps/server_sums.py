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
  server_sums.py same <files dir> <manifests dir> <SHA256SUMS>
      exit 0 when the files dir holds exactly what its SHA256SUMS lists, with those hashes, and
      `write` would give this SHA256SUMS byte for byte (the manifests step's retry: the listing
      the signer already signed still stands); exit 1 otherwise.
  server_sums.py verify <SHA256SUMS> <SHA256SUMS.sig> <keyring> <gitlab-release.py>
      the minisign signature against the keyring (gitlab-release.py's own check).
  server_sums.py sign <SHA256SUMS> <run>/signer.json <version> <keyring>
      has the release signer sign it into SHA256SUMS.sig beside it (one approval by the owner), for a
      folder that changed after the manifests step signed it (a run without manifests, a prune
      that left another listing); the label of the keyring's rank-1 key goes in the comment.
  server_sums.py sign-key <SHA256SUMS> <key file> <version> <keyring> <gitlab-release.py>
      the same signature from the update key's file on this machine (release-hosts.toml
      host.signer signing_key), for a run without a signer: the keyless path that wrote the
      listing unsigned, so SHA256SUMS.sig is on the server either way (docs/rebuild-and-compare.md).
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


def same(files, mdir, sums):
    import hashlib
    try:
        listed = read_sums(os.path.join(files, "SHA256SUMS"))
        if sorted(n for n in os.listdir(files) if n != "SHA256SUMS") != sorted(listed):
            return 1
        for name, sha in listed.items():
            h = hashlib.sha256()
            with open(os.path.join(files, name), "rb") as f:
                for chunk in iter(lambda: f.read(1 << 20), b""):
                    h.update(chunk)
            if h.hexdigest() != sha:
                return 1
        fresh = sums + ".same"
        write(files, mdir, fresh)
        try:
            with open(fresh, "rb") as f, open(sums, "rb") as g:
                return 0 if f.read() == g.read() else 1
        finally:
            os.remove(fresh)
    except (OSError, SystemExit):
        return 1


def gitlab_release(tool):
    spec = importlib.util.spec_from_file_location("gitlab_release", tool)
    gr = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gr)
    return gr


def verify(sums, sig, keyring, tool):
    gr = gitlab_release(tool)
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


def sign_key(sums, key_file, version, keyring, tool):
    """gitlab-release.py's own minisign signing (the GitHub Release's SHA256SUMS.sig), the trusted
    comment as sign() gives it, the key's label from the keyring."""
    gr = gitlab_release(tool)
    from pathlib import Path
    key = gr.load_private_key(Path(key_file).expanduser())
    keyid = gr.keyid_of(gr.raw_public(key))
    keys = gr.load_keyring(Path(keyring))
    if keyid not in keys:
        raise SystemExit(f"signing key {keyid} is not in the keyring {keyring}")
    trusted = f"Epic Cash {version} SHA256SUMS, BT Labs key {keys[keyid].get('label', keyid)}"
    with open(sums, "rb") as f:
        text = gr.minisign_sign(key, keyid, f.read(), trusted)
    out = os.path.join(os.path.dirname(os.path.abspath(sums)), "SHA256SUMS.sig")
    with open(out + ".tmp", "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(out + ".tmp", out)
    print(f"{out}: signed with key {keyid}")


def main(argv):
    if len(argv) == 4 and argv[0] == "write":
        write(*argv[1:])
    elif len(argv) == 4 and argv[0] == "same":
        sys.exit(same(*argv[1:]))
    elif len(argv) == 5 and argv[0] == "sign":
        try:
            sign(*argv[1:])
        except Exception as e:  # the signer refused, was unreachable, the owner did not answer
            raise SystemExit(f"{argv[1]}: not signed: {e}") from None
    elif len(argv) == 6 and argv[0] == "sign-key":
        try:
            sign_key(*argv[1:])
        except SystemExit:
            raise
        except Exception as e:  # gitlab-release.Fail (no key file, wrong mode, not Ed25519)
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
