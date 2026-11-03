#!/usr/bin/env bash
# G4 update trust, Android: a user on the PREVIOUS release who updates to the CANDIDATE keeps the
# wallet, its balance and history, their own node and Epicbox relay, and their settings; then the
# candidate sends to and receives from P through Epicbox. Driven on an emulator with uiautomator by
# the shared core (android/lane.py: core/lane.py, core/phone.py, android/android_platform.py);
# REL_TRUST_DRIVER=v1 runs the old android/trust.py instead.
#
# Environment (the runner's contract):
#   REL_PREVIOUS_DIR, REL_PREVIOUS_VERSION   previous release folder (emulator/bt-wallet-<v>[-notor]-android-x86_64.apk,
#                                            or epic-cash-mobile-<v>[-notor]-x86_64.apk before the rename)
#   REL_PREVIOUS_EXTRA                       previous run's non-published folder (emulator/…x86_64.apk), looked in first:
#                                            a release tools/rel published keeps its emulator APKs there, not in files/
#   REL_CANDIDATE_DIR, REL_CANDIDATE_VERSION candidate's published files
#   REL_CANDIDATE_EXTRA                      candidate's non-published folder (emulator/…x86_64.apk)
#   REL_VARIANT        tor | notor
#   REL_CHECKS         comma list of checks that must be true (default, android/lane.py: all eight but settings_kept,
#                      without send_ok,receive_ok when REL_FUNDS=0, and for a candidate from 26.10.25 the four
#                      migration checks: store_encrypted, app_files_kept, lan_nodes_kept, contact_note_kept;
#                      v1: all eight, and the four migration checks)
#   REL_FUNDS          1 = also receive from and send to P with the candidate; 0 = not (P still funds the
#                      previous release's wallet and the balance goes back to P; v1: data checks only)
#   REL_NODE           node to type in, e.g. https://node.btlabs.uk (unset: health pick below)
#   REL_EPICBOX        Epicbox relay to type in, e.g. epicbox.stackwallet.com (unset: health pick)
#   REL_OUT            result.txt, proof.json, trust.log and shots/ go here (v1: proof.json, logs, shots/
#                      and screens/, the catalogue: screens.json + PNGs)
#   REL_DRY_RUN=1      print the plan, touch nothing, exit 0
# Optional:
#   REL_ANDROID_SERIAL a running emulator to use (else REL_ANDROID_AVD, default wfe_trust_<variant>
#                      (v1: wfe_api36, read-only), is started headless on port REL_ANDROID_PORT,
#                      default 5580 for tor and 5582 for notor, and stopped at the end;
#                      REL_ANDROID_KEEP=1 leaves it running)
#   REL_TRUST_START    auto | state | fresh, REL_TRUST_SAVE_STATE, REL_TRUST_STATE_ROOT: saved end
#                      states (core/state.py; on Android an emulator snapshot of the AVD)
#   REL_TRUST_MODE     create: only the candidate, installed fresh, and a new wallet made on it (no
#                      previous release, no update, no funds; v2 only)
#   REL_TRUST_BREAK    break tests (core/breaks.py); never in a release run
#   REL_TRUST_STATE    (v1) where the test wallet's phrase and PIN are kept (mode 600; default
#                      ~/.config/btlabs/rel-trust-android for tor, ~/.config/btlabs/rel-wallet-q
#                      for notor: wallet Q, docs/RELEASING.md "Test wallets"); empty = a new
#                      wallet funded from P. One run per wallet at a time (flock on its .lock).
#   REL_P_*            P settings, see linux/p_funder.py (v1: android/pfund.py)
# Exit: 0 every check in REL_CHECKS true; 1 some false (not proven); 2 could not run.
# Also writes $REL_OUT/emulator.json (boot time, booted, alive at the end) for the runner's metrics.
set -uo pipefail
# Break tests (core/breaks.py) never run in a release run; the engine sets REL_RUN_KIND=release for one.
if [ "${REL_RUN_KIND:-}" = release ] && [ -n "${REL_TRUST_BREAK:-}" ]; then
  echo "trust-android: REL_TRUST_BREAK is set in a release run: break tests run in --test runs only" >&2; exit 2
fi
here="$(cd "$(dirname "$0")" && pwd)"
drv="$here/android"
sdk="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
export ADB="${ADB:-$sdk/platform-tools/adb}"
v1=0
[[ "${REL_TRUST_DRIVER:-v2}" == v1 ]] && v1=1
# v2's default checks are android/lane.py's (settings_kept not among them: the theme and Technical details are
# in Keystore-encrypted storage, the LEPIC CLI does not report the confirmations, the phone has no wallets.json
# label; the proof says so). v1 reads them off the screens.
if [[ $v1 == 1 ]]; then
  CHECKS_ALL=wallet_opens,balance_kept,history_kept,custom_nodes_kept,custom_relays_kept,settings_kept,send_ok,receive_ok
  # A candidate that encrypts the wallet database (26.10.25 on) must also pass the migration checks.
  if [[ "$(printf '%s\n' 26.10.25 "${REL_CANDIDATE_VERSION:-0}" | sort -V | head -1)" == 26.10.25 ]]; then
    CHECKS_ALL+=,store_encrypted,app_files_kept,lan_nodes_kept,contact_note_kept
  fi
  export REL_CHECKS="${REL_CHECKS:-$CHECKS_ALL}"
fi
export REL_FUNDS="${REL_FUNDS:-1}" REL_VARIANT="${REL_VARIANT:-tor}"
dry="${REL_DRY_RUN:-0}"

say() { echo "trust-android: $*" >&2; }
cannot() { # reason: write a fail-closed proof (when REL_OUT is known) and exit 2
  say "cannot run: $1"
  if [[ -n "${REL_OUT:-}" && "$dry" != 1 ]]; then
    mkdir -p "$REL_OUT" && python3 -I "$drv/$([[ $v1 == 1 ]] && echo trust.py || echo lane.py)" fail "$1" >/dev/null 2>&1
  fi
  exit 2
}

[[ -n "${REL_OUT:-}" ]] || cannot "REL_OUT is not set"
case "$REL_VARIANT" in tor | notor) ;; *) cannot "REL_VARIANT must be tor or notor, not '$REL_VARIANT'" ;; esac
# Each variant its own test wallet and emulator, so the two run at the same time.
if [[ "$REL_VARIANT" == notor ]]; then
  export REL_TRUST_STATE="${REL_TRUST_STATE:-$HOME/.config/btlabs/rel-wallet-q}"; default_port=5582
else
  export REL_TRUST_STATE="${REL_TRUST_STATE:-$HOME/.config/btlabs/rel-trust-android}"; default_port=5580
fi

# The x86_64 emulator APK of a release folder for the variant: bt-wallet-<v>[-notor]-android-x86_64.apk,
# or epic-cash-mobile-<v>[-notor]-x86_64.apk in a release made before the rename.
apk_in() { # dir version
  local d=$1 v=$2 f
  [[ -d "$d/emulator" ]] || return 1
  for f in "$d/emulator/bt-wallet-$v"{,-notor}-android-x86_64.apk "$d/emulator/epic-cash-mobile-$v"{,-notor}-x86_64.apk \
      "$d"/emulator/bt-wallet-*-android-x86_64.apk "$d"/emulator/epic-cash-mobile-*-x86_64.apk; do
    [[ -f "$f" ]] || continue
    if [[ "$REL_VARIANT" == notor ]]; then [[ "$(basename "$f")" == *-notor-* ]] || continue
    else [[ "$(basename "$f")" != *-notor-* ]] || continue; fi
    echo "$f"; return 0
  done
  return 1
}
# A dry run comes before the builds: a missing APK is named in the plan, not an error.
create=0
[[ "${REL_TRUST_MODE:-}" == create ]] && create=1
prev_apk="$(apk_in "${REL_PREVIOUS_EXTRA:-/nonexistent}" "${REL_PREVIOUS_VERSION:-}" ||
  apk_in "${REL_PREVIOUS_DIR:-/nonexistent}" "${REL_PREVIOUS_VERSION:-}")" ||
  if [[ $create == 1 && $v1 == 0 ]]; then prev_apk="<not used: REL_TRUST_MODE=create>"; elif [[ "$dry" == 1 ]]; then prev_apk="<not found: ${REL_PREVIOUS_DIR:-REL_PREVIOUS_DIR unset}/emulator>"; else
  cannot "no previous $REL_VARIANT x86_64 APK under REL_PREVIOUS_EXTRA/emulator (${REL_PREVIOUS_EXTRA:-unset}) or ${REL_PREVIOUS_DIR:-<REL_PREVIOUS_DIR unset>}/emulator"; fi
cand_apk="$(apk_in "${REL_CANDIDATE_EXTRA:-/nonexistent}" "${REL_CANDIDATE_VERSION:-}" ||
  apk_in "${REL_CANDIDATE_DIR:-/nonexistent}" "${REL_CANDIDATE_VERSION:-}")" ||
  if [[ "$dry" == 1 ]]; then cand_apk="<not built yet: ${REL_CANDIDATE_EXTRA:-REL_CANDIDATE_EXTRA}/emulator>"; else
  cannot "no candidate $REL_VARIANT x86_64 APK under REL_CANDIDATE_EXTRA/emulator or REL_CANDIDATE_DIR/emulator"; fi
export REL_PREVIOUS_APK="$prev_apk" REL_CANDIDATE_APK="$cand_apk"
# The package of each APK (aapt2 badging). They differ across the 26.10.25 app id change
# (uk.btlabs.epiccash.mobile → uk.btlabs.btwallet, authorised 2026-11-02): trust.py then installs
# the candidate beside the previous app instead of over it.
apk_pkg() { # apk → package, or nothing
  local a; a="$(ls -d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1)"
  [[ -f "$1" && -n "$a" ]] && "$a" dump badging "$1" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p"
}
prev_pkg="$(apk_pkg "$prev_apk")" cand_pkg="$(apk_pkg "$cand_apk")"
beside=0
[[ -n "$prev_pkg" && -n "$cand_pkg" && "$prev_pkg" != "$cand_pkg" ]] && beside=1

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

port="${REL_ANDROID_PORT:-$default_port}"
if [[ $v1 == 0 ]]; then
  avd="${REL_ANDROID_AVD:-wfe_trust_$REL_VARIANT}"
  if [[ "$dry" == 1 && $create == 1 ]]; then
    cat <<EOF
trust-android plan (v2, $REL_VARIANT, mode=create, required: ${REL_CHECKS:-$(python3 -I "$drv/lane.py" checks)})
  emulator   ${REL_ANDROID_SERIAL:-start AVD $avd headless (writable), emulator-$port; stopped at the end}
  create     adb uninstall; adb install $cand_apk; create a wallet (PIN, phrase read and dropped); Home
  out        $REL_OUT/result.txt, proof.json, trust.log, shots/, logcat.txt, emulator.json
EOF
    exit 0
  fi
  if [[ "$dry" == 1 ]]; then
    cat <<EOF
trust-android plan (v2, $REL_VARIANT, funds=$REL_FUNDS, required: ${REL_CHECKS:-$(python3 -I "$drv/lane.py" checks)})
  emulator   ${REL_ANDROID_SERIAL:-start AVD $avd headless (writable), emulator-$port; stopped at the end}
  signer     both APKs must carry the same certificate (apksigner); it goes in proof.json and the saved state
  start      ${REL_TRUST_START:-auto}: a saved $REL_VARIANT state of ${REL_PREVIOUS_VERSION:-?} (emulator snapshot) when one fits, else fresh
  fresh      adb uninstall; adb install $prev_apk; create a wallet (PIN, phrase read off Settings › Security);
             node $REL_NODE and Epicbox $REL_EPICBOX in use, loopback stand-ins added (adb reverse); Light, 1 confirmation, Technical details on
  fund       P pays the wallet (every lane); digest from the app's files (adb root)
  update     app stopped; adb install -r $cand_apk
  candidate  launch, unlock with the PIN; digest again; compare
  funds      $( [[ "$REL_FUNDS" == 1 ]] && echo "receive from P and send to P by Epicbox; everything back to P" || echo "everything back to P (REL_FUNDS=0: not checked)")
  out        $REL_OUT/result.txt, proof.json, trust.log, shots/, logcat.txt, emulator.json
EOF
    exit 0
  fi
  mkdir -p "$REL_OUT" || exit 2
  # One lane per emulator: the AVD's disk and snapshots are the lane's.
  lockdir="$HOME/.cache/rel-trust-android"
  mkdir -p -m 700 "$lockdir" && exec 8>>"$lockdir/$avd.lock" || cannot "cannot open $lockdir/$avd.lock"
  flock -n 8 || { say "AVD $avd in use: waiting for its lock"; flock -w 3600 8; } || cannot "AVD $avd busy for an hour"
  export REL_ANDROID_AVD="$avd" REL_ANDROID_PORT="$port"
  say "previous $prev_apk"
  say "candidate $cand_apk"
  python3 -I "$drv/lane.py" >"$REL_OUT/lane.out" 2>&1
  rc=$?
  case $rc in 0 | 1 | 2) ;; *) rc=2 ;; esac
  [[ -f "$REL_OUT/result.txt" ]] && say "$(cat "$REL_OUT/result.txt")"
  say "exit $rc ($( ((rc == 0)) && echo proven || { ((rc == 1)) && echo 'not proven' || echo 'could not run'; }))"
  exit $rc
fi
avd="${REL_ANDROID_AVD:-wfe_api36}"
if [[ "$dry" == 1 ]]; then
  cat <<EOF
trust-android plan ($REL_VARIANT, funds=$REL_FUNDS, required: $REL_CHECKS)
  emulator   ${REL_ANDROID_SERIAL:-start AVD $avd read-only, headless, emulator-$port; stopped at the end}
  packages   previous ${prev_pkg:-?}, candidate ${cand_pkg:-?}$([[ $beside == 1 ]] && echo ": different, the candidate goes in BESIDE the previous app (5 and 6 below)")
  1 install  adb uninstall ${prev_pkg:-<previous package>} (and ${cand_pkg:-<candidate package>}); adb install $prev_apk
  2 wallet   restore the test wallet from $REL_TRUST_STATE/phrase (none: create one, keep its phrase, P funds it); holds $REL_TRUST_STATE/.lock
             a first-start level picker ("Pick your view", builds that have one): Deep end (level 3), Undercover off
  3 user     node $REL_NODE typed in and in use; relay $REL_EPICBOX typed in and in use;
             Theme ${REL_TRUST_THEME:-Dark}, Technical details on, Confirmations ${REL_TRUST_CONFIRMATIONS:-1}
  4 digest   address, Total/Spendable, Activity rows, Node and Epicbox lists, settings
  4b seed    (candidate 26.10.25 on) app stopped, adb root: a contact in contacts.json, a note in wfe_meta.json, the stand-in node in lan_nodes.json; file set read
  5 update   adb install -r $cand_apk  (same signature, as the in-app updater's PackageInstaller)
  6 open     launch, unlock with the PIN, digest again, compare; the level picker showing = wallet_opens false;
             a candidate with levels must read level 3 in Settings › Advanced (settings_kept; proof "levels")
  6b files   (candidate 26.10.25 on) wallet.enc.sqlite3 + .check present, wallet.sqlite3 absent, .pre-encryption kept; sealed app files + contacts.keys wrap, plain files unchanged;
             [node] plain_http holds lan_nodes.json's agreements; the contact and note read in the app
  beside     (packages differ) previous app stopped; adb install $cand_apk beside it; the test wallet restored there
             from its phrase and set to Settings › Advanced › Wallet view › Deep end (a fresh install opens at
             level 1); wallet_opens and balance_kept (same wallet key, same total); history, servers, settings
             and the migration checks not applicable and not required
  7 funds    $( [[ "$REL_FUNDS" == 1 ]] && echo "through the shared P service (no lock): send ${REL_TRUST_SEND:-0.01} to P, receive ${REL_TRUST_RECEIVE:-0.02} from P, by Epicbox" || echo "skipped (REL_FUNDS=0)")
  out        $REL_OUT/proof.json, driver.log, screens.log, p.log, shots/
EOF
  exit 0
fi

mkdir -p "$REL_OUT" || exit 2
[[ -x "$ADB" ]] || cannot "adb not found at $ADB"
# One run per test wallet: two emulators restoring the same wallet would spend the same outputs.
# Wallet Q's CLI copy takes the same lock (docs/RELEASING.md "Test wallets").
mkdir -p -m 700 "$REL_TRUST_STATE" && exec 8>>"$REL_TRUST_STATE/.lock" || cannot "cannot open $REL_TRUST_STATE/.lock"
flock -n 8 || { say "test wallet $REL_TRUST_STATE in use: waiting for its lock"; flock -w 3600 8; } ||
  cannot "test wallet $REL_TRUST_STATE busy for an hour (its .lock)"
started="" boot_s="" booted=0
emu_health() { # alive: 1|0 — the emulator's health for the runner's metrics (metrics.jsonl)
  printf '{"avd": "%s", "port": %s, "own_emulator": %s, "booted": %s, "boot_s": %s, "alive_at_end": %s}\n' \
    "$avd" "$port" "$([[ -n "$started" ]] && echo true || echo false)" "$([[ $booted == 1 ]] && echo true || echo false)" \
    "${boot_s:-null}" "$([[ $1 == 1 ]] && echo true || echo false)" >"$REL_OUT/emulator.json"
}
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
  started=$! t_boot=$SECONDS
  export REL_ANDROID_SERIAL="emulator-$port"
  for _ in $(seq 1 90); do
    [[ "$("$ADB" -s "$REL_ANDROID_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]] && { booted=1; break; }
    kill -0 "$started" 2>/dev/null || break
    sleep 2
  done
  boot_s=$((SECONDS - t_boot))
  [[ $booted == 1 ]] || { emu_health 0; cannot "emulator $avd did not boot in ${boot_s}s (see $REL_OUT/emulator.log)"; }
  "$ADB" -s "$REL_ANDROID_SERIAL" shell settings put global window_animation_scale 0 >/dev/null 2>&1
  "$ADB" -s "$REL_ANDROID_SERIAL" shell settings put global transition_animation_scale 0 >/dev/null 2>&1
fi
say "previous $prev_apk"
say "candidate $cand_apk"
say "serial $REL_ANDROID_SERIAL, node $REL_NODE, epicbox $REL_EPICBOX, out $REL_OUT"
python3 -I "$drv/trust.py" run
rc=$?
[[ -n "$started" ]] || booted=1
[[ "$("$ADB" -s "$REL_ANDROID_SERIAL" get-state 2>/dev/null)" == device ]] && emu_health 1 || emu_health 0
case $rc in 0 | 1 | 2) ;; *) rc=2 ;; esac
say "exit $rc ($( ((rc == 0)) && echo proven || { ((rc == 1)) && echo 'not proven' || echo 'could not run'; }))"
exit $rc
