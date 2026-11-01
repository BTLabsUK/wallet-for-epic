#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Shared test binaries (docs/dev-tooling.md, "Test binaries"): prints the path of the Linux debug
# bundle or the debug APK of a commit, from /tmp/epic-build/testbins/, building it once on a miss.
#   tools/testbin.sh get [linux|apk] [--commit X] [--variant tor|notor] [--no-build]
#   tools/testbin.sh list | refresh | prune
# Runs the installed copy (tools/testbin/install.sh) when there is one, so every worktree uses
# the same store format; else this worktree's tools/testbin/testbin.py.
set -euo pipefail
installed="$HOME/.local/lib/wfe-testbin/testbin.py"
here="$(cd "$(dirname "$0")" && pwd)/testbin/testbin.py"
if [ -f "$installed" ] && [ -z "${TESTBIN_LOCAL:-}" ]; then exec python3 "$installed" "$@"; fi
exec python3 "$here" "$@"
