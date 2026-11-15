#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Server side of tools/rel's version folders (docs/RELEASING.md, "Rollback"). Runs ON the
download server as root (stdlib only, python3), sent over ssh on stdin:

    ssh <host> sudo -n env R=... API=... python3 - <command> [args] < relsrv.py

Layout under R (default /srv/examples/epic-cash-wallets, served by nginx):

    versions/<v>/downloads/   every file the release's page links, SHA256SUMS(.sig), provenance, sbom
    versions/<v>/index.html   the release page as it was deployed
    versions/<v>/update.json, update-v2.json   the release's signed manifests as published
    versions/<v>/spare/<serial>/update.json, update-v2.json   (0700) pre-signed pairs of this
                              release, each with a serial the spares of the other release sit
                              between, so a rollback and a roll-forward always find one above live
    versions/.history         versions in publish order, one per line
    current                   symlink to versions/<v> (the live release)
    downloads                 symlink to current/downloads
    index.html, update.json   real files (rsync of the page owns the first), installed from the version
    API (/srv/epiccash-api/v1/update.json)   the update-v2.json, a real file

Files shared between releases are hard links (same disk blocks). Nothing here deletes a file of
the live release. Commands (output: one line per fact; exit 0 ok, 1 refused, nothing half done):

    begin <v>                 versions/<v>/downloads from the live folder (hard links); no-op when there
    flip <v>                  current -> versions/<v>, downloads -> current/downloads; <v> into .history
    keep-page <v>             copies the deployed index.html into versions/<v>/
    keep-manifests <v> <dir>  copies update.json, update-v2.json of <dir> into versions/<v>/
    spares <v> <tar>          unpacks a tar of <serial>/{update.json,update-v2.json} into versions/<v>/spare/
    switch <v> [--dry]        THE ROLLBACK: flip, page and manifests of <v> (spare with the lowest
                              serial above live), each by atomic rename
    prune-versions <keep...>  removes version folders not in <keep> (current is always kept)
    trim <n>                  keeps the last <n> versions of the history (and current), removes the rest
    state                     json: live, history, serials, spares per version
    listing <v>               "<sha256>  <name>" of every file of versions/<v>/downloads except SHA256SUMS(.sig)
    put-file <v> <file> <name> <sha256>   publish-one: <file> (checked against <sha256>) becomes
                              versions/<v>/downloads/<name> by atomic rename (root, 0644); the other
                              version's hard link to an older <name> stays as it was
    put-listing <v> <tar>     publish-one: <tar>'s SHA256SUMS, SHA256SUMS.sig and provenance.json
                              replace the folder's, after the new SHA256SUMS is checked to list the
                              folder (with that provenance.json) exactly
    install-page <v> <file>   publish-one on a test target: <file> becomes the page (index.html) of
                              the live version <v> and of the site
    migrate <v> [--dry]       first time only: versions/<v> from today's flat folder"""
import base64
import hashlib
import json
import os
import shutil
import sys
import tarfile
import tempfile

R = os.environ.get("R", "/srv/examples/epic-cash-wallets")
API = os.environ.get("API", "/srv/epiccash-api/v1/update.json")
VER = os.path.join(R, "versions")
LIVE_FILES = {"update.json": lambda: os.path.join(R, "update.json"), "update-v2.json": lambda: API}


def die(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def vdir(v):
    if not v or "/" in v or v.startswith("."):
        die(f"bad version {v!r}")
    return os.path.join(VER, v)


def symlink_atomic(target, link):
    tmp = f"{link}.new.{os.getpid()}"
    if os.path.lexists(tmp):
        os.unlink(tmp)
    os.symlink(target, tmp)
    os.replace(tmp, link)  # rename(2) over a symlink: atomic


def copy_atomic(src, dst, mode=0o644):
    tmp = f"{dst}.new.{os.getpid()}"
    shutil.copyfile(src, tmp)
    os.chmod(tmp, mode)
    if os.geteuid() == 0:
        os.chown(tmp, 0, 0)
    os.replace(tmp, dst)


def history():
    try:
        with open(os.path.join(VER, ".history"), encoding="utf-8") as f:
            return [l.strip() for l in f if l.strip()]
    except FileNotFoundError:
        return []


def write_history(h):
    tmp = os.path.join(VER, f".history.new.{os.getpid()}")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write("".join(x + "\n" for x in h))
    os.chmod(tmp, 0o644)
    os.replace(tmp, os.path.join(VER, ".history"))


def live_version():
    try:
        return os.path.basename(os.readlink(os.path.join(R, "current")).rstrip("/"))
    except OSError:
        return None


def serial_of(path):
    try:
        with open(path, "rb") as f:
            env = json.load(f)
        return int(json.loads(base64.b64decode(env["payload"]))["serial"])
    except Exception:
        return None


def payload_version(path):
    with open(path, "rb") as f:
        env = json.load(f)
    return json.loads(base64.b64decode(env["payload"])).get("versionName")


def link_tree(src, dst):
    """dst = hard links of the files directly in src (flat folder)."""
    os.makedirs(dst, exist_ok=True)
    n = 0
    for name in sorted(os.listdir(src)):
        s, d = os.path.join(src, name), os.path.join(dst, name)
        if os.path.isfile(s) and not os.path.islink(s) and not os.path.lexists(d):
            os.link(s, d)
            n += 1
    return n


def cmd_begin(v):
    d = os.path.join(vdir(v), "downloads")
    if os.path.isdir(d):
        print(f"{d}: exists")
        return
    src = os.path.join(R, "downloads")
    os.makedirs(os.path.join(VER), exist_ok=True)
    tmp = d + f".tmp{os.getpid()}"
    n = link_tree(src, tmp) if os.path.isdir(src) else 0
    os.makedirs(tmp, exist_ok=True)
    os.makedirs(os.path.dirname(d), exist_ok=True)
    os.rename(tmp, d)
    print(f"{d}: {n} files linked from the live folder")


def cmd_flip(v):
    if not os.path.isdir(os.path.join(vdir(v), "downloads")):
        die(f"versions/{v}/downloads does not exist")
    # `downloads` is a symlink to current/downloads (the migration made it one)
    dl = os.path.join(R, "downloads")
    if os.path.lexists(dl) and not os.path.islink(dl):
        die("downloads is still a folder: run migrate first")
    symlink_atomic(os.path.join("versions", v), os.path.join(R, "current"))
    if not os.path.islink(dl):
        symlink_atomic(os.path.join("current", "downloads"), dl)
    h = [x for x in history() if x != v] + [v]
    write_history(h)
    print(f"current -> versions/{v}")


def cmd_keep_page(v):
    copy_atomic(os.path.join(R, "index.html"), os.path.join(vdir(v), "index.html"))
    print(f"versions/{v}/index.html kept")


def cmd_keep_manifests(v, d):
    for name in LIVE_FILES:
        copy_atomic(os.path.join(d, name), os.path.join(vdir(v), name))
    print(f"versions/{v}: update.json and update-v2.json kept")


def cmd_spares(v, tar):
    base = os.path.join(vdir(v), "spare")
    os.makedirs(base, exist_ok=True)
    os.chmod(base, 0o700)
    # a refresh replaces the whole ladder of this version
    for old in os.listdir(base):
        shutil.rmtree(os.path.join(base, old))
    n = 0
    with tarfile.open(tar) as t:
        for m in t.getmembers():
            parts = m.name.split("/")
            if not m.isfile() or len(parts) != 2 or not parts[0].isdigit() or parts[1] not in LIVE_FILES:
                die(f"unexpected member {m.name!r} in the spares tar")
            os.makedirs(os.path.join(base, parts[0]), exist_ok=True)
            with t.extractfile(m) as src, open(os.path.join(base, parts[0], parts[1]), "wb") as dst:
                shutil.copyfileobj(src, dst)
            n += 1
    for root, dirs, files in os.walk(base):
        for x in dirs:
            os.chmod(os.path.join(root, x), 0o700)
        for x in files:
            os.chmod(os.path.join(root, x), 0o600)
    print(f"versions/{v}/spare: {n // 2} pair(s): {', '.join(sorted(os.listdir(base)))}")


def spare_pair(v, above):
    base = os.path.join(vdir(v), "spare")
    best = None
    if os.path.isdir(base):
        for s in sorted(os.listdir(base), key=int):
            if int(s) > above and all(os.path.isfile(os.path.join(base, s, n)) for n in LIVE_FILES):
                if payload_version(os.path.join(base, s, "update.json")) == v:
                    best = s
                    break
    return best


def cmd_switch(v, dry=False):
    d = vdir(v)
    for need in ("downloads", "index.html", "update.json", "update-v2.json"):
        if not os.path.exists(os.path.join(d, need)):
            die(f"versions/{v}/{need} is missing: that release cannot be served from its folder")
    live = {n: serial_of(f()) for n, f in LIVE_FILES.items()}
    if None in live.values():
        die("the live manifests are unreadable: " + json.dumps(live))
    floor = max(live.values())
    pair = spare_pair(v, floor)
    if pair is None:
        die(f"versions/{v} has no pre-signed manifest pair with a serial above the live {floor}: "
            f"run tools/rel resign (it refreshes them), then again")
    pdir = os.path.join(d, "spare", pair)
    print(f"{v}: spare serial {pair} (live {floor}){' [dry: nothing changed]' if dry else ''}")
    if dry:
        return
    # 1. downloads (every file the release's page links)
    symlink_atomic(os.path.join("versions", v), os.path.join(R, "current"))
    # 2. the page, 3. manifests; each a rename. Manifests last: apps see the old release until
    # every file they would fetch is in place.
    copy_atomic(os.path.join(d, "index.html"), os.path.join(R, "index.html"))
    for name, f in LIVE_FILES.items():
        copy_atomic(os.path.join(pdir, name), f())
    write_history(history() if v in history() else history() + [v])
    print(f"switched to {v}")
    # what is installed now, for the caller's read-back of the public copies
    for label, path in (("index.html", os.path.join(R, "index.html")), ("update.json", os.path.join(R, "update.json")),
                        ("update-v2.json", API)):
        with open(path, "rb") as f:
            print(f"sha256 {label} {hashlib.sha256(f.read()).hexdigest()}")
    print(f"serial {serial_of(os.path.join(R, 'update.json'))}")


def cmd_prune_versions(*keep):
    cur = live_version()
    keep = set(keep) | ({cur} if cur else set())
    gone = []
    for v in sorted(os.listdir(VER)):
        if v.startswith(".") or v in keep or not os.path.isdir(os.path.join(VER, v)):
            continue
        shutil.rmtree(os.path.join(VER, v))
        gone.append(v)
    write_history([x for x in history() if x not in gone])
    print("removed: " + (", ".join(gone) or "nothing") + "; kept: " + ", ".join(sorted(keep)))


def cmd_trim(n):
    h = history()
    cmd_prune_versions(*h[-int(n):])


def cmd_state():
    out = {"live": live_version(), "history": history(), "versions": {}}
    for v in sorted(os.listdir(VER)) if os.path.isdir(VER) else []:
        if v.startswith(".") or not os.path.isdir(os.path.join(VER, v)):
            continue
        base = os.path.join(VER, v, "spare")
        out["versions"][v] = {
            "files": sorted(os.listdir(os.path.join(VER, v, "downloads"))) if os.path.isdir(os.path.join(VER, v, "downloads")) else [],
            "page": os.path.isfile(os.path.join(VER, v, "index.html")),
            "serial": serial_of(os.path.join(VER, v, "update.json")),
            "serial_v2": serial_of(os.path.join(VER, v, "update-v2.json")),
            "spares": sorted(int(s) for s in os.listdir(base)) if os.path.isdir(base) else [],
        }
    out["live_serial"] = {n: serial_of(f()) for n, f in LIVE_FILES.items()}
    out["downloads_is_link"] = os.path.islink(os.path.join(R, "downloads"))
    print(json.dumps(out))


LISTING_FILES = ("SHA256SUMS", "SHA256SUMS.sig", "SHA256SUMS.new")


def sha_of(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def folder_listing(v, override=None):
    """{name: sha256} of versions/<v>/downloads (regular files, listing files left out); override
    = {name: path} hashes another file in place of the folder's."""
    d = os.path.join(vdir(v), "downloads")
    if not os.path.isdir(d):
        die(f"versions/{v} has no downloads folder")
    out = {}
    for n in sorted(os.listdir(d)):
        p = os.path.join(d, n)
        if n in LISTING_FILES or not os.path.isfile(p) or os.path.islink(p):
            continue
        out[n] = sha_of((override or {}).get(n, p))
    return out


def cmd_listing(v):
    for n, h in sorted(folder_listing(v).items()):
        print(f"{h}  {n}")


def cmd_put_file(v, src, name, sha):
    if "/" in name or name.startswith(".") or name in LISTING_FILES:
        die(f"bad file name {name!r}")
    if sha_of(src) != sha:
        die(f"{src} is not {sha}: not installed")
    d = os.path.join(vdir(v), "downloads")
    if not os.path.isdir(d):
        die(f"versions/{v} has no downloads folder")
    copy_atomic(src, os.path.join(d, name))
    os.unlink(src)
    print(f"installed {name} {sha} {os.path.getsize(os.path.join(d, name))}")


def cmd_put_listing(v, tar):
    """provenance.json, SHA256SUMS and SHA256SUMS.sig out of <tar> replace the folder's, once the
    new SHA256SUMS is checked to list the folder as it is (with that provenance.json)."""
    d = tempfile.mkdtemp(prefix="put-listing-")
    try:
        with tarfile.open(tar) as t:
            for m in t.getmembers():
                if not m.isfile() or m.name not in ("provenance.json", "SHA256SUMS", "SHA256SUMS.sig"):
                    die(f"unexpected member {m.name!r} in the listing tar")
                with t.extractfile(m) as src, open(os.path.join(d, m.name), "wb") as dst:
                    shutil.copyfileobj(src, dst)
        sums_p = os.path.join(d, "SHA256SUMS")
        if not os.path.isfile(sums_p):
            die("the listing tar has no SHA256SUMS")
        prov = os.path.join(d, "provenance.json")
        want = folder_listing(v, {"provenance.json": prov} if os.path.isfile(prov) else None)
        have = {}
        with open(sums_p, encoding="utf-8") as f:
            for line in f:
                h, _, n = line.rstrip("\n").partition("  ")
                if len(h) != 64 or not n:
                    die(f"SHA256SUMS: not a listing line: {line.rstrip()!r}")
                have[n] = h
        if have != want:
            bad = sorted(n for n in set(have) | set(want) if have.get(n) != want.get(n))
            die(f"the new SHA256SUMS does not list versions/{v}/downloads (differs: {', '.join(bad)}): nothing installed")
        base = os.path.join(vdir(v), "downloads")
        for n in ("provenance.json", "SHA256SUMS", "SHA256SUMS.sig"):
            if os.path.isfile(os.path.join(d, n)):
                copy_atomic(os.path.join(d, n), os.path.join(base, n))
                print(f"installed {n} {sha_of(os.path.join(base, n))}")
    finally:
        shutil.rmtree(d, ignore_errors=True)
        try:
            os.unlink(tar)
        except OSError:
            pass


def cmd_install_page(v, src):
    if live_version() != v:
        die(f"{v} is not live ({live_version()}): the page is not changed")
    copy_atomic(src, os.path.join(vdir(v), "index.html"))
    copy_atomic(src, os.path.join(R, "index.html"))
    print(f"installed page {sha_of(os.path.join(R, 'index.html'))}")


def cmd_migrate(v, dry=False):
    """First time only: today's flat folder becomes versions/<v>; downloads becomes a symlink.
    The files are hard-linked, then the folder is swapped for the link by two renames (the gap
    between them is microseconds: downloads/ answers 404 for at most that long)."""
    dl = os.path.join(R, "downloads")
    if os.path.islink(dl):
        print("already migrated")
        return
    if not os.path.isdir(dl):
        die(f"{dl} is not a folder")
    live = {n: serial_of(f()) for n, f in LIVE_FILES.items()}
    if None in live.values():
        die("the live manifests are unreadable")
    for n, f in LIVE_FILES.items():
        have = payload_version(f())
        if have != v:
            die(f"live {n} names {have}, not {v}: pass the live release")
    files = [x for x in os.listdir(dl) if os.path.isfile(os.path.join(dl, x))]
    print(f"would make versions/{v}: {len(files)} downloads (hard links), index.html, update.json, update-v2.json; "
          f"downloads -> current/downloads; current -> versions/{v}" if dry else f"migrating to versions/{v}")
    if dry:
        return
    os.makedirs(VER, exist_ok=True)
    d = vdir(v)
    os.makedirs(d, exist_ok=True)
    link_tree(dl, os.path.join(d, "downloads"))
    copy_atomic(os.path.join(R, "index.html"), os.path.join(d, "index.html"))
    for n, f in LIVE_FILES.items():
        copy_atomic(f(), os.path.join(d, n))
    symlink_atomic(os.path.join("versions", v), os.path.join(R, "current"))
    # swap: old folder aside, link in place (rename, rename)
    aside = os.path.join(R, f".downloads-flat-{os.getpid()}")
    os.rename(dl, aside)
    os.symlink(os.path.join("current", "downloads"), dl)
    shutil.rmtree(aside)  # every file is also linked in versions/<v>/downloads
    write_history([v])
    print(f"migrated: current -> versions/{v}")


def main(argv):
    if not argv:
        die(__doc__)
    cmd, *a = argv
    dry = "--dry" in a
    a = [x for x in a if x != "--dry"]
    if cmd == "begin" and len(a) == 1:
        cmd_begin(*a)
    elif cmd == "flip" and len(a) == 1:
        cmd_flip(*a)
    elif cmd == "keep-page" and len(a) == 1:
        cmd_keep_page(*a)
    elif cmd == "keep-manifests" and len(a) == 2:
        cmd_keep_manifests(*a)
    elif cmd == "spares" and len(a) == 2:
        cmd_spares(*a)
    elif cmd == "switch" and len(a) == 1:
        cmd_switch(a[0], dry)
    elif cmd == "prune-versions":
        cmd_prune_versions(*a)
    elif cmd == "trim" and len(a) == 1:
        cmd_trim(*a)
    elif cmd == "state" and not a:
        cmd_state()
    elif cmd == "migrate" and len(a) == 1:
        cmd_migrate(a[0], dry)
    elif cmd == "listing" and len(a) == 1:
        cmd_listing(*a)
    elif cmd == "put-file" and len(a) == 4:
        cmd_put_file(*a)
    elif cmd == "put-listing" and len(a) == 2:
        cmd_put_listing(*a)
    elif cmd == "install-page" and len(a) == 2:
        cmd_install_page(*a)
    else:
        die(f"usage: relsrv.py begin|flip|keep-page|keep-manifests|spares|switch|prune-versions|trim|state|migrate|listing|put-file|put-listing|install-page ... (got {argv})")


if __name__ == "__main__":
    main(sys.argv[1:])
