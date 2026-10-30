#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Installs the nightly full check (tools/nightly/nightly.py) for this user. Idempotent.
#   tools/nightly/install.sh
# Copies nightly.py to ~/.local/lib/wfe-nightly/ (a run never executes the reporter from the
# worktree it tests), the units to ~/.config/systemd/user/, reloads systemd, enables the timer and
# creates the run worktree ~/wfe-worktrees/nightly (detached, at main) when it is missing. It
# takes away the old by-hand unit wfe-nightly-now.service (a by-hand run is now
# `python3 ~/.local/lib/wfe-nightly/nightly.py --by-hand`). Nothing is sent until
# ~/.config/wfe-nightly/notify_url and notify_token exist (see nightly.py's header).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="${WFE_NIGHTLY_REPO:-$HOME/wallet-for-epic}"
worktree="${WFE_NIGHTLY_WORKTREE:-$HOME/wfe-worktrees/nightly}"
lib="$HOME/.local/lib/wfe-nightly"
units="$HOME/.config/systemd/user"

install -d "$lib" "$units" "$HOME/epic-build/nightly"
install -m 755 "$here/nightly.py" "$lib/nightly.py"
for u in wfe-nightly.service wfe-nightly.timer; do
  install -m 644 "$here/$u" "$units/$u"
done
if [ -e "$units/wfe-nightly-now.service" ]; then
  systemctl --user disable wfe-nightly-now.service >/dev/null 2>&1 || true
  rm -f "$units/wfe-nightly-now.service"
fi
systemctl --user daemon-reload
systemctl --user enable --now wfe-nightly.timer

if [ ! -e "$worktree/.git" ]; then
  git -C "$repo" worktree add --detach "$worktree" refs/heads/main
fi
echo "installed: $lib/nightly.py, units in $units, run worktree $worktree"
systemctl --user list-timers wfe-nightly.timer --no-pager
