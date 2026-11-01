# SPDX-License-Identifier: Apache-2.0
"""The GitHub mirror of a release, against a fake GitHub on 127.0.0.1 and a fake gh: nothing
here talks to github.com. tools/gitlab-release.py makes the release (latest, every file an
asset, writes a second apart, BT Labs' login only, no token printed) and puts update-v2.json on
the latest release; tools/publish-update-json.sh runs that step only when switched on and never
fails on it. The server, GitLab and git push are shims."""
import base64
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import tempfile
import threading
import time
import unittest
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from support import REPO

BP = os.path.expanduser(os.environ.get("BTLABS_PUBLIC", "~/code/btlabs-public"))
SIGN = os.path.join(BP, "tool/btlabs_sign.py")
TOOL = os.path.join(REPO, "tools/gitlab-release.py")
REPO_NAME = "BTLabsUK/wallet-for-epic"
TOKEN = "fake-token-0123456789"

FAKE_GH = f"""#!/usr/bin/env bash
echo "$GH_CONFIG_DIR $*" >> "$FAKE_DIR/gh.calls"
case "$1 $2" in
  "api user") echo "${{FAKE_GH_LOGIN:-btlabs-uk}}" ;;
  "auth token") echo {TOKEN} ;;
  *) exit 1 ;;
esac
"""


class FakeGitHub:
    """The few REST calls gitlab-release.py makes, for one repository, in memory."""

    def __init__(self):
        self.tags, self.releases, self.blobs, self.log = set(), {}, {}, []
        self.latest, self.next_id = None, 1
        fake = self

        class H(BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def reply(self, code, body=None, ctype="application/json", headers=()):
                data = json.dumps(body).encode() if ctype == "application/json" and body is not None else (body or b"")
                self.send_response(code)
                self.send_header("Content-Type", ctype)
                self.send_header("Content-Length", str(len(data)))
                for k, v in headers:
                    self.send_header(k, v)
                self.end_headers()
                self.wfile.write(data)

            def handle_any(self):
                n = int(self.headers.get("Content-Length") or 0)
                body = self.rfile.read(n) if n else b""
                fake.log.append((self.command, self.path, time.monotonic(), self.headers.get("Authorization")))
                code, out, ctype, hdrs = fake.route(self.command, self.path, body, self.headers)
                self.reply(code, out, ctype, hdrs)

            do_GET = do_POST = do_PATCH = do_DELETE = handle_any

        self.srv = ThreadingHTTPServer(("127.0.0.1", 0), H)
        self.base = f"http://127.0.0.1:{self.srv.server_address[1]}"
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()

    def close(self):
        self.srv.shutdown()
        self.srv.server_close()

    def writes(self):
        return [(m, p, t) for m, p, t, _ in self.log if m in ("POST", "PATCH", "DELETE")]

    def asset_json(self, a):
        return {k: a[k] for k in ("id", "name", "label", "size", "digest")} | {
            "url": f"{self.base}/repos/{REPO_NAME}/releases/assets/{a['id']}"}

    def rel_json(self, r):
        return {**{k: r[k] for k in ("id", "tag_name", "name", "body", "draft", "prerelease")},
                "upload_url": f"{self.base}/uploads/repos/{REPO_NAME}/releases/{r['id']}/assets{{?name,label}}",
                "assets": [self.asset_json(a) for a in r["assets"]]}

    def add_release(self, tag, latest=True):
        self.tags.add(tag)
        r = {"id": self.next_id, "tag_name": tag, "name": tag, "body": "", "draft": False, "prerelease": False,
             "assets": []}
        self.next_id += 1
        self.releases[r["id"]] = r
        if latest:
            self.latest = r["id"]
        return r

    def route(self, method, path, body, headers):
        u = urllib.parse.urlparse(path)
        p, q = u.path, dict(urllib.parse.parse_qsl(u.query))
        api = f"/repos/{REPO_NAME}"
        if p.startswith(api) and headers.get("Authorization") != f"Bearer {TOKEN}":
            return 401, {"message": "Bad credentials"}, "application/json", ()
        by_tag = {r["tag_name"]: r for r in self.releases.values()}
        m = re.fullmatch(api + r"/releases/tags/(.+)", p)
        if method == "GET" and m:
            r = by_tag.get(urllib.parse.unquote(m[1]))
            return (200, self.rel_json(r), "application/json", ()) if r else (404, {}, "application/json", ())
        m = re.fullmatch(api + r"/git/ref/tags/(.+)", p)
        if method == "GET" and m:
            return (200 if urllib.parse.unquote(m[1]) in self.tags else 404), {}, "application/json", ()
        if method == "GET" and p == api + "/releases/latest":
            r = self.releases.get(self.latest)
            return (200, self.rel_json(r), "application/json", ()) if r else (404, {}, "application/json", ())
        if method == "POST" and p == api + "/releases":
            b = json.loads(body)
            r = self.add_release(b["tag_name"], latest=b.get("make_latest") == "true")
            r.update(name=b["name"], body=b["body"], draft=b["draft"], prerelease=b["prerelease"])
            return 201, self.rel_json(r), "application/json", ()
        m = re.fullmatch(api + r"/releases/(\d+)", p)
        if method == "PATCH" and m:
            r, b = self.releases[int(m[1])], json.loads(body)
            r.update({k: v for k, v in b.items() if k in ("name", "body", "draft", "prerelease")})
            if b.get("make_latest") == "true":
                self.latest = r["id"]
            return 200, self.rel_json(r), "application/json", ()
        m = re.fullmatch(api + r"/releases/assets/(\d+)", p)
        if m:
            aid = int(m[1])
            rel = next((r for r in self.releases.values() if any(a["id"] == aid for a in r["assets"])), None)
            if rel is None:
                return 404, {}, "application/json", ()
            a = next(a for a in rel["assets"] if a["id"] == aid)
            if method == "DELETE":
                rel["assets"].remove(a)
                return 204, b"", "text/plain", ()
            if method == "PATCH":
                a.update(json.loads(body))
                return 200, self.asset_json(a), "application/json", ()
            return 200, self.blobs[aid], "application/octet-stream", ()
        m = re.fullmatch(r"/uploads" + api + r"/releases/(\d+)/assets", p)
        if method == "POST" and m:
            rel = self.releases[int(m[1])]
            if any(a["name"] == q["name"] for a in rel["assets"]):
                return 422, {"message": "already_exists"}, "application/json", ()
            a = {"id": self.next_id, "name": q["name"], "label": q.get("label"), "size": len(body),
                 "digest": "sha256:" + hashlib.sha256(body).hexdigest()}
            self.next_id += 1
            self.blobs[a["id"]] = body
            rel["assets"].append(a)
            return 201, self.asset_json(a), "application/json", ()
        # The public web links redirect to the file, as github.com does.
        m = re.fullmatch(rf"/web/{REPO_NAME}/releases/(?:latest/download|download/([^/]+))/(.+)", p)
        if method == "GET" and m:
            rel = self.releases.get(self.latest) if m[1] is None else by_tag.get(m[1])
            a = next((a for a in (rel or {}).get("assets", []) if a["name"] == m[2]), None)
            if a is None:
                return 404, b"Not Found", "text/plain", ()
            return 302, b"", "text/plain", (("Location", f"{self.base}/blob/{a['id']}"),)
        m = re.fullmatch(r"/blob/(\d+)", p)
        if method == "GET" and m:
            return 200, self.blobs[int(m[1])], "application/octet-stream", ()
        return 404, {"message": f"fake: no route {method} {p}"}, "application/json", ()


@unittest.skipUnless(os.path.isfile(SIGN), "needs btlabs-public (its test keys)")
class GitHubReleaseTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="ghrel-")
        self.gh = FakeGitHub()
        bin_ = os.path.join(self.tmp, "bin")
        os.makedirs(bin_)
        self.write_exe(os.path.join(bin_, "gh"), FAKE_GH)
        self.key = os.path.join(self.tmp, "test-a.key")
        shutil.copy(os.path.join(BP, "testdata/keys/test-a.key"), self.key)
        os.chmod(self.key, 0o600)
        self.ring = os.path.join(self.tmp, "ring.json")
        subprocess.run(["python3", SIGN, "keyring", "--out", self.ring, os.path.join(BP, "testdata/keys/test-a.pub.json")],
                       check=True, capture_output=True)
        self.env = {k: v for k, v in os.environ.items() if k not in ("GH_CONFIG_DIR", "GITHUB_USER", "GH_TOKEN", "GITHUB_TOKEN")}
        self.env.update(PATH=f"{bin_}:{os.environ['PATH']}", FAKE_DIR=self.tmp, GITHUB_RELEASE_API=self.gh.base,
                        GITHUB_RELEASE_WEB=f"{self.gh.base}/web")
        self.files = os.path.join(self.tmp, "files")
        os.makedirs(self.files)
        for n in ("epic-cash-mobile-26.10.25-arm64-v8a.apk", "EpicCashDesktop-26.10.25-x86_64.AppImage"):
            with open(os.path.join(self.files, n), "wb") as f:
                f.write(n.encode() * 100)
        self.notes = os.path.join(self.tmp, "notes.txt")
        with open(self.notes, "w") as f:
            f.write("Epic Cash 26.10.25.\n")

    def tearDown(self):
        self.gh.close()
        shutil.rmtree(self.tmp, ignore_errors=True)

    @staticmethod
    def write_exe(path, text):
        with open(path, "w") as f:
            f.write(text)
        os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)

    def tool(self, *args, env=None):
        p = subprocess.run(["python3", TOOL, *args], capture_output=True, text=True, timeout=120,
                           env=dict(self.env, **(env or {})))
        self.assertNotIn(TOKEN, p.stdout + p.stderr)
        return p.returncode, p.stdout + p.stderr

    def publish(self, *extra):
        return self.tool("publish", "26.10.25", self.files, "--target", "github", "--key", self.key,
                         "--keyring", self.ring, "--notes", self.notes, *extra)

    def envelope(self, serial):
        payload = base64.b64encode(json.dumps({"versionName": "26.10.25", "serial": serial}).encode()).decode()
        path = os.path.join(self.tmp, f"update-v2-{serial}.json")
        with open(path, "w") as f:
            json.dump({"payload": payload, "signatures": []}, f)
        return path

    def test_release_is_made_latest_with_every_file_and_writes_apart(self):
        self.gh.add_release("v26.10.24")
        self.gh.tags.add("v26.10.25")
        rc, out = self.publish()
        self.assertEqual(rc, 0, out)
        rel = next(r for r in self.gh.releases.values() if r["tag_name"] == "v26.10.25")
        self.assertEqual(self.gh.latest, rel["id"])
        self.assertFalse(rel["draft"] or rel["prerelease"])
        self.assertEqual(sorted(a["name"] for a in rel["assets"]),
                         ["EpicCashDesktop-x86_64.AppImage", "SHA256SUMS", "SHA256SUMS.sig", "epic-cash-mobile-arm64-v8a.apk"])
        self.assertIn("signature ok", out)
        self.assertIn("anonymous", out)
        self.assertIn(": 200 (same bytes)", out)
        w = self.gh.writes()
        self.assertEqual(len(w), 5)  # the release, then four uploads, one at a time
        self.assertTrue(all(b[2] - a[2] >= 0.9 for a, b in zip(w, w[1:])), w)
        with open(os.path.join(self.tmp, "gh.calls")) as f:
            calls = f.read()
        self.assertIn(os.path.expanduser("~/.config/gh-btlabs") + " api user", calls)
        # A re-run changes nothing; update-v2.json on the release (github-update-json's) is no refusal.
        rc, out = self.tool("github-update-json", self.envelope(1))
        self.assertEqual(rc, 0, out)
        n = len(self.gh.writes())
        rc, out = self.publish()
        self.assertEqual(rc, 0, out)
        self.assertEqual(len(self.gh.writes()), n, out)

    def test_the_pipeline_step_publishes_a_copy_of_the_run_files(self):
        self.gh.tags.add("v26.10.25")
        sums = subprocess.run(["sha256sum", *sorted(os.listdir(self.files))], cwd=self.files, capture_output=True,
                              text=True, check=True).stdout
        with open(os.path.join(self.files, "SHA256SUMS"), "w") as f:
            f.write(sums)
        with open(os.path.join(self.files, "provenance.json"), "w") as f:
            f.write("{}")
        bp = os.path.join(self.tmp, "bp")
        os.makedirs(os.path.join(bp, "keys"))
        shutil.copy(self.ring, os.path.join(bp, "keys/btlabs-keyring.json"))
        stage = os.path.join(self.tmp, "stage")
        os.makedirs(stage)
        p = subprocess.run(["bash", os.path.join(REPO, "tools/rellib/steps/publish-github-release.sh"), "26.10.25",
                            self.files, stage], capture_output=True, text=True, timeout=120,
                           env=dict(self.env, REL_SRC=REPO, REL_SIGNER_SIGNING_KEY=self.key,
                                    REL_SIGNER_BTLABS_PUBLIC=bp, REL_NOTES_FILE=self.notes))
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        rel = next(iter(self.gh.releases.values()))
        self.assertEqual(sorted(a["name"] for a in rel["assets"]),
                         ["EpicCashDesktop-x86_64.AppImage", "SHA256SUMS", "SHA256SUMS.sig", "epic-cash-mobile-arm64-v8a.apk"])
        self.assertEqual(rel["body"].splitlines()[0], "Epic Cash 26.10.25.")
        with open(os.path.join(self.files, "SHA256SUMS")) as f:
            self.assertEqual(f.read(), sums)  # the run's SHA256SUMS is left as G6 reads it
        self.assertFalse(os.path.exists(os.path.join(self.files, "SHA256SUMS.sig")))

    def test_dry_run_writes_nothing(self):
        self.gh.add_release("v26.10.24")
        self.gh.tags.add("v26.10.25")
        rc, out = self.publish("--dry-run")
        self.assertEqual(rc, 0, out)
        self.assertIn("[dry-run] POST /releases", out)
        self.assertEqual(self.gh.writes(), [])
        self.assertFalse(os.path.exists(os.path.join(self.files, "SHA256SUMS")))

    def test_no_tag_or_another_login_is_refused(self):
        rc, out = self.publish()
        self.assertNotEqual(rc, 0)
        self.assertIn("tag v26.10.25 is not on GitHub", out)
        self.gh.tags.add("v26.10.25")
        self.gh.log.clear()
        rc, out = self.tool("publish", "26.10.25", self.files, "--target", "github", "--key", self.key,
                            "--keyring", self.ring, "--notes", self.notes, env={"FAKE_GH_LOGIN": "someone-else"})
        self.assertNotEqual(rc, 0)
        self.assertIn("logged in as someone-else, not btlabs-uk", out)
        self.assertEqual([x for x in self.gh.log if x[1].startswith("/repos")], [])

    def test_update_json_replaces_the_asset_on_the_latest_release(self):
        rc, out = self.tool("github-update-json", self.envelope(1))
        self.assertNotEqual(rc, 0)
        self.assertIn("has no latest release", out)
        self.gh.add_release("v26.10.24", latest=False)
        latest = self.gh.add_release("v26.10.25")
        rc, out = self.tool("github-update-json", self.envelope(1))
        self.assertEqual(rc, 0, out)
        rc, out = self.tool("github-update-json", self.envelope(1))
        self.assertIn("already there", out)
        n = len(self.gh.writes())
        rc, out = self.tool("github-update-json", self.envelope(2), "--dry-run")
        self.assertEqual((rc, len(self.gh.writes())), (0, n), out)
        rc, out = self.tool("github-update-json", self.envelope(2))
        self.assertEqual(rc, 0, out)
        self.assertEqual([m for m, _, _ in self.gh.writes()[n:]], ["DELETE", "POST"])
        assets = [a for a in latest["assets"] if a["name"] == "update-v2.json"]
        self.assertEqual(len(assets), 1)
        self.assertEqual(self.gh.blobs[assets[0]["id"]], open(self.envelope(2), "rb").read())
        self.assertEqual([r for r in self.gh.releases.values() if r["tag_name"] == "v26.10.24"][0]["assets"], [])

    def publish_update_json(self, **env):
        # publish-update-json.sh rewrites the site history with git-filter-repo; like
        # tools/publish/test-incremental.sh, skip where it is not installed.
        if subprocess.run(["git", "filter-repo", "--version"], capture_output=True).returncode != 0:
            self.skipTest("git-filter-repo is not installed")
        """tools/publish-update-json.sh with the server (ssh, scp), GitLab (git push, curl) and the
        signature tool stubbed; GitHub is the fake one."""
        shim = os.path.join(self.tmp, "bin")
        real_git, real_curl = shutil.which("git"), shutil.which("curl")
        self.write_exe(os.path.join(shim, "ssh"), '#!/usr/bin/env bash\necho "ssh $*" >> "$FAKE_DIR/calls"\n')
        self.write_exe(os.path.join(shim, "scp"), '#!/usr/bin/env bash\necho "scp $*" >> "$FAKE_DIR/calls"\n')
        self.write_exe(os.path.join(shim, "git"), f'#!/usr/bin/env bash\nfor a in "$@"; do [[ $a == push ]] && '
                       f'{{ echo "git push" >> "$FAKE_DIR/calls"; exit 0; }}; done\nexec {real_git} "$@"\n')
        # The server and GitLab copies read back as what was published; anything else (the fake
        # GitHub) through the real curl.
        self.write_exe(os.path.join(shim, "curl"), f'#!/usr/bin/env bash\nfor a in "$@"; do case $a in\n'
                       f'  https://*/update.json|https://gitlab.com/*/update.json) cat "$FAKE_DIR/pub/update.json"; exit ;;\n'
                       f'  https://*/v1/update.json|https://gitlab.com/*/update-v2.json) cat "$FAKE_DIR/pub/update-v2.json"; exit ;;\n'
                       f'esac; done\nexec {real_curl} "$@"\n')
        sign = os.path.join(self.tmp, "sign.py")
        with open(sign, "w") as f:
            f.write("import sys\nsys.exit(0)\n")
        site = os.path.join(self.tmp, "site")
        if not os.path.isdir(site):
            subprocess.run(["git", "init", "-q", "-b", "main", site], check=True)
            subprocess.run(["git", "-C", site, "-c", "user.name=t", "-c", "user.email=t@example.invalid", "commit",
                            "-q", "--allow-empty", "-m", "start"], check=True)
        pub = os.path.join(self.tmp, "pub")
        os.makedirs(pub, exist_ok=True)
        v1 = self.envelope(5)
        shutil.copy(v1, os.path.join(pub, "update.json"))
        shutil.copy(v1, os.path.join(pub, "update-v2.json"))
        token = os.path.join(self.tmp, "gitlab-token")
        with open(token, "w") as f:
            f.write("glpat-fake")
        e = dict(self.env, UPDATE_PUBLISH_CONF=os.path.join(self.tmp, "none.env"), UPDATE_SSH_HOST="server.invalid",
                 UPDATE_URL="https://server.invalid/update.json", UPDATE_URL_V2="https://server.invalid/v1/update.json",
                 UPDATE_SITE=site, UPDATE_KEYRING=self.ring, UPDATE_SIGN_TOOL=sign, GITLAB_TOKEN_FILE=token,
                 GITHUB_UPDATE_URL=f"{self.gh.base}/web/{REPO_NAME}/releases/latest/download/update-v2.json",
                 GITHUB_MIRROR_SITE="0", GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@example.invalid", GIT_COMMITTER_NAME="t",
                 GIT_COMMITTER_EMAIL="t@example.invalid", **env)
        p = subprocess.run(["bash", os.path.join(REPO, "tools/publish-update-json.sh"), v1, v1], capture_output=True,
                           text=True, timeout=120, env=e)
        out = p.stdout + p.stderr
        self.assertNotIn(TOKEN, out)
        with open(os.path.join(self.tmp, "calls")) as f:
            return p.returncode, out, f.read()

    def test_publish_update_json_github_only_when_on_and_never_a_gate(self):
        latest = self.gh.add_release("v26.10.25")
        rc, out, calls = self.publish_update_json()
        self.assertEqual(rc, 0, out)
        self.assertIn("git push", calls)
        self.assertIn("scp", calls)
        self.assertEqual(self.gh.log, [])  # off by default: GitHub is not touched
        self.assertNotIn("releases/latest/download", out)
        rc, out, _ = self.publish_update_json(GITHUB_UPDATE_JSON="1")
        self.assertEqual(rc, 0, out)
        self.assertEqual([a["name"] for a in latest["assets"]], ["update-v2.json"])
        self.assertIn(f"{self.gh.base}/web/{REPO_NAME}/releases/latest/download/update-v2.json: ok", out)
        # A GitHub failure is a warning; the server and GitLab copies are published all the same.
        os.remove(os.path.join(self.tmp, "calls"))
        rc, out, calls = self.publish_update_json(GITHUB_UPDATE_JSON="1", FAKE_GH_LOGIN="someone-else")
        self.assertEqual(rc, 0, out)
        self.assertIn("warning: update-v2.json not on the GitHub release", out)
        self.assertIn("scp", calls)
        self.assertIn("git push", calls)


if __name__ == "__main__":
    unittest.main()
