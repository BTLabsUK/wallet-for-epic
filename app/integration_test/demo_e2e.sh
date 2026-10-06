#!/usr/bin/env bash
# Host side of integration_test/demo_e2e_test.dart: the web demo end to end on floonet,
# without a browser (the real demo server on real LEPIC, two demos paying each other).
#
#   bash integration_test/demo_e2e.sh            (from app/ or anywhere)
#
# Floonet is not mined around the clock (OD-12): this starts `floo-miner` in pm2 when it is
# stopped, and stops it again on exit. The test's own server runs on a free loopback port with
# a data root under /tmp, removed by the test. Set WFE_DEMO_WEB_ROOT to have the server serve a
# built app/build/web under /app/ as well.
# Log: /tmp/epic-build/wfe-app-logs/demo-e2e-<time>.log.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$(cd "$HERE/.." && pwd)"
LIB="${WFE_DEMO_LEPIC_LIB:-$APP/third_party/lepic/bindings/flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so}"
LOGS=/tmp/epic-build/wfe-app-logs
LOG="$LOGS/demo-e2e-$(date -u +%Y%m%dT%H%M%SZ).log"
mkdir -p "$LOGS"
. "$(git rev-parse --show-toplevel)/tools/env.sh"

[ -f "$LIB" ] || { echo "no LEPIC library at $LIB; run tools/lepic.sh build linux"; exit 1; }

STARTED_MINER=0
cleanup() {
  set +e
  if [ "$STARTED_MINER" = 1 ]; then
    pm2 stop floo-miner > /dev/null 2>&1 && echo "floo-miner stopped again"
  fi
}
trap cleanup EXIT
trap "exit 130" INT TERM

miner_status() {
  pm2 jlist 2>/dev/null | python3 -c '
import json, sys
for p in json.load(sys.stdin):
    if p["name"] == "floo-miner":
        print(p["pm2_env"]["status"])
'
}

tip() {
  curl -s -m 15 -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"get_tip","params":[],"id":1}' \
    https://floo-node.btlabs.uk/v2/foreign |
    python3 -c 'import json, sys; print(json.load(sys.stdin)["result"]["Ok"]["height"])'
}

echo "floonet tip $(tip)"
if [ "$(miner_status)" != "online" ]; then
  pm2 start floo-miner > /dev/null
  STARTED_MINER=1
  echo "floo-miner started for this run"
fi

cd "$APP"
echo "log: $LOG"
WFE_DEMO_LEPIC_LIB="$LIB" WFE_DEMO_APP_DIR="$APP" WFE_DEMO_DART="$FLUTTER_ROOT/bin/dart" \
  xvfb-run -a flutter test integration_test/demo_e2e_test.dart -d linux \
  --reporter expanded > "$LOG" 2>&1 && status=0 || status=$?
grep -E 'WFE_E2E|All tests passed|Some tests failed|\[E\]' "$LOG" || true
echo "floonet tip $(tip)"
exit "$status"
