#!/usr/bin/env bash
# Fetches the Tor Expert Bundle pinned in tools/tor-bundle.json and keeps only what the desktop
# app runs (app/lib/src/tor_location.dart): tor and its libraries, and Tor's licence. The tarball
# and every kept file are checked against the pinned SHA-256; any mismatch fails and writes
# nothing to <out dir>.
#
# Usage: tools/fetch-tor.sh <linux|win|mac|macsilicon> <out dir>
#   Release builds copy <out dir> to bin/tor-bundle/ next to the app's executable (macOS:
#   Contents/Resources/bin/tor-bundle; tools/build-apple.sh joins mac and macsilicon with lipo).
#        tools/fetch-tor.sh android <jniLibs dir>
#   Android: only tor/libTor.so of each ABI is kept, as <jniLibs dir>/<abi>/libtor.so (the folder
#   app/android/app/build.gradle.kts packs as jniLibs; a PIE executable that Android extracts to
#   the app's native library folder) and Tor's licence as <jniLibs dir>/LICENSE.tor.txt.
# Env:   TOR_CACHE=<dir>   where tarballs are kept (default ~/.cache/epic-gui-tor/<version>);
#                          a cached tarball is used only when its hash matches.
#        TOR_ANDROID_ABIS  ABIs for `android` (default "arm64-v8a x86_64", the ABIs the app ships;
#                          the pins also cover armeabi-v7a and x86).
#
# The pins are SHA-256 only; this script never checks a signature. Moving them to a new bundle is
# done by hand, and the new hashes are written only after the Tor Project's signature checks:
#   gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org   (the `wkd`)
#   gpg --fingerprint EF6E286DDA85EA2A4BA7DE684E2C6E8793298290                    (`signingKey`)
#   curl -fLO --proto '=https' <baseUrl><version>/<tarball> and the same URL + .asc
#   gpg --verify <tarball>.asc <tarball>     (Good signature from that key, or stop)
#   sha256sum <tarball>, then the kept files after extracting, into tools/tor-bundle.json.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pins="$root/tools/tor-bundle.json"
plat="${1:-}"
out="${2:-}"
usage="usage: $0 <linux|win|mac|macsilicon|android> <out dir>"
case "$plat" in linux|win|mac|macsilicon|android|android-arm64-v8a|android-x86_64|android-armeabi-v7a|android-x86) ;; *) echo "$usage" >&2; exit 2 ;; esac
[[ -n "$out" ]] || { echo "$usage" >&2; exit 2; }

if [[ "$plat" == android ]]; then
  for abi in ${TOR_ANDROID_ABIS:-arm64-v8a x86_64}; do
    "$0" "android-$abi" "$out"
  done
  exit 0
fi

version="$(jq -r .bundleVersion "$pins")"
tarball="$(jq -r ".platforms[\"$plat\"].tarball" "$pins")"
want="$(jq -r ".platforms[\"$plat\"].sha256" "$pins")"
license="$(jq -r ".platforms[\"$plat\"].license" "$pins")"
cache="${TOR_CACHE:-$HOME/.cache/epic-gui-tor/$version}"
mkdir -p "$cache"

# macOS has shasum, not always sha256sum.
hash_of() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

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
check() { # <source> <name> <pinned hash> [<installed name>]
  local h
  h="$(hash_of "$1")"
  [[ "$h" == "$3" ]] || { echo "$2 hash mismatch: $h, pinned $3" >&2; exit 1; }
  install -m 755 "$1" "$staged/${4:-$2}"
  echo "$2 ok"
}
while IFS=$'\t' read -r name hash; do
  if [[ "$plat" == android-* ]]; then
    check "$work/tor/$name" "$name" "$hash" "${name,,}"   # libTor.so -> libtor.so
  else
    check "$work/tor/$name" "$name" "$hash"
  fi
done < <(jq -r ".platforms[\"$plat\"].files | to_entries[] | \"\(.key)\t\(.value)\"" "$pins")
check "$work/docs/tor.txt" LICENSE.tor.txt "$license"
chmod 644 "$staged/LICENSE.tor.txt"
printf 'Tor Expert Bundle %s, tor %s\n' "$version" "$(jq -r .tor "$pins")" > "$staged/VERSION"

# Only a fully checked set lands in <out dir>.
if [[ "$plat" == android-* ]]; then
  abi="${plat#android-}"
  mkdir -p "$out/$abi"
  install -m 755 "$staged/libtor.so" "$out/$abi/libtor.so"
  install -m 644 "$staged/LICENSE.tor.txt" "$out/LICENSE.tor.txt"
  echo "tor ($plat) in $out/$abi"
  exit 0
fi
mkdir -p "$out"
cp -a "$staged/." "$out/"
echo "tor bundle ($plat) in $out"
