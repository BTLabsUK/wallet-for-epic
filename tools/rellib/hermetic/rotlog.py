#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Copy stdin to a log file capped in size: rotlog.py <file> <max MB> <files kept>.

At <max MB> the file moves to <file>.1 (and .1 to .2, ...), keeping <files kept> old ones, so a
service's log never takes more than (files kept + 1) × max MB. Line-buffered: a line is on disk as
soon as the service writes it, so a lane's window can be read while the service runs.
"""
import os
import sys


def rotate(path, keep):
    for i in range(keep, 0, -1):
        src = path if i == 1 else "%s.%d" % (path, i - 1)
        if os.path.exists(src):
            os.replace(src, "%s.%d" % (path, i))


def main(path, max_mb, keep):
    cap = int(float(max_mb) * 1048576)
    keep = int(keep)
    out = open(path, "ab", buffering=0)
    for line in sys.stdin.buffer:
        if out.tell() + len(line) > cap and out.tell() > 0:
            out.close()
            rotate(path, keep)
            out = open(path, "ab", buffering=0)
        out.write(line)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
