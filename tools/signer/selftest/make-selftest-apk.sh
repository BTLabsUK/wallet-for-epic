#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Rebuilds selftest-unsigned.apk: an empty, code-free APK of package uk.btlabs.signer.selftest
# (never one of ours), which `btsign selftest` signs to read back the release certificate. The
# committed file is pinned by SHA-256 in btsign/ops.py (SELFTEST_APK_SHA256); a rebuild that
# gives other bytes needs that pin changed in the same commit.
# Usage: make-selftest-apk.sh [<android sdk>]
set -euo pipefail
sdk="${1:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
bt="$(ls -d "$sdk"/build-tools/* | sort -V | tail -1)"
jar="$(ls -d "$sdk"/platforms/android-* | sort -V | tail -1)/android.jar"
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cat >"$work/AndroidManifest.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="uk.btlabs.signer.selftest" android:versionCode="1" android:versionName="selftest">
    <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="24" />
    <application android:hasCode="false" android:label="btsign selftest (not an app)" />
</manifest>
XML
"$bt/aapt2" link --manifest "$work/AndroidManifest.xml" -I "$jar" -o "$work/raw.apk"
"$bt/zipalign" -f -P 16 4 "$work/raw.apk" "$here/selftest-unsigned.apk"
sha256sum "$here/selftest-unsigned.apk"
