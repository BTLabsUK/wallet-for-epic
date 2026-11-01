#!/usr/bin/env python3
"""Regenerates assets/sas/: the 256 pairing pictures of lib/src/sas_table.dart as small SVGs.

  assets/sas/<name>.svg   one per table entry, named by its word (kitty.svg, pretzel.svg, ...)
  assets/sas/LICENSE.txt  the source's licence notice (Apache-2.0), shown on the licences page

Source: Noto Emoji, the colour SVGs in 2D/svg of github.com/googlefonts/noto-emoji at the commit
pinned below (tag v2026-09-24-unicode18_0), Apache-2.0. Each download is checked against
tool/sas_pictures.sha256 before use; a file whose hash differs stops the run. The SVGs are
then made smaller (Illustrator data, comments, ids nobody refers to and hidden layers dropped,
styles turned into attributes, coordinates rounded to two decimals on the 128-unit grid, transforms to four); the
drawing itself is unchanged. test/sas_picture_test.dart parses every file with flutter_svg's
parser, warnings as errors.

Python 3 only, no packages. Run from app/: python3 tool/sas_pictures.py
  --update-checksums   write tool/sas_pictures.sha256 from the downloads (after a pin change)
Downloads are cached in $TMPDIR/noto-emoji-<commit>/.
"""
import concurrent.futures
import hashlib
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

REPO = 'googlefonts/noto-emoji'
COMMIT = 'e20cbc2bbec1926686be9f9bee7d1d2cfa1fea0e'  # tag v2026-09-24-unicode18_0
RAW = f'https://raw.githubusercontent.com/{REPO}/{COMMIT}/'
SUMS = 'tool/sas_pictures.sha256'
OUT = 'assets/sas'
CACHE = os.path.join(os.environ.get('TMPDIR', '/tmp'), f'noto-emoji-{COMMIT[:12]}')

SVG = 'http://www.w3.org/2000/svg'
XLINK = 'http://www.w3.org/1999/xlink'
ET.register_namespace('', SVG)
ET.register_namespace('xlink', XLINK)

# Style properties that become attributes of their own (shorter, and what every SVG reader knows).
PRESENTATION = {
    'fill', 'fill-opacity', 'fill-rule', 'stroke', 'stroke-width', 'stroke-opacity',
    'stroke-linecap', 'stroke-linejoin', 'stroke-miterlimit', 'stroke-dasharray',
    'stroke-dashoffset', 'opacity', 'stop-color', 'stop-opacity', 'clip-rule', 'clip-path',
}
# Properties that change nothing in a 128-unit picture drawn on its own.
DROPPED_STYLE = {'enable-background', 'overflow', 'display'}
NUMERIC_ATTRS = {
    'x', 'y', 'x1', 'y1', 'x2', 'y2', 'cx', 'cy', 'r', 'rx', 'ry', 'fx', 'fy', 'width', 'height',
    'stroke-width', 'opacity', 'stop-opacity', 'fill-opacity', 'stroke-opacity', 'offset',
    'stroke-miterlimit',
}
NUM = re.compile(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')


def table():
    """The (emoji, name) entries of lib/src/sas_table.dart, in table order."""
    src = open('lib/src/sas_table.dart', encoding='utf-8').read()
    entries = re.findall(r"SasWord\('([^']+)',\s*'([a-z]+)'\)", src)
    assert len(entries) == 256, len(entries)
    assert len({n for _, n in entries}) == 256, 'names must be unique'
    return entries


def source_name(emoji):
    """Noto's file name: the code points in lower-case hex, joined by _, without U+FE0F."""
    return 'emoji_u' + '_'.join('%04x' % ord(c) for c in emoji if c != '\ufe0f') + '.svg'


def fetch(path):
    local = os.path.join(CACHE, path.replace('/', '_'))
    if not os.path.exists(local):
        data = urllib.request.urlopen(RAW + path, timeout=60).read()
        with open(local + '.part', 'wb') as f:
            f.write(data)
        os.replace(local + '.part', local)
    with open(local, 'rb') as f:
        return f.read()


def fmt(value, digits=2):
    """A number with at most [digits] decimals, without a leading zero or trailing zeros."""
    s = ('%.*f' % (digits, float(value))).rstrip('0').rstrip('.')
    if s in ('-0', ''):
        s = '0'
    if s.startswith('0.'):
        s = s[1:]
    elif s.startswith('-0.'):
        s = '-' + s[2:]
    return s


def numbers(text, digits=2):
    return ' '.join(fmt(n, digits) for n in NUM.findall(text))


ARGS = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'q': 4, 't': 2, 'a': 7, 'z': 0}


def path_data(d):
    """[d] with every number rounded. Read command by command, so an arc's flags are read as
    the single digits they are even when glued to the next number ("a1 1 0 01.5.5")."""
    pos, out = 0, []
    cmd = None

    def num():
        nonlocal pos
        m = re.compile(r'[\s,]*([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?)').match(d, pos)
        pos = m.end()
        return m.group(1)

    def flag():
        nonlocal pos
        m = re.compile(r'[\s,]*([01])').match(d, pos)
        pos = m.end()
        return m.group(1)

    while True:
        m = re.compile(r'[\s,]*([MmLlHhVvCcSsQqTtAaZz])?').match(d, pos)
        if m.group(1):
            cmd = m.group(1)
            pos = m.end()
            out.append(cmd)
            if cmd in 'Zz':
                continue
        elif not re.match(r'[\s,]*[-+.\d]', d[pos:]):
            assert not d[pos:].strip(' \t\r\n,'), f'unread path data {d[pos:pos + 20]!r}'
            break
        n = ARGS[cmd.lower()]
        assert n, f'numbers after {cmd} in {d[:40]!r}'
        vals = []
        for k in range(n):
            vals.append(flag() if cmd in 'Aa' and k in (3, 4) else fmt(num()))
        for v in vals:
            # A separator only where the next number would otherwise run into this one: not
            # before a minus, after a command letter, or before ".5" when this one has a point.
            prev = out[-1] if out else ''
            if prev and not prev.isalpha() and not v.startswith('-') and \
                    not (v.startswith('.') and '.' in prev):
                out.append(' ')
            out.append(v)
    return ''.join(out)


def referenced_ids(root):
    refs = set()
    for el in root.iter():
        for k, v in el.attrib.items():
            refs.update(re.findall(r'url\(#([^)]+)\)', v))
            if k == f'{{{XLINK}}}href' and v.startswith('#'):
                refs.add(v[1:])
    return refs


def optimise(raw):
    root = ET.fromstring(raw)
    hidden = set()
    for el in root.iter():
        style = el.attrib.pop('style', '')
        for decl in filter(None, (s.strip() for s in style.split(';'))):
            key, _, value = (p.strip() for p in decl.partition(':'))
            if key == 'display' and value == 'none':
                hidden.add(el)
            elif key in PRESENTATION:
                el.set(key, value)
            elif key not in DROPPED_STYLE:
                raise ValueError(f'unknown style {decl!r}')
        if el.get('display') == 'none':
            hidden.add(el)
    # Drop hidden layers and anything outside the SVG namespace (Illustrator's private data).
    for parent in list(root.iter()):
        for child in list(parent):
            if child in hidden or not child.tag.startswith(f'{{{SVG}}}') or \
                    child.tag in (f'{{{SVG}}}title', f'{{{SVG}}}desc', f'{{{SVG}}}metadata'):
                parent.remove(child)
    refs = referenced_ids(root)
    for el in root.iter():
        for k in list(el.attrib):
            v = el.attrib[k]
            if k.startswith('{') and not k.startswith(f'{{{XLINK}}}') or \
                    k in ('version', 'data-name', 'display', 'enable-background') or \
                    (k == 'id' and v not in refs):
                del el.attrib[k]
            elif k == 'd':
                el.set(k, path_data(v))
            elif k == 'points':
                el.set(k, numbers(v))
            elif k in ('transform', 'gradientTransform'):
                el.set(k, re.sub(r'\(([^)]*)\)', lambda m: '(' + numbers(m.group(1), 4) + ')', v))
            elif k in NUMERIC_ATTRS and NUM.fullmatch(v.strip()):
                el.set(k, fmt(v))
        el.text = el.text.strip() or None if el.text else None
        el.tail = None
    for k in ('x', 'y', '{http://www.w3.org/XML/1998/namespace}space'):
        root.attrib.pop(k, None)
    # Empty groups left by the steps above.
    changed = True
    while changed:
        changed = False
        for parent in list(root.iter()):
            for child in list(parent):
                if child.tag in (f'{{{SVG}}}g', f'{{{SVG}}}defs') and len(child) == 0:
                    parent.remove(child)
                    changed = True
    # Groups with no attributes of their own hand their children to their parent.
    changed = True
    while changed:
        changed = False
        for parent in list(root.iter()):
            for i, child in enumerate(list(parent)):
                if child.tag == f'{{{SVG}}}g' and not child.attrib:
                    parent.remove(child)
                    for j, grandchild in enumerate(list(child)):
                        parent.insert(i + j, grandchild)
                    changed = True
                    break
    out = ET.tostring(root, encoding='unicode', short_empty_elements=True).replace(' />', '/>')
    if 'xlink:' not in out:
        out = out.replace(f' xmlns:xlink="{XLINK}"', '')
    return out + '\n'


def main():
    update = '--update-checksums' in sys.argv[1:]
    os.makedirs(CACHE, exist_ok=True)
    entries = table()
    paths = ['2D/svg/LICENSE'] + ['2D/svg/' + source_name(e) for e, _ in entries]
    with concurrent.futures.ThreadPoolExecutor(8) as pool:
        data = dict(zip(paths, pool.map(fetch, paths)))
    sums = {p: hashlib.sha256(b).hexdigest() for p, b in data.items()}
    if update:
        with open(SUMS, 'w') as f:
            f.write(f'# sha256 of the Noto Emoji sources at {REPO}@{COMMIT} (tool/sas_pictures.py)\n')
            for p in paths:
                f.write(f'{sums[p]}  {p}\n')
    want = {}
    for line in open(SUMS):
        if line.strip() and not line.startswith('#'):
            h, p = line.split()
            want[p] = h
    bad = [p for p in paths if want.get(p) != sums[p]]
    if bad:
        sys.exit(f'checksum mismatch or missing: {bad[:5]} ({len(bad)} files)')

    os.makedirs(OUT, exist_ok=True)
    total = 0
    for emoji, name in entries:
        svg = optimise(data['2D/svg/' + source_name(emoji)])
        with open(f'{OUT}/{name}.svg', 'w', encoding='utf-8') as f:
            f.write(svg)
        total += len(svg.encode())
    notice = data['2D/svg/LICENSE'].decode()
    with open(f'{OUT}/LICENSE.txt', 'w', encoding='utf-8') as f:
        f.write('The pairing pictures are Noto Emoji images (https://github.com/googlefonts/noto-emoji,\n'
                f'commit {COMMIT[:12]}), made smaller by tool/sas_pictures.py; the drawings are unchanged.\n\n')
        f.write(notice)
    raw = sum(len(data['2D/svg/' + source_name(e)]) for e, _ in entries)
    print(f'{len(entries)} pictures: {raw // 1024} KB of source, {total // 1024} KB written to {OUT}/')


if __name__ == '__main__':
    main()
