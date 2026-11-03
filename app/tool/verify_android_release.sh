#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Checks the Android release files in a folder: the signing cert (or "not signed"), package,
# version, label, LEPIC library, Tor's libtor.so and licence, 16 KB-aligned ELF segments, no
# Firebase, tools/dist-check.sh. build_android_release.sh runs it after every build; it also runs
# on downloaded files (tools/rel's fetch of a hosted build, a runner's artifact) on any host with
# the Android SDK and NDK of tools/env.sh.
#
# Usage: app/tool/verify_android_release.sh <dir with the APKs (or the AAB)>
#   <dir>/bt-wallet-<version><variant>-android-*.apk, <dir>/emulator/*.apk when present.
# Env:   WFE_TOR=0|1        the build without Tor / with Tor (default 1)
#        WFE_VERSION        the version the files must carry (default: tools/version.sh name)
#        WFE_BUILD_ID       when set, libapp.so of every APK must carry it (the About line)
#        WFE_UNSIGNED=1     the files must be unsigned (the release signer signs them later)
#        WFE_DIST=web|play|fdroid   the distribution (default web)
# Exit 0 when every check passes; else 1, with one line per failed check on stderr.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"
out_dir="${1:-}"
[[ -d "$out_dir" ]] || { echo "usage: $0 <dir with the APKs>" >&2; exit 2; }
out_dir="$(cd "$out_dir" && pwd)"
version="${WFE_VERSION:-$("$app_dir/../tools/version.sh" name)}"
want_code="$("$app_dir/../tools/version.sh" code)"
want_package=uk.btlabs.btwallet
want_label="BT Wallet"
# The release certificate. 0.1.0 (build 1) was signed with this host's debug key
# (5fdcc602...259d0e); later builds never are.
want_cert=59e4c290f3922d8e7d3b189eb98e7002dc50754c52d612ea91e82386390ec0aa
debug_cert=5fdcc602f907c83839b5b0a60d9ee15bb44d12411f8f1a67b28e92a95f259d0e
build_id="${WFE_BUILD_ID:-}"
dist="${WFE_DIST:-web}"
case "$dist" in web|play|fdroid) ;; *) echo "WFE_DIST=$dist: use web, play or fdroid" >&2; exit 2 ;; esac
tor=1 variant=
if [[ "${WFE_TOR:-1}" == 0 ]]; then tor=0 variant=-notor; fi
[[ $dist == web ]] || variant="$variant-$dist"
unsigned=0
[[ "${WFE_UNSIGNED:-}" == 1 ]] && unsigned=1

bt="$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
aapt2="$bt/aapt2" apksigner="$bt/apksigner" zipalign="$bt/zipalign"
[[ -x "$aapt2" && -x "$apksigner" && -x "$zipalign" ]] \
  || { echo "aapt2/apksigner/zipalign not found in $bt" >&2; exit 1; }
readelf="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"
[[ -x "$readelf" ]] || { echo "llvm-readelf not found in $ANDROID_NDK_HOME" >&2; exit 1; }

fail=0 failed=()
check() { # description, condition result (0 = ok)
  if [[ "$2" == 0 ]]; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; failed+=("FAIL ${name:-}: $1"); fi
}
shopt -s nullglob
for apk in "$out_dir"/bt-wallet-$version-*.apk "$out_dir"/emulator/bt-wallet-$version-*.apk; do
  name="$(basename "$apk")"
  abi="${name##*-android-}"; abi="${abi%.apk}"
  echo "$name"
  if [[ $unsigned == 1 ]]; then
    "$apksigner" verify "$apk" >/dev/null 2>&1 && r=1 || r=0
    check "not signed (the release signer signs it)" $r
  else
    certs="$("$apksigner" verify --print-certs "$apk")"
    grep -q "certificate SHA-256 digest: $want_cert" <<<"$certs" && r=0 || r=1
    check "signed by $want_cert" $r
    grep -q "certificate SHA-256 digest: $debug_cert" <<<"$certs" && r=1 || r=0
    check "not signed by the debug key" $r
  fi
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
  # The build id (WFE_BUILD_ID, the About line) is compiled into the Dart snapshot.
  if [[ -n "$build_id" ]]; then
    [[ "$(unzip -p "$apk" "lib/$abi/libapp.so" | LC_ALL=C grep -acF -- "$build_id" || true)" != 0 ]] && r=0 || r=1
    check "build id $build_id in lib/$abi/libapp.so" $r
  fi
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
  aab="$out_dir/bt-wallet-$version$variant-android.aab"
  basename "$aab"
  cert="$({ keytool -printcert -jarfile "$aab" 2>/dev/null || true; } | sed -n 's/^[[:space:]]*SHA256: //p' | head -1 | tr -d ':' | tr 'A-F' 'a-f')"
  if [[ $unsigned == 1 ]]; then
    [[ -z "$cert" ]] && r=0 || r=1; check "not signed (the release signer signs it)" $r
  else
    [[ "$cert" == "$want_cert" ]] && r=0 || r=1; check "signed by $want_cert" $r
  fi
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
  published="$(cd "$out_dir" && ls bt-wallet-$version-*.aab bt-wallet-$version-*.apk 2>/dev/null | tr '\n' ' ')"
  [[ "$published" == "bt-wallet-$version$variant-android.aab " ]] && r=0 || r=1
  check "only the bundle is published ($published)" $r
else
  # The phone download is arm64-v8a only.
  published="$(cd "$out_dir" && ls bt-wallet-$version-*.apk)"
  [[ "$published" == "bt-wallet-$version$variant-android-arm64-v8a.apk" ]] && r=0 || r=1
  check "only the arm64-v8a APK is published ($published)" $r
fi
[[ $fail == 0 ]] || { printf '%s\n' "${failed[@]}" >&2; echo "verification FAILED" >&2; exit 1; }
