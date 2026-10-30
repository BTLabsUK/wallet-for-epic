#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Prints the `desktop` block of update.json for a release (btlabs-public FORMAT.md section 6):
# per system the version and the release file the desktop downloads and installs by itself
# (lib/src/desktop/data/desk_update.dart), with its SHA-256 and size read from the file.
# Usage: tool/desktop_update_entry.sh <version> <folder>
#   version  the release, e.g. 26.10.9
#   folder   holds the files exactly as published in
#            https://epiccash.btlabs.uk/releases/downloads/ (the same folder as
#            https://examples.btlabs.uk/epic-cash-wallets/downloads/):
#              epic-cash-desktop-<version>-windows-x64-setup.exe
#              EpicCashDesktop-<version>-x86_64.AppImage
#              EpicCashDesktop-<version>-macos.dmg          (when the Apple build ships)
#            and their -notor twins for the builds without Tor
#            (epic-cash-desktop-<version>-notor-windows-x64-setup.exe, …), which go into
#            {"notor": {"desktop": {...}}}, the part only those builds read. A release ships
#            both variants: the Windows and Linux files of each are required.
#
# Output: {"desktop": {...}, "notor": {"desktop": {...}}}, to put into the payload by hand or with
#   jq -s '.[0] * .[1]' update.payload.json <(tool/desktop_update_entry.sh 26.10.9 <folder>)
# (tool/release_android.sh does it with WFE_DESKTOP_DIR). Clients up to 26.10.8 read only
# `version` from it (and `page`, which this block leaves out: a page off GitHub would make every
# client, phone included, reject the whole file); every client reads only its own system's entry,
# and clients up to 26.10.22 ignore the notor section.
set -euo pipefail
shopt -s inherit_errexit

if [[ $# -ne 2 ]]; then
  sed -n '6,16p' "${BASH_SOURCE[0]}" >&2
  exit 64
fi
version="$1"
dir="${2%/}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "$version is not a release version (YY.MM.patch)" >&2; exit 64; }
# The old name by default, for the old-format update.json: clients up to 26.10.23 accept a desktop
# file only under it and reject the whole manifest otherwise (https://docs.btlabs.uk/developers/releases/, Release
# addresses). tool/release_android.sh moves the URLs to the app's own address for update-v2.json;
# WFE_DOWNLOADS_BASE prints them under another address directly. Same files either way.
base="${WFE_DOWNLOADS_BASE:-https://examples.btlabs.uk/epic-cash-wallets/downloads}"
base="${base%/}"

entry() {
  local file="$dir/$1"
  [[ -f "$file" ]] || { echo "missing $file" >&2; exit 1; }
  jq -n --arg version "$version" --arg url "$base/$1" \
    --arg sha "$(sha256sum "$file" | cut -d' ' -f1)" --argjson size "$(stat -L -c %s "$file")" \
    '{version: $version, url: $url, sha256: $sha, size: $size}'
}

# WFE_DESKTOP_KEEP=<json> (tools/rellib/steps/desktop_keep.py): for a system this release has no
# file for, its entry from the live manifest, unchanged ({"desktop": {...}, "notor": {"desktop":
# {...}}}). A release that leaves a desktop system out keeps offering that system what it had.
kept() { # system variant → the kept entry, or exit non-zero
  [[ -n "${WFE_DESKTOP_KEEP:-}" ]] || return 1
  if [[ -z "$2" ]]; then jq -ec --arg s "$1" '.desktop[$s] // empty' "$WFE_DESKTOP_KEEP"
  else jq -ec --arg s "$1" '.notor.desktop[$s] // empty' "$WFE_DESKTOP_KEEP"; fi
}
pick() { # system variant file → this release's file, else the kept entry, else "missing"
  if [[ -f "$dir/$3" ]]; then entry "$3"; else kept "$1" "$2" || entry "$3"; fi
}

# One variant's block: Windows and Linux required (this release's or kept), macOS when its dmg
# is there or kept. $1 is "" or -notor.
systems() {
  local v="$1" windows linux macos="null"
  windows="$(pick windows "$v" "epic-cash-desktop-$version$v-windows-x64-setup.exe")"
  linux="$(pick linux "$v" "EpicCashDesktop-$version$v-x86_64.AppImage")"
  if [[ -f "$dir/EpicCashDesktop-$version$v-macos.dmg" ]]; then
    macos="$(entry "EpicCashDesktop-$version$v-macos.dmg")"
  elif kept macos "$v" >/dev/null; then
    macos="$(kept macos "$v")"
  fi
  jq -n --argjson windows "$windows" --argjson linux "$linux" --argjson macos "$macos" \
    '{windows: $windows, linux: $linux} + (if $macos == null then {} else {macos: $macos} end)'
}

tor="$(systems "")"
notor="$(systems -notor)"
jq -n --argjson tor "$tor" --argjson notor "$notor" '{desktop: $tor, notor: {desktop: $notor}}'
