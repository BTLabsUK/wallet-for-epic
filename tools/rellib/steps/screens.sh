#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `screens` of tools/rel, after G6 (verify-live): the release's screen catalogue, as the
# release lead did by hand up to 26.10.23 (docs/RELEASING.md, the `screens` row):
#   1. tools/screens.sh <version> --src <release checkout>  renders both screenshot tours of this
#      release's own source into /tmp/epic-build/screens/<version>/ (its lock, its .stage-* folder,
#      `latest`, the two newest versions kept);
#   2. tools/screens-publish.sh <version>  builds the public copy and deploys
#      https://epiccash.btlabs.uk/screens/ (the server keeps two versions too).
# Reuse: the catalogue is a function of the app and the catalogue tools. Their content key (git
# ids at the release commit, plus the version) is kept in <catalogue>/.rel-key; a catalogue of
# this version with the same key is not rendered again, and one the site already serves is not
# deployed again. A version bump changes the app, so another version is always rendered.
# A TEST run or the scratch target builds the public copy only (--build-only): the site is not
# touched. Never holds the release: the step is warn_only in release/pipeline.toml, so a failure
# here is a warning in the live message and the report.
# Leaves <stage>/links.json (the gallery link for the live message) after a live deploy.
# Usage: screens.sh <version> <stage dir>   (from the release checkout; env REL_SRC REL_COMMIT)
set -euo pipefail
v="${1:?usage: $0 <version> <stage dir>}" stage="${2:?}"
src="${REL_SRC:-$PWD}" commit="${REL_COMMIT:-$(git -C "$src" rev-parse HEAD)}"
root="${SCREENS_ROOT:-$HOME/epic-build/screens}"
url="https://epiccash.btlabs.uk/screens/"
mkdir -p "$stage"

# What the screens are made of: the app (screens, assets, translations, the tours in app/tool),
# the catalogue tools, the toolchain pins.
paths=(app tools/screens.sh tools/screens.py tools/screens_index.html tools/env.sh
       tools/lepic.rev tools/lepic-flutter.rev scripts/linux/flutter.version)
key="$(for p in "${paths[@]}"; do
         printf '%s %s\n' "$p" "$(git -C "$src" rev-parse -q --verify "$commit:$p" 2>/dev/null || echo none)"
       done | { cat; echo "version $v"; } | sha256sum | cut -c1-16)"
echo "content key $key (${paths[*]} at ${commit:0:12}, version $v)"

reused=0
if [[ -f "$root/$v/manifest.json" && "$(cat "$root/$v/.rel-key" 2>/dev/null || true)" == "$key" ]]; then
  reused=1
  echo "catalogue $root/$v has the same key: not rendered again"
else
  "$src/tools/screens.sh" "$v" --src "$src"
  # Under the catalogue's own lock, so no other run of tools/screens.sh replaces it meanwhile.
  (flock -w 600 9 && printf '%s\n' "$key" >"$root/$v/.rel-key") 9>"$root/.lock"
fi

if [[ "${REL_TEST:-0}" == 1 || "${REL_TARGET:-live}" == scratch ]]; then
  "$src/tools/screens-publish.sh" "$v" --build-only
  echo "scratch target: public copy built, the site not touched"
  exit 0
fi
live="$(curl -fsS --max-time 15 "${url}version.json" 2>/dev/null || true)"
if [[ $reused == 1 && $live == *"\"$v\""* ]]; then
  echo "$url already serves $v: not deployed again"
else
  "$src/tools/screens-publish.sh" "$v"
fi
printf '[{"label": "Screens %s", "url": "%s"}]\n' "$v" "$url" >"$stage/links.json"
echo "screens: $url serves $v"
