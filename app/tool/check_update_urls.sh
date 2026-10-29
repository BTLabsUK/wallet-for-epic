#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Fails when a file URL of an update payload is not a plain file name under its download folder:
# every `url` anywhere in it (apks, notor.apks, desktop and notor.desktop files). Apps reject the
# whole manifest otherwise, so tool/release_android.sh runs this before signing either one.
# Usage: tool/check_update_urls.sh <payload.json> <download-folder-url>
set -euo pipefail

if [[ $# -ne 2 ]]; then
  sed -n '6p' "${BASH_SOURCE[0]}" >&2
  exit 64
fi
payload="$1"
base="${2%/}/"
bad="$(jq -r --arg base "$base" '
  [.. | objects | select(has("url")) | .url]
  | if length == 0 then ["(no file URLs)"] else . end
  | map(select(type != "string" or (startswith($base) | not)
               or ((.[($base | length):]) | test("^[A-Za-z0-9][A-Za-z0-9._-]*$") | not)))
  | .[] | tostring' "$payload")"
if [[ -n "$bad" ]]; then
  echo "$payload: file URLs not under $base:" >&2
  sed 's/^/  /' <<<"$bad" >&2
  exit 1
fi
echo "ok   $payload: every file URL under $base"
