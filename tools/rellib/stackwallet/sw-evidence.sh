#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Evidence of one step of the live check: a screenshot of the emulator and Stack Wallet's log lines
# (logcat, the app's own pid only) into $SW_OUT (default ./sw-evidence). No wallet data is read.
#   sw-evidence.sh <step name>
set -euo pipefail
sdk="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
adb=("$sdk/platform-tools/adb" -s emulator-5560)
out="${SW_OUT:-./sw-evidence}"; step="${1:?step name}"
mkdir -p "$out"
stamp="$(date +%H%M%S)-${step// /-}"
"${adb[@]}" exec-out screencap -p >"$out/$stamp.png"
pid="$("${adb[@]}" shell pidof com.cypherstack.stackwallet | tr -d '\r' | cut -d' ' -f1 || true)"
if [[ -n "$pid" ]]; then "${adb[@]}" logcat -d --pid="$pid" >"$out/$stamp.log"; else echo "app not running" >"$out/$stamp.log"; fi
grep -ci "unable to parse" "$out/$stamp.log" | sed "s/^/'unable to parse' lines in $stamp.log: /"
