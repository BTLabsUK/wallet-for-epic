#!/usr/bin/env bash
# Builds the 0.1.0 Android release from the checkout: LEPIC at the pin (tools/lepic.rev), the
# arm64-v8a APK (the one phone download; no universal APK), copies it to an output dir with its
# release name, writes SHA256SUMS and verifies it (signing cert, package, version, label,
# LEPIC library, Tor's libtor.so and licence, 16 KB-aligned ELF segments, no Firebase config). The signing key is the debug keystore, as for every earlier
# build (release buildType in android/app/build.gradle.kts).
#
# Usage: tool/build_android_release.sh [output-dir]      default: app/build/release-0.1.0/
#
# WFE_EMULATOR_X86_64=1 also builds an x86_64 APK for our own emulator tests, into
# <output-dir>/emulator/: never published, not in SHA256SUMS.
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
want_label="Epic Wallet"
want_cert=5fdcc602f907c83839b5b0a60d9ee15bb44d12411f8f1a67b28e92a95f259d0e
out_dir="$(realpath -m "${1:-$app_dir/build/release-$version}")"
# The commit, shown beside the version in Settings (lib/src/app_info.dart).
build_id="$(git -C "$app_dir" rev-parse --short=7 HEAD)"

bt="$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
aapt2="$bt/aapt2" apksigner="$bt/apksigner" zipalign="$bt/zipalign"
[[ -x "$aapt2" && -x "$apksigner" && -x "$zipalign" ]] \
  || { echo "aapt2/apksigner/zipalign not found in $bt" >&2; exit 1; }
readelf="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"
[[ -x "$readelf" ]] || { echo "llvm-readelf not found in $ANDROID_NDK_HOME" >&2; exit 1; }

[[ ! -e "$app_dir/android/app/google-services.json" ]] \
  || { echo "android/app/google-services.json exists: 0.1.0 ships without Firebase" >&2; exit 1; }

cd "$app_dir"
flutter pub get
"$app_dir/../tools/fetch-tor.sh" android "$app_dir/android/app/src/main/tor-jniLibs"
"$app_dir/../tools/lepic.sh" sync
"$app_dir/../tools/lepic.sh" build android

apks="$app_dir/build/app/outputs/flutter-apk"
mkdir -p "$out_dir"
rm -f "$out_dir"/epic-wallet-$version-*.apk "$out_dir/SHA256SUMS" "$out_dir"/emulator/epic-wallet-$version-*.apk

emulator=()
[[ "${WFE_EMULATOR_X86_64:-}" == 1 ]] && emulator=(x86_64)
platforms=android-arm64
[[ ${#emulator[@]} -gt 0 ]] && platforms=android-arm64,android-x64
flutter build apk --release --target-platform "$platforms" --split-per-abi \
  --dart-define=WFE_BUILD_ID="$build_id"
cp "$apks/app-arm64-v8a-release.apk" "$out_dir/epic-wallet-$version-arm64-v8a.apk"
(cd "$out_dir" && sha256sum epic-wallet-$version-*.apk >SHA256SUMS)
if [[ ${#emulator[@]} -gt 0 ]]; then
  mkdir -p "$out_dir/emulator"
  cp "$apks/app-x86_64-release.apk" "$out_dir/emulator/epic-wallet-$version-x86_64.apk"
fi

fail=0
check() { # description, condition result (0 = ok)
  if [[ "$2" == 0 ]]; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; fi
}
shopt -s nullglob
for apk in "$out_dir"/epic-wallet-$version-*.apk "$out_dir"/emulator/epic-wallet-$version-*.apk; do
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
  abis=("$abi")
  for a in "${abis[@]}"; do
    grep -q "^lib/$a/liblepic_ffi.so$" <<<"$libs" && r=0 || r=1; check "lib/$a/liblepic_ffi.so" $r
    grep -q "^lib/$a/libtor.so$" <<<"$libs" && r=0 || r=1; check "lib/$a/libtor.so" $r
  done
  # Tor's GPL licence, shown in the app's licences (lib/src/tor_licence.dart).
  tor_licence=assets/flutter_assets/assets/licenses/tor.txt
  grep -q "^$tor_licence$" <<<"$libs" && r=0 || r=1; check "$tor_licence" $r
  # Devices with 16 KB pages (Android 15+) need every ELF LOAD segment aligned to 0x4000 or
  # more. The libraries are packed compressed (useLegacyPackaging, so tor can be extracted as a
  # file), so zipalign cannot vouch for them; the ELF headers are what count.
  unpacked="$(mktemp -d)"
  # Only the APK's own ABI: the QR scanner's AAR also carries a 32-bit ARM libbarhopper_v3.so
  # that is not 16 KB aligned.
  for a in "${abis[@]}"; do unzip -q "$apk" "lib/$a/*.so" -d "$unpacked"; done
  while IFS= read -r so; do
    r=0
    while read -r align; do (( align >= 16384 )) || r=1; done \
      < <("$readelf" -lW "$so" | awk '$1 == "LOAD" { print $NF }')
    check "${so#"$unpacked"/} LOAD align >= 0x4000" $r
  done < <(find "$unpacked" -name '*.so' | sort)
  rm -r -- "$unpacked"
  "$zipalign" -c -P 16 4 "$apk" >/dev/null && r=0 || r=1; check "zipalign -c -P 16 4" $r
  # The merged manifest must let Android extract the libraries at install.
  manifest="$("$aapt2" dump xmltree --file AndroidManifest.xml "$apk")"
  grep -q 'extractNativeLibs.*=true' <<<"$manifest" && r=0 || r=1
  check "manifest extractNativeLibs=true" $r
  grep -qiE 'google-services|firebase|google_app_id' <<<"$("$aapt2" dump resources "$apk" 2>/dev/null | grep -iE 'google_app_id|firebase_database_url|gcm_defaultSenderId' || true)" \
    && r=1 || r=0
  check "no Firebase config" $r
done
# The phone download is arm64-v8a only.
published="$(cd "$out_dir" && ls epic-wallet-$version-*.apk)"
[[ "$published" == "epic-wallet-$version-arm64-v8a.apk" ]] && r=0 || r=1
check "only the arm64-v8a APK is published ($published)" $r
echo "SHA256SUMS:"; cat "$out_dir/SHA256SUMS"
[[ $fail == 0 ]] || { echo "verification FAILED" >&2; exit 1; }
echo "Release $version ($build_id) built and verified in $out_dir"
