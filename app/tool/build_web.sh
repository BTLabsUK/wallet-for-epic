#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Builds the web app the way the demo serves it, then
# precompresses it and prints what a first load transfers.
#
# Usage: tool/build_web.sh [--base-href /app/] [--fake]
#   --base-href  the path the app is served under, with both slashes (default /app/)
#   --fake       --dart-define=WFE_WEB_FAKE=true: the tour's fake wallet, no server. For QA
#                previews only; no release uses it.
#
# Output: build/web, with a .gz (and a .br where `brotli` is installed) beside every file the
# server may send compressed.
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../../tools/env.sh
. "$app_dir/../tools/env.sh"

base_href=/app/
fake=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-href) base_href="${2:?--base-href needs a path}"; shift 2 ;;
    --fake) fake=true; shift ;;
    *) sed -n '5,8p' "${BASH_SOURCE[0]}" >&2; exit 64 ;;
  esac
done
[[ "$base_href" == /*/ || "$base_href" == / ]] || {
  echo "--base-href must start and end with /: $base_href" >&2
  exit 64
}

cd "$app_dir"
out="$app_dir/build/web"
log="$(mktemp -t wfe-build-web.XXXXXX)"
trap 'rm -f "$log"' EXIT

defines=(--dart-define=WFE_DEMO=true)
$fake && defines+=(--dart-define=WFE_WEB_FAKE=true)

# --wasm writes dart2wasm+skwasm and dart2js+CanvasKit side by side; the loader picks one per
# browser. --no-web-resources-cdn keeps the engine on our origin.
set +e
flutter build web --release --wasm --no-web-resources-cdn --base-href "$base_href" \
  "${defines[@]}" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
set -e
[[ $status -eq 0 ]] || exit "$status"
# A Wasm incompatibility the build only warns about still means a broken skwasm path.
if grep -qiE 'wasm dry run|not compatible with wasm' "$log"; then
  echo "build_web: the build reported a Wasm incompatibility (above)" >&2
  exit 1
fi

# Precompress what the server may send compressed. -k keeps the original for clients that
# accept neither.
have_brotli=false
command -v brotli >/dev/null && have_brotli=true
while IFS= read -r -d '' f; do
  gzip -9 -k -f -n "$f"
  $have_brotli && brotli -q 11 -k -f "$f"
done < <(find "$out" -type f \( -name '*.wasm' -o -name '*.js' -o -name '*.mjs' \
  -o -name '*.json' -o -name '*.html' -o -name '*.otf' -o -name '*.ttf' -o -name '*.bin' \
  -o -name NOTICES \) -print0)

# What a first load fetches, compressed the way the server sends it (.br when made, else .gz).
sent() {
  local f="$out/$1"
  [[ -f "$f" ]] || { echo "build_web: expected $1 in the build" >&2; return 1; }
  if [[ -f "$f.br" ]]; then stat -c %s "$f.br"
  elif [[ -f "$f.gz" ]]; then stat -c %s "$f.gz"
  else stat -c %s "$f"; fi
}
total() {
  local sum=0 n
  for f in "$@"; do n=$(sent "$f") || return 1; sum=$((sum + n)); done
  echo "$sum"
}
kib() { awk -v b="$1" 'BEGIN { printf "%.0f KiB", b / 1024 }'; }

# Fonts the engine waits for: every asset in FontManifest.json.
mapfile -t fonts < <(python3 -c '
import json, sys
for family in json.load(open(sys.argv[1])):
    for font in family["fonts"]:
        print("assets/" + font["asset"])
' "$out/assets/FontManifest.json")
# What Chrome fetched from a fake build before its first screen, besides icons.
common=(index.html flutter_bootstrap.js manifest.json assets/FontManifest.json "${fonts[@]}")
skwasm=$(total "${common[@]}" main.dart.wasm main.dart.mjs canvaskit/skwasm.js canvaskit/skwasm.wasm)
canvaskit=$(total "${common[@]}" main.dart.js canvaskit/canvaskit.js canvaskit/canvaskit.wasm)

echo
echo "build_web: $out (base href $base_href$($fake && echo ', fake wallet'))"
echo "  compressed with gzip$($have_brotli && echo ' and brotli' || echo '; brotli not installed')"
echo "  first load, skwasm (Chromium):                  $(kib "$skwasm")"
echo "  first load, CanvasKit (Safari, Firefox, iOS):   $(kib "$canvaskit")"
echo "  not counted: Noto fallbacks for missing glyphs (fonts.gstatic.com), icons"
