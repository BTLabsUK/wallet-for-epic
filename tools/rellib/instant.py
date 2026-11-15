# SPDX-License-Identifier: Apache-2.0
"""`tools/rel rollback` and `tools/rel rollforward` (docs/RELEASING.md, "Rollback").

One command makes the website serve the previous (or, after a rollback, the newer) release:

  site      one ssh call: relsrv.py switch <v> flips `current` (downloads, page assets of the
            release), installs the release's page and its pre-signed manifest pair by atomic
            rename. No upload, no signing, no rebuild.
  readback  then, in parallel with the two parts below: the public page, update.json,
            update-v2.json and SHA256SUMS are read back and compared with what the server
            installed.
  github    release-files.py github-switch: the release's update-v2.json asset, the release made
            the latest, the newer one hidden as a draft, the latest-download links read back.
  mirrors   the Pages repository copy of both manifests (the apps' other sources) and its read-back.

Every part is timed and printed. The site is the only part that cannot be retried by itself;
`--parts github,mirrors,readback` repeats the others against the release that is live now."""
import concurrent.futures as cf
import os
import pathlib
import subprocess
import sys
import time

from .presign import neighbours
from .server import ServerError, sha

PARTS = ("site", "readback", "github", "mirrors")
BAR_TOTAL = 240  # seconds: the owner's bar for the whole rollback
BAR_SITE = 10


class FlipError(Exception):
    pass


class Flip:
    def __init__(self, repo, server, work, say=print, github_repo=None):
        self.repo, self.server, self.work, self.say = repo, server, work, say
        self.github_repo = github_repo
        os.makedirs(work, exist_ok=True)

    # ---- plan ----

    def target(self, state, direction, to):
        live = state.get("live")
        if not live:
            raise FlipError("the server has no versions/current yet: run tools/rel migrate-layout first")
        prev, nxt = neighbours(state)
        want = to or (prev if direction == "rollback" else nxt)
        if not want:
            if direction == "rollback":
                raise FlipError(f"{live} is the oldest release on the server: nothing to roll back to")
            raise FlipError(f"{live} is the newest release on the server: nothing to roll forward to")
        if want == live:
            raise FlipError(f"{want} is live already")
        if want not in state["versions"]:
            raise FlipError(f"{want} is not on the server (kept: {', '.join(state['versions'])})")
        return live, want

    # ---- the parts ----

    def run(self, direction, to=None, dry=False, parts=PARTS):
        t_all = time.monotonic()
        st = self.server.state()
        live, want = self.target(st, direction, to)
        floor = max(s for s in st["live_serial"].values() if s is not None)
        self.say(f"{direction}: {live} -> {want} (live serial {floor})" + ("  [dry run: nothing changes]" if dry else ""))
        if dry:
            return self.dry(live, want, st)
        res = {"live": live, "target": want, "parts": {}, "ok": True}
        if "site" in parts:
            t0 = time.monotonic()
            try:
                out = self.server.relsrv("switch", want)
            except ServerError as e:
                raise FlipError(f"the website is unchanged: {e}")
            res["parts"]["site"] = time.monotonic() - t0
            self.say(f"site     {res['parts']['site']:6.1f} s  " + " | ".join(l for l in out.splitlines() if l.startswith(("switched", "serial"))))
            shas = {l.split()[1]: l.split()[2] for l in out.splitlines() if l.startswith("sha256 ")}
        else:
            now = self.server.state()
            if now["live"] != want:
                raise FlipError(f"--parts without site needs {want} to be live; live is {now['live']}")
            shas = None
        fns = {"readback": lambda: self.readback(want, shas),
               "github": lambda: self.github(live, want, floor),
               "mirrors": lambda: self.mirrors()}
        todo = [p for p in ("readback", "github", "mirrors") if p in parts]
        with cf.ThreadPoolExecutor(max_workers=3) as ex:
            futs = {p: (time.monotonic(), ex.submit(self.timed, fns[p])) for p in todo}
            for p, (_, fut) in futs.items():
                ok, secs, lines = fut.result()
                res["parts"][p] = secs
                self.say(f"{p:<8} {secs:6.1f} s  {'ok' if ok else 'FAILED'}")
                for l in lines:
                    self.say("           " + l)
                if not ok:
                    res["ok"] = False if p != "mirrors" else res["ok"]
                    res.setdefault("failed", []).append(p)
        res["total"] = time.monotonic() - t_all
        site = res["parts"].get("site")
        self.say(f"total    {res['total']:6.1f} s  (bar {BAR_TOTAL} s)" +
                 (f"; site switched in {site:.1f} s (bar {BAR_SITE} s)" if site is not None else ""))
        return res

    @staticmethod
    def timed(fn):
        t0 = time.monotonic()
        try:
            ok, lines = fn()
        except Exception as e:  # a part's failure is reported, the others still finish
            ok, lines = False, [f"{type(e).__name__}: {e}"]
        return ok, time.monotonic() - t0, lines

    def dry(self, live, want, st):
        """Everything read-only: the switch checks itself (--dry), GitHub's plan (--dry-run)."""
        out = self.server.relsrv("switch", want, "--dry")
        for l in out.splitlines():
            self.say("site     " + l)
        gh = self.run_gh(["github-switch", f"v{want}", "--draft", f"v{live}", "--dry-run"])
        for l in gh[1]:
            self.say("github   " + l)
        self.say("mirrors  would commit both manifests to the Pages repository and read the copies back")
        return {"live": live, "target": want, "dry": True, "ok": gh[0], "parts": {}}

    def readback(self, want, shas):
        s = self.server
        lines, ok = [], True
        got = {"index.html": sha(s.fetch("page")), "update.json": sha(s.fetch("update.json")),
               "update-v2.json": sha(s.fetch("update-v2.json"))}
        for n, h in got.items():
            if shas is None:
                lines.append(f"{n} {h[:12]} (served)")
                continue
            good = shas.get(n) == h
            ok &= good
            lines.append(f"{n} {'matches' if good else 'DIFFERS from'} the installed copy ({h[:12]})")
        sums_pub = s.fetch("download", "SHA256SUMS")
        sums_own = s.read_remote(os.path.join(s.R, "versions", want, "downloads", "SHA256SUMS"))
        good = sums_pub == sums_own
        ok &= good
        lines.append(f"downloads/SHA256SUMS {'is' if good else 'is NOT'} {want}'s ({sha(sums_pub)[:12]})")
        return ok, lines

    def run_gh(self, args):
        cmd = [sys.executable, os.path.join(self.repo, "tools/release-files.py")] + args
        if self.github_repo:
            cmd += ["--github-repo", self.github_repo]
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        lines = [l for l in (p.stdout + p.stderr).splitlines() if l.strip()]
        return p.returncode == 0, lines

    def github(self, live, want, floor):
        v2 = os.path.join(self.work, "installed-update-v2.json")
        pathlib.Path(v2).write_bytes(self.server.read_remote(self.server.API))
        return self.run_gh(["github-switch", f"v{want}", "--draft", f"v{live}", "--asset", v2, "--floor", str(floor)])

    def mirrors(self):
        files = {}
        for n, path in (("update.json", os.path.join(self.server.R, "update.json")), ("update-v2.json", self.server.API)):
            files[n] = os.path.join(self.work, "installed-" + n)
            pathlib.Path(files[n]).write_bytes(self.server.read_remote(path))
        env = dict(os.environ, UPDATE_SKIP_SERVER="1", GITHUB_UPDATE_JSON="0")
        if self.server.test:
            env.setdefault("UPDATE_SSH_HOST", "none")
        p = subprocess.run([os.path.join(self.repo, "tools/publish-update-json.sh"), files["update.json"], files["update-v2.json"]],
                           capture_output=True, text=True, timeout=900, env=env)
        lines = [l.strip() for l in (p.stdout + p.stderr).splitlines() if l.strip()]
        return p.returncode == 0, lines
