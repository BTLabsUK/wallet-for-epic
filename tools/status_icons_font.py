#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Builds app/assets/fonts/EpicStatusIcons.ttf from app/assets/icons/*.svg.

The status, method and trust glyphs ship as an icon font so they stay plain IconData (colour,
size and find.byIcon work as for any Material icon). Filled drawings (Tor, Epicbox, HTTP,
Link) are read as they are; stroked ones (the pairing trust shields and the lock: 24 px grid,
2 px round strokes, `stroke="currentColor"`) are outlined here first. Needs
fonttools and skia-pathops (pip install --target DIR fonttools skia-pathops; PYTHONPATH=DIR).
Run from the repo root; the code points are in app/lib/src/ui/status_icons.dart.
"""
import re, sys
from pathlib import Path
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.svgLib.path import parse_path
import pathops

ICONS = ['tor', 'epicbox', 'http', 'node', 'link',  # code points 0xE000 + index
         'trust-verified', 'trust-paired', 'trust-keys-changed', 'sealed']
UPM = 1024
S = UPM / 24.0

def rrect(x, y, w, h, r):
    return (f'M{x+r} {y}H{x+w-r}A{r} {r} 0 0 1 {x+w} {y+r}V{y+h-r}A{r} {r} 0 0 1 {x+w-r} {y+h}'
            f'H{x+r}A{r} {r} 0 0 1 {x} {y+h-r}V{y+r}A{r} {r} 0 0 1 {x+r} {y}Z')

def circle(cx, cy, r):
    return f'M{cx-r} {cy}A{r} {r} 0 1 1 {cx+r} {cy}A{r} {r} 0 1 1 {cx-r} {cy}Z'

# Node is a stroked drawing (2 px round); outline it by hand: outer and inner contour per box.
NODE = ' '.join([
    rrect(2, 3.5, 20, 8, 2.5), rrect(4, 5.5, 16, 4, 0.5),
    rrect(2, 12.5, 20, 8, 2.5), rrect(4, 14.5, 16, 4, 0.5),
    circle(7, 7.5, 1), circle(7, 16.5, 1)])

def shapes(name, svg):
    """(path d, matrix) pairs for one icon, in SVG space."""
    if name == 'node':
        return [(NODE, (1, 0, 0, 1, 0, 0), True)]
    m = re.search(r'transform="translate\(([\d.\-]+) ([\d.\-]+)\) scale\(([\d.]+)\)"', svg)
    tx, ty, sc = float(m.group(1)), float(m.group(2)), float(m.group(3))
    out = []
    for tag in re.findall(r'<(?:path|circle)[^>]*>', svg):
        if tag.startswith('<circle'):
            g = lambda k: float(re.search(k + r'="([\d.\-]+)"', tag).group(1))
            d = circle(g('cx'), g('cy'), g('r'))
        else:
            d = re.search(r' d="([^"]+)"', tag).group(1)
        out.append((d, (sc, 0, 0, sc, tx, ty), 'evenodd' in tag))
    return out

def stroked(svg):
    """The outline of a stroked drawing: every path, rect and circle stroked 2 px with round
    caps and joins, in font space."""
    out = pathops.Path()
    pen = out.getPen()
    for tag in re.findall(r'<(?:path|rect|circle)[^>]*>', svg):
        g = lambda k: float(re.search(r'\b' + k + r'="([\d.\-]+)"', tag).group(1))
        if tag.startswith('<rect'):
            rx = float(re.search(r'rx="([\d.]+)"', tag).group(1)) if 'rx=' in tag else 0
            d = rrect(g('x'), g('y'), g('width'), g('height'), rx) if rx else (
                f"M{g('x')} {g('y')}h{g('width')}v{g('height')}h{-g('width')}Z")
        elif tag.startswith('<circle'):
            d = circle(g('cx'), g('cy'), g('r'))
        else:
            d = re.search(r' d="([^"]+)"', tag).group(1)
        line = pathops.Path()
        parse_path(d, TransformPen(line.getPen(), (S, 0, 0, -S, 0, UPM)))
        line.stroke(2 * S, pathops.LineCap.ROUND_CAP, pathops.LineJoin.ROUND_JOIN, 4)
        line.convertConicsToQuads()
        line.draw(pen)
    out.simplify(fix_winding=True)
    return out

def glyph(name, svg):
    # SVG (y down) -> font (y up), via a nonzero-clean path from pathops.
    if 'stroke="currentColor"' in svg:
        path = stroked(svg)
        rec = RecordingPen()
        path.draw(rec)
        tt = TTGlyphPen(None)
        rec.replay(Cu2QuPen(tt, 1.0, reverse_direction=True))
        return tt.glyph()
    path = pathops.Path()
    pen = path.getPen()
    for d, (a, _b, _c, _e, tx, ty), eo in shapes(name, svg):
        sub = pathops.Path()
        # fill rule: pathops needs even-odd set before simplify
        sub.fillType = pathops.FillType.EVEN_ODD if eo else pathops.FillType.WINDING
        parse_path(d, TransformPen(sub.getPen(), (a * S, 0, 0, -a * S, tx * S, UPM - ty * S)))
        sub.simplify(fix_winding=True)
        sub.draw(pen)
    path.simplify(fix_winding=True)
    rec = RecordingPen()
    path.draw(rec)
    tt = TTGlyphPen(None)
    rec.replay(Cu2QuPen(tt, 1.0, reverse_direction=True))
    return tt.glyph()

def main():
    nd = TTGlyphPen(None)  # a visible .notdef box, as every font has
    for pts in ([(64, 0), (64, 800), (576, 800), (576, 0)], [(128, 64), (512, 64), (512, 736), (128, 736)]):
        nd.moveTo(pts[0]); [nd.lineTo(q) for q in pts[1:]]; nd.closePath()
    glyphs = {'.notdef': nd.glyph()}
    cmap, order = {}, ['.notdef']
    for i, n in enumerate(ICONS):
        gname = f'icon_{n}'.replace('-', '_')
        glyphs[gname] = glyph(n, Path(f'app/assets/icons/{n}.svg').read_text())
        cmap[0xE000 + i] = gname
        order.append(gname)
    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics({g: (UPM, getattr(glyphs[g], 'xMin', 0)) for g in order})
    fb.setupHorizontalHeader(ascent=UPM, descent=0)
    fb.setupNameTable({'familyName': 'EpicStatusIcons', 'styleName': 'Regular', 'uniqueFontIdentifier': 'EpicStatusIcons-Regular', 'fullName': 'EpicStatusIcons Regular', 'psName': 'EpicStatusIcons-Regular', 'version': 'Version 1.000'})
    fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, usWinAscent=UPM, usWinDescent=0)
    fb.setupPost()
    fb.save('app/assets/fonts/EpicStatusIcons.ttf')

main()
