# SPDX-License-Identifier: Apache-2.0
"""P as one shared service: every G4 check pays from and back to P at the same time.

P is the funded epic-wallet 4.1.0 CLI wallet on the PC that holds it, driven through p.py (outside
this repository: it opens a cmd.exe over SSH in P's folder and types P's password into the CLI's
prompt). Before, every check ran its own P listener under one flock for its whole exchange, and the
4.1.0 listener posts each payment it finalizes by Dandelion and then polls the node's mempool for up
to 240 s before it reads the next slate: six checks paid 37-200 s each, one after another, plus a
listener start and stop each (82 min of lock waits on 2026-10-31).

This service runs, for as long as checks use it:
  - ONE `owner_api` process of P (its Owner API v2 on P's PC, reached through an SSH forward), which
    every send goes through: init_send_tx with Epicbox send_args selects, sends and locks in one call,
    so two sends never pick the same output (the calls are made one at a time; each takes seconds);
  - ONE `listen -m epicbox` process of P, which answers payments to P and finalizes P's payments;
  - a poster: as soon as the listener has finalized one of the service's sends (P's saved copy of the
    tx is signed), it posts that copy once with fluff: no Dandelion stem, so no embargo, and the node
    takes it into its txpool and broadcasts it at once (a fluff post goes to the txpool even when the
    listener's stem post put the tx in the stempool), and the listener's mempool wait ends within a
    second or two. This is P's one fluff post: epic-wallet 4.1.0 has no way to make P post with fluff
    by itself. Its Epicbox listener finalizes and posts with fluff=false hard-coded (no config key, no
    flag) and then polls the mempool for up to 240 s; init_send_tx with Epicbox send_args returns
    right after publishing the slate, so its finalize/post_tx/fluff fields are never used. The
    node's own Dandelion settings are not touched; a fluff post is the sender's choice per tx.
Nothing waits on the mempool or a confirmation under any lock. The old flock (REL_P_LOCK) is held by
the service for its whole life, only so a driver of an older release checkout (its own P listener on
the same Epicbox address) waits until the service has stopped, never runs beside it.

Two processes of one wallet at once is how the Epic GUI wallet runs this same binary (owner_api and
listen side by side). P's password never leaves p.py's environment; the Owner API secret is read from
P's folder into memory only.

The service starts on the first client that needs it (Client.ensure) and stops after REL_P_IDLE_MIN
(default 40) minutes without a request and without a send of its own still unconfirmed.

    python3 -I p_service.py serve | status | stop | info | cancel <slate> [why]

Env: REL_P_TOOL (p.py), REL_P_PASS_FILE + REL_P_PASS_LINE (P's password), REL_P_LOCK (the old
flock), REL_P_SERVICE_DIR (socket, logs; default ~/.cache/rel-p-service), REL_P_OWNER_PORT (P's
owner_api_listen_port, default 23420), REL_P_IDLE_MIN, P_HOST (else p.py's default).
"""
import base64
import contextlib
import fcntl
import json
import os
import re
import signal
import socket
import socketserver
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "drivers"))
import facts  # noqa: E402
import nodehealth  # noqa: E402

HOME = os.path.expanduser("~")
# P's 4.1.0 listener polls its node's sync state every 10 s and stops reading Epicbox while the node says
# it is not synced: P then finalizes nothing. A pause this long moves P to the next synced node.
PAUSED = "Node not synced, pausing Epicbox message processing"
PAUSE_S = 60
MOVE_EVERY_S = 300  # one move or listener restart at most per this many seconds
# The listener can also lose its Epicbox subscription without a word ("WebSocket protocol error" in
# owner.log, then nothing): a send unanswered this long while the listener stayed silent restarts it,
# and Epicbox hands the waiting answers to the new subscription. At most STALL_TRIES per send.
STALL_S = 180
STALL_TRIES = 2
NODE_LINE = re.compile(r'(?m)^check_node_api_http_addr\s*=\s*"([^"]*)"')
NANO = 100_000_000  # atomic units per EPIC
MIN_CONF = 1  # P is a test wallet: one confirmation everywhere (the owner 2026-10-31)


def env_paths(env=os.environ):
    return {
        "tool": env.get("REL_P_TOOL") or env.get("REL_P_PY") or f"{HOME}/epic-build/interop/epicpay/p.py",
        "pass_file": env.get("REL_P_PASS_FILE") or f"{HOME}/.config/btlabs/p-pass-candidates",
        "pass_line": int(env.get("REL_P_PASS_LINE") or "1"),
        "lock": env.get("REL_P_LOCK") or f"{HOME}/epic/qa-funder/.rel-lock",
        "dir": env.get("REL_P_SERVICE_DIR") or f"{HOME}/.cache/rel-p-service",
        "owner_port": int(env.get("REL_P_OWNER_PORT") or "23420"),
        "idle_min": float(env.get("REL_P_IDLE_MIN") or "40"),
    }


def _tool_const(tool, name):
    """A constant of p.py (HOST, DIR), so P's host and folder are written down in one place."""
    try:
        src = open(tool).read()
    except OSError:
        return None
    if name == "HOST":
        m = re.search(r'HOST\s*=\s*os\.environ\.get\("P_HOST",\s*"([^"]+)"\)', src)
    else:
        m = re.search(r'^%s\s*=\s*r?"([^"]+)"' % name, src, re.M)
    return m.group(1) if m else None


def password(cfg):
    try:
        lines = open(cfg["pass_file"]).read().splitlines()
        return lines[cfg["pass_line"] - 1].strip() if len(lines) >= cfg["pass_line"] else ""
    except OSError:
        return ""


def clean(out):
    """P's CLI lines only: the remote shell's prompt, banner and the SSH close line name the PC."""
    keep = []
    for line in out.replace("\r", "").splitlines():
        line = re.sub(r"\S+@\S+ [A-Z]:\\\S*>.*$|[A-Z]:\\\S*>.*$", "", line)
        if re.search(r"Connection to \S+ closed|Microsoft Windows|Microsoft Corporation|^\s*$", line):
            continue
        keep.append(line.rstrip())
    return "\n".join(keep)


def epic_str(atomic):
    return ("%d.%08d" % divmod(int(atomic), NANO)).rstrip("0").rstrip(".")


def to_atomic(amount):
    whole, _, frac = str(amount).strip().partition(".")
    if not re.fullmatch(r"\d*", whole) or not re.fullmatch(r"\d{0,8}", frac) or not (whole or frac):
        raise ValueError("not an amount: %r" % amount)
    return int(whole or "0") * NANO + int((frac + "00000000")[:8])


# ---- the service ---------------------------------------------------------------------------------


class Service:
    def __init__(self, cfg):
        self.cfg = cfg
        self.tool = cfg["tool"]
        self.host = os.environ.get("P_HOST") or _tool_const(self.tool, "HOST")
        self.pdir = _tool_const(self.tool, "DIR")
        self.dir = cfg["dir"]
        os.makedirs(self.dir, mode=0o700, exist_ok=True)
        self.env = dict(os.environ, EPIC_P_PASS=password(cfg), P_TIMEOUT="1000000000")
        self.send_mu = threading.Lock()  # one init_send_tx at a time: output selection + lock, seconds
        self.state_mu = threading.Lock()
        self.sends = {}  # slate id -> {address, amount, tx_id, at, state, what}
        self.address = None
        self.secret = None
        self.port = None
        self.procs = {}
        self.last_request = time.time()
        self.stopping = threading.Event()
        self.rpc_id = 0
        self.paused_at = None
        self.moved_at = 0.0

    def log(self, msg):
        with open(os.path.join(self.dir, "service.log"), "a") as f:
            f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + msg + "\n")

    # -- P's two processes and the forward

    def _remote_pids(self, kinds=("listen", "owner_api")):
        """P's SSH-started epic-wallet processes (session 0, P's own exe): never a wallet anyone runs by hand."""
        like = " -or ".join("$_.CommandLine -like '*%s*'" % k for k in kinds)
        q = ("Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'epic-wallet.exe' -and "
             "$_.CommandLine -like '*epic-gui-wallet-610*' -and (%s) -and $_.SessionId -eq 0 } | "
             "ForEach-Object { $_.ProcessId }" % like)
        r = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=20", self.host,
                            "powershell -NoProfile -Command -"], input=q, capture_output=True, text=True, timeout=90)
        return [p for p in r.stdout.replace("\r", "").split() if p.isdigit()]

    def kill_remote(self, kinds=("listen", "owner_api")):
        for _ in range(3):
            try:
                pids = self._remote_pids(kinds)
            except Exception as e:  # noqa: BLE001
                self.log("P process check failed: %s" % e)
                return False
            if not pids:
                return True
            for pid in pids:
                subprocess.run(["ssh", "-o", "BatchMode=yes", self.host, "taskkill /PID %s /F" % pid],
                               capture_output=True, text=True, timeout=60)
            self.log("stopped P processes %s on P's side" % pids)
            time.sleep(2)
        return not self._remote_pids(kinds)

    def _start_p(self, name, args, ready, tries=4):
        """p.py <args> in the background, its output in <name>.log; True once `ready` shows. The CLI
        quits at once when the node says it is syncing (a short blip): then it is started again."""
        lp = os.path.join(self.dir, name + ".log")
        for attempt in range(tries):
            start = os.path.getsize(lp) if os.path.exists(lp) else 0
            proc = subprocess.Popen(["python3", "-I", self.tool, *args], env=self.env, stdout=open(lp, "a"),
                                    stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                                    cwd=os.path.dirname(self.tool), start_new_session=True)
            end = time.time() + 120
            new = ""
            while time.time() < end:
                with open(lp, errors="replace") as f:
                    f.seek(start)
                    new = f.read()
                m = re.search(ready, new)
                if m:
                    self.procs[name] = (proc, lp)
                    self.log("P %s up (local pid %d)" % (name, proc.pid))
                    return m
                if proc.poll() is not None:
                    break
                time.sleep(2)
            self._stop_local(proc)
            why = "node syncing" if "syncing" in new else "no ready line"
            self.log("P %s did not start (%s), try %d of %d" % (name, why, attempt + 1, tries))
            time.sleep(15)
        return None

    @staticmethod
    def _stop_local(proc):
        if proc and proc.poll() is None:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
                proc.wait(15)
            except (OSError, subprocess.TimeoutExpired):
                with contextlib.suppress(OSError):
                    os.killpg(proc.pid, signal.SIGKILL)

    def _forward(self):
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            self.port = s.getsockname()[1]
        proc = subprocess.Popen(["ssh", "-N", "-o", "BatchMode=yes", "-o", "ExitOnForwardFailure=yes",
                                 "-o", "ServerAliveInterval=30", "-L",
                                 "127.0.0.1:%d:127.0.0.1:%d" % (self.port, self.cfg["owner_port"]), self.host],
                                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                                start_new_session=True)
        self.procs["forward"] = (proc, None)

    def _read_secret(self):
        r = subprocess.run(["ssh", "-o", "BatchMode=yes", self.host, 'type "%s\\.owner_api_secret"' % self.pdir],
                           capture_output=True, text=True, timeout=60)
        s = r.stdout.strip()
        return s if r.returncode == 0 and re.fullmatch(r"[A-Za-z0-9]{8,64}", s) else None

    def start(self):
        if not (self.host and self.pdir and self.env["EPIC_P_PASS"]):
            raise RuntimeError("P is not set up (host %s, folder %s, password %s)" % (
                bool(self.host), bool(self.pdir), bool(self.env["EPIC_P_PASS"])))
        self.kill_remote()  # left by an earlier, killed run
        self.secret = self._read_secret()
        if not self.secret:
            raise RuntimeError("P's Owner API secret could not be read")
        m = self._start_p("listener", ["listen", "-m", "epicbox"], r"Starting epicbox listener for: (\S+)")
        if not m:
            raise RuntimeError("P's Epicbox listener did not start")
        self.address = m.group(1)
        if not self._start_p("owner", ["owner_api"], r"Starting Owner API|Owner API at"):
            raise RuntimeError("P's owner_api did not start")
        self._forward()
        for _ in range(30):
            try:
                self.rpc("node_height", [])
                break
            except Exception:  # noqa: BLE001 - the forward comes up within seconds
                time.sleep(2)
        else:
            raise RuntimeError("P's Owner API does not answer through the forward")
        self.log("P service up: address %s" % self.address)

    def supervise(self):
        """Restart the listener or owner_api when one quits (node blips), the forward when it drops."""
        while not self.stopping.wait(10):
            try:
                self.watch_node() or self.watch_listener()
            except Exception as e:  # noqa: BLE001 - a failed check never stops the supervisor
                self.log("P node check failed: %s" % e)
            for name in ("listener", "owner", "forward"):
                proc, _ = self.procs.get(name, (None, None))
                if proc is None or proc.poll() is None:
                    continue
                self.log("P %s quit (exit %s): starting it again" % (name, proc.returncode))
                if name == "forward":
                    self._forward()
                elif name == "listener":
                    self.kill_remote(("listen",))  # never two listeners on P's address
                    self._start_p("listener", ["listen", "-m", "epicbox"], r"Starting epicbox listener for:")
                else:
                    self.kill_remote(("owner_api",))
                    self._start_p("owner", ["owner_api"], r"Starting Owner API|Owner API at")

    # -- P's node: the next synced one when the listener pauses on it

    def _paused(self):
        """True while the listener's last line is its pause on "Node not synced"."""
        lp = self.procs.get("listener", (None, None))[1]
        try:
            with open(lp, "rb") as f:
                f.seek(max(0, os.path.getsize(lp) - 4096))
                lines = clean(f.read().decode(errors="replace")).splitlines()
        except (OSError, TypeError):
            return False
        return bool(lines) and PAUSED in lines[-1]

    def watch_node(self, now=None):
        """Called every 10 s: after PAUSE_S of the listener's pause, unpause(). -> unpause()'s answer, else None."""
        now = now or time.time()
        if not self._paused():
            self.paused_at = None
            return None
        self.paused_at = self.paused_at or now
        if now - self.paused_at < PAUSE_S or now - self.moved_at < MOVE_EVERY_S:
            return None
        self.moved_at = now
        return self.unpause(int(now - self.paused_at))

    def watch_listener(self, now=None):
        """Called every 10 s: a send unanswered for STALL_S while the listener wrote nothing since it was
        made restarts the listener. -> the slates it was restarted for, else None."""
        now = now or time.time()
        if now - self.moved_at < MOVE_EVERY_S:
            return None
        lp = self.procs.get("listener", (None, None))[1]
        try:
            spoke = os.path.getmtime(lp)
        except (OSError, TypeError):
            return None
        with self.state_mu:
            stuck = [(sid, r) for sid, r in self.sends.items() if r["state"] == "sent" and now - r["at"] >= STALL_S
                     and r["at"] > spoke and r.get("restarts", 0) < STALL_TRIES]
            for _, r in stuck:
                r["restarts"] = r.get("restarts", 0) + 1
        if not stuck:
            return None
        self.moved_at = now
        self.log("P listener silent %d s with %d send(s) unanswered (%s): starting it again" % (
            now - spoke, len(stuck), ", ".join(sid[:8] for sid, _ in stuck)))
        self.kill_remote(("listen",))  # the supervisor starts it again when its local side quits
        return [sid for sid, _ in stuck]

    def _p_toml(self):
        r = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=20", self.host,
                            'type "%s\\epic-wallet.toml"' % self.pdir], capture_output=True, text=True, timeout=60)
        return r.stdout if r.returncode == 0 else ""

    def _set_p_node(self, url):
        """check_node_api_http_addr in P's epic-wallet.toml = url (a URL of the test order: no quotes)."""
        q = ("$f = '%s\\epic-wallet.toml'; $t = [IO.File]::ReadAllText($f); "
             "[IO.File]::WriteAllText($f, ($t -replace '(?m)^check_node_api_http_addr\\s*=\\s*\"[^\"]*\"', "
             "'check_node_api_http_addr = \"%s\"'))" % (self.pdir, url))
        subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=20", self.host,
                        "powershell -NoProfile -Command -"], input=q, capture_output=True, text=True, timeout=90)
        m = NODE_LINE.search(self._p_toml())
        return bool(m) and m.group(1) == url

    def unpause(self, paused_s):
        """P's node not synced, behind or down: P moves to the next synced node of the test order and both
        processes start again on it. Its node synced: the listener alone starts again (a stuck poll).
        No node synced: nothing moves. -> the node P is on afterwards, None when nothing changed."""
        m = NODE_LINE.search(self._p_toml())
        cur = m.group(1) if m else None
        picks = ([cur] if cur else []) + [u for u in facts.NODE_PICK if u != cur]
        why = nodehealth.judge(picks, nodehealth.status)
        to = next((u for u in picks if not why.get(u)), None)
        if not to:
            self.log("P listener paused %d s and no node is synced (%s): leaving it" % (
                paused_s, "; ".join("%s %s" % (u, why[u]) for u in picks)))
            return None
        if to == cur:
            self.log("P listener paused %d s on 'Node not synced' while its node %s is synced: starting it again"
                     % (paused_s, cur))
            self.kill_remote(("listen",))  # the supervisor starts it again
            return cur
        if not self._set_p_node(to):
            self.log("P node could not be moved to %s (its epic-wallet.toml does not say it)" % to)
            return None
        self.log("P node moved: %s -> %s (the listener paused %d s on 'Node not synced'; %s %s)" % (
            cur, to, paused_s, cur, why.get(cur) if cur else "unset"))
        self.kill_remote()  # listener and owner_api read the node at start; the supervisor starts both again
        return to

    def stop(self):
        self.stopping.set()
        for name in ("forward", "owner", "listener"):
            self._stop_local(self.procs.get(name, (None, None))[0])
        ok = self.kill_remote()
        for name in ("owner", "listener"):
            lp = os.path.join(self.dir, name + ".log")
            with contextlib.suppress(OSError):
                text = clean(open(lp, errors="replace").read())
                with open(lp, "w") as f:
                    f.write(text + "\n")
        self.log("P service stopped%s" % ("" if ok else "; P processes may be left on P's side"))

    # -- Owner API v2 (the wallet opened by owner_api at its start)

    def rpc(self, method, params, timeout=180):
        with self.state_mu:
            self.rpc_id += 1
            rid = self.rpc_id
        body = json.dumps({"jsonrpc": "2.0", "method": method, "params": params, "id": rid}).encode()
        req = urllib.request.Request("http://127.0.0.1:%d/v2/owner" % self.port, data=body, headers={
            "Content-Type": "application/json",
            "Authorization": "Basic " + base64.b64encode(("epic:" + self.secret).encode()).decode()})
        with urllib.request.urlopen(req, timeout=timeout) as r:
            reply = json.loads(r.read().decode())
        if "error" in reply:
            raise RuntimeError("%s: %s" % (method, reply["error"]))
        res = reply.get("result", {})
        if isinstance(res, dict) and "Err" in res:
            raise RuntimeError("%s: %s" % (method, json.dumps(res["Err"])[:300]))
        return res.get("Ok") if isinstance(res, dict) else res

    def tx_entry(self, slate_id=None, tx_id=None):
        res = self.rpc("retrieve_txs", [False, tx_id, slate_id, None, None, None])
        txs = (res or {}).get("txs") if isinstance(res, dict) else (res[1] if isinstance(res, list) else None)
        txs = [t for t in txs or [] if str(t.get("tx_type", "")).startswith("TxSent")]
        return txs[0] if txs else None

    def finalized_copy(self, entry):
        """P's saved copy of the tx when it is signed (the listener finalized it), else None: before the
        reply, the saved copy carries a zero kernel excess."""
        tx = self.rpc("get_stored_tx", [entry])
        if not tx:
            return None
        k = ((tx.get("body") or {}).get("kernels") or [{}])[0]
        return tx if k.get("excess") and set(k["excess"]) != {"0"} else None

    def post(self, tx):
        try:
            self.rpc("post_tx", [tx, True])
            return True, "posted (fluff)"
        except Exception as e:  # noqa: BLE001
            s = str(e)
            if re.search(r"[Dd]uplicate|already", s):
                return True, "already in the pool"
            return False, s[-200:]

    # -- requests

    def do_send(self, address, amount, what=""):
        atomic = to_atomic(amount)
        args = {"src_acct_name": None, "amount": str(atomic), "minimum_confirmations": MIN_CONF,
                "max_outputs": 500, "num_change_outputs": 1, "selection_strategy_is_use_all": False,
                "message": None, "target_slate_version": None, "payment_proof_recipient_address": None,
                "ttl_blocks": None, "send_args": {"method": "epicbox", "dest": address, "finalize": False,
                                                  "post_tx": False, "fluff": False}}  # Epicbox: unused
        t0 = time.time()
        with self.send_mu:  # selection and the output lock in one call, never two at once
            waited = time.time() - t0
            slate = self.rpc("init_send_tx", {"args": args}, timeout=120)
        sid = (slate or {}).get("id")
        if not sid:
            raise RuntimeError("init_send_tx returned no slate")
        entry = self.tx_entry(slate_id=sid)
        rec = {"address": address, "amount": epic_str(atomic), "tx_id": entry and entry.get("id"), "slate": sid,
               "at": time.time(), "state": "sent", "what": what,
               "fee": epic_str(entry["fee"]) if entry and entry.get("fee") is not None else None}
        with self.state_mu:
            self.sends[sid] = rec
        self.log("send %s %s -> %s (%s): slate %s, tx %s, waited %.0f s for another send" % (
            what, rec["amount"], address[:12], "ok", sid, rec["tx_id"], waited))
        return dict(rec)

    def poster(self):
        """Posts each send once, with fluff, as soon as the listener has finalized it; keeps states current."""
        last_refresh = 0
        while not self.stopping.wait(2):
            with self.state_mu:
                pending = [r for r in self.sends.values() if r["state"] in ("sent", "posted")]
            if not pending:
                continue
            try:
                if time.time() - last_refresh > 30:  # confirmations: P's own records, refreshed from the node
                    last_refresh = time.time()
                    self.rpc("retrieve_txs", [True, None, None, None, None, None], timeout=300)
                for r in pending:
                    e = self.tx_entry(slate_id=r["slate"])
                    if not e:
                        continue
                    if e.get("tx_type") == "TxSentCancelled":
                        r["state"] = "cancelled"
                    elif e.get("confirmed"):
                        r["state"] = "confirmed"
                        self.log("send %s confirmed" % r["slate"])
                    elif r["state"] == "sent":
                        tx = self.finalized_copy(e)
                        if tx:
                            ok, note = self.post(tx)
                            self.log("send %s finalized by the listener: %s" % (r["slate"], note))
                            if ok:
                                r["state"] = "posted"
            except Exception as e:  # noqa: BLE001 - the next round tries again
                self.log("poster: %s" % e)

    def handle(self, req):
        self.last_request = time.time()
        op = req.get("op")
        if op == "ping":
            return {"ok": True, "address": self.address}
        if op == "send":
            return {"ok": True, **self.do_send(req["address"], req["amount"], req.get("what", ""))}
        if op == "status":
            with self.state_mu:
                r = self.sends.get(req["slate"])
            return {"ok": bool(r), **(r or {})}
        if op == "info":
            res = self.rpc("retrieve_summary_info", [True, MIN_CONF], timeout=300)
            s = res[1] if isinstance(res, list) else res
            return {"ok": True, "spendable": epic_str(s["amount_currently_spendable"]), "total": epic_str(s["total"])}
        if op == "cli":
            # A one-shot of P's CLI beside the two processes, as the GUI wallet does: `outputs`, or the
            # preflight's self-send (-m self: no Epicbox, no listener, a few seconds). Sends one at a
            # time, as every send.
            args = [str(a) for a in req["args"]]
            if not (args[:1] == ["outputs"] or args[:3] == ["send", "-m", "self"]):
                return {"ok": False, "rc": 2, "out": "only outputs or a self-send"}
            mu = self.send_mu if args[0] == "send" else contextlib.nullcontext()
            with mu:
                r = subprocess.run(["python3", "-I", self.tool, *args], env=self.env, capture_output=True,
                                   text=True, errors="replace", timeout=300, cwd=os.path.dirname(self.tool))
            out = clean(r.stdout + r.stderr)
            self.log("p.py %s: exit %d" % (" ".join(args[:6]), r.returncode))
            return {"ok": r.returncode == 0, "rc": r.returncode, "out": out}
        if op == "cancel":
            return self.cancel(req["slate"], req.get("why", ""))
        if op == "stop":
            threading.Thread(target=self.shutdown_soon, daemon=True).start()
            return {"ok": True}
        return {"ok": False, "note": "unknown op %r" % op}

    def cancel(self, slate, why=""):
        """Cancels a send of P that can never finalize (its slate went where the receiver does not read):
        P's inputs it holds are spendable again. Refused once the send is confirmed."""
        with self.send_mu:
            e = self.tx_entry(slate_id=slate)
            if not e:
                return {"ok": False, "note": "P has no send with slate %s" % slate}
            if e.get("confirmed"):
                return {"ok": False, "note": "send %s is confirmed" % slate}
            if e.get("tx_type") != "TxSentCancelled":
                self.rpc("cancel_tx", [None, slate])
            with self.state_mu:
                if slate in self.sends:
                    self.sends[slate]["state"] = "cancelled"
        self.log("send %s (tx %s) cancelled%s" % (slate, e.get("id"), ": " + why if why else ""))
        return {"ok": True, "tx": e.get("id")}

    def shutdown_soon(self):
        time.sleep(0.5)
        self.server.shutdown()

    def idle(self):
        """Stops after idle_min without a request, once none of its sends is still on its way."""
        while not self.stopping.wait(30):
            with self.state_mu:
                busy = [r for r in self.sends.values() if r["state"] in ("sent", "posted") and time.time() - r["at"] < 3600]
            if not busy and time.time() - self.last_request > self.cfg["idle_min"] * 60:
                self.log("idle for %d min: stopping" % self.cfg["idle_min"])
                self.server.shutdown()
                return


class _Handler(socketserver.StreamRequestHandler):
    def handle(self):
        line = self.rfile.readline()
        try:
            reply = self.server.svc.handle(json.loads(line))
        except Exception as e:  # noqa: BLE001 - the client gets the reason
            reply = {"ok": False, "note": "%s: %s" % (type(e).__name__, str(e)[-300:])}
        self.wfile.write((json.dumps(reply) + "\n").encode())


class _Server(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True


def serve(cfg):
    os.makedirs(cfg["dir"], mode=0o700, exist_ok=True)
    sock = os.path.join(cfg["dir"], "p.sock")
    svc = Service(cfg)
    svc.log("starting: waiting for the old P lock %s (a driver of an older checkout may hold it)" % cfg["lock"])
    os.makedirs(os.path.dirname(cfg["lock"]), exist_ok=True)
    lock = open(cfg["lock"], "a")
    fcntl.flock(lock, fcntl.LOCK_EX)
    try:
        svc.start()
        with contextlib.suppress(FileNotFoundError):
            os.unlink(sock)
        old = os.umask(0o077)
        server = _Server(sock, _Handler)
        os.umask(old)
        server.svc, svc.server = svc, server
        for target in (svc.supervise, svc.poster, svc.idle):
            threading.Thread(target=target, daemon=True).start()
        signal.signal(signal.SIGTERM, lambda *_: threading.Thread(target=server.shutdown, daemon=True).start())
        server.serve_forever()
    except Exception as e:  # noqa: BLE001
        svc.log("P service failed: %s" % e)
        raise
    finally:
        svc.stop()
        with contextlib.suppress(FileNotFoundError):
            os.unlink(sock)
        fcntl.flock(lock, fcntl.LOCK_UN)
        lock.close()


# ---- the client ----------------------------------------------------------------------------------


class Client:
    """What drivers and the preflight use: requests to the service, which is started when none runs."""

    def __init__(self, cfg=None, log=None):
        self.cfg = cfg or env_paths()
        self.sock = os.path.join(self.cfg["dir"], "p.sock")
        self.log = log or (lambda m: None)

    def call(self, op, timeout=600, **kw):
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            s.connect(self.sock)
            s.sendall((json.dumps({"op": op, **kw}) + "\n").encode())
            buf = b""
            while not buf.endswith(b"\n"):
                chunk = s.recv(65536)
                if not chunk:
                    break
                buf += chunk
        return json.loads(buf or b'{"ok": false, "note": "no reply"}')

    def up(self):
        try:
            return self.call("ping", timeout=20).get("ok", False)
        except OSError:
            return False

    def ensure(self, wait_s=900):
        """None when the service answers (started here if need be), else why not."""
        if self.up():
            return None
        os.makedirs(self.cfg["dir"], mode=0o700, exist_ok=True)
        with open(os.path.join(self.cfg["dir"], "start.lock"), "a") as lk:
            fcntl.flock(lk, fcntl.LOCK_EX)  # one starter; held only while it comes up
            if self.up():
                return None
            self.log("starting the shared P service (%s)" % self.cfg["dir"])
            out = open(os.path.join(self.cfg["dir"], "serve.out"), "a")
            proc = subprocess.Popen([sys.executable, "-I", os.path.abspath(__file__), "serve"], stdin=subprocess.DEVNULL,
                                    stdout=out, stderr=subprocess.STDOUT, start_new_session=True)
            end = time.time() + wait_s
            while time.time() < end:
                if self.up():
                    self.log("shared P service up")
                    return None
                if proc.poll() is not None:
                    return "the P service quit (exit %s; see %s/service.log)" % (proc.returncode, self.cfg["dir"])
                time.sleep(3)
            return "the P service did not come up in %d s (see %s/service.log)" % (wait_s, self.cfg["dir"])


def main(argv):
    cfg = env_paths()
    cmd = argv[1] if len(argv) > 1 else "status"
    if cmd == "serve":
        serve(cfg)
        return 0
    c = Client(cfg, log=lambda m: print(m, file=sys.stderr))
    if cmd == "status":
        print(json.dumps(c.call("ping") if c.up() else {"ok": False, "note": "not running"}))
        return 0
    if cmd == "stop":
        print(json.dumps(c.call("stop") if c.up() else {"ok": True, "note": "not running"}))
        return 0
    why = c.ensure()
    if why:
        print(why, file=sys.stderr)
        return 2
    if cmd == "cancel":
        print(json.dumps(c.call("cancel", slate=argv[2], why=" ".join(argv[3:]))))
        return 0
    print(json.dumps(c.call(cmd)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
