#!/usr/bin/env bash
# Builds the split-per-ABI release APKs and writes update.json, the manifest the in-app updater
# reads (lib/src/updater.dart). Publish the APKs and update.json together, for example as the
# assets of one GitHub release, so .../releases/latest/download/update.json names this release.
#
# Usage: tool/release_android.sh <download-base-url> [notes]
#   download-base-url  where the APKs will be served, e.g.
#                      https://github.com/<owner>/<repo>/releases/download/v1.0.1
#
# Bump `version:` in pubspec.yaml first: Android installs an update only when its version code
# is higher, and only when it is signed with the same key as the installed app.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  sed -n '6,9p' "${BASH_SOURCE[0]}" >&2
  exit 64
fi
base_url="${1%/}"
notes="${2:-}"

aapt2="$(find "$ANDROID_HOME/build-tools" -maxdepth 2 -name aapt2 -type f | sort -V | tail -1)"
[[ -x "$aapt2" ]] || { echo "aapt2 not found under $ANDROID_HOME/build-tools" >&2; exit 1; }

cd "$app_dir"
flutter build apk --release --target-platform android-arm64,android-x64 --split-per-abi \
  ${WFE_UPDATE_URL:+--dart-define=WFE_UPDATE_URL="$WFE_UPDATE_URL"}

out="$app_dir/build/app/outputs/flutter-apk"
package="" version_name="" entries=()
for abi in arm64-v8a x86_64; do
  apk="$out/app-$abi-release.apk"
  [[ -f "$apk" ]] || { echo "missing $apk" >&2; exit 1; }
  # Keep only the first line in bash: `| head -1` would SIGPIPE aapt2 under pipefail.
  badging="$("$aapt2" dump badging "$apk")"
  badging="${badging%%$'\n'*}"
  package="$(sed -n "s/.*package: name='\([^']*\)'.*/\1/p" <<<"$badging")"
  code="$(sed -n "s/.*versionCode='\([0-9]*\)'.*/\1/p" <<<"$badging")"
  version_name="$(sed -n "s/.*versionName='\([^']*\)'.*/\1/p" <<<"$badging")"
  sha="$(sha256sum "$apk" | cut -d' ' -f1)"
  size="$(stat -c %s "$apk")"
  entries+=("$(jq -n --arg abi "$abi" --argjson code "$code" --arg url "$base_url/app-$abi-release.apk" \
    --arg sha "$sha" --argjson size "$size" \
    '{abi: $abi, versionCode: $code, url: $url, sha256: $sha, size: $size}')")
done

printf '%s\n' "${entries[@]}" | jq -s --arg package "$package" --arg name "$version_name" --arg notes "$notes" \
  '{schema: 1, packageName: $package, versionName: $name, notes: $notes, apks: .}' >"$out/update.json"

echo "Wrote $out/update.json for $package $version_name:"
jq -r '.apks[] | "  \(.abi) versionCode \(.versionCode) \(.size) bytes"' "$out/update.json"
echo "Publish app-arm64-v8a-release.apk, app-x86_64-release.apk and update.json at $base_url"
