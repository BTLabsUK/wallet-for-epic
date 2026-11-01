#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Fresh app data on wfe_qa, floonet dev settings, restore from PHRASE_FILE, PIN 123456.
set -e
ROOT=$(cd "$(dirname "$0")/../../.." && pwd); . "$ROOT/tools/env.sh"
S=emulator-5556; P=uk.btlabs.epiccash.mobile; H=$(dirname "$0"); APP=$ROOT/app
PH() { if [ "$1" = tap ]; then "$H/ph.sh" wait "$2" 60 >/dev/null; fi; "$H/ph.sh" "$@"; }
adb -s $S shell pm clear $P >/dev/null
adb -s $S shell "run-as $P sh -c 'mkdir -p files/dev/floonet'"
for f in settings.default.toml app-config.toml; do adb -s $S shell "run-as $P sh -c 'cat > files/dev/floonet/$f'" < $APP/tool/config/floonet/$f; done
adb -s $S shell am start -n $P/.MainActivity >/dev/null; sleep 12
PH wait "Create a new wallet" 90 >/dev/null
PH tap "Deep end" >/dev/null; sleep 1
PH tap "Create a new wallet" >/dev/null; sleep 3
PH tap "Node and Epicbox" >/dev/null; sleep 2; PH tap "Network" >/dev/null; sleep 2; PH tap "Floonet" >/dev/null; sleep 3
PH tap "Restore from phrase" >/dev/null; sleep 3
adb -s $S shell input tap 540 450; sleep 1
python3 -I - "${PHRASE_FILE:?}" <<'PY'
import subprocess,sys,os
adb=os.path.expanduser("~/Android/Sdk/platform-tools/adb")
for w in open(sys.argv[1]).read().split():
    subprocess.run([adb,"-s","emulator-5556","shell","input","text",w]); subprocess.run([adb,"-s","emulator-5556","shell","input","keyevent","62"])
PY
sleep 1; PH key 4 >/dev/null; sleep 1; PH tap "Continue" >/dev/null; sleep 3
adb -s $S shell input tap 540 940; adb -s $S shell input text 123456; sleep 2; adb -s $S shell input text 123456
PH wait "Your wallet is restored" 120 >/dev/null; PH tap "Not now" >/dev/null; sleep 4; PH tap "Skip tour" >/dev/null 2>&1 || true
echo restored
