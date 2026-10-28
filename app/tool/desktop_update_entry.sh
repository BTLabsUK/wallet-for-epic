#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Prints the `desktop` block of update.json for a release (btlabs-public FORMAT.md section 6):
# per system the version and the release file the desktop downloads and installs by itself
# (lib/src/desktop/data/desk_update.dart), with its SHA-256 and size read from the file.
# Usage: tool/desktop_update_entry.sh <version> <folder>
#   version  the release, e.g. 26.10.9
#   folder   holds the two files exactly as published in
#            https://examples.btlabs.uk/epic-cash-wallets/downloads/:
#              epic-cash-desktop-<version>-windows-x64-setup.exe
#              EpicCashDesktop-<version>-x86_64.AppImage
#
# Output: {"desktop": {...}}, to put into the payload by hand or with
#   jq -s '.[0] * .[1]' update.payload.json <(tool/desktop_update_entry.sh 26.10.9 <folder>)
# Clients up to 26.10.8 read only `version` from it (and `page`, which this block leaves out:
# a page off GitHub would make every client, phone included, reject the whole file).
set -euo pipefail

if [[ $# -ne 2 ]]; then
  sed -n '5,10p' "${BASH_SOURCE[0]}" >&2
  exit 64
fi
version="$1"
dir="${2%/}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "$version is not a release version (YY.MM.patch)" >&2; exit 64; }
base="https://examples.btlabs.uk/epic-cash-wallets/downloads"

entry() {
  local file="$dir/$1"
  [[ -f "$file" ]] || { echo "missing $file" >&2; exit 1; }
  jq -n --arg version "$version" --arg url "$base/$1" \
    --arg sha "$(sha256sum "$file" | cut -d' ' -f1)" --argjson size "$(stat -c %s "$file")" \
    '{version: $version, url: $url, sha256: $sha, size: $size}'
}

windows="$(entry "epic-cash-desktop-$version-windows-x64-setup.exe")"
linux="$(entry "EpicCashDesktop-$version-x86_64.AppImage")"
jq -n --argjson windows "$windows" --argjson linux "$linux" '{desktop: {windows: $windows, linux: $linux}}'
