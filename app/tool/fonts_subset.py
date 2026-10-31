#!/usr/bin/env python3
"""Regenerates the two subset fonts from the sources of truth:

  assets/fonts/NotoEmojiSas.ttf    the pairing picture set (lib/src/sas_table.dart) only
  assets/fonts/NotoSansSCSubset.otf  every CJK character of the Chinese UI

Needs fontTools (pip install fonttools). Sources: Noto Color Emoji (CBDT, OFL, github.com/googlefonts/noto-emoji)
and Noto Sans CJK SC (OFL, github.com/notofonts/noto-cjk), found at the default Debian paths or given as
EMOJI_FONT / CJK_FONT. Run from app/: python3 tool/fonts_subset.py
"""
import glob, os, re, sys
from fontTools import subset
from fontTools.ttLib import TTFont, TTCollection

EMOJI = os.environ.get('EMOJI_FONT', '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf')
CJK = os.environ.get('CJK_FONT', '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')

def run(src, out, text):
    opts = subset.Options()
    opts.layout_features = ['*']
    opts.name_IDs = ['*']
    opts.notdef_outline = True
    opts.glyph_names = False
    opts.hinting = False
    opts.drop_tables += ['DSIG']
    font = subset.load_font(src, opts, dontLoadGlyphNames=True)
    s = subset.Subsetter(opts)
    s.populate(text=text)
    s.subset(font)
    subset.save_font(font, out, opts)
    print(out, os.path.getsize(out) // 1024, 'KB', len(set(text)), 'characters')

# Emoji: the first field of every SasWord('x', 'name') entry.
sas = open('lib/src/sas_table.dart', encoding='utf-8').read()
emoji = sorted(set(re.findall(r"SasWord\('([^']+)'", sas)))
assert len(emoji) == 256, len(emoji)
run(EMOJI, 'assets/fonts/NotoEmojiSas.ttf', ''.join(emoji))

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
