#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Checks that Android release builds are signed with the release key only
# (android/app/build.gradle.kts): a release build stops when key.properties is missing,
# incomplete, names the debug key or a keystore inside the repository, and goes ahead with the
# real one. `--apk` also builds a release APK and checks its certificate is the release one and
# not the debug one. Needs the release key.properties (WFE_ANDROID_KEY_PROPERTIES, default
# ~/.config/btlabs/android/key.properties); never prints its contents.
#
# Usage: tool/android_signing_check.sh [--apk]
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

# SHA-256 of the release certificate (public; the key itself stays in ~/.config/btlabs/android).
release_cert=59e4c290f3922d8e7d3b189eb98e7002dc50754c52d612ea91e82386390ec0aa
real_props="${WFE_ANDROID_KEY_PROPERTIES:-$HOME/.config/btlabs/android/key.properties}"
[[ -f "$real_props" ]] || { echo "release key.properties not found: $real_props" >&2; exit 1; }

work="$(mktemp -d)"
inside="$app_dir/build/signing-check"
trap 'rm -rf "$work" "$inside"' EXIT

cd "$app_dir"
[[ -f android/local.properties ]] || flutter build apk --config-only >/dev/null

fail=0
# expect <ok|refused> <description> <key.properties path>
expect() {
  local want="$1" what="$2" props="$3" out rc
  out="$(cd android && WFE_ANDROID_KEY_PROPERTIES="$props" ./gradlew -q --console=plain \
    :app:checkReleaseSigning 2>&1)" && rc=0 || rc=$?
  if [[ "$want" == refused ]]; then
    if [[ $rc -ne 0 ]] && grep -q "signed with the release key only" <<<"$out"; then
      echo "  ok   refused: $what"
    else
      echo "  FAIL not refused: $what"; fail=1
    fi
  elif [[ $rc -eq 0 ]]; then
    echo "  ok   accepted: $what"
  else
    echo "  FAIL refused: $what"; grep -E "^> |What went wrong" <<<"$out" | head -3; fail=1
  fi
}

echo "Release signing (build.gradle.kts):"
expect refused "no key.properties" "$work/missing.properties"

printf 'storeFile=%s\nkeyAlias=x\n' "$work/none.p12" >"$work/partial.properties"
expect refused "key.properties without passwords" "$work/partial.properties"

printf 'storeFile=%s\nstorePassword=android\nkeyAlias=androiddebugkey\nkeyPassword=android\n' \
  "$HOME/.android/debug.keystore" >"$work/debug.properties"
expect refused "key.properties naming the debug key" "$work/debug.properties"

mkdir -p "$inside"
: >"$inside/release.p12"
printf 'storeFile=%s\nstorePassword=x\nkeyAlias=x\nkeyPassword=x\n' "$inside/release.p12" \
  >"$work/inside.properties"
expect refused "a keystore inside the repository" "$work/inside.properties"

expect ok "the release key.properties" "$real_props"

# Release builds only depend on the check if preReleaseBuild runs it.
plan="$(cd android && WFE_ANDROID_KEY_PROPERTIES="$real_props" ./gradlew --console=plain \
  :app:assembleRelease --dry-run 2>/dev/null)"
grep -q "^:app:checkReleaseSigning " <<<"$plan" && echo "  ok   assembleRelease runs checkReleaseSigning" \
  || { echo "  FAIL assembleRelease does not run checkReleaseSigning"; fail=1; }

if [[ "${1:-}" == --apk ]]; then
  bt="$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
  debug_cert="$(keytool -list -v -keystore "$HOME/.android/debug.keystore" -storepass android \
    -alias androiddebugkey 2>/dev/null | sed -n 's/^\s*SHA256: //p' | tr -d ':' | tr 'A-F' 'a-f')"
  WFE_ANDROID_KEY_PROPERTIES="$real_props" flutter build apk --release \
    --target-platform android-arm64 --split-per-abi >/dev/null
  certs="$("$bt/apksigner" verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk)"
  grep -q "certificate SHA-256 digest: $release_cert" <<<"$certs" \
    && echo "  ok   the APK carries the release certificate" \
    || { echo "  FAIL the APK does not carry the release certificate"; fail=1; }
  if [[ -n "$debug_cert" ]] && grep -q "certificate SHA-256 digest: $debug_cert" <<<"$certs"; then
    echo "  FAIL the APK carries the debug certificate"; fail=1
  else
    echo "  ok   the APK does not carry the debug certificate"
  fi
fi

[[ $fail -eq 0 ]] && echo "Release signing: all checks passed" || { echo "Release signing: FAILED"; exit 1; }
