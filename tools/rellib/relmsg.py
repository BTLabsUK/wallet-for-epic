# SPDX-License-Identifier: Apache-2.0
"""The Telegram release relay (relmsg; contract: docs/release-relay.md). One live message per run,
edited in place; an alert when a step needs a reaction; the publish gate.

Status calls are best effort: if relmsg is down, steps still run and log. The gate is the
opposite: anything but an explicit approval is "no" (fail closed). The runner's producer token
cannot approve; approval comes from the owner's button or from the operator on the owner's word."""
import json
import os
import subprocess
import time

GATE_APPROVED, GATE_HELD, GATE_PENDING = "approved", "held", "pending"
KEY_CALLS = ("start", "gate", "gate-status", "done")


class Relmsg:
    def __init__(self, run, conf, enabled=True, log=None):
        self.run = run
        self.bin = os.environ.get("REL_RELMSG") or conf.get("bin", "relmsg")
        self.title = conf.get("title", "Epic Wallet")
        self.enabled = enabled
        self.log = log or (lambda *a: None)
        self.down = False

    @property
    def release_id(self):
        return (self.run.info.get("relmsg") or {}).get("release_id")

    def _call(self, args, want_json=True):
        if not self.enabled:
            return 99, {"error": "relmsg disabled for this run"}
        cmd = [self.bin, "--json"] if want_json else [self.bin]
        if self.release_id and args[0] not in ("start",):
            cmd += ["--release", str(self.release_id)]
        cmd += [str(a) for a in args]
        # The bot limits each token per minute (HTTP 429), and a network blip is not an answer:
        # wait and ask again, a bounded number of times. Never turns anything into an approval.
        waits = [float(x) for x in os.environ.get("REL_RELMSG_BACKOFF", "10,20,40").split(",") if x.strip()]
        for wait in waits + [None]:
            try:
                p = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            except (OSError, subprocess.TimeoutExpired) as e:
                self.run.event("relmsg", "error", detail=f"{args[0]}: {e}")
                return 98, {"error": str(e)}
            busy = "HTTP 429" in p.stderr
            # A relay that is down is asked again only for what matters (start, gate, done), and
            # only until it has been found down once in this process.
            down = ("network error" in p.stderr or "HTTP 50" in p.stderr) and args[0] in KEY_CALLS and not self.down
            if p.returncode != 1 or not (busy or down) or wait is None:
                if p.returncode == 1 and down:
                    self.down = True
                break
            self.run.event("relmsg", "retry", detail=f"{args[0]}: {p.stderr.strip()[-120:]}; again in {wait:g}s")
            time.sleep(wait)
        out = {}
        if p.stdout.strip():
            try:
                out = json.loads(p.stdout.strip().splitlines()[-1])
            except json.JSONDecodeError:
                out = {"text": p.stdout.strip()[-500:]}
        if p.returncode not in (0, 3, 5):
            self.run.event("relmsg", "error", detail=f"{args[0]} exit {p.returncode}: {p.stderr.strip()[-300:]}")
        return p.returncode, out

    def start(self, steps, platforms, note=None):
        if self.release_id:
            return self.release_id
        info = self.run.info
        args = ["start", info["version"], "--commit", info["commit"], "--run-id", info["run_id"],
                "--title", self.title, "--steps", ",".join(steps)]
        if platforms:
            args += ["--platforms", ",".join(platforms)]
        if info.get("test"):
            args.append("--test")
        rc, out = self._call(args)
        if rc == 0 and out.get("release_id") is not None:
            info.setdefault("relmsg", {})["release_id"] = out["release_id"]
            self.run.save_info()
            self.run.event("relmsg", "start", release_id=out["release_id"])
        return self.release_id

    def step(self, sid, status, note=None, label=None, platform=None):
        if not self.release_id:
            return
        # relmsg's states: pending|running|waiting|ok|failed|skipped.
        status = {"done": "ok", "held": "waiting", "closed": "waiting"}.get(status, status)
        args = ["step", sid, status]
        if note:
            args += ["--note", note[:200]]
        if label:
            args += ["--label", label[:60]]
        if platform:
            args += ["--platform", platform]
        if status == "failed":
            args.append("--no-alert")  # the runner sends its own alert, with the hint
        self._call(args)

    def platform(self, platform, status, note=None):
        if not self.release_id:
            return
        args = ["platform", platform, status] + (["--note", note[:200]] if note else [])
        self._call(args)

    def alert(self, title, step=None, log=None, expects=None, key=None):
        if not self.release_id:
            return
        args = ["alert", title[:200]]
        if step:
            args += ["--step", step]
        if log and os.path.exists(log):
            args += ["--log", log]
        if expects:
            args += ["--expects", expects[:500]]
        if key:
            args += ["--key", key]
        self._call(args)

    def gate_open(self, name, summary_file):
        """-> (gate_id or None, error text or None). Opening an existing gate returns it."""
        if not self.release_id:
            return None, "no live release in relmsg (relmsg start failed or relmsg is off)"
        rc, out = self._call(["gate", name, "--summary-file", summary_file, "--no-wait"])
        if rc == 0 and out.get("gate_id") is not None:
            return out["gate_id"], None
        return None, out.get("error") or f"relmsg gate exit {rc}"

    def gate_status(self, gate_id):
        """-> approved | held | pending | error. Only exit 0 means approved."""
        rc, out = self._call(["gate-status", gate_id])
        if rc == 0 and out.get("status") == GATE_APPROVED:
            return GATE_APPROVED, out
        if rc == 3:
            return GATE_HELD, out
        if rc == 5:
            return GATE_PENDING, out
        return "error", out

    def done(self, status, note=None):
        if not self.release_id:
            return
        self._call(["done", status] + (["--note", note[:500]] if note else []))
