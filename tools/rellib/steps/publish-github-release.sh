#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `publish-github-release` of tools/rel (release.toml publish.github): the GitHub Release of
# tag v<version> on BTLabsUK/wallet-for-epic, with the files publish-downloads put on the server
# (the run's SHA256SUMS lists them) as assets, through tools/release-files.py. It works on a
# copy in the stage folder: release-files.py writes its own SHA256SUMS and SHA256SUMS.sig there,
# and the run's SHA256SUMS stays as G6 reads it. The tag is on GitHub from publish-source.
# Usage: publish-github-release.sh <version> <files dir> <stage dir>
# Settings: GITHUB_RELEASE_REPO (default BTLabsUK/wallet-for-epic); REL_SIGNER_SIGNING_KEY and
# REL_SIGNER_BTLABS_PUBLIC (release-hosts.toml host.signer) for the key that signs SHA256SUMS.
set -euo pipefail
v="${1:?usage: $0 <version> <files dir> <stage dir>}" dir="${2:?}" stage="${3:?}"
dir="${dir%/}"
src="${REL_SRC:?}"
repo="${GITHUB_RELEASE_REPO:-BTLabsUK/wallet-for-epic}"
key="${REL_SIGNER_SIGNING_KEY:-$HOME/.config/btlabs/signing/btlabs-2026-a.key}"
keyring="${REL_SIGNER_BTLABS_PUBLIC:-$HOME/code/btlabs-public}/keys/btlabs-keyring.json"
mapfile -t files < <(cut -d' ' -f3- "$dir/SHA256SUMS")
(( ${#files[@]} > 0 )) || { echo "no files in $dir/SHA256SUMS" >&2; exit 1; }
(cd "$dir" && sha256sum -c --quiet SHA256SUMS)
out="$stage/github"
rm -rf "$out" && mkdir -p "$out"
for f in "${files[@]}"; do
  ln "$dir/$f" "$out/$f" 2>/dev/null || cp -p "$dir/$f" "$out/$f"
done
# The release notes: the release source's fastlane changelog of the version, else the run's
# update notes, else one line. release-files.py is the runner's (like this script), so a tool fix
# reaches a release whose source is older.
IFS=. read -r y m p <<<"${v%%-*}"
changelog="$src/fastlane/metadata/android/en-US/changelogs/$(printf '%02d%02d%02d00' "$((10#$y))" "$((10#$m))" "$((10#$p))").txt"
notes=()
if [[ -s "$changelog" ]]; then
  notes=(--notes "$changelog")
else
  if [[ -s "${REL_NOTES_FILE:-}" ]]; then
    notes=(--notes "$REL_NOTES_FILE")
  else
    echo "Epic Cash $v." >"$stage/github-notes.txt"
    notes=(--notes "$stage/github-notes.txt")
  fi
fi
# A follow-up run (REL_FOLLOW_UP=1) adds files to the published release: the listing assets
# (SHA256SUMS, its signature, provenance.json, the SBOM) change, every other asset keeps its bytes.
listing=()
[[ "${REL_FOLLOW_UP:-0}" == 1 ]] && listing=(--replace-listing)
python3 "$(cd "$(dirname "$0")/../.." && pwd)/release-files.py" publish "$v" "$out" --github-repo "$repo" \
  --key "$key" --keyring "$keyring" "${notes[@]}" "${listing[@]}"
