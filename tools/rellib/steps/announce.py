#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Step `announce` of tools/rel, after G6: the draft of the release's Telegram post, which the
release lead wrote by hand up to 26.10.23 (telegram-<version>.txt in the staged folders). It is
made from the version's changelog entry on the releases page (the page repository's
site/epic-cash/changelog/index.html, section id="v<version>", which publish-page already
requires): its first paragraph, then its list items as bullets, then the download and changelog
links. When the Android app id changed since the previous release (applicationId in
app/android/app/build.gradle.kts at REL_PREVIOUS_REF and REL_COMMIT, in REL_SRC), the old app
gets no update, so the first paragraph gives way to the per-platform update line (ANDROID_NEW_APP)
unless it already speaks of Android, and the step says so on stderr. Written to <stage>/announce.txt and sent to the owner once as a relmsg notice
(<stage>/notice.json, tools/rellib/engine.py forward_messages), to edit and post. Nothing is
posted anywhere by this step. Never holds the release (warn_only in release/pipeline.toml).

Usage: announce.py <version> <page repo> <stage dir>"""
import html.parser
import json
import os
import re
import subprocess
import sys

PAGE = "https://epiccash.btlabs.uk/releases/"
MAX_BULLETS = 8
APP = "BT Wallet"
GRADLE = "app/android/app/build.gradle.kts"
ANDROID_NEW_APP = (f"Windows and Linux: the app offers this update by itself; wallets, history and settings are kept. "
                   f"Android: this version is a new app ({APP}) and does not update the old one. Install it, then restore "
                   "your wallet with its recovery phrase; settings, contacts and notes do not carry over. The old app "
                   "keeps working and gets no more updates.")


class Entry(html.parser.HTMLParser):
    """The text of <section id="v<version>">: its paragraphs and its list items, in order."""

    def __init__(self, version):
        super().__init__(convert_charrefs=True)
        self.want = f"v{version}"
        self.depth = 0          # section nesting while inside the entry
        self.cur = None         # ("p" | "li", [text])
        self.items = []

    def handle_starttag(self, tag, attrs):
        if self.depth:
            if tag == "section":
                self.depth += 1
            elif tag in ("p", "li") and self.cur is None:
                cls = dict(attrs).get("class") or ""
                self.cur = ("for" if "for" in cls.split() else tag, [])
        elif tag == "section" and dict(attrs).get("id") == self.want:
            self.depth = 1

    def handle_endtag(self, tag):
        if not self.depth:
            return
        if tag == "section":
            self.depth -= 1
        elif self.cur is not None and tag in ("p", "li"):
            text = " ".join("".join(self.cur[1]).split())
            if text:
                self.items.append((self.cur[0], text))
            self.cur = None

    def handle_data(self, data):
        if self.depth and self.cur is not None:
            self.cur[1].append(data)


def android_id(src, ref):
    """applicationId in the Android build at <ref>; None when it cannot be read."""
    r = subprocess.run(["git", "-C", src, "show", f"{ref}:{GRADLE}"], capture_output=True, text=True)
    m = re.search(r'applicationId\s*=\s*"([^"]+)"', r.stdout) if r.returncode == 0 else None
    return m.group(1) if m else None


def android_id_changed():
    """(previous id, new id) when the Android app id changed since the previous release, else None."""
    src, prev, cur = os.environ.get("REL_SRC") or ".", os.environ.get("REL_PREVIOUS_REF"), os.environ.get("REL_COMMIT")
    if not prev or not cur:
        return None
    old, new = android_id(src, prev), android_id(src, cur)
    return (old, new) if old and new and old != new else None


def draft(version, changelog_html, new_app=None):
    p = Entry(version)
    p.feed(changelog_html)
    if not p.items:
        raise SystemExit(f"announce: the changelog has no entry id=\"v{version}\"")
    paras = [t for k, t in p.items if k == "p"]
    bullets = [t for k, t in p.items if k == "li"]
    lines = [f"{APP} {version} is out.", ""]
    first = paras[0] if paras else None
    if new_app and (first is None or "Android" not in first):
        print(f"announce: the Android app id changed ({new_app[0]} → {new_app[1]}) and the changelog's first "
              "paragraph does not speak of Android: the draft states the per-platform update line", file=sys.stderr)
        first = ANDROID_NEW_APP
    if first:
        lines += [first, ""]
    for b in bullets[:MAX_BULLETS]:
        lines.append(f"• {b if len(b) <= 220 else b[:217].rstrip() + '…'}")
    if len(bullets) > MAX_BULLETS:
        lines.append(f"• …and {len(bullets) - MAX_BULLETS} more in the changelog.")
    lines += ["", f"Download: {PAGE}", f"Changelog: {PAGE}changelog/#v{version}"]
    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) != 4:
        raise SystemExit(__doc__.strip().splitlines()[-1])
    version, site, stage = sys.argv[1:]
    log = os.path.join(os.path.expanduser(site), "site/epic-cash/changelog/index.html")
    with open(log, encoding="utf-8") as f:
        text = draft(version, f.read(), android_id_changed())
    os.makedirs(stage, exist_ok=True)
    with open(os.path.join(stage, "announce.txt"), "w", encoding="utf-8") as f:
        f.write(text)
    with open(os.path.join(stage, "notice.json"), "w", encoding="utf-8") as f:
        test = "TEST run, not released: " if os.environ.get("REL_TEST") == "1" else ""
        json.dump({"title": f"{test}{APP} {version}: draft Telegram post", "detail": text[:3000],
                   "expects": "edit and post it yourself; nothing was posted"}, f, ensure_ascii=False)
    print(text, end="")


if __name__ == "__main__":
    main()
