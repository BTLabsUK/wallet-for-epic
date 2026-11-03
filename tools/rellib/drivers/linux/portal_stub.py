#!/usr/bin/env python3
"""A stand-in file-chooser portal on a sandbox's own session bus, so the driver can answer the app's
file dialogs (file_picker on Linux asks org.freedesktop.portal.FileChooser over dbus; the sandbox has
no portal and no person to click).

    portal_stub.py <sandbox>      serve until the sandbox's bus goes

The driver queues the answer before it presses the button that opens a dialog: answer(sb, path).
Only paths inside the sandbox are answered (others cancel), and only on the sandbox's own bus.
OpenFile answers with that file; SaveFile with that file, or <folder>/<the name the app proposed>
when the queued path is a folder. Nothing queued: the dialog is cancelled, as a person would close
it. Each request is one line in <sandbox>/portal/log (method, title, chosen path; no file contents).

ensure(sb) starts it when it is not running: the app's restart (sandbox.app_stop) kills every
process on the sandbox's runtime dir, this one too."""
import json
import os
import signal
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sandbox  # noqa: E402

NAME = "org.freedesktop.portal.Desktop"
PATH = "/org/freedesktop/portal/desktop"
IFACE = "org.freedesktop.portal.FileChooser"
XML = """<node><interface name="org.freedesktop.portal.FileChooser">
  <method name="OpenFile"><arg type="s" direction="in"/><arg type="s" direction="in"/>
    <arg type="a{sv}" direction="in"/><arg type="o" direction="out"/></method>
  <method name="SaveFile"><arg type="s" direction="in"/><arg type="s" direction="in"/>
    <arg type="a{sv}" direction="in"/><arg type="o" direction="out"/></method>
  <property name="version" type="u" access="read"/>
</interface></node>"""
# the app subscribes to the Response signal after OpenFile returns: answer a little later, as a person would
REPLY_S = 1.5


def _dir(sb):
    return os.path.join(sb, "portal")


def answer(sb, path):
    """The next dialog's answer: a file to open, a file or folder to save to; None cancels it."""
    os.makedirs(_dir(sb), exist_ok=True)
    nxt = os.path.join(_dir(sb), "next")
    if path is not None and not inside(sb, path):
        raise ValueError("refusing a file dialog answer outside the sandbox: %s" % path)
    if path is None:
        if os.path.exists(nxt):
            os.unlink(nxt)
        return
    with open(nxt + ".tmp", "w") as f:
        f.write(os.path.abspath(path))
    os.replace(nxt + ".tmp", nxt)


def inside(sb, path):
    """Whether [path] is inside the sandbox [sb] (links resolved): the only files a dialog may name."""
    root = os.path.realpath(sb)
    return os.path.realpath(path).startswith(root + os.sep)


def _own_bus(sb, env):
    """Refuses unless env is this sandbox's (sandbox.guard) and its bus is not the account's own."""
    sandbox.guard(sb, env)
    bus = env.get("DBUS_SESSION_BUS_ADDRESS", "")
    real = "/run/user/%d/" % os.getuid()
    if real in bus:
        raise SystemExit("refusing: %s is the account's session bus" % bus)


def requests(sb):
    """The dialogs answered so far, oldest first: {method, title, path} (path None when cancelled)."""
    try:
        with open(os.path.join(_dir(sb), "log")) as f:
            return [json.loads(line) for line in f if line.strip()]
    except OSError:
        return []


def _owner(env, name=NAME):
    """The pid that owns [name] on the bus of env, or None."""
    try:
        out = subprocess.run(["dbus-send", "--session", "--print-reply", "--dest=org.freedesktop.DBus",
                              "/org/freedesktop/DBus", "org.freedesktop.DBus.GetConnectionUnixProcessID",
                              "string:" + name], env=env, capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None
    return int(out.split()[-1]) if "uint32" in out else None


def _live(pid):
    """Alive and not a zombie (a killed stub waits for its parent to reap it)."""
    try:
        return pid is not None and open("/proc/%d/stat" % pid).read().rsplit(")", 1)[1].split()[0] != "Z"
    except (OSError, IndexError):
        return False


def running(sb):
    """The stand-in runs and owns the portal name on the sandbox's bus."""
    pid = sandbox._pid(sb, "portal")
    return _live(pid) and _owner(sandbox.read_env(sb)) == pid


def ensure(sb):
    """Starts the stub on the sandbox's bus unless it runs; waits until it owns the portal name."""
    sb = os.path.abspath(sb)
    if running(sb):
        return
    env = sandbox.read_env(sb)
    _own_bus(sb, env)
    os.makedirs(_dir(sb), exist_ok=True)
    _evict(sb, env)
    with open(os.path.join(_dir(sb), "stub.log"), "a") as log:
        p = subprocess.Popen([sys.executable, "-I", os.path.abspath(__file__), sb], env=env, stdout=log,
                             stderr=log, stdin=subprocess.DEVNULL, start_new_session=True)
    sandbox._save_pid(sb, "portal", p.pid)
    end = time.time() + 15
    while time.time() < end:
        if os.path.exists(os.path.join(_dir(sb), "ready.%d" % p.pid)):
            return
        if p.poll() is not None:
            break
        time.sleep(0.2)
    raise RuntimeError("the file-chooser stand-in did not start (see %s)" % os.path.join(_dir(sb), "stub.log"))


def _evict(sb, env):
    """The real portal and its gtk backend (which shows the dialog), when the bus started them for
    the app (the sandbox's dbus can activate xdg-desktop-portal), and a stand-in left from before:
    stopped, so the stand-in can own the name. Only a process on this sandbox's runtime dir is ever
    stopped."""
    gone = []
    for name in (NAME, "org.freedesktop.impl.portal.desktop.gtk"):
        pid = _owner(env, name)
        if pid and sandbox._env_of(pid).get("XDG_RUNTIME_DIR") == sandbox._runtime(sb):
            os.kill(pid, signal.SIGTERM)
            gone.append(pid)
    old = sandbox._pid(sb, "portal")
    if _live(old) and sandbox._env_of(old).get("XDG_RUNTIME_DIR") == sandbox._runtime(sb):
        os.kill(old, signal.SIGTERM)
        gone.append(old)
    end = time.time() + 10
    while time.time() < end and any(_live(p) for p in gone):
        time.sleep(0.2)


def serve(sb):
    import gi
    gi.require_version("Gio", "2.0")
    from gi.repository import Gio, GLib

    sb = os.path.abspath(sb)
    _own_bus(sb, dict(os.environ))
    loop = GLib.MainLoop()
    node = Gio.DBusNodeInfo.new_for_xml(XML)
    seq = [0]

    def chosen(method, opts):
        nxt = os.path.join(_dir(sb), "next")
        try:
            path = open(nxt).read().strip()
            os.unlink(nxt)
        except OSError:
            return None
        if method == "SaveFile" and os.path.isdir(path):
            path = os.path.join(path, os.path.basename(opts.get("current_name") or "file"))
        return path if inside(sb, path) else None  # outside the sandbox: cancelled

    def call(conn, sender, path, iface, method, params, inv):
        _, title, opts = params.unpack()
        seq[0] += 1
        token = opts.get("handle_token") or "t%d" % seq[0]
        who = sender.lstrip(":").replace(".", "_")
        handle = "/org/freedesktop/portal/desktop/request/%s/%s" % (who, token)
        inv.return_value(GLib.Variant("(o)", (handle,)))
        got = chosen(method, opts)
        with open(os.path.join(_dir(sb), "log"), "a") as f:
            f.write(json.dumps({"method": method, "title": title, "path": got,
                                "name": opts.get("current_name")}) + "\n")

        def reply():
            if got:
                res = {"uris": GLib.Variant("as", ["file://" + got])}
                conn.emit_signal(sender, handle, "org.freedesktop.portal.Request", "Response",
                                 GLib.Variant("(ua{sv})", (0, res)))
            else:
                conn.emit_signal(sender, handle, "org.freedesktop.portal.Request", "Response",
                                 GLib.Variant("(ua{sv})", (1, {})))
            return False
        GLib.timeout_add(int(REPLY_S * 1000), reply)

    def prop(conn, sender, path, iface, name):
        return GLib.Variant("u", 3)

    def acquired(conn, name):
        open(os.path.join(_dir(sb), "ready.%d" % os.getpid()), "w").close()

    def bus(conn, name):
        conn.register_object(PATH, node.interfaces[0], call, prop, None)  # noqa: the deprecated form is the one PyGObject wraps
        conn.connect("closed", lambda *a: loop.quit())

    Gio.bus_own_name(Gio.BusType.SESSION, NAME, Gio.BusNameOwnerFlags.NONE, bus, acquired,
                     lambda *a: loop.quit())
    loop.run()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    serve(sys.argv[1])
