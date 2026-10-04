#!/usr/bin/env bash
# Pins and builds LEPIC for the app. LEPIC is a separate project: this script only clones
# LEPIC ($LEPIC_REPO, default GitHub) into the git-ignored app/third_party/lepic at the commit in tools/lepic.rev and
# builds there, so LEPIC's own repository gets no new worktree, branch or build output.
#
# Usage:
#   tools/lepic.sh sync              clone or move the clone to the pinned commit
#   tools/lepic.sh build linux       liblepic_ffi.so for this host, bundled by the hook on Linux
#   tools/lepic.sh build android     the three Android ABIs into bindings/flutter/native/
#   tools/lepic.sh build all         both
#   tools/lepic.sh lib               print the path of the Linux library
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
. "$(git rev-parse --show-toplevel)/tools/env.sh"
source_repo=${LEPIC_REPO:-https://github.com/BTLabs-EPIC/lepic.git}
clone="$root/app/third_party/lepic"
rev="$(tr -d '[:space:]' < "$root/tools/lepic.rev")"
# One target directory per clone: a shared one bakes the wrong paths into xtask.
unset CARGO_TARGET_DIR

check_clone() {
  [ -d "$clone/.git" ] || { echo "no LEPIC clone: run tools/lepic.sh sync" >&2; exit 1; }
  [ "$(git -C "$clone" rev-parse HEAD)" = "$rev" ] \
    || { echo "LEPIC clone is not at the pin $rev: run tools/lepic.sh sync" >&2; exit 1; }
  [ -z "$(git -C "$clone" status --porcelain --untracked-files=no)" ] \
    || { echo "LEPIC clone has local changes; it must match the pin exactly" >&2; exit 1; }
}

case "${1:-}" in
  sync)
    if [ ! -d "$clone/.git" ]; then
      mkdir -p "$(dirname "$clone")"
      git clone --quiet --no-checkout "$source_repo" "$clone"
    fi
    git -C "$clone" fetch --quiet origin
    git -C "$clone" checkout --quiet --detach "$rev"
    echo "LEPIC at $(git -C "$clone" log --oneline -1)"
    ;;
  build)
    check_clone
    what="${2:-all}"
    if [ "$what" = linux ] || [ "$what" = all ]; then
      (cd "$clone" && cargo xtask mobile --package --target x86_64-unknown-linux-gnu)
      echo "linux: $clone/bindings/flutter/native/x86_64-unknown-linux-gnu/"
    fi
    if [ "$what" = android ] || [ "$what" = all ]; then
      (cd "$clone" && cargo xtask mobile --package --target aarch64-linux-android \
        --target armv7-linux-androideabi --target x86_64-linux-android)
      echo "android: $clone/bindings/flutter/native/"
    fi
    ;;
  lib)
    echo "$clone/bindings/flutter/native/x86_64-unknown-linux-gnu/liblepic_ffi.so"
    ;;
  *)
    sed -n '6,12p' "$0" >&2
    exit 2
    ;;
esac
