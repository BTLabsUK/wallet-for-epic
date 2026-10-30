#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# The install contract (docs/install-contract.md): fails, naming the item, when the code no
# longer keeps something existing installs depend on (data folders, files, store keys, app ids,
# update addresses), or when tools/install-contract.json changed without a change record.
# Usage: tools/check-install-contract.sh [--hash]
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"
exec python3 -I tools/install_contract.py "$@"
