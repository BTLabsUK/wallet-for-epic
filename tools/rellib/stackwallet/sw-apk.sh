#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Stack Wallet for the live check: fetch the pinned official APK (apk.lock), verify it, and manage the
# QA emulator that holds it. Never creates or funds a wallet.
#   sw-apk.sh fetch            download the asset into $SW_APK_DIR (default ~/.cache/rel-stackwallet), verify size, sha256 and signer
#   sw-apk.sh start            boot AVD wfe_sw headless on port 5560 (a free port: another AVD is never touched)
#   sw-apk.sh install          adb install -r the verified APK on emulator-5560
#   sw-apk.sh stop             adb emu kill, wait for the process to go
#   sw-apk.sh status           what is installed
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/apk.lock"
sdk="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
adb="$sdk/platform-tools/adb"
avd=wfe_sw port=5560 serial=emulator-5560
dir="${SW_APK_DIR:-$HOME/.cache/rel-stackwallet}"
apk="$dir/$asset"

signer_of() { "$(ls -d "$sdk"/build-tools/* | sort -V | tail -1)/apksigner" verify --print-certs "$1" | sed -n 's/^Signer #1 certificate SHA-256 digest: //p'; }

case "${1:-}" in
  fetch)
    mkdir -p "$dir"
    [[ -f "$apk" ]] || gh release download "$tag" -R "$repo" -p "$asset" -D "$dir"
    [[ "$(stat -c %s "$apk")" == "$size" ]] || { echo "size differs from apk.lock" >&2; exit 1; }
    [[ "$(sha256sum "$apk" | cut -d' ' -f1)" == "$sha256" ]] || { echo "sha256 differs from apk.lock" >&2; exit 1; }
    [[ "$(signer_of "$apk")" == "$signer_sha256" ]] || { echo "signing certificate differs from apk.lock" >&2; exit 1; }
    echo "ok: $asset $version ($version_code), sha256 $sha256, signer $signer_sha256" ;;
  start)
    "$adb" devices | grep -q "^$serial\b" && { echo "$serial already running"; exit 0; }
    setsid "$sdk/emulator/emulator" -avd "$avd" -no-window -no-audio -no-boot-anim -port "$port" -gpu swiftshader_indirect \
      >"$dir/emulator.log" 2>&1 </dev/null &
    for _ in $(seq 1 90); do
      [[ "$("$adb" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == 1 ]] && { echo "booted"; exit 0; }
      sleep 2
    done
    echo "did not boot (see $dir/emulator.log)" >&2; exit 1 ;;
  install)
    "$0" fetch
    "$adb" -s "$serial" install -r "$apk" ;;
  stop)
    "$adb" -s "$serial" emu kill >/dev/null 2>&1 || true
    for _ in $(seq 1 30); do pgrep -f "avd $avd " >/dev/null || { echo stopped; exit 0; }; sleep 1; done
    echo "still running" >&2; exit 1 ;;
  status)
    "$adb" -s "$serial" shell dumpsys package "$package" | grep -E "versionName|versionCode" | head -2 ;;
  *) sed -n 3,10p "$0"; exit 2 ;;
esac
