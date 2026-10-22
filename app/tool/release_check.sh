#!/usr/bin/env bash
# Independent release check: drives the real desktop wallet (LEPIC, a real node, a real Epicbox
# relay) on Linux under xvfb, with throwaway data dirs and a throwaway keyring.
#
#   tool/release_check.sh pick            print the node and relay that would be used
#   tool/release_check.sh desktop [file]  run integration_test/release_check/*_test.dart (or one)
#
# Needs LEPIC built for Linux: tools/lepic.sh sync && tools/lepic.sh build linux.
# Env: RC_OUT (default $TMPDIR, else ~/.cache/release-check) holds the per-run data dirs,
# logs and shots/desktop. WFE_CHECK_NODE / WFE_CHECK_RELAY force a first choice.
# No funds move; recovery phrases and passwords are never printed.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$(git rev-parse --show-toplevel)/tools/env.sh"
OUT="${RC_OUT:-${TMPDIR:-$HOME/.cache/release-check}}"
mkdir -p "$OUT/shots/desktop"

NODES="${WFE_CHECK_NODE:-} https://node.btlabs.uk https://node.epicnet.us:3413 https://node.epiccash.com"
RELAYS="${WFE_CHECK_RELAY:-} epicbox.stackwallet.com epicbox.epicnet.us epicbox.epiccash.com"

node_ok() {
  curl -sf -m 10 -H 'content-type: application/json' \
    -d '{"jsonrpc":"2.0","method":"get_tip","params":[],"id":1}' "$1/v2/foreign" | grep -q '"height"'
}
relay_ok() {
  [ "$(curl -s -m 8 -o /dev/null -w '%{http_code}' -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
    -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' "https://$1:443/")" = 101 ]
}

NODE=""; NODE2=""
for n in $NODES; do
  node_ok "$n" || continue
  if [ -z "$NODE" ]; then NODE="$n"; elif [ -z "$NODE2" ] && [ "$n" != "$NODE" ]; then NODE2="$n"; fi
done
RELAY=""
for h in $RELAYS; do relay_ok "$h" && { RELAY="$h"; break; }; done
[ -n "$NODE" ] || { echo "no healthy node" >&2; exit 3; }
[ -n "$RELAY" ] || { echo "no healthy Epicbox relay" >&2; exit 3; }
[ -n "$NODE2" ] || NODE2="$NODE"
echo "node=$NODE other_node=$NODE2 relay=$RELAY"
[ "${1:-}" = pick ] && exit 0

case "${1:-}" in
  desktop)
    cd "$here"
    files=("${2:-}")
    [ -z "${files[0]}" ] && files=(integration_test/release_check/desktop_test.dart integration_test/release_check/restore_test.dart)
    run="$OUT/run-$(date +%H%M%S)"
    rc=0
    # The phrase of the first (empty, throwaway) wallet goes to a mode-600 file for restore_test.dart,
    # which deletes it; this script deletes it again if the restore test never ran.
    umask 077
    mkdir -p "$run"
    export RC_PHRASE_FILE="$run/phrase.tmp" RC_ADDR_FILE="$run/addr.txt"
    for f in "${files[@]}"; do
      name="$(basename "$f" .dart)"
      home="$run/$name"
      mkdir -p "$home/data" "$home/config" "$home/cache"
      # A fresh HOME and XDG dirs per file; a throwaway keyring unlocked with a throwaway password.
      HOME="$home" XDG_DATA_HOME="$home/data" XDG_CONFIG_HOME="$home/config" XDG_CACHE_HOME="$home/cache" \
      PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}" RC_SHOTS="$OUT/shots/desktop" RC_HOME="$home" \
      timeout 1500 xvfb-run -a -s "-screen 0 1600x1000x24" dbus-run-session -- bash -c '
        printf "%s" "throwaway-$$" | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1
        exec flutter test -d linux "$0" --dart-define=WFE_CHECK_NODE="$1" --dart-define=WFE_CHECK_NODE2="$2" --dart-define=WFE_CHECK_RELAY="$3"
      ' "$f" "$NODE" "$NODE2" "$RELAY" 2>&1 | tee "$OUT/$name.log" | tail -80
      [ "${PIPESTATUS[0]}" -eq 0 ] || rc=1
    done
    rm -f "$RC_PHRASE_FILE"
    grep -h '^RC ' "$OUT"/desktop_test.log "$OUT"/restore_test.log 2>/dev/null | sed 's/^RC //' > "$OUT/results.txt"
    echo "results: $(grep -c '^PASS' "$OUT/results.txt") pass, $(grep -c '^FAIL' "$OUT/results.txt") fail ($OUT/results.txt)"
    exit $rc
    ;;
  *) sed -n 2,8p "$0" >&2; exit 2 ;;
esac
