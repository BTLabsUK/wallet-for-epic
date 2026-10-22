#!/usr/bin/env bash
# Builds the split-per-ABI release APKs and writes the signed update.json, the manifest the
# in-app updater reads (lib/src/updater.dart; btlabs-public FORMAT.md section 6). The APKs go
# to the GitHub release; update.json goes to BT Labs' Pages repo, BTLabs-EPIC/btlabs-epic.github.io,
# served as https://btlabs-epic.github.io/update.json. Publish the APKs first.
# Usage: tool/release_android.sh <download-base-url> [notes]
#   download-base-url  where the APKs will be served (https), e.g.
#                      https://github.com/BTLabs-EPIC/wallet-for-epic/releases/download/v1.0.1
#   notes              plain text; line feeds allowed, no tabs or carriage returns
#
# It writes update.payload.json (unsigned; serial = issued_at in Unix seconds, expiry in 182
# days) and signs it with btlabs-public's tool when the signing key is on this machine:
#   BTLABS_PUBLIC       the btlabs-public checkout (default ~/code/btlabs-public)
#   BTLABS_SIGNING_KEY  the rank-1 key (default ~/.config/btlabs/signing/btlabs-2026-a.key)
# Without them it stops after the payload and prints the signing command.
#
# WFE_DESKTOP_RELEASE=1 adds the `desktop` entry the desktop update check reads
# (lib/src/desktop/data/desk_update.dart): set it only when this release also ships desktop
# builds, else the desktop would offer a release that has none. Its page is the release's tag
# page, derived from download-base-url.
#
# Bump `version:` in pubspec.yaml first: Android installs an update only when its version code
# is higher, and only when it is signed with the same key as the installed app.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  sed -n '5,8p' "${BASH_SOURCE[0]}" >&2
  exit 64
fi
base_url="${1%/}"
notes="${2:-}"
if [[ "$notes" == *$'\r'* || "$notes" == *$'\t'* ]]; then
  echo "notes: no tabs or carriage returns (FORMAT.md section 6)" >&2
  exit 64
fi
btlabs_public="${BTLABS_PUBLIC:-$HOME/code/btlabs-public}"
signing_key="${BTLABS_SIGNING_KEY:-$HOME/.config/btlabs/signing/btlabs-2026-a.key}"

aapt2="$(find "$ANDROID_HOME/build-tools" -maxdepth 2 -name aapt2 -type f | sort -V | tail -1)"
[[ -x "$aapt2" ]] || { echo "aapt2 not found under $ANDROID_HOME/build-tools" >&2; exit 1; }

cd "$app_dir"
# After `flutter test`, the plugin registrant can still list the dev-only integration_test plugin,
# and the first release build then fails to compile it. `pub get` regenerates it first.
flutter pub get
# package:lepic's build hook bundles prebuilt libraries and fails without them, whichever core
# the build selects. Up to date, this is a no-op build.
"$app_dir/../tools/lepic.sh" build android
flutter build apk --release --target-platform android-arm64 --split-per-abi \
  ${WFE_UPDATE_URL:+--dart-define=WFE_UPDATE_URL="$WFE_UPDATE_URL"} \
  ${WFE_CORE:+--dart-define=WFE_CORE="$WFE_CORE"}

out="$app_dir/build/app/outputs/flutter-apk"
package="" version_name="" entries=()
# The phone download is arm64-v8a only; x86_64 builds are for our own emulators, never published.
for abi in arm64-v8a; do
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

desktop_page=""
if [[ "${WFE_DESKTOP_RELEASE:-}" == 1 ]]; then
  desktop_page="${base_url/\/releases\/download\//\/releases\/tag\/}"
fi
issued_epoch="$(date -u +%s)"
issued_at="$(date -u -d "@$issued_epoch" +%Y-%m-%dT%H:%M:%SZ)"
expires_at="$(date -u -d "@$((issued_epoch + 182 * 86400))" +%Y-%m-%dT%H:%M:%SZ)"
payload="$out/update.payload.json"
manifest="$out/update.json"
rm -f "$manifest"
printf '%s\n' "${entries[@]}" | jq -s --arg package "$package" --arg name "$version_name" --arg notes "$notes" \
  --arg page "$desktop_page" --argjson serial "$issued_epoch" --arg issued "$issued_at" --arg expires "$expires_at" \
  '($notes | sub("^\\s+"; "") | sub("\\s+$"; "")) as $n
   | {schema: 1, serial: $serial, issued_at: $issued, expires_at: $expires,
      packageName: $package, versionName: $name, apks: .}
   + (if $n == "" then {} else {notes: $n} end)
   + (if $page == "" then {} else {desktop: {version: $name, page: $page}} end)' >"$payload"

echo "Wrote $payload for $package $version_name (serial $issued_epoch, expires $expires_at):"
jq -r '.apks[] | "  \(.abi) versionCode \(.versionCode) \(.size) bytes"' "$payload"

tool="$btlabs_public/tool/btlabs_sign.py"
keyring="$btlabs_public/keys/btlabs-keyring.json"
sign=(python3 "$tool" sign --type update --key "$signing_key" --keyring "$keyring" --payload "$payload" --out "$manifest")
if [[ ! -f "$tool" || ! -f "$keyring" || ! -f "$signing_key" ]]; then
  echo "Not signed: needs $tool, $keyring and the signing key $signing_key." >&2
  echo "On the signing machine run:" >&2
  printf '  %q' "${sign[@]}" >&2
  echo >&2
  exit 1
fi
# The tool refuses a payload that does not validate and an envelope that does not verify; with
# the published manifest as --prev, also a serial that is not above it.
published="$out/update.published.json"
if curl -fsS --max-time 20 -o "$published" https://btlabs-epic.github.io/update.json; then
  sign+=(--prev "$published")
else
  rm -f "$published"
  echo "No published update.json yet (or not reachable): signing without --prev."
fi
"${sign[@]}"
python3 "$tool" verify --type update --keyring "$keyring" --envelope "$manifest"
echo "1. Publish app-arm64-v8a-release.apk at $base_url (the GitHub release)."
echo "2. Then publish $manifest as update.json in BTLabs-EPIC/btlabs-epic.github.io"
echo "   (btlabs-public docs/hosting.md, \"Publishing a release manifest\")."
