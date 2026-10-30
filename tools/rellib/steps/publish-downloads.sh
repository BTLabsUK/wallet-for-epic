#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `publish-downloads` of tools/rel: uploads the run's release files to the download
# server's downloads/ folder (root-owned 0644, like every release before), rewrites the server's
# SHA256SUMS over every file there, and reads each new file back over HTTPS from both download
# addresses (the old one in app/tool/config/old-update.toml and [updates] downloads of
# app/assets/config/app-config.toml). Touches neither the page nor the manifests. Idempotent.
# Usage: publish-downloads.sh <files dir> <ssh host> <server downloads dir>
set -euo pipefail
dir="${1:?usage: $0 <files dir> <ssh host> <server downloads dir>}"; dir="${dir%/}"
host="${2:?}" dest="${3:?}"
src="${REL_SRC:?}"
stage=".rel-dl-stage-${REL_RUN_ID:-run}"
mapfile -t files < <(cut -d' ' -f3- "$dir/SHA256SUMS")
(( ${#files[@]} > 0 )) || { echo "no files in $dir/SHA256SUMS" >&2; exit 1; }
(cd "$dir" && sha256sum -c --quiet SHA256SUMS)
ssh "$host" "mkdir -p ~/$stage"
rsync -t "${files[@]/#/$dir/}" "$host:$stage/"
# shellcheck disable=SC2029
ssh "$host" "set -e; cd ~/$stage
  sudo install -o root -g root -m 0644 ${files[*]} $dest/
  cd $dest
  ls | grep -vx SHA256SUMS | LC_ALL=C sort | xargs sha256sum | sudo tee SHA256SUMS.new >/dev/null
  sudo chmod 0644 SHA256SUMS.new && sudo mv SHA256SUMS.new SHA256SUMS
  cd ~/$stage && rm -f ${files[*]} && cd && rmdir ~/$stage"
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
  echo "$base: ${#files[@]} files served with their checksums"
done
