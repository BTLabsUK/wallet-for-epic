#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `publish-page` of tools/rel: the release page (tools/releases/README.md): build.py add
# from the run's files, render into the page repository, check the changelog has the version's
# entry, commit there and deploy with its ./deploy-epic-cash.sh (which checks the live URLs).
# Leaves tools/releases/releases.json changed in the release worktree, with a copy in the step's
# folder (the worktree goes at cleanup): commit it on main (docs/RELEASING.md, After the release).
# REL_GITHUB=1 (release.toml publish.github) adds the GitHub Release as a Mirror link.
# Usage: publish-page.sh <version> <files dir> <page repo>
set -euo pipefail
v="${1:?usage: $0 <version> <files dir> <page repo>}" dir="${2:?}" site="${3:?}"
src="${REL_SRC:?}"
log="$site/site/epic-cash/changelog/index.html"
grep -q "id=\"v$v\"" "$log" || { echo "the changelog has no entry id=\"v$v\" ($log): write it first" >&2; exit 1; }
mirror=()
[[ "${REL_GITHUB:-0}" == 1 ]] && mirror=(--github)
python3 "$src/tools/releases/build.py" add "$v" "$dir" "${mirror[@]}"
WFE_RELEASES_SITE="$site/site/epic-cash" python3 "$src/tools/releases/build.py" render
cd "$site"
if [[ -n "$(git status --porcelain site/epic-cash)" ]]; then
  git add site/epic-cash
  git commit -q -m "Epic Cash $v release page"
fi
./deploy-epic-cash.sh
if [[ -n "${REL_STAGE:-}" ]]; then
  mkdir -p "$REL_STAGE" && cp -f "$src/tools/releases/releases.json" "$REL_STAGE/releases.json"
fi
echo "page deployed; commit tools/releases/releases.json on main (copy: ${REL_STAGE:-the release worktree}/releases.json)"
