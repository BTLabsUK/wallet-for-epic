#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Fetches a pinned external input of the hosted builds (tools/build-inputs.json): downloads it over
# https, checks its sha256 and prints the path of the file. Nothing is written to <out dir> unless
# the hash matches. Works in bash on Linux and in Git Bash on Windows (curl, sha256sum, sed).
#
# Usage: tools/fetch-build-inputs.sh node <linux|windows> <out dir>
#   prints <out dir>/epic (linux) or <out dir>/epic.exe (windows)
# The builds call it only when WFE_FETCH_INPUTS=1 (the hosted runner) and the node binary is not
# given by WFE_NODE_BIN / WFE_NODE_BIN_WIN.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pins="$root/tools/build-inputs.json"
usage="usage: $0 node <linux|windows> <out dir>"
kind="${1:-}" plat="${2:-}" out="${3:-}"
[[ "$kind" == node && ( "$plat" == linux || "$plat" == windows ) && -n "$out" ]] || { echo "$usage" >&2; exit 2; }

# The platform's block of the pins, read with sed so that neither jq nor python is needed on the
# Windows runner; the file keeps one key per line.
block="$(sed -n "/\"node\"/,/\"ndk\"/p" "$pins" | sed -n "/\"$plat\": *{/,/}/p")"
field() { sed -n "s/^ *\"$1\": *\"\([^\"]*\)\".*/\1/p" <<<"$block" | head -1; }
url="$(field url)" want="$(field sha256)" file="$(field file)"
[[ -n "$url" && -n "$want" && -n "$file" ]] || { echo "$pins has no node pin for $plat" >&2; exit 1; }

mkdir -p "$out"
dest="$out/$file"
part="$(mktemp "$out/.fetch.XXXXXX")"
trap 'rm -f -- "$part"' EXIT
curl -fsS --proto '=https' --tlsv1.2 --retry 0 -o "$part" "$url" >&2
got="$(sha256sum "$part" | cut -d' ' -f1)"
if [[ "$got" != "$want" ]]; then
  echo "$url: sha256 $got, pinned $want" >&2
  exit 1
fi
mv -f -- "$part" "$dest"
chmod 755 "$dest"
echo "$dest"
