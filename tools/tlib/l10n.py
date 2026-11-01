# SPDX-License-Identifier: Apache-2.0
"""The app's strings: keeps every translation at the English template's keys (tools/l10n).

Where strings live (app/README.md, "Languages"):
  app/lib/l10n/app_en.arb                      the template: every key, with its description
  app/lib/l10n/app_<lang>.arb                  each translation
  app/lib/l10n/desk/<part>.json                the desktop's English (`desk*` keys), and
  app/lib/l10n/desk/<part>.<lang>.json         its translations (key: text only)
  app/lib/l10n/desk_invoices/<part>[.<lang>].json   the same for the invoice screens (`deskInv*`)
  app/lib/l10n/untranslated.json               {lang: [keys]} still in English, to translate

sync:
  1. every desk fragment translation gets the keys of its English part (missing ones as the
     English text) and loses the keys its part no longer has; a translation of a part that is
     gone is deleted;
  2. the fragments are merged into the ARB files in place (a key keeps its place, a new one is
     appended; a `desk*` key with no fragment is dropped, a `deskInv*` key without one stays:
     a few were added to the ARB files directly);
  3. every app_<lang>.arb gets the template's missing keys (as the English text) and loses keys
     the template does not have;
  4. untranslated.json lists every key filled with English that is still the English text;
  5. `flutter gen-l10n` writes app_localizations*.dart.
It changes no translated text. What is left for a person (keys to translate, placeholders that
differ from the English) is printed with the file to edit.
"""
import json
import os
import re
import subprocess

L10N = os.path.join("app", "lib", "l10n")
UNTRANSLATED = "untranslated.json"


def owns_desk(key):
    return key.startswith("desk") and not key.startswith("deskInv")


def owns_inv(key):
    return key.startswith("deskInv")


# (folder, owns a key, drops an owned key no fragment has)
GROUPS = (("desk", owns_desk, True), ("desk_invoices", owns_inv, False))


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def dump(path, data):
    text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    try:
        with open(path, encoding="utf-8") as f:
            if f.read() == text:
                return False
    except OSError:
        pass
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    return True


def messages(data):
    return {k: v for k, v in data.items() if not k.startswith("@")}


class Strings:
    """The string files of one checkout (`root` is the repository)."""

    def __init__(self, root):
        self.dir = os.path.join(root, L10N)
        self.locales = sorted(n[len("app_"):-len(".arb")] for n in os.listdir(self.dir)
                              if n.startswith("app_") and n.endswith(".arb") and n != "app_en.arb")

    def arb(self, locale):
        return os.path.join(self.dir, f"app_{locale}.arb")

    def parts(self, folder):
        d = os.path.join(self.dir, folder)
        if not os.path.isdir(d):
            return []
        return sorted(n[:-len(".json")] for n in os.listdir(d) if n.endswith(".json") and n.count(".") == 1)

    def fragment(self, folder, part, locale=None):
        return os.path.join(self.dir, folder, f"{part}.json" if locale is None else f"{part}.{locale}.json")

    def where(self, key, locale):
        """The file a person edits to translate `key` into `locale`, relative to app/."""
        for folder, owns, _ in GROUPS:
            if owns(key):
                for part in self.parts(folder):
                    if key in load(self.fragment(folder, part)):
                        return f"lib/l10n/{folder}/{part}.{locale}.json"
        return f"lib/l10n/app_{locale}.arb"

    # -- step 1
    def sync_fragments(self, arbs, filled, removed):
        for folder, owns, _ in GROUPS:
            parts = self.parts(folder)
            for part in parts:
                english = messages(load(self.fragment(folder, part)))
                for locale in self.locales:
                    path = self.fragment(folder, part, locale)
                    tr = load(path) if os.path.exists(path) else {}
                    out = {}
                    for k, v in tr.items():
                        if k.startswith("@") or k in english:
                            out[k] = v
                        else:
                            removed.setdefault(locale, []).append(k)
                    for k, v in english.items():
                        if k not in out:
                            # a translation written straight into the ARB file moves into the fragment
                            have = arbs.get(locale, {}).get(k)
                            if isinstance(have, str) and have != v:
                                out[k] = have
                            else:
                                out[k] = v
                                filled.setdefault(locale, []).append(k)
                    dump(path, out)
            d = os.path.join(self.dir, folder)
            if os.path.isdir(d):
                for n in sorted(os.listdir(d)):
                    stem = n.split(".")[0]
                    if n.endswith(".json") and n.count(".") == 2 and stem not in parts:
                        os.remove(os.path.join(d, n))
                        removed.setdefault(n.split(".")[1], []).append(f"{folder}/{n} (its part is gone)")

    # -- step 2 (was app/tool/desk_l10n.py)
    def merge_fragments(self, arbs):
        for folder, owns, drop in GROUPS:
            parts = self.parts(folder)
            english = {}
            for part in parts:
                for key, value in load(self.fragment(folder, part)).items():
                    if not owns(key.lstrip("@")):
                        raise ValueError(f"{folder}/{part}.json: {key} does not belong in {folder}/")
                    if key in english:
                        raise ValueError(f"{folder}/{part}.json: {key} is also in another part")
                    english[key] = value
            for locale, data in arbs.items():
                if locale == "en":
                    wanted = dict(english)
                else:
                    wanted = {}
                    for part in parts:
                        path = self.fragment(folder, part, locale)
                        if os.path.exists(path):
                            for key, value in load(path).items():
                                if not key.startswith("@") and key in english:
                                    wanted[key] = value
                out = {}
                for key, value in data.items():
                    if not owns(key.lstrip("@")):
                        out[key] = value
                    elif key in wanted:
                        out[key] = wanted.pop(key)
                    elif not drop:
                        out[key] = value
                out.update(wanted)
                arbs[locale] = out

    # -- step 3
    @staticmethod
    def sync_arb(data, template, filled, removed):
        out = {}
        for k, v in data.items():
            if k == "@@locale" or (k.startswith("@") and k[1:] in template) or k in template:
                out[k] = v
            elif not k.startswith("@"):
                removed.append(k)
        for k, v in template.items():
            if k not in out:
                out[k] = v
                filled.append(k)
        return out

    def sync(self, gen=True, env=None):
        """Runs steps 1-5; returns the report (see report_lines)."""
        filled, removed = {}, {}
        arbs = {"en": load(self.arb("en"))}
        arbs.update({loc: load(self.arb(loc)) for loc in self.locales})
        self.sync_fragments(arbs, filled, removed)
        self.merge_fragments(arbs)
        template = messages(arbs["en"])
        for loc in self.locales:
            f, r = [], []
            arbs[loc] = self.sync_arb(arbs[loc], template, f, r)
            filled.setdefault(loc, []).extend(f)
            removed.setdefault(loc, []).extend(r)
        changed = [loc for loc in arbs if dump(self.arb(loc), arbs[loc])]
        untranslated = self.sync_untranslated(arbs, filled)
        if gen:
            subprocess.run(["flutter", "gen-l10n"], cwd=os.path.dirname(os.path.dirname(self.dir)),
                           env=env, check=True, stdout=subprocess.DEVNULL)
        return {"filled": filled, "removed": removed, "changed": changed, "untranslated": untranslated,
                "placeholders": self.placeholder_problems(arbs)}

    # -- step 4
    def sync_untranslated(self, arbs, filled):
        path = os.path.join(self.dir, UNTRANSLATED)
        old = load(path) if os.path.exists(path) else {}
        english = messages(arbs["en"])
        out = {}
        for loc in self.locales:
            tr = messages(arbs[loc])
            keys = set(old.get(loc, [])) | set(filled.get(loc, []))
            out[loc] = sorted(k for k in keys if k in english and tr.get(k) == english[k])
        dump(path, out)
        return out

    def placeholder_problems(self, arbs=None):
        arbs = arbs or {loc: load(self.arb(loc)) for loc in ["en", *self.locales]}
        english = messages(arbs["en"])
        out = []
        for loc in self.locales:
            for k, v in messages(arbs[loc]).items():
                if k not in english or not isinstance(v, str):
                    continue
                try:
                    have, want = placeholders(v), placeholders(english[k])
                except ValueError as e:
                    out.append((loc, k, f"not valid ICU: {e}"))
                    continue
                if have != want:
                    out.append((loc, k, f"placeholders {sorted(have)}, the English has {sorted(want)}"))
        return out

    def check(self):
        """What sync would change, and what is left for a person, without writing."""
        arbs = {"en": load(self.arb("en"))}
        arbs.update({loc: load(self.arb(loc)) for loc in self.locales})
        english = messages(arbs["en"])
        missing = {loc: sorted(set(english) - set(messages(arbs[loc]))) for loc in self.locales}
        extra = {loc: sorted(set(messages(arbs[loc])) - set(english)) for loc in self.locales}
        path = os.path.join(self.dir, UNTRANSLATED)
        listed = load(path) if os.path.exists(path) else {}
        untranslated = {loc: [k for k in listed.get(loc, []) if messages(arbs[loc]).get(k) == english.get(k)]
                        for loc in self.locales}
        return {"missing": missing, "extra": extra, "untranslated": untranslated,
                "placeholders": self.placeholder_problems(arbs)}


def placeholders(message):
    """Placeholder names of an ICU message at any depth (as test/l10n_test.dart reads them)."""
    names = set()

    def argument(i):
        m = re.compile(r"\s*(\w+)\s*(?:,\s*(\w+)\s*,)?").match(message, i)
        if not m or not m.group(1):
            raise ValueError(f"bad argument at {i}")
        names.add(m.group(1))
        j = m.end()
        if m.group(2) is None:
            if j >= len(message) or message[j] != "}":
                raise ValueError(f"expected }} at {j}")
            return j + 1
        while True:
            s = re.compile(r"\s*(=?\w+)\s*\{").match(message, j)
            if not s:
                break
            j = branch(s.end())
        c = re.compile(r"\s*\}").match(message, j)
        if not c:
            raise ValueError(f"expected }} after branches at {j}")
        return c.end()

    def branch(i):
        while i < len(message):
            if message[i] == "{":
                i = argument(i + 1)
            elif message[i] == "}":
                return i + 1
            else:
                i += 1
        raise ValueError("unclosed branch")

    i = 0
    while i < len(message):
        if message[i] == "{":
            i = argument(i + 1)
        elif message[i] == "}":
            raise ValueError(f"unmatched }} at {i}")
        else:
            i += 1
    return names


def report_lines(strings, rep, limit=8):
    """Short lines for a person: what sync did and what is left."""
    out = []
    for loc in strings.locales:
        f, r = rep["filled"].get(loc, []), rep["removed"].get(loc, [])
        if f or r:
            out.append(f"{loc}: {len(f)} keys added (English for now), {len(r)} stale keys removed")
    left = [(loc, k) for loc, keys in rep["untranslated"].items() for k in keys]
    if left:
        out.append(f"to translate: {len(left)} (lib/l10n/{UNTRANSLATED}; l10n_quality_test fails until done)")
        for loc, k in left[:limit]:
            out.append(f"  {k} -> {strings.where(k, loc)}")
        if len(left) > limit:
            out.append(f"  … {len(left) - limit} more: tools/l10n check")
    for loc, k, why in rep["placeholders"][:limit]:
        out.append(f"fix by hand: {k} in {strings.where(k, loc)}: {why}")
    if len(rep["placeholders"]) > limit:
        out.append(f"  … {len(rep['placeholders']) - limit} more: tools/l10n check")
    return out
