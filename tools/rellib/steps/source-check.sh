#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# G2: tools/check.sh --full in its own D-Bus session with a fresh, unlocked keyring. The
# integration tests store wallet secrets in the keyring; an agent's shell has none (or a locked
# one), and simple_test then fails with KeyringLocked. The keyring lives in the step's folder.
# A rerun of a failed G2 (the marker `g2-failed` is in the step's folder: written when check.sh
# fails, removed when it passes) first runs `tools/check.sh --full --cached` (tools/t's result
# cache, which lives in ~/.cache/wfe-test-results, keyed by content, so it holds across attempts and
# checkouts): a failure there ends the step at once; a pass is no evidence, so the normal uncached
# `tools/check.sh --full` runs after it. A first attempt runs only the latter.
# Usage: source-check.sh <step out dir>   (from the release checkout)
set -euo pipefail
export XDG_DATA_HOME="${1:?step out dir}/xdg-data"
mkdir -p "$XDG_DATA_HOME"
marker="$1/g2-failed"
dbus-run-session -- bash -c '
  eval "$(printf rel | gnome-keyring-daemon --unlock --components=secrets)"
  export GNOME_KEYRING_CONTROL
  marker="$1"
  if [[ -f $marker ]]; then
    echo "G2 rerun: cached full check first, then the uncached evidence run"
    tools/check.sh --full --cached || { echo "G2 rerun: the cached check failed; step fails"; exit 1; }
  else
    echo "G2 first attempt: uncached full check"
  fi
  if tools/check.sh --full; then
    rm -f "$marker"
  else
    touch "$marker"
    exit 1
  fi' _ "$marker"
