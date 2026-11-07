# SPDX-License-Identifier: Apache-2.0
"""What may be a secret on a screen: a password field, a run of words that could be a recovery phrase.
Such a screen is never kept as a shot or a dump (core/driver.py)."""
import re

DESTRUCTIVE = re.compile(r"\b(delete|remove|erase|reset|wipe|forget|restore|uninstall|log ?out|sign ?out|send|pay|"
                         r"cancel (the )?(payment|send)|replace|clear|import|unlink|disconnect|"
                         r"confirm|approve|accept (the )?(invoice|payment|request)|sign|finali[sz]e|broadcast|"
                         r"withdraw|transfer|spend|"
                         r"(show|reveal|view|back ?up) (the |my )?(recovery )?(phrase|words|seed))\b", re.I)
ACTIONABLE = {"button", "link", "menu_item", "row", "tab", "checkbox", "toggle"}
PHRASE = re.compile(r"(\b[a-z]{3,8}\b[\s|,]+){11,}")  # 12+ short lower-case words in a row: maybe a recovery phrase
# A phrase shown one word per node: "Word 3: ghost" (phone), "3. ghost" / "3" + "ghost" (desktop grid)
WORD_CELL = re.compile(r"(word\s*)?\d{1,2}\s*[:.)]?\s*[a-z]{3,8}", re.I)
LONE_WORD = re.compile(r"[a-z]{3,8}")


def secret_screen(tree):
    return any("password" in n.states for n in tree) or phrase_screen(tree)


def phrase_screen(tree):
    """What may be a recovery phrase on the screen (a password field alone is not one): in the labels, or
    typed into fields (a restore screen's word fields, or the whole phrase pasted into one)."""
    cells = lone = vals = 0
    for n in tree:
        value = (n.value or "").strip().lower()
        if PHRASE.search(" ".join([n.name or "", n.value or ""]).lower()) or PHRASE.search(value + " "):
            return True
        name = (n.name or "").strip()
        cells += bool(WORD_CELL.fullmatch(name))
        lone += bool(LONE_WORD.fullmatch(name))
        vals += bool(LONE_WORD.fullmatch(value))
    return cells >= 3 or lone >= 6 or vals >= 6
