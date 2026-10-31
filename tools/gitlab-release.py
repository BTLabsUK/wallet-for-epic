#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Hosts a release's files on GitLab and/or GitHub: a signed SHA256SUMS, then on GitLab the
Generic Packages registry and the Release of tag v<version> with one link per file, on GitHub the
Release of tag v<version> with every file as an asset. Runs on our own machines (no CI on either
host). Re-running changes only what differs; --dry-run changes nothing.

  tools/gitlab-release.py publish <version> <folder> [--target gitlab|github|both] [--dry-run]
                          [--project P] [--github-repo O/R] [--notes FILE]
  tools/gitlab-release.py github-update-json <update-v2.json> [--github-repo O/R] [--dry-run]
  tools/gitlab-release.py verify <SHA256SUMS> [<SHA256SUMS.sig>] [--keyring K]
  tools/gitlab-release.py pubkey [--keyring K]

publish:
  1. writes <folder>/SHA256SUMS over every top-level file (not dotfiles, update*.json,
     *.payload.json or the SHA256SUMS files themselves) and signs it into SHA256SUMS.sig;
  2. uploads each file to the project's Generic Packages registry as package <package>/<version>
     (a file already there with the same SHA-256 is skipped; a different one is refused unless
     --replace);
  3. creates or updates the Release of tag v<version> (the tag must already be on GitLab:
     tools/publish-github.sh puts it there; --ref creates it from a commit, for tests only):
     name "Epic Cash <version>", the changelog as its description, and one link per file whose
     direct path is the file name without "-<version>", so
     /-/releases/permalink/latest/downloads/<name> always serves the newest one;
  4. checks the uploads against the registry's SHA-256 and the signature against the keyring,
     and prints the permalinks.

With --target github (or both) instead of (or after) 2–4: creates or updates the GitHub Release
of tag v<version> (the tag must already be on GitHub: tools/mirror-github.sh puts it there) with
the changelog as its notes, and uploads each file as an asset named without "-<version>" and
labelled with its full name, so github.com/<owner>/<repo>/releases/latest/download/<name> always
serves the newest one. The release is made the latest one (not a draft; a prerelease only for
-rcN). An asset already there with the same SHA-256 is skipped; other bytes, or an asset that is
not in the folder, are refused unless --replace. Then it reads SHA256SUMS and its signature back
from the release and checks them.

github-update-json: puts the signed update-v2.json (tools/publish-update-json.sh checks it first)
on the latest GitHub Release as the asset update-v2.json, so
github.com/<owner>/<repo>/releases/latest/download/update-v2.json is one of the apps' update
sources: the old asset is deleted, then the file uploaded under the same name. Refused when the
repository has no latest release. The same bytes already there: nothing is changed.

GitHub writes go one at a time, at least a second apart, and nothing polls GitHub.

SHA256SUMS lists each file under its full name and, when it differs, under the name without the
version too (the same hash), so `sha256sum --ignore-missing -c SHA256SUMS` checks a download
from either kind of link.

The signature is minisign's format (ED, prehashed), made with the same Ed25519 key that signs
update.json (btlabs-public, FORMAT.md): `minisign -Vm SHA256SUMS -x SHA256SUMS.sig -P <key>`
checks it with the key `pubkey` prints, and `verify` checks it against the keyring.

Settings: the GitLab token is read from --token-file (default ~/.config/btlabs/gitlab-token), the
GitHub token from `gh auth token` with gh's own config GH_CONFIG_DIR (default ~/.config/gh-btlabs),
which must be logged in as GITHUB_USER (default btlabs-uk; any other login is refused, as in
tools/mirror-github.sh); neither token is printed. GITHUB_RELEASE_API and GITHUB_RELEASE_WEB
replace https://api.github.com and https://github.com (local tests only). The signing key is --key (default ~/.config/btlabs/signing/btlabs-2026-a.key), the
keyring --keyring (default ~/code/btlabs-public/keys/btlabs-keyring.json).
"""
from __future__ import annotations

import argparse
import base64
import fnmatch
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path

import requests
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey, Ed25519PublicKey

HOME = Path.home()
DEFAULTS = {
    "host": "https://gitlab.com",
    "project": "epic-cash-bt/wallet-for-epic",
    "github_repo": "BTLabsUK/wallet-for-epic",
    "github_user": "btlabs-uk",
    "gh_config": HOME / ".config/gh-btlabs",
    "package": "epic-cash",
    "token_file": HOME / ".config/btlabs/gitlab-token",
    "key": HOME / ".config/btlabs/signing/btlabs-2026-a.key",
    "keyring": HOME / "code/btlabs-public/keys/btlabs-keyring.json",
}
REPO = Path(__file__).resolve().parent.parent
CHANGELOGS = REPO / "fastlane/metadata/android/en-US/changelogs"
SKIP = (".*", "SHA256SUMS", "SHA256SUMS.sig", "update*.json", "*.payload.json")
VERSION_RE = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?\Z")
NAME_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._+-]*\Z")


class Fail(Exception):
    pass


def say(msg: str) -> None:
    print(msg, flush=True)


# --------------------------------------------------------------------------- signing


def keyid_of(raw_pub: bytes) -> str:
    """btlabs-public's keyid: the first 16 hex characters of SHA-256 over the raw key."""
    return hashlib.sha256(raw_pub).hexdigest()[:16]


def load_keyring(path: Path) -> dict[str, dict]:
    try:
        ring = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        raise Fail(f"cannot read keyring {path}: {e.__class__.__name__}") from None
    keys = {}
    for k in ring.get("keys", []):
        raw = base64.b64decode(k["public_key"])
        if keyid_of(raw) != k["keyid"]:
            raise Fail(f"keyring {path}: keyid {k['keyid']} does not match its key")
        keys[k["keyid"]] = {**k, "raw": raw}
    if not keys:
        raise Fail(f"keyring {path} has no keys")
    return keys


def load_private_key(path: Path) -> Ed25519PrivateKey:
    try:
        if path.stat().st_mode & 0o077:
            raise Fail(f"key file {path} is readable by group/other; chmod 600 it")
        key = serialization.load_pem_private_key(path.read_bytes(), password=None)
    except Fail:
        raise
    except Exception:  # never include the exception text: it could echo key bytes
        raise Fail(f"key file {path} is not a readable unencrypted PKCS#8 PEM key") from None
    if not isinstance(key, Ed25519PrivateKey):
        raise Fail(f"key file {path} is not an Ed25519 key")
    return key


def raw_public(key: Ed25519PrivateKey) -> bytes:
    return key.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)


def minisign_pubkey(raw_pub: bytes, keyid: str, label: str) -> str:
    """The key in minisign's public key format; minisign's key id is our keyid's 8 bytes."""
    blob = base64.b64encode(b"Ed" + bytes.fromhex(keyid) + raw_pub).decode()
    return f"untrusted comment: minisign public key of BT Labs {label} ({keyid})\n{blob}\n"


def minisign_sign(key: Ed25519PrivateKey, keyid: str, data: bytes, trusted: str) -> str:
    """A minisign signature (ED: Ed25519 over BLAKE2b-512 of the file). No timestamp in the
    trusted comment, so the same file and key always give the same bytes (Ed25519 is
    deterministic) and a re-run uploads nothing new."""
    sig = key.sign(hashlib.blake2b(data, digest_size=64).digest())
    glob = key.sign(sig + trusted.encode())
    return (
        f"untrusted comment: signature from BT Labs key {keyid}\n"
        f"{base64.b64encode(b'ED' + bytes.fromhex(keyid) + sig).decode()}\n"
        f"trusted comment: {trusted}\n"
        f"{base64.b64encode(glob).decode()}\n"
    )


def signer_client():
    """tools/signer/btsign_client.py: the release signer named by [host.signer] endpoint."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("btsign_client", REPO / "tools/signer/btsign_client.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if not mod.endpoint():
        raise Fail(f"--signer: no [host.signer] endpoint in {mod.hosts_file()}")
    return mod


def signer_minisign(mod, version: str, sums_text: str, trusted: str, dry_run: bool) -> str:
    """SHA256SUMS signed by the release signer (one approval in Telegram); a dry run asks nothing."""
    if dry_run:
        return "untrusted comment: dry run\nRUQAAAAAAAAAAA==\ntrusted comment: dry run\n\n"
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        Path(d, "SHA256SUMS").write_text(sums_text, encoding="utf-8")
        try:
            mod.Client().sign(version, [{"op": "minisign", "file": str(Path(d, "SHA256SUMS")), "out": "SHA256SUMS.sig",
                                         "trusted_comment": trusted}], d, label=f"Release SHA256SUMS {version}")
        except mod.SignerError as e:
            raise Fail(str(e)) from None
        return Path(d, "SHA256SUMS.sig").read_text(encoding="utf-8")


def minisign_verify(text: str, data: bytes, keys: dict[str, dict]) -> dict:
    """Checks a minisign signature against the keyring; returns the signing key's entry."""
    lines = text.splitlines()
    if len(lines) < 4 or not lines[2].startswith("trusted comment: "):
        raise Fail("signature file is not in minisign format")
    blob = base64.b64decode(lines[1])
    if len(blob) != 74 or blob[:2] not in (b"ED", b"Ed"):
        raise Fail("signature is not an Ed25519 minisign signature")
    keyid, sig = blob[2:10].hex(), blob[10:]
    entry = keys.get(keyid)
    if entry is None:
        raise Fail(f"signed by key {keyid}, which is not in the keyring")
    msg = hashlib.blake2b(data, digest_size=64).digest() if blob[:2] == b"ED" else data
    pub = Ed25519PublicKey.from_public_bytes(entry["raw"])
    try:
        pub.verify(sig, msg)
        pub.verify(base64.b64decode(lines[3]), sig + lines[2][len("trusted comment: "):].encode())
    except InvalidSignature:
        raise Fail("BAD SIGNATURE") from None
    return entry


# --------------------------------------------------------------------------- files


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def release_files(folder: Path, excludes: list[str]) -> list[Path]:
    out = []
    for p in sorted(folder.iterdir(), key=lambda p: p.name):
        if not p.is_file() or p.is_symlink():
            continue
        if any(fnmatch.fnmatchcase(p.name, g) for g in (*SKIP, *excludes)):
            continue
        if not NAME_RE.match(p.name):
            raise Fail(f"{p.name}: GitLab package file names take letters, digits, . _ + - only")
        out.append(p)
    if not out:
        raise Fail(f"no release files in {folder}")
    return out


def stable_name(file_name: str, version: str) -> str:
    """The file name without its version, for the latest-release permalink."""
    return file_name.replace(f"-{version}", "", 1)


def version_code(version: str) -> str:
    y, m, p = version.split("-")[0].split(".")
    return f"{int(y):02d}{int(m):02d}{int(p):02d}00"


def notes_for(version: str, notes_file: str | None, pubkey: str) -> str:
    if notes_file:
        body = Path(notes_file).read_text(encoding="utf-8").strip()
    else:
        cl = CHANGELOGS / f"{version_code(version)}.txt"
        body = cl.read_text(encoding="utf-8").strip() if cl.exists() else ""
        if not body:
            raise Fail(f"no changelog at {cl}; pass --notes FILE")
    key_lines = "\n".join(f"    {l}" for l in pubkey.strip().splitlines())
    return (
        f"{body}\n\n"
        "### Check your download\n\n"
        "`SHA256SUMS` lists every file's SHA-256; `SHA256SUMS.sig` is its minisign signature "
        "by BT Labs' release key, the same key that signs the in-app update information:\n\n"
        f"    minisign -Vm SHA256SUMS -x SHA256SUMS.sig -P {pubkey.strip().splitlines()[1]}\n"
        "    sha256sum --ignore-missing -c SHA256SUMS\n\n"
        "The key in minisign's format:\n\n"
        f"{key_lines}\n\n"
        "The keyring it comes from: "
        "https://gitlab.com/epic-cash-bt/btlabs-epic.github.io/-/raw/main/btlabs-keyring.json\n"
    )


# --------------------------------------------------------------------------- GitLab API


class GitLab:
    def __init__(self, host: str, project: str, token_file: Path, dry: bool):
        try:
            token = token_file.read_text(encoding="utf-8").strip()
        except OSError:
            raise Fail(f"no GitLab token at {token_file}") from None
        self.s = requests.Session()
        self.s.headers["PRIVATE-TOKEN"] = token
        self.host = host.rstrip("/")
        self.project = project
        self.api = f"{self.host}/api/v4/projects/{urllib.parse.quote(project, safe='')}"
        self.dry = dry

    def call(self, method: str, url: str, write: bool = False, ok404: bool = False, **kw):
        if write and self.dry:
            say(f"  [dry-run] {method} {url.replace(self.api, '<project>')}")
            return None
        timeout = kw.pop("timeout", 60)
        for attempt in range(6):
            r = self.s.request(method, url if url.startswith("http") else self.api + url,
                               timeout=timeout, **kw)
            if r.status_code == 429 or r.status_code >= 502:
                wait = int(r.headers.get("Retry-After", 2 ** attempt * 5))
                say(f"  GitLab answered {r.status_code}; retrying in {wait} s")
                time.sleep(min(wait, 300))
                if "data" in kw and hasattr(kw["data"], "seek"):
                    kw["data"].seek(0)
                continue
            if r.status_code == 404 and ok404:
                return None
            if r.status_code >= 400:
                # The body is GitLab's error text; it never contains the token.
                raise Fail(f"{method} {url.replace(self.api, '<project>')}: {r.status_code} "
                           f"{r.text[:300]}")
            return r.json() if r.content and "json" in r.headers.get("Content-Type", "") else r
        raise Fail(f"{method} {url}: still rate limited")

    def pages(self, url: str) -> list:
        out, page = [], 1
        while True:
            sep = "&" if "?" in url else "?"
            got = self.call("GET", f"{url}{sep}per_page=100&page={page}", ok404=True) or []
            out += got
            if len(got) < 100:
                return out
            page += 1


def package_url(gl: GitLab, package: str, version: str, name: str) -> str:
    return f"{gl.api}/packages/generic/{package}/{version}/{name}"


def existing_package_files(gl: GitLab, package: str, version: str) -> dict[str, list[dict]]:
    pkgs = gl.pages(f"/packages?package_type=generic&package_name={package}")
    files: dict[str, list[dict]] = {}
    for p in pkgs:
        if p["name"] == package and p["version"] == version:
            for f in gl.pages(f"/packages/{p['id']}/package_files"):
                files.setdefault(f["file_name"], []).append({**f, "package_id": p["id"]})
    return files


def upload(gl: GitLab, package: str, version: str, files: list[Path], sums: dict[str, str],
           replace: bool) -> None:
    have = existing_package_files(gl, package, version)
    for p in files:
        want = sums[p.name]
        old = have.get(p.name, [])
        if any(f.get("file_sha256") == want for f in old):
            say(f"  = {p.name} (already uploaded)")
            continue
        if old and not replace:
            raise Fail(f"{p.name} is already in package {package}/{version} with other bytes; "
                       "a published file never changes silently (--replace to swap it)")
        size = p.stat().st_size if p.exists() else 0  # a dry run writes no SHA256SUMS
        say(f"  ↑ {p.name} ({size / 1e6:.1f} MB)")
        if not gl.dry:
            with p.open("rb") as f:
                got = gl.call("PUT", package_url(gl, package, version, p.name) + "?select=package_file",
                              write=True, data=f, timeout=3600,
                              headers={"Content-Type": "application/octet-stream"})
            if isinstance(got, dict) and got.get("file_sha256") not in (None, want):
                raise Fail(f"{p.name}: GitLab stored SHA-256 {got.get('file_sha256')}, not {want}")
        else:
            gl.call("PUT", package_url(gl, package, version, p.name), write=True)
        for f in old:  # only with --replace: drop the file it replaced
            gl.call("DELETE", f"/packages/{f['package_id']}/package_files/{f['id']}", write=True)


def ensure_release(gl: GitLab, tag: str, ref: str | None, name: str, notes: str,
                   links: list[dict]) -> None:
    rel = gl.call("GET", f"/releases/{urllib.parse.quote(tag, safe='')}", ok404=True)
    if rel is None:
        if gl.call("GET", f"/repository/tags/{urllib.parse.quote(tag, safe='')}", ok404=True) is None \
                and not ref:
            raise Fail(f"tag {tag} is not on GitLab; publish it first (tools/publish-github.sh)")
        body = {"tag_name": tag, "name": name, "description": notes,
                "assets": {"links": links}}
        if ref:
            body["ref"] = ref
        say(f"  + release {tag} with {len(links)} links")
        gl.call("POST", "/releases", write=True, json=body)
        return
    if rel.get("name") != name or rel.get("description") != notes:
        say(f"  ~ release {tag}: name/description")
        gl.call("PUT", f"/releases/{tag}", write=True, json={"name": name, "description": notes})
    else:
        say(f"  = release {tag}")
    have = {l["name"]: l for l in rel.get("assets", {}).get("links", [])}
    base = f"/releases/{urllib.parse.quote(tag, safe='')}/assets/links"
    wanted = {l["name"] for l in links}
    for old in have.values():  # first, so a renamed link can take a freed URL or path
        if old["name"] not in wanted:
            say(f"  - link {old['name']}")
            gl.call("DELETE", f"{base}/{old['id']}", write=True)
    for l in links:
        old = have.get(l["name"])
        if old is None:
            say(f"  + link {l['name']}")
            gl.call("POST", base, write=True, json=l)
        elif (old["url"], old.get("link_type"), old.get("direct_asset_url", "").split("/downloads", 1)[-1]) \
                != (l["url"], l["link_type"], l["direct_asset_path"]):
            say(f"  ~ link {l['name']}")
            gl.call("PUT", f"{base}/{old['id']}", write=True, json=l)
        else:
            say(f"  = link {l['name']}")


# --------------------------------------------------------------------------- GitHub API


class GitHub:
    PAUSE = 1.0  # seconds between two writes: one at a time, never a burst

    def __init__(self, repo: str, dry: bool):
        # Only BT Labs' own login, from gh's own config: never the default gh config (another
        # account) and never a token in the environment.
        env = {k: v for k, v in os.environ.items() if k not in ("GH_TOKEN", "GITHUB_TOKEN")}
        env["GH_CONFIG_DIR"] = os.environ.get("GH_CONFIG_DIR") or str(DEFAULTS["gh_config"])
        user = os.environ.get("GITHUB_USER") or DEFAULTS["github_user"]
        try:
            login = subprocess.run(["gh", "api", "user", "--jq", ".login"], capture_output=True,
                                   text=True, check=True, timeout=60, env=env).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            raise Fail(f"gh is not logged in (GH_CONFIG_DIR={env['GH_CONFIG_DIR']})") from None
        if login != user:
            raise Fail(f"gh is logged in as {login}, not {user} (GH_CONFIG_DIR={env['GH_CONFIG_DIR']})")
        try:
            token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True,
                                   check=True, timeout=30, env=env).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            raise Fail(f"no GitHub token from gh (GH_CONFIG_DIR={env['GH_CONFIG_DIR']})") from None
        self.s = requests.Session()
        self.s.headers.update({"Authorization": f"Bearer {token}",
                               "Accept": "application/vnd.github+json",
                               "X-GitHub-Api-Version": "2022-11-28"})
        self.repo = repo
        self.web = (os.environ.get("GITHUB_RELEASE_WEB") or "https://github.com").rstrip("/")
        api = (os.environ.get("GITHUB_RELEASE_API") or "https://api.github.com").rstrip("/")
        self.api = f"{api}/repos/{repo}"
        self.dry = dry
        self.last_write = 0.0

    def call(self, method: str, url: str, write: bool = False, ok404: bool = False, **kw):
        short = url.replace(self.api, "<repo>")
        if write and self.dry:
            say(f"  [dry-run] {method} {short.split('?')[0]}")
            return None
        if write:
            time.sleep(max(0.0, self.last_write + self.PAUSE - time.monotonic()))
            self.last_write = time.monotonic()
        timeout = kw.pop("timeout", 60)
        for attempt in range(6):
            r = self.s.request(method, url if url.startswith("http") else self.api + url,
                               timeout=timeout, **kw)
            limited = r.status_code == 429 or (r.status_code == 403 and
                                               r.headers.get("X-RateLimit-Remaining") == "0")
            if limited or r.status_code >= 502:
                wait = int(r.headers.get("Retry-After", 2 ** attempt * 5))
                say(f"  GitHub answered {r.status_code}; retrying in {wait} s")
                time.sleep(min(wait, 300))
                if "data" in kw and hasattr(kw["data"], "seek"):
                    kw["data"].seek(0)
                continue
            if r.status_code == 404 and ok404:
                return None
            if r.status_code >= 400:
                raise Fail(f"{method} {short}: {r.status_code} {r.text[:300]}")
            return r.json() if r.content and "json" in r.headers.get("Content-Type", "") else r
        raise Fail(f"{method} {short}: still rate limited")

    def asset_bytes(self, asset: dict) -> bytes:
        r = self.s.get(asset["url"], headers={"Accept": "application/octet-stream"}, timeout=600)
        if r.status_code != 200:
            raise Fail(f"download of asset {asset['name']}: {r.status_code}")
        return r.content


def asset_sha256(gh: GitHub, asset: dict) -> str:
    """GitHub's own digest of an asset when it gives one, else the hash of its bytes."""
    d = asset.get("digest") or ""
    if d.startswith("sha256:"):
        return d[len("sha256:"):]
    return hashlib.sha256(gh.asset_bytes(asset)).hexdigest()


def github_plan(gh: GitHub, tag: str, ref: str | None, files: list[Path], sums: dict[str, str],
                version: str, replace: bool) -> tuple[dict | None, list[tuple]]:
    """What github_release will do: the release as it is (None when missing) and one step
    (action, asset name, file, asset on GitHub) per asset. Every refusal is raised here, before
    anything is written."""
    rel = gh.call("GET", f"/releases/tags/{urllib.parse.quote(tag, safe='')}", ok404=True)
    if rel is None and gh.call("GET", f"/git/ref/tags/{urllib.parse.quote(tag, safe='')}",
                               ok404=True) is None and not ref:
        raise Fail(f"tag {tag} is not on GitHub; mirror it first (tools/mirror-github.sh)")
    want = {stable_name(p.name, version): p for p in files}
    have = {a["name"]: a for a in (rel or {}).get("assets", [])}
    plan = []
    for n, p in want.items():
        old = have.get(n)
        if old is None:
            plan.append(("+", n, p, None))
        elif asset_sha256(gh, old) == sums[p.name]:
            plan.append(("=" if old.get("label") == p.name else "label", n, p, old))
        elif replace:
            plan.append(("~", n, p, old))
        else:
            raise Fail(f"{n} is already on the GitHub release {tag} with other bytes; "
                       "a published file never changes silently (--replace to swap it)")
    for n, old in have.items():
        if n not in want and not fnmatch.fnmatchcase(n, "update*.json"):  # github-update-json's
            if not replace:
                raise Fail(f"the GitHub release {tag} has an asset {n} that is not in the folder "
                           "(--replace removes it)")
            plan.append(("-", n, None, old))
    return rel, plan


def version_key(tag: str) -> tuple:
    m = re.match(r"v?([0-9]+)\.([0-9]+)\.([0-9]+)", tag or "")
    return tuple(int(x) for x in m.groups()) if m else ()


def github_release(gh: GitHub, tag: str, ref: str | None, name: str, notes: str,
                   rel: dict | None, plan: list[tuple], sums: dict[str, str]) -> None:
    """Creates or updates the Release of tag and carries out github_plan's steps. The release
    becomes the latest one unless it is an -rcN or a newer release is already the latest."""
    latest = gh.call("GET", "/releases/latest", ok404=True)
    newest = "-rc" not in tag and (latest is None or version_key(latest.get("tag_name")) <= version_key(tag))
    if rel is None:
        say(f"  + release {tag}" + (" (latest)" if newest else ""))
        body = {"tag_name": tag, "name": name, "body": notes, "draft": False,
                "prerelease": "-rc" in tag, "make_latest": "true" if newest else "false"}
        if ref:
            body["target_commitish"] = ref
        rel = gh.call("POST", "/releases", write=True, json=body)
    else:
        want_latest = newest and (latest or {}).get("id") != rel.get("id")
        if (rel.get("name") != name or (rel.get("body") or "") != notes or rel.get("draft")
                or bool(rel.get("prerelease")) != ("-rc" in tag) or want_latest):
            say(f"  ~ release {tag}: name/notes/latest")
            body = {"name": name, "body": notes, "draft": False, "prerelease": "-rc" in tag}
            if want_latest:
                body["make_latest"] = "true"
            gh.call("PATCH", f"/releases/{rel['id']}", write=True, json=body)
        else:
            say(f"  = release {tag}" + (" (latest)" if (latest or {}).get("id") == rel.get("id") else ""))
    for action, n, p, old in plan:
        if action == "=":
            say(f"  = {n} (already uploaded)")
            continue
        if action == "label":
            say(f"  ~ {n}: label {p.name}")
            gh.call("PATCH", f"/releases/assets/{old['id']}", write=True,
                    json={"name": n, "label": p.name})
            continue
        if action in ("-", "~"):
            say(f"  - {n} (old bytes)" if action == "~" else f"  - {n} (not in the folder)")
            gh.call("DELETE", f"/releases/assets/{old['id']}", write=True)
            if action == "-":
                continue
        size = p.stat().st_size if p.exists() else 0  # a dry run writes no SHA256SUMS
        say(f"  ↑ {n} ← {p.name} ({size / 1e6:.1f} MB)")
        if gh.dry:
            gh.call("POST", "<uploads>", write=True)
            continue
        upload_url = rel["upload_url"].split("{", 1)[0]
        q = urllib.parse.urlencode({"name": n, "label": p.name})
        with p.open("rb") as f:
            got = gh.call("POST", f"{upload_url}?{q}", write=True, data=f, timeout=3600,
                          headers={"Content-Type": "application/octet-stream",
                                   "Content-Length": str(size)})
        if isinstance(got, dict) and got.get("size") != size:
            raise Fail(f"{n}: GitHub stored {got.get('size')} bytes, not {size}")
        dg = (got or {}).get("digest") or ""
        if dg.startswith("sha256:") and dg[7:] != sums[p.name]:
            raise Fail(f"{n}: GitHub stored SHA-256 {dg[7:]}, not {sums[p.name]}")


def check_github(gh: GitHub, tag: str, files: list[Path], sums: dict[str, str], version: str,
                 sums_text: str, sig_text: str, keys: dict) -> None:
    rel = gh.call("GET", f"/releases/tags/{urllib.parse.quote(tag, safe='')}")
    have = {a["name"]: a for a in rel.get("assets", [])}
    for p in files:
        n = stable_name(p.name, version)
        if n not in have or asset_sha256(gh, have[n]) != sums[p.name]:
            raise Fail(f"{n}: the GitHub release has no asset with SHA-256 {sums[p.name]}")
    say(f"  asset SHA-256 of {len(files)} files: ok")
    got_sums = gh.asset_bytes(have["SHA256SUMS"])
    got_sig = gh.asset_bytes(have["SHA256SUMS.sig"])
    if got_sums != sums_text.encode() or got_sig != sig_text.encode():
        raise Fail("the GitHub release's SHA256SUMS or its signature differs from ours")
    entry = minisign_verify(got_sig.decode(), got_sums, keys)
    say(f"  SHA256SUMS from the release: signature ok (key {entry['label']})")
    # The public link, as a download would follow it (anonymous: a private repository or a
    # hidden account answers 404 here, which is reported, not an error).
    url = f"{gh.web}/{gh.repo}/releases/download/{tag}/SHA256SUMS"
    r = requests.get(url, timeout=60)
    say(f"  anonymous {url}: {r.status_code}"
        + (" (same bytes)" if r.status_code == 200 and r.content == sums_text.encode() else ""))


# --------------------------------------------------------------------------- commands


def cmd_publish(a) -> int:
    if not VERSION_RE.match(a.version):
        raise Fail(f"version {a.version!r} is not X.Y.Z")
    folder = Path(a.folder).resolve()
    tag = a.tag or f"v{a.version}"
    keys = load_keyring(Path(a.keyring))
    if a.signer:
        # The release signer holds the key (docs/RELEASING.md, "Signer"): its held key must be the
        # keyring's; SHA256SUMS.sig is made there after the owner's code.
        signer = signer_client()
        held = [k["keyid"] for k in signer.Client().info().get("keys", []) if k.get("held")]
        if len(held) != 1:
            raise Fail(f"the signer holds {len(held)} keys, not one")
        keyid, key = held[0], None
    else:
        key = load_private_key(Path(a.key))
        keyid = keyid_of(raw_public(key))
    if keyid not in keys:
        raise Fail(f"signing key {keyid} is not in the keyring {a.keyring}")
    label = keys[keyid].get("label", keyid)
    notes = notes_for(a.version, a.notes, minisign_pubkey(keys[keyid]["raw"], keyid, label))
    to_gitlab, to_github = a.target in ("gitlab", "both"), a.target in ("github", "both")

    dest = " and ".join(([f"{a.host}/{a.project}"] if to_gitlab else []) +
                        ([f"github.com/{a.github_repo}"] if to_github else []))
    say(f"Epic Cash {a.version}: {folder} → {dest} ({tag})")
    files = release_files(folder, a.exclude)
    sums = {p.name: sha256_file(p) for p in files}
    stables = {stable_name(n, a.version): n for n in sums}
    if len(stables) != len(sums) or any(s in sums and s != n for s, n in stables.items()):
        raise Fail("two files have the same name without the version")
    lines = {**sums, **{s: sums[n] for s, n in stables.items()}}  # both names, one hash
    sums_text = "".join(f"{lines[n]}  {n}\n" for n in sorted(lines))
    trusted = f"Epic Cash {a.version} SHA256SUMS, BT Labs key {label}"
    if a.signer:
        sig_text = signer_minisign(signer, a.version, sums_text, trusted, a.dry_run)
    else:
        sig_text = minisign_sign(key, keyid, sums_text.encode(), trusted)
    if not (a.signer and a.dry_run):
        minisign_verify(sig_text, sums_text.encode(), keys)
    gl = GitLab(a.host, a.project, Path(a.token_file), a.dry_run) if to_gitlab else None
    gh = GitHub(a.github_repo, a.dry_run) if to_github else None
    all_files = files + [folder / "SHA256SUMS", folder / "SHA256SUMS.sig"]
    sums_all = {**sums,
                "SHA256SUMS": hashlib.sha256(sums_text.encode()).hexdigest(),
                "SHA256SUMS.sig": hashlib.sha256(sig_text.encode()).hexdigest()}
    if gh:  # before anything is written, as for GitLab below
        gh_rel, gh_steps = github_plan(gh, tag, a.ref, all_files, sums_all, a.version, a.replace)
    if gl:
        have = existing_package_files(gl, a.package, a.version)
        for n, want in sums.items():  # before anything is written: a refused run leaves no trace
            if have.get(n) and not a.replace and not any(f.get("file_sha256") == want for f in have[n]):
                raise Fail(f"{n} is already in package {a.package}/{a.version} with other bytes; "
                           "a published file never changes silently (--replace to swap it)")
    for name, text in (("SHA256SUMS", sums_text), ("SHA256SUMS.sig", sig_text)):
        path = folder / name
        same = path.exists() and path.read_text(encoding="utf-8") == text
        if a.dry_run:
            say(f"  [dry-run] {'keep' if same else 'write'} {name}")
        elif not same:
            path.write_text(text, encoding="utf-8")
            say(f"  wrote {name}")
    say(sums_text.rstrip())

    if gl:
        gitlab_publish(a, gl, tag, notes, all_files, sums_all, sums_text, sig_text, keys)
    if gh:
        say("GitHub release:")
        github_release(gh, tag, a.ref, f"Epic Cash {a.version}", notes, gh_rel, gh_steps,
                       sums_all)
        if not a.dry_run:
            say("Check (GitHub):")
            check_github(gh, tag, all_files, sums_all, a.version, sums_text, sig_text, keys)
        base = f"https://github.com/{a.github_repo}/releases"
        say("Links (GitHub):")
        say(f"  release page   {base}/tag/{tag}")
        say(f"  latest release {base}/latest")
        for p in all_files:
            say(f"  {base}/download/{tag}/{stable_name(p.name, a.version)}")
        say("  newest of each file:")
        for p in all_files:
            say(f"  {base}/latest/download/{stable_name(p.name, a.version)}")
    return 0


def gitlab_publish(a, gl: GitLab, tag: str, notes: str, all_files: list[Path],
                   sums_all: dict[str, str], sums_text: str, sig_text: str, keys: dict) -> None:
    say("Packages:")
    upload(gl, a.package, a.version, all_files, sums_all, a.replace)

    links = []
    for p in all_files:
        stable = stable_name(p.name, a.version)
        links.append({
            "name": p.name,
            "url": package_url(gl, a.package, a.version, p.name),
            "direct_asset_path": f"/{stable}",
            "link_type": "other" if p.name.startswith("SHA256SUMS") else "package",
        })
    say("Release:")
    ensure_release(gl, tag, a.ref, f"Epic Cash {a.version}", notes, links)
    if not a.dry_run:
        say("Check:")
        have = existing_package_files(gl, a.package, a.version)
        for n, want in sums_all.items():
            if not any(f.get("file_sha256") == want for f in have.get(n, [])):
                raise Fail(f"{n}: the registry has no file with SHA-256 {want}")
        say(f"  registry SHA-256 of {len(sums_all)} files: ok")
        # Through the release permalink, as a download would. On a private project the web path
        # can answer a sign-in redirect or a Cloudflare challenge even with the token: then the
        # package URL behind it.
        via = "the release permalink"
        dl = f"{gl.host}/{a.project}/-/releases/{tag}/downloads"
        got = [gl.s.get(f"{dl}/{n}", timeout=60) for n in ("SHA256SUMS", "SHA256SUMS.sig")]
        if any(r.status_code != 200 for r in got):
            via = f"the package URL (the permalink answered {got[0].status_code})"
            got = [gl.s.get(package_url(gl, a.package, a.version, n), timeout=60)
                   for n in ("SHA256SUMS", "SHA256SUMS.sig")]
        if got[0].content != sums_text.encode() or got[1].content != sig_text.encode():
            raise Fail("the release's SHA256SUMS or its signature differs from ours")
        entry = minisign_verify(got[1].text, got[0].content, keys)
        say(f"  SHA256SUMS via {via}: signature ok (key {entry['label']})")

    proj = f"{gl.host}/{a.project}"
    say("Permalinks:")
    say(f"  release page   {proj}/-/releases/{tag}")
    say(f"  latest release {proj}/-/releases/permalink/latest")
    for l in links:
        say(f"  {proj}/-/releases/{tag}/downloads{l['direct_asset_path']}")
    say("  newest of each file:")
    for l in links:
        say(f"  {proj}/-/releases/permalink/latest/downloads{l['direct_asset_path']}")


def cmd_github_update_json(a) -> int:
    """The signed update-v2.json as the asset update-v2.json on the latest GitHub Release."""
    path, name = Path(a.file), "update-v2.json"
    try:
        data = path.read_bytes()
        env = json.loads(data)
    except (OSError, ValueError) as e:
        raise Fail(f"cannot read {path}: {e.__class__.__name__}") from None
    if not isinstance(env, dict) or "payload" not in env or "signatures" not in env:
        raise Fail(f"{path} is not a signed manifest (payload + signatures)")
    want = hashlib.sha256(data).hexdigest()
    gh = GitHub(a.github_repo, a.dry_run)
    rel = gh.call("GET", "/releases/latest", ok404=True)
    if rel is None:
        raise Fail(f"github.com/{a.github_repo} has no latest release: publish one first "
                   "(publish --target github)")
    tag = rel["tag_name"]
    say(f"{name} ({want}) → github.com/{a.github_repo} latest release {tag}")
    old = next((x for x in rel.get("assets", []) if x["name"] == name), None)
    if old is not None and asset_sha256(gh, old) == want:
        say(f"  = {name} (already there)")
        return 0
    if old is not None:
        say(f"  - {name} (old bytes)")
        gh.call("DELETE", f"/releases/assets/{old['id']}", write=True)
    say(f"  ↑ {name} ({len(data)} bytes)")
    if gh.dry:
        gh.call("POST", "<uploads>", write=True)
        return 0
    upload_url = rel["upload_url"].split("{", 1)[0]
    got = gh.call("POST", f"{upload_url}?{urllib.parse.urlencode({'name': name})}", write=True,
                  data=data, timeout=300, headers={"Content-Type": "application/json"})
    if not isinstance(got, dict) or got.get("size") != len(data):
        raise Fail(f"{name}: GitHub stored {(got or {}).get('size')} bytes, not {len(data)}")
    if asset_sha256(gh, got) != want:
        raise Fail(f"{name}: GitHub stored other bytes than {want}")
    say(f"  {name} on {tag}: ok")
    say(f"  {gh.web}/{a.github_repo}/releases/latest/download/{name}")
    return 0


def cmd_verify(a) -> int:
    keys = load_keyring(Path(a.keyring))
    sums = Path(a.sums)
    sig = Path(a.sig or f"{a.sums}.sig")
    entry = minisign_verify(sig.read_text(encoding="utf-8"), sums.read_bytes(), keys)
    say(f"{sums}: signature ok, BT Labs key {entry['label']} ({entry['keyid']})")
    return 0


def cmd_pubkey(a) -> int:
    for k in load_keyring(Path(a.keyring)).values():
        sys.stdout.write(minisign_pubkey(k["raw"], k["keyid"], k.get("label", k["keyid"])))
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("publish", help="sums, signature, packages, release")
    p.add_argument("version")
    p.add_argument("folder")
    p.add_argument("--dry-run", action="store_true", help="change nothing, say what would change")
    p.add_argument("--host", default=DEFAULTS["host"])
    p.add_argument("--target", choices=("gitlab", "github", "both"), default="gitlab",
                   help="where the release goes (default gitlab)")
    p.add_argument("--project", default=DEFAULTS["project"])
    p.add_argument("--github-repo", default=DEFAULTS["github_repo"], help="owner/repo on GitHub")
    p.add_argument("--package", default=DEFAULTS["package"])
    p.add_argument("--tag", help="default v<version>")
    p.add_argument("--ref", help="create the tag from this commit (sandbox tests only)")
    p.add_argument("--notes", help="release description (default: the fastlane changelog)")
    p.add_argument("--exclude", action="append", default=[], help="file name glob to leave out")
    p.add_argument("--replace", action="store_true", help="swap a file uploaded with other bytes")
    p.add_argument("--token-file", default=str(DEFAULTS["token_file"]))
    p.add_argument("--key", default=str(DEFAULTS["key"]))
    p.add_argument("--signer", action="store_true",
                   help="sign SHA256SUMS with the release signer ([host.signer] endpoint) instead of --key")
    p.add_argument("--keyring", default=str(DEFAULTS["keyring"]))
    u = sub.add_parser("github-update-json", help="update-v2.json onto the latest GitHub Release")
    u.add_argument("file")
    u.add_argument("--github-repo", default=DEFAULTS["github_repo"], help="owner/repo on GitHub")
    u.add_argument("--dry-run", action="store_true", help="change nothing, say what would change")
    v = sub.add_parser("verify", help="check SHA256SUMS.sig against the keyring")
    v.add_argument("sums")
    v.add_argument("sig", nargs="?")
    v.add_argument("--keyring", default=str(DEFAULTS["keyring"]))
    k = sub.add_parser("pubkey", help="the keyring's keys in minisign's format")
    k.add_argument("--keyring", default=str(DEFAULTS["keyring"]))
    a = ap.parse_args(argv)
    try:
        return {"publish": cmd_publish, "github-update-json": cmd_github_update_json,
                "verify": cmd_verify, "pubkey": cmd_pubkey}[a.cmd](a)
    except Fail as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
