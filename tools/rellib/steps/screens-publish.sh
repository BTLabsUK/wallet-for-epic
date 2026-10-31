#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `screens-publish` of tools/rel, after G6 (verify-live): the release is live, so its screen
# catalogue (rendered before the gate by step `screens`) becomes `latest` and the public gallery
# https://epiccash.btlabs.uk/screens/ (docs/RELEASING.md, "Screens"):
#   1. tools/screens.sh <version> --promote   points `latest` at it, keeps the two newest versions;
#   2. tools/screens-publish.sh <version>     builds the public copy (manifest.json's images only:
#      the real/ screens of the trust drivers and the tours' logs never leave this machine) and
#      deploys it; one the site already serves is not deployed again.
# A TEST run or the scratch target builds the public copy only (--build-only) and leaves `latest`
# alone: nothing was published. Never holds the release: warn_only in release/pipeline.toml.
# Leaves <stage>/links.json (the gallery link for the live message) after a live deploy.
# Usage: screens-publish.sh <version> <stage dir>   (from the release checkout; env REL_SRC)
set -euo pipefail
v="${1:?usage: $0 <version> <stage dir>}" stage="${2:?}"
src="${REL_SRC:-$PWD}"
root="${SCREENS_ROOT:-$HOME/epic-build/screens}"
url="https://epiccash.btlabs.uk/screens/"
mkdir -p "$stage"
[[ -f $root/$v/manifest.json ]] || { echo "screens-publish: no catalogue $root/$v (step screens did not make one)" >&2; exit 1; }

if [[ "${REL_TEST:-0}" == 1 || "${REL_TARGET:-live}" == scratch ]]; then
  "$src/tools/screens-publish.sh" "$v" --build-only
  echo "scratch target: public copy built; latest and the site not touched"
  exit 0
fi
"$src/tools/screens.sh" "$v" --promote
# Deployed again only when the site does not serve this version, or serves an older render of it
# (.published-key: the content key of the last deploy, .rel-key: the catalogue's).
key="$(cat "$root/$v/.rel-key" 2>/dev/null || echo none)"
live="$(curl -fsS --max-time 15 "${url}version.json" 2>/dev/null || true)"
if [[ $live == *"\"$v\""* && "$(cat "$root/$v/.published-key" 2>/dev/null || true)" == "$key" ]]; then
  echo "$url already serves this catalogue of $v: not deployed again"
else
  "$src/tools/screens-publish.sh" "$v"
  printf '%s\n' "$key" >"$root/$v/.published-key"
fi
printf '[{"label": "Screens %s", "url": "%s"}]\n' "$v" "$url" >"$stage/links.json"
echo "screens: $url serves $v"
