#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Publishes a signed update.json to every source the apps read (updateManifestSources in
# app/lib/src/updater.dart): the GitHub Pages repository and BT Labs' download server. The apps
# check every copy against the same keys and use the one with the higher serial, so both must
# carry the same file. Run it once per release, after the release files are on the server.
#
# Usage: tools/publish-update-json.sh <signed update.json>
# Settings (environment, or ~/.config/btlabs/update-publish.env, KEY=VALUE lines):
#   UPDATE_SSH_HOST   ssh host of the download server (required)
#   UPDATE_DEST       its path for the file (default /srv/examples/epic-cash-wallets/update.json)
#   UPDATE_SITE       checkout of the GitHub Pages repository (default ~/code/btlabs-epic.github.io)
#   UPDATE_KEYRING    keyring to verify against (default ~/code/btlabs-public/keys/btlabs-keyring.json)
#   UPDATE_SIGN_TOOL  btlabs_sign.py (default ~/code/btlabs-public/tool/btlabs_sign.py)
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

python3 "$tool" verify --type update --keyring "$keyring" --envelope "$file" >/dev/null \
  || { echo "$file does not verify against $keyring" >&2; exit 1; }
sum="$(sha256sum "$file" | cut -d' ' -f1)"
version="$(jq -r .payload "$file" | base64 -d | jq -r .versionName)"

# 1. GitHub Pages: commit and push the file in the site repository.
cp "$file" "$site/update.json"
if [[ -n "$(git -C "$site" status --porcelain update.json)" ]]; then
  git -C "$site" add update.json
  git -C "$site" commit -q -m "Epic Cash $version update.json"
fi
git -C "$site" push -q

# 2. The download server: the same bytes beside the download page.
scp -q "$file" "$host:update.json.new"
# shellcheck disable=SC2029  # $dest is meant to expand here
ssh "$host" "sudo install -m 0644 -o root -g root update.json.new '$dest' && rm -f update.json.new"

# 3. Read both back from outside. GitHub Pages can take a few minutes to serve a push.
check() {
  local got
  got="$(curl -fsS --max-time 30 "$1" | sha256sum | cut -d' ' -f1)" || { echo "  $1: not reachable"; return 1; }
  if [[ "$got" == "$sum" ]]; then echo "  $1: ok"; else echo "  $1: differs (not served yet?)"; return 1; fi
}
echo "update.json $version ($sum):"
check https://examples.btlabs.uk/epic-cash-wallets/update.json
check https://btlabs-epic.github.io/update.json || echo "  (GitHub Pages: check again in a few minutes)"
