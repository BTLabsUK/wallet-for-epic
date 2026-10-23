#!/usr/bin/env python3
"""Exports the product wordmark as SVG (text as paths) and PNG, the same layout as
`BrandWordmark` in app/lib/src/ui/theme/brand.dart: "Epic Cash" in Montserrat SemiBold at size
S with -0.02 em tracking, filled with the mark's gold gradient (#F6D471 to #C98A3E); under it
the platform word, uppercase, at S/2 with +0.14 em tracking, in grey, aligned to the right
edge of "Epic Cash". The lockup puts the mark (docs/themes/epic-mark.svg) to the left.

Output, in docs/themes/wordmark/ (run from anywhere):
  epic-cash-{desktop,mobile}.svg            the wordmark for dark backgrounds (transparent)
  epic-cash-{desktop,mobile}-light.svg      for light backgrounds: the AA brown and dark grey
  epic-cash-{desktop,mobile}-lockup.svg     mark + wordmark, dark backgrounds
  epic-cash-{desktop,mobile}-lockup-light.svg
  *.png                                     each SVG at 2048 px wide, transparent, plus
  epic-cash-{desktop,mobile}-lockup-black.png  the lockup on #08080A with a margin (stores)

Needs fonttools and uharfbuzz (shaping with the font's kerning), and for the PNGs a Chromium:
`WORDMARK_PY` may point at a Python with Playwright; without one the PNGs are skipped.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / 'app/assets/fonts/Montserrat-SemiBold.ttf'
MARK = ROOT / 'docs/themes/epic-mark.svg'
OUT = ROOT / 'docs/themes/wordmark'

S = 100.0  # "Epic Cash" font size in SVG units
SECOND_RATIO, GAP_RATIO, LINE = 0.5, 0.12, 1.1
TRACK_FIRST, TRACK_SECOND = -0.02, 0.14
GOLD, GOLD_DEEP, GREY = '#F6D471', '#C98A3E', '#A4A4AD'
BROWN, GREY_LIGHT = '#8F5E1F', '#55555F'
BLACK = '#08080A'

VARIANTS = {'desktop': 'Desktop', 'mobile': 'Mobile'}


def shape(text: str, size: float, tracking: float):
    """Glyph ids, x positions and the run's width, in SVG units, with the font's kerning."""
    import uharfbuzz as hb

    blob = hb.Blob.from_file_path(str(FONT))
    face = hb.Face(blob)
    font = hb.Font(face)
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(font, buf)
    upem = face.upem
    k = size / upem
    track = tracking * size
    x = 0.0
    runs = []
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        runs.append((info.codepoint, x + pos.x_offset * k, -pos.y_offset * k))
        x += pos.x_advance * k + track
    width = x - track  # no tracking after the last glyph
    return runs, width


def glyph_paths(size: float, runs, baseline: float, x0: float) -> str:
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont

    ttf = TTFont(str(FONT))
    glyph_set = ttf.getGlyphSet()
    order = ttf.getGlyphOrder()
    k = size / ttf['head'].unitsPerEm
    parts = []
    for gid, x, y in runs:
        pen = SVGPathPen(glyph_set)
        tpen = TransformPen(pen, (k, 0, 0, -k, x0 + x, baseline + y))
        glyph_set[order[gid]].draw(tpen)
        d = pen.getCommands()
        if d:
            parts.append(d)
    return ' '.join(parts)


def metrics():
    from fontTools.ttLib import TTFont

    ttf = TTFont(str(FONT))
    upem = ttf['head'].unitsPerEm
    return ttf['hhea'].ascent / upem, -ttf['hhea'].descent / upem


def baseline_in_box(size: float, box: float, ascent: float, descent: float) -> float:
    """Where Flutter puts the baseline of a line with `height: LINE`: the glyph box centred."""
    glyph_box = (ascent + descent) * size
    return (box - glyph_box) / 2 + ascent * size


def wordmark(word: str, first: tuple[str, str] | str, second: str):
    """The wordmark's SVG body and its size. [first] is a gradient pair or a flat colour."""
    asc, desc = metrics()
    s2 = S * SECOND_RATIO
    box1, box2, gap = S * LINE, s2 * LINE, S * GAP_RATIO
    runs1, w1 = shape('Epic Cash', S, TRACK_FIRST)
    runs2, w2 = shape(word.upper(), s2, TRACK_SECOND)
    width = max(w1, w2)
    height = box1 + gap + box2
    b1 = baseline_in_box(S, box1, asc, desc)
    b2 = box1 + gap + baseline_in_box(s2, box2, asc, desc)
    d1 = glyph_paths(S, runs1, b1, width - w1)
    d2 = glyph_paths(s2, runs2, b2, width - w2)
    if isinstance(first, tuple):
        defs = (f'<linearGradient id="g" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="{box1:.1f}">'
                f'<stop offset="0" stop-color="{first[0]}"/><stop offset="1" stop-color="{first[1]}"/></linearGradient>')
        fill1 = 'url(#g)'
    else:
        defs, fill1 = '', first
    body = f'<path fill="{fill1}" d="{d1}"/><path fill="{second}" d="{d2}"/>'
    return defs, body, width, height


def mark_paths() -> tuple[str, float, float]:
    svg = MARK.read_text()
    vb = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', svg)
    w, h = float(vb[1]), float(vb[2])
    paths = ''.join(re.findall(r'<path[^>]*/>', svg))
    return paths, w, h


def svg_doc(defs: str, body: str, width: float, height: float, label: str, bg: str | None = None, pad: float = 0) -> str:
    w, h = width + 2 * pad, height + 2 * pad
    rect = f'<rect width="{w:.1f}" height="{h:.1f}" fill="{bg}"/>' if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.1f} {h:.1f}" width="{w:.1f}" height="{h:.1f}" '
            f'role="img" aria-label="{label}">'
            f'<title>{label}</title><defs>{defs}</defs>{rect}<g transform="translate({pad:.1f} {pad:.1f})">{body}</g></svg>\n')


def lockup(word: str, first, second, mark_fill):
    """The mark at the wordmark's height, a gap of a third of it, then the wordmark."""
    defs, body, w, h = wordmark(word, first, second)
    paths, mw, mh = mark_paths()
    # The mark's height is the wordmark's height / 0.6 (BrandLockup: text = 0.6 of the mark),
    # clipped so the mark never dwarfs the text: its height equals the wordmark's.
    mark_h = h
    k = mark_h / mh
    mark_w = mw * k
    gap = mark_h * 0.34
    if isinstance(mark_fill, tuple):
        defs += (f'<linearGradient id="m" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="{mark_h:.1f}">'
                 f'<stop offset="0" stop-color="{mark_fill[0]}"/><stop offset="1" stop-color="{mark_fill[1]}"/></linearGradient>')
        mf = 'url(#m)'
    else:
        mf = mark_fill
    mark = f'<g fill="{mf}" transform="scale({k:.5f})">{paths}</g>'
    text = f'<g transform="translate({mark_w + gap:.1f} 0)">{body}</g>'
    return defs, mark + text, mark_w + gap + w, h


def write_pngs(svgs: list[Path]) -> list[Path]:
    py = os.environ.get('WORDMARK_PY') or os.path.expanduser('python3')
    if not Path(py).exists():
        print('no Playwright python: PNGs skipped (set WORDMARK_PY)', file=sys.stderr)
        return []
    script = r'''
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright
W = 2048
with sync_playwright() as p:
    b = p.chromium.launch()
    for arg in sys.argv[1:]:
        svg = Path(arg)
        text = svg.read_text()
        import re
        vb = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', text)
        w, h = float(vb[1]), float(vb[2])
        H = round(W * h / w)
        page = b.new_page(viewport={'width': W, 'height': H}, device_scale_factor=1)
        page.set_content('<html><body style="margin:0;background:transparent">' + text.replace(f'width="{vb[1]}" height="{vb[2]}"', f'width="{W}" height="{H}"') + '</body></html>')
        page.screenshot(path=str(svg.with_suffix('.png')), omit_background=True, clip={'x': 0, 'y': 0, 'width': W, 'height': H})
        page.close()
    b.close()
'''
    out = []
    subprocess.run([py, '-I', '-c', script, *map(str, svgs)], check=True)
    for s in svgs:
        out.append(s.with_suffix('.png'))
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for key, word in VARIANTS.items():
        label = f'Epic Cash {word}'
        for suffix, first, second, mark_fill, bg, pad in [
            ('', (GOLD, GOLD_DEEP), GREY, (GOLD, GOLD_DEEP), None, 0),
            ('-light', BROWN, GREY_LIGHT, BROWN, None, 0),
        ]:
            defs, body, w, h = wordmark(word, first, second)
            p = OUT / f'epic-cash-{key}{suffix}.svg'
            p.write_text(svg_doc(defs, body, w, h, label))
            written.append(p)
            defs, body, w, h = lockup(word, first, second, mark_fill)
            p = OUT / f'epic-cash-{key}-lockup{suffix}.svg'
            p.write_text(svg_doc(defs, body, w, h, label))
            written.append(p)
        # The store and website version: the lockup on brand black, a margin of half its height.
        defs, body, w, h = lockup(word, (GOLD, GOLD_DEEP), GREY, (GOLD, GOLD_DEEP))
        p = OUT / f'epic-cash-{key}-lockup-black.svg'
        p.write_text(svg_doc(defs, body, w, h, label, bg=BLACK, pad=h / 2))
        written.append(p)
    pngs = write_pngs(written)
    for p in written + pngs:
        print(p.relative_to(ROOT))


if __name__ == '__main__':
    main()
