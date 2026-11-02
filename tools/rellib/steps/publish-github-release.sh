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
# The release notes: the fastlane changelog of the version (release-files.py's default), else
# the run's update notes, else one line.
IFS=. read -r y m p <<<"${v%%-*}"
notes=()
if [[ ! -s "$src/fastlane/metadata/android/en-US/changelogs/$(printf '%02d%02d%02d00' "$((10#$y))" "$((10#$m))" "$((10#$p))").txt" ]]; then
  if [[ -s "${REL_NOTES_FILE:-}" ]]; then
    notes=(--notes "$REL_NOTES_FILE")
  else
    echo "Epic Cash $v." >"$stage/github-notes.txt"
    notes=(--notes "$stage/github-notes.txt")
  fi
fi
python3 "$src/tools/release-files.py" publish "$v" "$out" --github-repo "$repo" \
  --key "$key" --keyring "$keyring" "${notes[@]}"
