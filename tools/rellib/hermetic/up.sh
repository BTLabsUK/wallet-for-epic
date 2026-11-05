#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Node and relay up, then both health checks (which write status.json). Idempotent: a running service
# is left alone. Exits 0 when both are healthy; a node still syncing makes it exit 1 with the relay up.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# A dry run of tools/rel starts nothing here, as its drivers touch nothing.
if [ "${REL_DRY_RUN:-0}" = 1 ]; then echo "up: dry run: node and relay not started"; exit 0; fi
. "$HERE/env.sh"
# Trust lanes start side by side and each runs this (release/pipeline.toml): one at a time, so two
# never both start a node or a relay.
mkdir -p "$HERMETIC_RUN"
exec 9>"$HERMETIC_RUN/up.lock"
flock -w 600 9 || { echo "up: another up.sh still holds $HERMETIC_RUN/up.lock after 10 min" >&2; exit 1; }
# 9>&-: the services started here must not inherit the lock and hold it after this script ends
bash "$HERE/node.sh" start 9>&- || exit 1
bash "$HERE/relay.sh" start 9>&- || exit 1
rc=0
bash "$HERE/relay.sh" health || rc=1
bash "$HERE/node.sh" health || rc=1
exit $rc
