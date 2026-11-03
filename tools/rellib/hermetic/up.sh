#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Node and relay up, then both health checks (which write status.json). Idempotent: a running service
# is left alone. Exits 0 when both are healthy; a node still syncing makes it exit 1 with the relay up.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$HERE/node.sh" start || exit 1
bash "$HERE/relay.sh" start || exit 1
rc=0
bash "$HERE/relay.sh" health || rc=1
bash "$HERE/node.sh" health || rc=1
exit $rc
