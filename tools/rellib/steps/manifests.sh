#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Step `manifests` of tools/rel: writes and signs the release's two update manifests from this
# run's files with app/tool/release_android.sh (WFE_APK_DIR + WFE_DESKTOP_DIR = the run's files/,
# the old format's download folder from app/tool/config/old-update.toml, the notes from the
# run), and keeps them with their payloads in the run's manifests/ (tools/rel rollback re-signs
# those payloads with a higher serial).
# A TEST run (REL_TEST=1) never touches the real key: release_android.sh is pointed at a key that
# does not exist, so it stops after writing the payloads, and the payloads are signed with
# btlabs-public's test key against a test keyring kept in the run (manifests/test-keyring.json).
# With a signer (<run>/signer.json, written by G1 when [host.signer] endpoint is set) the release
# signer signs both manifests and the downloads folder's SHA256SUMS as it will stand once live
# (server_sums.py: manifests/SHA256SUMS and SHA256SUMS.sig, installed by publish-downloads), in
# one go: the follow-up sign-android's request declared (<run>/signer-continue.json), signed on
# that request's code, so a release needs one code (docs/RELEASING.md, "Signer"). When that
# request no longer waits (expired, a retry, a run that signed Android elsewhere) the client asks
# with a new request and code, as before. A retry after the signer had answered takes the
# manifests it returned again when nothing they were made from changed (the client's receipt,
# server_sums.py same), and opens no request. The key on this machine is not read.
# The manifests are valid for REL_MANIFEST_DAYS days (release/pipeline.toml [manifest]).
# Env (set by tools/rel): REL_VERSION REL_SRC REL_FILES REL_MANIFESTS REL_NOTES_FILE REL_TEST REL_RUN
#   REL_MANIFEST_DAYS
#   REL_SIGNER_BTLABS_PUBLIC REL_SIGNER_SIGNING_KEY (release-hosts.toml host.signer)
set -euo pipefail
src="${REL_SRC:?}" files="${REL_FILES:?}" m="${REL_MANIFESTS:?}"
bp="${REL_SIGNER_BTLABS_PUBLIC:-$HOME/code/btlabs-public}"
base="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["old_update"]["downloads"])' \
  "$src/app/tool/config/old-update.toml")"
notes="$(cat "${REL_NOTES_FILE:-/dev/null}" 2>/dev/null || true)"
out="$src/app/build/app/outputs/flutter-apk"
mkdir -p "$m" "$out"
sj="${REL_RUN:-/nonexistent}/signer.json"
reuse=0
if [[ "${REL_TEST:-0}" != 1 && -f "$sj" && -f "$m/SHA256SUMS" && -f "$out/btsign-receipt.json" ]] \
    && python3 -I "$(jq -r .client "$sj")" receipt --out-dir "$out" \
    && python3 -I "$(dirname "$0")/server_sums.py" same "$files" "$m" "$m/SHA256SUMS"; then
  # Checked again below as if just signed (both envelopes verified, the listing's signature).
  reuse=1
  echo "the signer already returned these manifests for exactly these files: checking them again, no new request"
else
  for f in update.json update-v2.json update.payload.json update-v2.payload.json btsign-receipt.json; do
    rm -f -- "${out:?}/$f"
  done
fi
export WFE_APK_DIR="$files" WFE_DESKTOP_DIR="$files" BTLABS_PUBLIC="$bp" WFE_MANIFEST_DAYS="${REL_MANIFEST_DAYS:-182}"
# Desktop systems this release has no file for keep their live entry (desktop_keep.py).
rm -f -- "$m/desktop-keep.json"
python3 -I "$(dirname "$0")/desktop_keep.py" "$src" "$files" "$REL_VERSION" "$bp" "$m/desktop-keep.json"
if [[ -f "$m/desktop-keep.json" ]]; then
  grep -q WFE_DESKTOP_KEEP "$src/app/tool/desktop_update_entry.sh" || {
    echo "this commit's app/tool/desktop_update_entry.sh cannot keep live desktop entries: a release" >&2
    echo "without every desktop system needs a commit that has it (or every desktop system in scope)" >&2
    exit 1; }
  export WFE_DESKTOP_KEEP="$m/desktop-keep.json"
fi
if [[ "${REL_TEST:-0}" == 1 ]]; then
  # Stops before signing ("Not signed": exit 1) with the payloads written.
  BTLABS_SIGNING_KEY="$m/no-such-key" "$src/app/tool/release_android.sh" "$base" "$notes" || true
  [[ -f "$out/update.payload.json" && -f "$out/update-v2.payload.json" ]] \
    || { echo "release_android.sh wrote no payloads" >&2; exit 1; }
  tool="$bp/tool/btlabs_sign.py"
  python3 "$tool" keyring --out "$m/test-keyring.json" "$bp/testdata/keys/test-a.pub.json"
  python3 "$tool" sign --type update --key "$bp/testdata/keys/test-a.key" --keyring "$m/test-keyring.json" \
    --payload "$out/update.payload.json" --out "$out/update.json"
  python3 "$tool" sign --type update --app-config "$src/app/assets/config/app-config.toml" \
    --key "$bp/testdata/keys/test-a.key" --keyring "$m/test-keyring.json" \
    --payload "$out/update-v2.payload.json" --out "$out/update-v2.json"
  echo "TEST run: signed with btlabs-public's test key (never accepted by an installed app)"
elif [[ "$reuse" == 1 ]]; then
  tool="$bp/tool/btlabs_sign.py" keyring="$bp/keys/btlabs-keyring.json"
  python3 "$tool" verify --type update --keyring "$keyring" --envelope "$out/update.json"
  python3 "$tool" verify --type update --app-config "$src/app/assets/config/app-config.toml" --keyring "$keyring" \
    --envelope "$out/update-v2.json"
  cp -f -- "$out/SHA256SUMS.sig" "$m/SHA256SUMS.sig"
  python3 "$(dirname "$0")/server_sums.py" verify "$m/SHA256SUMS" "$m/SHA256SUMS.sig" \
    "$bp/keys/btlabs-keyring.json" "$src/tools/gitlab-release.py"
elif [[ -f "$sj" ]]; then
  client="$(jq -r .client "$sj")"
  REL_HOSTS="$(jq -r .hosts "$sj")"; export REL_HOSTS
  rm -f -- "$m/SHA256SUMS" "$m/SHA256SUMS.sig" "$out/SHA256SUMS.sig"
  python3 -I "$(dirname "$0")/server_sums.py" write "$files" "$m" "$m/SHA256SUMS"
  label="$(jq -r '.keys | min_by(.rank) | .label' "$bp/keys/btlabs-keyring.json")"
  # sign-android's request, when it declared these and is for this version: the same code.
  cont="" cf="$REL_RUN/signer-continue.json"
  if [[ -f "$cf" && "$(jq -r '.version // empty' "$cf")" == "$REL_VERSION" ]]; then
    cont="$(jq -r '.request // empty' "$cf")"
  fi
  BTLABS_SIGNER="$client" BTSIGN_CONTINUE="$cont" \
    WFE_SIGNER_JOBS="minisign:file=$m/SHA256SUMS,out=SHA256SUMS.sig,trusted_comment=Epic Cash $REL_VERSION SHA256SUMS, BT Labs key $label" \
    "$src/app/tool/release_android.sh" "$base" "$notes"
  # A copy: the signed file stays beside the client's receipt for a retry.
  cp -f -- "$out/SHA256SUMS.sig" "$m/SHA256SUMS.sig"
  python3 "$(dirname "$0")/server_sums.py" verify "$m/SHA256SUMS" "$m/SHA256SUMS.sig" \
    "$bp/keys/btlabs-keyring.json" "$src/tools/gitlab-release.py"
else
  BTLABS_SIGNING_KEY="${REL_SIGNER_SIGNING_KEY:-$HOME/.config/btlabs/signing/btlabs-2026-a.key}" \
    "$src/app/tool/release_android.sh" "$base" "$notes"
fi
for f in update.json update-v2.json update.payload.json update-v2.payload.json update-legacy.json; do
  if [[ -f "$out/$f" ]]; then cp -f "$out/$f" "$m/$f"; fi
done
ls -l "$m"
