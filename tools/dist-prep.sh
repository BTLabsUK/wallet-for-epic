#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Prepares a checkout for a distribution build (https://docs.btlabs.uk/developers/build/variants/). Since 26.10.24 every build
# reads QR codes with the free scanner (camera + flutter_zxing) and none has Firebase, Google
# Play services or ML Kit, so there is nothing to edit any more: for `fdroid` (the step F-Droid's
# prebuild runs) this script only checks that nothing in app/lib, app/android, pubspec.yaml or
# the lock names Firebase, Google Play services or ML Kit, and fails if something does. Then run
# `flutter pub get --enforce-lockfile` and build with --dart-define=WFE_DIST=fdroid.
#
# Usage: tools/dist-prep.sh <web|play|fdroid> [--root <repo dir>] [--dry-run]
#   web, play   nothing to do: WFE_DIST alone makes those builds (the dart-define and Gradle).
#   --root      the checkout to check (default: the one this script is in).
#   --dry-run   kept for old recipes: the script changes nothing anyway.
set -euo pipefail

usage="usage: $0 <web|play|fdroid> [--root <repo dir>] [--dry-run]"
dist="${1:-}"
[[ $# -gt 0 ]] && shift
root="$(cd "$(dirname "$0")/.." && pwd)"
dry=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) root="$(cd "${2:?$usage}" && pwd)"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    *) echo "$usage" >&2; exit 2 ;;
  esac
done
case "$dist" in
  web|play) echo "WFE_DIST=$dist: nothing to prepare"; exit 0 ;;
  fdroid) ;;
  *) echo "$usage" >&2; exit 2 ;;
esac

app="$root/app"
[[ -f "$app/pubspec.yaml" && -f "$app/lib/src/ui/scanner_backend.dart" ]] \
  || { echo "$root is not a wallet-for-epic checkout" >&2; exit 1; }

echo "Checking $root for WFE_DIST=fdroid$([[ $dry == 1 ]] && echo ' (dry run: nothing to change either way)')"

# Check: nothing proprietary named where the Android build reads. Comments that explain it and
# the manifest lines that remove what a plugin declares and Gradle's guard do not count.
left="$(grep -rniE 'firebase|google-services|com\.google\.gms|com\.google\.android\.gms|play-services|mlkit|mobile_scanner' \
  "$app/pubspec.yaml" "$app/pubspec.lock" "$app/lib" "$app/android" \
  --exclude-dir=build --exclude-dir=.gradle --exclude='GeneratedPluginRegistrant.java' \
  --exclude=google-services.json || true)"
left="$(grep -vE ':[0-9]+:\s*(//|///|#|\*|<!--)|tools:node="remove"|dist-prep: names only' <<<"$left" || true)"
if [[ -n "$left" ]]; then
  echo "Still named (take it out of the code):" >&2
  echo "$left" >&2
  exit 1
fi
echo "Nothing to change. Next: (cd app && flutter pub get --enforce-lockfile), then build with --dart-define=WFE_DIST=fdroid."
