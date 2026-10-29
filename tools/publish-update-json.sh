#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Publishes a signed update.json to every source the apps read (updateManifestSources in
# app/lib/src/updater.dart): BT Labs' download server, the GitLab copy of the GitHub Pages
# repository (read as its raw file on main) and GitHub Pages. The apps check every copy against
# the same keys and use the one with the higher serial, so all must carry the same file. Run it
# once per release, after the release files are on the server.
#
# Usage: tools/publish-update-json.sh <signed update.json>
# Settings (environment, or ~/.config/btlabs/update-publish.env, KEY=VALUE lines):
#   UPDATE_SSH_HOST   ssh host of the download server (required)
#   UPDATE_DEST       its path for the file (default /srv/examples/epic-cash-wallets/update.json, the
#                     release folder: served as https://epiccash.btlabs.uk/api/v1/update.json and, for
#                     installs that read the old address, https://examples.btlabs.uk/epic-cash-wallets/update.json)
#   UPDATE_SITE       checkout of the GitHub Pages repository (default ~/code/btlabs-epic.github.io)
#   UPDATE_KEYRING    keyring to verify against (default ~/code/btlabs-public/keys/btlabs-keyring.json)
#   UPDATE_SIGN_TOOL  btlabs_sign.py (default ~/code/btlabs-public/tool/btlabs_sign.py)
#   UPDATE_GITLAB     GitLab project of the copy (default epic-cash-bt/btlabs-epic.github.io)
#   GITLAB_TOKEN_FILE its write token (default ~/.config/btlabs/gitlab-token; never printed)
# The GitLab copy is the Pages repository's main, cleaned the same way every time (commit
# addresses to the noreply address by tools/publish/mailmap, co-author and generated-with trailers dropped), so each run
# reproduces the published commits and pushes the new one as a fast-forward. Needs git-filter-repo.
set -euo pipefail
file="${1:?usage: $0 <signed update.json>}"
conf="${UPDATE_PUBLISH_CONF:-$HOME/.config/btlabs/update-publish.env}"
# shellcheck disable=SC1090
[[ -f "$conf" ]] && { set -a; . "$conf"; set +a; }
host="${UPDATE_SSH_HOST:?set UPDATE_SSH_HOST (or put it in $conf)}"
dest="${UPDATE_DEST:-/srv/examples/epic-cash-wallets/update.json}"
site="${UPDATE_SITE:-$HOME/code/btlabs-epic.github.io}"
keyring="${UPDATE_KEYRING:-$HOME/code/btlabs-public/keys/btlabs-keyring.json}"
tool="${UPDATE_SIGN_TOOL:-$HOME/code/btlabs-public/tool/btlabs_sign.py}"
gitlab="${UPDATE_GITLAB:-epic-cash-bt/btlabs-epic.github.io}"
token_file="${GITLAB_TOKEN_FILE:-$HOME/.config/btlabs/gitlab-token}"
kit="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/publish"
[[ -r "$token_file" ]] || { echo "no GitLab token at $token_file" >&2; exit 1; }

python3 "$tool" verify --type update --keyring "$keyring" --envelope "$file" >/dev/null \
  || { echo "$file does not verify against $keyring" >&2; exit 1; }
sum="$(sha256sum "$file" | cut -d' ' -f1)"
version="$(jq -r .payload "$file" | base64 -d | jq -r .versionName)"

# 1. The site repository: commit the file (pushed to GitHub last, as GitHub may refuse).
cp "$file" "$site/update.json"
if [[ -n "$(git -C "$site" status --porcelain update.json)" ]]; then
  git -C "$site" add update.json
  git -C "$site" commit -q -m "Epic Cash $version update.json"
fi

# 2. GitLab: the same repository, cleaned, pushed to the copy's main.
export GIT_TERMINAL_PROMPT=0
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
git clone -q --bare --no-local "$site" "$work/pub.git"
git -C "$work/pub.git" filter-repo --force --quiet --mailmap "$kit/mailmap" --message-callback '
import re
keep = [l for l in message.split(b"\n") if not re.match(rb"(?i)(co-authored-by:|.*generated with )", l.strip())]
return b"\n".join(keep).rstrip(b"\n") + b"\n"'
git -C "$work/pub.git" -c credential.helper= \
  -c "credential.helper=!f() { echo username=oauth2; echo \"password=\$(cat '$token_file')\"; }; f" \
  push -q "https://gitlab.com/$gitlab.git" main:main

# 3. The download server: the same bytes beside the download page.
scp -q "$file" "$host:update.json.new"
# shellcheck disable=SC2029  # $dest is meant to expand here
ssh "$host" "sudo install -m 0644 -o root -g root update.json.new '$dest' && rm -f update.json.new"

# 4. GitHub Pages, last: the account may be flagged; the other two sources carry the release then.
github=ok
git -C "$site" push -q || { github=failed; echo "GitHub push failed: the apps use the other sources" >&2; }

# 5. Read every copy back. GitHub Pages can take a few minutes to serve a push; the GitLab copy
# is read through the API while the project is private (its raw URL then answers a sign-in page).
check() {
  local got
  got="$(curl -fsS --max-time 30 "$1" | sha256sum | cut -d' ' -f1)" || { echo "  $1: not reachable"; return 1; }
  if [[ "$got" == "$sum" ]]; then echo "  $1: ok"; else echo "  $1: differs (not served yet?)"; return 1; fi
}
echo "update.json $version ($sum):"
check https://epiccash.btlabs.uk/api/v1/update.json
check https://examples.btlabs.uk/epic-cash-wallets/update.json
raw="https://gitlab.com/$gitlab/-/raw/main/update.json"
if out="$(check "$raw")"; then
  echo "$out"
else
  got="$(curl -fsS --max-time 30 -H @- "https://gitlab.com/api/v4/projects/${gitlab//\//%2F}/repository/files/update.json/raw?ref=main" \
    <<<"PRIVATE-TOKEN: $(cat "$token_file")" | sha256sum | cut -d' ' -f1)" || got=""
  [[ "$got" == "$sum" ]] && echo "  GitLab copy (private, read through the API): ok" \
    || { echo "  GitLab copy: differs or missing"; exit 1; }
fi
if [[ "$github" == ok ]]; then check https://btlabs-epic.github.io/update.json || echo "  (GitHub Pages: check again in a few minutes)"; fi
