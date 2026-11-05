# SPDX-License-Identifier: Apache-2.0
"""The Mac that runs the iOS Simulator, over ssh from this host: one ControlMaster connection for every
command (simctl, the app's files), and one tunnel process for the ports (WebDriverAgent's HTTP port here
by -L; the stand-ins and hermetic services of this host there by -R, the twin of Android's `adb reverse`).

ssh's own failure (exit 255: the Mac unreachable, the connection cut) raises HarnessGone, as adb's
"device not found" does on Android: the lane reconnects and runs the phase again. Text that must stay
secret goes on ssh's stdin, never in a command line.
"""
import os
import shlex
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from core.faults import HarnessGone  # noqa: E402

CACHE = os.path.expanduser("~/.cache/rel-trust-ios")


def q(s):
    return shlex.quote(str(s))


class Mac:
    """ssh to [host] (an ssh config name). Commands run in the Mac user's shell; build them with q()."""

    def __init__(self, host, log=print):
        self.host, self.log = host, log
        os.makedirs(CACHE, mode=0o700, exist_ok=True)
        self.opts = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=20", "-o", "ServerAliveInterval=15",
                     "-o", "ServerAliveCountMax=4", "-o", "ControlMaster=auto",
                     "-o", "ControlPath=%s/cm-%%C" % CACHE, "-o", "ControlPersist=600"]
        self.tunnel = None

    def run(self, cmd, timeout=120, inp=None, text=True, check=False):
        """[cmd] on the Mac; returns the CompletedProcess. Exit 255 (ssh itself failed) raises HarnessGone;
        [check]: any other non-zero exit raises RuntimeError with its output's end."""
        try:
            r = subprocess.run(["ssh", *self.opts, self.host, cmd], capture_output=True, timeout=timeout, input=inp,
                               stdin=None if inp is not None else subprocess.DEVNULL,
                               **({"text": True, "errors": "replace"} if text else {}))
        except subprocess.TimeoutExpired:
            if not self.online():
                raise HarnessGone("mac", "the Mac %s stopped answering" % self.host)
            raise
        if r.returncode == 255:
            err = r.stderr if text else r.stderr.decode("utf-8", "replace")
            raise HarnessGone("mac", "ssh to %s failed: %s" % (self.host, (err or "").strip()[-160:]))
        if check and r.returncode != 0:
            out = (r.stdout + r.stderr) if text else (r.stdout + r.stderr).decode("utf-8", "replace")
            raise RuntimeError("%s: exit %d: %s" % (cmd.split()[0], r.returncode, out.strip()[-300:]))
        return r

    def sh(self, cmd, timeout=120):
        return self.run(cmd, timeout=timeout).stdout

    def online(self):
        try:
            return subprocess.run(["ssh", *self.opts, self.host, "true"], capture_output=True, timeout=30,
                                  stdin=subprocess.DEVNULL).returncode == 0
        except (subprocess.TimeoutExpired, OSError):
            return False

    def put_file(self, local, remote, timeout=600):
        """[local] (a file here) to [remote] on the Mac, through ssh's stdin."""
        with open(local, "rb") as f:
            r = subprocess.run(["ssh", *self.opts, self.host, "cat > %s" % q(remote)], stdin=f, capture_output=True,
                               timeout=timeout)
        if r.returncode == 255:
            raise HarnessGone("mac", "ssh to %s failed copying %s" % (self.host, os.path.basename(local)))
        if r.returncode != 0:
            raise RuntimeError("copying %s to the Mac: %s" % (local, r.stderr.decode("utf-8", "replace").strip()[-200:]))

    # ---- the tunnel

    def open_tunnel(self, local=(), remote=(), logf=None):
        """One `ssh -N` holding [local] (here_port, mac_port) -L forwards and [remote] ports -R forwarded to
        the same port here. Replaces a tunnel already open."""
        self.close_tunnel()
        args = ["ssh", *self.opts, "-N", "-o", "ExitOnForwardFailure=yes"]
        for here, there in local:
            args += ["-L", "127.0.0.1:%d:127.0.0.1:%d" % (here, there)]
        for p in remote:
            args += ["-R", "127.0.0.1:%d:127.0.0.1:%d" % (p, p)]
        self.tunnel = subprocess.Popen(args + [self.host], stdout=logf or subprocess.DEVNULL, stderr=subprocess.STDOUT,
                                       stdin=subprocess.DEVNULL, start_new_session=True)
        return self.tunnel

    def tunnel_up(self):
        return self.tunnel is not None and self.tunnel.poll() is None

    def close_tunnel(self):
        if self.tunnel is not None and self.tunnel.poll() is None:
            self.tunnel.terminate()
            try:
                self.tunnel.wait(10)
            except subprocess.TimeoutExpired:
                self.tunnel.kill()
        self.tunnel = None

    def close(self):
        self.close_tunnel()
        subprocess.run(["ssh", *self.opts, "-O", "exit", self.host], capture_output=True, timeout=30,
                       stdin=subprocess.DEVNULL)
