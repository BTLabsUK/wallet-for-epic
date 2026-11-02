#!/usr/bin/env python3
"""Regenerates the subset fonts from their sources:

  assets/fonts/NotoSansSCSubset.otf  every CJK character of the Chinese UI
  assets/fonts/Geist*.ttf            Geist and Geist Mono (the network-modes picture,
                                     ui/help/network_modes_diagram.dart): Latin and Cyrillic

Needs fontTools (pip install fonttools). Run from app/.
  python3 tool/fonts_subset.py        the CJK subset. Source: Noto Sans CJK SC (OFL,
                                      github.com/notofonts/noto-cjk), found at the default Debian
                                      path or given as CJK_FONT.
  python3 tool/fonts_subset.py geist  the Geist subsets. Source: the static TTFs of a Geist release
                                      (OFL, github.com/vercel/geist-font, 1.9.0), unzipped into
                                      GEIST_DIR (the folder holding Geist/ and GeistMono/).
(The pairing pictures are SVGs, assets/sas, from tool/sas_pictures.py.)
"""
import glob, os, re, sys
from fontTools import subset
from fontTools.ttLib import TTFont, TTCollection

CJK = os.environ.get('CJK_FONT', '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')

def run(src, out, text, hinting=False):
    opts = subset.Options()
    opts.layout_features = ['*']
    opts.name_IDs = ['*']
    opts.notdef_outline = True
    opts.glyph_names = False
    opts.hinting = hinting
    opts.drop_tables += ['DSIG']
    font = subset.load_font(src, opts, dontLoadGlyphNames=True)
    s = subset.Subsetter(opts)
    s.populate(text=text)
    s.subset(font)
    subset.save_font(font, out, opts)
    print(out, os.path.getsize(out) // 1024, 'KB', len(set(text)), 'characters')

# Geist: Basic Latin, Latin-1, Latin Extended-A (German, Polish), Cyrillic (Russian), the
# punctuation the strings use. Thai and Chinese fall back to the bundled Noto fonts. Hinting
# kept: the picture's labels are small on Windows and Linux.
if sys.argv[1:] == ['geist']:
    src = os.environ.get('GEIST_DIR', 'geist-font')
    text = ''.join(chr(c) for r in [(0x20, 0x7E), (0xA0, 0x17F), (0x400, 0x45F), (0x490, 0x491),
                                     (0x2010, 0x2027), (0x2030, 0x203A), (0x2190, 0x2193)] for c in range(r[0], r[1] + 1))
    for face in ['Geist/ttf/Geist-Regular.ttf', 'GeistMono/ttf/GeistMono-Regular.ttf', 'GeistMono/ttf/GeistMono-Medium.ttf']:
        run(os.path.join(src, face), 'assets/fonts/' + os.path.basename(face), text, hinting=True)
    sys.exit(0)

# The pairing pictures' emoji (the first field of every SasWord('x', 'name') entry), kept out
# of the CJK set.
sas = open('lib/src/sas_table.dart', encoding='utf-8').read()
emoji = sorted(set(re.findall(r"SasWord\('([^']+)'", sas)))

# CJK: everything in the Chinese strings, plus the language names the pickers show.
files = ['lib/l10n/app_zh.arb', 'lib/src/help/help_zh.dart', 'lib/src/l10n.dart']
files += glob.glob('lib/l10n/desk/*.zh.json') + glob.glob('lib/l10n/desk_invoices/*.zh.json')
chars = set()
for f in files:
    for c in open(f, encoding='utf-8').read():
        if ord(c) > 0x2E7F and not (0x0E00 <= ord(c) <= 0x0E7F) and not (0x1F000 <= ord(c) <= 0x1FFFF):
            chars.add(c)
chars -= set(emoji)
if CJK.endswith('.ttc'):
    tmp = os.environ.get('TMPDIR', '.') + '/cjk-sc.otf'
    ttc = TTCollection(CJK)
    # the SC face is the one whose name says so (Noto Sans CJK SC)
    face = next((f for f in ttc.fonts if 'SC' in f['name'].getDebugName(1)), ttc.fonts[0])
    face.save(tmp)
    CJK = tmp
run(CJK, 'assets/fonts/NotoSansSCSubset.otf', ''.join(sorted(chars)))
