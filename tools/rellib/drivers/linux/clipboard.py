#!/usr/bin/env python3
"""The clipboard of a sandbox's own Xvfb: what the app copied (Copy link, Copy message), read the way
another app on that display reads it, and set there for the app's Paste.

    clipboard.py <sandbox> get         prints the CLIPBOARD text (nothing when empty)
    clipboard.py <sandbox> set         owns the CLIPBOARD with <text> (stdin) until stopped (or 10 min)

Only on the sandbox's display (sandbox.guard refuses anything else). The driver calls read(sb),
write(sb, text) and clear(sb); nothing it reads is logged here."""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sandbox  # noqa: E402

HOLD_S = 600


def _env(sb):
    env = sandbox.read_env(sb)
    sandbox.guard(sb, env)
    env["NO_AT_BRIDGE"] = "1"
    return env


def read(sb, timeout=15):
    """The CLIPBOARD text on the sandbox's display, '' when empty."""
    r = subprocess.run([sys.executable, "-I", os.path.abspath(__file__), sb, "get"], env=_env(sb),
                       capture_output=True, text=True, timeout=timeout)
    if r.returncode:
        raise RuntimeError("clipboard read failed: %s" % (r.stderr.strip().splitlines() or ["?"])[-1])
    return r.stdout


def write(sb, text):
    """Owns the CLIPBOARD on the sandbox's display with [text] (a process that stays until replaced)."""
    stop(sb)
    p = subprocess.Popen([sys.executable, "-I", os.path.abspath(__file__), sb, "set"], env=_env(sb),
                         stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    p.stdin.write(text)
    p.stdin.close()
    p.stdout.readline()  # "ok" once it owns the selection
    with open(os.path.join(sb, "clipboard.pid"), "w") as f:
        f.write(str(p.pid))


def stop(sb):
    pidf = os.path.join(sb, "clipboard.pid")
    try:
        pid = int(open(pidf).read().strip())
        os.unlink(pidf)
        os.kill(pid, 15)
    except (OSError, ValueError):
        pass


def clear(sb):
    write(sb, "")
    stop(sb)


def _main(argv):
    sb, what = argv[1], argv[2]
    sandbox.guard(sb, dict(os.environ))
    import gi
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gdk, GLib, Gtk
    cb = Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
    if what == "get":
        sys.stdout.write(cb.wait_for_text() or "")
        return 0
    text = sys.stdin.read()
    cb.set_text(text, -1)
    cb.store()
    print("ok", flush=True)
    GLib.timeout_add_seconds(HOLD_S, Gtk.main_quit)
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
