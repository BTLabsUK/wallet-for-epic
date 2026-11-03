#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Relay and node down; the chain and the relay's database are kept. Idempotent.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$HERE/relay.sh" stop
bash "$HERE/node.sh" stop
