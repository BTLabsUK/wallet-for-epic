#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Publishes the release's two signed manifests to every source the apps read, once per release,
# after the release files are on the server (https://docs.btlabs.uk/developers/releases/, Release addresses):
#   update.json     the old format, for installed apps up to 26.10.23 (file URLs under the old
#                   download address): BT Labs' download server, and update.json in the Pages
#                   repository (its GitLab copy, read as the raw file on main);
#   update-v2.json  the new format, the only one the current app reads ([updates] manifests of
#                   app/assets/config/app-config.toml): the server's API file, update-v2.json
#                   in the same Pages repository, and with GITHUB_UPDATE_JSON=1 the asset
#                   update-v2.json of the latest GitHub Release (a mirror; never a gate).
# Both name the same release and serial (tool/release_android.sh writes and signs both), so every
# old version still updates to the newest. The apps check every copy against the same keys and
# use the one with the higher serial. The old format can be retired once no install older than
# the first release with update-v2.json remains.
#
# Usage: tools/publish-update-json.sh <signed update.json> <signed update-v2.json>
# Settings (environment, or ~/.config/btlabs/update-publish.env, KEY=VALUE lines):
#   UPDATE_SSH_HOST   ssh host of the download server (required)
#   UPDATE_DEST       its path for update.json (default /srv/examples/epic-cash-wallets/update.json)
#   UPDATE_DEST_V2    its path for update-v2.json (default /srv/epiccash-api/v1/update.json)
#   UPDATE_URL        where the server serves update.json (default the old download address)
#   UPDATE_URL_V2     where it serves update-v2.json (default the first [updates] manifest)
#   UPDATE_SITE       checkout of the Pages repository (default ~/code/btlabs-epic.github.io)
#   UPDATE_KEYRING    keyring to verify against (default ~/code/btlabs-public/keys/btlabs-keyring.json)
#   UPDATE_SIGN_TOOL  btlabs_sign.py (default ~/code/btlabs-public/tool/btlabs_sign.py)
#   UPDATE_GITLAB     GitLab project of the copy (default epic-cash-bt/btlabs-epic.github.io)
#   GITLAB_TOKEN_FILE its write token (default ~/.config/btlabs/gitlab-token; never printed)
#   GITHUB_UPDATE_JSON 1: also put update-v2.json on the latest GitHub Release (release.toml
#                     publish.github sets it; default 0). Through tools/gitlab-release.py
#                     github-update-json, gh logged in as btlabs-uk in GH_CONFIG_DIR
#                     (default ~/.config/gh-btlabs). A GitHub failure is a warning only.
#   GITHUB_RELEASE_REPO its repository (default BTLabsUK/wallet-for-epic)
#   GITHUB_MIRROR_SITE 1: also copy the Pages repository's GitLab main to its GitHub mirror
#                     (tools/mirror-github.sh btlabs-epic.github.io; default GITHUB_UPDATE_JSON).
#                     A failure is a warning only.
#   GITHUB_UPDATE_URL  where GitHub serves it (default .../releases/latest/download/update-v2.json)
# The GitLab copy is the Pages repository's main, cleaned the same way every time (commit
# addresses to the noreply address by tools/publish/mailmap, co-author and generated-with trailers dropped), so each run
# reproduces the published commits and pushes the new one as a fast-forward. Needs git-filter-repo.
set -euo pipefail
file="${1:?usage: $0 <signed update.json> <signed update-v2.json>}"
file2="${2:?usage: $0 <signed update.json> <signed update-v2.json>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
conf="${UPDATE_PUBLISH_CONF:-$HOME/.config/btlabs/update-publish.env}"
# shellcheck disable=SC1090
[[ -f "$conf" ]] && { set -a; . "$conf"; set +a; }
host="${UPDATE_SSH_HOST:?set UPDATE_SSH_HOST (or put it in $conf)}"
dest="${UPDATE_DEST:-/srv/examples/epic-cash-wallets/update.json}"
dest2="${UPDATE_DEST_V2:-/srv/epiccash-api/v1/update.json}"
url="${UPDATE_URL:-https://examples.btlabs.uk/epic-cash-wallets/update.json}"
# The new manifest's own address is the app's first source: read from the app's config.
url2="${UPDATE_URL_V2:-$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["updates"]["manifests"][0])' \
  "$root/app/assets/config/app-config.toml")}"
site="${UPDATE_SITE:-$HOME/code/btlabs-epic.github.io}"
keyring="${UPDATE_KEYRING:-$HOME/code/btlabs-public/keys/btlabs-keyring.json}"
tool="${UPDATE_SIGN_TOOL:-$HOME/code/btlabs-public/tool/btlabs_sign.py}"
gitlab="${UPDATE_GITLAB:-epic-cash-bt/btlabs-epic.github.io}"
token_file="${GITLAB_TOKEN_FILE:-$HOME/.config/btlabs/gitlab-token}"
kit="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/publish"
gh_repo="${GITHUB_RELEASE_REPO:-BTLabsUK/wallet-for-epic}"
gh_url="${GITHUB_UPDATE_URL:-https://github.com/$gh_repo/releases/latest/download/update-v2.json}"
[[ -r "$token_file" ]] || { echo "no GitLab token at $token_file" >&2; exit 1; }

# update-v2.json's file URLs are checked against [updates] of the app's app-config.toml, as the
# app checks them; update.json's against the tool's old download folder.
python3 "$tool" verify --type update --keyring "$keyring" --envelope "$file" >/dev/null \
  || { echo "$file does not verify against $keyring" >&2; exit 1; }
python3 "$tool" verify --type update --app-config "$root/app/assets/config/app-config.toml" --keyring "$keyring" \
  --envelope "$file2" >/dev/null || { echo "$file2 does not verify against $keyring" >&2; exit 1; }
sum="$(sha256sum "$file" | cut -d' ' -f1)"
sum2="$(sha256sum "$file2" | cut -d' ' -f1)"
version="$(jq -r .payload "$file" | base64 -d | jq -r .versionName)"
for k in versionName serial; do
  [[ "$(jq -r .payload "$file" | base64 -d | jq -r ".$k")" == "$(jq -r .payload "$file2" | base64 -d | jq -r ".$k")" ]] \
    || { echo "$file and $file2 name different releases ($k)" >&2; exit 1; }
done

# 1. The site repository: commit both files.
cp "$file" "$site/update.json"
cp "$file2" "$site/update-v2.json"
if [[ -n "$(git -C "$site" status --porcelain update.json update-v2.json)" ]]; then
  git -C "$site" add update.json update-v2.json
  git -C "$site" commit -q -m "Epic Cash $version update.json and update-v2.json"
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

# 3. The download server: the old format beside the download page, the new one at its API file.
scp -q "$file" "$host:update.json.new"
scp -q "$file2" "$host:update-v2.json.new"
# shellcheck disable=SC2029  # $dest and $dest2 are meant to expand here
ssh "$host" "sudo install -m 0644 -o root -g root update.json.new '$dest' && rm -f update.json.new \
  && sudo install -m 0644 -o root -g root -D update-v2.json.new '$dest2' && rm -f update-v2.json.new"

# 4. GitHub, last and only when switched on: update-v2.json onto the latest GitHub Release (a
# mirror: when it fails, the apps use the other sources).
github=off
if [[ "${GITHUB_UPDATE_JSON:-0}" == 1 ]]; then
  github=ok
  python3 "$root/tools/gitlab-release.py" github-update-json "$file2" --github-repo "$gh_repo" \
    || { github=failed; echo "warning: update-v2.json not on the GitHub release: the apps use the other sources" >&2; }
fi
if [[ "${GITHUB_MIRROR_SITE:-${GITHUB_UPDATE_JSON:-0}}" == 1 ]]; then
  GITLAB_TOKEN_FILE="$token_file" "$root/tools/mirror-github.sh" "${gitlab##*/}" \
    || echo "warning: the GitHub mirror of ${gitlab##*/} is behind GitLab (re-run tools/mirror-github.sh)" >&2
fi

# 5. Read every copy back. The GitLab copy is read through the API while the project is private
# (its raw URL then answers a sign-in page). GitHub's latest/download link redirects to the file.
check() { # <url> <sha256>
  local got
  got="$(curl -fsSL --max-time 30 "$1" | sha256sum | cut -d' ' -f1)" || { echo "  $1: not reachable"; return 1; }
  if [[ "$got" == "$2" ]]; then echo "  $1: ok"; else echo "  $1: differs (not served yet?)"; return 1; fi
}
check_gitlab() { # <file name> <sha256>
  local out got
  if out="$(check "https://gitlab.com/$gitlab/-/raw/main/$1" "$2")"; then echo "$out"; return; fi
  got="$(curl -fsS --max-time 30 -H @- "https://gitlab.com/api/v4/projects/${gitlab//\//%2F}/repository/files/$1/raw?ref=main" \
    <<<"PRIVATE-TOKEN: $(cat "$token_file")" | sha256sum | cut -d' ' -f1)" || got=""
  [[ "$got" == "$2" ]] && echo "  GitLab copy of $1 (private, read through the API): ok" \
    || { echo "  GitLab copy of $1: differs or missing"; exit 1; }
}
echo "update.json $version ($sum):"
check "$url" "$sum"
check_gitlab update.json "$sum"
echo "update-v2.json $version ($sum2):"
check "$url2" "$sum2"
check_gitlab update-v2.json "$sum2"
if [[ "$github" == ok ]]; then check "$gh_url" "$sum2" || echo "  warning: GitHub does not serve it yet (a mirror, not a gate)"; fi
if [[ "$github" == failed ]]; then echo "  warning: GitHub copy not published (see above)"; fi
