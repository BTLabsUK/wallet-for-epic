#!/usr/bin/env python3
"""Small uiautomator driver for Epic Cash Mobile on an emulator (Flutter puts labels in
content-desc, so uiautomator sees them).

ph.py <serial> dump                 masked list of labelled / clickable nodes
ph.py <serial> tap TEXT [N]         tap the Nth node whose label contains TEXT (in Python, TEXT
                                    can also be a tuple of texts: any one matches)
ph.py <serial> wait TEXT [SECS]     wait until a label contains TEXT
ph.py <serial> type TEXT            type in 10-character chunks (adb drops long strings)
ph.py <serial> key CODE | xy X Y | shot PATH | launch | ver

Masking: EditText text, labels holding any of the words given to secret_words(), 'Word N: x'
cells, numbered word lists and labels of 12+ lowercase words (a phrase) print as ***.
"""
import html, os, re, subprocess, sys, time

PKG = "uk.btlabs.epiccash.mobile"
ADB = os.environ.get("ADB", os.path.expanduser("~/Android/Sdk/platform-tools/adb"))
_SECRET_WORDS = set()


def secret_words(words):
    """Labels holding three or more of these words are never printed."""
    _SECRET_WORDS.update(w.lower() for w in words)


def adb(serial, *args, capture=True, timeout=120):
    r = subprocess.run([ADB, "-s", serial, *args], capture_output=capture, text=True,
                       timeout=timeout, errors="replace")
    return r.stdout if capture else ""


def mask(label, cls=""):
    if "EditText" in cls and label:
        return "***"
    if re.search(r"\bWord \d+\b", label):
        return "Word ***"
    words = re.findall(r"\b[a-z]+\b", label)
    if _SECRET_WORDS and sum(w in _SECRET_WORDS for w in set(words)) >= 3:
        return "*** (masked)"
    if len(re.findall(r"(?:^|\|)\s*\d+\s*[:.)]?\s+[a-z]+\b", label)) >= 3:
        return "*** (masked numbered words)"
    if len(words) >= 12 and len(words) >= 0.9 * len(label.split()):
        return "*** (masked phrase-like text)"
    return label


def nodes(serial):
    x = ""
    for _ in range(4):
        adb(serial, "shell", "uiautomator", "dump", "/sdcard/ui.xml")
        x = adb(serial, "exec-out", "cat", "/sdcard/ui.xml")
        if "<node" in x:
            break
        time.sleep(1)
    out = []
    for m in re.finditer(r"<node [^>]*>", x):
        n = m.group(0)
        g = lambda k: (re.search(" " + k + r'="([^"]*)"', n) or [None, ""])[1]
        label = html.unescape(g("text") or g("content-desc")).replace("\n", " | ")
        cls = g("class")
        clickable = g("clickable") == "true"
        if not (label or clickable or cls.endswith("EditText")):
            continue
        b = [int(v) for v in re.findall(r"\d+", g("bounds"))]
        out.append(dict(label=label, cls=cls, clickable=clickable,
                        checked=g("checked") == "true", bounds=b,
                        center=((b[0] + b[2]) // 2, (b[1] + b[3]) // 2) if len(b) == 4 else None))
    return out


def show(ns, out=sys.stdout):
    for n in ns:
        flags = ("[C]" if n["clickable"] else "") + ("[E]" if "EditText" in n["cls"] else "") + ("[X]" if n["checked"] else "")
        print(n["bounds"], flags, mask(n["label"], n["cls"])[:160], file=out)


def matches(label, text, exact=False):
    """[text] is one text or a tuple of them (a label's words in the previous release and the
    candidate): any one matches."""
    texts = (text,) if isinstance(text, str) else tuple(text)
    return any(label == t if exact else t in label for t in texts)


def find(serial, text, nth=1, exact=False, clickable=None, ns=None):
    ns = nodes(serial) if ns is None else ns
    hits = [n for n in ns if matches(n["label"], text, exact)
            and (clickable is None or n["clickable"] == clickable)]
    return hits[nth - 1] if len(hits) >= nth else None


def tap_xy(serial, xy):
    adb(serial, "shell", "input", "tap", *map(str, xy))


def tap_bar(serial, xy):
    """Tap something low on the screen (tab bar, foot buttons): keyboard down first."""
    hide_keyboard(serial)
    tap_xy(serial, xy)


def tap(serial, text, nth=1, exact=False, clickable=None):
    n = find(serial, text, nth, exact, clickable)
    if not n:
        raise LookupError(f"not on screen: {text}")
    tap_xy(serial, n["center"])
    return n


def wait(serial, text, secs=60, exact=False, clickable=None):
    end = time.time() + secs
    while time.time() < end:
        n = find(serial, text, 1, exact, clickable)
        if n:
            return n
        time.sleep(2)
    return None


def type_text(serial, s):
    for i in range(0, len(s), 10):
        chunk = s[i:i + 10].replace(" ", "%s")
        adb(serial, "shell", "input", "text", chunk)


def key(serial, code):
    adb(serial, "shell", "input", "keyevent", str(code))


def keyboard_shown(serial):
    return "mInputShown=true" in adb(serial, "shell", "dumpsys", "input_method")


def hide_keyboard(serial):
    """The soft keyboard covers the tab bar and is not in the uiautomator dump."""
    for _ in range(2):  # Back with the keyboard up only closes the keyboard
        if not keyboard_shown(serial):
            return
        key(serial, 4)
        time.sleep(0.8)


def swipe_up(serial):
    adb(serial, "shell", "input", "swipe", "540", "1800", "540", "800", "400")


def version(serial):
    d = adb(serial, "shell", "dumpsys", "package", PKG)
    vn = re.search(r"versionName=(\S+)", d)
    vc = re.search(r"versionCode=(\d+)", d)
    return (vn.group(1) if vn else None, vc.group(1) if vc else None)


def launch(serial):
    adb(serial, "shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")


def shot(serial, path):
    with open(path, "wb") as f:
        f.write(subprocess.run([ADB, "-s", serial, "exec-out", "screencap", "-p"],
                               capture_output=True, timeout=60).stdout)
    return path


if __name__ == "__main__":
    s, cmd, *a = sys.argv[1:]
    if cmd == "dump":
        show(nodes(s))
    elif cmd == "tap":
        n = tap(s, a[0], int(a[1]) if len(a) > 1 else 1)
        print("tapped", mask(n["label"], n["cls"])[:80], n["bounds"])
    elif cmd == "wait":
        n = wait(s, a[0], int(a[1]) if len(a) > 1 else 60)
        print("found" if n else "TIMEOUT", a[0])
        sys.exit(0 if n else 1)
    elif cmd == "type":
        type_text(s, a[0])
    elif cmd == "key":
        key(s, a[0])
    elif cmd == "xy":
        tap_xy(s, (a[0], a[1]))
    elif cmd == "shot":
        print(shot(s, a[0]))
    elif cmd == "launch":
        launch(s)
    elif cmd == "ver":
        print(*version(s))
