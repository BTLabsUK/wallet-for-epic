#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# The flow lanes' Android test build (release/pipeline.toml testbuild-android): the candidate's
# emulator APK, built unsigned like a release build and signed here with this machine's debug key,
# never the release key. It is never shipped: it stays in the step's folder.
# Usage: testbuild-android.sh <step out dir>   (from the release checkout; WFE_TOR as the build's)
set -euo pipefail
out="${1:?step out dir}"
WFE_UNSIGNED=1 WFE_EMULATOR_X86_64=1 app/tool/build_android_release.sh "$out"
. tools/env.sh
bt="$(find "$ANDROID_HOME/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
ks="$HOME/.android/debug.keystore"
if [[ ! -f "$ks" ]]; then
  mkdir -p "$(dirname "$ks")"
  keytool -genkeypair -keystore "$ks" -storepass android -keypass android -alias androiddebugkey \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" -noprompt
fi
for apk in "$out"/emulator/*.apk; do
  "$bt/zipalign" -f -p 4 "$apk" "$apk.aligned"
  "$bt/apksigner" sign --ks "$ks" --ks-pass pass:android --key-pass pass:android \
    --ks-key-alias androiddebugkey --out "$apk" "$apk.aligned"
  rm -f -- "$apk.aligned" "$apk.idsig"
  "$bt/apksigner" verify "$apk"
done
