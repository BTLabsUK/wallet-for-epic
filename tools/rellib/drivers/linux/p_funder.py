# SPDX-License-Identifier: Apache-2.0
"""P, the funded CLI wallet the release checks pay from and back to, driven by its p.py (outside
this repository: it runs P's CLI over SSH in a session of its own on the PC that holds P).

Every use holds an exclusive flock on the shared lock file for the whole exchange (sends and the
listener that finalizes or answers), so two drivers never run two P listeners on one address.
P's password comes from a file (line N); it goes only into p.py's environment, never a log.
"""
import contextlib
import fcntl
import os
import re
import signal
import subprocess
import time


class P:
    def __init__(self, tool, pass_file, pass_line, lock_file, log_dir, log):
        self.tool = tool
        self.pass_file = pass_file
        self.pass_line = pass_line
        self.lock_file = lock_file
        self.log_dir = log_dir
        self.log = log
        self.listener = None
        self._lock = None
        src = open(tool).read() if os.path.exists(tool) else ""
        m = re.search(r'HOST\s*=\s*os\.environ\.get\("P_HOST",\s*"([^"]+)"\)', src)
        self.host = os.environ.get("P_HOST") or (m.group(1) if m else None)

    def ready(self):
        """None when P can be used, else why not."""
        if not os.path.exists(self.tool):
            return "no P tool at %s" % self.tool
        if not self._password():
            return "no P password at line %d of %s" % (self.pass_line, self.pass_file)
        if not self.host:
            return "no P host (P_HOST or p.py's default)"
        return None

    def _password(self):
        try:
            lines = open(self.pass_file).read().splitlines()
            return lines[self.pass_line - 1].strip() if len(lines) >= self.pass_line else ""
        except OSError:
            return ""

    def _env(self):
        env = dict(os.environ)
        env["EPIC_P_PASS"] = self._password()
        return env

    @contextlib.contextmanager
    def exchange(self, what, wait_s=3600):
        """Hold the P lock for one exchange; the listener is stopped on the way out, whatever happened."""
        os.makedirs(os.path.dirname(self.lock_file), exist_ok=True)
        f = open(self.lock_file, "a")
        t0 = time.time()
        waited = False
        while True:
            try:
                fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if not waited:
                    self.log("waiting for the P lock (%s): another check is using P" % self.lock_file)
                    waited = True
                if time.time() - t0 > wait_s:
                    f.close()
                    raise TimeoutError("P lock busy for %d s" % wait_s)
                time.sleep(5)
        self.log("P lock held for %s (waited %d s)" % (what, time.time() - t0))
        try:
            yield self
        finally:
            try:
                self.stop_listener()
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)
                f.close()
                self.log("P lock released")

    def run(self, *args, timeout=240):
        """One P command; its output (P's CLI prints no secrets) goes to a log file and is returned."""
        r = subprocess.run(["python3", "-I", self.tool, *args], env=self._env(), capture_output=True, text=True,
                           timeout=timeout, cwd=os.path.dirname(self.tool))
        out = _clean(r.stdout + r.stderr)
        with open(os.path.join(self.log_dir, "p.log"), "a") as lf:
            lf.write("\n=== p.py %s (exit %d)\n%s\n" % (" ".join(args), r.returncode, out))
        return r.returncode, out

    def send(self, address, amount):
        rc, out = self.run("send", "-m", "epicbox", "-d", address, amount)
        ok = rc == 0 and "ERROR" not in out and re.search(r"Tx created|successfully|Command 'send' completed", out)
        return bool(ok), _last_lines(out)

    def info(self):
        rc, out = self.run("info", timeout=180)
        m = re.search(r"Currently Spendable\s*\|\s*([\d.]+)", out)
        return m.group(1) if m else None

    def start_listener(self):
        if self.listener and self.listener.poll() is None:
            return
        log = open(os.path.join(self.log_dir, "p-listener.log"), "a")
        self.listener = subprocess.Popen(["python3", "-I", self.tool, "listen", "-m", "epicbox"], env=self._env(),
                                         stdout=log, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                                         cwd=os.path.dirname(self.tool), start_new_session=True)
        self.log("P listener started (local pid %d)" % self.listener.pid)

    def _remote_listeners(self):
        q = ("Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'epic-wallet.exe' -and "
             "$_.CommandLine -like '*epic-gui-wallet-610*listen*' -and $_.SessionId -eq 0 } | "
             "ForEach-Object { $_.ProcessId }")
        r = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=20", self.host,
                            "powershell -NoProfile -Command -"], input=q, capture_output=True, text=True, timeout=90)
        return [p for p in r.stdout.replace("\r", "").split() if p.isdigit()]

    def stop_listener(self):
        """Stop the local p.py listen, then P's SSH-started listener on the remote side by PID (session 0
        only, never a wallet anyone runs by hand), then check that none is left."""
        if self.listener and self.listener.poll() is None:
            try:
                os.killpg(self.listener.pid, signal.SIGTERM)
            except OSError:
                pass
            try:
                self.listener.wait(15)
            except subprocess.TimeoutExpired:
                os.killpg(self.listener.pid, signal.SIGKILL)
        if self.listener is None:
            return True
        self.listener = None
        lp = os.path.join(self.log_dir, "p-listener.log")
        try:
            with open(lp) as f:
                text = _clean(f.read())
            with open(lp, "w") as f:
                f.write(text + "\n")
        except OSError:
            pass
        left = []
        for _ in range(3):
            try:
                pids = self._remote_listeners()
            except Exception as e:  # noqa: BLE001
                self.log("P listener check failed: %s" % e)
                return False
            for pid in pids:
                subprocess.run(["ssh", "-o", "BatchMode=yes", self.host, "taskkill /PID %s /F" % pid],
                               capture_output=True, text=True, timeout=60)
            time.sleep(2)
            left = self._remote_listeners()
            if not left:
                self.log("P listener stopped; none left on P's side")
                return True
        self.log("P listener still running on P's side: pids %s" % left)
        return False


def _clean(out):
    """P's CLI lines only: the remote shell's prompt, banner and the SSH close line name the PC."""
    keep = []
    for line in out.replace("\r", "").splitlines():
        line = re.sub(r"\S+@\S+ [A-Z]:\\\S*>.*$|[A-Z]:\\\S*>.*$", "", line)
        if re.search(r"Connection to \S+ closed|Microsoft Windows|Microsoft Corporation|^\s*$", line):
            continue
        keep.append(line.rstrip())
    return "\n".join(keep)


def _last_lines(out, n=4):
    lines = [re.sub(r"^\S+ \S+ (INFO|WARN|ERROR) ", r"\1 ", l.strip()) for l in out.splitlines()
             if l.strip() and "Password" not in l and re.search(r"INFO|WARN|ERROR", l)]
    return " / ".join(lines[-n:])
