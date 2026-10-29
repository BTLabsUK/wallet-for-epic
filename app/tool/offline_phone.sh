#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Phone offline check: integration_test/offline_phone_test.dart on an emulator of its own in
# airplane mode from the first start; when the test asks (want-up in the app's external files
# folder), airplane mode goes off and the test checks the wallet recovers by itself.
#
#   tool/offline_phone.sh            AVD wfe_small (OFFLINE_AVD) on port 5560 (OFFLINE_PORT),
#                                    started read-only and headless, killed at the end.
#
# Never uses 5554 (wfe_api36), 5556 (wfe_qa) or 5558 (wfe_qa2): other work runs there. The app
# is uninstalled first (a fresh first start). Run it through build-slot (gradle builds the
# debug APK). Env: RC_OUT (default $TMPDIR) gets the log, results and shots/phone.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$(cd "$here/.." && pwd)/tools/env.sh"
OUT="${RC_OUT:-${TMPDIR:-$HOME/.cache/release-check}}"
AVD="${OFFLINE_AVD:-wfe_small}"
PORT="${OFFLINE_PORT:-5560}"
case "$PORT" in 5554|5556|5558) echo "port $PORT belongs to other work" >&2; exit 2 ;; esac
SER="emulator-$PORT"
PKG=uk.btlabs.epiccash.mobile
EXT="/sdcard/Android/data/$PKG/files"
mkdir -p "$OUT/shots/phone"
a() { timeout 60 adb -s "$SER" "$@"; }

adb devices | grep -q "^$SER" && { echo "$SER is already running: not ours" >&2; exit 3; }
emu=""; watcher=""
cleanup() {
  [ -n "$watcher" ] && kill "$watcher" 2>/dev/null
  timeout 20 adb -s "$SER" emu kill >/dev/null 2>&1
  [ -n "$emu" ] && { sleep 3; kill "$emu" 2>/dev/null; }
}
trap cleanup EXIT INT TERM

emulator -avd "$AVD" -port "$PORT" -no-window -no-audio -gpu swiftshader_indirect -read-only -no-snapshot \
  > "$OUT/emulator-$PORT.log" 2>&1 &
emu=$!
timeout 120 adb -s "$SER" wait-for-device || { echo "emulator did not come up" >&2; exit 3; }
for _ in $(seq 1 120); do
  [ "$(a shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break
  sleep 2
done
[ "$(a shell getprop sys.boot_completed | tr -d '\r')" = 1 ] || { echo "emulator did not boot" >&2; exit 3; }
echo "$SER booted ($AVD)"

a uninstall "$PKG" >/dev/null 2>&1
a shell cmd connectivity airplane-mode enable
a shell svc wifi disable; a shell svc data disable
sleep 3
if a shell ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
  echo "airplane mode left the network up: stopping" >&2; exit 3
fi
echo "airplane mode on, no network on $SER"

(
  until a shell "test -e $EXT/want-up" 2>/dev/null; do kill -0 $$ 2>/dev/null || exit 0; sleep 2; done
  a shell cmd connectivity airplane-mode disable
  a shell svc wifi enable; a shell svc data enable
  echo "airplane mode off at $(date +%T)"
  a shell "touch $EXT/up"
) &
watcher=$!

cd "$here"
timeout 2400 flutter test -d "$SER" integration_test/offline_phone_test.dart 2>&1 | tee "$OUT/offline_phone.log" |
  grep --line-buffered -E '^(RC |VISIT )|[0-9]+:[0-9]+ \+|Error|Exception' | tail -200
rc="${PIPESTATUS[0]}"
a pull "$EXT/shots" "$OUT/shots/phone" >/dev/null 2>&1
grep -h '^RC ' "$OUT/offline_phone.log" | sed 's/^RC //' > "$OUT/offline-phone-results.txt"
echo "results: $(grep -c '^PASS' "$OUT/offline-phone-results.txt") pass, $(grep -c '^FAIL' "$OUT/offline-phone-results.txt") fail ($OUT/offline-phone-results.txt)"
exit "$rc"
