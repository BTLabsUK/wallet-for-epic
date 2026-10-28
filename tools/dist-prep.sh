#!/usr/bin/env bash
# Prepares a checkout for a distribution build (https://docs.btlabs.uk/developers/build/variants/). Only the F-Droid build
# needs it: Flutter packs every plugin named in pubspec.yaml, so a dart-define alone cannot keep
# Google ML Kit (the QR scanner of the other builds) out of the APK. The app has no Firebase or
# other Google push code in any build since 26.10.20. For `fdroid` this script edits the
# checkout in place:
#
#   - the QR scanner: mobile_scanner (Google ML Kit) out of app/pubspec.yaml, camera +
#     flutter_zxing (zxing-cpp, built from its bundled source) in; the two scanner screens import
#     scanner_backend_foss.dart, and scanner_backend.dart is deleted;
#   - app/pubspec.lock: replaced by app/pubspec.fdroid.lock, the lock of this dependency set;
#
# then checks that nothing in app/lib, app/android, pubspec.yaml or the lock names Firebase,
# Google Play services or ML Kit. Run `flutter pub get --enforce-lockfile` afterwards, then build
# with --dart-define=WFE_DIST=fdroid; android/app/build.gradle.kts refuses WFE_DIST=fdroid while
# mobile_scanner is there.
#
# The edits are not meant to be committed: run it in a build checkout (F-Droid's prebuild, a
# fresh clone, or a copy), never in a working tree with changes of its own.
#
# Usage: tools/dist-prep.sh <web|play|fdroid> [--root <repo dir>] [--dry-run]
#   web, play   nothing to do: WFE_DIST alone makes those builds (the dart-define and Gradle).
#   --root      the checkout to edit (default: the one this script is in).
#   --dry-run   print what would change, change nothing.
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
[[ -f "$app/pubspec.yaml" && -f "$app/lib/src/ui/scanner_backend_foss.dart" ]] \
  || { echo "$root is not a wallet-for-epic checkout with the F-Droid scanner" >&2; exit 1; }

# One step: says what it does, does it unless --dry-run.
step() { # description, command...
  local what="$1"; shift
  echo "  $what"
  [[ $dry == 1 ]] || "$@"
}
# Deletes the lines of $1 that match the extended regex $2, failing when none does (the file
# changed shape and this script must follow).
drop_lines() {
  grep -qE "$2" "$1" || { echo "no line matching '$2' in $1" >&2; return 1; }
  sed -i -E "\\#$2#d" "$1"
}

echo "Preparing $root for WFE_DIST=fdroid$([[ $dry == 1 ]] && echo ' (dry run)')"

# mobile_scanner reads codes with ML Kit; the F-Droid build reads them with zxing-cpp
# (flutter_zxing) on frames from the camera plugin (CameraX). scanner_backend.dart and
# scanner_backend_foss.dart have the same API.
if grep -q '^  mobile_scanner:' "$app/pubspec.yaml"; then
  step "pubspec.yaml: mobile_scanner out, camera and flutter_zxing in" \
    sed -i -E 's#^  mobile_scanner: .*#  camera: 0.12.2\n  flutter_zxing: 3.1.0#' "$app/pubspec.yaml"
fi
for f in lib/src/ui/qr_camera.dart lib/src/ui/scan_screen.dart; do
  if grep -q "^import 'scanner_backend.dart';" "$app/$f"; then
    step "$f: import scanner_backend_foss.dart" \
      sed -i "s#^import 'scanner_backend.dart';#import 'scanner_backend_foss.dart';#" "$app/$f"
  fi
done
[[ -e "$app/lib/src/ui/scanner_backend.dart" ]] \
  && step "delete lib/src/ui/scanner_backend.dart" rm -- "$app/lib/src/ui/scanner_backend.dart"
if grep -q 'lib/src/ui/scanner_backend_foss.dart' "$app/analysis_options.yaml"; then
  step "analysis_options.yaml: analyse scanner_backend_foss.dart" \
    drop_lines "$app/analysis_options.yaml" "lib/src/ui/scanner_backend_foss\.dart|The F-Droid build's scanner: its packages"
fi

# The lockfile of this dependency set, so every F-Droid build resolves the same packages.
step "pubspec.lock: the F-Droid lockfile (pubspec.fdroid.lock)" cp "$app/pubspec.fdroid.lock" "$app/pubspec.lock"

[[ $dry == 1 ]] && { echo "Dry run: nothing changed."; exit 0; }

# Check: nothing proprietary named where the Android build reads. Comments that explain it and
# the manifest lines that remove what a plugin declares and Gradle's guard do not count.
left="$(grep -rniE 'firebase|google-services|com\.google\.gms|com\.google\.android\.gms|play-services|mlkit|mobile_scanner' \
  "$app/pubspec.yaml" "$app/pubspec.lock" "$app/lib" "$app/android" \
  --exclude-dir=build --exclude-dir=.gradle --exclude='GeneratedPluginRegistrant.java' \
  --exclude=google-services.json || true)"
left="$(grep -vE ':[0-9]+:\s*(//|///|#|\*|<!--)|tools:node="remove"|dist-prep: names only' <<<"$left" || true)"
if [[ -n "$left" ]]; then
  echo "Still named after preparing (fix this script or the code):" >&2
  echo "$left" >&2
  exit 1
fi
echo "Done. Next: (cd app && flutter pub get --enforce-lockfile), then build with --dart-define=WFE_DIST=fdroid."
