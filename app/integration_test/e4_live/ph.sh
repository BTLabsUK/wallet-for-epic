#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# E4 live test: drive the phone (wfe_qa, emulator-5556) with uiautomator through tools/rellib/drivers/android/ph.py.
#   ph.sh text | tap <text> | wait <text> [secs] | type <text> | key <code> | shot <png>
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
export ROOT
exec python3 -I -c '
import os, sys
sys.path.insert(0, os.path.join(os.environ["ROOT"], "tools/rellib/drivers/android"))
import ph
S = os.environ.get("E4_SERIAL", "emulator-5556")
c, a = sys.argv[1], sys.argv[2:]
if c == "text": ph.show(ph.nodes(S))
elif c == "tap": ph.tap(S, a[0])
elif c == "wait": print(ph.wait(S, a[0], int(a[1]) if len(a) > 1 else 60))
elif c == "type": ph.type_text(S, a[0])
elif c == "key": ph.key(S, a[0])
elif c == "shot": ph.shot(S, a[0])
' "$@"
