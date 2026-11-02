#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Builds the phone app as a clickable web preview on the fake wallet (no server)
# and stages it for publishing under any path. Every visit is a fresh install: the wallet level
# step, then the normal PIN pad (any PIN opens the fake wallet), then Home with a live payment
# timeline (a send walks through its steps, a payment from Bob arrives ~20 s after Home) and
# the Epicbox relay going quiet at level 1 (~45 s, or `?relaydown`) with the offer to move
# (web/preview.dart, preview_live.dart, preview_levels.dart).
#
# Usage: tool/build_preview.sh <out dir>
#
# The out dir gets build/web with a relative base href (the publish URL's path is not known
# before publishing) and without the .gz/.br files a plain static server would not use.
set -euo pipefail

out="${1:?usage: tool/build_preview.sh <out dir>}"
app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

cd "$app_dir"
build=(flutter build web --release --wasm --no-web-resources-cdn --base-href /app/
  --dart-define=WFE_WEB_FAKE=true)
"${build[@]}"

mkdir -p "$out"
cp -a build/web/. "$out/"
sed -i 's#<base href="/app/">#<base href="./">#' "$out/index.html"
grep -q '<base href="./">' "$out/index.html" || { echo "base href not set" >&2; exit 1; }
find "$out" -type f \( -name '*.gz' -o -name '*.br' \) -delete
echo "preview staged in $out"
