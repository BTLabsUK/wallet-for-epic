#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Keeps the app's old names and pinned upstream versions out of the docs.

The app is BT Wallet. Its names up to 26.10.24 (Epic Cash Desktop, Epic Cash Mobile, their file
names and app ids) stay only where they are history or compatibility: moving from an old install,
old file names the tools must still recognise, fixtures of old installs. Each file that may name
them is listed in tools/doc-names.allow with the number of mentions it holds, so a new mention
anywhere fails until someone adds it there on purpose.

`versions` globs in the allow file also fail on a written-out Epic node or epic-wallet version
(4.1.0, v4.1.1): the docs say "the latest release" and link it, or link the file holding a pin.

Usage: tools/check-doc-names.py [--root <repo>]   (default: the repository this script is in)

tools/doc-names.allow, one entry per line, `#` comments:
  scan <glob>         files to check for old names (git-tracked paths, fnmatch, ** allowed)
  versions <glob>     files to check for upstream version numbers
  <path> <count>      a file allowed exactly <count> lines with old names (the reason above it)
"""
import argparse
import fnmatch
import os
import re
import subprocess
import sys

OLD = re.compile(r'Epic ?Cash ?(Desktop|Mobile)|EpicCash(Desktop|Mobile)|epic-cash-(desktop|mobile)'
                 r'|epiccash\.mobile|epiccashmobile|epiccashwallet|com\.blacktyger\.epiccash')
# An Epic node or epic-wallet version written next to its name: "node v4.1.0", "epic 4.1.1".
UPSTREAM = re.compile(r'(?i)(epic-wallet|\bnode\b|\bepic\b)[^\n]{0,60}?\bv?[34]\.\d+\.\d+\b'
                      r'|\bv?[34]\.\d+\.\d+\b[^\n]{0,30}?(epic-wallet|\bnode\b)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    root = ap.parse_args().root
    scan, versions, allowed = [], [], {}
    with open(os.path.join(root, 'tools', 'doc-names.allow'), encoding='utf-8') as f:
        for n, line in enumerate(f, 1):
            line = line.split('#', 1)[0].split()
            if not line:
                continue
            if len(line) == 2 and line[0] in ('scan', 'versions'):
                (scan if line[0] == 'scan' else versions).append(line[1])
            elif len(line) == 2 and line[1].isdigit():
                allowed[line[0]] = int(line[1])
            else:
                sys.exit(f'tools/doc-names.allow:{n}: not "scan <glob>", "versions <glob>" or "<path> <count>"')
    files = subprocess.run(['git', '-C', root, 'ls-files', '-z'], capture_output=True, text=True,
                           check=True).stdout.split('\0')
    fail = []

    def match(path, globs):
        return any(fnmatch.fnmatch(path, g) for g in globs)

    def lines(path):
        try:
            with open(os.path.join(root, path), encoding='utf-8') as f:
                return list(enumerate(f, 1))
        except (UnicodeDecodeError, FileNotFoundError):
            return []

    me = os.path.realpath(__file__)
    for path in files:
        if os.path.realpath(os.path.join(root, path)) == me:
            continue  # this file: the old names are its patterns
        if match(path, scan):
            hits = [(n, l) for n, l in lines(path) if OLD.search(l)]
            want = allowed.get(path, 0)
            if len(hits) != want:
                fail.append(f'{path}: {len(hits)} lines with an old app name, the allow file says {want}')
                if len(hits) > want:
                    fail += [f'  {path}:{n}: {l.strip()[:140]}' for n, l in hits]
        if match(path, versions):
            fail += [f'{path}:{n}: upstream version written out (say "the latest release" and link it): '
                     f'{l.strip()[:140]}' for n, l in lines(path) if UPSTREAM.search(l)]
    stale = [p for p in allowed if p not in files]
    fail += [f'tools/doc-names.allow: {p} is not in the repository' for p in stale]
    if fail:
        print('\n'.join(fail))
        print('Old names: use BT Wallet. Where the old name is history or compatibility, add or update '
              'the file\'s line in tools/doc-names.allow with the reason.')
        return 1
    print(f'doc names: ok ({sum(match(p, scan) for p in files)} files, {len(allowed)} allowed)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
