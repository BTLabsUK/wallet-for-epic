#!/usr/bin/env python3
"""P, the funded CLI wallet the release checks pay from and back to, driven through p.py.

Every use of P holds the shared lock (REL_P_LOCK, default /opt/epic/qa-funder/.rel-lock) for the
whole exchange: the send and the P listener that finalizes it (a send to P is answered by that
listener too). Two P listeners at once would fight over one Epicbox address, so other drivers
take the same lock.

    with PSession(log_path) as p:     # lock, then P's Epicbox listener in the background
        p.send(addr, "0.02")          # P pays addr (capped)
        ...                           # the phone answers; the listener finalizes and posts
    # listener stopped (locally and P's session-0 process on its host), lock released

Settings (env):
  REL_P_PY         p.py (default /tmp/epic-build/interop/epicpay/p.py; it knows P's host and folder)
  REL_P_PASS_FILE  file holding P's password (default ~/.config/btlabs/p-pass when not empty,
                   else line 1 of ~/.config/btlabs/p-pass-candidates); never printed or logged
  REL_P_ADDRESS    P's Epicbox address (default: asked from P with `address`)
  REL_P_MAX_SEND   cap per send, EPIC (default and ceiling 0.05)
  REL_P_MAX_TOTAL  cap on what P pays out in one run (default and ceiling 0.2)
"""
import fcntl, os, re, signal, subprocess, sys, time

HOME = os.path.expanduser("~")
P_PY = os.environ.get("REL_P_PY", f"{HOME}/epic-build/interop/epicpay/p.py")
LOCK = os.environ.get("REL_P_LOCK", f"{HOME}/epic/qa-funder/.rel-lock")
MAX_SEND = min(float(os.environ.get("REL_P_MAX_SEND", "0.05")), 0.05)
MAX_TOTAL = min(float(os.environ.get("REL_P_MAX_TOTAL", "0.2")), 0.2)
ADDR_RE = re.compile(r"\b([1-9A-HJ-NP-Za-km-z]{40,64}@[a-z0-9.-]+\.[a-z]{2,}(?::\d+)?)")


def _password():
    path = os.environ.get("REL_P_PASS_FILE")
    if path:
        return open(path).read().splitlines()[0].strip()
    main = f"{HOME}/.config/btlabs/p-pass"
    if os.path.exists(main) and os.path.getsize(main) > 0:
        return open(main).read().splitlines()[0].strip()
    return open(f"{HOME}/.config/btlabs/p-pass-candidates").read().splitlines()[0].strip()


def _p_host():
    """P's ssh target, read from p.py so it is written down in one place."""
    if os.environ.get("P_HOST"):
        return os.environ["P_HOST"]
    m = re.search(r'P_HOST",\s*"([^"]+)"', open(P_PY).read())
    return m.group(1) if m else None


class PSession:
    def __init__(self, log_path):
        self.log_path = log_path
        self.paid = 0.0
        self.listener = None
        self.lock = None
        self.pw = _password()
        self.env = dict(os.environ, EPIC_P_PASS=self.pw)

    def _log(self, *a):
        with open(self.log_path, "a") as f:
            f.write(time.strftime("%H:%M:%S ") + " ".join(map(str, a)) + "\n")

    def _clean(self, text):
        return text.replace(self.pw, "***") if self.pw else text

    def run(self, *args, timeout=180):
        r = subprocess.run([sys.executable, "-I", P_PY, *args], env=self.env, capture_output=True,
                           text=True, timeout=timeout, errors="replace")
        out = self._clean((r.stdout or "") + (r.stderr or "")).replace("\r", "")
        self._log(f"p.py {' '.join(args)} rc={r.returncode}\n" + out[-3000:])
        return r.returncode, out

    def __enter__(self):
        self.lock = open(LOCK, "a")
        self._log("waiting for", LOCK)
        fcntl.flock(self.lock, fcntl.LOCK_EX)
        self._log("lock held")
        self._kill_remote_listener()  # a listener left by an earlier, killed run
        self._address = self.address()  # before the listener: one P wallet process at a time
        self.start_listener()
        return self

    def start_listener(self, tries=6):
        """Start P's listener and wait for its "Starting epicbox listener" line. The CLI quits
        when its node says it is syncing (it does for a moment now and then): try again."""
        lp = self.log_path + ".listener"
        for attempt in range(tries):
            start = os.path.getsize(lp) if os.path.exists(lp) else 0
            self.listener = subprocess.Popen(
                [sys.executable, "-I", P_PY, "listen", "-m", "epicbox"], env=self.env,
                stdin=subprocess.DEVNULL, stdout=open(lp, "a"),
                stderr=subprocess.STDOUT, start_new_session=True)
            end = time.time() + 60
            while time.time() < end:
                with open(lp, errors="replace") as f:
                    f.seek(start)
                    new = f.read()
                if "Starting epicbox listener" in new:
                    time.sleep(3)
                    self._log("P listener started")
                    return True
                if self.listener.poll() is not None or re.search(r"ERROR|Connection to .* closed", new):
                    break
                time.sleep(2)
            self._log(f"P listener did not start (try {attempt + 1}):",
                      " ".join(re.findall(r"ERROR[^\n]*", new))[:200])
            self.stop_listener()
            time.sleep(20)
        raise RuntimeError("P's Epicbox listener did not start")

    def stop_listener(self):
        if self.listener and self.listener.poll() is None:
            os.killpg(self.listener.pid, signal.SIGTERM)
            try:
                self.listener.wait(10)
            except subprocess.TimeoutExpired:
                os.killpg(self.listener.pid, signal.SIGKILL)
        self._kill_remote_listener()
        self.listener = None

    def __exit__(self, *exc):
        try:
            self.stop_listener()
            # The listener log holds no password (p.py types it into the pty; it is not echoed),
            # but scrub it anyway.
            lp = self.log_path + ".listener"
            if os.path.exists(lp):
                t = open(lp, errors="replace").read()
                open(lp, "w").write(self._clean(t))
        finally:
            fcntl.flock(self.lock, fcntl.LOCK_UN)
            self.lock.close()
            self._log("lock released")
        return False

    def _kill_remote_listener(self):
        """Stop only P's SSH-started listener (session 0, P's own exe, `listen`), by PID."""
        host = _p_host()
        if not host:
            return
        ps = ("Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'epic-wallet.exe' -and "
              "$_.CommandLine -like '*epic-gui-wallet-610*listen*' -and $_.SessionId -eq 0 } | "
              "ForEach-Object { $_.ProcessId }")
        try:
            r = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", host,
                                "powershell -NoProfile -Command -"], input=ps, capture_output=True,
                               text=True, timeout=60)
            for pid in re.findall(r"^\s*(\d+)\s*$", r.stdout, re.M):
                subprocess.run(["ssh", "-o", "BatchMode=yes", host, f"taskkill /PID {pid} /F"],
                               capture_output=True, timeout=60)
                self._log("stopped P listener pid", pid)
        except Exception as e:  # noqa: BLE001 - best effort; reported in the log
            self._log("remote listener check failed:", e)

    def address(self):
        a = os.environ.get("REL_P_ADDRESS") or getattr(self, "_address", None)
        if a:
            return a
        _, out = self.run("address")
        m = ADDR_RE.search(out)
        return m.group(1) if m else None

    def send(self, addr, amount):
        amt = float(amount)
        if not (0 < amt <= MAX_SEND) or self.paid + amt > MAX_TOTAL + 1e-9:
            raise ValueError(f"P send of {amount} refused (cap {MAX_SEND}/send, {MAX_TOTAL}/run)")
        if not ADDR_RE.fullmatch(addr):
            raise ValueError("not an Epicbox address")
        rc, out = self.run("send", "-m", "epicbox", "-d", addr, f"{amt:.8f}".rstrip("0"))
        ok = rc == 0 and "ERROR" not in out and re.search(r"Tx created|completed successfully", out)
        if ok:
            self.paid += amt
        return bool(ok), out

    def listener_mark(self):
        lp = self.log_path + ".listener"
        return os.path.getsize(lp) if os.path.exists(lp) else 0

    def finalized_since(self, mark):
        """True when P's listener logged a finalize after `mark` (a listener_mark())."""
        lp = self.log_path + ".listener"
        if not os.path.exists(lp):
            return False
        with open(lp, errors="replace") as f:
            f.seek(mark)
            return "Finalize transaction" in f.read()

    def repost_to(self, addr):
        """P's listener finalizes a payment and at times never posts it (the tx stays
        "Sent (Created)" with its finalized copy saved): post P's unconfirmed sends to `addr`
        again from that copy. The listener is stopped meanwhile (one wallet process at a time)."""
        k = addr.split("@")[0]
        self.stop_listener()
        _, out = self.run("txs", timeout=240)
        ids = []
        for m in re.finditer(r"^\s*(\d+)\s+Sent[^\n]*?" + re.escape(k) + r"[^\n]*\n([^\n]*)", out, re.M):
            nxt = m.group(2)
            if re.search(r"\bfalse\b", nxt) and "Cancelled" not in m.group(0):
                ids.append(m.group(1))
        for i in ids:
            rc, o = self.run("repost", "-i", i)
            self._log(f"repost {i}: rc={rc} {'ok' if 'Reposted' in o else 'not reposted'}")
        self.start_listener()
        return ids

    def info(self):
        _, out = self.run("info")
        m = re.search(r"Currently Spendable\s*\|\s*([0-9.]+)", out)
        return m.group(1) if m else None


if __name__ == "__main__":
    # pfund.py info | address   (one-shot, under the lock, no listener)
    cmd = sys.argv[1] if len(sys.argv) > 1 else "info"
    log = os.environ.get("REL_P_LOG", os.path.join(os.environ.get("TMPDIR", "/tmp"), "pfund.log"))
    s = PSession.__new__(PSession)
    s.log_path, s.pw = log, _password()
    s.env = dict(os.environ, EPIC_P_PASS=s.pw)
    with open(LOCK, "a") as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        print(s.info() if cmd == "info" else s.address())
