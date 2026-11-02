#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# E4 step 5: how long a backgrounded phone (screen off, unplugged) keeps answering payments.
# Needs: wfe_qa on 5556 with the wallet unlocked, the desktop app stopped, a funded CLI wallet
# (cli_pay.sh) and ADDR_FILE with the shared address. Sends 1 EPIC at each offset (minutes) after
# the phone went to the background and reports whether the phone received the slate and when.
set -u
# SPDX-License-Identifier: Apache-2.0
H=$(cd "$(dirname "$0")" && pwd); S=emulator-5556; P=uk.btlabs.btwallet
. "$(cd "$H/../../.." && pwd)/tools/env.sh"
OFFSETS=${OFFSETS:-"1 5 15 30 60"}
say() { echo "LIVE $(date -u +%T) $*"; }
plog() { adb -s $S shell "run-as $P cat files/logs/wfe.log" 2>/dev/null; }
[ "${PLUGGED:-0}" = 1 ] || adb -s $S shell dumpsys battery unplug
adb -s $S shell input keyevent KEYCODE_HOME; sleep 2
adb -s $S shell input keyevent KEYCODE_SLEEP
T0=$(date +%s); say "phone backgrounded, screen off, battery unplugged"
for off in $OFFSETS; do
  now=$(( $(date +%s) - T0 )); wait=$(( off*60 - now )); [ $wait -gt 0 ] && sleep $wait
  before=$(plog | grep -c "stage=S1")
  ts=$(date -u +%T); say "t=${off}min sending"
  "$H/cli_pay.sh" "$(cat "$ADDR_FILE")" 1 "bg-$off" | sed 's/^/   cli: /'
  got=MISS
  for i in $(seq 1 24); do
    sleep 5
    if [ "$(plog | grep -c 'stage=S1')" -gt "$before" ]; then got=$(plog | grep "stage=S1" | tail -1 | cut -c1-24); break; fi
  done
  say "t=${off}min sent $ts phone S1: $got"
done
adb -s $S shell dumpsys battery reset; adb -s $S shell input keyevent KEYCODE_WAKEUP
say "done"
