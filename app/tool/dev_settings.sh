#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copies a hidden dev chain's settings file (app/tool/settings/<chain>.toml) to where a dev
# build reads it: <data folder>/dev/<chain>/settings.toml (docs/settings-file.md, "Test
# networks"). A dev chain without its file does not start.
#
# Usage: app/tool/dev_settings.sh <floonet|usernet> [data folder]
#   The data folder defaults to the desktop's, ~/.epic_cash_desktop. On a phone, give a local
#   folder and push dev/<chain>/settings.toml into the app's files folder yourself (adb).
#   An existing file is kept as settings.toml.old-<time> before it is replaced.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
chain="${1:-}"
case "$chain" in
  floonet|usernet) ;;
  *) sed -n '7,10p' "$0" >&2; exit 2 ;;
esac
data="${2:-$HOME/.epic_cash_desktop}"
dest="$data/dev/$chain"
mkdir -p "$dest"
if [ -f "$dest/settings.toml" ]; then
  mv "$dest/settings.toml" "$dest/settings.toml.old-$(date +%Y%m%d-%H%M%S)"
fi
cp "$here/settings/$chain.toml" "$dest/settings.toml"
echo "$chain settings: $dest/settings.toml"
