# SPDX-License-Identifier: Apache-2.0
# The one place for the hermetic environment's ports and paths: a local mainnet node and a loopback
# Epicbox relay for the G4 trust lanes. Every script here sources this; nothing retypes a port.
#
# Ports: a block of our own (43413-43423) so this never collides with a node on the mainnet
# defaults (3413/3414), the stable network (23413+), the dev relay (3423) or the ssh tunnels on 334xx.
# They are Epic protocol ports, so they are recorded here and not in the workspace ports.json.

HERMETIC_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HERMETIC_SRC
export HERMETIC_ROOT="${HERMETIC_ROOT:-$HOME/epic-build/rel/hermetic}"

export HERMETIC_BIN="$HERMETIC_ROOT/bin"
export HERMETIC_EPIC="$HERMETIC_BIN/epic"
export HERMETIC_FOUNDATION="$HERMETIC_BIN/foundation.json"
export HERMETIC_RUN="$HERMETIC_ROOT/var/run"
export HERMETIC_LOG="$HERMETIC_ROOT/var/log"
export HERMETIC_STATUS="$HERMETIC_ROOT/status.json"   # written by health; read by drivers/core/hermetic.py

# Node: mainnet, API on loopback only, P2P outbound (inbound bound to loopback, so nobody dials in).
export NODE_DIR="$HERMETIC_ROOT/node"
export NODE_API_PORT=43413
export NODE_P2P_PORT=43414
export NODE_API_URL="http://127.0.0.1:${NODE_API_PORT}"
export NODE_PUBLIC_URL="https://node.btlabs.uk"       # the reference height for health; read only
export NODE_SYNC_SLACK=5                              # blocks behind the public tip still counted as synced
export NODE_MAX_GB=25                                 # stop and report if the chain grows past this

# Relay: /opt/epic/epic-relay on loopback, its own database on the dev PostgreSQL (dev/pg.sh, 7787).
export RELAY_SRC="${RELAY_SRC:-$HOME/epic/epic-relay}"
export RELAY_PORT=43423
# The identity must be spelled the way the app spells the relay: it is given 127.0.0.1:<port>, so a
# wallet stamps its address @127.0.0.1:43423, and a relay named localhost would refuse to carry it.
export RELAY_DOMAIN=127.0.0.1
export RELAY_ALIASES="localhost:${RELAY_PORT}"
export RELAY_ADDR="${RELAY_DOMAIN}:${RELAY_PORT}"
export RELAY_PG_PORT=7787
export RELAY_PG_DB=epicrelay_hermetic
export RELAY_PG_DSN="postgresql://epicrelay:epicrelay@127.0.0.1:${RELAY_PG_PORT}/${RELAY_PG_DB}"

mkdir -p "$HERMETIC_RUN" "$HERMETIC_LOG"

# alive <pidfile>: the pid in it is running.
alive() { [ -s "$1" ] && kill -0 "$(cat "$1")" 2>/dev/null; }

# stop_pid <pidfile> <name>: TERM, then KILL after 30 s; removes the pid file.
stop_pid() {
    local f="$1" n="$2" pid i
    if ! alive "$f"; then rm -f "$f"; echo "$n: not running"; return 0; fi
    pid="$(cat "$f")"
    kill "$pid"
    for i in $(seq 30); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid"
    rm -f "$f"
    echo "$n: stopped ($pid)"
}

# status_set <key> <json value>: one key of status.json, the rest kept.
status_set() {
    python3 - "$HERMETIC_STATUS" "$1" "$2" <<'PY'
import json, os, sys, time
path, key, val = sys.argv[1], sys.argv[2], json.loads(sys.argv[3])
try:
    with open(path) as f:
        d = json.load(f)
except (OSError, ValueError):
    d = {}
d[key] = val
d["updated"] = int(time.time())
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(d, f, indent=2, sort_keys=True)
os.replace(tmp, path)
PY
}
