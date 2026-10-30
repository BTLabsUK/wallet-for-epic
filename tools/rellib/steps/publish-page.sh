#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `publish-page` of tools/rel: the release page (tools/releases/README.md): build.py add
# from the run's files, render into the page repository, check the changelog has the version's
# entry, commit there and deploy with its ./deploy-epic-cash.sh (which checks the live URLs).
# Leaves tools/releases/releases.json changed in the release worktree: commit it on main.
# Usage: publish-page.sh <version> <files dir> <page repo>
set -euo pipefail
v="${1:?usage: $0 <version> <files dir> <page repo>}" dir="${2:?}" site="${3:?}"
src="${REL_SRC:?}"
log="$site/site/epic-cash/changelog/index.html"
grep -q "id=\"v$v\"" "$log" || { echo "the changelog has no entry id=\"v$v\" ($log): write it first" >&2; exit 1; }
python3 "$src/tools/releases/build.py" add "$v" "$dir"
WFE_RELEASES_SITE="$site/site/epic-cash" python3 "$src/tools/releases/build.py" render
cd "$site"
if [[ -n "$(git status --porcelain site/epic-cash)" ]]; then
  git add site/epic-cash
  git commit -q -m "Epic Cash $v release page"
fi
./deploy-epic-cash.sh
echo "page deployed; commit tools/releases/releases.json on main"
