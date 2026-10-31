#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `tag` of tools/rel, right after the publish gate and before anything leaves this machine:
# the release tag on the release commit, "git tag -a v<version> -m 'Epic Cash <version>'" as every
# release before had it by hand (https://docs.btlabs.uk/developers/releases/, Cutting a release). publish-source
# pushes it to GitLab (and GitHub), where publish-github-release needs it; G4 of the next release
# reads it as the previous release's ref (published.json).
# - The commit must be on main (the old process merged the release into main first): a release
#   from anywhere else stops here, before the downloads.
# - v<version> already on this commit: kept. On another commit (a rebuild of the same version,
#   as 26.10.16 and 26.10.24 were): the next free v<version>-r2, -r3, …, or the one already on
#   this commit.
# - A TEST run or the scratch target (REL_TARGET=scratch) makes no tag: it says which it would make.
# Writes the tag's name to <stage>/tag.txt.
# Usage: tag.sh <version> <commit> <main checkout> <stage dir>
set -euo pipefail
v="${1:?usage: $0 <version> <commit> <main checkout> <stage dir>}" commit="${2:?}" repo="${3:?}" stage="${4:?}"
mkdir -p "$stage"
g() { git -C "$repo" "$@"; }
on_main=1
g merge-base --is-ancestor "$commit" main || on_main=0
at() { g rev-parse -q --verify "refs/tags/$1^{commit}" 2>/dev/null || true; }
name="v$v" n=1
while :; do
  here="$(at "$name")"
  [[ -z "$here" || "$here" == "$commit" ]] && break
  n=$((n + 1)); name="v$v-r$n"
done
if [[ "${REL_TEST:-0}" == 1 || "${REL_TARGET:-live}" == scratch ]]; then
  echo "scratch target: would tag $commit as $name (no tag made)"
  [[ $on_main == 1 ]] || echo "warning: $commit is not on main: a live release of it would stop here"
  echo "$name" >"$stage/tag.txt"
  exit 0
fi
[[ $on_main == 1 ]] \
  || { echo "the release commit $commit is not on main in $repo: merge it into main first" >&2; exit 1; }
if [[ -n "$here" ]]; then
  echo "$name is already on $commit: kept"
else
  g tag -a "$name" -m "Epic Cash ${name#v}" "$commit"
  echo "tagged $commit as $name"
fi
echo "$name" >"$stage/tag.txt"
