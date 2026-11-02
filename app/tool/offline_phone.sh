#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Phone offline check: integration_test/offline_phone_test.dart on an emulator of its own in
# airplane mode from the first start; when the test asks (want-up in the app's files/rc-offline,
# read with run-as), airplane mode goes off and the test checks the wallet recovers by itself.
#
#   tool/offline_phone.sh            AVD wfe_small (OFFLINE_AVD) on port 5560 (OFFLINE_PORT),
#                                    started read-only and headless, killed at the end.
#                                    OFFLINE_DEVICE_PIN: the AVD's screen-lock PIN (1111).
#
# OFFLINE_KILL_PROOF=1: the network-mode proof instead (integration_test/net_modes_phone_test.dart):
# the network stays ON, the app starts in Kill switch, and every packet its uid sends is counted
# (adb root, an iptables/ip6tables owner rule, loopback left out, put in the moment the package is installed; DNS
# counts too, as Android's resolver sends on the asking app's uid). Zero is the pass.
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
PKG=uk.btlabs.btwallet
EXT="files/rc-offline"   # run-as $PKG: relative to the app's data folder
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

# An app launched under the lock screen never starts (flutter test then waits for ever). The AVD
# may have a screen lock (wfe_small's PIN is 1111): it is typed in, and the screen stays on to
# the end. The emulator runs read-only, so nothing of this stays.
a shell svc power stayon true
locked() { a shell dumpsys window | grep -q 'isKeyguardShowing=true'; }
sleep 5
for _ in 1 2 3; do
  locked || break
  a shell input keyevent 224; a shell input keyevent 82; sleep 1
  a shell input text "${OFFLINE_DEVICE_PIN:-1111}"; a shell input keyevent 66; sleep 3
done
if locked; then
  echo "the screen stays locked: set OFFLINE_DEVICE_PIN to the AVD's screen-lock PIN" >&2; exit 3
fi

a uninstall "$PKG" >/dev/null 2>&1
if [ "${OFFLINE_KILL_PROOF:-0}" = 1 ]; then
  a root >/dev/null 2>&1; sleep 3; timeout 60 adb -s "$SER" wait-for-device
  a shell ping -c 1 -W 5 1.1.1.1 >/dev/null 2>&1 || { echo "the emulator has no network: the proof needs one" >&2; exit 3; }
  echo "network on, counting the app's packets"
  (
    # The counting rule goes in as soon as the package has a uid, before its first frame.
    uid=""
    until [ -n "$uid" ]; do
      kill -0 $$ 2>/dev/null || exit 0
      uid="$(a shell pm list packages -U "$PKG" 2>/dev/null | tr -d '\r' | sed -n "s/^package:$PKG uid://p")"
      [ -n "$uid" ] || sleep 0.2
    done
    for t in iptables ip6tables; do a shell "$t -I OUTPUT 1 ! -o lo -m owner --uid-owner $uid -j ACCEPT"; done
    echo "$uid" > "$OUT/app-uid"
    echo "counting packets of uid $uid from $(date +%T)"
  ) &
  watcher=$!
  cd "$here"
  timeout 2400 flutter test --no-uninstall -d "$SER" integration_test/net_modes_phone_test.dart 2>&1 | tee "$OUT/net_modes_phone.log" |
    grep --line-buffered -E '^(RC )|[0-9]+:[0-9]+ \+|Error|Exception' | tail -200
  rc="${PIPESTATUS[0]}"
  uid="$(cat "$OUT/app-uid" 2>/dev/null)"
  {
    echo "app uid: ${uid:-NOT FOUND}"
    for t in iptables ip6tables; do
      echo "$t:"; a shell "$t -L OUTPUT -v -n -x" | grep -E "owner UID match $uid|pkts" | tr -d '\r'
    done
  } | tee "$OUT/kill-proof-counters.txt"
  grep -h '^RC ' "$OUT/net_modes_phone.log" | sed 's/^RC //' > "$OUT/net-modes-phone-results.txt"
  echo "results: $(grep -c '^PASS' "$OUT/net-modes-phone-results.txt") pass, $(grep -c '^FAIL' "$OUT/net-modes-phone-results.txt") fail"
  exit "$rc"
fi
a shell cmd connectivity airplane-mode enable
a shell svc wifi disable; a shell svc data disable
sleep 3
if a shell ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
  echo "airplane mode left the network up: stopping" >&2; exit 3
fi
echo "airplane mode on, no network on $SER"

(
  until a shell run-as "$PKG" test -e "$EXT/want-up" 2>/dev/null; do kill -0 $$ 2>/dev/null || exit 0; sleep 2; done
  a shell cmd connectivity airplane-mode disable
  a shell svc wifi enable; a shell svc data enable
  echo "airplane mode off at $(date +%T)"
  a shell run-as "$PKG" touch "$EXT/up"
) &
watcher=$!

cd "$here"
# Kept installed after the test, so its screenshots can be read out of its folder.
timeout 2400 flutter test --no-uninstall -d "$SER" integration_test/offline_phone_test.dart 2>&1 | tee "$OUT/offline_phone.log" |
  grep --line-buffered -E '^(RC |VISIT )|[0-9]+:[0-9]+ \+|Error|Exception' | tail -200
rc="${PIPESTATUS[0]}"
timeout 60 adb -s "$SER" exec-out run-as "$PKG" tar cf - -C "$EXT" shots 2>/dev/null | tar xf - -C "$OUT/shots/phone" 2>/dev/null
grep -h '^RC ' "$OUT/offline_phone.log" | sed 's/^RC //' > "$OUT/offline-phone-results.txt"
echo "results: $(grep -c '^PASS' "$OUT/offline-phone-results.txt") pass, $(grep -c '^FAIL' "$OUT/offline-phone-results.txt") fail ($OUT/offline-phone-results.txt)"
exit "$rc"
