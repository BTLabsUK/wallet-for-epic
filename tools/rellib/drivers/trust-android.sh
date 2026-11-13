#!/usr/bin/env bash
# G4 update trust, Android: a user on the PREVIOUS release who updates to the CANDIDATE keeps the
# wallet, its balance and history, their own node and Epicbox relay, and their settings; then the
# candidate sends to and receives from P through Epicbox. Driven on an emulator with uiautomator by
# the shared core (android/lane.py: core/lane.py, core/phone.py, android/android_platform.py).
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
#                      migration checks: store_encrypted, app_files_kept, lan_nodes_kept, contact_note_kept)
#   REL_FUNDS          1 = also receive from and send to P with the candidate; 0 = not (P still funds the
#                      previous release's wallet and the balance goes back to P)
#   REL_NODE           node to type in, e.g. https://node.btlabs.uk (unset: health pick below)
#   REL_EPICBOX        Epicbox relay to type in, e.g. epicbox.btlabs.uk (unset: health pick)
#   REL_OUT            result.txt, proof.json, trust.log and shots/ go here
#   REL_DRY_RUN=1      print the plan, touch nothing, exit 0
# Optional:
#   REL_ANDROID_SERIAL a running emulator to use (else REL_ANDROID_AVD, default wfe_trust_<variant>
#                      is started headless on port REL_ANDROID_PORT,
#                      default 5580 for tor and 5582 for notor, and stopped at the end;
#                      REL_ANDROID_KEEP=1 leaves it running)
#   REL_TRUST_START    auto | state | fresh, REL_TRUST_SAVE_STATE, REL_TRUST_STATE_ROOT: saved end
#                      states (core/state.py; on Android an emulator snapshot of the AVD)
#   REL_TRUST_MODE     create: only the candidate, installed fresh, and a new wallet made on it (no
#                      previous release, no update, no funds)
#                      flow: the update lane on one build, the run's test build as previous and
#                      candidate (release/pipeline.toml flow-*); the update is adb install -r of it
#   REL_P_*            P settings, see linux/p_funder.py
# Exit: 0 every check in REL_CHECKS true; 1 some false (not proven); 2 could not run.
# Also writes $REL_OUT/emulator.json (boot time, booted, alive at the end) for the runner's metrics.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
drv="$here/android"
. "$here/../../env.sh"   # java for apksigner: the nightly's PATH is bare
sdk="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
export ADB="${ADB:-$sdk/platform-tools/adb}"
# The default checks are android/lane.py's (settings_kept is not among them: the theme and Technical details are
# in Keystore-encrypted storage, the LEPIC CLI does not report the confirmations, the phone has no wallets.json
# label; the proof says so).
export REL_FUNDS="${REL_FUNDS:-1}" REL_VARIANT="${REL_VARIANT:-tor}"
dry="${REL_DRY_RUN:-0}"

say() { echo "trust-android: $*" >&2; }
cannot() { # reason: write a fail-closed proof (when REL_OUT is known) and exit 2
  say "cannot run: $1"
  if [[ -n "${REL_OUT:-}" && "$dry" != 1 ]]; then
    mkdir -p "$REL_OUT" && python3 -I "$drv/lane.py" fail "$1" >/dev/null 2>&1
  fi
  exit 2
}

[[ -n "${REL_OUT:-}" ]] || cannot "REL_OUT is not set"
case "$REL_VARIANT" in tor | notor) ;; *) cannot "REL_VARIANT must be tor or notor, not '$REL_VARIANT'" ;; esac
# Each variant its own emulator, so the two run at the same time.
if [[ "$REL_VARIANT" == notor ]]; then default_port=5582; else default_port=5580; fi

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
  if [[ $create == 1 ]]; then prev_apk="<not used: REL_TRUST_MODE=create>"; elif [[ "$dry" == 1 ]]; then prev_apk="<not found: ${REL_PREVIOUS_DIR:-REL_PREVIOUS_DIR unset}/emulator>"; else
  cannot "no previous $REL_VARIANT x86_64 APK under REL_PREVIOUS_EXTRA/emulator (${REL_PREVIOUS_EXTRA:-unset}) or ${REL_PREVIOUS_DIR:-<REL_PREVIOUS_DIR unset>}/emulator"; fi
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
  for n in https://node.btlabs.uk; do
    if [[ "$dry" == 1 ]] || node_ok "$n"; then REL_NODE=$n; break; fi
  done
  [[ -n "${REL_NODE:-}" ]] || cannot "no node answered (node.btlabs.uk)"
  picked+=" node"
fi
if [[ -z "${REL_EPICBOX:-}" ]]; then
  for r in epicbox.btlabs.uk; do
    if [[ "$dry" == 1 ]] || relay_ok "$r"; then REL_EPICBOX=$r; break; fi
  done
  [[ -n "${REL_EPICBOX:-}" ]] || cannot "no Epicbox relay answered"
  picked+=" epicbox"
fi
export REL_NODE REL_EPICBOX
[[ -n "$picked" ]] && say "health pick (${picked# }$([[ "$dry" == 1 ]] && echo ", dry run: first in line, not checked")): node $REL_NODE, epicbox $REL_EPICBOX"

port="${REL_ANDROID_PORT:-$default_port}"
avd="${REL_ANDROID_AVD:-wfe_trust_$REL_VARIANT}"
if [[ "$dry" == 1 && $create == 1 ]]; then
  cat <<EOF
trust-android plan ($REL_VARIANT, mode=create, required: ${REL_CHECKS:-$(python3 -I "$drv/lane.py" checks)})
  emulator   ${REL_ANDROID_SERIAL:-start AVD $avd headless (writable), emulator-$port; stopped at the end}
  create     adb uninstall; adb install $cand_apk; create a wallet (PIN, phrase read and dropped); Home
  out        $REL_OUT/result.txt, proof.json, trust.log, shots/, logcat.txt, emulator.json
EOF
  exit 0
fi
if [[ "$dry" == 1 ]]; then
  cat <<EOF
trust-android plan ($REL_VARIANT, mode=${REL_TRUST_MODE:-update}, funds=$REL_FUNDS, required: ${REL_CHECKS:-$(python3 -I "$drv/lane.py" checks)})
  emulator   ${REL_ANDROID_SERIAL:-start AVD $avd headless (writable), emulator-$port; stopped at the end}
  signer     both APKs must carry the same certificate (apksigner); it goes in proof.json and the saved state
  start      ${REL_TRUST_START:-auto}: the lane seed android-$REL_VARIANT when there is one (Restore from phrase on the previous release, core/lane_seed.py), else a saved $REL_VARIANT state of ${REL_PREVIOUS_VERSION:-?} (emulator snapshot) when one fits, else fresh
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
