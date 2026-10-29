#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copies a hidden dev chain's two settings files (app/tool/config/<chain>/settings.default.toml
# and app-config.toml) to where a WFE_DEV_NETWORKS build reads them: <data folder>/dev/<chain>/
# (docs/settings-file.md, "Test networks"). The app writes settings.toml there from the default
# copy on its first start on the chain. A dev chain without the two files does not start.
#
# Usage: app/tool/dev_settings.sh <floonet|usernet> [data folder] [--reset]
#   The data folder defaults to the desktop's, ~/.epic_cash_desktop. On a phone, give a local
#   folder and push dev/<chain>/ into the app's files folder yourself (adb). --reset keeps an
#   existing settings.toml as settings.toml.old-<time>, so the next start writes a fresh one.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
chain="${1:-}"
case "$chain" in
  floonet|usernet) ;;
  *) sed -n '8,11p' "$0" >&2; exit 2 ;;
esac
data="$HOME/.epic_cash_desktop"
reset=0
for a in "${@:2}"; do
  case "$a" in
    --reset) reset=1 ;;
    *) data="$a" ;;
  esac
done
dest="$data/dev/$chain"
mkdir -p "$dest"
cp "$here/config/$chain/settings.default.toml" "$dest/settings.default.toml"
cp "$here/config/$chain/app-config.toml" "$dest/app-config.toml"
if [ "$reset" -eq 1 ] && [ -f "$dest/settings.toml" ]; then
  mv "$dest/settings.toml" "$dest/settings.toml.old-$(date +%Y%m%d-%H%M%S)"
fi
echo "$chain settings: $dest/settings.default.toml, $dest/app-config.toml"
