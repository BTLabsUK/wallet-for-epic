#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Writes docs/design/directory-vectors.json: the test vectors of the directory wire format
(docs/design/directory-wire.md). The wallet's tests and a directory service's tests read copies
of that file; this script is the reference implementation they all match. Python 3.12, stdlib
only: the secp256k1 ECDSA below is plain and slow on purpose.

Usage: tools/directory_vectors.py [--check] [--lepic <k3check>]
  --check          fail if the file differs
  --lepic <path>   cross-check every signature against LEPIC's own K3 code through the built
                   `k3check` tool (sign: same DER and key texts; verify: true or false)
"""
import argparse
import base64
import hashlib
import hmac
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/design/directory-vectors.json'
SAS = ROOT / 'app/lib/src/sas_table.dart'

# ---------------------------------------------------------------- secp256k1 ECDSA

P = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
G = (0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,
     0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8)


def pt_add(a, b):
    if a is None:
        return b
    if b is None:
        return a
    if a[0] == b[0] and (a[1] + b[1]) % P == 0:
        return None
    if a == b:
        m = 3 * a[0] * a[0] * pow(2 * a[1], -1, P) % P
    else:
        m = (b[1] - a[1]) * pow(b[0] - a[0], -1, P) % P
    x = (m * m - a[0] - b[0]) % P
    return (x, (m * (a[0] - x) - a[1]) % P)


def pt_mul(k, pt):
    out = None
    while k:
        if k & 1:
            out = pt_add(out, pt)
        pt = pt_add(pt, pt)
        k >>= 1
    return out


def compress(pt) -> bytes:
    return bytes([2 + (pt[1] & 1)]) + pt[0].to_bytes(32, 'big')


def decompress(b: bytes):
    """The point of a 33-byte compressed key, or None when it is not on the curve."""
    if len(b) != 33 or b[0] not in (2, 3):
        return None
    x = int.from_bytes(b[1:], 'big')
    if x >= P:
        return None
    y = pow((x ** 3 + 7) % P, (P + 1) // 4, P)
    if y * y % P != (x ** 3 + 7) % P:
        return None
    return (x, y if y & 1 == b[0] & 1 else P - y)


def rfc6979_k(sk: int, digest: bytes):
    """RFC 6979 nonces with HMAC-SHA256 (no extra data), as libsecp256k1 makes them."""
    x = sk.to_bytes(32, 'big')
    h = (int.from_bytes(digest, 'big') % N).to_bytes(32, 'big')
    v, k = b'\x01' * 32, b'\x00' * 32
    k = hmac.new(k, v + b'\x00' + x + h, hashlib.sha256).digest()
    v = hmac.new(k, v, hashlib.sha256).digest()
    k = hmac.new(k, v + b'\x01' + x + h, hashlib.sha256).digest()
    v = hmac.new(k, v, hashlib.sha256).digest()
    while True:
        v = hmac.new(k, v, hashlib.sha256).digest()
        t = int.from_bytes(v, 'big')
        if 1 <= t < N:
            yield t
        k = hmac.new(k, v + b'\x00', hashlib.sha256).digest()
        v = hmac.new(k, v, hashlib.sha256).digest()


def der_int(i: int) -> bytes:
    b = i.to_bytes((i.bit_length() + 8) // 8, 'big')  # a leading 0 when the top bit is set
    return b'\x02' + bytes([len(b)]) + b


def der_sig(r: int, s: int) -> bytes:
    body = der_int(r) + der_int(s)
    return b'\x30' + bytes([len(body)]) + body


def der_parse(sig: bytes):
    """(r, s) of a strict DER signature, or None."""
    try:
        if sig[0] != 0x30 or sig[1] != len(sig) - 2 or sig[2] != 2:
            return None
        rl = sig[3]
        r = sig[4:4 + rl]
        if sig[4 + rl] != 2 or sig[5 + rl] != len(sig) - 6 - rl:
            return None
        s = sig[6 + rl:]
        for v in (r, s):
            if not v or v[0] & 0x80 or (len(v) > 1 and v[0] == 0 and not v[1] & 0x80):
                return None
        return int.from_bytes(r, 'big'), int.from_bytes(s, 'big')
    except IndexError:
        return None


def ecdsa_sign(sk: int, digest: bytes) -> bytes:
    z = int.from_bytes(digest, 'big')
    for k in rfc6979_k(sk, digest):
        r = pt_mul(k, G)[0] % N
        s = pow(k, -1, N) * (z + r * sk) % N
        if r and s:
            return der_sig(r, N - s if s > N // 2 else s)  # low S


def ecdsa_verify(pub: bytes, digest: bytes, sig: bytes) -> bool:
    q, rs = decompress(pub), der_parse(sig)
    if q is None or rs is None:
        return False
    r, s = rs
    if not (1 <= r < N and 1 <= s <= N // 2):  # low S only
        return False
    z, w = int.from_bytes(digest, 'big'), pow(s, -1, N)
    pt = pt_add(pt_mul(z * w % N, G), pt_mul(r * w % N, q))
    return pt is not None and pt[0] % N == r


def sk_of(n: int) -> int:
    v = int.from_bytes(hashlib.sha256(b'directory vector key ' + str(n).encode()).digest(), 'big')
    assert 0 < v < N  # holds for every n the vectors use
    return v


def pub_of(n: int) -> bytes:
    return compress(pt_mul(sk_of(n), G))


# ---------------------------------------------------------------- base58check, key text

B58 = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
VERSION = {0: b'\x01\x00', 1: b'\x01\x88'}  # mainnet, floonet


def dsha(b: bytes) -> bytes:
    return hashlib.sha256(hashlib.sha256(b).digest()).digest()


def b58check(payload: bytes) -> str:
    raw = payload + dsha(payload)[:4]
    n, out = int.from_bytes(raw, 'big'), ''
    while n:
        n, r = divmod(n, 58)
        out = B58[r] + out
    return B58[0] * (len(raw) - len(raw.lstrip(b'\0'))) + out


def b58check_decode(text: str):
    """The payload of a base58check text, or None."""
    n = 0
    for c in text:
        i = B58.find(c)
        if i < 0:
            return None
        n = n * 58 + i
    raw = n.to_bytes((n.bit_length() + 7) // 8, 'big')
    raw = b'\0' * (len(text) - len(text.lstrip(B58[0]))) + raw
    if len(raw) < 5 or dsha(raw[:-4])[:4] != raw[-4:]:
        return None
    return raw[:-4]


def key_text(pub: bytes, net: int) -> str:
    return b58check(VERSION[net] + pub)


def key_text_parse(text: str):
    """(net, 33-byte key) of an Epicbox key text, or None."""
    p = b58check_decode(text)
    if p is None or len(p) != 35 or p[0] != 1 or p[1] not in (0, 0x88) or p[2] not in (2, 3):
        return None
    return (0 if p[1] == 0 else 1), p[2:]


# ---------------------------------------------------------------- K3

K3_TAG = b'lepic/listing-signature/v1'
D_HELLO, D_LISTING, D_MOVED = 'epic-dir-hello/1', 'epic-listing/1', 'epic-listing-moved/1'
D_PAYREQ, D_UNLIST = 'epic-payreq/1', 'epic-unlist/1'
DOMAINS = [D_HELLO, D_LISTING, D_MOVED, D_PAYREQ, D_UNLIST]


def k3_digest(domain: str, message: bytes) -> bytes:
    t = hashlib.sha256(K3_TAG).digest()
    d = domain.encode()
    return hashlib.sha256(t + t + bytes([len(d)]) + d + message).digest()


def k3_sign(sk: int, domain: str, message: bytes) -> bytes:
    return ecdsa_sign(sk, k3_digest(domain, message))


def k3_verify(pub: bytes, domain: str, message: bytes, sig: bytes) -> bool:
    return ecdsa_verify(pub, k3_digest(domain, message), sig)


# ---------------------------------------------------------------- SAS table, codes

def sas_table() -> list:
    text = SAS.read_text(encoding='utf-8')
    t = re.findall(r"SasWord\('([^']+)', '([^']+)'\)", text)
    assert len(t) == 256
    return t


def code_of(label: bytes, key: bytes) -> dict:
    idx = list(hashlib.sha256(label + key).digest()[:4])
    t = sas_table()
    return {'indexes': idx, 'emoji': ''.join(t[i][0] for i in idx),
            'names': [t[i][1] for i in idx]}


def dir_code(dkey: bytes) -> dict:
    return code_of(b'epic-dir/1', dkey)


def listing_code(key: bytes) -> dict:
    return code_of(b'epic-listing/1 code', key)


# ---------------------------------------------------------------- TLV codec


class Err(Exception):
    """A named error of the spec: checksum, malformed, network, signature, expired, for_other,
    bind, dkey."""


def tlv(items) -> bytes:
    return b''.join(bytes([t, len(v) >> 8, len(v) & 0xff]) + v for t, v in items)


def parse_tlv(raw: bytes) -> list:
    """[(tag, value, start offset)]: strictly increasing tags, no bytes after the last field."""
    out, i, last = [], 0, -1
    while i < len(raw):
        if i + 3 > len(raw):
            raise Err('malformed')
        tag, n = raw[i], raw[i + 1] << 8 | raw[i + 2]
        if tag <= last or i + 3 + n > len(raw):
            raise Err('malformed')
        out.append((tag, raw[i + 3:i + 3 + n], i))
        last, i = tag, i + 3 + n
    return out


class F:
    def __init__(self, tag, name, kind, size=None, optional=False):
        self.tag, self.name, self.kind, self.size, self.optional = tag, name, kind, size, optional


# kinds: 'u' size bytes big-endian int; 'b' size bytes (hex); 'ascii' (lo, hi); 'card'; 'label'
CARD = [F(1, 'format', 'u', 1), F(2, 'net', 'u', 1), F(3, 'address', 'ascii', (1, 128)),
        F(4, 'dkey', 'b', 33), F(5, 'handle', 'b', 16), F(6, 'seq', 'u', 4),
        F(7, 'issued', 'u', 8)]
PAYREQ = [F(1, 'format', 'u', 1), F(2, 'net', 'u', 1), F(3, 'card', 'card'),
          F(4, 'amount', 'u', 8), F(5, 'reqid', 'b', 16), F(6, 'expires', 'u', 8),
          F(7, 'kind', 'u', 1), F(8, 'label', 'label', optional=True),
          F(9, 'for', 'b', 33, optional=True)]
# payload type -> (name, fields after tag 01, signed)
PAYLOADS = {
    1: ('dir-hello', [F(2, 'net', 'u', 1), F(3, 'dkey', 'b', 33), F(4, 'handle', 'b', 16),
                      F(5, 'bind', 'b', 4), F(6, 'issued', 'u', 8),
                      F(7, 'flags', 'u', 1, optional=True)], True),
    2: ('listing', [F(2, 'card', 'card')], False),
    3: ('unlist', [F(2, 'net', 'u', 1), F(3, 'address', 'ascii', (1, 128)),
                   F(4, 'dkey', 'b', 33), F(5, 'handle', 'b', 16), F(6, 'issued', 'u', 8)], True),
    4: ('unlisted', [F(2, 'dkey', 'b', 33), F(3, 'handle', 'b', 16), F(4, 'issued', 'u', 8)],
        False),
    5: ('receipt', [F(2, 'reqid', 'b', 16), F(3, 'stage', 'u', 1), F(4, 'amount', 'u', 8),
                    F(5, 'at', 'u', 8)], False),
    6: ('moved', [F(2, 'net', 'u', 1), F(3, 'old_address', 'ascii', (1, 128)),
                  F(4, 'card', 'card')], True),
}
HELLO_NO_PAYMENTS = 0x01   # hello flags bit 0: this contact takes no payments
LABEL_RE = re.compile(rb'@[A-Za-z0-9_]{1,32}')


class Parsed:
    def __init__(self, fields, raw, msg, sig, kids):
        self.fields, self.raw, self.msg, self.sig, self.kids = fields, raw, msg, sig, kids


def decode_struct(raw: bytes, schema: list, signed: bool, lead=()) -> Parsed:
    """Structure only: the TLV rules, sizes, required fields. `lead` are fields (tag 01 of a
    payload) the caller has read already."""
    by_tag = {f.tag: f for f in schema}
    fields, kids, sig, sig_at = {}, {}, None, len(raw)
    for tag, val, start in parse_tlv(raw):
        if tag == 0xFF:
            if not signed or not 8 <= len(val) <= 72:
                raise Err('malformed')
            sig, sig_at = val, start
        elif tag in by_tag:
            f = by_tag[tag]
            if f.kind == 'u':
                if len(val) != f.size:
                    raise Err('malformed')
                fields[f.name] = int.from_bytes(val, 'big')
            elif f.kind == 'b':
                if len(val) != f.size:
                    raise Err('malformed')
                fields[f.name] = val.hex()
            elif f.kind == 'ascii':
                if not f.size[0] <= len(val) <= f.size[1] or not val.isascii():
                    raise Err('malformed')
                fields[f.name] = val.decode('ascii')
            elif f.kind == 'label':  # a bad label is dropped, not an error
                fields[f.name] = val.decode('ascii') if LABEL_RE.fullmatch(val) else None
            else:
                kids[f.name] = decode_card(val)
                fields[f.name] = kids[f.name].fields
        elif tag == 1 and lead:
            fields['type'] = lead[0]
        elif tag >= 0x80:
            fields.setdefault('extra', []).append({'tag': tag, 'hex': val.hex()})
        else:
            raise Err('malformed')
    if signed and sig is None:
        raise Err('malformed')
    if any(not f.optional and f.name not in fields for f in schema):
        raise Err('malformed')
    if sig is not None:
        fields['sig'] = sig.hex()
    return Parsed(fields, raw, raw[:sig_at], sig, kids)


def encode_struct(fields: dict, schema: list, signed: bool, lead=None) -> bytes:
    items = [(1, bytes([lead]))] if lead is not None else []
    for f in schema:
        v = fields.get(f.name)
        if v is None:
            continue
        if f.kind == 'u':
            b = v.to_bytes(f.size, 'big')
        elif f.kind == 'b':
            b = bytes.fromhex(v)
        elif f.kind in ('ascii', 'label'):
            b = v.encode('ascii')
        else:
            b = encode_card(v)
        items.append((f.tag, b))
    items += [(e['tag'], bytes.fromhex(e['hex'])) for e in fields.get('extra', [])]
    items.sort(key=lambda it: it[0])
    if signed:
        items.append((0xFF, bytes.fromhex(fields['sig'])))
    return tlv(items)


def encode_card(fields):
    return encode_struct(fields, CARD, True)


def encode_payreq(fields):
    return encode_struct(fields, PAYREQ, True)


def encode_payload(fields):
    _, schema, signed = PAYLOADS[fields['type']]
    return encode_struct(fields, schema, signed, lead=fields['type'])


def decode_card(raw: bytes) -> Parsed:
    p = decode_struct(raw, CARD, True)
    f = p.fields
    if f['format'] != 1 or f['net'] not in (0, 1) or bytes.fromhex(f['dkey'])[0] not in (2, 3):
        raise Err('malformed')
    addr_parse(f['address'])
    return p


def addr_parse(text: str):
    """(net, listing key) of `key@relay[:port]`."""
    key, at, relay = text.partition('@')
    host, colon, port = relay.rpartition(':')
    if not colon:
        host = relay
    ok = at and host and re.fullmatch(r'[A-Za-z0-9.\-]+', host) and \
        (not colon or (port.isdigit() and port.isascii() and 1 <= int(port) <= 65535))
    k = key_text_parse(key) if ok else None
    if k is None:
        raise Err('malformed')
    return k


# ---------------------------------------------------------------- verification

def card_network(p: Parsed, net: int):
    f = p.fields
    if f['net'] != net or addr_parse(f['address'])[0] != net:
        raise Err('network')


def card_signature(p: Parsed):
    pub = addr_parse(p.fields['address'])[1]
    if not k3_verify(pub, D_LISTING, p.msg, p.sig):
        raise Err('signature')


def verify_card(raw: bytes, net: int) -> dict:
    p = decode_card(raw)
    card_network(p, net)
    card_signature(p)
    return p.fields


def verify_payreq(raw: bytes, ctx: dict) -> dict:
    """`raw` is the request without its text wrapper. ctx: net, now, listing_key (hex, optional)."""
    p = decode_struct(raw, PAYREQ, True)
    f = p.fields
    if f['format'] != 1 or f['kind'] not in (1, 2) or f['net'] not in (0, 1) \
            or ('for' in f and bytes.fromhex(f['for'])[0] not in (2, 3)):
        raise Err('malformed')
    card = p.kids['card']
    if f['net'] != ctx['net'] or card.fields['net'] != f['net']:
        raise Err('network')
    card_network(card, f['net'])
    if not k3_verify(bytes.fromhex(card.fields['dkey']), D_PAYREQ, p.msg, p.sig):
        raise Err('signature')
    card_signature(card)
    if ctx['now'] > f['expires'] + 120:
        raise Err('expired')
    if 'for' in f and f['for'] != ctx.get('listing_key'):
        raise Err('for_other')
    return f


def text_of(raw: bytes, form: str, host='links.example') -> str:
    p = base64.urlsafe_b64encode(raw + dsha(raw)[:4]).decode().rstrip('=')
    return f'epiccash://pay/1/{p}' if form == 'scheme' else f'https://{host}/p#1/{p}'


def text_payload(text: str) -> bytes:
    """The request bytes of a link text: the router takes `pay/1/<p>` or `p#1/<p>` anywhere."""
    text = text.strip()
    if 'pay/1/' in text:
        p = text.rsplit('pay/1/', 1)[1]
    elif 'p#1/' in text:
        p = text.rsplit('p#1/', 1)[1]
    else:
        raise Err('malformed')
    if not re.fullmatch(r'[A-Za-z0-9_\-]*', p) or len(p) % 4 == 1:
        raise Err('checksum')
    raw = base64.urlsafe_b64decode(p + '=' * (-len(p) % 4))
    if len(raw) < 5 or dsha(raw[:-4])[:4] != raw[-4:]:
        raise Err('checksum')
    return raw[:-4]


def verify_payreq_text(text: str, ctx: dict) -> dict:
    return verify_payreq(text_payload(text), ctx)


def verify_payload(raw: bytes, ctx: dict) -> dict:
    """ctx: net; dkey (hex, the directory's, type 2); bind (hex, type 1)."""
    items = parse_tlv(raw)
    if not items or items[0][0] != 1 or len(items[0][1]) != 1:
        raise Err('malformed')
    t = items[0][1][0]
    if t not in PAYLOADS:
        return {'type': t, 'dropped': True}  # acknowledged and dropped
    _, schema, signed = PAYLOADS[t]
    p = decode_struct(raw, schema, signed, lead=(t,))
    f = p.fields
    net = f.get('net')
    if net not in (None, 0, 1):
        raise Err('malformed')
    if t == 5 and f['stage'] not in (1, 2):
        raise Err('malformed')
    if t == 1 and f.get('flags', 0) & ~HELLO_NO_PAYMENTS:
        raise Err('malformed')
    for name in ('dkey', 'for'):
        if name in f and bytes.fromhex(f[name])[0] not in (2, 3):
            raise Err('malformed')
    keynet, pub = None, None
    if t == 3:
        keynet, pub = addr_parse(f['address'])
    if t == 6:
        keynet, pub = addr_parse(f['old_address'])
    card = p.kids.get('card')
    if net is not None and net != ctx['net']:
        raise Err('network')
    if keynet is not None and keynet != ctx['net']:
        raise Err('network')
    if card:
        card_network(card, ctx['net'])
    if t == 1 and not k3_verify(bytes.fromhex(f['dkey']), D_HELLO, p.msg, p.sig):
        raise Err('signature')
    if t == 3 and not k3_verify(pub, D_UNLIST, p.msg, p.sig):
        raise Err('signature')
    if t == 6 and not k3_verify(pub, D_MOVED, p.msg, p.sig):
        raise Err('signature')
    if card:
        card_signature(card)
    if t == 1 and f['bind'] != ctx['bind']:
        raise Err('bind')
    if t == 2 and f['card']['dkey'] != ctx['dkey']:
        raise Err('dkey')
    return f


# ---------------------------------------------------------------- the vectors

NOW = 1_800_000_000
RELAY = 'relay.example:443'


def h16(label: str, n: int) -> str:
    return hashlib.sha256(f'directory vector {label} {n}'.encode()).digest()[:16].hex()


class Rec:
    """A record under construction: fields, bytes and the signatures made on the way."""

    def __init__(self):
        self.sigs = []

    def sign(self, n: int, domain: str, message: bytes) -> str:
        der = k3_sign(sk_of(n), domain, message)
        self.sigs.append({'sk': sk_of(n).to_bytes(32, 'big').hex(), 'domain': domain,
                          'message': message.hex(), 'der': der.hex()})
        return der.hex()


def signed_items(rec, items, n, domain, extra_sig=None):
    """tlv bytes of items plus an FF field signed by key n (or the given sig bytes)."""
    body = tlv(items)
    sig = bytes.fromhex(rec.sign(n, domain, body)) if extra_sig is None else extra_sig
    return body + tlv([(0xFF, sig)])


def u(v, n):
    return v.to_bytes(n, 'big')


def card_items(net=0, n_list=10, n_dir=1, handle=0, seq=1, issued=NOW - 1000, relay=RELAY,
               address=None, fmt=1, dkey=None, handle_bytes=None):
    addr = address or f'{key_text(pub_of(n_list), net)}@{relay}'
    return [(1, u(fmt, 1)), (2, u(net, 1)), (3, addr.encode()),
            (4, dkey or pub_of(n_dir)),
            (5, handle_bytes or bytes.fromhex(h16('handle', handle))),
            (6, u(seq, 4)), (7, u(issued, 8))]


def make_card(rec, signer=None, domain=D_LISTING, **kw):
    n_list = kw.get('n_list', 10)
    return signed_items(rec, card_items(**kw), signer or n_list, domain)


def payreq_items(card: bytes, net=0, amount=250_000_000, reqid=0, expires=NOW + 86_400, kind=1,
                 label=b'@alice_test', for_key=None, fmt=1):
    items = [(1, u(fmt, 1)), (2, u(net, 1)), (3, card), (4, u(amount, 8)),
             (5, bytes.fromhex(h16('reqid', reqid))), (6, u(expires, 8)), (7, u(kind, 1))]
    if label is not None:
        items.append((8, label))
    if for_key is not None:
        items.append((9, for_key))
    return items


def make_payreq(rec, card, signer=1, domain=D_PAYREQ, **kw):
    return signed_items(rec, payreq_items(card, **kw), signer, domain)


def ctx_of(net=0, now=NOW, **kw):
    return {'net': net, 'now': now, **kw}


def flip(b: bytes, i: int) -> bytes:
    return b[:i] + bytes([b[i] ^ 1]) + b[i + 1:]


def card_entry(id_, note, raw, rec, ctx):
    f = verify_card(raw, ctx['net'])
    assert encode_card(f) == raw, id_
    return {'id': id_, 'note': note, 'ctx': ctx, 'fields': f, 'hex': raw.hex(),
            'listing_key': key_of_address(f['address']).hex(),
            'listing_code': listing_code(key_of_address(f['address'])),
            'signatures': rec.sigs}


def key_of_address(a: str) -> bytes:
    return addr_parse(a)[1]


def payreq_entry(id_, note, raw, rec, ctx):
    f = verify_payreq(raw, ctx)
    assert encode_payreq(f) == raw, id_
    assert verify_payreq_text(text_of(raw, 'scheme'), ctx) == f
    assert verify_payreq_text(text_of(raw, 'https'), ctx) == f
    return {'id': id_, 'note': note, 'ctx': ctx, 'fields': f, 'hex': raw.hex(),
            'text': {'scheme': text_of(raw, 'scheme'), 'https': text_of(raw, 'https')},
            'signatures': rec.sigs}


def payload_entry(id_, note, raw, rec, ctx):
    f = verify_payload(raw, ctx)
    assert encode_payload(f) == raw, id_
    return {'id': id_, 'note': note, 'type': f['type'], 'ctx': ctx, 'fields': f,
            'hex': raw.hex(), 'signatures': rec.sigs}


def bad_entry(id_, note, kind, data, ctx, error, key='input_hex'):
    verify = {'card': lambda d: verify_card(bytes.fromhex(d), ctx['net']),
              'payreq': lambda d: verify_payreq_text(d, ctx),
              'payload': lambda d: verify_payload(bytes.fromhex(d), ctx)}[kind]
    out = {'id': id_, 'note': note, 'kind': kind, key: data, 'ctx': ctx, 'error': error}
    try:
        got = verify(data)
        assert error is None, (id_, 'accepted but', error)
        out['fields'] = got
    except Err as e:
        assert str(e) == error, (id_, str(e), error)
    return out


def section_k3() -> dict:
    sign, verify = [], []
    msgs = [b'', b'directory vector message', bytes(range(256)) * 2]
    for i, dom in enumerate(DOMAINS):
        for j, m in enumerate(msgs):
            n = 1 + i * 3 + j
            sk, pub = sk_of(n), pub_of(n)
            dg, der = k3_digest(dom, m), k3_sign(sk, dom, m)
            assert k3_verify(pub, dom, m, der)
            e = {'n': n, 'sk': sk.to_bytes(32, 'big').hex(), 'pubkey': pub.hex(),
                 'key_text': key_text(pub, 0), 'domain': dom, 'message': m.hex(),
                 'digest': dg.hex(), 'der': der.hex()}
            sign.append(e)
            verify.append({'key_text': e['key_text'], 'domain': dom, 'message': e['message'],
                           'der': e['der'], 'valid': True})
    e = sign[4]  # a mid-size case for the failing ones
    base = {'key_text': e['key_text'], 'domain': e['domain'], 'message': e['message'],
            'der': e['der']}
    der = bytes.fromhex(e['der'])
    r, s = der_parse(der)
    msg = bytes.fromhex(e['message'])
    for note, change in [
        ('wrong domain', {'domain': D_PAYREQ}),
        ('another key', {'key_text': key_text(pub_of(99), 0)}),
        ('tampered message', {'message': flip(msg, 3).hex()}),
        ('tampered signature', {'der': (der[:10] + bytes([der[10] ^ 1]) + der[11:]).hex()}),
        ('high S, same signature', {'der': der_sig(r, N - s).hex()}),
        ('truncated DER', {'der': e['der'][:-2]}),
    ]:
        v = {**base, **change, 'note': note, 'valid': False}
        assert not k3_verify(key_of_text(v['key_text']), v['domain'], bytes.fromhex(v['message']),
                             bytes.fromhex(v['der'])), note
        verify.append(v)
    return {'tag': K3_TAG.decode(),
            'digest': 'SHA256(SHA256(tag) || SHA256(tag) || u8 len(domain) || domain || message)',
            'sign': sign, 'verify': verify}


def key_of_text(text: str) -> bytes:
    return key_text_parse(text)[1]


def section_key_text() -> list:
    out = []
    for n in range(1, 9):
        pub = pub_of(n)
        m, f = key_text(pub, 0), key_text(pub, 1)
        assert key_text_parse(m) == (0, pub) and key_text_parse(f) == (1, pub)
        out.append({'n': n, 'pubkey': pub.hex(), 'mainnet': m, 'floonet': f})
    return out


def section_codes() -> dict:
    return {
        'directory': [{'dkey': pub_of(n).hex(), **dir_code(pub_of(n))} for n in (1, 2, 3)],
        'listing': [{'key': pub_of(n).hex(), **listing_code(pub_of(n))} for n in (10, 11, 12)],
    }


def card_set() -> list:
    out = []
    rec = Rec()
    out.append(card_entry('card-main', 'mainnet card, relay with a port', make_card(rec), rec,
                          ctx_of()))
    rec = Rec()
    out.append(card_entry('card-main-noport', 'relay without a port',
                          make_card(rec, relay='relay.example', n_list=11, handle=1, seq=7), rec,
                          ctx_of()))
    rec = Rec()
    out.append(card_entry('card-floonet', 'floonet card (key text version 01 88)',
                          make_card(rec, net=1, n_list=12, handle=2), rec, ctx_of(net=1)))
    rec = Rec()
    out.append(card_entry('card-seq-max', 'highest seq, other directory',
                          make_card(rec, n_dir=2, n_list=13, handle=3, seq=0xFFFFFFFF), rec,
                          ctx_of()))
    rec = Rec()
    items = card_items(handle=4)
    items.append((0x90, b'\x01\x02\x03'))
    out.append(card_entry('card-unknown-high-tag', 'unknown tag 90 is skipped and signed',
                          signed_items(rec, items, 10, D_LISTING), rec, ctx_of()))
    rec = Rec()
    long_relay = 'a' * 40 + '.example:65535'
    out.append(card_entry('card-long-address', 'address near the 128-byte limit',
                          make_card(rec, relay=long_relay, handle=5), rec, ctx_of()))
    return out


def good_card_raw(**kw) -> bytes:
    return make_card(Rec(), **kw)


def payreq_set() -> list:
    out = []
    pay_key = pub_of(20).hex()

    def one(id_, note, ctx=None, card_kw=None, **kw):
        rec = Rec()
        card = make_card(rec, **(card_kw or {}))
        raw = make_payreq(rec, card, **kw)
        out.append(payreq_entry(id_, note, raw, rec, ctx or ctx_of()))

    one('req-basic', 'payer-made request, 2.5 EPIC, label')
    one('req-payee', 'payee request for any amount, no label', kind=2, amount=0, label=None,
        reqid=1, card_kw={'n_list': 11, 'handle': 1})
    one('req-for', 'made for one payer: for matches the wallet', reqid=2, for_key=pub_of(20),
        ctx=ctx_of(listing_key=pay_key), card_kw={'handle': 2})
    one('req-floonet', 'floonet request', net=1, reqid=3, card_kw={'net': 1, 'handle': 3},
        ctx=ctx_of(net=1))
    one('req-late-edge', 'now = expires + 120 is not expired', reqid=4, expires=NOW - 120 + 0,
        ctx=ctx_of(), card_kw={'handle': 4})
    one('req-max-label', 'label of 32 characters', reqid=5, label=b'@' + b'a_B9' * 8,
        card_kw={'handle': 5})
    rec = Rec()
    items = payreq_items(make_card(rec, handle=6), reqid=6) + [(0x91, b'\xaa')]
    raw = signed_items(rec, items, 1, D_PAYREQ)
    out.append(payreq_entry('req-unknown-high-tag',
                            'unknown tag 91 in the request is skipped and signed', raw, rec,
                            ctx_of()))
    return out


def payload_set() -> list:
    out = []
    rec = Rec()
    bind = bytes([7, 77, 177, 250])
    hello = signed_items(rec, [(1, b'\x01'), (2, u(0, 1)), (3, pub_of(1)),
                               (4, bytes.fromhex(h16('handle', 0))), (5, bind),
                               (6, u(NOW - 50, 8))], 1, D_HELLO)
    out.append(payload_entry('hello', 'dir-hello, mainnet', hello, rec,
                             ctx_of(bind=bind.hex())))
    rec = Rec()
    hello_f = signed_items(rec, [(1, b'\x01'), (2, u(1, 1)), (3, pub_of(2)),
                                 (4, bytes.fromhex(h16('handle', 1))), (5, bytes([1, 2, 3, 4])),
                                 (6, u(NOW - 50, 8))], 2, D_HELLO)
    out.append(payload_entry('hello-floonet', 'dir-hello, floonet', hello_f, rec,
                             ctx_of(net=1, bind='01020304')))
    rec = Rec()
    hello_np = signed_items(rec, [(1, b'\x01'), (2, u(1, 1)), (3, pub_of(2)),
                                  (4, bytes.fromhex(h16('handle', 1))), (5, bytes([1, 2, 3, 4])),
                                  (6, u(NOW - 50, 8)), (7, u(HELLO_NO_PAYMENTS, 1))], 2, D_HELLO)
    out.append(payload_entry('hello-no-payments', 'dir-hello, floonet, takes no payments',
                             hello_np, rec, ctx_of(net=1, bind='01020304')))
    rec = Rec()
    card = make_card(rec)
    out.append(payload_entry('listing', 'listing: the card', tlv([(1, b'\x02'), (2, card)]), rec,
                             ctx_of(dkey=pub_of(1).hex())))
    rec = Rec()
    addr = f'{key_text(pub_of(10), 0)}@{RELAY}'
    unlist = signed_items(rec, [(1, b'\x03'), (2, u(0, 1)), (3, addr.encode()), (4, pub_of(1)),
                                (5, bytes.fromhex(h16('handle', 0))), (6, u(NOW - 10, 8))],
                          10, D_UNLIST)
    out.append(payload_entry('unlist', 'unlist, signed by the listing key', unlist, rec, ctx_of()))
    rec = Rec()
    out.append(payload_entry('unlisted', 'unlisted, not signed',
                             tlv([(1, b'\x04'), (2, pub_of(1)),
                                  (3, bytes.fromhex(h16('handle', 0))), (4, u(NOW - 5, 8))]),
                             rec, ctx_of()))
    for stage in (1, 2):
        rec = Rec()
        out.append(payload_entry(f'receipt-{stage}', f'receipt, stage {stage}',
                                 tlv([(1, b'\x05'), (2, bytes.fromhex(h16('reqid', 0))),
                                      (3, u(stage, 1)), (4, u(250_000_000, 8)),
                                      (5, u(NOW - 3, 8))]), rec, ctx_of()))
    rec = Rec()
    new_card = make_card(rec, n_list=14, handle=0, seq=2, relay='relay2.example:443')
    old = f'{key_text(pub_of(10), 0)}@{RELAY}'
    moved = signed_items(rec, [(1, b'\x06'), (2, u(0, 1)), (3, old.encode()), (4, new_card)], 10,
                         D_MOVED)
    out.append(payload_entry('moved', 'moved notice, signed by the old listing key', moved, rec,
                             ctx_of()))
    return out


def tamper_sig(raw: bytes) -> bytes:
    """A different last signature byte (the FF field is last)."""
    return flip(raw, len(raw) - 1)


def section_bad() -> list:
    bad = []

    def add(*a, **kw):
        bad.append(bad_entry(*a, **kw))

    # ---- cards
    c = good_card_raw()
    add('card-tamper-seq', 'a byte of seq changed after signing', 'card',
        card_tamper_at_seq(c).hex(), ctx_of(), 'signature')
    add('card-wrong-domain', 'signed under epic-payreq/1', 'card',
        make_card(Rec(), domain=D_PAYREQ).hex(), ctx_of(), 'signature')
    add('card-other-key', 'signed by a key other than the one in 03', 'card',
        make_card(Rec(), signer=15).hex(), ctx_of(), 'signature')
    add('card-wrong-network', 'floonet card checked by a mainnet wallet', 'card',
        good_card_raw(net=1).hex(), ctx_of(net=0), 'network')
    other_net_addr = f'{key_text(pub_of(10), 1)}@{RELAY}'
    add('card-address-other-network', 'net 0 but the key text of 03 is floonet', 'card',
        make_card(Rec(), address=other_net_addr).hex(), ctx_of(), 'network')
    add('card-unknown-low-tag', 'unknown tag 0A is rejected', 'card',
        signed_items(Rec(), card_items() + [(0x0A, b'x')], 10, D_LISTING).hex(), ctx_of(),
        'malformed')
    items = card_items()
    add('card-out-of-order', 'tags 05 and 04 swapped', 'card',
        signed_items(Rec(), items[:3] + [items[4], items[3]] + items[5:], 10, D_LISTING).hex(),
        ctx_of(), 'malformed')
    add('card-duplicate-tag', 'tag 07 twice', 'card',
        signed_items(Rec(), items + [items[-1]], 10, D_LISTING).hex(), ctx_of(), 'malformed')
    add('card-trailing-bytes', 'one byte after the signature', 'card', (c + b'\x00').hex(),
        ctx_of(), 'malformed')
    add('card-truncated', 'cut inside the signature', 'card', c[:-5].hex(), ctx_of(), 'malformed')
    add('card-format-2', 'format 2', 'card', make_card(Rec(), fmt=2).hex(), ctx_of(), 'malformed')
    add('card-short-handle', 'handle of 15 bytes', 'card',
        make_card(Rec(), handle_bytes=bytes(15)).hex(), ctx_of(), 'malformed')
    add('card-no-signature', 'no FF field', 'card', tlv(items).hex(), ctx_of(), 'malformed')
    add('card-short-signature', 'signature of 7 bytes', 'card',
        tlv(items + [(0xFF, bytes(7))]).hex(), ctx_of(), 'malformed')
    add('card-long-signature', 'signature of 73 bytes', 'card',
        tlv(items + [(0xFF, bytes(73))]).hex(), ctx_of(), 'malformed')
    add('card-bad-key-text', 'a character of the key text changed', 'card',
        make_card(Rec(), address='1' + f'{key_text(pub_of(10), 0)}'[1:] + '@' + RELAY).hex(),
        ctx_of(), 'malformed')
    for n, err in ((128, None), (129, 'malformed')):
        relay = 'r' * (n - len(key_text(pub_of(10), 0)) - 1)
        add(f'card-address-{n}', f'address of {n} bytes',
            'card', make_card(Rec(), relay=relay).hex(), ctx_of(), err)
    add('card-unknown-high-tag-ok', 'unknown tag 90 is accepted', 'card',
        signed_items(Rec(), items + [(0x90, b'zz')], 10, D_LISTING).hex(), ctx_of(), None)

    # ---- payment requests
    rec = Rec()
    card = make_card(rec)
    req = make_payreq(rec, card)
    good = text_of(req, 'scheme')
    p = good.split('pay/1/')[1]
    mid = len(p) // 2
    altered = p[:mid] + ('A' if p[mid] != 'A' else 'B') + p[mid + 1:]
    add('req-bad-checksum', 'a character in the middle changed', 'payreq',
        'epiccash://pay/1/' + altered, ctx_of(), 'checksum', key='input_text')
    add('req-bad-base64', 'a character outside the base64url set', 'payreq',
        'epiccash://pay/1/' + p[:10] + '!' + p[11:], ctx_of(), 'checksum', key='input_text')
    add('req-cut-short', 'eight characters missing at the end', 'payreq',
        'epiccash://pay/1/' + p[:-8], ctx_of(), 'checksum', key='input_text')
    add('req-no-marker', 'no pay/1/ or p#1/ in the text', 'payreq', 'epiccash://pair/1/' + p,
        ctx_of(), 'malformed', key='input_text')

    def mk(**kw):
        r = Rec()
        return make_payreq(r, kw.pop('card', None) or make_card(r), **kw)

    def txt(raw, form='scheme'):
        return text_of(raw, form)

    def addp(id_, note, raw, error, ctx=None, form='scheme'):
        add(id_, note, 'payreq', txt(raw, form), ctx or ctx_of(), error, key='input_text')

    # tampering with the checksum recomputed
    addp('req-tamper-amount', 'a byte of amount changed', tamper_req(req, 'amount'), 'signature')
    addp('req-tamper-card', 'a byte of the embedded card changed', tamper_req(req, 'card'),
         'signature')
    addp('req-tamper-dsig', 'the last signature byte changed', tamper_sig(req), 'signature')
    addp('req-wrong-domain', 'dsig made under epic-listing/1', mk(domain=D_LISTING), 'signature')
    addp('req-other-signer', 'dsig made by a key other than the card dkey', mk(signer=2),
         'signature')
    r = Rec()
    other_dir_card = make_card(r, n_dir=2)
    addp('req-card-other-dkey', 'card is for directory 2, request signed by directory 1',
         make_payreq(r, other_dir_card, signer=1), 'signature')
    r = Rec()
    bad_card = card_tamper_at_seq(make_card(r))
    addp('req-card-bad-sig', 'card with a changed seq, the request signed over it',
         make_payreq(r, bad_card), 'signature')
    r = Rec()
    addp('req-card-wrong-domain', 'card signed under epic-payreq/1, request valid',
         make_payreq(r, make_card(r, domain=D_PAYREQ)), 'signature')
    addp('req-wrong-network', 'floonet request, mainnet wallet',
         mk(net=1, card=make_card(Rec(), net=1)), 'network')
    addp('req-net-differs-from-card', 'request net 1 over a net 0 card', mk(net=1), 'network',
         ctx_of(net=1))
    addp('req-card-key-other-network', 'card address holds a floonet key text',
         mk(card=make_card(Rec(), address=other_net_addr)), 'network')
    exp = NOW + 86_400
    addp('req-expired', 'now = expires + 121', mk(expires=exp), 'expired',
         ctx_of(now=exp + 121))
    addp('req-expired-edge-ok', 'now = expires + 120 is accepted', mk(expires=exp), None,
         ctx_of(now=exp + 120))
    addp('req-for-other', 'made for another payer', mk(for_key=pub_of(21)), 'for_other',
         ctx_of(listing_key=pub_of(20).hex()))
    addp('req-for-no-listing-key', 'for present, the wallet has no listing key',
         mk(for_key=pub_of(20)), 'for_other')
    addp('req-for-bad-prefix', 'for is not a compressed key', mk(for_key=b'\x05' + bytes(32)),
         'malformed', ctx_of(listing_key=pub_of(20).hex()))
    addp('req-for-me-ok', 'made for this wallet', mk(for_key=pub_of(20)), None,
         ctx_of(listing_key=pub_of(20).hex()))
    # order: expired is checked before for_other
    addp('req-expired-and-for-other', 'both: expired is reported', mk(expires=exp,
         for_key=pub_of(21)), 'expired', ctx_of(now=exp + 500, listing_key=pub_of(20).hex()))

    def mkitems(items, signer=1):
        return signed_items(Rec(), items, signer, D_PAYREQ)

    cardb = make_card(Rec())
    base = payreq_items(cardb)
    addp('req-unknown-low-tag', 'unknown tag 0A', mkitems(base + [(0x0A, b'x')]), 'malformed')
    addp('req-unknown-high-tag-ok', 'unknown tag 92 is accepted',
         mkitems(base + [(0x92, b'x')]), None)
    addp('req-out-of-order', 'tags 04 and 05 swapped',
         mkitems(base[:3] + [base[4], base[3]] + base[5:]), 'malformed')
    addp('req-duplicate-tag', 'tag 04 twice', mkitems(base[:4] + [base[3]] + base[4:]),
         'malformed')
    addp('req-trailing-bytes', 'bytes after the signature', mk() + b'\x00\x00', 'malformed')
    addp('req-format-2', 'format 2', mk(fmt=2), 'malformed')
    addp('req-kind-3', 'kind 3', mk(kind=3), 'malformed')
    addp('req-short-amount', 'amount of 4 bytes', mkitems(base[:3] + [(4, bytes(4))] + base[4:]),
         'malformed')
    addp('req-no-card', 'tag 03 missing', mkitems(base[:2] + base[3:]), 'malformed')
    addp('req-bad-card', 'tag 03 holds bytes that are no card', mkitems(base[:2] + [(3, b'\x01')]
         + base[3:]), 'malformed')
    addp('req-no-signature', 'no FF field', tlv(base), 'malformed')
    for slug, note, lab in [('33', 'a label of 33 characters', b'@' + b'a' * 33),
                            ('no-at', 'no @', b'alice_test'),
                            ('space', 'a character outside the set', b'@ali ce'),
                            ('only-at', 'only @', b'@'), ('non-ascii', 'not ASCII', '@élise'.encode())]:
        addp('req-label-' + slug, f'bad label ({note}): accepted, label dropped',
             mkitems(payreq_items(cardb, label=lab)), None)
    addp('req-https-form', 'https text form, any host', mk(), None, form='https')

    # ---- payloads
    ctx = ctx_of(bind=bytes([7, 77, 177, 250]).hex(), dkey=pub_of(1).hex())
    hello_items = [(1, b'\x01'), (2, u(0, 1)), (3, pub_of(1)),
                   (4, bytes.fromhex(h16('handle', 0))), (5, bytes([7, 77, 177, 250])),
                   (6, u(NOW - 50, 8))]
    hello = signed_items(Rec(), hello_items, 1, D_HELLO)

    def addl(id_, note, raw, error):
        add(id_, note, 'payload', raw.hex(), ctx, error)

    addl('hello-tamper', 'a byte of handle changed', flip(hello, 3 + 1 + 3 + 1 + 3 + 33 + 3 + 3),
         'signature')
    addl('hello-wrong-domain', 'signed under epic-listing/1',
         signed_items(Rec(), hello_items, 1, D_LISTING), 'signature')
    addl('hello-other-signer', 'signed by another key', signed_items(Rec(), hello_items, 2,
         D_HELLO), 'signature')
    addl('hello-wrong-network', 'net 1 to a mainnet wallet',
         signed_items(Rec(), [(1, b'\x01'), (2, u(1, 1))] + hello_items[2:], 1, D_HELLO),
         'network')
    addl('hello-wrong-bind', 'bind differs from the pairing check',
         signed_items(Rec(), hello_items[:4] + [(5, bytes([7, 77, 177, 251]))] + hello_items[5:],
                      1, D_HELLO), 'bind')
    addl('hello-short-bind', 'bind of 3 bytes',
         signed_items(Rec(), hello_items[:4] + [(5, bytes(3))] + hello_items[5:], 1, D_HELLO),
         'malformed')
    addl('hello-no-signature', 'no FF field', tlv(hello_items), 'malformed')
    addl('hello-flags-unknown-bit', 'flags 0x02: an unknown bit',
         signed_items(Rec(), hello_items + [(7, u(2, 1))], 1, D_HELLO), 'malformed')
    addl('hello-flags-short', 'flags of 0 bytes',
         signed_items(Rec(), hello_items + [(7, b'')], 1, D_HELLO), 'malformed')
    addl('hello-trailing', 'a byte after the signature', hello + b'\x00', 'malformed')
    addl('payload-empty', 'no bytes', b'', 'malformed')
    addl('payload-type-not-first', 'tag 02 first', tlv([(2, b'\x00')]), 'malformed')
    addl('payload-unknown-type-ok', 'type 99 is acknowledged and dropped',
         tlv([(1, b'\x63'), (2, b'whatever')]), None)
    r = Rec()
    other_card = make_card(r, n_dir=2)
    addl('listing-other-dkey', 'card is for directory 2', tlv([(1, b'\x02'), (2, other_card)]),
         'dkey')
    addl('listing-tampered-card', 'card with a changed seq',
         tlv([(1, b'\x02'), (2, card_tamper_at_seq(make_card(Rec())))]), 'signature')
    addl('listing-wrong-network', 'floonet card',
         tlv([(1, b'\x02'), (2, make_card(Rec(), net=1))]), 'network')
    addl('listing-bad-card', 'not a card', tlv([(1, b'\x02'), (2, b'\x01\x00')]), 'malformed')
    addr = f'{key_text(pub_of(10), 0)}@{RELAY}'
    ul_items = [(1, b'\x03'), (2, u(0, 1)), (3, addr.encode()), (4, pub_of(1)),
                (5, bytes.fromhex(h16('handle', 0))), (6, u(NOW - 10, 8))]
    unlist = signed_items(Rec(), ul_items, 10, D_UNLIST)
    addl('unlist-tamper', 'a byte of issued changed', tamper_issued(unlist), 'signature')
    addl('unlist-signed-by-dkey', 'signed by the directory key, not the listing key',
         signed_items(Rec(), ul_items, 1, D_UNLIST), 'signature')
    addl('unlist-wrong-domain', 'signed under epic-listing/1',
         signed_items(Rec(), ul_items, 10, D_LISTING), 'signature')
    addl('unlist-wrong-network', 'net 1', signed_items(Rec(), [ul_items[0], (2, u(1, 1))]
         + ul_items[2:], 10, D_UNLIST), 'network')
    addl('unlist-address-other-network', 'floonet key text in 03', signed_items(Rec(),
         ul_items[:2] + [(3, f'{key_text(pub_of(10), 1)}@{RELAY}'.encode())] + ul_items[3:], 10,
         D_UNLIST), 'network')
    unlisted = tlv([(1, b'\x04'), (2, pub_of(1)), (3, bytes.fromhex(h16('handle', 0))),
                    (4, u(NOW, 8))])
    addl('unlisted-trailing', 'a byte after the last field', unlisted + b'\x00', 'malformed')
    addl('unlisted-short-dkey', 'dkey of 32 bytes',
         tlv([(1, b'\x04'), (2, pub_of(1)[1:]), (3, bytes.fromhex(h16('handle', 0))),
              (4, u(NOW, 8))]), 'malformed')
    addl('receipt-stage-3', 'stage 3', tlv([(1, b'\x05'), (2, bytes(16)), (3, b'\x03'),
                                           (4, u(1, 8)), (5, u(NOW, 8))]), 'malformed')
    addl('receipt-missing-at', 'tag 05 missing', tlv([(1, b'\x05'), (2, bytes(16)), (3, b'\x01'),
                                                     (4, u(1, 8))]), 'malformed')
    r = Rec()
    new_card = make_card(r, n_list=14, seq=2, relay='relay2.example:443')
    mv_items = [(1, b'\x06'), (2, u(0, 1)), (3, addr.encode()), (4, new_card)]
    addl('moved-tamper-sig', 'last signature byte changed',
         tamper_sig(signed_items(Rec(), mv_items, 10, D_MOVED)), 'signature')
    addl('moved-wrong-domain', 'signed under epic-listing/1',
         signed_items(Rec(), mv_items, 10, D_LISTING), 'signature')
    addl('moved-other-signer', 'signed by the new key, not the old one',
         signed_items(Rec(), mv_items, 14, D_MOVED), 'signature')
    addl('moved-bad-new-card', 'the new card has a changed seq',
         signed_items(Rec(), mv_items[:3] + [(4, card_tamper_at_seq(new_card))], 10, D_MOVED),
         'signature')
    addl('moved-wrong-network', 'floonet notice', signed_items(Rec(), [mv_items[0], (2, u(1, 1))]
         + mv_items[2:], 10, D_MOVED), 'network')
    return bad


def field_offset(raw: bytes, tag: int) -> int:
    for t, v, start in parse_tlv(raw):
        if t == tag:
            return start + 3
    raise KeyError(tag)


def card_tamper_at_seq(card: bytes) -> bytes:
    return flip(card, field_offset(card, 6) + 3)


def tamper_issued(raw: bytes) -> bytes:
    return flip(raw, field_offset(raw, 6) + 7)


def tamper_req(raw: bytes, what: str) -> bytes:
    if what == 'amount':
        return flip(raw, field_offset(raw, 4) + 7)
    at = field_offset(raw, 3)  # the card's own seq, inside the request
    n = raw[at - 2] << 8 | raw[at - 1]
    return flip(raw, at + field_offset(raw[at:at + n], 6) + 3)


def build() -> str:
    doc = {
        'spec': 'docs/design/directory-wire.md',
        'sas_table': 'app/lib/src/sas_table.dart (LEPIC testdata/sas/emoji-v1.txt)',
        'link_host': 'links.example (a placeholder: the router never checks the host)',
        'key_derivation': 'sk_n = SHA256("directory vector key " || decimal n), as a 32-byte '
                          'big-endian scalar',
        'errors': ['checksum', 'malformed', 'network', 'signature', 'expired', 'for_other',
                   'bind', 'dkey'],
        'k3': section_k3(),
        'key_text': section_key_text(),
        'codes': section_codes(),
        'cards': card_set(),
        'payreqs': payreq_set(),
        'payloads': payload_set(),
        'bad': section_bad(),
    }
    return json.dumps(doc, indent=2, ensure_ascii=False) + '\n'


# ---------------------------------------------------------------- LEPIC cross-check

def lepic_check(k3check: str, doc: dict) -> bool:
    def run(*args):
        return subprocess.run([k3check, *args], capture_output=True, text=True, check=True,
                               timeout=60).stdout.split()

    sigs = [(s['sk'], s['domain'], s['message'], s['der']) for s in doc['k3']['sign']]
    n_k3 = len(sigs)
    for sect in ('cards', 'payreqs', 'payloads'):
        for e in doc[sect]:
            sigs += [(s['sk'], s['domain'], s['message'], s['der']) for s in e['signatures']]
    sigs = list(dict.fromkeys(sigs))  # the same signature in two entries is checked once
    ok, fails = 0, []
    for sk, dom, msg, der in sigs:
        d, pub, main, floo = run('sign', sk, dom, msg)
        mine = compress(pt_mul(int(sk, 16), G))
        good = d == der and pub == mine.hex() and main == key_text(mine, 0) \
            and floo == key_text(mine, 1)
        v = run('verify', main, dom, msg, der)
        if good and v == ['true']:
            ok += 1
        else:
            fails.append((sk[:8], dom, d == der, v))
    print(f'sign: {ok}/{len(sigs)} signatures identical to LEPIC (DER, pubkey, both key texts); '
          f'{n_k3} of them from the k3 section')
    vok = 0
    for v in doc['k3']['verify']:
        got = run('verify', v['key_text'], v['domain'], v['message'], v['der'])
        if got == [str(v['valid']).lower()]:
            vok += 1
        else:
            fails.append((v.get('note', 'good'), v['domain'], got, v['valid']))
    print(f"verify: {vok}/{len(doc['k3']['verify'])} k3 verdicts equal LEPIC's "
          f"({sum(1 for v in doc['k3']['verify'] if v['valid'])} true, "
          f"{sum(1 for v in doc['k3']['verify'] if not v['valid'])} false)")
    for f in fails:
        print('FAIL', f, file=sys.stderr)
    return not fails


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--lepic', metavar='K3CHECK')
    args = ap.parse_args()
    text = build()
    doc = json.loads(text)
    if args.lepic:
        return 0 if lepic_check(args.lepic, doc) else 1
    if args.check:
        if OUT.read_text() != text:
            print(f'{OUT} is out of date: run tools/directory_vectors.py', file=sys.stderr)
            return 1
        return 0
    OUT.write_text(text)
    print({k: len(v) for k, v in doc.items() if isinstance(v, list)})
    return 0


if __name__ == '__main__':
    sys.exit(main())
