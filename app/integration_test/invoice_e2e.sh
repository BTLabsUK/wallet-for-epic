#!/usr/bin/env bash
# Host side of integration_test/invoice_e2e_test.dart: the whole app on an Android emulator,
# on floonet, paying and declining invoices that a LEPIC CLI wallet issues as a service.
#
#   bash integration_test/invoice_e2e.sh [emulator-serial]      (default emulator-5556)
#
# Needs the LEPIC CLI built in the pinned clone:
#   (cd app/third_party/lepic && cargo build --release -p lepic-cli)
#
# What it does, and undoes on exit:
#   1. Makes a throwaway service wallet with that CLI in a fresh directory under /tmp, on floonet
#      against https://floo-node.btlabs.uk and wss://flooepicbox.btlabs.uk:443. Its phrase goes
#      nowhere and its password lives only in this shell; the directory is removed on exit.
#   2. Starts `floo-miner` in pm2 when it is stopped, and stops it again on exit.
#   3. Runs the test with the service's address as a define, and answers its output:
#      `WFE_E2E payments=<address>`: claims 10 EPIC from the floonet faucet to it;
#      `WFE_E2E invoice-address=<address>`: issues 1.5 EPIC ("order 1") and 0.7 EPIC
#      ("order 2") to it;
#      `WFE_E2E step=approved`: drains the service's payments address until the payment is
#      finalized and posted, which sends the app the `posted` receipt, then once more for the
#      `declined` notice.
# Logs: /tmp/epic-build/wfe-app-logs/invoice-e2e-*.log.
set -euo pipefail

SERIAL="${1:-emulator-5556}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="$(cd "$HERE/.." && pwd)"
CLI_BIN="${LEPIC_CLI:-$APP/third_party/lepic/target/release/lepic}"
LOGS=/tmp/epic-build/wfe-app-logs
FAUCET='https://floo-explorer.btlabs.uk/api/faucet/claim'
mkdir -p "$LOGS"
. "$(git rev-parse --show-toplevel)/tools/env.sh"

[ -x "$CLI_BIN" ] || { echo "no LEPIC CLI at $CLI_BIN; build it first (see the header)"; exit 1; }

SVC_DIR="$(mktemp -d /tmp/wfe-invoice-svc.XXXXXX)"
STARTED_MINER=0
TEST_PID=""
# Never printed or logged; only the CLI reads it, from its environment.
LEPIC_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -d '/+=')"
export LEPIC_PASSWORD

cleanup() {
  set +e
  [ -n "$TEST_PID" ] && { pkill -P "$TEST_PID"; kill "$TEST_PID"; } 2>/dev/null
  [ "$STARTED_MINER" = 1 ] && pm2 stop floo-miner > /dev/null 2>&1
  rm -rf "$SVC_DIR"
}
trap cleanup EXIT
trap "exit 130" INT TERM

cat > "$SVC_DIR/config.toml" <<EOF
network = floonet
data_dir = "$SVC_DIR/wallet"
node_url = "https://floo-node.btlabs.uk"
epicbox_relay = "wss://flooepicbox.btlabs.uk:443"
EOF
svc() { "$CLI_BIN" --config "$SVC_DIR/config.toml" "$@"; }

echo "== the service wallet"
# `wallet init` prints the phrase: that output goes nowhere.
svc wallet init > /dev/null 2>&1
SVC_ADDRESS="$(svc wallet address 2>/dev/null | grep -o '[1-9A-HJ-NP-Za-km-z]\{52\}@[^ ]*' | head -1)"
[ -n "$SVC_ADDRESS" ] || { echo "the service has no epicbox address"; exit 1; }
echo "service address $SVC_ADDRESS"

if [ "$(pm2 jlist 2>/dev/null | python3 -c 'import json,sys; print(next((p["pm2_env"]["status"] for p in json.load(sys.stdin) if p["name"]=="floo-miner"), ""))')" != online ]; then
  pm2 start floo-miner > /dev/null
  STARTED_MINER=1
  echo "floo-miner started"
fi

echo "== running the test on $SERIAL (about half an hour: the faucet's payment needs 10 blocks)"
START=$(date +%s)
LOG="$LOGS/invoice-e2e-test.log"
(cd "$APP" && exec flutter test integration_test/invoice_e2e_test.dart -d "$SERIAL" \
  --dart-define=WFE_E2E=floonet-invoices --dart-define=WFE_SERVICE_ADDRESS="$SVC_ADDRESS" \
  > "$LOG" 2>&1) &
TEST_PID=$!
CLAIMED=0
ISSUED=0
FINALIZED=0
DRAINS_AFTER=0
while kill -0 "$TEST_PID" 2>/dev/null; do
  if [ "$CLAIMED" = 0 ]; then
    PAY="$(sed -n 's/.*WFE_E2E payments=\([^ ]*\).*/\1/p' "$LOG" | head -1)"
    if [ -n "$PAY" ]; then
      for _ in 1 2 3 4; do
        CODE="$(curl -s -m 30 -o "$LOGS/invoice-e2e-faucet.log" -w '%{http_code}' -X POST \
          "$FAUCET?method=epicbox&destination=$PAY")"
        [ "$CODE" = 200 ] && break
        echo "faucet answered $CODE; again in 40 s"
        sleep 40
      done
      echo "faucet claim to the app: $CODE"
      CLAIMED=1
    fi
  fi
  if [ "$ISSUED" = 0 ]; then
    INV="$(sed -n 's/.*WFE_E2E invoice-address=\([^ ]*\).*/\1/p' "$LOG" | head -1)"
    if [ -n "$INV" ]; then
      svc invoice issue 1.5 --to "$INV" -m "order 1" >> "$LOGS/invoice-e2e-svc.log" 2>&1
      svc invoice issue 0.7 --to "$INV" -m "order 2" >> "$LOGS/invoice-e2e-svc.log" 2>&1
      echo "issued 1.5 and 0.7 EPIC to the app's invoice address"
      ISSUED=1
    fi
  fi
  if grep -q "WFE_E2E step=approved" "$LOG" && [ "$DRAINS_AFTER" -lt 3 ]; then
    OUT="$(svc epicbox drain 2>&1 || true)"
    echo "$OUT" >> "$LOGS/invoice-e2e-svc.log"
    if echo "$OUT" | grep -q 'finalized [1-9]'; then
      FINALIZED=1
      echo "the service finalized and posted the payment"
    fi
    [ "$FINALIZED" = 1 ] && grep -q "WFE_E2E step=declined" "$LOG" &&
      DRAINS_AFTER=$((DRAINS_AFTER + 1))
    sleep 10
  fi
  sleep 3
done
set +e
wait "$TEST_PID"
STATUS=$?
set -e
TEST_PID=""
grep -o 'WFE_E2E step=[a-z-]* after [0-9:.]*' "$LOG" || true
grep -o 'notices [0-9]*' "$LOGS/invoice-e2e-svc.log" | sort | uniq -c || true
echo "== test exit $STATUS after $(( $(date +%s) - START )) s; log $LOG"
exit "$STATUS"
