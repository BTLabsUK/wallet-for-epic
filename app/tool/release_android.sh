#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Builds the split-per-ABI release APKs and writes the two signed manifests of the release
# (btlabs-public FORMAT.md section 6; https://docs.btlabs.uk/developers/releases/, Release addresses): update.json, the
# old format installed apps up to 26.10.23 read, with file URLs under download-base-url, and
# update-v2.json, the new format the current app reads ([updates] manifests of
# app/assets/config/app-config.toml), the same release and serial with file URLs under
# [updates] downloads of that file. One file serves
# both variants: its top-level release names the builds with Tor, its `notor` section the builds
# without Tor (-notor files), which read only that section. Publish the release files first, then
# update.json with tools/publish-update-json.sh.
# Usage: tool/release_android.sh <download-base-url> [notes]
#   download-base-url  where the APKs will be served (https): the old format's folder,
#                      [old_update] downloads of tool/config/old-update.toml
#   notes              plain text; line feeds allowed, no tabs or carriage returns
#
# It writes update.payload.json (unsigned; serial = issued_at in Unix seconds, expiry in
# WFE_MANIFEST_DAYS days, default 182; tools/rel passes release/pipeline.toml [manifest]
# validity_days) and signs it with btlabs-public's tool when the signing key is on this machine:
#   BTLABS_PUBLIC       the btlabs-public checkout (default ~/code/btlabs-public)
#   BTLABS_SIGNING_KEY  the rank-1 key (default ~/.config/btlabs/signing/btlabs-2026-a.key)
#   BTLABS_SIGNER       instead of the key: tools/signer/btsign_client.py, the release signer
#                       (docs/RELEASING.md, "Signer"); WFE_SIGNER_JOBS adds client jobs
# Without them it stops after the payload and prints the signing command.
#
# WFE_DESKTOP_RELEASE=1 adds the `desktop` entry the desktop update check reads
# (lib/src/desktop/data/desk_update.dart): set it only when this release also ships desktop
# builds, else the desktop would offer a release that has none. Its page is WFE_DESKTOP_PAGE,
# else the release's tag page derived from download-base-url. The manifest only takes a page on
# the project's GitHub accounts (FORMAT.md section 6): any other page makes every client, phone
# included, reject the whole file. The desktop's own downloads (since 26.10.9) are per system:
# tool/desktop_update_entry.sh prints that block from the published setup and AppImage.
#
# WFE_APK_DIR=<folder> takes the APKs tool/build_android_release.sh put there under their release
# names instead of building one: epic-cash-mobile-<version>-arm64-v8a.apk for the top level and
# epic-cash-mobile-<version>-notor-arm64-v8a.apk for the notor section, both required, as a
# release builds and ships both variants (https://docs.btlabs.uk/developers/releases/). The manifest names them under
# download-base-url by those names: https://examples.btlabs.uk/epic-cash-wallets/downloads, the
# release folder that https://epiccash.btlabs.uk/releases/downloads/ also serves. The manifest keeps
# the examples.btlabs.uk address while installed apps need it: with Tor on, apps up to 26.10.23
# reach only that name through the downloads onion (https://docs.btlabs.uk/developers/releases/, Release addresses).
# update-v2.json names each file by its name under [updates] downloads, and
# tool/check_update_urls.sh stops the script before signing when any file URL of either payload
# is off its folder.
# WFE_DESKTOP_DIR=<folder> adds the per-system desktop blocks (tool/desktop_update_entry.sh) from
# the published setups, AppImages and dmgs in that folder, the -notor ones into the notor section.
#
# Set the release's version first (`tools/version.sh set`, https://docs.btlabs.uk/developers/releases/): Android installs
# an update only when its version code is higher, and only when it is signed with the same key as
# the installed app. A test build (YY.MM.patch-rcN) never goes to the update channel: refused.
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
if [[ "$notes" == *$'\r'* || "$notes" == *$'\t'* ]]; then
  echo "notes: no tabs or carriage returns (FORMAT.md section 6)" >&2
  exit 64
fi
# The old format's folder and address (tool/config/old-update.toml): download-base-url must be
# that folder, checked with every file URL before signing.
old_config="$app_dir/tool/config/old-update.toml"
old_base="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["old_update"]["downloads"])' "$old_config")"
old_base="${old_base%/}"
old_manifest_url="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["old_update"]["manifest"])' "$old_config")"
btlabs_public="${BTLABS_PUBLIC:-$HOME/code/btlabs-public}"
signing_key="${BTLABS_SIGNING_KEY:-$HOME/.config/btlabs/signing/btlabs-2026-a.key}"
# Clients accept a validity of at most 400 days (FORMAT.md section 5).
manifest_days="${WFE_MANIFEST_DAYS:-182}"
[[ "$manifest_days" =~ ^[1-9][0-9]{0,2}$ && "$manifest_days" -le 400 ]] \
  || { echo "WFE_MANIFEST_DAYS=$manifest_days: a whole number of days, 1 to 400" >&2; exit 64; }

"$app_dir/../tools/version.sh" check
version="$("$app_dir/../tools/version.sh" name)"
want_code="$("$app_dir/../tools/version.sh" code)"
[[ "$version" != *-* ]] || { echo "$version is a test build: never published to update.json" >&2; exit 1; }

aapt2="$(find "$ANDROID_HOME/build-tools" -maxdepth 2 -name aapt2 -type f | sort -V | tail -1)"
[[ -x "$aapt2" ]] || { echo "aapt2 not found under $ANDROID_HOME/build-tools" >&2; exit 1; }

cd "$app_dir"
out="$app_dir/build/app/outputs/flutter-apk"
if [[ -z "${WFE_APK_DIR:-}" ]]; then
  # After `flutter test`, the plugin registrant can still list the dev-only integration_test plugin,
  # and the first release build then fails to compile it. `pub get` regenerates it first.
  flutter pub get
  # package:lepic's build hook bundles prebuilt libraries and fails without them. Up to date,
  # this is a no-op build.
  "$app_dir/../tools/lepic.sh" build android
  flutter build apk --release --target-platform android-arm64 --split-per-abi \
    ${WFE_UPDATE_URL:+--dart-define=WFE_UPDATE_URL="$WFE_UPDATE_URL"}
else
  mkdir -p "$out"
fi

package="" version_name="" entries=() notor_entries=()
# The phone download is arm64-v8a only; x86_64 builds are for our own emulators, never published.
# Each APK of a variant: "" (with Tor, the top level) and -notor (the notor section, WFE_APK_DIR).
variants=("")
[[ -n "${WFE_APK_DIR:-}" ]] && variants+=(-notor)
for variant in "${variants[@]}"; do
for abi in arm64-v8a; do
  apk="$out/app-$abi-release.apk" file="app-$abi-release.apk"
  if [[ -n "${WFE_APK_DIR:-}" ]]; then
    file="epic-cash-mobile-$version$variant-$abi.apk" apk="${WFE_APK_DIR%/}/$file"
  fi
  [[ -f "$apk" ]] || { echo "missing $apk" >&2; exit 1; }
  # Keep only the first line in bash: `| head -1` would SIGPIPE aapt2 under pipefail.
  badging="$("$aapt2" dump badging "$apk")"
  badging="${badging%%$'\n'*}"
  package="$(sed -n "s/.*package: name='\([^']*\)'.*/\1/p" <<<"$badging")"
  code="$(sed -n "s/.*versionCode='\([0-9]*\)'.*/\1/p" <<<"$badging")"
  version_name="$(sed -n "s/.*versionName='\([^']*\)'.*/\1/p" <<<"$badging")"
  [[ "$version_name" == "$version" && "$code" == "$want_code" ]] \
    || { echo "$apk is $version_name ($code), not $version ($want_code)" >&2; exit 1; }
  sha="$(sha256sum "$apk" | cut -d' ' -f1)"
  size="$(stat -L -c %s "$apk")"
  entry="$(jq -n --arg abi "$abi" --argjson code "$code" --arg url "$base_url/$file" \
    --arg sha "$sha" --argjson size "$size" \
    '{abi: $abi, versionCode: $code, url: $url, sha256: $sha, size: $size}')"
  if [[ -z "$variant" ]]; then entries+=("$entry"); else notor_entries+=("$entry"); fi
done
done

desktop_page=""
if [[ "${WFE_DESKTOP_RELEASE:-}" == 1 ]]; then
  desktop_page="${WFE_DESKTOP_PAGE:-${base_url/\/releases\/download\//\/releases\/tag\/}}"
fi
issued_epoch="$(date -u +%s)"
issued_at="$(date -u -d "@$issued_epoch" +%Y-%m-%dT%H:%M:%SZ)"
expires_at="$(date -u -d "@$((issued_epoch + manifest_days * 86400))" +%Y-%m-%dT%H:%M:%SZ)"
payload="$out/update.payload.json"
manifest="$out/update.json"
payload2="$out/update-v2.payload.json"
manifest2="$out/update-v2.json"
rm -f "$manifest" "$manifest2"
printf '%s\n' "${entries[@]}" | jq -s --arg package "$package" --arg name "$version_name" --arg notes "$notes" \
  --arg page "$desktop_page" --argjson serial "$issued_epoch" --arg issued "$issued_at" --arg expires "$expires_at" \
  '($notes | sub("^\\s+"; "") | sub("\\s+$"; "")) as $n
   | {schema: 1, serial: $serial, issued_at: $issued, expires_at: $expires,
      packageName: $package, versionName: $name, apks: .}
   + (if $n == "" then {} else {notes: $n} end)
   + (if $page == "" then {} else {desktop: {version: $name, page: $page}} end)' >"$payload"
if [[ ${#notor_entries[@]} -gt 0 ]]; then
  notor_apks="$(printf '%s\n' "${notor_entries[@]}" | jq -s .)"
  jq --argjson apks "$notor_apks" '. + {notor: {apks: $apks}}' "$payload" >"$payload.tmp"
  mv "$payload.tmp" "$payload"
fi
if [[ -n "${WFE_DESKTOP_DIR:-}" ]]; then
  # Deep merge: the top-level desktop block and, for the -notor files, notor.desktop.
  desktop_block="$(WFE_DOWNLOADS_BASE="$old_base" "$app_dir/tool/desktop_update_entry.sh" "$version" "$WFE_DESKTOP_DIR")"
  jq --argjson d "$desktop_block" '. * $d' "$payload" >"$payload.tmp"
  mv "$payload.tmp" "$payload"
fi

# The new format: the same payload, its file URLs under the app's own download address.
config="$app_dir/assets/config/app-config.toml"
base2="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["updates"]["downloads"])' "$config")"
base2="${base2%/}"
manifest2_url="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["updates"]["manifests"][0])' "$config")"
# Every file URL by its file name, whatever folder the old one names: the same files.
jq --arg new "$base2/" \
  'walk(if type == "object" and (.url | type) == "string" then .url = $new + (.url | split("/") | last) else . end)' \
  "$payload" >"$payload2"
# Both before signing: a URL off its folder makes the apps reject the whole manifest.
"$app_dir/tool/check_update_urls.sh" "$payload" "$old_base"
"$app_dir/tool/check_update_urls.sh" "$payload2" "$base2"

echo "Wrote $payload for $package $version_name (serial $issued_epoch, expires $expires_at):"
jq -r '(.apks[] | "  \(.abi) versionCode \(.versionCode) \(.size) bytes \(.url)"),
       (.notor.apks[]? | "  notor \(.abi) versionCode \(.versionCode) \(.size) bytes \(.url)")' "$payload"

# 0.1.0 (com.blacktyger.epicwallet, debug-signed) reads an unsigned update.json from
# https://github.com/blacktyger/wallet-for-epic/releases/latest/download/update.json, takes it
# only when packageName is its own, and shows nothing of it but "Update to <versionName>"; its
# installer then refuses an APK of another package ("the APK is for <package>, not this app").
# So the legacy file names the old package and says in versionName that the release is a new
# app, and its APK entries are the new APK: tapping Install fetches it and ends with that
# message naming the new app. WFE_LEGACY_NAME replaces the versionName text.
legacy="$out/update-legacy.json"
legacy_name="${WFE_LEGACY_NAME:-Epic Cash Mobile $version_name, a new app: install it beside this one}"
jq --arg name "$legacy_name" \
  '{packageName: "com.blacktyger.epicwallet", versionName: $name, apks: .apks}' "$payload" >"$legacy"
echo "Wrote $legacy for 0.1.0 (\"Update to $legacy_name\")."

tool="$btlabs_public/tool/btlabs_sign.py"
keyring="$btlabs_public/keys/btlabs-keyring.json"
sign=(python3 "$tool" sign --type update --key "$signing_key" --keyring "$keyring" --payload "$payload" --out "$manifest")
# update-v2.json's links are checked against [updates] of the app's app-config.toml.
sign2=(python3 "$tool" sign --type update --app-config "$config" --key "$signing_key" --keyring "$keyring" --payload "$payload2" --out "$manifest2")
# BTLABS_SIGNER=<tools/signer/btsign_client.py>: the release signer signs both instead of the key
# here (docs/RELEASING.md, "Signer"), in one request the owner approves with one code; the caller's
# WFE_SIGNER_JOBS (one client job per line) ride in the same request.
signer="${BTLABS_SIGNER:-}"
if [[ ! -f "$tool" || ! -f "$keyring" || ( -z "$signer" && ! -f "$signing_key" ) ]]; then
  echo "Not signed: needs $tool, $keyring and the signing key $signing_key (or BTLABS_SIGNER)." >&2
  echo "On the signing machine run:" >&2
  printf '  %q' "${sign[@]}" >&2
  echo >&2
  printf '  %q' "${sign2[@]}" >&2
  echo >&2
  exit 1
fi
# The keys installed apps trust (lib/src/btlabs_keys.dart) must be the keyring the file is
# signed against, or the script succeeds and every phone rejects the file.
python3 - "$app_dir/lib/src/btlabs_keys.dart" "$keyring" <<'PY' || exit 1
import json, sys
app = open(sys.argv[1], encoding="utf-8").read().split("'''")[1]
if json.loads(app) != json.load(open(sys.argv[2], encoding="utf-8")):
    sys.exit("lib/src/btlabs_keys.dart and %s hold different keys: ship the new keyring first" % sys.argv[2])
PY
# The tool refuses a payload that does not validate and an envelope that does not verify; with
# the published manifest as --prev, also a serial that is not above it (a slow clock here). The
# published copy is read from BT Labs' own server, the first source the apps read.
published="$out/update.published.json"
rm -f "$published"
status="$(curl -sS --max-time 20 -o "$published" -w '%{http_code}' "$old_manifest_url" || true)"
case "$status" in
  200) sign+=(--prev "$published") ;;
  404) rm -f "$published"; echo "No update.json published yet: signing without --prev." ;;
  *) echo "Cannot read the published update.json (HTTP ${status:-none}); not signing." >&2; exit 1 ;;
esac
published2="$out/update-v2.published.json"
rm -f "$published2"
status="$(curl -sS --max-time 20 -o "$published2" -w '%{http_code}' "$manifest2_url" || true)"
case "$status" in
  200) sign2+=(--prev "$published2") ;;
  404) rm -f "$published2"; echo "No update-v2.json published yet: signing it without --prev." ;;
  *) echo "Cannot read the published update-v2.json (HTTP ${status:-none}); not signing it." >&2; exit 1 ;;
esac
if [[ -n "$signer" ]]; then
  # The signer runs the same btlabs_sign.py (vendored, pinned): the same envelopes, --prev too.
  j1="update-manifest:payload=$payload,out=$(basename "$manifest")"
  [[ -f "$published" ]] && j1+=",prev=$published"
  j2="update-manifest:payload=$payload2,out=$(basename "$manifest2"),app_config=$config"
  [[ -f "$published2" ]] && j2+=",prev=$published2"
  jobs=("$j1" "$j2")
  if [[ -n "${WFE_SIGNER_JOBS:-}" ]]; then mapfile -t -O "${#jobs[@]}" jobs <<<"$WFE_SIGNER_JOBS"; fi
  rm -f "$manifest" "$manifest2"
  python3 "$signer" sign --version "$version" --out-dir "$out" --label "Update manifests $version" "${jobs[@]}"
else
  "${sign[@]}"
  "${sign2[@]}"
fi
python3 "$tool" verify --type update --keyring "$keyring" --envelope "$manifest"
python3 "$tool" verify --type update --app-config "$config" --keyring "$keyring" --envelope "$manifest2"
echo "1. Publish the files it names: $(jq -r '[.apks[].url, .notor.apks[]?.url] | join(" ")' "$payload")"
echo "2. Then publish both: tools/publish-update-json.sh $manifest $manifest2"
echo "3. For 0.1.0 phones, $legacy is their update.json, read only from the latest GitHub release of"
echo "   blacktyger/wallet-for-epic, which answers 404 since GitHub flagged that account: keep it, publish nothing."
