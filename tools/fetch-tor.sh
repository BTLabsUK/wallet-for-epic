#!/usr/bin/env bash
# Fetches the Tor Expert Bundle pinned in tools/tor-bundle.json and keeps only what the desktop
# app runs (app/lib/src/tor_location.dart): tor and its libraries, and Tor's licence. The tarball
# and every kept file are checked against the pinned SHA-256; any mismatch fails and writes
# nothing to <out dir>.
#
# Usage: tools/fetch-tor.sh <linux|win> <out dir>
#   Release builds copy <out dir> to bin/tor-bundle/ next to the app's executable.
# Env:   TOR_CACHE=<dir>   where tarballs are kept (default ~/.cache/epic-gui-tor/<version>);
#                          a cached tarball is used only when its hash matches.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pins="$root/tools/tor-bundle.json"
plat="${1:-}"
out="${2:-}"
case "$plat" in linux|win) ;; *) echo "usage: $0 <linux|win> <out dir>" >&2; exit 2 ;; esac
[[ -n "$out" ]] || { echo "usage: $0 <linux|win> <out dir>" >&2; exit 2; }

version="$(jq -r .bundleVersion "$pins")"
tarball="$(jq -r ".platforms.$plat.tarball" "$pins")"
want="$(jq -r ".platforms.$plat.sha256" "$pins")"
license="$(jq -r ".platforms.$plat.license" "$pins")"
cache="${TOR_CACHE:-$HOME/.cache/epic-gui-tor/$version}"
mkdir -p "$cache"

hash_of() { sha256sum "$1" | cut -d' ' -f1; }

file="$cache/$tarball"
part="$file.part"
if [[ ! -f "$file" || "$(hash_of "$file")" != "$want" ]]; then
  ok=
  for base in $(jq -r '.baseUrls[]' "$pins"); do
    echo "downloading $base$version/$tarball"
    if curl -fsSL --proto '=https' --proto-redir '=https' --retry 2 --connect-timeout 20 -o "$part" "$base$version/$tarball"; then
      ok=1
      break
    fi
  done
  [[ -n "$ok" ]] || { rm -f -- "$part"; echo "download failed" >&2; exit 1; }
  mv -f "$part" "$file"
fi
got="$(hash_of "$file")"
if [[ "$got" != "$want" ]]; then
  rm -f -- "$file"
  echo "tarball hash mismatch: $got, pinned $want (removed)" >&2
  exit 1
fi
echo "tarball ok $got"

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
tar -xzf "$file" -C "$work" tor docs/tor.txt

staged="$work/keep"
mkdir -p "$staged"
check() { # <source> <name> <pinned hash>
  local h
  h="$(hash_of "$1")"
  [[ "$h" == "$3" ]] || { echo "$2 hash mismatch: $h, pinned $3" >&2; exit 1; }
  install -m 755 "$1" "$staged/$2"
  echo "$2 ok"
}
while IFS=$'\t' read -r name hash; do
  check "$work/tor/$name" "$name" "$hash"
done < <(jq -r ".platforms.$plat.files | to_entries[] | \"\(.key)\t\(.value)\"" "$pins")
check "$work/docs/tor.txt" LICENSE.tor.txt "$license"
chmod 644 "$staged/LICENSE.tor.txt"
printf 'Tor Expert Bundle %s, tor %s\n' "$version" "$(jq -r .tor "$pins")" > "$staged/VERSION"

# Only a fully checked set lands in <out dir>.
mkdir -p "$out"
cp -a "$staged/." "$out/"
echo "tor bundle ($plat) in $out"
