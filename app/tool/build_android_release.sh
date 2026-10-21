#!/usr/bin/env bash
# Builds the 0.1.0 Android release from the checkout: LEPIC at the pin (tools/lepic.rev), the
# split-per-ABI APKs (arm64-v8a, x86_64) and a universal APK, copies them to an output dir with
# release names, writes SHA256SUMS and verifies each APK (signing cert, package, version, label,
# LEPIC library, no Firebase config). The signing key is the debug keystore, as for every earlier
# build (release buildType in android/app/build.gradle.kts).
#
# Usage: tool/build_android_release.sh [output-dir]      default: app/build/release-0.1.0/
#
# No WFE_UPDATE_URL is passed: the default feed is the project's GitHub update.json, and the
# updater ignores any manifest whose packageName differs from the installed app's
# (lib/src/updater.dart), so this build never offers the 1.x builds (com.blacktyger.epic_wallet).
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

version=0.1.0
want_package=com.blacktyger.epicwallet
want_label="Epic Wallet 0.1"
want_cert=5fdcc602f907c83839b5b0a60d9ee15bb44d12411f8f1a67b28e92a95f259d0e
out_dir="$(realpath -m "${1:-$app_dir/build/release-$version}")"

bt="$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
aapt2="$bt/aapt2" apksigner="$bt/apksigner"
[[ -x "$aapt2" && -x "$apksigner" ]] || { echo "aapt2/apksigner not found in $bt" >&2; exit 1; }

[[ ! -e "$app_dir/android/app/google-services.json" ]] \
  || { echo "android/app/google-services.json exists: 0.1.0 ships without Firebase" >&2; exit 1; }

cd "$app_dir"
flutter pub get
"$app_dir/../tools/lepic.sh" sync
"$app_dir/../tools/lepic.sh" build android

apks="$app_dir/build/app/outputs/flutter-apk"
mkdir -p "$out_dir"
rm -f "$out_dir"/epic-wallet-$version-*.apk "$out_dir/SHA256SUMS"

flutter build apk --release --target-platform android-arm64,android-x64 --split-per-abi
cp "$apks/app-arm64-v8a-release.apk" "$out_dir/epic-wallet-$version-arm64-v8a.apk"
cp "$apks/app-x86_64-release.apk" "$out_dir/epic-wallet-$version-x86_64.apk"
flutter build apk --release --target-platform android-arm64,android-x64
cp "$apks/app-release.apk" "$out_dir/epic-wallet-$version-universal.apk"

(cd "$out_dir" && sha256sum epic-wallet-$version-*.apk >SHA256SUMS)

fail=0
check() { # description, condition result (0 = ok)
  if [[ "$2" == 0 ]]; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; fi
}
for apk in "$out_dir"/epic-wallet-$version-*.apk; do
  name="$(basename "$apk")"
  abi="${name#epic-wallet-$version-}"; abi="${abi%.apk}"
  echo "$name"
  certs="$("$apksigner" verify --print-certs "$apk")"
  grep -q "certificate SHA-256 digest: $want_cert" <<<"$certs" && r=0 || r=1
  check "signed by $want_cert" $r
  badging="$("$aapt2" dump badging "$apk")"
  head1="${badging%%$'\n'*}"
  grep -q "name='$want_package'" <<<"$head1" && r=0 || r=1; check "package $want_package" $r
  grep -q "versionName='$version'" <<<"$head1" && r=0 || r=1; check "versionName $version" $r
  echo "       $head1"
  grep -q "^application-label:'$want_label'" <<<"$badging" && r=0 || r=1; check "label $want_label" $r
  libs="$(unzip -Z1 "$apk")"
  if [[ "$abi" == universal ]]; then abis=(arm64-v8a x86_64); else abis=("$abi"); fi
  for a in "${abis[@]}"; do
    grep -q "^lib/$a/liblepic_ffi.so$" <<<"$libs" && r=0 || r=1; check "lib/$a/liblepic_ffi.so" $r
  done
  grep -qiE 'google-services|firebase|google_app_id' <<<"$("$aapt2" dump resources "$apk" 2>/dev/null | grep -iE 'google_app_id|firebase_database_url|gcm_defaultSenderId' || true)" \
    && r=1 || r=0
  check "no Firebase config" $r
done
echo "SHA256SUMS:"; cat "$out_dir/SHA256SUMS"
[[ $fail == 0 ]] || { echo "verification FAILED" >&2; exit 1; }
echo "Release $version built and verified in $out_dir"
