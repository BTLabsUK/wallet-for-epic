#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `screens` of tools/rel, BEFORE the publish gate: the release's screen catalogue, rendered
# from the release source as soon as G2 (source-check) passed, in its own lane beside the builds and
# G4 (docs/RELEASING.md, "Screens"):
#   tools/screens.sh <version> --src <release checkout> --candidate
# renders both screenshot tours (each flutter test through build-slot, so it takes the machine's
# build slots like a build) into /tmp/epic-build/screens/<version>/. --candidate: `latest` stays on the
# published release (the gallery and everyone reading `latest` see the release that is live) and
# that release's catalogue is never pruned: it is what step screens-check compares with. Step
# screens-publish points `latest` here and deploys the gallery after the read-back (G6).
# Reuse: the catalogue is a function of the app and the catalogue tools. Their content key (git
# ids at the release commit, plus the version) is kept in <catalogue>/.rel-key; a catalogue of
# this version with the same key is not rendered again. A version bump changes the app, so another
# version is always rendered.
# Leaves <stage>/render.json {version, ok, reused, key, catalogue, seconds, note}. The step is
# warn_only (release/pipeline.toml): a failed render holds nothing by itself; screens-check, before
# the gate, turns a missing catalogue or a failed tour into a FAIL with the failed tests named.
# Usage: screens.sh <version> <stage dir>   (from the release checkout; env REL_SRC REL_COMMIT)
set -euo pipefail
v="${1:?usage: $0 <version> <stage dir>}" stage="${2:?}"
src="${REL_SRC:-$PWD}" commit="${REL_COMMIT:-$(git -C "$src" rev-parse HEAD)}"
root="${SCREENS_ROOT:-$HOME/epic-build/screens}"
mkdir -p "$stage"
t0=$(date +%s)

# What the screens are made of: the app (screens, assets, translations, the tours in app/tool),
# the catalogue tools, the toolchain pins.
paths=(app tools/screens.sh tools/screens.py tools/screens_index.html tools/env.sh
       tools/lepic.rev tools/lepic-flutter.rev scripts/linux/flutter.version)
key="$(for p in "${paths[@]}"; do
         printf '%s %s\n' "$p" "$(git -C "$src" rev-parse -q --verify "$commit:$p" 2>/dev/null || echo none)"
       done | { cat; echo "version $v"; } | sha256sum | cut -c1-16)"
echo "content key $key (${paths[*]} at ${commit:0:12}, version $v)"

result() {  # ok reused note
  python3 - "$stage/render.json" "$v" "$1" "$2" "$key" "$root/$v" "$(( $(date +%s) - t0 ))" "$3" <<'PY'
import json, sys
p, v, ok, reused, key, cat, secs, note = sys.argv[1:]
json.dump({"version": v, "ok": ok == "1", "reused": reused == "1", "key": key, "catalogue": cat,
           "seconds": int(secs), "note": note}, open(p, "w"))
PY
}

if [[ -f "$root/$v/manifest.json" && "$(cat "$root/$v/.rel-key" 2>/dev/null || true)" == "$key" ]]; then
  echo "catalogue $root/$v has the same key: not rendered again"
  result 1 1 "same content key: reused"
  exit 0
fi
if ! "$src/tools/screens.sh" "$v" --src "$src" --candidate; then
  result 0 0 "tools/screens.sh failed (tour logs in $root/failed-$v.logs when a tour failed)"
  exit 1
fi
# Under the catalogue's own lock, so no other run of tools/screens.sh replaces it meanwhile.
(flock -w 600 9 && printf '%s\n' "$key" >"$root/$v/.rel-key") 9>"$root/.lock"
result 1 0 "rendered"
echo "screens: $root/$v ready (candidate: latest stays on the published release)"
