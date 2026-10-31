# SPDX-License-Identifier: Apache-2.0
"""G4 update trust: the curated screens of the real installed releases, for the release's screen catalogue.

Each trust driver leaves in REL_OUT/screens/ one PNG per key point of the candidate after the update
(after-<point>.png) and, where the flow already passes them, the same points on the previous release
(before-<point>.png), plus screens.json:

  {"platform": "linux|android|windows", "variant": "tor|notor", "previous": "<ver>", "candidate": "<ver>",
   "shots": [{"code": "after-home", "file": "after-home.png", "phase": "before|after", "point": "home",
              "version": "<ver>", "taken": "<iso time>", "note": "..."}],
   "missing": [{"code": "...", "reason": "..."}]}

Best effort only: a capture that fails is logged and listed under "missing"; it never raises, never
changes a check and never waits. The shots are taken at moments the flow already stands on those
screens (the digests), never on a recovery phrase, PIN entry or a typed password; the drivers' own
guards decide that before calling take(). REL_OUT/shots/ stays the drivers' debug folder.
"""
import datetime
import json
import os

POINTS = ("wallets", "home", "history", "settings-node", "settings-epicbox")
PHASES = ("before", "after")


class Screens:
    def __init__(self, out, platform, variant, previous, candidate, log):
        self.dir = os.path.join(out, "screens")
        self.head = {"platform": platform, "variant": variant, "previous": previous, "candidate": candidate}
        self.log = log
        self.shots = {}    # code -> entry
        self.missing = {}  # code -> reason

    def take(self, phase, point, capture, note=""):
        """capture(path) writes a PNG to path. True when the shot is kept; never raises."""
        code = "%s-%s" % (phase, point)
        try:
            if phase not in PHASES or point not in POINTS:
                raise ValueError("not a catalogue point")
            os.makedirs(self.dir, exist_ok=True)
            path = os.path.join(self.dir, code + ".png")
            tmp = os.path.join(self.dir, code + ".part.png")  # the extension tells ImageMagick the format
            capture(tmp)
            with open(tmp, "rb") as f:
                if f.read(8) != b"\x89PNG\r\n\x1a\n":
                    raise ValueError("the capture is not a PNG")
            os.replace(tmp, path)
            self.shots[code] = {"code": code, "file": code + ".png", "phase": phase, "point": point,
                                "version": self.head["previous" if phase == "before" else "candidate"],
                                "taken": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
                                "note": note}
            self.missing.pop(code, None)
            ok = True
        except Exception as e:  # noqa: BLE001
            self.log("screen %s not taken: %s" % (code, e))
            try:
                os.unlink(os.path.join(self.dir, code + ".part.png"))
            except OSError:
                pass
            if code not in self.shots:
                self.missing[code] = "capture failed: %s" % str(e)[:200]
            ok = False
        self.write()
        return ok

    def miss(self, code, reason):
        """A point this run cannot or will not capture (kept only when no shot of it exists)."""
        if code not in self.shots:
            self.missing[code] = reason
            self.write()

    def finish(self, why_not_reached="not reached: the run stopped before this point"):
        """Every point of both phases is now a shot or listed as missing; screens.json written."""
        for phase in PHASES:
            for point in POINTS:
                code = "%s-%s" % (phase, point)
                if code not in self.shots and code not in self.missing:
                    self.missing[code] = why_not_reached
        self.write()

    def write(self):
        try:
            os.makedirs(self.dir, exist_ok=True)
            order = {"%s-%s" % (ph, pt): i for i, (ph, pt) in enumerate((ph, pt) for ph in PHASES for pt in POINTS)}
            doc = dict(self.head,
                       shots=sorted(self.shots.values(), key=lambda s: order.get(s["code"], 99)),
                       missing=[{"code": c, "reason": r} for c, r in sorted(self.missing.items(), key=lambda x: order.get(x[0], 99))])
            tmp = os.path.join(self.dir, "screens.json.tmp")
            with open(tmp, "w") as f:
                json.dump(doc, f, indent=2, ensure_ascii=False)
                f.write("\n")
            os.replace(tmp, os.path.join(self.dir, "screens.json"))
        except Exception as e:  # noqa: BLE001
            self.log("screens.json not written: %s" % e)
