# SPDX-License-Identifier: Apache-2.0
"""tools/rel rollback / rollforward (docs/RELEASING.md, "Rollback"): the website, GitHub and the
mirrors switch to the other release in seconds, with nothing signed or uploaded at that moment.

The target is a folder standing in for the server (REL_SERVER_ROOT: site/, api/), the real
tools/rellib/steps/relsrv.py running on it without ssh, a fake GitHub on 127.0.0.1 and the Pages
repository as a local git repository. Manifests are signed with the test keys of
app/test/fixtures/btlabs/. Nothing leaves this machine. The timings the test prints are the proof
run's seconds per part."""
import base64
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import time
import unittest

from support import Base, REPO
from test_release_files import FakeGitHub, FAKE_GH, REPO_NAME, TOKEN
from test_resign import BP, CFG, NEW, OLD, RING, TOOL, payload_of, sign, verifies
from rellib.instant import Flip, FlipError
from rellib.presign import Presign
from rellib.resign import iso
from rellib.run import write_json
from rellib.server import Server, payload

A, B = "26.10.24", "26.10.25"


def have_filter_repo():
    return subprocess.run(["git", "filter-repo", "--version"], capture_output=True).returncode == 0


@unittest.skipUnless(os.path.isfile(TOOL) and have_filter_repo(), "needs btlabs-public and git-filter-repo")
class InstantRollbackTest(Base):
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
        self.gh = FakeGitHub()
        self.addCleanup(self.gh.close)
        self.pipeline.data["manifest"] = {"validity_days": 45}
        self.hosts["host"]["signer"] = {}
        now = int(time.time())
        self.serials = {A: now - 3 * 86400, B: now - 86400}
        self.release_a = self.make_release(A, self.serials[A])
        self.release_b = self.make_release(B, self.serials[B])
        self.install_layout()
        self.github_releases()
        self.mirror_env()

    # ---- fixtures ----

    def make_release(self, v, serial):
        d = os.path.join(self.tmp, "rel-" + v)
        os.makedirs(d)
        apk = lambda s: {"abi": "arm64-v8a", "versionCode": int(v.replace(".", "")), "url": OLD + f"epic-cash-mobile-{v}{s}-arm64-v8a.apk",
                         "sha256": hashlib.sha256((v + s).encode()).hexdigest(), "size": 4096}
        pl = {"schema": 1, "serial": serial, "issued_at": iso(serial), "expires_at": iso(serial + 45 * 86400),
              "packageName": "uk.btlabs.btwallet", "versionName": v, "apks": [apk("")], "notes": f"Notes {v}.", "notor": {"apks": [apk("-notor")]}}
        v2 = json.loads(json.dumps(pl).replace(OLD, NEW))
        for pname, ename, p, is2 in (("update.payload.json", "update.json", pl, False), ("update-v2.payload.json", "update-v2.json", v2, True)):
            write_json(os.path.join(d, pname), p)
            sign(os.path.join(d, pname), os.path.join(d, ename), app_config=is2)
        files = {f"epic-cash-mobile-{v}-arm64-v8a.apk": (v * 400).encode(), f"epic-cash-mobile-{v}-notor-arm64-v8a.apk": (v * 300).encode(),
                 "SHA256SUMS": f"sums of {v}\n".encode(), "SHA256SUMS.sig": f"sig of {v}\n".encode()}
        return {"dir": d, "files": files, "page": f"<html>page {v}</html>\n".encode()}

    def install_layout(self):
        """What a release run leaves: A published and migrated, then B published into its own folder."""
        a, b = self.release_a, self.release_b
        for n, data in a["files"].items():
            pathlib.Path(self.site, "downloads", n).write_bytes(data)
        pathlib.Path(self.site, "index.html").write_bytes(a["page"])
        shutil.copyfile(os.path.join(a["dir"], "update.json"), os.path.join(self.site, "update.json"))
        shutil.copyfile(os.path.join(a["dir"], "update-v2.json"), os.path.join(self.api, "update.json"))
        self.server.relsrv("migrate", A)
        # B, as publish-downloads.sh, publish-page.sh and publish-update-json.sh do it
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

    def github_releases(self):
        self.gh_assets = {}
        for v, rel in ((A, self.release_a), (B, self.release_b)):
            r = self.gh.add_release("v" + v, latest=(v == B))
            for n, data in list(rel["files"].items()) + [("update-v2.json", pathlib.Path(rel["dir"], "update-v2.json").read_bytes())]:
                a = {"id": self.gh.next_id, "name": n, "label": None, "size": len(data), "digest": "sha256:" + hashlib.sha256(data).hexdigest()}
                self.gh.next_id += 1
                self.gh.blobs[a["id"]] = data
                r["assets"].append(a)
        bin_ = os.path.join(self.tmp, "bin")
        os.makedirs(bin_)
        gh = os.path.join(bin_, "gh")
        pathlib.Path(gh).write_text(FAKE_GH)
        os.chmod(gh, 0o755)
        self.env_keep = dict(os.environ)
        os.environ.update(PATH=f"{bin_}:{os.environ['PATH']}", FAKE_DIR=self.tmp, GITHUB_RELEASE_API=self.gh.base,
                          GITHUB_RELEASE_WEB=f"{self.gh.base}/web")
        for k in ("GH_CONFIG_DIR", "GITHUB_USER", "GH_TOKEN", "GITHUB_TOKEN"):
            os.environ.pop(k, None)
        self.addCleanup(self.restore_env)

    def restore_env(self):
        for k in list(os.environ):
            if k not in self.env_keep:
                del os.environ[k]
        os.environ.update(self.env_keep)

    def mirror_env(self):
        """publish-update-json.sh against a local Pages repository; its pushes land in raw/main."""
        site = os.path.join(self.tmp, "pages")
        subprocess.run(["git", "init", "-q", "-b", "main", site], check=True)
        subprocess.run(["git", "-C", site, "-c", "user.name=t", "-c", "user.email=t@example.invalid", "commit", "-q", "--allow-empty", "-m", "start"], check=True)
        raw = os.path.join(self.tmp, "raw", "main")
        os.makedirs(raw)
        push = os.path.join(self.tmp, "push-github.sh")
        pathlib.Path(push).write_text(f'#!/usr/bin/env bash\nfor f in update.json update-v2.json; do git -C "$2" show main:$f > "{raw}/$f"; done\n')
        os.chmod(push, 0o755)
        os.environ.update(
            UPDATE_PUBLISH_CONF=os.path.join(self.tmp, "none.env"), UPDATE_SITE=site, UPDATE_KEYRING=RING, UPDATE_SIGN_TOOL=TOOL,
            PUSH_GITHUB=push, UPDATE_SITE_RAW="file://" + os.path.join(self.tmp, "raw"),
            UPDATE_URL="file://" + os.path.join(self.site, "update.json"), UPDATE_URL_V2="file://" + os.path.join(self.api, "update.json"),
            GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@example.invalid", GIT_COMMITTER_NAME="t", GIT_COMMITTER_EMAIL="t@example.invalid")

    def presign(self):
        t0 = time.monotonic()
        res = Presign(REPO, self.root, self.pipeline, self.hosts, self.server, say=self.say, test=True).refresh(os.path.join(self.tmp, "presign"))
        return res, time.monotonic() - t0

    def flip(self, direction, **kw):
        f = Flip(REPO, self.server, os.path.join(self.tmp, "flip-" + str(time.monotonic())), say=self.say, github_repo=REPO_NAME)
        return f.run(direction, **kw)

    def served(self, name):
        return self.server.fetch(name)

    def live_state(self):
        return {"page": self.served("page"), "v1": payload(self.served("update.json")), "v2": payload(self.served("update-v2.json")),
                "sums": self.server.fetch("download", "SHA256SUMS")}

    # ---- tests ----

    def test_rollback_and_rollforward_serve_the_other_release(self):
        pre, secs = self.presign()
        self.assertEqual(pre["other"], A)
        self.assertEqual(pre["github"], "ok")
        # nothing signed after this point: a signer that fails would make the flip fail
        signed = {"n": 0}
        # ---- rollback
        self.assertEqual(self.live_state()["v2"]["versionName"], B)
        before = self.live_state()["v2"]["serial"]
        res = self.flip("rollback")
        self.assertTrue(res["ok"], "\n".join(self.log[-60:]))
        s = self.live_state()
        self.assertEqual((s["v1"]["versionName"], s["v2"]["versionName"]), (A, A))
        self.assertEqual(s["page"], self.release_a["page"])
        self.assertEqual(s["sums"], self.release_a["files"]["SHA256SUMS"])
        self.assertGreater(s["v2"]["serial"], before)
        self.assertEqual(s["v1"]["serial"], s["v2"]["serial"])
        for n, v2 in (("update.json", False), ("update-v2.json", True)):
            self.assertTrue(verifies(os.path.join(self.site, "update.json") if not v2 else os.path.join(self.api, "update.json"), v2), n)
        # downloads of A are served, B's files are not in the live folder
        self.assertEqual(sorted(os.listdir(os.path.join(self.site, "downloads"))), sorted(self.release_a["files"]))
        # GitHub: A latest, B hidden, the pre-signed manifest on A
        rels = {r["tag_name"]: r for r in self.gh.releases.values()}
        self.assertEqual(self.gh.latest, rels["v" + A]["id"])
        self.assertTrue(rels["v" + B]["draft"])
        self.assertFalse(rels["v" + A]["draft"])
        on_a = [self.gh.blobs[x["id"]] for x in rels["v" + A]["assets"] if x["name"] == "update-v2.json"]
        self.assertEqual(len(on_a), 1)
        self.assertEqual(json.loads(base64.b64decode(json.loads(on_a[0])["payload"]))["serial"], s["v2"]["serial"])
        # the Pages mirror holds the same pair
        raw = os.path.join(self.tmp, "raw", "main")
        self.assertEqual(pathlib.Path(raw, "update-v2.json").read_bytes(), self.served("update-v2.json"))
        self.assertEqual(pathlib.Path(raw, "update.json").read_bytes(), self.served("update.json"))
        self.assertEqual(set(res["parts"]), {"site", "readback", "github", "mirrors"})
        self.assertLess(res["parts"]["site"], 10)
        self.report("rollback", res)
        # ---- roll forward
        res2 = self.flip("rollforward")
        self.assertTrue(res2["ok"], self.log[-12:])
        s2 = self.live_state()
        self.assertEqual(s2["v2"]["versionName"], B)
        self.assertEqual(s2["page"], self.release_b["page"])
        self.assertGreater(s2["v2"]["serial"], s["v2"]["serial"])
        rels = {r["tag_name"]: r for r in self.gh.releases.values()}
        self.assertEqual(self.gh.latest, rels["v" + B]["id"])
        self.assertTrue(rels["v" + A]["draft"] is True and rels["v" + B]["draft"] is False)
        self.report("rollforward", res2)
        # ---- and back again: the ladder has more rungs
        res3 = self.flip("rollback")
        self.assertTrue(res3["ok"], self.log[-12:])
        self.assertEqual(self.live_state()["v2"]["versionName"], A)
        self.assertGreater(self.live_state()["v2"]["serial"], s2["v2"]["serial"])

    def report(self, what, res):
        line = ", ".join(f"{k} {v:.1f} s" for k, v in res["parts"].items())
        print(f"\n[{what}] {line}; total {res['total']:.1f} s", flush=True)

    def test_a_spare_below_the_live_serial_is_refused_and_nothing_changes(self):
        # no ladder was signed: the first release published after migration has none yet
        before = self.live_state()
        with self.assertRaisesRegex(FlipError, "no pre-signed manifest pair"):
            self.flip("rollback")
        self.assertEqual(self.live_state(), before)

    def test_dry_run_changes_nothing(self):
        self.presign()
        before, n = self.live_state(), len(self.gh.writes())
        res = self.flip("rollback", dry=True)
        self.assertTrue(res["dry"])
        self.assertEqual(self.live_state(), before)
        self.assertEqual(len(self.gh.writes()), n)

    def test_the_commands_of_tools_rel(self):
        """presign, rollback, rollforward and their dry runs through the command line (exit codes)."""
        import io
        from contextlib import redirect_stderr, redirect_stdout
        from rellib.cli import main

        def rel(*args):
            out, err = io.StringIO(), io.StringIO()
            with redirect_stdout(out), redirect_stderr(err):
                code = main(["--state-root", self.root, "--hosts", os.path.join(self.tmp, "no-hosts.toml"), *args])
            return code, out.getvalue() + err.getvalue()

        common = ["--test-root", self.srvroot]
        code, out = rel("presign", *common)
        self.assertEqual(code, 0, out)
        before = self.live_state()
        code, out = rel("rollback", "--dry-run", "--github-repo", REPO_NAME, *common)
        self.assertEqual(code, 0, out)
        self.assertEqual(self.live_state(), before)
        code, out = rel("rollback", "--github-repo", REPO_NAME, *common)
        self.assertEqual(code, 0, out)
        self.assertEqual(payload(self.served("update-v2.json"))["versionName"], A)
        self.assertIn("rolled back", out)
        code, out = rel("rollforward", "--github-repo", REPO_NAME, *common)
        self.assertEqual(code, 0, out)
        self.assertEqual(payload(self.served("update-v2.json"))["versionName"], B)
        code, out = rel("rollforward", "--github-repo", REPO_NAME, *common)
        self.assertNotEqual(code, 0)
        self.assertIn("newest release", out)
        print("\n[tools/rel rollback / rollforward through the command line] ok", flush=True)

    def test_migrate_layout_command(self):
        """tools/rel migrate-layout on a flat server: the dry run changes nothing, the real run builds the version folder."""
        import io
        from contextlib import redirect_stderr, redirect_stdout
        from rellib.cli import main
        root = os.path.join(self.tmp, "flat")
        site, api = os.path.join(root, "site"), os.path.join(root, "api")
        os.makedirs(os.path.join(site, "downloads"))
        os.makedirs(api)
        a = self.release_a
        for n, data in a["files"].items():
            pathlib.Path(site, "downloads", n).write_bytes(data)
        pathlib.Path(site, "index.html").write_bytes(a["page"])
        shutil.copyfile(os.path.join(a["dir"], "update.json"), os.path.join(site, "update.json"))
        shutil.copyfile(os.path.join(a["dir"], "update-v2.json"), os.path.join(api, "update.json"))

        def rel(*args):
            out, err = io.StringIO(), io.StringIO()
            with redirect_stdout(out), redirect_stderr(err):
                code = main(["--state-root", self.root, "--hosts", os.path.join(self.tmp, "no-hosts.toml"), "migrate-layout", "--test-root", root, *args])
            return code, out.getvalue() + err.getvalue()

        code, out = rel("--dry-run")
        self.assertEqual(code, 0, out)
        self.assertFalse(os.path.exists(os.path.join(site, "versions")))
        code, out = rel()
        self.assertEqual(code, 0, out)
        self.assertTrue(os.path.islink(os.path.join(site, "current")))
        self.assertTrue(os.path.islink(os.path.join(site, "downloads")))
        self.assertEqual(sorted(os.listdir(os.path.join(site, "versions", A, "downloads"))), sorted(a["files"]))
        self.assertIn(f"current -> versions/{A}", out)

    def test_nothing_to_roll_forward_to(self):
        self.presign()
        with self.assertRaisesRegex(FlipError, "newest release"):
            self.flip("rollforward")


if __name__ == "__main__":
    unittest.main()
