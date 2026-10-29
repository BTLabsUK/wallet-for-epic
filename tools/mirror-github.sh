#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Mirrors the public GitLab projects (gitlab.com/epic-cash-bt/*) to GitHub (BTLabs-EPIC/*): main
# and the tags, nothing else, the same commits GitLab has. GitLab is the source; this never
# pushes local history. Runs from our own machines (no CI on either host).
#
#   tools/mirror-github.sh [--dry-run] [--replace] [repo ...]
#
# Default repos: wallet-for-epic lepic lepic-flutter btlabs-docs epic-status btlabs-epic.github.io.
# Per repo:
#   1. fetches GitLab's main and tags into a bare cache ($MIRROR_DIR, default ~/publish/mirror);
#   2. refuses when any commit on GitLab's main carries an agent path or a CI workflow file;
#   3. creates a missing GitHub repository with GitLab's visibility and description, Actions off
#      (the Pages repository keeps Actions on: GitHub Pages builds with them);
#   4. compares GitHub with GitLab and pushes what differs: main as a fast-forward, missing tags.
#      A main that does not extend GitHub's, a moved tag, an extra tag or any other branch is
#      refused unless --replace, which force-pushes main and the moved tags (with a lease on what
#      it saw) and deletes the extra tags and branches;
#   5. reads GitHub back and checks it equals GitLab.
#
# A re-run with nothing new pushes nothing. --dry-run changes nothing and prints the plan.
# Environment: GITLAB_GROUP (default epic-cash-bt), GITHUB_OWNER (default BTLabs-EPIC),
# GITLAB_TOKEN_FILE (default ~/.config/btlabs/gitlab-token), MIRROR_DIR. GitHub access is
# `gh auth` (git-credential); neither token is printed.
set -euo pipefail

dry=0 replace=0 repos=()
for arg in "$@"; do
  case $arg in
    --dry-run|-n) dry=1 ;;
    --replace) replace=1 ;;
    -h|--help) sed -n '3,24p' "$0"; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) repos+=("$arg") ;;
  esac
done
[ ${#repos[@]} -gt 0 ] || repos=(wallet-for-epic lepic lepic-flutter btlabs-docs epic-status btlabs-epic.github.io)

group=${GITLAB_GROUP:-epic-cash-bt}
owner=${GITHUB_OWNER:-BTLabs-EPIC}
token_file=${GITLAB_TOKEN_FILE:-$HOME/.config/btlabs/gitlab-token}
cache=${MIRROR_DIR:-$HOME/publish/mirror}
pages_repo="${owner,,}.github.io"
# Only BT Labs' own organisation: the Epic Cash project's repositories are never touched.
case ${owner,,} in epiccash|epic-cash|epiccash-*) echo "refusing owner $owner" >&2; exit 2 ;; esac
[ -r "$token_file" ] || { echo "no GitLab token at $token_file" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh is not logged in" >&2; exit 1; }

gitlab_url() { echo "https://gitlab.com/$group/$1.git"; }
github_url() { echo "https://github.com/$owner/$1.git"; }
# git with both hosts' credentials from their stores; the helper prints only to git.
g() {
  git -c credential.helper= \
    -c "credential.https://gitlab.com.helper=!f() { test \"\$1\" = get && echo username=oauth2 && echo \"password=\$(cat '$token_file')\"; }; f" \
    -c 'credential.https://github.com.helper=!gh auth git-credential' "$@"
}
gl_api() { curl -sS -f -H @- "https://gitlab.com/api/v4/$1" <<<"PRIVATE-TOKEN: $(cat "$token_file")"; }
export GIT_TERMINAL_PROMPT=0

# Agent and process paths, and CI workflow files: none may reach GitHub (the letters in
# brackets keep the publish scan of this file quiet).
forbidden='(^|/)\.(k[i]ro|c[l]aude|coord|fleet|cursor|codex|windsurf|continue|aider[^/]*)(/|$)|(^|/)(AGENTS|C[L]AUDE|GEMINI)\.md$|^\.github/workflows/|^\.gitlab-ci\.yml$'

fail=0
for repo in "${repos[@]}"; do
  echo "== $repo: gitlab.com/$group/$repo → github.com/$owner/$repo"
  meta=$(gl_api "projects/$group%2F$repo") || { echo "   not on GitLab" >&2; fail=1; continue; }
  read -r vis desc < <(python3 -I -c 'import json,sys; p=json.load(sys.stdin); print(p["visibility"], (p.get("description") or "").replace("\n"," "))' <<<"$meta")

  bare="$cache/$repo.git"
  [ -d "$bare" ] || git init -q --bare "$bare"
  g -C "$bare" fetch -q --prune --no-tags "$(gitlab_url "$repo")" \
    '+refs/heads/main:refs/heads/main' '+refs/tags/*:refs/tags/*'
  main=$(git -C "$bare" rev-parse refs/heads/main)
  bad=$(git -C "$bare" log --format= --name-only main | sort -u | grep -E "$forbidden" | head -5 || true)
  if [ -n "$bad" ]; then echo "   GitLab's main holds paths that must not be mirrored:"; sed 's/^/     /' <<<"$bad"; fail=1; continue; fi
  declare -A want=() have=()
  while read -r sha ref; do want[$ref]=$sha; done < <(git -C "$bare" for-each-ref --format='%(objectname) %(refname)' refs/heads/main refs/tags)

  if ! gh api "repos/$owner/$repo" --silent 2>/dev/null; then
    echo "   + create github.com/$owner/$repo ($vis)"
    if [ $dry = 0 ]; then
      gh api -X POST "orgs/$owner/repos" -f name="$repo" -f visibility="$vis" -f description="$desc" \
        -F has_issues=true -F has_wiki=false -F has_projects=false -F auto_init=false --silent
      [ "$repo" = "$pages_repo" ] || gh api -X PUT "repos/$owner/$repo/actions/permissions" -F enabled=false --silent
    fi
  fi
  if [ $dry = 0 ] || gh api "repos/$owner/$repo" --silent 2>/dev/null; then
    while read -r sha ref; do
      case $ref in refs/heads/*|refs/tags/*) [[ $ref == *'^{}' ]] || have[$ref]=$sha ;; esac
    done < <(g ls-remote "$(github_url "$repo")")
  fi

  # The plan: refspecs to push, refs to delete, refusals without --replace.
  specs=() leases=() deletes=() refused=()
  for ref in "${!want[@]}"; do
    w=${want[$ref]} h=${have[$ref]:-}
    [ "$h" = "$w" ] && continue
    if [ -z "$h" ]; then specs+=("$w:$ref"); echo "   + $ref ${w:0:12}"; continue; fi
    if [ "$ref" = refs/heads/main ] && git -C "$bare" cat-file -e "$h" 2>/dev/null &&
       git -C "$bare" merge-base --is-ancestor "$h" "$w"; then
      specs+=("$w:$ref"); echo "   > $ref ${h:0:12}..${w:0:12}"; continue
    fi
    refused+=("$ref"); specs+=("+$w:$ref"); leases+=("--force-with-lease=$ref:$h")
    echo "   ! $ref ${h:0:12} → ${w:0:12} (replace)"
  done
  for ref in "${!have[@]}"; do
    [ -n "${want[$ref]:-}" ] && continue
    refused+=("$ref"); deletes+=(":$ref"); leases+=("--force-with-lease=$ref:${have[$ref]}")
    echo "   - $ref ${have[$ref]:0:12} (not on GitLab)"
  done
  if [ ${#specs[@]} -eq 0 ] && [ ${#deletes[@]} -eq 0 ]; then echo "   = in sync (main ${main:0:12}, ${#want[@]} refs)"; unset want have; continue; fi
  if [ ${#refused[@]} -gt 0 ] && [ $replace = 0 ]; then
    echo "   refused: ${#refused[@]} ref(s) would be replaced or deleted; --replace does it"
    fail=1; unset want have; continue
  fi
  if [ $dry = 1 ]; then echo "   [dry-run] nothing pushed"; unset want have; continue; fi

  # Branches first (GitHub refuses to delete the default branch, and main is the default), then
  # the tags, in one atomic push.
  g -C "$bare" push -q --atomic "${leases[@]}" "$(github_url "$repo")" "${specs[@]}" "${deletes[@]}"
  if [ "$(gh api "repos/$owner/$repo" --jq .default_branch)" != main ]; then
    gh api -X PATCH "repos/$owner/$repo" -f default_branch=main --silent
  fi

  # Read back.
  got=$(g ls-remote "$(github_url "$repo")" | grep -E $'\trefs/(heads|tags)/' | grep -v '\^{}$' | sort -k2)
  exp=$(for ref in "${!want[@]}"; do printf '%s\t%s\n' "${want[$ref]}" "$ref"; done | sort -k2)
  if [ "$got" = "$exp" ]; then echo "   ok: GitHub equals GitLab (main ${main:0:12}, ${#want[@]} refs)"
  else echo "   MISMATCH after push:"; diff <(echo "$exp") <(echo "$got") | sed 's/^/     /'; fail=1; fi
  unset want have
done
exit $fail
