#!/usr/bin/env bash
# Host side of integration_test/usernet_e2e_test.dart: the whole app on an Android emulator
# against the local usernet, the local epicbox relay and a stock epic-wallet CLI.
#
#   bash integration_test/usernet_e2e.sh [emulator-serial]      (default emulator-5558)
#
# What it does, and undoes on exit:
#   1. Starts what is not already running: the usernet node (/opt/epic/stable-network) and the local
#      relay (/opt/epic/epic-relay on 127.0.0.1:3423, epicbox protocol). The miner runs for the whole
#      test (burn_reward stays on, so mining confirms without crediting anyone).
#   2. Makes a throwaway stock epic-wallet 4.0.0 CLI wallet, funds it from alice by file slate,
#      and runs its epicbox listener, which answers the app's send and finishes its own.
#   3. `adb reverse` for the node (23413) and relay (3423), so the app's usernet preset reaches
#      them as 127.0.0.1.
#   4. Runs the test with the CLI's address as a define. When the test prints
#      `WFE_E2E address=<address>`, the CLI sends 1 EPIC to it over epicbox.
# Logs: /tmp/epic-build/wfe-app-logs/e2e-*.log. The phrase is never printed or logged.
set -euo pipefail

SERIAL="${1:-emulator-5558}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$(cd "$HERE/.." && pwd)"
NET="${EPIC_STABLE_NET:-$HOME/epic/stable-network}"
RELAY_DIR="${EPIC_RELAY_DIR:-$HOME/epic/epic-relay}"
CLI_BIN="${EPIC_STOCK_CLI:-$HOME/epic/user-env/bin/epic-wallet}"
LOGS=/tmp/epic-build/wfe-app-logs
CLI_PASS=e2e-stock-cli
mkdir -p "$LOGS"
. "$APP/../tools/env.sh"

# Kept after the run (no recursive delete here): a throwaway wallet on a private chain.
CLI_DIR="$LOGS/e2e-cli-$(date +%s)"
mkdir -p "$CLI_DIR"
STARTED_NODE=0
STARTED_RELAY=0
STARTED_MINER=0
CLI_PID=""
TEST_PID=""

net() { (cd "$NET" && . ./env.sh && "$@"); }
cli() { (cd "$CLI_DIR" && "$CLI_BIN" --usernet --pass "$CLI_PASS" "$@"); }
height() {
  curl -s -m 5 -X POST http://127.0.0.1:23413/v2/foreign \
    -d '{"jsonrpc":"2.0","id":1,"method":"get_tip","params":[]}' |
    sed -n 's/.*"height": *\([0-9]*\).*/\1/p' | head -1
}

cleanup() {
  set +e
  [ -n "$TEST_PID" ] && kill "$TEST_PID" 2>/dev/null
  [ -n "$CLI_PID" ] && kill "$CLI_PID" 2>/dev/null
  if [ "$STARTED_MINER" = 1 ]; then
    kill "$(cat "$NET/var/run/miner.pid" 2>/dev/null)" 2>/dev/null
    rm -f "$NET/var/run/miner.pid"
  fi
  [ "$STARTED_RELAY" = 1 ] && pkill -f "$RELAY_DIR/.venv/bin/epic-relay"
  if [ "$STARTED_NODE" = 1 ]; then
    kill "$(cat "$NET/var/run/node.pid" 2>/dev/null)" 2>/dev/null
    rm -f "$NET/var/run/node.pid"
  fi
  adb -s "$SERIAL" reverse --remove tcp:23413 2>/dev/null
  adb -s "$SERIAL" reverse --remove tcp:3423 2>/dev/null
}
trap cleanup EXIT
trap "exit 130" INT TERM

echo "== host side"
if [ -z "$(height)" ]; then
  net bash net.sh node > "$LOGS/e2e-node.log" 2>&1
  STARTED_NODE=1
fi
if ! (exec 3<>/dev/tcp/127.0.0.1/3423) 2>/dev/null; then
  (cd "$RELAY_DIR" && EPIC_RELAY_EPICBOX_DOMAIN=127.0.0.1 EPIC_RELAY_ALIASES=localhost:3423 \
    setsid uv run epic-relay > "$LOGS/e2e-relay.log" 2>&1 < /dev/null &)
  STARTED_RELAY=1
  for _ in $(seq 60); do (exec 3<>/dev/tcp/127.0.0.1/3423) 2>/dev/null && break; sleep 1; done
fi
echo "node at $(height), relay up"

# The stock CLI wallet. `init` prints its phrase: that output goes nowhere.
(cd "$CLI_DIR" && "$CLI_BIN" --usernet --pass "$CLI_PASS" init -w > /dev/null 2>&1)
sed -i \
  -e 's/^api_listen_port = .*/api_listen_port = 23895/' \
  -e 's/^owner_api_listen_port = .*/owner_api_listen_port = 23896/' \
  -e 's|^check_node_api_http_addr = .*|check_node_api_http_addr = "http://127.0.0.1:23413"|' \
  -e 's/^node_api_secret_path/#node_api_secret_path/' \
  -e 's/^use_tor_listener = .*/use_tor_listener = false/' \
  -e 's/^epicbox_domain = .*/epicbox_domain = "127.0.0.1"/' \
  -e 's/^epicbox_port = .*/epicbox_port = 3423/' \
  -e 's/^epicbox_protocol_unsecure = .*/epicbox_protocol_unsecure = true/' \
  "$CLI_DIR/epic-wallet.toml"

echo "== funding the CLI from alice"
net w alice send -m file -d "$CLI_DIR/fund.tx" -c 3 3 > "$LOGS/e2e-alice-send.log" 2>&1
cli receive -i "$CLI_DIR/fund.tx" > "$LOGS/e2e-cli-receive.log" 2>&1
net w alice finalize -f -i "$CLI_DIR/fund.tx.response" > "$LOGS/e2e-alice-finalize.log" 2>&1
if ! kill -0 "$(cat "$NET/var/run/miner.pid" 2>/dev/null)" 2>/dev/null; then
  net bash net.sh miner > "$LOGS/e2e-miner.log" 2>&1
  STARTED_MINER=1
fi
spendable() {
  cli info --min_conf 3 2>/dev/null | sed -n 's/.*Currently Spendable *| *\([0-9.]*\).*/\1/p' | head -1
}
for _ in $(seq 150); do
  [ "$(spendable)" = "3.00000000" ] && break
  sleep 4
done
[ "$(spendable)" = "3.00000000" ] || { echo "the CLI was not funded"; exit 1; }
echo "CLI funded at height $(height)"

(cd "$CLI_DIR" && exec "$CLI_BIN" --usernet --pass "$CLI_PASS" listen -m epicbox \
  > "$LOGS/e2e-cli-listen.log" 2>&1) &
CLI_PID=$!
for _ in $(seq 30); do
  CLI_ADDRESS="$(sed -n 's/.*Starting epicbox listener for: *\([^ ]*\).*/\1/p' "$LOGS/e2e-cli-listen.log" | head -1)"
  [ -n "$CLI_ADDRESS" ] && break
  sleep 1
done
[ -n "$CLI_ADDRESS" ] || { echo "the CLI listener did not start"; exit 1; }
echo "CLI listens as $CLI_ADDRESS"

adb -s "$SERIAL" reverse tcp:23413 tcp:23413 > /dev/null
adb -s "$SERIAL" reverse tcp:3423 tcp:3423 > /dev/null

echo "== running the test on $SERIAL (several minutes)"
START=$(date +%s)
STATUS=1
# flutter_tools sometimes loses the VM service connection while it attaches to the app on a busy
# host ("Failed to load ... Service connection disposed", "Failed to start Dart Development
# Service", or a silent hang) before the test body runs. Only a run that never reached home is
# retried; a failure inside the test is not.
for ATTEMPT in 1 2 3; do
  (cd "$APP" && exec flutter test integration_test/usernet_e2e_test.dart -d "$SERIAL" \
    --dart-define=WFE_E2E=usernet --dart-define=WFE_CLI_ADDRESS="$CLI_ADDRESS" \
    > "$LOGS/e2e-test.log" 2>&1) &
  TEST_PID=$!
  SENT=0
  REVERSE_AT=0
  ATTEMPT_START=$(date +%s)
  while kill -0 "$TEST_PID" 2>/dev/null; do
    # Keep the reverse ports in place: a tool run that lost the app can remove them.
    if [ $(( $(date +%s) - REVERSE_AT )) -ge 10 ]; then
      if ! adb -s "$SERIAL" reverse --list 2>/dev/null | grep -q "tcp:3423"; then
        adb -s "$SERIAL" reverse tcp:23413 tcp:23413 > /dev/null 2>&1
        adb -s "$SERIAL" reverse tcp:3423 tcp:3423 > /dev/null 2>&1
      fi
      REVERSE_AT=$(date +%s)
    fi
    # A tool that lost the app can hang instead of exiting: give the build and attach 15 min.
    if ! grep -q "WFE_E2E step=home" "$LOGS/e2e-test.log" &&
      [ $(( $(date +%s) - ATTEMPT_START )) -gt 900 ]; then
      echo "attempt $ATTEMPT: no progress in 15 min; stopping it"
      pkill -P "$TEST_PID" 2>/dev/null; kill "$TEST_PID" 2>/dev/null
      break
    fi
    if [ "$SENT" = 0 ]; then
      ADDRESS="$(sed -n 's/.*WFE_E2E address=\([^ ]*\).*/\1/p' "$LOGS/e2e-test.log" | head -1)"
      if [ -n "$ADDRESS" ]; then
        echo "app address $ADDRESS; the CLI sends 1 EPIC"
        cli send -m epicbox -d "$ADDRESS" -c 3 1 > "$LOGS/e2e-cli-send.log" 2>&1 ||
          echo "the CLI send failed, see $LOGS/e2e-cli-send.log"
        SENT=1
      fi
    fi
    sleep 2
  done
  set +e
  wait "$TEST_PID"
  STATUS=$?
  set -e
  TEST_PID=""
  if [ "$STATUS" != 0 ] && ! grep -q "WFE_E2E step=home" "$LOGS/e2e-test.log"; then
    echo "attempt $ATTEMPT: the tool lost the app before the test started; trying again"
    cp "$LOGS/e2e-test.log" "$LOGS/e2e-test-attempt$ATTEMPT.log"
    continue
  fi
  break
done
grep -o 'WFE_E2E step=[a-z-]* after [0-9:.]*' "$LOGS/e2e-test.log" || true
echo "== test exit $STATUS after $(( $(date +%s) - START )) s; log $LOGS/e2e-test.log"
grep -q "Finalize transaction\|finalized successfully" "$LOGS/e2e-cli-listen.log" &&
  echo "the CLI answered and finished its payments"
exit "$STATUS"
