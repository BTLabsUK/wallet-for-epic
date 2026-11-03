#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Builds the Android release from the checkout: LEPIC at the pin (tools/lepic.rev), the
# arm64-v8a APK (the one phone download; no universal APK), copies it to an output dir with its
# release name, writes SHA256SUMS and verifies it with tool/verify_android_release.sh (signing cert, package, version, label,
# LEPIC library, Tor's libtor.so and licence, 16 KB-aligned ELF segments, no Firebase). The signing key is the release key named by
# WFE_ANDROID_KEY_PROPERTIES (default ~/.config/btlabs/android/key.properties, never in a
# repository); without it the build stops (android/app/build.gradle.kts, README "Release signing").
#
# WFE_UNSIGNED=1 builds every file unsigned (Gradle -PwfeUnsigned=true) for the release signer
# (docs/RELEASING.md, "Signer"), which signs them later with the same key; tools/rel does so on
# its own when its run has a signer (<run>/signer.json). The key is then not needed here, and the
# checks below say "not signed" instead of naming the certificate.
#
# Usage: tool/build_android_release.sh [output-dir]      default: app/build/release-<version>/
#
# WFE_BUILD_ID=<id> is the build id shown in About, instead of the short commit (the hosted build
# passes the published commit).
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
#   play    an Android App Bundle for Google Play, bt-wallet-<version>[-notor]-play-android.aab
#           (arm64-v8a, signed with the same key as the APK).
#   fdroid  bt-wallet-<version>[-notor]-fdroid-android-arm64-v8a.apk, the APK for IzzyOnDroid and
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
out_dir="$(realpath -m "${1:-$app_dir/build/release-$version}")"
# The commit, shown beside the version in Settings (lib/src/app_info.dart).
# WFE_BUILD_ID overrides it (the hosted build names the published commit).
build_id="${WFE_BUILD_ID:-$(git -C "$app_dir" rev-parse --short=7 HEAD)}"
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

# Release files are bt-wallet-<version><variant>-android-<abi>.apk (bundle: ...-android.aab),
# variant -notor for the build without Tor and -play or -fdroid for a store build. Earlier
# builds were epic-cash-mobile-<version><variant>-<abi>.apk; the clean-up below removes both.
tor=1 variant=
if [[ "${WFE_TOR:-1}" == 0 ]]; then tor=0 variant=-notor; fi
[[ $dist == web ]] || variant="$variant-$dist"

emulator=()
[[ "${WFE_EMULATOR_X86_64:-}" == 1 ]] && emulator=(x86_64)

unsigned=0
if [[ "${WFE_UNSIGNED:-}" == 1 || -f "${REL_RUN:-/nonexistent}/signer.json" ]]; then
  unsigned=1
  export ORG_GRADLE_PROJECT_wfeUnsigned=true
  echo "Building unsigned: the release signer signs these files (docs/RELEASING.md, \"Signer\")."
fi

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
shared=1
if [[ $dist == fdroid ]]; then
  export RUSTFLAGS="--remap-path-prefix=${CARGO_HOME:-$HOME/.cargo}=/cargo"
  shared=0
fi
# The binding's tool/lepic.sh builds LEPIC without Tor for WFE_TOR=0. From the shared Android
# clones of this variant, one per ABI, built at once (tools/lepic.sh, LEPIC_SHARED): their cargo
# targets are kept between releases, also across pins, and the two variants never share one
# (the owner 2026-11-02). F-Droid builds in this checkout, as on its build server.
LEPIC_SHARED=$shared LEPIC_NO_CACHE=1 WFE_TOR=$tor "$app_dir/../tools/lepic.sh" build android

apks="$app_dir/build/app/outputs/flutter-apk"
mkdir -p "$out_dir"
rm -f "$out_dir"/{bt-wallet,epic-cash-mobile}-$version-*.apk "$out_dir"/{bt-wallet,epic-cash-mobile}-$version-*.aab "$out_dir/SHA256SUMS" \
  "$out_dir"/emulator/{bt-wallet,epic-cash-mobile}-$version-*.apk

defines=(
  --dart-define=WFE_BUILD_ID="$build_id" --dart-define=WFE_BUILD_TAG="$build_tag"
  --dart-define=WFE_TOR="$([[ $tor == 1 ]] && echo true || echo false)" --dart-define=WFE_DIST="$dist"
)
if [[ $dist == play ]]; then
  # Google Play takes a bundle; the emulator's x86_64 APK is a build of its own.
  flutter build appbundle --release --target-platform android-arm64 "${defines[@]}"
  cp "$app_dir/build/app/outputs/bundle/release/app-release.aab" "$out_dir/bt-wallet-$version$variant-android.aab"
  (cd "$out_dir" && sha256sum bt-wallet-$version-*.aab >SHA256SUMS)
  if [[ ${#emulator[@]} -gt 0 ]]; then
    flutter build apk --release --target-platform android-x64 --split-per-abi "${defines[@]}"
  fi
else
  platforms=android-arm64
  [[ ${#emulator[@]} -gt 0 ]] && platforms=android-arm64,android-x64
  flutter build apk --release --target-platform "$platforms" --split-per-abi "${defines[@]}"
  cp "$apks/app-arm64-v8a-release.apk" "$out_dir/bt-wallet-$version$variant-android-arm64-v8a.apk"
  (cd "$out_dir" && sha256sum bt-wallet-$version-*.apk >SHA256SUMS)
fi
if [[ ${#emulator[@]} -gt 0 ]]; then
  mkdir -p "$out_dir/emulator"
  cp "$apks/app-x86_64-release.apk" "$out_dir/emulator/bt-wallet-$version$variant-android-x86_64.apk"
fi

# The checks are app/tool/verify_android_release.sh's, which also runs on downloaded files.
rc=0
WFE_VERSION="$version" WFE_BUILD_ID="$build_id" WFE_TOR="$tor" WFE_DIST="$dist" WFE_UNSIGNED="$unsigned" \
  "$app_dir/tool/verify_android_release.sh" "$out_dir" || rc=$?
echo "SHA256SUMS:"; cat "$out_dir/SHA256SUMS"
[[ $rc == 0 ]] || { echo "verification FAILED" >&2; exit 1; }
echo "Release $version ($build_id) built and verified in $out_dir"
