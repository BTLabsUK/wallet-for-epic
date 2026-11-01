#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Installs the shared test binaries tool for this user. Idempotent.
#   tools/testbin/install.sh
# Copies testbin.py to ~/.local/lib/wfe-testbin/ (tools/testbin.sh in any worktree runs it), links
# ~/.local/bin/wfe-testbin to it, installs the units in ~/.config/systemd/user/ and enables
# wfe-testbin.timer. TESTBIN_NO_TIMER=1 installs without enabling the timer.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
lib="$HOME/.local/lib/wfe-testbin"
units="$HOME/.config/systemd/user"
install -d "$lib" "$units" "$HOME/.local/bin" "$HOME/epic-build/testbins"
install -m 755 "$here/testbin.py" "$lib/testbin.py"
ln -sfn "$lib/testbin.py" "$HOME/.local/bin/wfe-testbin"
for u in wfe-testbin.service wfe-testbin.timer; do
  install -m 644 "$here/$u" "$units/$u"
done
systemctl --user daemon-reload
if [ -z "${TESTBIN_NO_TIMER:-}" ]; then
  systemctl --user enable --now wfe-testbin.timer
  systemctl --user list-timers wfe-testbin.timer --no-pager
fi
echo "installed: $lib/testbin.py, ~/.local/bin/wfe-testbin, units in $units"
