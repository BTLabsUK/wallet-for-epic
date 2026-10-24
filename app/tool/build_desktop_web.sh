#!/usr/bin/env bash
# Builds the desktop interface (canned data only) as a static web site that works from any
# sub-path of a host: base href "./".
#
# Usage: tool/build_desktop_web.sh [output-dir]   (default: build/desktop_web)
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

out="${1:-build/desktop_web}"
[[ "$out" == /* ]] || out="$PWD/$out"
cd "$app_dir"

flutter build web --release -t lib/main_desktop_web.dart \
  --dart-define=WFE_DESK_MOCK=true ${WFE_DESK_START:+--dart-define=WFE_DESK_START=$WFE_DESK_START} \
  --no-web-resources-cdn --no-wasm-dry-run --base-href / -o "$out"

# Relative base, so the site runs under any path. Fail loudly if the build changed shape.
grep -q '<base href="/">' "$out/index.html" || { echo "build_desktop_web: no <base href=\"/\"> in index.html" >&2; exit 1; }
sed -i 's|<base href="/">|<base href="./">|' "$out/index.html"
if grep -nE "(['\"])/(main\.dart\.js|flutter|assets|canvaskit|icons|manifest)" "$out/flutter_bootstrap.js" "$out/index.html"; then
  echo "build_desktop_web: absolute path found above" >&2
  exit 1
fi
echo "build_desktop_web: $out"
