#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Writes docs/design/key-picture-vectors.json: the test vectors of the key picture
(docs/design/key-picture.md). The app's test, the invite page's test and the faucet bot read
copies of that file; this script is the reference implementation they all match.

Usage: tools/key_picture_vectors.py [--check]   (--check: fail if the file differs)
"""
import argparse
import base64
import hashlib
import json
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'docs/design/key-picture-vectors.json'

LABEL = b'BT Wallet key picture v1'
TILE = '#141418'
PALETTE = ['#ff8a80', '#ffab5e', '#ffd54f', '#c5e1a5', '#69db7c', '#4dd0c4',
           '#4fc3f7', '#82a8ff', '#b39dff', '#e59bff', '#ff8fc7', '#d0d4dc']

# Keys that get the BT Labs badge: tag 08 of the service's invites, its name, the logo.
BTLABS_KEYS = [
    {'key': '342ac7f0d377f6138e71a87eeb14af02279527a5be5ef95a43878babfbd62456',
     'name': 'BT Labs Faucet', 'logo': 'btlabs'},
]


def picture(key: bytes) -> dict:
    assert len(key) == 32
    seed = hashlib.sha256(LABEL + key).digest()
    colour = seed[0] % len(PALETTE)
    cells = ((seed[1] << 8) | seed[2]) & 0x7fff
    if bin(cells).count('1') < 4:
        cells = ~cells & 0x7fff
    grid = [['.'] * 5 for _ in range(5)]
    for i in range(15):
        if cells >> i & 1:
            x, y = i // 5, i % 5
            grid[y][x] = grid[y][4 - x] = '#'
    return {'key': key.hex(), 'seed': seed.hex(), 'colour': colour, 'hex': PALETTE[colour],
            'cells': cells, 'grid': [''.join(r) for r in grid]}


def tag08(link: str):
    """Tag 08 of a pairing invite `…pair/1/<base64url>` or `…/pair#1/<base64url>`, or None."""
    rest = link.rsplit('pair/', 1)[-1] if 'pair/' in link else link.rsplit('pair#', 1)[-1]
    if not rest.startswith('1/'):
        return None
    b = rest[2:]
    try:
        raw = base64.urlsafe_b64decode(b.rstrip('=') + '=' * (-len(b.rstrip('=')) % 4))
    except ValueError:
        return None
    if len(raw) < 5:
        return None
    body = raw[:-4]
    if hashlib.sha256(hashlib.sha256(body).digest()).digest()[:4] != raw[-4:]:
        return None
    i, last, key = 0, -1, None
    while i < len(body):
        if i + 3 > len(body):
            return None
        tag, n = body[i], body[i + 1] << 8 | body[i + 2]
        i += 3
        if tag <= last or i + n > len(body):
            return None
        last = tag
        if tag == 8:
            key = body[i:i + n] if n == 32 else None
        i += n
    return key.hex() if key else None


def link_of(fields: list) -> str:
    body = b''.join(bytes([t, len(v) >> 8, len(v) & 0xff]) + v for t, v in fields)
    raw = body + hashlib.sha256(hashlib.sha256(body).digest()).digest()[:4]
    return 'epiccash://pair/1/' + base64.urlsafe_b64encode(raw).decode().rstrip('=')


def keys() -> list:
    out = [bytes(32), bytes([0xff] * 32)]
    out += [bytes.fromhex(k) for k in (
        # the six keys of the style comparison page
        '4cc08d5a9c44cf0c19cf0f496a19c3a1211291f0463d888e7bb3b6847386bd12',
        '2e75f01199933e1a99bed624339ff547e423a48eb4b6c97eddb8d9a23e145879',
        '42131d0ce80c1096c38a2bd81276f625b1ce8637e18d006adf7e850f3a95387c',
        '5f65d38bed127fcbcc9eae382068839a0839199e791c09aacb9e70145ecd4c03',
        'f1716c7fe00cabaf8591b12f1628e5484801d3e84a94857096f13cbc5dbbeb3b',
        'f0d28df52c440ec13c736151e354d645e3af0bcc15476e438fb2f35bef01793b')]
    out += [bytes.fromhex(k['key']) for k in BTLABS_KEYS]
    # every colour once, and keys whose cells are inverted (fewer than 4 came out)
    seen, inverted, i = {picture(k)['colour'] for k in out}, 0, 0
    while len(seen) < len(PALETTE) or inverted < 2:
        k = hashlib.sha256(b'key picture vector %d' % i).digest()
        i += 1
        s = hashlib.sha256(LABEL + k).digest()
        few = bin(((s[1] << 8) | s[2]) & 0x7fff).count('1') < 4
        if few and inverted < 2:
            inverted += 1
            out.append(k)
        elif s[0] % len(PALETTE) not in seen:
            seen.add(s[0] % len(PALETTE))
            out.append(k)
    return out


def links() -> list:
    faucet = bytes.fromhex(BTLABS_KEYS[0]['key'])
    other = keys()[2]
    good = link_of([(1, b'\x01'), (2, b'\x00'), (3, b'\x03'), (4, b'BT Labs Faucet'),
                    (5, bytes.fromhex('000000006aeaeeca')), (6, bytes(16)), (7, bytes(32)),
                    (8, faucet), (9, b'epicbox.btlabs.uk:443')])
    noname = link_of([(1, b'\x01'), (2, b'\x00'), (8, other)])
    rest = good.split('pair/', 1)[1]
    broken = rest[:-2] + ('A' if rest[-2] != 'A' else 'B') + rest[-1]
    return [
        {'link': good, 'key': faucet.hex()},
        {'link': 'https://epiccash.btlabs.uk/pair#' + rest, 'key': faucet.hex()},
        {'link': noname, 'key': other.hex()},
        {'link': 'epiccash://pair/1/' + broken, 'key': None, 'why': 'checksum'},
        {'link': link_of([(1, b'\x01'), (9, b'x'), (8, other)]), 'key': None, 'why': 'tags out of order'},
        {'link': link_of([(1, b'\x01'), (8, other[:31])]), 'key': None, 'why': 'tag 08 not 32 bytes'},
        {'link': link_of([(1, b'\x01'), (4, b'Anna')]), 'key': None, 'why': 'no tag 08'},
    ]


def build() -> str:
    doc = {
        'spec': 'docs/design/key-picture.md',
        'label': LABEL.decode(),
        'tile': TILE,
        'palette': PALETTE,
        'btlabs_keys': BTLABS_KEYS,
        'pictures': [picture(k) for k in keys()],
        'links': links(),
    }
    return json.dumps(doc, indent=2) + '\n'


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    text = build()
    for v in json.loads(text)['links']:
        assert tag08(v['link']) == v['key'], v
    if ap.parse_args().check:
        if OUT.read_text() != text:
            print(f'{OUT} is out of date: run tools/key_picture_vectors.py', file=sys.stderr)
            return 1
        return 0
    OUT.write_text(text)
    return 0


if __name__ == '__main__':
    sys.exit(main())
