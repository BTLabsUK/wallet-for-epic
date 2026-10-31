#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `publish-downloads` of tools/rel: uploads the run's release files to the download
# server's downloads/ folder (root-owned 0644, like every release before), rewrites the server's
# SHA256SUMS over every file there, and reads each new file back over HTTPS from both download
# addresses (the old one in app/tool/config/old-update.toml and [updates] downloads of
# app/assets/config/app-config.toml). Touches neither the page nor the manifests. Idempotent.
# SHA256SUMS is signed (SHA256SUMS.sig beside it, minisign, the update key) when the run has a
# signer (<run>/signer.json): the listing the manifests step had signed (manifests/SHA256SUMS,
# the folder as it stands once pruned) is installed when every line of it matches the folder;
# without one (a run without manifests) the folder's listing is signed here, one more approval.
# Without a signer the folder's listing is signed here with the update key's file
# (release-hosts.toml host.signer signing_key, server_sums.py sign-key): SHA256SUMS.sig is
# always served (docs/rebuild-and-compare.md); no key, no upload.
# Usage: publish-downloads.sh <files dir> <ssh host> <server downloads dir>
set -euo pipefail
dir="${1:?usage: $0 <files dir> <ssh host> <server downloads dir>}"; dir="${dir%/}"
host="${2:?}" dest="${3:?}"
src="${REL_SRC:?}"
stage=".rel-dl-stage-${REL_RUN_ID:-run}"
here="$(cd "$(dirname "$0")" && pwd)"
sj="${REL_RUN:-/nonexistent}/signer.json" m="${REL_MANIFESTS:-/nonexistent}"
keyring="${REL_SIGNER_BTLABS_PUBLIC:-$HOME/code/btlabs-public}/keys/btlabs-keyring.json"
key="${REL_SIGNER_SIGNING_KEY:-$HOME/.config/btlabs/signing/btlabs-2026-a.key}"; key="${key/#\~/$HOME}"
if [[ ! -f "$sj" && ! -r "$key" ]]; then
  echo "no signer and no update key at $key: SHA256SUMS would go out unsigned" >&2; exit 1
fi
mapfile -t files < <(cut -d' ' -f3- "$dir/SHA256SUMS")
(( ${#files[@]} > 0 )) || { echo "no files in $dir/SHA256SUMS" >&2; exit 1; }
(cd "$dir" && sha256sum -c --quiet SHA256SUMS)
signed=()
if [[ -f "$sj" && -f "$m/SHA256SUMS.sig" ]]; then
  python3 "$here/server_sums.py" verify "$m/SHA256SUMS" "$m/SHA256SUMS.sig" "$keyring" "$src/tools/gitlab-release.py"
  signed=("$m/SHA256SUMS" "$m/SHA256SUMS.sig")
fi
ssh "$host" "mkdir -p ~/$stage"
rsync -t "${files[@]/#/$dir/}" "${signed[@]}" "$host:$stage/"
# shellcheck disable=SC2029
ssh "$host" "set -e; cd ~/$stage
  sudo install -o root -g root -m 0644 ${files[*]} $dest/
  cd $dest
  ls | grep -vx -e SHA256SUMS -e SHA256SUMS.sig | LC_ALL=C sort | xargs sha256sum | sudo tee SHA256SUMS.new >/dev/null
  sudo chmod 0644 SHA256SUMS.new"
if (( ${#signed[@]} > 0 )); then
  # Every line signed must be the folder's (files of older versions still there until the prune
  # are not in it); then the signed pair replaces the listing.
  # shellcheck disable=SC2029
  ssh "$host" "set -e; cd $dest
    grep -Fxvf SHA256SUMS.new ~/$stage/SHA256SUMS && { echo 'those lines of the signed SHA256SUMS do not match the folder' >&2; exit 1; }
    sudo install -o root -g root -m 0644 ~/$stage/SHA256SUMS.sig SHA256SUMS.sig.new
    sudo install -o root -g root -m 0644 ~/$stage/SHA256SUMS SHA256SUMS.new
    sudo mv SHA256SUMS.new SHA256SUMS && sudo mv SHA256SUMS.sig.new SHA256SUMS.sig
    rm -f ~/$stage/SHA256SUMS ~/$stage/SHA256SUMS.sig"
  echo "SHA256SUMS: the listing signed in the manifests step"
else
  work="${REL_RUN:?}/publish-sums"
  mkdir -p "$work"
  rm -f -- "$work/SHA256SUMS" "$work/SHA256SUMS.sig"
  # shellcheck disable=SC2029
  ssh "$host" "cat $dest/SHA256SUMS.new" >"$work/SHA256SUMS"
  if [[ -f "$sj" ]]; then
    python3 "$here/server_sums.py" sign "$work/SHA256SUMS" "$sj" "${REL_VERSION:?}" "$keyring"
  else
    python3 "$here/server_sums.py" sign-key "$work/SHA256SUMS" "$key" "${REL_VERSION:?}" "$keyring" "$src/tools/gitlab-release.py"
  fi
  python3 "$here/server_sums.py" verify "$work/SHA256SUMS" "$work/SHA256SUMS.sig" "$keyring" "$src/tools/gitlab-release.py"
  rsync -t "$work/SHA256SUMS" "$work/SHA256SUMS.sig" "$host:$stage/"
  # shellcheck disable=SC2029
  ssh "$host" "set -e; cd $dest
    cmp -s SHA256SUMS.new ~/$stage/SHA256SUMS || { echo 'the folder changed while SHA256SUMS was signed' >&2; exit 1; }
    sudo install -o root -g root -m 0644 ~/$stage/SHA256SUMS.sig SHA256SUMS.sig.new
    sudo mv SHA256SUMS.new SHA256SUMS && sudo mv SHA256SUMS.sig.new SHA256SUMS.sig
    rm -f ~/$stage/SHA256SUMS ~/$stage/SHA256SUMS.sig"
  echo "SHA256SUMS: the folder's listing, signed now"
fi
# shellcheck disable=SC2029
ssh "$host" "cd ~/$stage && rm -f ${files[*]} && cd && rmdir ~/$stage"
old="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["old_update"]["downloads"])' \
  "$src/app/tool/config/old-update.toml")"
new="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["updates"]["downloads"])' \
  "$src/app/assets/config/app-config.toml")"
for base in "${old%/}" "${new%/}"; do
  served="$(curl -fsS --max-time 30 "$base/SHA256SUMS")"
  for f in "${files[@]}"; do
    want="$(grep "  $f\$" "$dir/SHA256SUMS" | cut -d' ' -f1)"
    got="$(grep "  $f\$" <<<"$served" | cut -d' ' -f1)"
    [[ -n "$want" && "$want" == "$got" ]] || { echo "$base: SHA256SUMS differs for $f" >&2; exit 1; }
    code="$(curl -sS -o /dev/null -w '%{http_code}' -I --max-time 30 "$base/$f")"
    [[ "$code" == 200 ]] || { echo "$base/$f: HTTP $code" >&2; exit 1; }
  done
  for f in SHA256SUMS.sig provenance.json sbom.cdx.json; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' -I --max-time 30 "$base/$f")"
    [[ "$code" == 200 ]] || { echo "$base/$f: HTTP $code" >&2; exit 1; }
  done
  echo "$base: ${#files[@]} files served with their checksums"
done
