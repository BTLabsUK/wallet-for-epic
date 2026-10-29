#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Builds the Android release from the checkout: LEPIC at the pin (tools/lepic.rev), the
# arm64-v8a APK (the one phone download; no universal APK), copies it to an output dir with its
# release name, writes SHA256SUMS and verifies it (signing cert, package, version, label,
# LEPIC library, Tor's libtor.so and licence, 16 KB-aligned ELF segments, no Firebase). The signing key is the release key named by
# WFE_ANDROID_KEY_PROPERTIES (default ~/.config/btlabs/android/key.properties, never in a
# repository); without it the build stops (android/app/build.gradle.kts, README "Release signing").
#
# Usage: tool/build_android_release.sh [output-dir]      default: app/build/release-<version>/
#
# WFE_EMULATOR_X86_64=1 also builds an x86_64 APK for our own emulator tests, into
# <output-dir>/emulator/: never published, not in SHA256SUMS.
#
# WFE_TOR=0 builds the version without Tor (https://docs.btlabs.uk/developers/build/variants/): --dart-define=WFE_TOR=false,
# no tor fetched or packed (android/app/build.gradle.kts), LEPIC built without its tor feature,
# -notor in the APK names, and the checks turned round: no libtor.so, no Tor code in
# liblepic_ffi.so, no Tor licence. Both pack the libraries compressed, extracted at install.
#
# WFE_DIST=play|fdroid builds a store build (https://docs.btlabs.uk/developers/build/variants/); unset or web is the build from
# our own page, as before. Neither store build has the in-app updater or the install permission.
#   play    an Android App Bundle for Google Play, epic-cash-mobile-<version>[-notor]-play.aab
#           (arm64-v8a, signed with the same key as the APK).
#   fdroid  epic-cash-mobile-<version>[-notor]-fdroid-arm64-v8a.apk, the APK for IzzyOnDroid and
#           the one F-Droid's own build must reproduce, with pubspec.lock enforced and tor built
#           from source (tools/build-tor-android.sh) instead of the Tor Project's binary.
# tools/dist-check.sh checks each output against its distribution.
#
# No WFE_UPDATE_URL is passed: the default feed is BT Labs' signed update.json, and the
# updater refuses a verified manifest whose packageName differs from the installed app's
# (lib/src/updater.dart), so this build never offers another app's builds.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

# pubspec.yaml's version and build number (https://docs.btlabs.uk/developers/releases/); every APK carries that build
# number as its versionCode, with no ABI offset (android/gradle.properties).
"$app_dir/../tools/version.sh" check >/dev/null || { "$app_dir/../tools/version.sh" check; exit 1; }
version="$("$app_dir/../tools/version.sh" name)"
want_code="$("$app_dir/../tools/version.sh" code)"
want_package=uk.btlabs.epiccash.mobile
want_label="Epic Cash Mobile"
# The release certificate. 0.1.0 (build 1) was signed with this host's debug key
# (5fdcc602...259d0e); later builds never are.
want_cert=59e4c290f3922d8e7d3b189eb98e7002dc50754c52d612ea91e82386390ec0aa
debug_cert=5fdcc602f907c83839b5b0a60d9ee15bb44d12411f8f1a67b28e92a95f259d0e
out_dir="$(realpath -m "${1:-$app_dir/build/release-$version}")"
# The commit, shown beside the version in Settings (lib/src/app_info.dart).
build_id="$(git -C "$app_dir" rev-parse --short=7 HEAD)"
# A rebuild of the same version: r2 from the tag v<version>-r2 on HEAD (WFE_BUILD_TAG).
build_tag="${WFE_BUILD_TAG:-$(git -C "$app_dir" tag --points-at HEAD | sed -n 's/^v[0-9.]*-\(r[0-9][0-9]*\)$/\1/p' | head -1)}"

bt="$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
aapt2="$bt/aapt2" apksigner="$bt/apksigner" zipalign="$bt/zipalign"
[[ -x "$aapt2" && -x "$apksigner" && -x "$zipalign" ]] \
  || { echo "aapt2/apksigner/zipalign not found in $bt" >&2; exit 1; }
readelf="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"
[[ -x "$readelf" ]] || { echo "llvm-readelf not found in $ANDROID_NDK_HOME" >&2; exit 1; }

dist="${WFE_DIST:-web}"
case "$dist" in web|play|fdroid) ;; *) echo "WFE_DIST=$dist: use web, play or fdroid" >&2; exit 2 ;; esac

# The build without Tor names its files epic-cash-mobile-<version>-notor-<abi>.apk; a store
# build adds -play or -fdroid.
tor=1 variant=
if [[ "${WFE_TOR:-1}" == 0 ]]; then tor=0 variant=-notor; fi
[[ $dist == web ]] || variant="$variant-$dist"

emulator=()
[[ "${WFE_EMULATOR_X86_64:-}" == 1 ]] && emulator=(x86_64)

cd "$app_dir"
if [[ $dist == fdroid ]]; then
  flutter pub get --enforce-lockfile
else
  flutter pub get
fi
tor_libs="$app_dir/android/app/src/main/tor-jniLibs"
if [[ $tor == 1 && $dist == fdroid ]]; then
  # Built from source, for the ABIs this build packs; never a Tor Project binary left there by
  # an earlier build.
  for a in arm64-v8a x86_64 armeabi-v7a x86; do rm -f -- "$tor_libs/$a/libtor.so"; done
  abis_tor=arm64-v8a
  [[ ${#emulator[@]} -gt 0 ]] && abis_tor="arm64-v8a x86_64"
  TOR_ANDROID_ABIS="$abis_tor" "$app_dir/../tools/build-tor-android.sh" "$tor_libs"
elif [[ $tor == 1 ]]; then
  "$app_dir/../tools/fetch-tor.sh" android "$tor_libs"
fi
"$app_dir/../tools/lepic.sh" sync
# The F-Droid build must come out the same on F-Droid's build server: without this, LEPIC's
# library names every crate's source path under this host's cargo home (panic locations).
# The recipe sets the same (https://docs.btlabs.uk/developers/build/variants/).
if [[ $dist == fdroid ]]; then
  export RUSTFLAGS="--remap-path-prefix=${CARGO_HOME:-$HOME/.cargo}=/cargo"
fi
# The binding's tool/lepic.sh builds LEPIC without Tor for WFE_TOR=0.
WFE_TOR=$tor "$app_dir/../tools/lepic.sh" build android

apks="$app_dir/build/app/outputs/flutter-apk"
mkdir -p "$out_dir"
rm -f "$out_dir"/epic-cash-mobile-$version-*.apk "$out_dir"/epic-cash-mobile-$version-*.aab "$out_dir/SHA256SUMS" \
  "$out_dir"/emulator/epic-cash-mobile-$version-*.apk

defines=(
  --dart-define=WFE_BUILD_ID="$build_id" --dart-define=WFE_BUILD_TAG="$build_tag"
  --dart-define=WFE_TOR="$([[ $tor == 1 ]] && echo true || echo false)" --dart-define=WFE_DIST="$dist"
)
if [[ $dist == play ]]; then
  # Google Play takes a bundle; the emulator's x86_64 APK is a build of its own.
  flutter build appbundle --release --target-platform android-arm64 "${defines[@]}"
  cp "$app_dir/build/app/outputs/bundle/release/app-release.aab" "$out_dir/epic-cash-mobile-$version$variant.aab"
  (cd "$out_dir" && sha256sum epic-cash-mobile-$version-*.aab >SHA256SUMS)
  if [[ ${#emulator[@]} -gt 0 ]]; then
    flutter build apk --release --target-platform android-x64 --split-per-abi "${defines[@]}"
  fi
else
  platforms=android-arm64
  [[ ${#emulator[@]} -gt 0 ]] && platforms=android-arm64,android-x64
  flutter build apk --release --target-platform "$platforms" --split-per-abi "${defines[@]}"
  cp "$apks/app-arm64-v8a-release.apk" "$out_dir/epic-cash-mobile-$version$variant-arm64-v8a.apk"
  (cd "$out_dir" && sha256sum epic-cash-mobile-$version-*.apk >SHA256SUMS)
fi
if [[ ${#emulator[@]} -gt 0 ]]; then
  mkdir -p "$out_dir/emulator"
  cp "$apks/app-x86_64-release.apk" "$out_dir/emulator/epic-cash-mobile-$version$variant-x86_64.apk"
fi

fail=0
check() { # description, condition result (0 = ok)
  if [[ "$2" == 0 ]]; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; fi
}
shopt -s nullglob
for apk in "$out_dir"/epic-cash-mobile-$version-*.apk "$out_dir"/emulator/epic-cash-mobile-$version-*.apk; do
  name="$(basename "$apk")"
  abi="${name#epic-cash-mobile-$version$variant-}"; abi="${abi%.apk}"
  echo "$name"
  certs="$("$apksigner" verify --print-certs "$apk")"
  grep -q "certificate SHA-256 digest: $want_cert" <<<"$certs" && r=0 || r=1
  check "signed by $want_cert" $r
  grep -q "certificate SHA-256 digest: $debug_cert" <<<"$certs" && r=1 || r=0
  check "not signed by the debug key" $r
  badging="$("$aapt2" dump badging "$apk")"
  head1="${badging%%$'\n'*}"
  grep -q "name='$want_package'" <<<"$head1" && r=0 || r=1; check "package $want_package" $r
  grep -q "versionName='$version'" <<<"$head1" && r=0 || r=1; check "versionName $version" $r
  # The published arm64-v8a APK carries exactly the derived code; the emulator's never more.
  code="$(sed -n "s/.*versionCode='\([0-9]*\)'.*/\1/p" <<<"$head1")"
  if [[ "$abi" == arm64-v8a ]]; then
    [[ "$code" == "$want_code" ]] && r=0 || r=1; check "versionCode $code = $want_code" $r
  else
    [[ -n "$code" ]] && (( code <= want_code )) && r=0 || r=1; check "versionCode $code <= $want_code" $r
  fi
  echo "       $head1"
  grep -q "^application-label:'$want_label'" <<<"$badging" && r=0 || r=1; check "label $want_label" $r
  libs="$(unzip -Z1 "$apk")"
  abis=("$abi")
  for a in "${abis[@]}"; do
    grep -q "^lib/$a/liblepic_ffi.so$" <<<"$libs" && r=0 || r=1; check "lib/$a/liblepic_ffi.so" $r
    if [[ $tor == 1 ]]; then
      grep -q "^lib/$a/libtor.so$" <<<"$libs" && r=0 || r=1; check "lib/$a/libtor.so" $r
    else
      grep -qiE '^lib/.*tor[^/]*\.so$' <<<"$libs" && r=1 || r=0; check "no tor library in lib/" $r
    fi
  done
  # Tor's GPL licence, shown in the app's licences (lib/src/tor_licence.dart). The build without
  # Tor still carries the text file (assets cannot follow a dart-define) but never shows it.
  tor_licence=assets/flutter_assets/assets/licenses/tor.txt
  [[ $tor == 1 ]] && { grep -q "^$tor_licence$" <<<"$libs" && r=0 || r=1; check "$tor_licence" $r; }
  # Devices with 16 KB pages (Android 15+) need every ELF LOAD segment aligned to 0x4000 or
  # more. The libraries are packed compressed (useLegacyPackaging, so tor can be extracted as a
  # file), so zipalign cannot vouch for them; the ELF headers are what count.
  unpacked="$(mktemp -d)"
  # Only the APK's own ABI: the QR scanner's AAR also carries a 32-bit ARM libbarhopper_v3.so
  # that is not 16 KB aligned.
  for a in "${abis[@]}"; do unzip -q "$apk" "lib/$a/*.so" -d "$unpacked"; done
  # LEPIC's Tor code (lepic-tor) names itself in the library's strings; without Tor it is not
  # compiled in.
  for a in "${abis[@]}"; do
    lepic_tor="$(LC_ALL=C grep -ac 'lepic_tor\|lepic-tor' "$unpacked/lib/$a/liblepic_ffi.so" || true)"
    if [[ $tor == 1 ]]; then
      [[ "$lepic_tor" != 0 ]] && r=0 || r=1; check "lib/$a/liblepic_ffi.so has LEPIC's Tor" $r
    else
      [[ "$lepic_tor" == 0 ]] && r=0 || r=1; check "lib/$a/liblepic_ffi.so has no Tor code" $r
    fi
  done
  while IFS= read -r so; do
    r=0
    while read -r align; do (( align >= 16384 )) || r=1; done \
      < <("$readelf" -lW "$so" | awk '$1 == "LOAD" { print $NF }')
    check "${so#"$unpacked"/} LOAD align >= 0x4000" $r
  done < <(find "$unpacked" -name '*.so' | sort)
  rm -r -- "$unpacked"
  "$zipalign" -c -P 16 4 "$apk" >/dev/null && r=0 || r=1; check "zipalign -c -P 16 4" $r
  # The merged manifest must let Android extract the libraries at install (tor runs from
  # there); the build without Tor packs them compressed the same way, for a smaller download.
  manifest="$("$aapt2" dump xmltree --file AndroidManifest.xml "$apk")"
  grep -q 'extractNativeLibs.*=true' <<<"$manifest" && r=0 || r=1
  check "manifest extractNativeLibs=true" $r
  # No Firebase or other Google push code since 26.10.20, even with a google-services.json
  # lying in android/app: not in the resources, the manifest or the code.
  "$aapt2" dump resources "$apk" 2>/dev/null | grep -qiE 'google_app_id|gcm_defaultSenderId|firebase' && r=1 || r=0
  check "no Firebase config" $r
  # com.google.firebase.components was ML Kit's plumbing (no build has ML Kit since 26.10.24;
  # dist-check refuses it): only Firebase's app, messaging or a push service counts here.
  grep -iE 'firebase|com\.google\.android\.c2dm|POST_NOTIFICATIONS' <<<"$manifest" | grep -qviE 'com\.google\.firebase\.components' && r=1 || r=0
  check "no Firebase or notification entries in the manifest" $r
  dex="$(mktemp -d)"
  unzip -q "$apk" 'classes*.dex' -d "$dex"
  LC_ALL=C grep -aqiE 'com/google/firebase/(messaging|iid|installations|FirebaseApp)|firebase-messaging' "$dex"/classes*.dex && r=1 || r=0
  check "no Firebase classes" $r
  rm -r -- "$dex"
  # What the distribution must and must not carry: the updater, proprietary code.
  "$app_dir/../tools/dist-check.sh" "$dist" "$apk" && r=0 || r=1; check "tools/dist-check.sh $dist" $r
done
if [[ $dist == play ]]; then
  # The bundle: signed with the release key (Play App Signing is given the same key), arm64-v8a
  # only, and the distribution's rules.
  aab="$out_dir/epic-cash-mobile-$version$variant.aab"
  basename "$aab"
  cert="$(keytool -printcert -jarfile "$aab" | sed -n 's/^[[:space:]]*SHA256: //p' | head -1 | tr -d ':' | tr 'A-F' 'a-f')"
  [[ "$cert" == "$want_cert" ]] && r=0 || r=1; check "signed by $want_cert" $r
  files="$(unzip -Z1 "$aab")"
  grep -q '^base/lib/arm64-v8a/liblepic_ffi.so$' <<<"$files" && r=0 || r=1; check "base/lib/arm64-v8a/liblepic_ffi.so" $r
  if [[ $tor == 1 ]]; then
    grep -q '^base/lib/arm64-v8a/libtor.so$' <<<"$files" && r=0 || r=1; check "base/lib/arm64-v8a/libtor.so" $r
  else
    grep -qiE '^base/lib/.*tor[^/]*\.so$' <<<"$files" && r=1 || r=0; check "no tor library in base/lib/" $r
  fi
  grep -E '^base/lib/' <<<"$files" | grep -qvE '^base/lib/arm64-v8a/' && r=1 || r=0; check "arm64-v8a libraries only" $r
  unzip -p "$aab" base/manifest/AndroidManifest.xml | LC_ALL=C grep -aqF "$want_package" && r=0 || r=1
  check "package $want_package" $r
  "$app_dir/../tools/dist-check.sh" play "$aab" && r=0 || r=1; check "tools/dist-check.sh play" $r
  published="$(cd "$out_dir" && ls epic-cash-mobile-$version-*.aab epic-cash-mobile-$version-*.apk 2>/dev/null | tr '\n' ' ')"
  [[ "$published" == "epic-cash-mobile-$version$variant.aab " ]] && r=0 || r=1
  check "only the bundle is published ($published)" $r
else
  # The phone download is arm64-v8a only.
  published="$(cd "$out_dir" && ls epic-cash-mobile-$version-*.apk)"
  [[ "$published" == "epic-cash-mobile-$version$variant-arm64-v8a.apk" ]] && r=0 || r=1
  check "only the arm64-v8a APK is published ($published)" $r
fi
echo "SHA256SUMS:"; cat "$out_dir/SHA256SUMS"
[[ $fail == 0 ]] || { echo "verification FAILED" >&2; exit 1; }
echo "Release $version ($build_id) built and verified in $out_dir"
