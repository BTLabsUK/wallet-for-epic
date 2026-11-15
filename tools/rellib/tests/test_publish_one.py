# SPDX-License-Identifier: Apache-2.0
"""tools/rel publish-one (docs/RELEASING.md, "Publish one file"): one built file goes onto the
live release, and nothing else of the release changes.

The target is a folder standing in for the server (REL_SERVER_ROOT: site/, api/, the version
folders), the real tools/rellib/steps/relsrv.py running on it without ssh, the real
tools/releases/build.py rendering the page, and the Pages repository as a local git repository.
Manifests and SHA256SUMS are signed with the test keys of app/test/fixtures/btlabs/. The Android
signer is a stand-in (no apksigner here): a file carries the release certificate when it holds the
marker. Nothing leaves this machine. The test prints the proof run's seconds per part, one line
per platform and variant."""
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import time
import unittest

from support import Base, REPO
from test_release_files import FakeGitHub, FAKE_GH, REPO_NAME
import test_instant_rollback as ir
from test_resign import NEW, OLD, RING, TOOL, payload_of, sign, verifies, private_key
from rellib import pubone
from rellib.instant import Flip
from rellib.pubone import PublishOne, PublishOneError
from rellib.resign import differences, iso
from rellib.run import write_json
from rellib.server import Server, payload

A, B = "26.11.3", "26.11.4"
COMMIT = "c0ffee0123456789c0ffee0123456789c0ffee01"
TEAM = "TEAM123456"
MARK = b"SIGNED-WITH-THE-RELEASE-KEY"
SIGN_KEYS = {"windows": "windows", "linux": "linux", "macos": "macos"}


def names(v):
    return {("windows", "tor"): f"bt-wallet-{v}-windows-x64-setup.exe", ("windows", "notor"): f"bt-wallet-{v}-notor-windows-x64-setup.exe",
            ("linux", "tor"): f"bt-wallet-{v}-linux-x86_64.AppImage", ("linux", "notor"): f"bt-wallet-{v}-notor-linux-x86_64.AppImage",
            ("android", "tor"): f"bt-wallet-{v}-android-arm64-v8a.apk", ("android", "notor"): f"bt-wallet-{v}-notor-android-arm64-v8a.apk",
            ("macos", "tor"): f"bt-wallet-{v}-macos.dmg", ("macos", "notor"): f"bt-wallet-{v}-notor-macos.dmg",
            ("ios", "notor"): f"bt-wallet-{v}-notor-ios-unsigned.ipa"}


def body(name, tag):
    """A file of the right kind with distinguishable content (tag), 4 KB."""
    pad = hashlib.sha256((name + tag).encode()).hexdigest().encode() * 64
    if name.endswith((".apk", ".ipa", ".zip")):
        return b"PK\x03\x04" + pad
    if name.endswith(".AppImage"):
        return b"\x7fELF" + pad
    if name.endswith(".exe"):
        return b"MZ" + pad
    if name.endswith(".dmg"):
        return pad + b"koly" + b"\0" * 508
    raise ValueError(name)


def sha(b):
    return hashlib.sha256(b).hexdigest()


def tree(root):
    """Everything under root: path -> file hash, or the link target."""
    out = {}
    for d, dirs, files in os.walk(root):
        for n in dirs + files:
            p = os.path.join(d, n)
            rel = os.path.relpath(p, root)
            if os.path.islink(p):
                out[rel] = "-> " + os.readlink(p)
            elif os.path.isfile(p):
                out[rel] = sha(pathlib.Path(p).read_bytes())
    return out


@unittest.skipUnless(os.path.isfile(TOOL) and ir.have_filter_repo(), "needs btlabs-public and git-filter-repo")
class PublishOneTest(Base):
    mirror_env = ir.InstantRollbackTest.mirror_env
    restore_env = ir.InstantRollbackTest.restore_env

    def setUp(self):
        super().setUp()
        self.log = []
        self.say = self.log.append
        self.srvroot = os.path.join(self.tmp, "server")
        self.site = os.path.join(self.srvroot, "site")
        self.api = os.path.join(self.srvroot, "api")
        os.makedirs(os.path.join(self.site, "downloads"))
        os.makedirs(self.api)
        self.server = Server(REPO, None, root=self.srvroot, say=self.say)
        self.pipeline.data["manifest"] = {"validity_days": 45}
        self.hosts["host"]["signer"] = {}
        self.hosts["host"]["apple"] = {"team_id": TEAM}
        self.main = os.path.join(self.tmp, "main")
        os.makedirs(self.main)
        self.hosts["path"]["main_checkout"] = self.main
        self.data = os.path.join(self.tmp, "releases.json")
        self.env_keep = dict(os.environ)
        self.addCleanup(self.restore_env)
        now = int(time.time())
        self.serials = {A: now - 3 * 86400, B: now - 86400}
        self.names = {A: names(A), B: names(B)}
        self.contents = {v: {n: body(n, v) for n in self.names[v].values()} for v in (A, B)}
        self.current = dict(self.contents[B])  # what the live release serves now, per file
        self.write_data()
        self.release_a = self.make_release(A)
        self.release_b = self.make_release(B)
        self.install_layout()
        self.mirror_env()
        self.apple = os.path.join(self.tmp, "apple")
        os.makedirs(self.apple)
        os.environ["PUBLISH_DIR"] = os.path.join(self.tmp, "nopublish")

    # ---- fixtures ----

    def install_layout(self):
        """What a release run leaves: A published and migrated, then B published into its own folder."""
        a, b = self.release_a, self.release_b
        for n, data in a["files"].items():
            pathlib.Path(self.site, "downloads", n).write_bytes(data)
        pathlib.Path(self.site, "index.html").write_bytes(a["page"])
        shutil.copyfile(os.path.join(a["dir"], "update.json"), os.path.join(self.site, "update.json"))
        shutil.copyfile(os.path.join(a["dir"], "update-v2.json"), os.path.join(self.api, "update.json"))
        self.server.relsrv("migrate", A)
        self.server.relsrv("begin", B)
        d = os.path.join(self.site, "versions", B, "downloads")
        for n in os.listdir(d):
            os.unlink(os.path.join(d, n))
        for n, data in b["files"].items():
            pathlib.Path(d, n).write_bytes(data)
        self.server.relsrv("flip", B)
        pathlib.Path(self.site, "index.html").write_bytes(b["page"])
        self.server.relsrv("keep-page", B)
        self.server.install_manifests({n: os.path.join(b["dir"], n) for n in ("update.json", "update-v2.json")})

    def write_data(self):
        recs = []
        for v in (B, A):
            fs = [{"name": n, "size": len(b), "sha256": sha(b)} for n, b in sorted(self.contents[v].items())]
            recs.append({"version": v, "date": "2026-11-1" + ("5" if v == B else "0"), "files": fs, "sig": True})
        # the older release keeps only slots the newer has no file for: here none, so the page lists B only
        recs = [recs[0]]
        write_json(self.data, {"releases": recs})
        self.render(os.path.join(self.tmp, "page-B"))
        recs = [dict(recs[0], version=A, files=[{"name": n, "size": len(b), "sha256": sha(b)} for n, b in sorted(self.contents[A].items())])]
        write_json(os.path.join(self.tmp, "data-A.json"), {"releases": recs})
        self.render(os.path.join(self.tmp, "page-A"), os.path.join(self.tmp, "data-A.json"))

    def render(self, out, data=None):
        env = dict(os.environ, WFE_RELEASES_DATA=data or self.data)
        subprocess.run(["python3", os.path.join(REPO, "tools/releases/build.py"), "render", "--out", out], check=True, capture_output=True, env=env)

    def payloads(self, v, serial):
        c = self.contents[v]
        n = self.names[v]
        apk = lambda key: {"abi": "arm64-v8a", "versionCode": 2611000 + int(v.split(".")[-1]), "url": OLD + n[key],
                           "sha256": sha(c[n[key]]), "size": len(c[n[key]])}
        dsk = lambda key: {"version": v, "url": OLD + n[key], "sha256": sha(c[n[key]]), "size": len(c[n[key]])}
        pl = {"schema": 1, "serial": serial, "issued_at": iso(serial), "expires_at": iso(serial + 45 * 86400),
              "packageName": "uk.btlabs.btwallet", "versionName": v, "notes": f"Notes {v}.",
              "apks": [apk(("android", "tor"))],
              "desktop": {p: dsk((p, "tor")) for p in ("windows", "linux", "macos")},
              "notor": {"apks": [apk(("android", "notor"))], "desktop": {p: dsk((p, "notor")) for p in ("windows", "linux", "macos")}}}
        return pl, json.loads(json.dumps(pl).replace(OLD, NEW))

    def make_release(self, v):
        d = os.path.join(self.tmp, "rel-" + v)
        os.makedirs(d)
        pl, v2 = self.payloads(v, self.serials[v])
        for pname, ename, p, is2 in (("update.payload.json", "update.json", pl, False), ("update-v2.payload.json", "update-v2.json", v2, True)):
            write_json(os.path.join(d, pname), p)
            sign(os.path.join(d, pname), os.path.join(d, ename), app_config=is2)
        files = dict(self.contents[v])
        prov = {"version": v, "commit": COMMIT, "files": {n: {"bytes": len(b), "sha256": sha(b), "step": "build"} for n, b in files.items()}}
        files["provenance.json"] = (json.dumps(prov, indent=2) + "\n").encode()
        files["sbom.cdx.json"] = b'{"bomFormat": "CycloneDX"}\n'
        sums = "".join(f"{sha(b)}  {n}\n" for n, b in sorted(files.items()))
        sp = os.path.join(d, "SHA256SUMS")
        pathlib.Path(sp).write_text(sums)
        self.sign_sums(sp, v)
        files["SHA256SUMS"] = pathlib.Path(sp).read_bytes()
        files["SHA256SUMS.sig"] = pathlib.Path(sp + ".sig").read_bytes() if os.path.exists(sp + ".sig") else pathlib.Path(d, "SHA256SUMS.sig").read_bytes()
        page = pathlib.Path(self.tmp, "page-" + ("A" if v == A else "B"), "index.html").read_bytes()
        return {"dir": d, "files": files, "page": page}

    def sign_sums(self, sums, v):
        key = private_key("test-a", os.path.dirname(sums))
        subprocess.run(["python3", os.path.join(REPO, "tools/rellib/steps/server_sums.py"), "sign-key", sums, key, v, RING,
                        os.path.join(REPO, "tools/release-files.py")], check=True, capture_output=True)

    def po(self, **kw):
        kw.setdefault("min_bytes", 100)
        kw.setdefault("no_github", True)
        kw.setdefault("data_path", self.data)
        kw.setdefault("apple_results", self.apple)
        p = PublishOne(REPO, self.root, self.pipeline, self.hosts, self.server, say=self.say, test=True, **kw)
        # the stand-ins for the Android tools: a file carries the release certificate when it holds MARK
        p.cert_of = lambda path: p.cert if MARK in pathlib.Path(path).read_bytes() else None
        p.sign_apk = self.fake_sign_apk
        return p

    def fake_sign_apk(self, src, out_dir):
        self.signer_calls = getattr(self, "signer_calls", []) + [os.path.basename(src)]
        os.makedirs(os.path.join(out_dir, "out"), exist_ok=True)
        out = os.path.join(out_dir, "out", os.path.basename(src))
        pathlib.Path(out).write_bytes(pathlib.Path(src).read_bytes() + MARK)
        return out

    def built(self, platform, variant, tag="rebuilt", version=B):
        """A newly built file of the slot in a folder of its own (as a build leaves it)."""
        name = self.names[version][(platform, variant)]
        d = os.path.join(self.tmp, "built", platform + variant)
        os.makedirs(d, exist_ok=True)
        p = os.path.join(d, name)
        pathlib.Path(p).write_bytes(body(name, tag))
        return p

    def mac_report(self, path, commit=COMMIT, team=TEAM):
        name = os.path.basename(path)
        s = sha(pathlib.Path(path).read_bytes())
        for f in os.listdir(self.apple):
            os.unlink(os.path.join(self.apple, f))
        shutil.copyfile(path, os.path.join(self.apple, name))
        pathlib.Path(self.apple, name + ".sha256").write_text(f"{s}  {name}\n")
        pathlib.Path(self.apple, name[:-4] + ".REPORT.txt").write_text(
            f"commit: {commit}\nsha256: {s}\nTeamIdentifier={team}\nTeamIdentifier={team}\n"
            "accepted\nsource=Notarized Developer ID\naccepted\nsource=Notarized Developer ID\n")

    def live(self):
        return {"v1": payload(self.server.fetch("update.json")), "v2": payload(self.server.fetch("update-v2.json")),
                "page": self.server.fetch("page")}

    def folder(self, v):
        return os.path.join(self.site, "versions", v, "downloads")

    # ---- the proof: one timed publish-one per configuration ----

    def publish(self, platform, variant, tag="rebuilt", entry_key=None, before_publish=None):
        path = self.built(platform, variant, tag)
        name = os.path.basename(path)
        if platform == "macos":
            self.mac_report(path)
        files_before = {n: sha(pathlib.Path(self.folder(B), n).read_bytes()) for n in os.listdir(self.folder(B))}
        a_before = self.other_release()
        before = self.live()
        t0 = time.monotonic()
        res = self.po().run(platform, variant, path)
        secs = time.monotonic() - t0
        self.assertTrue(res["ok"], "\n".join(self.log[-40:]))
        print(f"\n[publish-one {platform} {variant}] " + ", ".join(f"{k} {v:.1f} s" for k, v in res["parts"].items()) + f"; live and read back {res['live']:.1f} s; total {secs:.1f} s", flush=True)
        self.assertLess(secs, pubone.BAR_SECONDS)
        new = pathlib.Path(path).read_bytes()
        served = pathlib.Path(self.folder(B), name).read_bytes()
        expected = new + MARK if platform == "android" else new
        self.assertEqual(served, expected)
        files_after = {n: sha(pathlib.Path(self.folder(B), n).read_bytes()) for n in os.listdir(self.folder(B))}
        changed = {n for n in files_after if files_before.get(n) != files_after[n]}
        self.assertEqual(changed, {name, "provenance.json", "SHA256SUMS", "SHA256SUMS.sig"})
        self.assertEqual(self.other_release(), a_before, "the other release's files and page are untouched")
        # listing: lists the folder exactly, signature verifies
        sums = pathlib.Path(self.folder(B), "SHA256SUMS").read_text()
        listed = {l.split("  ")[1]: l.split("  ")[0] for l in sums.splitlines()}
        self.assertEqual(listed, {n: h for n, h in files_after.items() if n not in ("SHA256SUMS", "SHA256SUMS.sig")})
        self.assertEqual(listed[name], sha(served))
        prov = json.loads(pathlib.Path(self.folder(B), "provenance.json").read_text())
        self.assertEqual(prov["files"][name]["sha256"], sha(served))
        self.assertEqual(prov["files"][name]["step"], "publish-one")
        self.assertEqual(prov["commit"], COMMIT)
        for n, e in prov["files"].items():
            if n != name:
                self.assertEqual(e["sha256"], sha(self.current[n]), n)
        after = self.live()
        # the page: this file's slot has the new hash, the other slots keep theirs
        page = after["page"].decode()
        self.assertIn(sha(served), page)
        self.assertNotIn(sha(self.current[name]), page)
        for n, b in self.current.items():
            if n != name and not n.endswith("-unsigned.ipa"):
                self.assertIn(sha(b)[:12], page.replace(sha(served), ""), n)
        # the data file on main: this file only
        recs = json.load(open(self.data))["releases"]
        self.assertEqual({f["name"]: f["sha256"] for f in recs[0]["files"]}[name], sha(served))
        self.current[name] = served
        return res, before, after, name, served

    def other_release(self):
        """The older release as a visitor would get it: its files, its page. (Its spare manifests
        are refreshed by every publish: that is the ladder.)"""
        t = tree(os.path.join(self.site, "versions", A))
        return {k: v for k, v in t.items() if k.startswith("downloads/") or k == "index.html"}

    def entry(self, p, platform, variant):
        root = p["notor"] if variant == "notor" else p
        return root["apks"][0] if platform == "android" else root["desktop"][platform]

    def check_manifests(self, platform, variant, before, after, name, served, listed=True):
        for k in ("v1", "v2"):
            self.assertGreater(after[k]["serial"], before[k]["serial"])
            self.assertEqual(after["v1"]["serial"], after["v2"]["serial"])
            if not listed:
                self.assertEqual(differences(before[k], after[k]), [])
                continue
            top = "notor" if variant == "notor" else ("apks" if platform == "android" else "desktop")
            self.assertEqual(differences(before[k], after[k]), [top])
            old_e, new_e = self.entry(before[k], platform, variant), self.entry(after[k], platform, variant)
            self.assertEqual(new_e["sha256"], sha(served))
            self.assertEqual(new_e["size"], len(served))
            self.assertTrue(new_e["url"].endswith("/" + name))
            self.assertEqual(new_e["url"].rsplit("/", 1)[0], old_e["url"].rsplit("/", 1)[0])
            # only that entry differs
            strip = lambda p: json.loads(json.dumps(p).replace(new_e["sha256"], old_e["sha256"]))
            a, b = json.loads(json.dumps(before[k])), strip(after[k])
            for d in (a, b):
                for x in ("serial", "issued_at", "expires_at"):
                    d.pop(x)
            ea, eb = self.entry(a, platform, variant), self.entry(b, platform, variant)
            ea.pop("size"), eb.pop("size")
            self.assertEqual(a, b)
        self.assertTrue(verifies(os.path.join(self.site, "update.json"), False))
        self.assertTrue(verifies(os.path.join(self.api, "update.json"), True))

    def one(self, platform, variant, **kw):
        res, before, after, name, served = self.publish(platform, variant, **kw)
        self.check_manifests(platform, variant, before, after, name, served)
        # the Pages mirror holds the same pair
        raw = os.path.join(self.tmp, "raw", "main")
        self.assertEqual(pathlib.Path(raw, "update-v2.json").read_bytes(), self.server.fetch("update-v2.json"))
        return res

    def test_windows_tor(self):
        self.one("windows", "tor")

    def test_windows_notor(self):
        self.one("windows", "notor")

    def test_linux_tor(self):
        self.one("linux", "tor")

    def test_linux_notor(self):
        self.one("linux", "notor")

    def test_android_tor_unsigned_goes_to_the_signer(self):
        self.one("android", "tor")
        self.assertEqual(self.signer_calls, [self.names[B][("android", "tor")]])
        prov = json.loads(pathlib.Path(self.folder(B), "provenance.json").read_text())
        e = prov["files"][self.names[B][("android", "tor")]]
        self.assertEqual(e["unsigned_sha256"], sha(body(self.names[B][("android", "tor")], "rebuilt")))
        self.assertEqual(e["signed_by"], "signer")

    def test_android_notor_already_signed_is_not_sent(self):
        path = self.built("android", "notor")
        pathlib.Path(path).write_bytes(pathlib.Path(path).read_bytes() + MARK)
        before = self.live()
        res = self.po().run("android", "notor", path)
        self.assertTrue(res["ok"], self.log[-30:])
        self.assertFalse(hasattr(self, "signer_calls"))
        served = pathlib.Path(self.folder(B), os.path.basename(path)).read_bytes()
        self.assertEqual(served, pathlib.Path(path).read_bytes())
        self.check_manifests("android", "notor", before, self.live(), os.path.basename(path), served)

    def test_android_signed_by_another_key_is_refused(self):
        path = self.built("android", "tor")
        po = self.po()
        po.cert_of = lambda p: "ab" * 32
        before = tree(self.srvroot)
        with self.assertRaisesRegex(PublishOneError, "another certificate"):
            po.run("android", "tor", path)
        self.assertEqual(tree(self.srvroot), before)

    def test_macos_tor(self):
        self.one("macos", "tor")

    def test_macos_notor(self):
        self.one("macos", "notor")

    def test_macos_without_the_mac_report_is_refused(self):
        path = self.built("macos", "tor")
        before = tree(self.srvroot)
        with self.assertRaisesRegex(PublishOneError, "not shown to be signed and notarised"):
            self.po().run("macos", "tor", path)
        self.assertEqual(tree(self.srvroot), before)

    def test_macos_report_of_another_commit_is_refused(self):
        path = self.built("macos", "tor")
        self.mac_report(path, commit="deadbeef")
        before = tree(self.srvroot)
        with self.assertRaisesRegex(PublishOneError, "commit"):
            self.po().run("macos", "tor", path)
        self.assertEqual(tree(self.srvroot), before)

    def test_ios_is_recorded_but_has_no_page_download_and_no_manifest_entry(self):
        path = self.built("ios", "notor")
        before = self.live()
        files_before = os.listdir(self.folder(B))
        res = self.po().run("ios", "notor", path)
        self.assertTrue(res["ok"], self.log[-30:])
        after = self.live()
        served = pathlib.Path(self.folder(B), os.path.basename(path)).read_bytes()
        self.assertEqual(served, pathlib.Path(path).read_bytes())
        self.assertEqual(sorted(os.listdir(self.folder(B))), sorted(files_before))
        # the manifests are exactly as they were
        self.assertEqual(before["v1"], after["v1"])
        self.assertEqual(before["v2"], after["v2"])
        self.assertTrue(any("no entry for this file" in l for l in self.log))
        recs = json.load(open(self.data))["releases"]
        self.assertEqual({f["name"]: f["sha256"] for f in recs[0]["files"]}[os.path.basename(path)], sha(served))

    def github_setup(self):
        """Both releases on a fake GitHub: assets under their stable names, a SHA256SUMS listing both
        names (signed with the test key), the page record of the live release marked as mirrored."""
        self.gh = FakeGitHub()
        self.addCleanup(self.gh.close)
        rf = os.path.join(REPO, "tools/release-files.py")
        for v, rel in ((A, self.release_a), (B, self.release_b)):
            r = self.gh.add_release("v" + v, latest=(v == B))
            files = {n: b for n, b in rel["files"].items() if not n.startswith("SHA256SUMS")}
            lines = {}
            for n, b in files.items():
                lines[n] = lines[n.replace(f"-{v}", "", 1)] = sha(b)
            d = os.path.join(self.tmp, "gh-" + v)
            os.makedirs(d)
            sums = os.path.join(d, "SHA256SUMS")
            pathlib.Path(sums).write_text("".join(f"{h}  {n}\n" for n, h in sorted(lines.items())))
            self.sign_sums(sums, v)
            assets = {n.replace(f"-{v}", "", 1): b for n, b in files.items()}
            assets["SHA256SUMS"] = pathlib.Path(sums).read_bytes()
            assets["SHA256SUMS.sig"] = pathlib.Path(sums + ".sig").read_bytes() if os.path.exists(sums + ".sig") else pathlib.Path(d, "SHA256SUMS.sig").read_bytes()
            assets["update-v2.json"] = pathlib.Path(rel["dir"], "update-v2.json").read_bytes()
            for n, data in assets.items():
                a = {"id": self.gh.next_id, "name": n, "label": None, "size": len(data), "digest": "sha256:" + sha(data)}
                self.gh.next_id += 1
                self.gh.blobs[a["id"]] = data
                r["assets"].append(a)
        bin_ = os.path.join(self.tmp, "bin")
        os.makedirs(bin_)
        pathlib.Path(bin_, "gh").write_text(FAKE_GH)
        os.chmod(os.path.join(bin_, "gh"), 0o755)
        os.environ.update(PATH=f"{bin_}:{os.environ['PATH']}", FAKE_DIR=self.tmp, GITHUB_RELEASE_API=self.gh.base,
                          GITHUB_RELEASE_WEB=f"{self.gh.base}/web")
        for k in ("GH_CONFIG_DIR", "GITHUB_USER", "GH_TOKEN", "GITHUB_TOKEN"):
            os.environ.pop(k, None)
        data = json.load(open(self.data))
        data["releases"][0]["github"] = True
        write_json(self.data, data)

    def gh_assets(self, v):
        rel = next(r for r in self.gh.releases.values() if r["tag_name"] == "v" + v)
        return {a["name"]: self.gh.blobs[a["id"]] for a in rel["assets"]}

    def test_github_mirror_gets_the_file_and_a_new_signed_listing(self):
        self.github_setup()
        a_before = self.gh_assets(A)
        b_before = self.gh_assets(B)
        path = self.built("windows", "tor")
        name = os.path.basename(path)
        stable = name.replace(f"-{B}", "", 1)
        t0 = time.monotonic()
        res = self.po(no_github=False, github_repo=REPO_NAME).run("windows", "tor", path)
        print(f"\n[publish-one windows tor, with the GitHub mirror] " + ", ".join(f"{k} {v:.1f} s" for k, v in res["parts"].items()) +
              f"; live and read back {res['live']:.1f} s; total {time.monotonic() - t0:.1f} s", flush=True)
        self.assertTrue(res["ok"], "\n".join(self.log[-30:]))
        self.assertEqual(res["warnings"], [])
        after = self.gh_assets(B)
        self.assertEqual(after[stable], pathlib.Path(path).read_bytes())
        sums = after["SHA256SUMS"].decode()
        self.assertIn(f"{sha(after[stable])}  {name}\n", sums)
        self.assertIn(f"{sha(after[stable])}  {stable}\n", sums)
        self.assertEqual({l.split("  ")[1] for l in sums.splitlines()},
                         {l.split("  ")[1] for l in b_before["SHA256SUMS"].decode().splitlines()} | {"provenance.json"})
        d = os.path.join(self.tmp, "ghverify")
        os.makedirs(d)
        pathlib.Path(d, "SHA256SUMS").write_bytes(after["SHA256SUMS"])
        pathlib.Path(d, "SHA256SUMS.sig").write_bytes(after["SHA256SUMS.sig"])
        v = subprocess.run(["python3", os.path.join(REPO, "tools/release-files.py"), "verify", os.path.join(d, "SHA256SUMS"), "--keyring", RING],
                           capture_output=True, text=True)
        self.assertEqual(v.returncode, 0, v.stderr)
        for n, b in b_before.items():
            if n not in (stable, "SHA256SUMS", "SHA256SUMS.sig", "provenance.json"):
                self.assertEqual(after[n], b, n)
        # the older release: only its spare manifest (the ladder) is new
        a_after = self.gh_assets(A)
        for n, b in a_before.items():
            if n != "update-v2.json":
                self.assertEqual(a_after[n], b, n)

    def test_the_play_bundle_is_refused_with_its_way(self):
        p = os.path.join(self.tmp, f"bt-wallet-{B}-play-android.aab")
        pathlib.Path(p).write_bytes(b"PK\x03\x04" + b"x" * 400)
        with self.assertRaisesRegex(PublishOneError, "Play"):
            self.po().run("android", "tor", p)

    # ---- refusals change nothing ----

    def test_refusals(self):
        before = tree(self.srvroot)
        win = self.built("windows", "tor")
        for args, why in (
            (("windows", "notor", win), "is a windows tor file, not windows notor"),
            (("linux", "tor", win), "is a windows tor file, not linux tor"),
            (("windows", "tor", win, "26.11.9"), "is version 26.11.4, not 26.11.9"),
        ):
            with self.assertRaisesRegex(PublishOneError, why):
                self.po().run(*args[:3], version=args[3] if len(args) > 3 else None)
        small = os.path.join(self.tmp, "small", names(B)[("windows", "tor")])
        os.makedirs(os.path.dirname(small))
        pathlib.Path(small).write_bytes(b"MZ" + b"0" * 10)
        with self.assertRaisesRegex(PublishOneError, "only 12 bytes"):
            self.po().run("windows", "tor", small)
        bad = os.path.join(self.tmp, "bad", names(B)[("windows", "tor")])
        os.makedirs(os.path.dirname(bad))
        pathlib.Path(bad).write_bytes(b"ZZ" + b"0" * 400)
        with self.assertRaisesRegex(PublishOneError, "not a Windows executable"):
            self.po().run("windows", "tor", bad)
        self.assertEqual(tree(self.srvroot), before)

    def test_a_file_of_the_other_release_is_refused(self):
        """After a rollback, A is live: B's installer is refused (roll forward first)."""
        self.po().refresh_ladder(os.path.join(self.tmp, "presign"))
        f = Flip(REPO, self.server, os.path.join(self.tmp, "flip"), say=self.say)
        f.run("rollback", parts=("site", "readback", "mirrors"))
        before = tree(self.srvroot)
        with self.assertRaisesRegex(PublishOneError, f"{A} is live: roll back or forward first"):
            self.po().run("windows", "tor", self.built("windows", "tor"))
        self.assertEqual(tree(self.srvroot), before)

    def test_dry_run_changes_nothing(self):
        path = self.built("windows", "tor")
        before = tree(self.srvroot), pathlib.Path(self.data).read_bytes()
        res = self.po().run("windows", "tor", path, dry=True)
        self.assertTrue(res["dry"])
        self.assertEqual((tree(self.srvroot), pathlib.Path(self.data).read_bytes()), before)
        out = "\n".join(self.log)
        self.assertIn("dry run: nothing changes", out)
        self.assertIn("update-v2.json: entry", out)

    def test_the_command_line(self):
        """tools/rel publish-one --test-root: a dry run, then the real thing, exit codes and the line it prints."""
        import io
        from contextlib import redirect_stderr, redirect_stdout
        from rellib.cli import main
        name = self.names[B][("windows", "notor")]
        d = os.path.join(self.tmp, "built-cli")
        os.makedirs(d)
        path = os.path.join(d, name)
        pathlib.Path(path).write_bytes(body(name, "cli") + b"\0" * 1_100_000)

        def rel(*args):
            out, err = io.StringIO(), io.StringIO()
            with redirect_stdout(out), redirect_stderr(err):
                code = main(["--state-root", self.root, "--hosts", os.path.join(self.tmp, "no-hosts.toml"), "publish-one", "windows", "notor", path,
                             "--test-root", self.srvroot, "--data", self.data, "--no-github", *args])
            return code, out.getvalue() + err.getvalue()

        before = tree(self.srvroot), pathlib.Path(self.data).read_bytes()
        code, out = rel("--dry-run")
        self.assertEqual(code, 0, out)
        self.assertEqual((tree(self.srvroot), pathlib.Path(self.data).read_bytes()), before)
        code, out = rel("--version", A)
        self.assertNotEqual(code, 0)
        self.assertIn(A, out)
        code, out = rel()
        self.assertEqual(code, 0, out)
        self.assertIn(f"published {name}", out)
        self.assertEqual(self.server.fetch("download", name), pathlib.Path(path).read_bytes())

    # ---- what a publish-one leaves behind ----

    def test_the_rollback_ladder_is_fresh_afterwards(self):
        """The live release's spare manifests name the file that was replaced: rolling back to A and
        forward to B again must serve B's new file and an entry that matches it."""
        self.po().refresh_ladder(os.path.join(self.tmp, "presign0"))
        res, before, after, name, served = self.publish("windows", "tor")
        f = Flip(REPO, self.server, os.path.join(self.tmp, "flip1"), say=self.say)
        r = f.run("rollback", parts=("site", "readback", "mirrors"))
        self.assertTrue(r["ok"], self.log[-20:])
        self.assertEqual(self.live()["v2"]["versionName"], A)
        r = Flip(REPO, self.server, os.path.join(self.tmp, "flip2"), say=self.say).run("rollforward", parts=("site", "readback", "mirrors"))
        self.assertTrue(r["ok"], self.log[-20:])
        back = self.live()
        self.assertEqual(back["v2"]["versionName"], B)
        self.assertEqual(self.entry(back["v2"], "windows", "tor")["sha256"], sha(served))
        self.assertGreater(back["v2"]["serial"], after["v2"]["serial"])
        self.assertIn(sha(served), back["page"].decode())

    def test_two_publishes_in_a_row_keep_both(self):
        self.publish("windows", "tor", tag="first")
        res, before, after, name, served = self.publish("windows", "notor", tag="second")
        self.assertEqual(self.entry(after["v2"], "windows", "tor")["sha256"], sha(body(self.names[B][("windows", "tor")], "first")))
        self.check_manifests("windows", "notor", before, after, name, served)


if __name__ == "__main__":
    unittest.main()
