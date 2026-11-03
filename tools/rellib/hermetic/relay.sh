#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# A loopback Epicbox relay (/opt/epic/epic-relay) for the hermetic G4 lanes.
#
#   relay.sh start    dev PostgreSQL up (epic-relay's dev/pg.sh), our own database on it, relay started
#   relay.sh stop     stop the relay; the database and the PostgreSQL container are left running
#   relay.sh status   running or not, and the relay's /status
#   relay.sh health   /healthz answers and the identity is $RELAY_ADDR; exit 0 only then
#
# Logs at DEBUG as JSON lines into var/log/relay.log, capped by rotlog.py (RELAY_LOG_MB × files).
#
# The app speaks plain ws:// to a loopback relay and wss:// to anything else (LEPIC
# crates/lepic-epicbox/src/session.rs check_security; app/lib/src/send_preflight.dart relayProbeUri),
# so a device reaches this relay as 127.0.0.1:$RELAY_PORT: adb reverse on the emulator, an ssh -R
# tunnel on a rig.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"

PID="$HERMETIC_RUN/relay.pid"
LOG="$HERMETIC_LOG/relay.log"
PG_CONTAINER=epic-relay-pg

pg() { bash "$RELAY_SRC/dev/pg.sh" "$@"; }
psql_in() {  # psql_in <db> <args...>, through the container, as dev/pg.sh does
    local db="$1"; shift
    docker exec -i "$PG_CONTAINER" psql -v ON_ERROR_STOP=1 -q -U epicrelay -d "$db" "$@"
}

ensure_db() {
    pg up >/dev/null
    if [ "$(psql_in epicrelay -tAc "SELECT 1 FROM pg_database WHERE datname = '$RELAY_PG_DB'")" != 1 ]; then
        psql_in epicrelay -c "CREATE DATABASE $RELAY_PG_DB"
    fi
    psql_in "$RELAY_PG_DB" < "$RELAY_SRC/dev/schema.sql"
}

case "${1:-status}" in
start)
    if alive "$PID"; then echo "relay: already running ($(cat "$PID"))"; exit 0; fi
    ensure_db
    cd "$RELAY_SRC"
    EPIC_RELAY_HOST=127.0.0.1 EPIC_RELAY_PORT="$RELAY_PORT" \
    EPIC_RELAY_EPICBOX_DOMAIN="$RELAY_DOMAIN" EPIC_RELAY_ALIASES="$RELAY_ALIASES" \
    EPIC_RELAY_PG_DSN="$RELAY_PG_DSN" EPIC_RELAY_LOG_LEVEL=DEBUG EPIC_RELAY_LOG_JSON=1 \
        nohup uv run --frozen epic-relay > >(python3 -I "$HERMETIC_SRC/rotlog.py" "$LOG" "$RELAY_LOG_MB" "$RELAY_LOG_FILES") 2>&1 &
    echo $! > "$PID"
    for _ in $(seq 30); do
        curl -sf -m 2 "http://$RELAY_ADDR/healthz" >/dev/null && break
        alive "$PID" || { echo "relay: exited; tail $LOG" >&2; tail -20 "$LOG" >&2; exit 1; }
        sleep 1
    done
    echo "relay: started ($(cat "$PID")), ws://$RELAY_ADDR, database $RELAY_PG_DB, log $LOG"
    ;;
stop)
    stop_pid "$PID" relay
    status_set relay null
    ;;
status)
    if alive "$PID"; then echo "relay: running ($(cat "$PID")) on ws://$RELAY_ADDR"; else echo "relay: stopped"; fi
    curl -s -m 5 "http://$RELAY_ADDR/status" || true
    echo
    ;;
health)
    if alive "$PID" && curl -sf -m 5 "http://$RELAY_ADDR/healthz" >/dev/null; then
        status_set relay "\"$RELAY_ADDR\""
        echo "relay: healthy at $RELAY_ADDR"
        exit 0
    fi
    status_set relay null
    echo "relay: not healthy"
    exit 1
    ;;
*)
    echo "usage: relay.sh {start|stop|status|health}" >&2
    exit 2
    ;;
esac
