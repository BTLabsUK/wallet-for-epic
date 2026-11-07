# SPDX-License-Identifier: Apache-2.0
"""What a lane recovered from, for proof.json `recovered`, the release summary and a drafted fix to
the recipe (selector-fixes.md next to the proof). One per lane (lane.rec); Driver keeps it.

A recovery here is deterministic: a setting found by walking every Settings section instead of the
pages the recipe names (moved()). No model is asked.

phrase_screen and secret_screen live in secret.py; they are re-exported here for older importers."""
import json
import os
import time

from .secret import ACTIONABLE, DESTRUCTIVE, LONE_WORD, PHRASE, WORD_CELL, phrase_screen, secret_screen  # noqa: F401


class Recover:
    """One per lane. `out` the lane's output folder; `log` a function for the lane log."""

    def __init__(self, out, platform, build="", log=print):
        self.out, self.platform, self.build, self.log = out, platform, build, log
        self.used = []          # what proof.json lists as `recovered`

    def _record(self, kind, step, target, node, why, texts):
        e = {"kind": kind, "step": step, "target": getattr(target, "id", str(target)), "platform": self.platform,
             "build": self.build, "picked": {"role": node.role, "name": node.name, "id": node.id}, "why": why,
             "looked_for": texts, "at": time.strftime("%Y-%m-%dT%H:%M:%S")}
        self.used.append(e)
        try:
            with open(os.path.join(self.out, "recovered.json"), "w") as f:
                json.dump(self.used, f, indent=1)
            with open(os.path.join(self.out, "selector-fixes.md"), "a") as f:
                f.write("- `%s` (step %s, %s %s): not on Settings › %s; found under Settings › %s. Fix: name that page "
                        "for it in the recipe (core/desktop.py), or move the control back.\n" % (
                            e["target"], step, self.platform, self.build, " / ".join(texts) or "?", node.name))
        except OSError:
            pass
        self.log("RECOVERED (%s) step %s: %s → %s (%s)" % (kind, step, e["target"], node.brief(), why))
