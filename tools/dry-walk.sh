#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Seeded dry walk: the phone and desktop tours visit the lanes' screens on seeded data, no coins, no
# device, and tools/ui-targets walk fails when a target a driver presses is on no screen of its tour.
# Usage: tools/dry-walk.sh <out-dir>   (from anywhere inside the main checkout or a worktree)
set -uo pipefail
out=${1:?usage: tools/dry-walk.sh <out-dir>}
root="$(git rev-parse --show-toplevel)"
. "$root/tools/env.sh"
heavy=()
command -v build-slot >/dev/null && heavy=(build-slot)
mkdir -p "$out/phone" "$out/desktop"
out=$(cd "$out" && pwd)
rc=0
# A fresh worktree has the clones, not this host's library: the prebuilt cache has it.
LEPIC_SHARED=1 "${heavy[@]}" "$root/tools/lepic.sh" build linux >"$out/lepic.log" 2>&1 || rc=$?
cd "$root/app" || exit 1
SHOTS_META=1 TOUR_SHOTS_OUT="$out/phone" "${heavy[@]}" flutter test tool/screenshot_tour_test.dart >"$out/phone.log" 2>&1 || rc=$?
tail -n 1 "$out/phone.log"
SHOTS_META=1 DESK_SHOTS_OUT="$out/desktop" "${heavy[@]}" flutter test tool/desktop_tour_test.dart >"$out/desktop.log" 2>&1 || rc=$?
tail -n 1 "$out/desktop.log"
"$root/tools/ui-targets" walk "$out" || rc=$?
exit $rc
