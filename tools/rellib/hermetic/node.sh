#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# A local mainnet epic node for the hermetic G4 lanes.
#
#   node.sh start    install the binary if needed, write the config, start in the background
#   node.sh stop     stop it, chain kept
#   node.sh status   running or not, height, disk
#   node.sh health   local height vs the public node's; exit 0 only when synced within NODE_SYNC_SLACK
#
# Mainnet only (the app is mainnet-only). Pruned (archive_mode = false). The API is on 127.0.0.1 only
# and the foreign API is open, as a user's own node is (LEPIC sends no credentials to it); the owner
# API needs node/.api_secret.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"

SRC_BIN="${HERMETIC_NODE_SRC:-$HOME/epic-build/node-bin/4.1.1/linux/epic-v4.1.1-linux-amd64/epic}"
SRC_BIN_SHA=9e84309c0b397250e16024cbf0738fcffef94798515f48ec02259a59417f135a
SRC_TGZ_SHA=778a8a08778383bd74d2756a2811f3dcd9fbc3591b10295a6f272674b62f21e4
SRC_FOUNDATION="${HERMETIC_FOUNDATION_SRC:-$HOME/epic-r1/debian/foundation.json}"
FOUNDATION_SHA=5a3a7584127dd31fba18eaeff1c551bfaa74b4e50e537a1e1904fe6730b17f5c
PID="$HERMETIC_RUN/node.pid"
LOG="$HERMETIC_LOG/node.log"

sha() { sha256sum "$1" | cut -d' ' -f1; }

install_bin() {
    mkdir -p "$HERMETIC_BIN"
    if [ ! -x "$HERMETIC_EPIC" ] || [ "$(sha "$HERMETIC_EPIC")" != "$SRC_BIN_SHA" ]; then
        [ "$(sha "$SRC_BIN")" = "$SRC_BIN_SHA" ] || { echo "node: $SRC_BIN is not the 4.1.1 release binary" >&2; exit 1; }
        cp "$SRC_BIN" "$HERMETIC_EPIC"
        chmod 755 "$HERMETIC_EPIC"
    fi
    if [ ! -f "$HERMETIC_FOUNDATION" ] || [ "$(sha "$HERMETIC_FOUNDATION")" != "$FOUNDATION_SHA" ]; then
        [ "$(sha "$SRC_FOUNDATION")" = "$FOUNDATION_SHA" ] || { echo "node: $SRC_FOUNDATION is not the mainnet foundation.json" >&2; exit 1; }
        cp "$SRC_FOUNDATION" "$HERMETIC_FOUNDATION"
    fi
    cat > "$HERMETIC_BIN/PROVENANCE.md" <<P
# Provenance

| File | Version | sha256 | From |
| --- | --- | --- | --- |
| epic | $("$HERMETIC_EPIC" --version 2>/dev/null) | $SRC_BIN_SHA | the EpicCash release tarball epic-v4.1.1-linux-amd64.tar.gz (sha256 $SRC_TGZ_SHA, matching its published -sha256sum.txt), unpacked under /tmp/epic-build/node-bin/4.1.1 |
| foundation.json | mainnet | $FOUNDATION_SHA | debian/foundation.json of the epic node repository (last changed 2020-10-09, b89830c); the same bytes as the wallet repositories' tests/assets/foundation.json |

Checks: node.sh start refuses to copy either file when its sha256 differs from the one above.
Written by tools/rellib/hermetic/node.sh.
P
}

write_config() {
    mkdir -p "$NODE_DIR"
    # A relocated config names an api_secret_path that nothing creates, which leaves the owner API
    # open; write the secret first. (4.1.1 keeps GET /v1/status and owner get_status public on purpose.)
    if [ ! -s "$NODE_DIR/.api_secret" ]; then
        (umask 077; head -c 15 /dev/urandom | base64 | tr -d '/+=' > "$NODE_DIR/.api_secret")
    fi
    if [ ! -f "$NODE_DIR/epic-server.toml" ]; then
        (cd "$NODE_DIR" && "$HERMETIC_EPIC" server config >/dev/null)
    fi
    local peer_ip
    peer_ip="$(getent ahostsv4 "$NODE_PEER_HOST" | awk 'NR==1{print $1}')"
    [ -n "$peer_ip" ] || { echo "node: cannot resolve $NODE_PEER_HOST" >&2; exit 1; }
    # Set the keys this environment owns, every start, so the config cannot drift from env.sh.
    python3 - "$NODE_DIR/epic-server.toml" "$peer_ip:$NODE_PEER_PORT" <<PY
import re, sys
path, peer = sys.argv[1], sys.argv[2]
text = open(path).read()
want = {
    "db_root": '"$NODE_DIR/chain_data"',
    "api_http_addr": '"127.0.0.1:$NODE_API_PORT"',
    "api_secret_path": '"$NODE_DIR/.api_secret"',
    "foundation_path": '"$HERMETIC_FOUNDATION"',
    "chain_type": '"Mainnet"',
    "archive_mode": "false",
    "run_tui": "false",
    "host": '"127.0.0.1"',
    "port": "$NODE_P2P_PORT",
    "enable_stratum_server": "false",
    # Debug to a rotated file (NODE_LOG_MB × NODE_LOG_FILES at most, rotated files gzipped); stdout,
    # which nohup appends to node.log unrotated, keeps warnings only.
    "log_to_stdout": "true",
    "stdout_log_level": '"WARN"',
    "log_to_file": "true",
    "file_log_level": '"DEBUG"',
    "log_file_path": '"$NODE_LOG"',
    "log_file_append": "true",
    "log_max_size": str($NODE_LOG_MB * 1048576),
    "log_max_files": "$NODE_LOG_FILES",
    "seeding_type": '"DNSSeed"',
}
for k, v in want.items():
    text, n = re.subn(r"(?m)^#?\s*%s\s*=.*$" % k, "%s = %s" % (k, v), text, count=1)
    if n != 1:
        sys.exit("epic-server.toml has no %s" % k)
# Normal peer discovery from the mainnet DNS seed; our public node is one preferred peer among
# many, never the only one (no seeds, peers_allow or outbound-count overrides).
text = re.sub(r'(?m)^(seeds|peers_allow|peers_preferred|peer_min_preferred_outbound_count)\s*=.*\n', "", text)
text = re.sub(r'(?m)^(seeding_type = "DNSSeed")$', r'\1\npeers_preferred = ["%s"]' % peer, text, count=1)
# The foreign API stays open, as on a user's own node the app is pointed at.
text = re.sub(r'(?m)^foreign_api_secret_path\s*=.*$', '#foreign_api_secret_path = ".foreign_api_secret"', text)
open(path, "w").write(text)
PY
}

disk_gb() { du -sk "$NODE_DIR/chain_data" 2>/dev/null | awk '{printf "%.2f", $1/1048576}'; }

rpc() {  # rpc <url> <method>: the result's Ok, or nothing
    curl -s -m 15 -X POST "$1/v2/foreign" -H 'content-type: application/json' \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"$2\",\"params\":[],\"id\":1}" 2>/dev/null |
        python3 -c 'import json,sys
try: print(json.load(sys.stdin)["result"]["Ok"]["height"])
except Exception: pass'
}

owner_locked() {  # the owner API refuses a call without the secret
    [ "$(curl -s -o /dev/null -w '%{http_code}' -m 10 -X POST "$NODE_API_URL/v2/owner" \
        -H 'content-type: application/json' -d '{"jsonrpc":"2.0","method":"get_peers","params":[],"id":1}')" = 401 ]
}

owner_status() {  # sync_status and connections from the owner API, with the node's own secret
    [ -s "$NODE_DIR/.api_secret" ] || return 0
    curl -s -m 10 -u "epic:$(cat "$NODE_DIR/.api_secret")" -X POST "$NODE_API_URL/v2/owner" \
        -H 'content-type: application/json' -d '{"jsonrpc":"2.0","method":"get_status","params":[],"id":1}' 2>/dev/null |
        python3 -c 'import json,sys
try:
    o = json.load(sys.stdin)["result"]["Ok"]; print(o.get("sync_status"), o.get("connections"))
except Exception: pass'
}

case "${1:-status}" in
start)
    if alive "$PID"; then echo "node: already running ($(cat "$PID"))"; exit 0; fi
    install_bin
    write_config
    cd "$NODE_DIR"
    # Low priority: the sync is long and the machine is shared.
    nohup nice -n 10 ionice -c3 "$HERMETIC_EPIC" > >(python3 -I "$HERMETIC_SRC/rotlog.py" "$LOG" 4 2) 2>&1 &
    echo $! > "$PID"
    sleep 2
    alive "$PID" || { echo "node: exited at once; tail $LOG" >&2; tail -20 "$LOG" >&2; exit 1; }
    echo "node: started ($(cat "$PID")), API $NODE_API_URL, P2P $NODE_P2P_PORT (DNS seed peers, $NODE_PEER_HOST preferred), debug log $NODE_LOG"
    ;;
stop)
    stop_pid "$PID" node
    status_set node null
    ;;
status)
    if alive "$PID"; then echo "node: running ($(cat "$PID"))"; else echo "node: stopped"; fi
    echo "height: $(rpc "$NODE_API_URL" get_tip || true)  sync/peers: $(owner_status || true)  disk: $(disk_gb) GB"
    ;;
health)
    local_h="$(rpc "$NODE_API_URL" get_tip || true)"
    public_h="$(rpc "$NODE_PUBLIC_URL" get_tip || true)"
    gb="$(disk_gb)"
    echo "local: ${local_h:-none}  public: ${public_h:-none}  sync/peers: $(owner_status || true)  disk: ${gb:-0} GB"
    if awk -v g="${gb:-0}" -v m="$NODE_MAX_GB" 'BEGIN{exit !(g > m)}'; then
        echo "node: chain data over $NODE_MAX_GB GB" >&2
    fi
    if ! owner_locked; then
        status_set node null
        echo "node: the owner API answers without its secret" >&2
        exit 1
    fi
    if [ -n "$local_h" ] && [ -n "$public_h" ] && [ $((public_h - local_h)) -le "$NODE_SYNC_SLACK" ]; then
        status_set node "{\"url\": \"$NODE_API_URL\", \"height\": $local_h, \"public\": $public_h}"
        echo "node: synced"
        exit 0
    fi
    status_set node null
    echo "node: not synced"
    exit 1
    ;;
*)
    echo "usage: node.sh {start|stop|status|health}" >&2
    exit 2
    ;;
esac
