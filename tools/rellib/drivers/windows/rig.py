# SPDX-License-Identifier: Apache-2.0
"""The Windows rig from the build machine: SSH to the box as the rig user (one multiplexed connection), the agent
(agent.ps1) queued once per run as epicrig through the rig's queue, commands through rpc.ps1.

Everything on the box lives under C:\\EpicRig\\trust: bin\\ (agent.ps1, rpc.ps1) and runs\\<name>\\
(the agent's cmd/res folders, the app's USERPROFILE home\\ with its data folder and per-user install,
installers, logs)."""
import base64
import json
import os
import subprocess
import time

BASE = r"C:\EpicRig\trust"
QUEUE = r"C:\wintest-rig\scripts\queue-script.ps1"
HERE = os.path.dirname(os.path.abspath(__file__))


class RigError(Exception):
    pass


class Rig:
    def __init__(self, host, name, log, control_dir):
        self.host = host
        self.run = BASE + r"\runs" + "\\" + name
        self.log = log
        os.makedirs(control_dir, mode=0o700, exist_ok=True)
        self.ssh_opts = ["-o", "BatchMode=yes", "-o", "ControlMaster=auto", "-o", "ControlPersist=900",
                         "-o", "ControlPath=%s/cm-%%C" % control_dir, "-o", "ServerAliveInterval=30"]
        self.seq = 0

    # ---- plumbing

    def ssh(self, command, timeout=120, check=True):
        r = subprocess.run(["ssh", *self.ssh_opts, self.host, command], capture_output=True, text=True, errors="replace",
                           timeout=timeout)
        if check and r.returncode != 0:
            raise RigError("ssh %r: exit %d: %s" % (command[:80], r.returncode, (r.stderr or r.stdout)[-400:]))
        return r.stdout

    def pwsh(self, script, timeout=120, check=True):
        """A PowerShell snippet as BT (session 0 over SSH; never epicrig's windows)."""
        enc = base64.b64encode(script.encode("utf-16-le")).decode()
        return self.ssh("pwsh -NoProfile -NonInteractive -EncodedCommand %s" % enc, timeout=timeout, check=check)

    def put(self, local, remote, timeout=600):
        r = subprocess.run(["scp", "-q", *self.ssh_opts, local, "%s:%s" % (self.host, remote.replace("\\", "/"))],
                           capture_output=True, text=True, timeout=timeout)
        if r.returncode != 0:
            raise RigError("scp %s: %s" % (os.path.basename(local), r.stderr[-300:]))

    def get(self, remote, local, timeout=300):
        r = subprocess.run(["scp", "-q", *self.ssh_opts, "%s:%s" % (self.host, remote.replace("\\", "/")), local],
                           capture_output=True, text=True, timeout=timeout)
        return r.returncode == 0

    def close(self):
        subprocess.run(["ssh", *self.ssh_opts, "-O", "exit", self.host], capture_output=True, timeout=20)

    # ---- the agent

    def prepare(self):
        self.pwsh("New-Item -ItemType Directory -Force '%s\\bin','%s' | Out-Null" % (BASE, self.run))
        for f in ("agent.ps1", "rpc.ps1"):
            self.put(os.path.join(HERE, f), BASE + "\\bin\\" + f)

    def busy(self):
        """Jobs waiting in or running from the rig queue (an agent waits behind them). A running mark
        older than the task's 4 h limit is a leftover, not a job."""
        out = self.pwsh("(Get-ChildItem C:\\EpicRig\\queue -Filter *.json -File).Count; "
                        "(Get-ChildItem C:\\EpicRig\\queue\\done -Filter *.running.json -File | "
                        "Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }).Count")
        n = [int(x) for x in out.split()[:2]] if out.strip() else [0, 0]
        return n[0] + n[1]

    def start_agent(self, idle_min=45, wait_s=420):
        label = "trust-" + self.run.rsplit("\\", 1)[-1][-15:]
        self.pwsh("& '%s' '%s\\bin\\agent.ps1' -ScriptArgs @('%s','%d') -Label '%s'" % (QUEUE, BASE, self.run, idle_min, label))
        self.log("rig agent queued as epicrig (%s)" % label)
        r = self.call("ping", timeout=wait_s)
        if not r.get("ok"):
            raise RigError("rig agent did not start: %s" % r.get("error"))
        self.log("rig agent up: user %s, profile %s" % (r.get("user"), r.get("profile")))
        return r

    def call(self, op, timeout=120, **kw):
        self.seq += 1
        seq = "%s-%05d" % (time.strftime("%H%M%S"), self.seq)
        kw["op"] = op
        b64 = base64.b64encode(json.dumps(kw).encode()).decode()
        out = self.ssh("pwsh -NoProfile -NonInteractive -File %s\\bin\\rpc.ps1 %s %s %s %d" % (BASE, self.run, seq, b64, timeout),
                       timeout=timeout + 60, check=False)
        out = out.strip().lstrip("\ufeff")
        try:
            return json.loads(out) if out else {"ok": False, "error": "no answer"}
        except ValueError:
            return {"ok": False, "error": "bad answer: %s" % out[-300:]}

    # ---- reading the app's files: by the agent, as epicrig. From 26.10.25 the app keeps its data
    # folder to its own user and SYSTEM (WAL-12), so BT is refused there; before the agent is up
    # (or after it quit) the read falls back to BT over SSH, which an older release still allows.

    def as_owner(self, script, timeout=120):
        """A PowerShell snippet run by the agent (epicrig); its output, or None when no agent answers."""
        r = self.call("ps", timeout=timeout, code=script)
        return (r.get("out") or "") if r.get("ok") else None

    def text(self, path):
        """A text file's content, None when it does not exist."""
        out = self.as_owner("$p = '%s'; if (Test-Path -LiteralPath $p) { 'OK'; $t = Get-Content -Raw -Encoding utf8 "
                            "-LiteralPath $p; if ($null -eq $t) { $t = '' }; "
                            "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($t)) -split '(.{1,200})' | "
                            "Where-Object { $_ } } else { 'NONE' }" % path)
        if out is not None:
            lines = [x.strip() for x in out.replace("\r", "").split("\n") if x.strip()]
            if lines and lines[0] == "OK":
                return base64.b64decode("".join(lines[1:])).decode("utf-8", "replace")
            if lines and lines[0] == "NONE":
                return None
        out = self.pwsh("$p = '%s'; if (Test-Path -LiteralPath $p) { 'OK'; Get-Content -Raw -Encoding utf8 -LiteralPath $p } "
                        "else { 'NONE' }" % path, check=False)
        out = out.lstrip("\ufeff")
        return out[2:].lstrip("\r\n") if out.startswith("OK") else None

    def files(self, root, skip=("logs", "tor", "cache")):
        """Files under [root], relative, without the given top folders, lock and log files."""
        script = ("$r = '%s'; if (Test-Path -LiteralPath $r) { Get-ChildItem -LiteralPath $r -Recurse -File -Force | "
                  "ForEach-Object { $_.FullName.Substring($r.Length + 1) } }" % root)
        out = self.as_owner(script)
        if out is None:
            out = self.pwsh(script, check=False)
        keep = []
        for f in out.replace("\r", "").splitlines():
            f = f.strip()
            if not f or f.split("\\")[0] in skip or f.endswith((".lock", ".log")) or f.startswith("LOCK"):
                continue
            keep.append(f.replace("\\", "/"))
        return sorted(keep)

    def fetch_db(self, db, local_dir, tag):
        """Copies the wallet's SQLite files (with -wal and -shm) on the box, then here; the local path. The
        copies land under the run folder, which BT can read."""
        snap = self.run + "\\snap\\" + tag
        script = ("New-Item -ItemType Directory -Force '%s' | Out-Null; foreach ($x in '', '-wal', '-shm') { "
                  "if (Test-Path -LiteralPath ('%s' + $x)) { Copy-Item -LiteralPath ('%s' + $x) -Destination '%s' -Force } }"
                  % (snap, db, db, snap))
        if self.as_owner(script) is None:
            self.pwsh(script)
        local = os.path.join(local_dir, tag)
        os.makedirs(local, exist_ok=True)
        name = db.rsplit("\\", 1)[-1]
        for x in ("", "-wal", "-shm"):
            self.get(snap + "\\" + name + x, os.path.join(local, name + x))
        return os.path.join(local, name)

    def put_secret(self, local, name):
        """A secret file into <run>\\secret (readable by BT and epicrig only); its path on the box."""
        d = self.run + "\\secret"
        self.pwsh("New-Item -ItemType Directory -Force '%s' | Out-Null; icacls '%s' /inheritance:r /grant:r "
                  "\"${env:USERNAME}:(OI)(CI)F\" \"epicrig:(OI)(CI)F\" | Out-Null" % (d, d))
        self.put(local, d + "\\" + name)
        return d + "\\" + name

    def quit_agent(self):
        try:
            self.call("quit", timeout=60)
        except Exception:  # noqa: BLE001
            pass
