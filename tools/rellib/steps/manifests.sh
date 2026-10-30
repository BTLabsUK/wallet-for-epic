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
# Env (set by tools/rel): REL_SRC REL_FILES REL_MANIFESTS REL_NOTES_FILE REL_TEST
#   REL_SIGNER_BTLABS_PUBLIC REL_SIGNER_SIGNING_KEY (release-hosts.toml host.signer)
set -euo pipefail
src="${REL_SRC:?}" files="${REL_FILES:?}" m="${REL_MANIFESTS:?}"
bp="${REL_SIGNER_BTLABS_PUBLIC:-$HOME/code/btlabs-public}"
base="$(python3 -I -c 'import sys, tomllib; print(tomllib.load(open(sys.argv[1], "rb"))["old_update"]["downloads"])' \
  "$src/app/tool/config/old-update.toml")"
notes="$(cat "${REL_NOTES_FILE:-/dev/null}" 2>/dev/null || true)"
out="$src/app/build/app/outputs/flutter-apk"
mkdir -p "$m" "$out"
for f in update.json update-v2.json update.payload.json update-v2.payload.json; do
  rm -f -- "${out:?}/$f"
done
export WFE_APK_DIR="$files" WFE_DESKTOP_DIR="$files" BTLABS_PUBLIC="$bp"
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
else
  BTLABS_SIGNING_KEY="${REL_SIGNER_SIGNING_KEY:-$HOME/.config/btlabs/signing/btlabs-2026-a.key}" \
    "$src/app/tool/release_android.sh" "$base" "$notes"
fi
for f in update.json update-v2.json update.payload.json update-v2.payload.json update-legacy.json; do
  if [[ -f "$out/$f" ]]; then cp -f "$out/$f" "$m/$f"; fi
done
ls -l "$m"
