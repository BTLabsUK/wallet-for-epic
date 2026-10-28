#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Pairing between two real desktop apps: builds the Linux app once with
# integration_test/release_check/two_apps_test.dart as its entry, then starts it twice under
# xvfb, as A and B, each with its own HOME (the data folder is $HOME/.epic_cash_desktop), XDG
# dirs, D-Bus session and throwaway keyring. The two meet through files in a sync folder.
#
#   tool/two_apps_check.sh [node] [relay]     (default https://node.btlabs.uk epicbox.stackwallet.com)
#
# Needs LEPIC built for Linux: tools/lepic.sh sync && tools/lepic.sh build linux.
# Env: RC_OUT (default $TMPDIR, else ~/.cache/release-check) holds the run, its logs and
# shots/two. No funds move; recovery phrases and passwords are never printed.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/../tools/env.sh"
NODE="${1:-https://node.btlabs.uk}"
RELAY="${2:-epicbox.stackwallet.com}"
OUT="${RC_OUT:-${TMPDIR:-$HOME/.cache/release-check}}"
run="$OUT/two-$(date +%H%M%S)"
shots="$OUT/shots/two"
mkdir -p "$run/sync" "$shots"
cd "$here"

echo "building the app with the two-app test as its entry"
flutter build linux --debug -t integration_test/release_check/two_apps_test.dart > "$run/build.log" 2>&1 \
  || { tail -30 "$run/build.log"; exit 1; }
bin="$here/build/linux/x64/debug/bundle/epic_wallet"
[ -x "$bin" ] || { echo "no app binary at $bin" >&2; exit 1; }

pids=()
for role in A B; do
  home="$run/$role"
  mkdir -p "$home/data" "$home/config" "$home/cache"
  # Each in its own process group, so the end stops exactly what this script started.
  HOME="$home" XDG_DATA_HOME="$home/data" XDG_CONFIG_HOME="$home/config" XDG_CACHE_HOME="$home/cache" \
  RC_ROLE="$role" RC_SYNC="$run/sync" RC_SHOTS="$shots" RC_NODE="$NODE" RC_RELAY="$RELAY" \
    setsid timeout 3000 xvfb-run -a -s "-screen 0 1600x1000x24" dbus-run-session -- bash -c '
      printf "%s" "throwaway-$$" | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1
      exec "$0"
    ' "$bin" > "$run/$role.log" 2>&1 &
  pids+=("$!")
done

stop() {
  for p in "${pids[@]}"; do kill -- "-$p" 2>/dev/null; done
}
trap stop EXIT

# Both done, either failed, or 45 minutes.
end=$(( $(date +%s) + 2700 ))
while [ "$(date +%s)" -lt "$end" ]; do
  a=$(grep -c '^RC DONE A' "$run/A.log" 2>/dev/null); b=$(grep -c '^RC DONE B' "$run/B.log" 2>/dev/null)
  [ "${a:-0}" -ge 1 ] && [ "${b:-0}" -ge 1 ] && break
  grep -qE 'EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK|Test failed' "$run/A.log" "$run/B.log" 2>/dev/null && { sleep 20; break; }
  sleep 5
done

grep -h '^RC ' "$run/A.log" "$run/B.log" | sed 's/^RC //' > "$run/results.txt"
cat "$run/results.txt"
for role in A B; do
  grep -n 'EXCEPTION CAUGHT' -A12 "$run/$role.log" | head -20
done
echo "run: $run  shots: $shots"
grep -q '^FAIL' "$run/results.txt" && exit 1
[ "$(grep -c '^RC DONE' "$run/A.log" "$run/B.log" | awk -F: '{s+=$2} END {print s}')" -eq 2 ] || exit 1
exit 0
