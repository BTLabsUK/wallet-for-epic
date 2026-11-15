# SPDX-License-Identifier: Apache-2.0
"""`tools/rel publish-one <platform> <variant> <file>` (docs/RELEASING.md, "Publish one file").

One built file goes onto the live release, signed the way the release signs it, and nothing else
of the release is touched: no rebuild, no download of other files, no run state, no gate (the
word "publish Windows no-Tor" is the approval).

  check     the name fills the slot, the version is the live one, size and magic bytes, for an
            APK its certificate; the Play .aab has no slot here and is refused
  sign      Android: the signer (job `apk`) unless the file already carries the release
            certificate. Windows and Linux files are not signed one by one: SHA256SUMS.sig covers
            them (there is no Authenticode). macOS: signed and notarised on the Mac; here the
            Mac's report is checked (apple-mac-check.sh). iOS: nothing is signed.
  provenance  provenance.json of the release gets this file's entry, or a new one (the SBOM stays)
  listing   SHA256SUMS of the version folder with this file's line and the new provenance line,
            signed again (minisign, the release signer), installed only if it lists the folder
  upload    the file into versions/<v>/downloads by atomic rename
  page      only this file's slot in releases.json, the page rendered and deployed
  manifests only this platform's entry in update.json and update-v2.json, both signed again with
            one serial above the live one (the signer, or the test key), installed by atomic
            rename; no entry for a file the manifests do not list (portable zip, universal APK)
  presign   the rollback ladder is signed again (the live release's rungs name this file)
  github    the release's GitHub assets and its SHA256SUMS (a mirror: a failure is a warning)
  read back one line per check: page slot, file, listing and its signature, both manifests

--dry-run does the checks that only read (the server, the live manifests, the page data) and says
what would change; nothing is signed, uploaded or written."""
import base64
import concurrent.futures as cf
import datetime as dt
import getpass
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shutil
import socket
import subprocess
import sys
import tarfile
import time
import types

from .resign import NAMES, Resign, ResignError, differences, iso, new_serial, payload_bytes, resigned
from .server import ServerError, payload, sha

MIN_BYTES = 1_000_000
BAR_SECONDS = 180  # the bar is about three minutes for a Windows installer
DESKTOP = {"windows": re.compile(r"-windows-x64-setup\.exe$"), "linux": re.compile(r"\.AppImage$"), "macos": re.compile(r"\.dmg$")}
AAB = re.compile(r"^bt-wallet-.+-android\.aab$")


class PublishOneError(Exception):
    """Refused: the message says why. Nothing was changed unless it says so."""


def build_module(repo):
    spec = importlib.util.spec_from_file_location("releases_build", os.path.join(repo, "tools/releases/build.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def file_sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def locate(p, plat, variant, name):
    """The manifest entry of a file in payload p, or None (the manifests do not list it)."""
    root = p.get("notor", {}) if variant == "notor" else p
    if plat == "android":
        m = re.search(r"-android-([\w-]+)\.apk$", name)
        for e in root.get("apks", []):
            if m and e.get("abi") == m.group(1):
                return e
        return None
    if plat in DESKTOP and DESKTOP[plat].search(name):
        return root.get("desktop", {}).get(plat)
    return None


def top_key(plat, variant):
    return "notor" if variant == "notor" else ("apks" if plat == "android" else "desktop")


def edit_payload(raw, plat, variant, name, version, digest, size):
    """(new payload JSON text, changed top-level key) with only this file's entry replaced."""
    p = json.loads(raw)
    e = locate(p, plat, variant, name)
    if e is None:
        return None, None
    e["url"] = e["url"].rsplit("/", 1)[0] + "/" + name
    e["sha256"], e["size"] = digest, size
    if plat != "android":
        e["version"] = version
    return json.dumps(p, ensure_ascii=False), top_key(plat, variant)


class Parts:
    """Seconds per part, printed as they finish."""

    def __init__(self, say):
        self.say, self.t0, self.secs = say, time.monotonic(), {}

    def run(self, part, fn, *args):
        t = time.monotonic()
        try:
            return fn(*args)
        finally:
            self.secs[part] = time.monotonic() - t
            self.say(f"{part:<10}{self.secs[part]:6.1f} s")

    def total(self):
        return time.monotonic() - self.t0


class PublishOne:
    def __init__(self, repo, state_root, pipeline, hosts, server, say=print, test=False, min_bytes=MIN_BYTES,
                 apple_results=None, github_repo=None, data_path=None, no_github=False):
        self.repo, self.hosts, self.server, self.say, self.test = repo, hosts, server, say, test
        self.min_bytes, self.apple_results, self.github_repo, self.no_github = min_bytes, apple_results, github_repo, no_github
        self.pipeline, self.state_root = pipeline, state_root
        self.rs = Resign(repo, state_root, pipeline, hosts, say=say, test=test, live_dir=None, server=server)
        self.build = build_module(repo)
        self.cert = self.build.ANDROID_CERT_SHA256
        self.main = os.path.expanduser(hosts["path"].get("main_checkout") or repo)
        self.data_path = data_path or os.path.join(self.main, "tools/releases/releases.json")
        self.keyring = self.rs.keyring
        self.tool_release_files = os.path.join(repo, "tools/release-files.py")
        # replaced by the tests: no apksigner or signer on a test machine
        self.cert_of = self._cert_of
        self.sign_apk = self._sign_apk

    # ---- 1. what the file is ----

    def check(self, platform, variant, path, version=None):
        name = os.path.basename(path)
        if AAB.match(name):
            raise PublishOneError(f"{name}: the Play bundle has no place on the page or in the manifests; it goes to Play with tools/play-upload.sh")
        if os.path.islink(path) or not os.path.isfile(path):
            raise PublishOneError(f"{path} is not a regular file")
        s = self.build.slot(name)
        if s is None:
            raise PublishOneError(f"{name}: no name pattern of tools/releases/build.py KINDS matches it (files are bt-wallet-<version>[-notor]-<platform>-...)")
        if s != (platform, variant):
            raise PublishOneError(f"{name} is a {s[0]} {s[1]} file, not {platform} {variant}")
        v = self.build.version_of(name)
        if version and version != v:
            raise PublishOneError(f"{name} is version {v}, not {version}")
        size = os.path.getsize(path)
        if size < self.min_bytes:
            raise PublishOneError(f"{name}: only {size} bytes")
        with open(path, "rb") as f:
            magic = f.read(8)
            if name.endswith((".apk", ".ipa", ".zip")) and magic[:2] != b"PK":
                raise PublishOneError(f"{name}: not a zip")
            if name.endswith(".AppImage") and magic[:4] != b"\x7fELF":
                raise PublishOneError(f"{name}: not an ELF AppImage")
            if name.endswith(".exe") and magic[:2] != b"MZ":
                raise PublishOneError(f"{name}: not a Windows executable")
            if name.endswith(".dmg"):
                f.seek(-512, 2)
                if f.read(4) != b"koly":
                    raise PublishOneError(f"{name}: not a disk image")
        return {"name": name, "version": v, "size": size, "sha": file_sha(path), "platform": platform, "variant": variant}

    # ---- 2. the live release, read only ----

    def preflight(self, info, dry=False):
        st = self.server.state()
        live = st.get("live")
        unmigrated = not live
        if unmigrated and dry:
            # read only: say what the live manifests show, and that the real run needs the layout first
            live = payload(self.server.fetch("update-v2.json"))["versionName"]
            self.say(f"  note: the server has no version folders yet (tools/rel migrate-layout); a real run would refuse; the live release is {live} by its manifest")
        if unmigrated and not dry:
            raise PublishOneError("the server has no versions/current yet: run tools/rel migrate-layout first (publish-one writes into the live version's folder)")
        if info["version"] != live:
            raise PublishOneError(f"{info['name']} is {info['version']} but {live} is live: roll back or forward first, then publish the file")
        live_files = self.rs.read_live()
        raw = {}
        for n, _ in NAMES:
            raw[n] = payload_bytes(live_files[n])
        serials = {json.loads(r)["serial"] for r in raw.values()}
        if len(serials) != 1:
            raise PublishOneError(f"the live manifests do not share a serial: {sorted(serials)}")
        top = json.loads(raw["update-v2.json"])
        if top.get("versionName") != live:
            raise PublishOneError(f"the live manifest names {top.get('versionName')}, `current` is {live}: not a state to publish into")
        info.update(live=live, live_files=live_files, raw=raw, state=st, serial=serials.pop())
        entries = {}
        for n, _ in NAMES:
            e = locate(json.loads(raw[n]), info["platform"], info["variant"], info["name"])
            entries[n] = e
        info["entries"] = entries
        have = st.get("versions", {}).get(live, {}).get("files")
        info["on_server"] = have is not None and info["name"] in have
        info["unmigrated"] = unmigrated
        return info

    # ---- 3. signing, per platform ----

    def _cert_of(self, path):
        from . import signer
        return signer.cert_of(path, signer.android_tools())

    def _sign_apk(self, src, out_dir):
        from . import signer as btsign
        if not btsign.endpoint(self.hosts):
            raise PublishOneError("no signer: set endpoint under [host.signer] (docs/RELEASING.md, \"Signer\")")
        name = os.path.basename(src)
        inp = os.path.join(out_dir, "in")
        os.makedirs(inp, exist_ok=True)
        shutil.copyfile(src, os.path.join(inp, name))
        outp = os.path.join(out_dir, "out")
        os.makedirs(outp, exist_ok=True)
        engine = types.SimpleNamespace(hosts=self.hosts)
        btsign.client(engine, self.say).sign(self.live_version, [{"op": "apk", "file": os.path.join(inp, name), "out": name}], outp,
                                             label=f"Android {name} (publish-one)")
        return os.path.join(outp, name)

    def sign(self, info, path, work):
        """-> (path of the file to publish, extra provenance fields)."""
        plat, name = info["platform"], info["name"]
        extra = {}
        if plat == "android":
            have = self.cert_of(path)
            if have == self.cert:
                self.say(f"{name}: already signed with the release certificate {self.cert[:12]}…, not sent to the signer")
                return path, extra
            if have:
                raise PublishOneError(f"{name} is signed by another certificate ({have[:12]}…), not the release key {self.cert[:12]}…")
            self.live_version = info["version"]
            out = self.sign_apk(path, work)
            got = self.cert_of(out)
            if got != self.cert:
                raise PublishOneError(f"{name}: the signer's file is not signed by {self.cert[:12]}… ({got})")
            extra = {"unsigned_sha256": info["sha"], "signed_by": "signer"}
            return out, extra
        if plat == "macos":
            return self.check_mac(info, path, work), extra
        if plat in ("windows", "linux"):
            self.say(f"{name}: not signed one by one (no Authenticode, no detached signature); the signed SHA256SUMS covers it")
        return path, extra

    def check_mac(self, info, path, work):
        res = self.apple_results or os.path.dirname(os.path.abspath(path))
        team = ((self.hosts["host"].get("apple") or {}).get("team_id") or "")
        commit = self.server_provenance(info["version"]).get("commit") or ""
        out = os.path.join(work, "mac-checked")
        os.makedirs(out, exist_ok=True)
        script = os.path.join(self.repo, "tools/rellib/steps/apple-mac-check.sh")
        p = subprocess.run([script, res, info["name"], commit, team, out], capture_output=True, text=True, timeout=600)
        text = (p.stdout + p.stderr).strip()
        if p.returncode != 0:
            raise PublishOneError(f"the Mac's dmg is not shown to be signed and notarised: {text[-400:]} (the dmg, {info['name']}.sha256 and the REPORT must be in {res}; signing happens on the Mac, tools/build-apple.sh mac-release)")
        self.say(text.splitlines()[-1])
        return os.path.join(out, info["name"])

    # ---- 4. what the folder will look like ----

    def server_provenance(self, v):
        p = os.path.join(self.server.R, "versions", v, "downloads", "provenance.json")
        try:
            return json.loads(self.server.read_remote(p))
        except (ServerError, OSError, ValueError):
            self.say("warning: the version folder has no readable provenance.json; a new one is made with this file's entry only")
            return {"version": v, "files": {}}

    def provenance(self, info, final, extra):
        v = info["version"]
        prov = self.server_provenance(v)
        entry = {"bytes": os.path.getsize(final), "sha256": file_sha(final), "step": "publish-one", "host": socket.gethostname(),
                 "built_by": getpass.getuser(), "published_at": iso(int(time.time()))}
        entry.update(extra)
        prov.setdefault("files", {})[info["name"]] = entry
        return (json.dumps(prov, indent=2, ensure_ascii=False) + "\n").encode(), entry

    def listing(self, info, entry, prov_bytes, work):
        """Directory with provenance.json, SHA256SUMS and (signed) SHA256SUMS.sig for the folder
        with this file in it."""
        out = self.server.relsrv("listing", info["version"])
        lines = {}
        for l in out.splitlines():
            h, _, n = l.partition("  ")
            lines[n] = h
        lines[info["name"]] = entry["sha256"]
        lines["provenance.json"] = sha(prov_bytes)
        d = os.path.join(work, "listing")
        os.makedirs(d, exist_ok=True)
        pathlib.Path(d, "provenance.json").write_bytes(prov_bytes)
        pathlib.Path(d, "SHA256SUMS").write_text("".join(f"{h}  {n}\n" for n, h in sorted(lines.items())), encoding="utf-8")
        self.sign_listing(info["version"], d)
        return d

    def sign_listing(self, version, d):
        sums = os.path.join(d, "SHA256SUMS")
        sums_py = os.path.join(self.repo, "tools/rellib/steps/server_sums.py")
        if self.test:
            key = os.path.join(d, "test-a.key")
            shutil.copyfile(os.path.join(self.repo, "app/test/fixtures/btlabs/test-a.key"), key)
            os.chmod(key, 0o600)
            cmd = [sys.executable, sums_py, "sign-key", sums, key, version, self.keyring, self.tool_release_files]
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            os.unlink(key)
            if p.returncode != 0:
                raise PublishOneError(f"signing SHA256SUMS: {(p.stdout + p.stderr).strip()[-300:]}")
        else:
            from . import signer as btsign
            if not btsign.endpoint(self.hosts):
                raise PublishOneError("no signer: SHA256SUMS cannot be signed (docs/RELEASING.md, \"Signer\")")
            label = min(json.load(open(self.keyring, encoding="utf-8"))["keys"], key=lambda k: k["rank"])["label"]
            job = {"op": "minisign", "file": sums, "out": "SHA256SUMS.sig", "trusted_comment": f"Epic Cash {version} SHA256SUMS, BT Labs key {label}"}
            btsign.client(types.SimpleNamespace(hosts=self.hosts), self.say).sign(version, [job], d, label=f"Downloads SHA256SUMS {version} (publish-one)")
        p = subprocess.run([sys.executable, sums_py, "verify", sums, os.path.join(d, "SHA256SUMS.sig"), self.keyring, self.tool_release_files],
                           capture_output=True, text=True, timeout=120)
        if p.returncode != 0:
            raise PublishOneError(f"the new SHA256SUMS.sig does not verify: {(p.stdout + p.stderr).strip()[-300:]}")

    # ---- 5. the server ----

    def install(self, info, final, listing_dir, work):
        v = info["version"]
        staged = self.server.put(final, f"publish-one-{info['name']}")
        tar = os.path.join(work, "listing.tar")
        with tarfile.open(tar, "w") as t:
            for n in ("provenance.json", "SHA256SUMS", "SHA256SUMS.sig"):
                t.add(os.path.join(listing_dir, n), arcname=n)
        staged_tar = self.server.put(tar, "publish-one-listing.tar")
        # back to back: between the two the listing does not cover the file yet
        self.say("  " + self.server.relsrv("put-file", v, staged, info["name"], file_sha(final)).strip())
        for l in self.server.relsrv("put-listing", v, staged_tar).splitlines():
            self.say("  " + l)

    # ---- 6. the page ----

    def page(self, info, work):
        v, name = info["version"], info["name"]
        data = os.path.join(work, "releases.json")
        if os.path.isfile(self.data_path):
            shutil.copyfile(self.data_path, data)
        else:
            pathlib.Path(data).write_text('{"releases": []}\n')
        env = dict(os.environ, WFE_RELEASES_DATA=data)
        # the record keeps its date and its GitHub flag: put only replaces this file's entry
        p = subprocess.run([sys.executable, os.path.join(self.repo, "tools/releases/build.py"), "put", v, info["final"]],
                           capture_output=True, text=True, env=env, timeout=120)
        if p.returncode != 0:
            raise PublishOneError(f"build.py put: {(p.stdout + p.stderr).strip()[-300:]}")
        self.say("  " + p.stdout.strip())
        rec = [r for r in json.load(open(data))["releases"] if r["version"] == v][0]
        info["github_mirror"] = bool(rec.get("github"))
        site = os.path.join(work, "site")
        if self.test:
            p = subprocess.run([sys.executable, os.path.join(self.repo, "tools/releases/build.py"), "render", "--out", site],
                               capture_output=True, text=True, env=env, timeout=120)
            if p.returncode != 0:
                raise PublishOneError(f"build.py render: {(p.stdout + p.stderr).strip()[-300:]}")
            staged = self.server.put(os.path.join(site, "index.html"), "publish-one-index.html")
            self.say("  " + self.server.relsrv("install-page", v, staged).strip())
            return data
        page_repo = os.path.expanduser(self.hosts["path"]["page_repo"])
        out = os.path.join(page_repo, "site/epic-cash")
        p = subprocess.run([sys.executable, os.path.join(self.repo, "tools/releases/build.py"), "render", "--out", out],
                           capture_output=True, text=True, env=env, timeout=120)
        if p.returncode != 0:
            raise PublishOneError(f"build.py render: {(p.stdout + p.stderr).strip()[-300:]}")
        sh = lambda *c, cwd=page_repo: subprocess.run(c, cwd=cwd, capture_output=True, text=True, timeout=900)
        if sh("git", "status", "--porcelain", "site/epic-cash").stdout.strip():
            sh("git", "add", "site/epic-cash")
            sh("git", "commit", "-q", "-m", f"Epic Cash {v} release page: {name}")
        d = sh("./deploy-epic-cash.sh")
        if d.returncode != 0:
            raise PublishOneError(f"deploy-epic-cash.sh failed: {(d.stdout + d.stderr).strip()[-400:]}")
        self.say("  " + self.server.relsrv("keep-page", v).strip())
        return data

    def commit_main(self, data, version):
        """The page data on main, as publish-page.sh does it: only when that is safe."""
        rj = "tools/releases/releases.json"
        git = lambda *a: subprocess.run(["git", "-C", self.main, *a], capture_output=True, text=True)
        if self.test and not os.path.isdir(os.path.join(self.main, ".git")):
            shutil.copyfile(data, self.data_path)
            return "page data written to " + self.data_path
        why = ""
        if git("symbolic-ref", "-q", "--short", "HEAD").stdout.strip() != "main":
            why = f"{self.main} is not on branch main"
        else:
            gd = git("rev-parse", "--absolute-git-dir").stdout.strip()
            if any(os.path.exists(os.path.join(gd, m)) for m in ("MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "rebase-merge", "rebase-apply")):
                why = f"a merge, rebase or cherry-pick is in progress in {self.main}"
            elif git("status", "--porcelain", "--", rj).stdout.strip():
                why = f"{self.main} has its own change to {rj}"
        if not why:
            shutil.copyfile(data, os.path.join(self.main, rj))
            c = git("commit", "-q", "--only", "-m", f"Release {version}: one file on the releases page", "--", rj)
            if c.returncode == 0:
                return f"committed {rj} on main: {git('rev-parse', '--short', 'HEAD').stdout.strip()}"
            git("checkout", "-q", "--", rj)
            why = "git commit failed"
        return f"WARNING: {rj} not committed on main: {why}; copy {data} to {self.main}/{rj} and commit it"

    # ---- 7. the manifests ----

    def manifests(self, info, work):
        """-> {name: signed file}, or None when the manifests list no such file."""
        edited = {}
        key = None
        for n, _ in NAMES:
            text, k = edit_payload(info["raw"][n], info["platform"], info["variant"], info["name"], info["version"], info["final_sha"], info["final_size"])
            if text is None:
                return None
            edited[n], key = text, k
        serial = new_serial(info["serial"])
        days = self.pipeline.manifest_days()
        jobs, bodies = [], {}
        os.makedirs(os.path.join(work, "man"), exist_ok=True)
        for n, pname in NAMES:
            body = resigned(edited[n].encode(), serial, days)
            bodies[n] = body
            pp = os.path.join(work, "man", pname)
            pathlib.Path(pp).write_bytes(body)
            prev = os.path.join(work, "man", "live-" + n)
            pathlib.Path(prev).write_bytes(info["live_files"][n])
            job = {"payload": pp, "out": n, "prev": prev}
            if n == "update-v2.json":
                job["app_config"] = self.rs.cfg
            jobs.append(job)
        signed = os.path.join(work, "man", "signed")
        os.makedirs(signed, exist_ok=True)
        self.rs.work = work
        self.rs.sign(info["version"], signed, jobs)
        files = {}
        for n, _ in NAMES:
            path = os.path.join(signed, n)
            if not os.path.isfile(path):
                raise PublishOneError(f"the signer returned no {n}")
            self.rs.verify(n, path)
            got = payload_bytes(pathlib.Path(path).read_bytes())
            if got != bodies[n]:
                raise PublishOneError(f"signed {n} carries another payload than the one sent")
            extra = set(differences(json.loads(info["raw"][n]), json.loads(got))) - {key}
            if extra:
                raise PublishOneError(f"signed {n} differs from the live one in {sorted(extra)}, not only {key}")
            files[n] = path
        info["new_serial"] = serial
        return files

    def publish_manifests(self, files):
        if self.test:
            self.server.install_manifests(files)
            from .instant import Flip
            ok, lines = Flip(self.repo, self.server, os.path.join(os.path.dirname(files["update.json"]), "mirror"), say=self.say).mirrors()
            for l in lines[-4:]:
                self.say("  " + l)
            if not ok:
                self.say("warning: the Pages mirror failed (above); the website's manifests are live")
            return
        self.rs.publish(files)

    # ---- 8. read back ----

    def readback(self, info, listing_dir):
        s, name, v = self.server, info["name"], info["version"]
        lines, ok = [], True

        def line(good, text):
            nonlocal ok
            ok &= bool(good)
            lines.append(("ok     " if good else "FAILED ") + text)

        if info["platform"] in self.build.STORE_ONLY:
            lines.append(f"n/a    page: {info['platform']} is offered through its store only, the page shows no download; the file is recorded in the page data")
        else:
            page = s.fetch("page").decode("utf-8", "replace")
            line(name in page and info["final_sha"] in page, f"page: {name} listed with sha256 {info['final_sha'][:12]}")
        on = {l.partition("  ")[2]: l.partition("  ")[0] for l in s.relsrv("listing", v).splitlines()}
        line(on.get(name) == info["final_sha"], f"server file versions/{v}/downloads/{name} sha256 {info['final_sha'][:12]} (hashed on the server)")
        if not s.test:
            for base in s.download_bases:
                import urllib.request
                req = urllib.request.Request(f"{base}/{name}", method="HEAD")
                with urllib.request.urlopen(req, timeout=60) as r:
                    line(int(r.headers.get("Content-Length", -1)) == info["final_size"], f"{base}/{name} served, {r.headers.get('Content-Length')} bytes")
        sums = s.fetch("download", "SHA256SUMS")
        line(f"{info['final_sha']}  {name}\n".encode() in sums, f"served SHA256SUMS lists {name}")
        try:
            sig = s.fetch("download", "SHA256SUMS.sig")
            tmp = os.path.join(listing_dir, "served")
            os.makedirs(tmp, exist_ok=True)
            pathlib.Path(tmp, "SHA256SUMS").write_bytes(sums)
            pathlib.Path(tmp, "SHA256SUMS.sig").write_bytes(sig)
            p = subprocess.run([sys.executable, os.path.join(self.repo, "tools/rellib/steps/server_sums.py"), "verify", os.path.join(tmp, "SHA256SUMS"),
                                os.path.join(tmp, "SHA256SUMS.sig"), self.keyring, self.tool_release_files], capture_output=True, text=True, timeout=120)
            line(p.returncode == 0, "served SHA256SUMS.sig verifies against the keyring")
        except Exception as e:
            line(False, f"served SHA256SUMS.sig: {e}")
        if info.get("manifest_files"):
            for n, _ in NAMES:
                served = s.fetch(n)
                tmp = os.path.join(listing_dir, "served-" + n)
                pathlib.Path(tmp).write_bytes(served)
                try:
                    self.rs.verify(n, tmp)
                    good = True
                except ResignError:
                    good = False
                e = locate(payload(served), info["platform"], info["variant"], name)
                line(good and e is not None and e["sha256"] == info["final_sha"] and e["url"].endswith("/" + name),
                     f"{n} serial {payload(served)['serial']} verifies, entry {name} sha256 {info['final_sha'][:12]}")
        else:
            lines.append("n/a    manifests: no entry for this file")
        return ok, lines

    # ---- the whole job ----

    def run(self, platform, variant, path, version=None, dry=False, work=None):
        parts = Parts(self.say)
        work = work or os.path.join(self.state_root, "publish-one", time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()))
        os.makedirs(work, exist_ok=True)
        info = self.check(platform, variant, path, version)
        info["path"] = path
        self.say(f"publish-one: {info['name']} ({info['size']} bytes, sha256 {info['sha'][:12]}) as {platform} {variant} of {info['version']}" + ("  [dry run: nothing changes]" if dry else ""))
        parts.run("preflight", self.preflight, info, dry)
        if dry:
            return self.dry(info)
        final, extra = parts.run("sign", self.sign, info, path, work)
        info.update(final=final, final_sha=file_sha(final), final_size=os.path.getsize(final))
        prov, entry = self.provenance(info, final, extra)
        lst = parts.run("listing", self.listing, info, entry, prov, work)
        parts.run("upload", self.install, info, final, lst, work)
        data = parts.run("page", self.page, info, work)
        files = parts.run("manifests", self.manifests, info, work)
        info["manifest_files"] = files
        if files:
            self.publish_manifests(files)
        else:
            self.say("manifests: the live manifests list no entry for this file; they stay as they are")
        res = {"name": info["name"], "version": info["version"], "parts": parts.secs, "ok": True, "warnings": []}
        note = self.commit_main(data, info["version"])
        self.say(note)
        if note.startswith("WARNING"):
            res["warnings"].append(note)
        if not info.get("github_mirror") or self.no_github:
            self.say("github    skipped (the release has no GitHub mirror on the page, or --no-github)")
        else:
            try:
                parts.run("github", self.github, info, lst, work)
            except Exception as e:
                res["warnings"].append(f"GitHub mirror: {e}")
                self.say("warning: " + res["warnings"][-1])
        ok, lines = parts.run("readback", self.readback, info, lst)
        for l in lines:
            self.say("  " + l)
        res["live"] = parts.total()
        self.say(f"published and read back in {res['live']:.1f} s (bar {BAR_SECONDS} s)")
        # the rollback ladder is refreshed last: the file is live already, and this part signs 16 manifests
        try:
            parts.run("presign", self.refresh_ladder, work)
        except Exception as e:
            res["warnings"].append(f"the rollback ladder was not refreshed ({e}); run tools/rel presign")
            self.say("warning: " + res["warnings"][-1])
        res.update(ok=ok, total=parts.total(), lines=lines)
        self.say(f"total     {res['total']:6.1f} s")
        return res

    def refresh_ladder(self, work):
        from .presign import Presign
        Presign(self.repo, self.state_root, self.pipeline, self.hosts, self.server, say=self.say, test=self.test).refresh(
            os.path.join(work, "presign"), github=not self.no_github)

    def github(self, info, listing_dir, work):
        cmd = [sys.executable, self.tool_release_files, "github-put-file", f"v{info['version']}", info["final"], "--version", info["version"],
               "--listing-dir", listing_dir, "--keyring", self.keyring]
        key = None
        if self.test:
            key = os.path.join(work, "test-a.github.key")
            shutil.copyfile(os.path.join(self.repo, "app/test/fixtures/btlabs/test-a.key"), key)
            os.chmod(key, 0o600)
            cmd += ["--sign-key", key]
        else:
            cmd += ["--signer"]
        if self.github_repo:
            cmd += ["--github-repo", self.github_repo]
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        finally:
            if key:
                os.unlink(key)
        for l in (p.stdout + p.stderr).strip().splitlines()[-5:]:
            self.say("  " + l)
        if p.returncode != 0:
            raise PublishOneError("github-put-file failed")

    def dry(self, info):
        e = info["entries"]
        self.say(f"  live release {info['live']}, serial {info['serial']}; {info['name']} is {'on the server already' if info['on_server'] else 'not in a version folder yet' if not info['unmigrated'] else 'not checked (no version folders yet)'}")
        plat = info["platform"]
        how = {"android": "the signer (job apk), unless the file already carries the release certificate",
               "macos": "signed and notarised on the Mac: the Mac's REPORT is checked here",
               "ios": "not signed (unsigned IPA, store only)"}.get(plat, "not signed one by one: SHA256SUMS.sig covers it")
        self.say(f"  signing: {how}")
        for n, entry in e.items():
            self.say(f"  {n}: " + (f"entry {json.dumps(entry)[:120]} would get the new url, sha256 and size" if entry else "no entry for this file: unchanged"))
        self.say(f"  would: upload into versions/{info['live']}/downloads, sign SHA256SUMS again, set the page slot, "
                 f"{'sign both manifests again with serial above ' + str(info['serial']) if any(e.values()) else 'leave the manifests'}, refresh the rollback ladder, read back")
        return {"dry": True, "ok": True, "name": info["name"], "version": info["version"], "parts": {}}
