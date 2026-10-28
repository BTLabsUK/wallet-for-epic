#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Uploads the Play App Bundle of the version in pubspec.yaml to a Google Play testing track
# (https://docs.btlabs.uk/developers/build/variants/, "Google Play"). Production stays a click in Play Console.
#   tools/play-upload.sh <aab> [--track internal] [--notes-file <file>] [--validate]
# The release name is "<version> (<versionCode>)" from tools/version.sh; the notes default to
# play-notes/<version>.txt under docs (en-GB) when it exists. The service account key is
# WFE_PLAY_KEY (default ~/.config/btlabs/play/service-account.json, never in a repository).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
aab="${1:?usage: tools/play-upload.sh <aab> [--track T] [--notes-file F] [--validate]}"; shift
key="${WFE_PLAY_KEY:-$HOME/.config/btlabs/play/service-account.json}"
[[ -r "$key" ]] || { echo "no Play service account key at $key" >&2; exit 1; }
[[ -f "$aab" && "$aab" == *.aab ]] || { echo "$aab: not an App Bundle" >&2; exit 1; }
version="$("$root/tools/version.sh" name)"
code="$("$root/tools/version.sh" code)"
args=()
notes="$root/docs/play-notes/$version.txt"
[[ " $* " == *" --notes-file "* || ! -f "$notes" ]] || args+=(--notes-file "$notes")
exec python3 -I "$root/tools/play_upload.py" --key "$key" --package uk.btlabs.epiccash.mobile \
  --aab "$aab" --name "$version ($code)" "${args[@]}" "$@"
