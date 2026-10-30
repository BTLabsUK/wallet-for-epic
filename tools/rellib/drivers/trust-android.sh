#!/usr/bin/env bash
# G4 update trust, Android: a user on the PREVIOUS release who updates to the CANDIDATE keeps the
# wallet, its balance and history, their own node and Epicbox relay, and their settings; then the
# candidate sends to and receives from P through Epicbox. Driven on an emulator with uiautomator
# (tools/rellib/drivers/android/trust.py).
#
# Environment (the runner's contract):
#   REL_PREVIOUS_DIR, REL_PREVIOUS_VERSION   previous release folder (emulator/epic-cash-mobile-<v>[-notor]-x86_64.apk)
#   REL_CANDIDATE_DIR, REL_CANDIDATE_VERSION candidate's published files
#   REL_CANDIDATE_EXTRA                      candidate's non-published folder (emulator/…x86_64.apk)
#   REL_VARIANT        tor | notor
#   REL_CHECKS         comma list of checks that must be true (default: all eight)
#   REL_FUNDS          1 = also send_ok / receive_ok, 0 = data checks only
#   REL_NODE           node to type in, e.g. https://node.btlabs.uk (unset: health pick below)
#   REL_EPICBOX        Epicbox relay to type in, e.g. epicbox.stackwallet.com (unset: health pick)
#   REL_OUT            proof.json, logs and screenshots go here
#   REL_DRY_RUN=1      print the plan, touch nothing, exit 0
# Optional:
#   REL_ANDROID_SERIAL a running emulator to use (else REL_ANDROID_AVD, default wfe_api36, is
#                      started read-only and headless on port REL_ANDROID_PORT, default 5580, and
#                      stopped at the end)
#   REL_TRUST_STATE    where the test wallet's phrase and PIN are kept (mode 600; default
#                      ~/.config/btlabs/rel-trust-android); empty = a new wallet funded from P
#   REL_P_*            P settings, see android/pfund.py
# Exit: 0 every check in REL_CHECKS true; 1 some false (not proven); 2 could not run.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
drv="$here/android"
sdk="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
export ADB="${ADB:-$sdk/platform-tools/adb}"
CHECKS_ALL=wallet_opens,balance_kept,history_kept,custom_nodes_kept,custom_relays_kept,settings_kept,send_ok,receive_ok
export REL_CHECKS="${REL_CHECKS:-$CHECKS_ALL}"
export REL_FUNDS="${REL_FUNDS:-1}" REL_VARIANT="${REL_VARIANT:-tor}"
dry="${REL_DRY_RUN:-0}"

say() { echo "trust-android: $*" >&2; }
cannot() { # reason: write a fail-closed proof (when REL_OUT is known) and exit 2
  say "cannot run: $1"
  if [[ -n "${REL_OUT:-}" && "$dry" != 1 ]]; then
    mkdir -p "$REL_OUT" && python3 -I "$drv/trust.py" fail "$1" >/dev/null 2>&1
  fi
  exit 2
}

[[ -n "${REL_OUT:-}" ]] || cannot "REL_OUT is not set"
case "$REL_VARIANT" in tor | notor) ;; *) cannot "REL_VARIANT must be tor or notor, not '$REL_VARIANT'" ;; esac

# The x86_64 emulator APK of a release folder for the variant.
apk_in() { # dir version
  local d=$1 v=$2 f
  [[ -d "$d/emulator" ]] || return 1
  for f in "$d/emulator/epic-cash-mobile-$v"{,-notor}-x86_64.apk "$d"/emulator/epic-cash-mobile-*-x86_64.apk; do
    [[ -f "$f" ]] || continue
    if [[ "$REL_VARIANT" == notor ]]; then [[ "$f" == *-notor-x86_64.apk ]] || continue
    else [[ "$f" != *-notor-x86_64.apk ]] || continue; fi
    echo "$f"; return 0
  done
  return 1
}
# A dry run comes before the builds: a missing APK is named in the plan, not an error.
prev_apk="$(apk_in "${REL_PREVIOUS_DIR:-/nonexistent}" "${REL_PREVIOUS_VERSION:-}")" ||
  if [[ "$dry" == 1 ]]; then prev_apk="<not found: ${REL_PREVIOUS_DIR:-REL_PREVIOUS_DIR unset}/emulator>"; else
  cannot "no previous $REL_VARIANT x86_64 APK under ${REL_PREVIOUS_DIR:-<REL_PREVIOUS_DIR unset>}/emulator"; fi
cand_apk="$(apk_in "${REL_CANDIDATE_EXTRA:-/nonexistent}" "${REL_CANDIDATE_VERSION:-}" ||
  apk_in "${REL_CANDIDATE_DIR:-/nonexistent}" "${REL_CANDIDATE_VERSION:-}")" ||
  if [[ "$dry" == 1 ]]; then cand_apk="<not built yet: ${REL_CANDIDATE_EXTRA:-REL_CANDIDATE_EXTRA}/emulator>"; else
  cannot "no candidate $REL_VARIANT x86_64 APK under REL_CANDIDATE_EXTRA/emulator or REL_CANDIDATE_DIR/emulator"; fi
export REL_PREVIOUS_APK="$prev_apk" REL_CANDIDATE_APK="$cand_apk"

# Health pick, BT Labs first, when the runner gave none.
node_ok() { curl -fsS -m 10 "$1/v1/status" 2>/dev/null | grep -q '"height"'; }
relay_ok() {
  [[ "$(curl -s -m 10 -o /dev/null -w '%{http_code}' -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
    -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' "https://$1/")" == 101 ]]
}
picked=""
if [[ -z "${REL_NODE:-}" ]]; then
  for n in https://node.btlabs.uk https://node.epicnet.us:3413 https://node.epiccash.com:3413; do
    if [[ "$dry" == 1 ]] || node_ok "$n"; then REL_NODE=$n; break; fi
  done
  [[ -n "${REL_NODE:-}" ]] || cannot "no node answered (node.btlabs.uk, node.epicnet.us:3413, node.epiccash.com:3413)"
  picked+=" node"
fi
if [[ -z "${REL_EPICBOX:-}" ]]; then
  for r in epicbox.stackwallet.com epicbox.epicnet.us epicbox.epiccash.com; do
    if [[ "$dry" == 1 ]] || relay_ok "$r"; then REL_EPICBOX=$r; break; fi
  done
  [[ -n "${REL_EPICBOX:-}" ]] || cannot "no Epicbox relay answered"
  picked+=" epicbox"
fi
export REL_NODE REL_EPICBOX
[[ -n "$picked" ]] && say "health pick (${picked# }$([[ "$dry" == 1 ]] && echo ", dry run: first in line, not checked")): node $REL_NODE, epicbox $REL_EPICBOX"

avd="${REL_ANDROID_AVD:-wfe_api36}" port="${REL_ANDROID_PORT:-5580}"
if [[ "$dry" == 1 ]]; then
  cat <<EOF
trust-android plan ($REL_VARIANT, funds=$REL_FUNDS, required: $REL_CHECKS)
  emulator   ${REL_ANDROID_SERIAL:-start AVD $avd read-only, headless, emulator-$port; stopped at the end}
  1 install  adb uninstall uk.btlabs.epiccash.mobile; adb install $prev_apk
  2 wallet   restore the test wallet from ${REL_TRUST_STATE:-~/.config/btlabs/rel-trust-android}/phrase (none: create one, keep its phrase, P funds it)
  3 user     node $REL_NODE typed in and in use; relay $REL_EPICBOX typed in and in use;
             Theme ${REL_TRUST_THEME:-Dark}, Technical details on, Confirmations ${REL_TRUST_CONFIRMATIONS:-4}
  4 digest   address, Total/Spendable, Activity rows, Node and Epicbox lists, settings
  5 update   adb install -r $cand_apk  (same signature, as the in-app updater's PackageInstaller)
  6 open     launch, unlock with the PIN, digest again, compare
  7 funds    $( [[ "$REL_FUNDS" == 1 ]] && echo "under flock ${REL_P_LOCK:-/opt/epic/qa-funder/.rel-lock}: send ${REL_TRUST_SEND:-0.01} to P, receive ${REL_TRUST_RECEIVE:-0.02} from P, by Epicbox" || echo "skipped (REL_FUNDS=0)")
  out        $REL_OUT/proof.json, driver.log, screens.log, p.log, shots/
EOF
  exit 0
fi

mkdir -p "$REL_OUT" || exit 2
[[ -x "$ADB" ]] || cannot "adb not found at $ADB"
started=""
stop_emu() {
  if [[ -n "$started" ]]; then
    "$ADB" -s "emulator-$port" emu kill >/dev/null 2>&1
    for _ in $(seq 1 30); do kill -0 "$started" 2>/dev/null || break; sleep 1; done
    kill "$started" 2>/dev/null
  fi
}
trap stop_emu EXIT
if [[ -n "${REL_ANDROID_SERIAL:-}" ]]; then
  [[ "$("$ADB" -s "$REL_ANDROID_SERIAL" get-state 2>/dev/null)" == device ]] ||
    cannot "emulator $REL_ANDROID_SERIAL is not online"
else
  "$ADB" devices | grep -q "^emulator-$port\b" && cannot "emulator-$port is already in use (set REL_ANDROID_SERIAL or REL_ANDROID_PORT)"
  "$sdk/emulator/emulator" -list-avds 2>/dev/null | grep -qx "$avd" || cannot "no AVD $avd"
  setsid "$sdk/emulator/emulator" -avd "$avd" -read-only -no-window -no-audio -no-boot-anim \
    -port "$port" -gpu swiftshader_indirect >"$REL_OUT/emulator.log" 2>&1 </dev/null &
  started=$!
  export REL_ANDROID_SERIAL="emulator-$port"
  booted=""
  for _ in $(seq 1 90); do
    [[ "$("$ADB" -s "$REL_ANDROID_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]] && { booted=1; break; }
    kill -0 "$started" 2>/dev/null || break
    sleep 2
  done
  [[ -n "$booted" ]] || cannot "emulator $avd did not boot (see $REL_OUT/emulator.log)"
  "$ADB" -s "$REL_ANDROID_SERIAL" shell settings put global window_animation_scale 0 >/dev/null 2>&1
  "$ADB" -s "$REL_ANDROID_SERIAL" shell settings put global transition_animation_scale 0 >/dev/null 2>&1
fi
say "previous $prev_apk"
say "candidate $cand_apk"
say "serial $REL_ANDROID_SERIAL, node $REL_NODE, epicbox $REL_EPICBOX, out $REL_OUT"
python3 -I "$drv/trust.py" run
rc=$?
case $rc in 0 | 1 | 2) ;; *) rc=2 ;; esac
say "exit $rc ($( ((rc == 0)) && echo proven || { ((rc == 1)) && echo 'not proven' || echo 'could not run'; }))"
exit $rc
