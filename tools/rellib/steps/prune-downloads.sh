#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `prune-downloads` of tools/rel, after the manifests are live and read back: every file of
# another version leaves the server's downloads/ (the page keeps no history; old version URLs
# answering 404 is intended), and the server's SHA256SUMS is rewritten. Files the previous
# release's run folder already holds (tools/rel keeps it as the rollback backup) are not copied;
# any other file is copied to <previous dir>/../server-archive first.
# Usage: prune-downloads.sh <version> <ssh host> <server downloads dir> <previous release dir>
set -euo pipefail
v="${1:?usage: $0 <version> <ssh host> <downloads dir> <previous dir>}" host="${2:?}" dest="${3:?}" prev="${4:-}"
mapfile -t old < <(ssh "$host" "ls $dest" | grep -vx SHA256SUMS | grep -v -- "-$v-" || true)
(( ${#old[@]} > 0 )) || { echo "nothing to prune"; exit 0; }
keep="${prev:-.}/../server-archive"
for f in "${old[@]}"; do
  if [[ -n "$prev" && -f "$prev/$f" ]]; then continue; fi
  mkdir -p "$keep"
  rsync -t "$host:$dest/$f" "$keep/$f"
done
# shellcheck disable=SC2029
ssh "$host" "set -e; cd $dest; sudo rm -f -- ${old[*]}
  ls | grep -vx SHA256SUMS | LC_ALL=C sort | xargs sha256sum | sudo tee SHA256SUMS.new >/dev/null
  sudo chmod 0644 SHA256SUMS.new && sudo mv SHA256SUMS.new SHA256SUMS"
echo "pruned ${#old[@]} file(s): ${old[*]}"
