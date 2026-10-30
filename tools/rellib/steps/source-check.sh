#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# G2: tools/check.sh --full in its own D-Bus session with a fresh, unlocked keyring. The
# integration tests store wallet secrets in the keyring; an agent's shell has none (or a locked
# one), and simple_test then fails with KeyringLocked. The keyring lives in the step's folder.
# Usage: source-check.sh <step out dir>   (from the release checkout)
set -euo pipefail
export XDG_DATA_HOME="${1:?step out dir}/xdg-data"
mkdir -p "$XDG_DATA_HOME"
exec dbus-run-session -- bash -c '
  eval "$(printf rel | gnome-keyring-daemon --unlock --components=secrets)"
  export GNOME_KEYRING_CONTROL
  exec tools/check.sh --full'
