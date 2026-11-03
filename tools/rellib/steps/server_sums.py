#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The downloads folder's SHA256SUMS as it will stand once the release is live and pruned, so the
signer can sign it before anything is published (docs/RELEASING.md, "Signer").

  server_sums.py write <files dir> <manifests dir> <out>
      this run's files/SHA256SUMS (every release file, provenance.json, sbom.cdx.json) and the
      desktop installers its manifests keep from the live one (manifests/desktop-keep.json, their
      hashes from that verified manifest) and the files `live` carries (manifests/live-keep.sums),
      sorted by name: the lines the server's
      `ls | grep -vx -e SHA256SUMS -e SHA256SUMS.sig -e SHA256SUMS.new | LC_ALL=C sort | xargs sha256sum` gives
      after prune-downloads.
  server_sums.py live <downloads URL> <files dir> <version> <keyring> <release-files.py> <out>
      the live folder's files that stay once <version> is live (tools/releases/build.py keep:
      every platform and variant the run has no file for keeps its newest release, whatever the
      release's scope), as SHA256SUMS lines from the live SHA256SUMS, its signature checked
      against the keyring first. No live SHA256SUMS (HTTP 404, a first release): an empty <out>.
  server_sums.py same <files dir> <manifests dir> <SHA256SUMS>
      exit 0 when the files dir holds exactly what its SHA256SUMS lists, with those hashes, and
      `write` would give this SHA256SUMS byte for byte (the manifests step's retry: the listing
      the signer already signed still stands); exit 1 otherwise.
  server_sums.py verify <SHA256SUMS> <SHA256SUMS.sig> <keyring> <release-files.py>
      the minisign signature against the keyring (release-files.py's own check).
  server_sums.py sign <SHA256SUMS> <run>/signer.json <version> <keyring>
      has the release signer sign it into SHA256SUMS.sig beside it (one approval by the owner), for a
      folder that changed after the manifests step signed it (a run without manifests, a prune
      that left another listing); the label of the keyring's rank-1 key goes in the comment.
  server_sums.py sign-key <SHA256SUMS> <key file> <version> <keyring> <release-files.py>
      the same signature from the update key's file on this machine (release-hosts.toml
      host.signer signing_key), for a run without a signer: the keyless path that wrote the
      listing unsigned, so SHA256SUMS.sig is on the server either way (docs/rebuild-and-compare.md).
Exit: 0 ok; 1 refused (two hashes for one name, a bad signature)."""
import importlib.util
import json
import os
import re
import sys
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))

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
    lp = os.path.join(mdir, "live-keep.sums")
    if os.path.isfile(lp):
        for name, sha in read_sums(lp).items():
            if sums.get(name, sha) != sha:
                raise SystemExit(f"{name}: two hashes ({sums[name][:12]}…, {sha[:12]}…)")
            sums[name] = sha
    text = "".join(f"{sums[n]}  {n}\n" for n in sorted(sums))
    tmp = out + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
    os.replace(tmp, out)
    print(f"{out}: {len(sums)} files")


def build_py():
    spec = importlib.util.spec_from_file_location("releases_build", os.path.join(HERE, "../../releases/build.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def carried(version, live, run):
    """Of the live listing ({name: sha256}), the lines that stay beside the run's file names."""
    kept = build_py().keep(version, list(live) + list(run))
    return {n: live[n] for n in sorted(kept) if n in live and n not in run}


def fetch(url):
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise


def live(base, files, version, keyring, tool, out):
    base = base.rstrip("/")
    sums = fetch(f"{base}/SHA256SUMS")
    lines = {}
    if sums is not None:
        sig = fetch(f"{base}/SHA256SUMS.sig")
        if sig is None:
            raise SystemExit(f"{base}/SHA256SUMS.sig: not served, so the live hashes are not trusted")
        gr = release_files(tool)
        from pathlib import Path
        gr.minisign_verify(sig.decode("utf-8"), sums, gr.load_keyring(Path(keyring)))
        tmp = out + ".live"
        with open(tmp, "wb") as f:
            f.write(sums)
        try:
            listed = read_sums(tmp)
        finally:
            os.remove(tmp)
        lines = carried(version, listed, read_sums(os.path.join(files, "SHA256SUMS")))
    with open(out + ".tmp", "w", encoding="utf-8") as f:
        f.write("".join(f"{sha}  {n}\n" for n, sha in lines.items()))
    os.replace(out + ".tmp", out)
    print(f"{out}: {len(lines)} file(s) kept from the live folder" + "".join(f"\n  {n}" for n in lines))


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


def release_files(tool):
    spec = importlib.util.spec_from_file_location("release_files", tool)
    gr = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gr)
    return gr


def verify(sums, sig, keyring, tool):
    gr = release_files(tool)
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
    """release-files.py's own minisign signing (the GitHub Release's SHA256SUMS.sig), the trusted
    comment as sign() gives it, the key's label from the keyring."""
    gr = release_files(tool)
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
    elif len(argv) == 7 and argv[0] == "live":
        try:
            live(*argv[1:])
        except SystemExit:
            raise
        except Exception as e:  # unreachable, a bad signature
            raise SystemExit(f"{argv[1]}: the live SHA256SUMS: {e}") from None
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
        except Exception as e:  # release-files.Fail (no key file, wrong mode, not Ed25519)
            raise SystemExit(f"{argv[1]}: not signed: {e}") from None
    elif len(argv) == 5 and argv[0] == "verify":
        try:
            verify(*argv[1:])
        except Exception as e:  # release-files.Fail and friends
            raise SystemExit(f"{argv[2]}: {e}") from None
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
