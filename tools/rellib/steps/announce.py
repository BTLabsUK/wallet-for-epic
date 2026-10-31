#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Step `announce` of tools/rel, after G6: the draft of the release's Telegram post, which the
release lead wrote by hand up to 26.10.23 (telegram-<version>.txt in the staged folders). It is
made from the version's changelog entry on the releases page (the page repository's
site/epic-cash/changelog/index.html, section id="v<version>", which publish-page already
requires): its first paragraph, then its list items as bullets, then the download and changelog
links. Written to <stage>/announce.txt and sent to the owner once as a relmsg notice
(<stage>/notice.json, tools/rellib/engine.py forward_messages), to edit and post. Nothing is
posted anywhere by this step. Never holds the release (warn_only in release/pipeline.toml).

Usage: announce.py <version> <page repo> <stage dir>"""
import html.parser
import json
import os
import sys

PAGE = "https://epiccash.btlabs.uk/releases/"
MAX_BULLETS = 8


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


def draft(version, changelog_html):
    p = Entry(version)
    p.feed(changelog_html)
    if not p.items:
        raise SystemExit(f"announce: the changelog has no entry id=\"v{version}\"")
    paras = [t for k, t in p.items if k == "p"]
    bullets = [t for k, t in p.items if k == "li"]
    lines = [f"Epic Cash {version} is out.", ""]
    if paras:
        lines += [paras[0], ""]
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
        text = draft(version, f.read())
    os.makedirs(stage, exist_ok=True)
    with open(os.path.join(stage, "announce.txt"), "w", encoding="utf-8") as f:
        f.write(text)
    with open(os.path.join(stage, "notice.json"), "w", encoding="utf-8") as f:
        test = "TEST run, not released: " if os.environ.get("REL_TEST") == "1" else ""
        json.dump({"title": f"{test}Epic Cash {version}: draft Telegram post", "detail": text[:3000],
                   "expects": "edit and post it yourself; nothing was posted"}, f, ensure_ascii=False)
    print(text, end="")


if __name__ == "__main__":
    main()
