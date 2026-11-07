#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `publish-page` of tools/rel: the release page (tools/releases/README.md): build.py add
# from the run's files, render into the page repository, check the changelog has the version's
# entry, commit there and deploy with its ./deploy-epic-cash.sh (which checks the live URLs).
# Then commits the new tools/releases/releases.json on main in <main checkout> (as tag.sh tags
# there), so main always has the released version; publish-source stops at the release commit,
# so GitHub gets this one with the next release. Only when that is safe: the checkout is on main, no merge/rebase/cherry-pick is in progress and its
# releases.json has no change of its own; the commit takes that one file (git commit --only), so
# whatever else is staged or changed there stays as it was. Otherwise nothing is committed and the
# step leaves notice.json (one message to the owner, in the report) saying what to commit by hand.
# A copy of the file stays in the step's folder either way; the release source's copy goes back
# to the commit's.
# REL_GITHUB=1 (release.toml publish.github) adds the GitHub Release as a Mirror link.
# When publish-downloads served a signed SHA256SUMS (the run's signer), build.py sees a
# SHA256SUMS.sig beside the files and the page shows the signature check.
# Usage: publish-page.sh <version> <files dir> <page repo> <main checkout>
set -euo pipefail
v="${1:?usage: $0 <version> <files dir> <page repo> <main checkout>}" dir="${2:?}" site="${3:?}" main="${4:?}"
src="${REL_SRC:?}"
log="$site/site/epic-cash/changelog/index.html"
grep -q "id=\"v$v\"" "$log" || { echo "the changelog has no entry id=\"v$v\" ($log): write it first" >&2; exit 1; }
mirror=()
[[ "${REL_GITHUB:-0}" == 1 ]] && mirror=(--github)
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
python3 "$src/tools/releases/build.py" add "$v" "$dir" "${mirror[@]}"
WFE_RELEASES_SITE="$site/site/epic-cash" python3 "$src/tools/releases/build.py" render
cd "$site"
if [[ -n "$(git status --porcelain site/epic-cash)" ]]; then
  git add site/epic-cash
  git commit -q -m "Epic Cash $v release page"
fi
./deploy-epic-cash.sh
stage="${REL_STAGE:-${REL_RUN:?}/publish-page-out}"
mkdir -p "$stage" && cp -f "$src/tools/releases/releases.json" "$stage/releases.json"
# The release source stays clean: a later run of the same commit (tools/rel --follow-up) uses it.
if git -C "$src" rev-parse -q --git-dir >/dev/null 2>&1; then
  git -C "$src" checkout -q -- tools/releases/releases.json
fi
echo "page deployed"

# main's releases.json: the record of this release (build.py add replaces the one record).
rj=tools/releases/releases.json
m() { git -C "$main" "$@"; }
why=""
if [[ "$(m symbolic-ref -q --short HEAD 2>/dev/null || true)" != main ]]; then
  why="$main is not on branch main"
elif gd="$(m rev-parse --absolute-git-dir)" && [[ -e "$gd/MERGE_HEAD" || -e "$gd/CHERRY_PICK_HEAD" || -e "$gd/REVERT_HEAD" \
        || -d "$gd/rebase-merge" || -d "$gd/rebase-apply" ]]; then
  why="a merge, rebase or cherry-pick is in progress in $main"
elif [[ -n "$(m status --porcelain -- "$rj")" ]]; then
  why="$main has its own change to $rj"
fi
if [[ -z "$why" ]]; then
  if cmp -s "$stage/releases.json" "$main/$rj"; then
    echo "main already has $v in $rj"
  else
    cp -f "$stage/releases.json" "$main/$rj"
    if m commit -q --only -m "Release $v: the releases page data" -- "$rj"; then
      echo "committed $rj on main: $(m rev-parse --short HEAD)"
    else
      m checkout -q -- "$rj"
      why="git commit in $main failed (its log above)"
    fi
  fi
fi
if [[ -n "$why" ]]; then
  echo "WARNING: $rj not committed on main: $why" >&2
  python3 -I - "$stage/notice.json" "$v" "$why" "$stage/releases.json" "$main" <<'PY'
import json, sys
out, v, why, copy, main = sys.argv[1:]
with open(out, "w", encoding="utf-8") as f:
    json.dump({"title": f"{v}: releases.json not committed on main",
               "detail": f"{why}. Copy {copy} to {main}/tools/releases/releases.json and commit it on main.",
               "expects": "commit releases.json on main by hand"}, f)
PY
fi
