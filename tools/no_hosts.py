# SPDX-License-Identifier: Apache-2.0
"""The scanner behind tools/check-no-hosts.sh: "All configuration in settings.toml (no hardcoded
configuration)".

Reads NUL-separated paths (relative to <dir>) on stdin, prints every line that names a host,
a URL with a literal host, an IPv4 address, an onion address, a port or an HTTP API path, and
exits 1 when there is one. Ports: `:NNNN` inside a string, a port-named variable, parameter or
field set to a number, and the Epic ports anywhere (comments too); 80 and 443 are the web's own
(protocol) and pass. API paths: a string literal starting `/v1/`, `/v2/` or `/api/`.

Usage: python3 -I no_hosts.py <label> <dir> <allow file>

The allow file holds `<glob>\t<regex>` lines (glob over `<label>/<path>`); text the regex
matches in a file the glob matches is taken out before the checks. A comment line above each
says why.
"""

import fnmatch
import os
import re
import sys

# Endings that are a host whenever they end a dotted lower-case name.
STRONG = 'com|uk|us|org|io|tech|cash|xyz|eu'
# Endings that are also common field or file names (`p.net`, `invite.id`, `libtor.so`): a host
# only with two labels before it (`epic-node.iniaku.my.id`), inside a string or a comment, not
# an interpolation (`${a.b.id}`) and never followed by `(`. A one-label one (`t.me`) is caught
# in a URL.
WEAK = 'cloud|money|finance|exchange|pool|biz|club|net|id|me|de|pl|ru|cn|th|app|dev|co|to|is|sh|so|ai|gg|pro|ch|link|network|my|info|online|site|space'

LABEL = r'(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)'
STRONG_RE = re.compile(r'(?<![A-Za-z0-9_.\-])(' + LABEL + r'+)(' + STRONG + r')(?![A-Za-z0-9_\-])')
WEAK_RE = re.compile(r'(?<![A-Za-z0-9_.\-${])(' + LABEL + r'{2,})(' + WEAK + r')(?![A-Za-z0-9_\-(])')
URL_RE = re.compile(r'\b(?:https?|wss?)://([A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+)')
IP_RE = re.compile(r'(?<![0-9.])((?:25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])(?:\.(?:25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])){3})(?![0-9.])')
ONION_RE = re.compile(r'[a-z2-7]{56}\.onion', re.IGNORECASE)

# The ports of Epic's node, wallet listener, stratum and Epicbox on each chain.
EPIC_PORTS = '3413|3414|3415|3416|3420|3423|13413|13414|13415|13416|23413|23414|23415|23416'
EPIC_PORT_RE = re.compile(r'(?<![0-9A-Za-z_.])(' + EPIC_PORTS + r')(?![0-9])')
# `host:NNNN` in a string: after a name character, not part of a time (`13:58:01`) or a version.
STRING_PORT_RE = re.compile(r'(?<=[A-Za-z0-9\]}])\:([0-9]{2,5})(?![0-9:.])')
# `port = 3415`, `this.port = 3415`, `httpPort: 3415`, `"port": 3415`, `port_number = 3415`.
NAMED_PORT_RE = re.compile(
    r'(?<![A-Za-z0-9_])(?:[a-z][A-Za-z0-9_]*Port|[pP]ort)(?:_?[A-Za-z0-9_]*)?["\']?\s*(?:=(?!=)|:)\s*([0-9]+)(?![0-9.])')
API_PATH_RE = re.compile(r'[\'"]/(?:v[0-9]+|api)/')
# The web's own ports: protocol, not configuration.
PROTOCOL_PORTS = {80, 443}

OK_HOST = re.compile(
    r'^(?:localhost|(?:[a-z0-9-]+\.)*example(?:\.(?:com|org|net))?|(?:[a-z0-9-]+\.)+(?:invalid|test|localhost|example|local|lan|internal|home\.arpa))$',
    re.IGNORECASE)


def ok_ip(ip):
    """Loopback, every-interface, private, shared, link-local and documentation ranges: never a
    server the wallet is pointed at."""
    a = [int(x) for x in ip.split('.')]
    return (a[0] in (0, 10, 127) or a[:2] == [192, 168] or (a[0] == 172 and 16 <= a[1] <= 31)
            or (a[0] == 100 and 64 <= a[1] <= 127) or a[:2] == [169, 254]
            or a[:3] == [192, 0, 2] or a[:3] == [198, 51, 100] or a[:3] == [203, 0, 113])


def ok_host(h):
    h = h.lower().rstrip('.')
    if IP_RE.fullmatch(h):
        return ok_ip(h)
    if re.fullmatch(r'[0-9.]+', h):
        return True  # the start of an address built at run time (`http://192.168.$x`)
    return bool(OK_HOST.match(h))


def port_findings(text):
    """The port and API path findings of one line (a string's port and the API path only inside a
    string literal)."""
    out = []
    for m in EPIC_PORT_RE.finditer(text):
        out.append(f'port {m.group(1)}')
    for m in STRING_PORT_RE.finditer(text):
        p = int(m.group(1))
        if 80 <= p <= 65535 and p not in PROTOCOL_PORTS and in_text(text, m.start(), strings_only=True) \
                and host_before(text, m.start()):
            out.append(f'port :{p}')
    for m in NAMED_PORT_RE.finditer(text):
        p = int(m.group(1))
        if 0 < p <= 65535 and p not in PROTOCOL_PORTS and not in_text(text, m.start(1), strings_only=True) and not is_comment(text, m.start(1)):
            out.append(f'port {m.group(0).strip()}')
    for m in API_PATH_RE.finditer(text):
        if in_text(text, m.start() + 1, strings_only=True):
            out.append(f'API path {text[m.start() + 1:m.start() + 24].split(chr(39))[0].split(chr(34))[0]}')
    return out


def host_before(line, pos):
    """Whether the text before the `:` at [pos] is a host: a dotted name or address,
    `localhost`, an IPv6 address in brackets, or an interpolation (`${host}`). An id such as
    `l:103` is not."""
    if line[pos - 1] in ']}':
        return True
    start = pos
    while start > 0 and re.match(r'[A-Za-z0-9.\-_]', line[start - 1]):
        start -= 1
    token = line[start:pos]
    return '.' in token or token.lower() == 'localhost'


def is_comment(line, pos):
    """Whether [pos] of [line] is in a comment (the line is one, or one starts before it outside a
    string)."""
    return in_text(line, pos) and not in_text(line, pos, strings_only=True)


def findings(text):
    out = port_findings(text)
    text = text.replace('\\.', '.')  # a host written as a regex (`fastepic\.eu`)
    for m in ONION_RE.finditer(text):
        out.append(m.group(0))
    for m in URL_RE.finditer(text):
        if not ok_host(m.group(1)):
            out.append(m.group(0))
    for m in IP_RE.finditer(text):
        if not ok_ip(m.group(1)):
            out.append(m.group(1))
    for m in STRONG_RE.finditer(text):
        if not ok_host(m.group(0)):
            out.append(m.group(0))
    for m in WEAK_RE.finditer(text):
        if in_text(text, m.start()) and not ok_host(m.group(0)):
            out.append(m.group(0))
    return out


def in_text(line, pos, strings_only=False):
    """Whether [pos] is inside a string literal or a comment of [line] (one line, so a string
    or a block comment that started on an earlier line is not seen). [strings_only]: inside a
    string literal only."""
    if re.match(r'\s*(\*|#|///|//)', line):
        return not strings_only
    quote = None
    i = 0
    while i < pos:
        c = line[i]
        if quote:
            if c == '\\':
                i += 1
            elif c == quote:
                quote = None
        elif c in '\'"`':
            quote = c
        elif line.startswith('//', i) or line.startswith('/*', i):
            return not strings_only
        i += 1
    return quote is not None


def load_allow(path):
    rules = []
    try:
        with open(path, encoding='utf-8') as f:
            for line in f:
                line = line.rstrip('\n')
                if not line.strip() or line.lstrip().startswith('#'):
                    continue
                glob, _, rx = line.partition('\t')
                rules.append((glob, re.compile(rx)))
    except FileNotFoundError:
        pass
    return rules


def main():
    label, base, allow_path = sys.argv[1:4]
    rules = load_allow(allow_path)
    paths = [p for p in sys.stdin.buffer.read().decode('utf-8').split('\0') if p]
    bad = 0
    for rel in paths:
        name = f'{label}/{rel}'
        mine = [rx for glob, rx in rules if fnmatch.fnmatch(name, glob)]
        try:
            with open(os.path.join(base, rel), encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
        except (IsADirectoryError, FileNotFoundError):
            continue
        for n, line in enumerate(lines, 1):
            text = line.rstrip('\n')
            for rx in mine:
                text = rx.sub(' ', text)
            hits = findings(text)
            if hits:
                bad += 1
                print(f'{name}:{n}: {", ".join(dict.fromkeys(hits))}')
    if bad:
        print(f'FAIL {label}: {bad} line(s)')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
