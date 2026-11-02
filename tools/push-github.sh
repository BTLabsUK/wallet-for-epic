#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Pushes a local repository's main and tags to GitHub (github.com/BTLabsUK/<repo>, the only public
# home) for the repositories that are published as they are: btlabs-docs, epic-status and
# btlabs-epic.github.io. LEPIC, lepic-flutter and wallet-for-epic are published only through
# tools/publish-github.sh (filtered history) and are refused here. Runs from our own machines (no
# CI on GitHub; the rules: https://docs.btlabs.uk/developers/releases/ "Publishing to GitHub").
#
#   tools/push-github.sh [--dry-run] [--replace] <repo> [<local repository>]
#
# The local repository defaults to ~/<repo>, else ~/code/<repo>. Per run:
#   1. refuses when any commit on the local main carries an agent path or a CI workflow file;
#   2. creates a missing GitHub repository (private: making it public is the owner's click), and
#      turns Actions and Pages off on every run if someone switched them on;
#   3. compares GitHub with the local main and tags and pushes what differs over SSH: main as a
#      fast-forward, missing tags. A main that does not extend GitHub's, a moved tag, an extra tag
#      or any other branch is refused unless --replace, which force-pushes main and the moved tags
#      (with a lease on what it saw) and deletes the extra tags and branches;
#   4. reads GitHub back and checks it equals the local main and tags.
#
# A re-run with nothing new pushes nothing. --dry-run changes nothing and prints the plan.
# Environment: GITHUB_OWNER (default BTLabsUK), GITHUB_REPOS (the repositories allowed).
# Git goes over SSH (~/.ssh/config picks the org owner's key for github.com); the API through gh
# with its own config, GH_CONFIG_DIR (default ~/.config/gh-btlabs), logged in as $GITHUB_USER
# (default btlabs-uk); any other gh login is refused.
set -euo pipefail

dry=0 replace=0 args=()
for arg in "$@"; do
  case $arg in
    --dry-run|-n) dry=1 ;;
    --replace) replace=1 ;;
    -h|--help) sed -n '3,25p' "$0"; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) args+=("$arg") ;;
  esac
done
[ ${#args[@]} -ge 1 ] && [ ${#args[@]} -le 2 ] || { sed -n '9p' "$0" >&2; exit 2; }
repo=${args[0]}
read -ra allowed <<<"${GITHUB_REPOS:-btlabs-docs epic-status btlabs-epic.github.io}"
[[ " ${allowed[*]} " == *" $repo "* ]] ||
  { echo "refusing $repo: not in GITHUB_REPOS (${allowed[*]}); LEPIC, lepic-flutter and wallet-for-epic go through tools/publish-github.sh" >&2; exit 2; }
local_repo=${args[1]:-}
if [ -z "$local_repo" ]; then
  for d in "$HOME/$repo" "$HOME/code/$repo"; do [ -d "$d" ] && { local_repo=$d; break; }; done
fi
[ -n "$local_repo" ] && git -C "$local_repo" rev-parse -q --verify refs/heads/main >/dev/null ||
  { echo "no local repository with a main for $repo (${local_repo:-~/$repo, ~/code/$repo})" >&2; exit 1; }

owner=${GITHUB_OWNER:-BTLabsUK}
# Only BT Labs' own organisation: the Epic Cash project's repositories are never touched.
case ${owner,,} in epiccash|epic-cash|epiccash-*) echo "refusing owner $owner" >&2; exit 2 ;; esac
export GH_CONFIG_DIR=${GH_CONFIG_DIR:-$HOME/.config/gh-btlabs} GIT_TERMINAL_PROMPT=0
login=$(gh api user --jq .login 2>/dev/null) || { echo "gh is not logged in (GH_CONFIG_DIR=$GH_CONFIG_DIR)" >&2; exit 1; }
[ "$login" = "${GITHUB_USER:-btlabs-uk}" ] || { echo "gh is logged in as $login, not ${GITHUB_USER:-btlabs-uk}" >&2; exit 1; }
remote="git@github.com:$owner/$repo.git"

# Agent and process paths, and CI workflow files: none may reach GitHub (the letters in
# brackets keep the publish scan of this file quiet).
forbidden='(^|/)\.(k[i]ro|c[l]aude|coord|fleet|cursor|codex|windsurf|continue|aider[^/]*)(/|$)|(^|/)(AGENTS|C[L]AUDE|GEMINI)\.md$|(^|/)(HANDOFF|RESUME)[^/]*$|^\.github/workflows/'

echo "== $repo: $local_repo → github.com/$owner/$repo"
main=$(git -C "$local_repo" rev-parse refs/heads/main)
bad=$(git -C "$local_repo" log --format= --name-only main | sort -u | grep -E "$forbidden" | head -5 || true)
if [ -n "$bad" ]; then echo "   the local main holds paths that must not be published:"; sed 's/^/     /' <<<"$bad"; exit 1; fi
declare -A want=() have=()
while read -r sha ref; do want[$ref]=$sha; done < <(git -C "$local_repo" for-each-ref --format='%(objectname) %(refname)' refs/heads/main refs/tags)

exists=1
gh api "repos/$owner/$repo" --silent 2>/dev/null || exists=0
if [ $exists = 0 ]; then
  echo "   + create github.com/$owner/$repo (private)"
  [ $dry = 1 ] || gh api -X POST "orgs/$owner/repos" -f name="$repo" -f visibility=private \
    -F has_wiki=false -F has_projects=false -F has_discussions=false -F auto_init=false --silent
fi
# No Actions and no Pages, ever: off before the first push, and again if switched on.
if [ $dry = 0 ]; then
  [ "$(gh api "repos/$owner/$repo/actions/permissions" --jq .enabled)" = false ] ||
    { echo "   actions: turning off"; gh api -X PUT "repos/$owner/$repo/actions/permissions" -F enabled=false --silent; }
  [ "$(gh api "repos/$owner/$repo" --jq .has_pages)" = false ] ||
    { echo "   pages: turning off"; gh api -X DELETE "repos/$owner/$repo/pages" --silent; }
fi
if [ $dry = 0 ] || [ $exists = 1 ]; then
  while read -r sha ref; do
    case $ref in refs/heads/*|refs/tags/*) [[ $ref == *'^{}' ]] || have[$ref]=$sha ;; esac
  done < <(git ls-remote "$remote")
fi

# The plan: refspecs to push, refs to delete, refusals without --replace.
specs=() leases=() deletes=() refused=()
for ref in "${!want[@]}"; do
  w=${want[$ref]} h=${have[$ref]:-}
  [ "$h" = "$w" ] && continue
  if [ -z "$h" ]; then specs+=("$w:$ref"); echo "   + $ref ${w:0:12}"; continue; fi
  if [ "$ref" = refs/heads/main ] && git -C "$local_repo" cat-file -e "$h" 2>/dev/null &&
     git -C "$local_repo" merge-base --is-ancestor "$h" "$w"; then
    specs+=("$w:$ref"); echo "   > $ref ${h:0:12}..${w:0:12}"; continue
  fi
  refused+=("$ref"); specs+=("+$w:$ref"); leases+=("--force-with-lease=$ref:$h")
  echo "   ! $ref ${h:0:12} → ${w:0:12} (replace)"
done
for ref in "${!have[@]}"; do
  [ -n "${want[$ref]:-}" ] && continue
  refused+=("$ref"); deletes+=(":$ref"); leases+=("--force-with-lease=$ref:${have[$ref]}")
  echo "   - $ref ${have[$ref]:0:12} (not in the local repository)"
done
if [ ${#specs[@]} -eq 0 ] && [ ${#deletes[@]} -eq 0 ]; then echo "   = in sync (main ${main:0:12}, ${#want[@]} refs)"; exit 0; fi
if [ ${#refused[@]} -gt 0 ] && [ $replace = 0 ]; then
  echo "   refused: ${#refused[@]} ref(s) would be replaced or deleted; --replace does it"; exit 1
fi
if [ $dry = 1 ]; then echo "   [dry-run] nothing pushed"; exit 0; fi

git -C "$local_repo" push -q --atomic "${leases[@]}" "$remote" "${specs[@]}" "${deletes[@]}"
if [ "$(gh api "repos/$owner/$repo" --jq .default_branch)" != main ]; then
  gh api -X PATCH "repos/$owner/$repo" -f default_branch=main --silent
fi

# Read back.
got=$(git ls-remote "$remote" | grep -E $'\trefs/(heads|tags)/' | grep -v '\^{}$' | sort -k2)
exp=$(for ref in "${!want[@]}"; do printf '%s\t%s\n' "${want[$ref]}" "$ref"; done | sort -k2)
if [ "$got" = "$exp" ]; then echo "   ok: GitHub equals the local main and tags (main ${main:0:12}, ${#want[@]} refs)"
else echo "   MISMATCH after push:"; diff <(echo "$exp") <(echo "$got") | sed 's/^/     /'; exit 1; fi
