# SPDX-License-Identifier: Apache-2.0
"""E4 live test: drive the Linux desktop app in the trust-linux sandbox over AT-SPI.

    TRUST_SB=<sandbox> python3 -I dk.py text | tree | click <re:pattern> | fill <n> <text> | key <k> | scroll <dir> [n] | wait <pattern> [s]

The sandbox is started with tools/rellib/drivers/linux/sandbox.py (start, then app <sandbox> <AppDir>);
see e4_live.sh.
"""
import os
import sys

root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
sys.path.insert(0, os.path.join(root, "tools", "rellib", "drivers", "linux"))
import ui  # noqa: E402

c, a = sys.argv[1], sys.argv[2:]
if c == "fill":
    ui.fill(int(a[0]), a[1])
elif c == "key":
    ui.key(*a)
elif c == "wait":
    ui.wait(a[0], float(a[1]) if len(a) > 1 else 30)
elif c == "click":
    print(ui.click(a[0], timeout=float(a[1]) if len(a) > 1 else 20))
elif c == "text":
    print("\n".join(t.replace("\n", " | ") for t in ui.texts()))
elif c == "tree":
    for n in ui.nodes():
        if n.name or n.actions or n.value or "editable" in n.states:
            print(n)
elif c == "scroll":
    ui.scroll(a[0], int(a[1]) if len(a) > 1 else 5)
else:
    sys.exit(__doc__)
