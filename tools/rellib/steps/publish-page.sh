#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `publish-page` of tools/rel: the release page (tools/releases/README.md): build.py add
# from the run's files, render into the page repository, check the changelog has the version's
# entry, commit there and deploy with its ./deploy-epic-cash.sh (which checks the live URLs).
# Leaves tools/releases/releases.json changed in the release worktree: commit it on main.
# When publish-downloads served a signed SHA256SUMS (the run's signer), build.py sees a
# SHA256SUMS.sig beside the files and the page shows the signature check.
# Usage: publish-page.sh <version> <files dir> <page repo>
set -euo pipefail
v="${1:?usage: $0 <version> <files dir> <page repo>}" dir="${2:?}" site="${3:?}"
src="${REL_SRC:?}"
log="$site/site/epic-cash/changelog/index.html"
grep -q "id=\"v$v\"" "$log" || { echo "the changelog has no entry id=\"v$v\" ($log): write it first" >&2; exit 1; }
sig=""
for c in "${REL_MANIFESTS:-/nonexistent}/SHA256SUMS.sig" "${REL_RUN:-/nonexistent}/publish-sums/SHA256SUMS.sig"; do
  if [[ -z "$sig" && -f "$c" && -f "${REL_RUN:-/nonexistent}/signer.json" ]]; then sig="$c"; fi
done
if [[ -n "$sig" ]]; then
  # The run's files as links (build.py hashes them), with the signature beside them.
  view="${REL_RUN:?}/page-files"
  mkdir -p "$view"
  for f in "$dir"/*; do ln -sfn "$f" "$view/$(basename "$f")"; done
  cp -f "$sig" "$view/SHA256SUMS.sig"
  dir="$view"
fi
python3 "$src/tools/releases/build.py" add "$v" "$dir"
WFE_RELEASES_SITE="$site/site/epic-cash" python3 "$src/tools/releases/build.py" render
cd "$site"
if [[ -n "$(git status --porcelain site/epic-cash)" ]]; then
  git add site/epic-cash
  git commit -q -m "Epic Cash $v release page"
fi
./deploy-epic-cash.sh
echo "page deployed; commit tools/releases/releases.json on main"
