#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `prune-downloads` of tools/rel, after the manifests are live and read back: every file of
# another version leaves the server's downloads/ (the page keeps no history; old version URLs
# answering 404 is intended), and the server's SHA256SUMS is rewritten. Files the previous
# release's run folder already holds (tools/rel keeps it as the rollback backup) are not copied;
# any other file is copied to <previous dir>/../server-archive first.
# A file the new manifests still name stays (a desktop system this release left out keeps the
# previous release's installer: manifests/desktop-keep.json). SHA256SUMS.sig, provenance.json and
# sbom.cdx.json stay too (no version in their names; they are the release's). A signed listing
# (SHA256SUMS.sig, publish-downloads) is left alone when the pruned folder is what it signed; when
# the folder came out otherwise and the run has a signer (<run>/signer.json), the new listing is
# signed (one more approval); without a signer it is signed with the update key's file
# (server_sums.py sign-key), as publish-downloads does.
# Usage: prune-downloads.sh <version> <ssh host> <server downloads dir> <previous release dir> [<manifests dir>]
set -euo pipefail
v="${1:?usage: $0 <version> <ssh host> <downloads dir> <previous dir> [<manifests dir>]}" host="${2:?}" dest="${3:?}" prev="${4:-}" mdir="${5:-}"
named=""
if [[ -n "$mdir" && -f "$mdir/update.payload.json" ]]; then
  named="$(jq -r '.. | objects | .url? // empty | split("/") | last' "$mdir/update.payload.json" | sort -u)"
fi
mapfile -t old < <(ssh "$host" "ls $dest" | grep -vx -e SHA256SUMS -e SHA256SUMS.sig -e provenance.json -e sbom.cdx.json \
  | grep -v -- "-$v-" | grep -vxF -f <(printf '%s\n' "$named") || true)
(( ${#old[@]} > 0 )) || { echo "nothing to prune"; exit 0; }
keep="${prev:-.}/../server-archive"
for f in "${old[@]}"; do
  if [[ -n "$prev" && -f "$prev/$f" ]]; then continue; fi
  mkdir -p "$keep"
  rsync -t "$host:$dest/$f" "$keep/$f"
done
# shellcheck disable=SC2029
ssh "$host" "set -e; cd $dest; sudo rm -f -- ${old[*]}
  ls | grep -vx -e SHA256SUMS -e SHA256SUMS.sig | LC_ALL=C sort | xargs sha256sum | sudo tee SHA256SUMS.new >/dev/null
  sudo chmod 0644 SHA256SUMS.new"
echo "pruned ${#old[@]} file(s): ${old[*]}"
sj="${REL_RUN:-/nonexistent}/signer.json"
# shellcheck disable=SC2029
if ssh "$host" "cd $dest && test -f SHA256SUMS.sig && cmp -s SHA256SUMS.new SHA256SUMS"; then
  ssh "$host" "sudo rm -f $dest/SHA256SUMS.new"
  echo "SHA256SUMS: the signed listing is the pruned folder's"
else
  here="$(cd "$(dirname "$0")" && pwd)"
  keyring="${REL_SIGNER_BTLABS_PUBLIC:-$HOME/code/btlabs-public}/keys/btlabs-keyring.json"
  work="${REL_RUN:?}/prune-sums" stage=".rel-prune-stage-${REL_RUN_ID:-run}"
  mkdir -p "$work"
  rm -f -- "$work/SHA256SUMS" "$work/SHA256SUMS.sig"
  # shellcheck disable=SC2029
  ssh "$host" "cat $dest/SHA256SUMS.new" >"$work/SHA256SUMS"
  if [[ -f "$sj" ]]; then
    python3 "$here/server_sums.py" sign "$work/SHA256SUMS" "$sj" "$v" "$keyring"
  else
    key="${REL_SIGNER_SIGNING_KEY:-$HOME/.config/btlabs/signing/btlabs-2026-a.key}"
    python3 "$here/server_sums.py" sign-key "$work/SHA256SUMS" "${key/#\~/$HOME}" "$v" "$keyring" "${REL_SRC:?}/tools/release-files.py"
  fi
  python3 "$here/server_sums.py" verify "$work/SHA256SUMS" "$work/SHA256SUMS.sig" "$keyring" "${REL_SRC:?}/tools/release-files.py"
  ssh "$host" "mkdir -p ~/$stage"
  rsync -t "$work/SHA256SUMS" "$work/SHA256SUMS.sig" "$host:$stage/"
  # shellcheck disable=SC2029
  ssh "$host" "set -e; cd $dest
    cmp -s SHA256SUMS.new ~/$stage/SHA256SUMS || { echo 'the folder changed while SHA256SUMS was signed' >&2; exit 1; }
    sudo install -o root -g root -m 0644 ~/$stage/SHA256SUMS.sig SHA256SUMS.sig.new
    sudo mv SHA256SUMS.new SHA256SUMS && sudo mv SHA256SUMS.sig.new SHA256SUMS.sig
    rm -f ~/$stage/SHA256SUMS ~/$stage/SHA256SUMS.sig && rmdir ~/$stage"
  echo "SHA256SUMS: the pruned folder's listing, signed now"
fi
