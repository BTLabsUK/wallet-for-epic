#!/usr/bin/env bash
# G4 update trust, iOS: the phone lane of trust-android.sh on an iPhone Simulator on a Mac. A user on the
# PREVIOUS release who updates to the CANDIDATE keeps the wallet, its balance and history, their own node
# and Epicbox relay, and their settings; then the candidate sends to and receives from P through Epicbox.
# Driven over ssh by the shared core (ios/lane.py: core/lane.py, core/phone.py, ios/ios_platform.py) with
# WebDriverAgent (ios/wda.py) reading the accessibility tree and tapping. Without Tor only (iOS cannot
# start a bundled tor).
#
# Environment (the runner's contract, as trust-android.sh):
#   REL_PREVIOUS_DIR, REL_PREVIOUS_VERSION   previous release folder (ios/ or emulator/
#                                            bt-wallet-<v>-notor-ios-simulator.zip: tools/build-apple.sh ios-sim)
#   REL_PREVIOUS_EXTRA                       previous run's non-published folder, looked in first
#   REL_CANDIDATE_DIR, REL_CANDIDATE_VERSION candidate's published files
#   REL_CANDIDATE_EXTRA                      candidate's non-published folder
#   REL_PREVIOUS_APP, REL_CANDIDATE_APP      a Simulator zip each, instead of the folders
#   REL_VARIANT        notor (tor: refused)
#   REL_CHECKS, REL_FUNDS, REL_NODE, REL_EPICBOX, REL_OUT, REL_DRY_RUN=1   as trust-android.sh
#   REL_TRUST_MODE     create | flow (flow: one build as previous and candidate, simctl install over it)
# The Mac:
#   REL_IOS_SSH        ssh name of the Mac (default bob-mac); Xcode with an iOS Simulator runtime there
#   REL_IOS_HOME       the lane's folder in the Mac user's home (default btlabs-ios-driver): WebDriverAgent's
#                      build in wda-build/ (`trust-ios.sh setup` makes it), each device's run/<device>/
#   REL_IOS_DEVICE     the lane's Simulator device (default wfe-trust-<variant>; made when missing, booted
#                      headless, shut down at the end; REL_IOS_KEEP=1 leaves it and WebDriverAgent running)
#   REL_IOS_WDA_PORT   WebDriverAgent's port on the Mac (default 8102)
# No saved states on iOS yet: REL_TRUST_SAVE_STATE defaults to 0 and the wallet is set up every run.
# Exit: 0 every check in REL_CHECKS true; 1 some false (not proven); 2 could not run.
# Also writes $REL_OUT/simulator.json (device, boots, WebDriverAgent starts, recoveries).
#
# `trust-ios.sh setup`: WebDriverAgent cloned (pinned commit) and built for testing on the Mac, unsigned.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
drv="$here/ios"
mac="${REL_IOS_SSH:-bob-mac}"
home="${REL_IOS_HOME:-btlabs-ios-driver}"
WDA_COMMIT=3d6a4e0
say() { echo "trust-ios: $*" >&2; }

if [[ "${1:-}" == setup ]]; then
  # shellcheck disable=SC2029  # expanded here on purpose: the Mac's folder and the pinned commit
  ssh -o BatchMode=yes "$mac" "zsh -l -c 'set -e; B=\$HOME/$home; mkdir -p \$B
    [ -d \$B/WebDriverAgent ] || git clone -q https://github.com/appium/WebDriverAgent.git \$B/WebDriverAgent
    cd \$B/WebDriverAgent && git fetch -q origin && git checkout -q $WDA_COMMIT
    xcodebuild build-for-testing -project WebDriverAgent.xcodeproj -scheme WebDriverAgentRunner \
      -destination \"generic/platform=iOS Simulator\" -derivedDataPath \$B/wda-build CODE_SIGNING_ALLOWED=NO -quiet
    ls \$B/wda-build/Build/Products/*.xctestrun'"
  exit $?
fi

if [[ "${REL_RUN_KIND:-}" = release ]] && [[ -n "${REL_TRUST_BREAK:-}" ]]; then
  say "REL_TRUST_BREAK is set in a release run: break tests run in --test runs only"; exit 2
fi
export REL_FUNDS="${REL_FUNDS:-1}" REL_VARIANT="${REL_VARIANT:-notor}" REL_TRUST_SAVE_STATE="${REL_TRUST_SAVE_STATE:-0}"
dry="${REL_DRY_RUN:-0}"
cannot() { # reason: write a fail-closed proof (when REL_OUT is known) and exit 2
  say "cannot run: $1"
  if [[ -n "${REL_OUT:-}" && "$dry" != 1 ]]; then
    mkdir -p "$REL_OUT" && python3 -I "$drv/lane.py" fail "$1" >/dev/null 2>&1
  fi
  exit 2
}
[[ -n "${REL_OUT:-}" ]] || cannot "REL_OUT is not set"
[[ "$REL_VARIANT" == notor ]] || cannot "iOS is built without Tor only: REL_VARIANT must be notor, not '$REL_VARIANT'"

# The variant's Simulator zip of a release folder: ios/ or emulator/bt-wallet-<v>-notor-ios-simulator.zip.
app_in() { # dir version
  local d=$1 v=$2 f
  for f in "$d"/{ios,emulator,.}/bt-wallet-"$v"-notor-ios-simulator.zip "$d"/{ios,emulator,.}/bt-wallet-*-notor-ios-simulator.zip; do
    [[ -f "$f" ]] && { echo "$f"; return 0; }
  done
  return 1
}
create=0
[[ "${REL_TRUST_MODE:-}" == create ]] && create=1
prev="${REL_PREVIOUS_APP:-}"
[[ -n "$prev" ]] || prev="$(app_in "${REL_PREVIOUS_EXTRA:-/nonexistent}" "${REL_PREVIOUS_VERSION:-}" ||
  app_in "${REL_PREVIOUS_DIR:-/nonexistent}" "${REL_PREVIOUS_VERSION:-}")" ||
  if [[ $create == 1 ]]; then prev="<not used: REL_TRUST_MODE=create>"; elif [[ "$dry" == 1 ]]; then prev="<not found: ${REL_PREVIOUS_DIR:-REL_PREVIOUS_DIR unset}/ios>"; else
  cannot "no previous notor Simulator zip under REL_PREVIOUS_EXTRA (${REL_PREVIOUS_EXTRA:-unset}) or ${REL_PREVIOUS_DIR:-<REL_PREVIOUS_DIR unset>}"; fi
cand="${REL_CANDIDATE_APP:-}"
[[ -n "$cand" ]] || cand="$(app_in "${REL_CANDIDATE_EXTRA:-/nonexistent}" "${REL_CANDIDATE_VERSION:-}" ||
  app_in "${REL_CANDIDATE_DIR:-/nonexistent}" "${REL_CANDIDATE_VERSION:-}")" ||
  if [[ "$dry" == 1 ]]; then cand="<not built yet: ${REL_CANDIDATE_EXTRA:-REL_CANDIDATE_EXTRA}/ios>"; else
  cannot "no candidate notor Simulator zip under REL_CANDIDATE_EXTRA or REL_CANDIDATE_DIR"; fi
export REL_PREVIOUS_APP="$prev" REL_CANDIDATE_APP="$cand"
device="${REL_IOS_DEVICE:-wfe-trust-$REL_VARIANT}"

if [[ "$dry" == 1 ]]; then
  cat <<EOF
trust-ios plan ($REL_VARIANT, mode=${REL_TRUST_MODE:-update}, funds=$REL_FUNDS, required: ${REL_CHECKS:-$(python3 -I "$drv/lane.py" checks)})
  mac        ssh $mac; Simulator $device (made when missing, booted headless; shut down at the end), WebDriverAgent from ~/$home/wda-build on port ${REL_IOS_WDA_PORT:-8102}
  ports      ssh -L WebDriverAgent here; ssh -R the stand-ins and this host's node and relay there
  start      fresh every run (no saved states on iOS): simctl uninstall, Keychain reset; simctl install $prev;
             create a wallet (PIN, phrase read off Settings › Security); node, Epicbox, settings set through the screens
  fund       P pays the wallet; digest from the app's data container (ssh)
  update     app stopped; simctl install $cand over it
  candidate  launch, unlock with the PIN; digest again; compare
  funds      $( [[ "$REL_FUNDS" == 1 ]] && echo "receive from P and send to P by Epicbox; everything back to P" || echo "everything back to P (REL_FUNDS=0: not checked)")
  out        $REL_OUT/result.txt, proof.json, trust.log, shots/, console.txt, wda.log, simulator.json
EOF
  exit 0
fi

mkdir -p "$REL_OUT" || exit 2
# One lane per Simulator device: its data container and Keychain are the lane's.
lockdir="$HOME/.cache/rel-trust-ios"
mkdir -p -m 700 "$lockdir" && exec 8>>"$lockdir/$device.lock" || cannot "cannot open $lockdir/$device.lock"
flock -n 8 || { say "Simulator $device in use: waiting for its lock"; flock -w 3600 8; } || cannot "Simulator $device busy for an hour"
export REL_IOS_SSH="$mac" REL_IOS_HOME="$home" REL_IOS_DEVICE="$device"
say "previous $prev"
say "candidate $cand"
python3 -I "$drv/lane.py" >"$REL_OUT/lane.out" 2>&1
rc=$?
case $rc in 0 | 1 | 2) ;; *) rc=2 ;; esac
[[ -f "$REL_OUT/result.txt" ]] && say "$(cat "$REL_OUT/result.txt")"
say "exit $rc ($( ((rc == 0)) && echo proven || { ((rc == 1)) && echo 'not proven' || echo 'could not run'; }))"
exit $rc
