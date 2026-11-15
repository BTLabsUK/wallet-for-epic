# SPDX-License-Identifier: Apache-2.0
"""The download server as tools/rel's rollback, presign and publish-one see it: the version
folders (tools/rellib/steps/relsrv.py runs on the server over ssh) and the public addresses the
apps and visitors use. One class, two targets:

  live    ssh <host.web.ssh> sudo python3 - ...; reads back over HTTPS
  test    REL_SERVER_ROOT=<dir>: a folder (site/, api/update.json) on this machine; relsrv.py runs
          locally without ssh/sudo and the read-back reads the same folder through its symlinks,
          the way nginx would serve it. For proofs; nothing leaves this machine.

Settings of the live target come from release-hosts.toml ([host.web] ssh, downloads_dir) and
~/.config/btlabs/update-publish.env (UPDATE_DEST_V2); the addresses from the app's config."""
import base64
import hashlib
import json
import os
import pathlib
import shlex
import subprocess
import tomllib
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
RELSRV = HERE / "steps" / "relsrv.py"
DEFAULT_API = "/srv/epiccash-api/v1/update.json"
SLOTS = ("update.json", "update-v2.json")


class ServerError(Exception):
    pass


def sha(b):
    return hashlib.sha256(b).hexdigest()


class Server:
    def __init__(self, repo, hosts=None, root=None, say=print):
        self.repo, self.say = repo, say
        root = root or os.environ.get("REL_SERVER_ROOT")
        old = tomllib.loads((pathlib.Path(repo) / "app/tool/config/old-update.toml").read_text(encoding="utf-8"))["old_update"]
        cfg = tomllib.loads((pathlib.Path(repo) / "app/assets/config/app-config.toml").read_text(encoding="utf-8"))["updates"]
        self.test = bool(root)
        if self.test:
            self.root = os.path.abspath(root)
            self.R = os.path.join(self.root, "site")
            self.API = os.path.join(self.root, "api", "update.json")
            self.ssh = None
        else:
            web = hosts["host"]["web"]
            self.ssh = web["ssh"]
            self.R = os.path.dirname(web["downloads_dir"].rstrip("/"))
            self.API = os.environ.get("UPDATE_DEST_V2") or self._env_file("UPDATE_DEST_V2") or DEFAULT_API
        self.urls = {"update.json": old["manifest"], "update-v2.json": cfg["manifests"][0]}
        self.page_url = os.environ.get("REL_PAGE_URL", "https://examples.btlabs.uk/epic-cash-wallets/")
        self.download_bases = [old["downloads"].rstrip("/"), cfg["downloads"].rstrip("/")]

    @staticmethod
    def _env_file(key):
        p = pathlib.Path(os.environ.get("UPDATE_PUBLISH_CONF", os.path.expanduser("~/.config/btlabs/update-publish.env")))
        if p.is_file():
            for line in p.read_text(encoding="utf-8").splitlines():
                if line.startswith(key + "="):
                    return line.split("=", 1)[1].strip().strip("'\"")
        return None

    # ---- the server tool ----

    def relsrv(self, *args, timeout=300):
        """Output of `relsrv.py <args>` on the server (a refusal: ServerError with its message)."""
        script = RELSRV.read_bytes()
        env = {"R": self.R, "API": self.API}
        if self.test:
            cmd = ["env"] + [f"{k}={v}" for k, v in env.items()] + ["python3", "-", *args]
        else:
            remote = "sudo -n env " + " ".join(f"{k}={shlex.quote(v)}" for k, v in env.items()) + \
                     " python3 - " + " ".join(shlex.quote(a) for a in args)
            cmd = ["ssh", "-o", "BatchMode=yes", self.ssh, remote]
        p = subprocess.run(cmd, input=script, capture_output=True, timeout=timeout)
        if p.returncode != 0:
            raise ServerError((p.stderr or p.stdout).decode(errors="replace").strip()[-600:] or f"exit {p.returncode}")
        return p.stdout.decode()

    def state(self):
        return json.loads(self.relsrv("state"))

    def put(self, local, name):
        """A file into the ssh user's home (live) or the test root, for a relsrv command."""
        if self.test:
            dst = os.path.join(self.root, "stage")
            os.makedirs(dst, exist_ok=True)
            out = os.path.join(dst, name)
            with open(local, "rb") as s, open(out, "wb") as d:
                d.write(s.read())
            return out
        p = subprocess.run(["scp", "-q", "-o", "BatchMode=yes", local, f"{self.ssh}:{name}"], capture_output=True, text=True, timeout=300)
        if p.returncode != 0:
            raise ServerError(f"scp {name}: {p.stderr.strip()}")
        return f"/home/{self.remote_user()}/{name}"

    def remote_user(self):
        p = subprocess.run(["ssh", "-o", "BatchMode=yes", self.ssh, "echo $HOME"], capture_output=True, text=True, timeout=60)
        return p.stdout.strip().rsplit("/", 1)[-1]

    def read_remote(self, path):
        """Bytes of a file on the server (as root: private spare folders too)."""
        if self.test:
            return pathlib.Path(path).read_bytes()
        p = subprocess.run(["ssh", "-o", "BatchMode=yes", self.ssh, f"sudo -n cat {shlex.quote(path)}"], capture_output=True, timeout=120)
        if p.returncode != 0:
            raise ServerError(f"cannot read {path}: {p.stderr.decode(errors='replace').strip()}")
        return p.stdout

    def install_manifests(self, files):
        """Test target only: both manifests live (atomic renames) and kept in the live version's folder."""
        assert self.test
        live = self.state()["live"]
        for name, dst in (("update.json", os.path.join(self.R, "update.json")), ("update-v2.json", self.API)):
            for d in (dst, os.path.join(self.R, "versions", live, name)):
                tmp = d + ".new"
                pathlib.Path(tmp).write_bytes(pathlib.Path(files[name]).read_bytes())
                os.replace(tmp, d)

    # ---- what the public sees ----

    def fetch(self, what, name=None, method="GET"):
        """Bytes of a public address: what = page | update.json | update-v2.json | download."""
        if self.test:
            rel = {"page": "index.html", "update.json": "update.json", "update-v2.json": None, "download": f"downloads/{name}"}[what]
            path = self.API if what == "update-v2.json" else os.path.join(self.R, rel)
            return pathlib.Path(path).read_bytes() if method == "GET" else b""
        url = {"page": self.page_url, "download": f"{self.download_bases[1]}/{name}"}.get(what) or self.urls[what]
        req = urllib.request.Request(url, method=method, headers={"Cache-Control": "no-cache"})
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.read() if method == "GET" else str(r.headers.get("Content-Length", "")).encode()


def payload(env_bytes):
    return json.loads(base64.b64decode(json.loads(env_bytes)["payload"]))
