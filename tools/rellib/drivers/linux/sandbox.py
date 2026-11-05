#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""A private desktop session for the AppImage: own Xvfb, own dbus session, an unlocked throwaway
gnome-keyring and the AT-SPI bus switched on, with HOME and the XDG dirs under one sandbox folder.

    sandbox.py start <sandbox>             Xvfb + dbus + keyring + a11y; writes <sandbox>/env
    sandbox.py app <sandbox> <AppDir>      start the extracted AppImage (refuses outside the sandbox)
    sandbox.py app-stop <sandbox>          stop the app only (an update keeps the session)
    sandbox.py stop <sandbox>              stop everything this sandbox started, by PID
    sandbox.py shot <sandbox> <png>        screenshot of the sandbox display

The app is never started unless HOME, the XDG dirs and DISPLAY are the sandbox's: a failed env
step once started a release on the real display with the real HOME.
"""
import pathlib
import fcntl
import os
import pwd
import re
import secrets
import signal
import subprocess
import sys
import time

# the account's real home, from the password database (HOME may already be the sandbox's)
REAL_HOME = os.path.realpath(pwd.getpwuid(os.getuid()).pw_dir)


def _p(sb, *parts):
    return os.path.join(sb, *parts)


def read_env(sb):
    env = {}
    try:
        with open(_p(sb, "env")) as f:
            for line in f:
                k, _, v = line.rstrip("\n").partition("=")
                env[k] = v
    except FileNotFoundError:
        pass
    return env


def _write_env(sb, env):
    tmp = _p(sb, "env.tmp")
    with open(tmp, "w") as f:
        for k, v in env.items():
            f.write("%s=%s\n" % (k, v))
    os.replace(tmp, _p(sb, "env"))


def _alive(pid):
    try:
        os.kill(int(pid), 0)
        return True
    except (OSError, ValueError, TypeError):
        return False


def _runtime(sb):
    """The sandbox's XDG_RUNTIME_DIR: a short folder of its own outside the sandbox, because the
    sockets in it (dbus, at-spi, the app's atk-bridge server) must fit the 108-byte unix socket
    path; under a long work folder the app's atk-bridge said "Socket name too long" and showed
    nothing to AT-SPI (26.10.26-run3 trust-linux-notor). sandbox/runtime links to it."""
    import hashlib
    tag = hashlib.sha1(os.path.abspath(sb).encode()).hexdigest()[:10]
    return os.path.join(REAL_HOME, ".cache", "rts", tag)


def _pid(sb, name):
    try:
        return int(pathlib.Path(_p(sb, "pids", name)).read_text().strip())
    except (OSError, ValueError):
        return None


def _save_pid(sb, name, pid):
    with open(_p(sb, "pids", name), "w") as f:
        f.write(str(pid))


def _free_display(start=140):
    for n in range(start, 200):
        if not os.path.exists("/tmp/.X11-unix/X%d" % n) and not os.path.exists("/tmp/.X%d-lock" % n):
            return n
    raise SystemExit("no free X display")


def _lock_pid(n):
    try:
        return int(pathlib.Path("/tmp/.X%d-lock" % n).read_text().strip())
    except (OSError, ValueError):
        return None


def _own_xvfb(sb, size):
    """Starts an Xvfb on a free display and returns (display, process) once that display is ours:
    two sandboxes started in the same second see the same free number, the later Xvfb finds it
    taken and quits while the other one's socket is there. The X lock file names the server that
    holds the display, so a display counts as ours only when it names our Xvfb; else the next one.
    Sandboxes claim displays one at a time (a lock file in ~/.cache), and a claim counts once our
    Xvfb is still up a moment later: two trust steps started together raced for :144 (26.10.26-run2)."""
    path = os.path.join(pwd.getpwuid(os.getuid()).pw_dir, ".cache", "rel-xvfb-claim.lock")  # not a sandbox HOME
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            return _claim_xvfb(sb, size)
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def _claim_xvfb(sb, size):
    n = 140
    while True:
        n = _free_display(n)
        x = subprocess.Popen(["Xvfb", ":%d" % n, "-screen", "0", size, "-nolisten", "tcp", "-ac"],
                             stdout=open(_p(sb, "logs", "xvfb.log"), "w"), stderr=subprocess.STDOUT,
                             start_new_session=True)
        for _ in range(100):
            if x.poll() is not None or (os.path.exists("/tmp/.X11-unix/X%d" % n) and _lock_pid(n) == x.pid):
                break
            time.sleep(0.1)
        if x.poll() is None and _lock_pid(n) == x.pid:
            time.sleep(0.5)
            if x.poll() is None and _lock_pid(n) == x.pid:
                return n, x
        if x.poll() is None:
            if os.path.exists("/tmp/.X11-unix/X%d" % n):
                x.kill()  # up, but the display is another server's
            else:
                raise SystemExit("Xvfb :%d did not start (logs/xvfb.log)" % n)
        n += 1


def base_env(sb):
    """The environment every sandbox process gets: nothing inherited but PATH and LANG."""
    return {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "LANG": "C.UTF-8",
        "HOME": _p(sb, "home"),
        "XDG_DATA_HOME": _p(sb, "home", ".local", "share"),
        "XDG_CONFIG_HOME": _p(sb, "home", ".config"),
        "XDG_CACHE_HOME": _p(sb, "home", ".cache"),
        "XDG_RUNTIME_DIR": _runtime(sb),
        "XDG_SESSION_TYPE": "x11",
        "GDK_BACKEND": "x11",
        "NO_AT_BRIDGE": "0",
        "GTK_A11Y": "atspi",
        "LIBGL_ALWAYS_SOFTWARE": "1",
        "TMPDIR": _p(sb, "tmp"),
    }


def start(sb, size="1400x950x24"):
    sb = os.path.abspath(sb)
    if os.path.realpath(sb) in (REAL_HOME, "/") or not os.path.isdir(sb):
        raise SystemExit("sandbox %r is not a folder of its own" % sb)
    if _alive(_pid(sb, "xvfb")):
        return read_env(sb)
    os.umask(0o077)
    for d in ("pids", "logs", "tmp", "home/.local/share/keyrings", "home/.config", "home/.cache"):
        os.makedirs(_p(sb, d), exist_ok=True)
    os.makedirs(_runtime(sb), mode=0o700, exist_ok=True)
    os.chmod(_runtime(sb), 0o700)
    if not os.path.lexists(_p(sb, "runtime")):
        os.symlink(_runtime(sb), _p(sb, "runtime"))
    env = base_env(sb)
    n, x = _own_xvfb(sb, size)
    _save_pid(sb, "xvfb", x.pid)
    env["DISPLAY"] = ":%d" % n
    # dbus session bus of our own (never the user's)
    out = subprocess.run(["dbus-daemon", "--session", "--fork", "--print-address=1", "--print-pid=1"],
                         env=env, capture_output=True, text=True, timeout=20).stdout.split()
    env["DBUS_SESSION_BUS_ADDRESS"], dpid = out[0], out[1]
    _save_pid(sb, "dbus", dpid)
    kpw = _p(sb, "keyring.pw")
    if not os.path.exists(kpw):
        with open(kpw, "w") as f:
            f.write(secrets.token_urlsafe(18))
    with open(kpw) as f:
        r = subprocess.run(["gnome-keyring-daemon", "--unlock", "--components=secrets"], stdin=f, env=env,
                           capture_output=True, text=True, timeout=30)
    for line in r.stdout.splitlines():
        k, _, v = line.partition("=")
        if k == "GNOME_KEYRING_CONTROL":
            env[k] = v
    kp = subprocess.run(["pgrep", "-n", "-f", "gnome-keyring-daemon"], capture_output=True, text=True).stdout.split()
    for p in kp:
        if _env_of(p).get("XDG_RUNTIME_DIR") == env["XDG_RUNTIME_DIR"]:
            _save_pid(sb, "keyring", p)
    a11y = ["dbus-send", "--session", "--print-reply", "--dest=org.a11y.Bus", "/org/a11y/bus"]
    with open(_p(sb, "logs", "atspi.log"), "w") as log:
        subprocess.run(a11y + ["org.a11y.Bus.GetAddress"], env=env, stdout=log, stderr=log, timeout=20)
        for prop in ("IsEnabled", "ScreenReaderEnabled"):
            subprocess.run(a11y + ["org.freedesktop.DBus.Properties.Set", "string:org.a11y.Status",
                                   "string:%s" % prop, "variant:boolean:true"], env=env, stdout=log, stderr=log,
                           timeout=20)
    _write_env(sb, env)
    return env


def _env_of(pid):
    try:
        raw = pathlib.Path("/proc/%s/environ" % pid).read_bytes().split(b"\0")
    except OSError:
        return {}
    out = {}
    for item in raw:
        k, _, v = item.decode(errors="replace").partition("=")
        out[k] = v
    return out


def guard(sb, env):
    """Refuse unless env points at this sandbox and its own Xvfb."""
    sb = os.path.abspath(sb)
    home = env.get("HOME", "")
    if not home.startswith(sb + os.sep) or os.path.realpath(home) == REAL_HOME:
        raise SystemExit("refusing: HOME %r is not inside the sandbox" % home)
    for k in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        if not env.get(k, "").startswith(sb + os.sep):
            raise SystemExit("refusing: %s is not inside the sandbox" % k)
    if env.get("XDG_RUNTIME_DIR") != _runtime(sb):
        raise SystemExit("refusing: XDG_RUNTIME_DIR is not this sandbox's")
    disp = env.get("DISPLAY", "")
    m = re.fullmatch(r":(\d+)", disp)
    if not m or int(m.group(1)) < 100:
        raise SystemExit("refusing: DISPLAY %r is not a sandbox display" % disp)
    try:
        lock_pid = int(pathlib.Path("/tmp/.X%s-lock" % m.group(1)).read_text().strip())
    except (OSError, ValueError):
        lock_pid = None
    if lock_pid != _pid(sb, "xvfb"):
        raise SystemExit("refusing: DISPLAY %s is not this sandbox's Xvfb" % disp)
    if not env.get("DBUS_SESSION_BUS_ADDRESS"):
        raise SystemExit("refusing: no sandbox dbus session")


def app(sb, appdir, extra_env=None):
    sb = os.path.abspath(sb)
    env = read_env(sb)
    guard(sb, env)
    env.update(extra_env or {})
    run = os.path.join(appdir, "AppRun")
    if not os.access(run, os.X_OK):
        raise SystemExit("no AppRun in %s" % appdir)
    log = open(_p(sb, "logs", "app-%d.log" % int(time.time())), "w")
    p = subprocess.Popen([run], env=env, cwd=env["HOME"], stdout=log, stderr=subprocess.STDOUT,
                         start_new_session=True)
    _save_pid(sb, "app", p.pid)
    return p.pid


def _descendants(pid):
    out = []
    try:
        kids = subprocess.run(["pgrep", "-P", str(pid)], capture_output=True, text=True).stdout.split()
    except OSError:
        kids = []
    for k in kids:
        out += _descendants(k) + [int(k)]
    return out


def app_stop(sb, timeout=20):
    sb = os.path.abspath(sb)
    pid = _pid(sb, "app")
    if not _alive(pid):
        return
    procs = _descendants(pid) + [pid]
    for p in [pid] + procs:
        try:
            os.kill(p, signal.SIGTERM)
        except OSError:
            pass
    end = time.time() + timeout
    while time.time() < end and any(_alive(p) for p in procs):
        time.sleep(0.2)
    for p in procs:
        if _alive(p):
            try:
                os.kill(p, signal.SIGKILL)
            except OSError:
                pass
    # the app's own helpers (tor, lepic) carry the sandbox runtime dir: none may outlive it
    _kill_by_runtime(sb, keep={_pid(sb, "dbus"), _pid(sb, "keyring"), _pid(sb, "xvfb")}, apps_only=True)


def _kill_by_runtime(sb, keep=(), apps_only=False):
    rt = _runtime(sb)
    keep = {int(k) for k in keep if k}
    for p in os.listdir("/proc"):
        if not p.isdigit() or int(p) in keep or int(p) == os.getpid():
            continue
        if _env_of(p).get("XDG_RUNTIME_DIR") != rt:
            continue
        if apps_only:
            try:
                exe = os.readlink("/proc/%s/exe" % p)
            except OSError:
                continue
            if any(s in exe for s in ("dbus", "keyring", "at-spi", "Xvfb")):
                continue
        try:
            os.kill(int(p), signal.SIGKILL)
        except OSError:
            pass


def stop(sb):
    sb = os.path.abspath(sb)
    app_stop(sb)
    for name in ("keyring", "dbus"):
        p = _pid(sb, name)
        if _alive(p):
            os.kill(p, signal.SIGTERM)
    _kill_by_runtime(sb, keep={_pid(sb, "xvfb")})
    x = _pid(sb, "xvfb")
    if _alive(x):
        os.kill(x, signal.SIGTERM)
        for _ in range(30):
            if not _alive(x):
                break
            time.sleep(0.1)
        if _alive(x):
            os.kill(x, signal.SIGKILL)
    for f in os.listdir(_p(sb, "pids")) if os.path.isdir(_p(sb, "pids")) else []:
        os.unlink(_p(sb, "pids", f))
    if os.path.exists(_p(sb, "env")):
        os.unlink(_p(sb, "env"))


def shot(sb, png):
    env = read_env(os.path.abspath(sb))
    guard(os.path.abspath(sb), env)
    subprocess.run(["import", "-window", "root", png], env=env, check=True, timeout=30)
    return png


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    cmd, sb = argv[1], argv[2]
    if cmd == "start":
        env = start(sb)
        print("sandbox up on DISPLAY=%s" % env["DISPLAY"])
    elif cmd == "app":
        print("app pid %d" % app(sb, argv[3]))
    elif cmd == "app-stop":
        app_stop(sb)
    elif cmd == "stop":
        stop(sb)
    elif cmd == "shot":
        print(shot(sb, argv[3]))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
