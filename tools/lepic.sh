#!/usr/bin/env bash
# Pins and builds LEPIC for the app. The app depends on package:lepic, the Flutter binding, which
# lives in its own repository and pins its LEPIC commit. This script clones lepic-flutter
# into the git-ignored app/third_party/lepic-flutter at the commit in tools/lepic-flutter.rev,
# and LEPIC into app/third_party/lepic at the commit in tools/lepic.rev, which must be the
# binding's own pin. They come from LEPIC_FLUTTER_REPO and LEPIC_REPO (a URL or a path) when set,
# else from ~/lepic-flutter and ~/lepic when those have the pinned commits, else from
# https://gitlab.com/bt-labs-group/{lepic-flutter,lepic}.git. The binding's tool/lepic.sh then
# builds the libraries from that LEPIC clone, so neither source repository gets a new worktree, branch or build output.
#
# Usage:
#   tools/lepic.sh sync              clone or move both clones to their pinned commits
#   tools/lepic.sh build linux       liblepic_ffi.so for this host, bundled by the hook on Linux
#   tools/lepic.sh build android     the three Android ABIs into the binding's native/
#   tools/lepic.sh build all         both
#   tools/lepic.sh lib               print the path of the Linux library
#
# WFE_TOR=0 builds the libraries without LEPIC's tor feature (https://docs.btlabs.uk/developers/build/variants/): the
# binding's tool/lepic.sh reads the same switch.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/tools/env.sh"
clone="$root/app/third_party/lepic"
binding="$root/app/third_party/lepic-flutter"
rev="$(tr -d '[:space:]' < "$root/tools/lepic.rev")"
binding_rev="$(tr -d '[:space:]' < "$root/tools/lepic-flutter.rev")"
source_repo="$(wfe_repo "${LEPIC_REPO:-}" "$HOME/lepic" https://gitlab.com/bt-labs-group/lepic.git "$rev")"
binding_repo="$(wfe_repo "${LEPIC_FLUTTER_REPO:-}" "$HOME/lepic-flutter" \
  https://gitlab.com/bt-labs-group/lepic-flutter.git "$binding_rev")"
# One target directory per clone: a shared one bakes the wrong paths into xtask.
unset CARGO_TARGET_DIR

# Moves (or first makes) the clone $1 of repository $2 to commit $3.
sync_clone() {
  if [ ! -d "$1/.git" ]; then
    mkdir -p "$(dirname "$1")"
    git clone --quiet --no-checkout "$2" "$1"
  fi
  git -C "$1" fetch --quiet origin
  git -C "$1" checkout --quiet --detach "$3"
}

# Fails unless the clone $1 exists, is at commit $2 and has no local changes.
check_clone() {
  [ -d "$1/.git" ] || { echo "no clone at $1: run tools/lepic.sh sync" >&2; exit 1; }
  [ "$(git -C "$1" rev-parse HEAD)" = "$2" ] \
    || { echo "$1 is not at the pin $2: run tools/lepic.sh sync" >&2; exit 1; }
  [ -z "$(git -C "$1" status --porcelain --untracked-files=no)" ] \
    || { echo "$1 has local changes; it must match the pin exactly" >&2; exit 1; }
}

# The binding builds and tests against its own LEPIC pin; the app's must be the same commit.
check_pins_agree() {
  local binding_pin
  binding_pin="$(tr -d '[:space:]' < "$binding/lepic.rev")"
  [ "$binding_pin" = "$rev" ] || {
    echo "tools/lepic.rev ($rev) differs from the LEPIC pin of lepic-flutter $binding_rev" \
      "($binding_pin): set tools/lepic.rev to the binding's lepic.rev" >&2
    exit 1
  }
}

case "${1:-}" in
  sync)
    sync_clone "$binding" "$binding_repo" "$binding_rev"
    echo "lepic-flutter at $(git -C "$binding" log --oneline -1)"
    check_pins_agree
    sync_clone "$clone" "$source_repo" "$rev"
    echo "LEPIC at $(git -C "$clone" log --oneline -1)"
    ;;
  build)
    check_clone "$binding" "$binding_rev"
    check_clone "$clone" "$rev"
    check_pins_agree
    what="${2:-all}"
    case "$what" in
      linux|android|all) ;;
      *) sed -n '9,15p' "$0" >&2; exit 2 ;;
    esac
    if [ "$what" = linux ] || [ "$what" = all ]; then
      LEPIC_DIR="$clone" "$binding/tool/lepic.sh" build linux
      echo "linux: $binding/native/x86_64-unknown-linux-gnu/"
    fi
    if [ "$what" = android ] || [ "$what" = all ]; then
      LEPIC_DIR="$clone" "$binding/tool/lepic.sh" build android
      echo "android: $binding/native/"
    fi
    ;;
  lib)
    echo "$binding/native/x86_64-unknown-linux-gnu/liblepic_ffi.so"
    ;;
  *)
    sed -n '9,15p' "$0" >&2
    exit 2
    ;;
esac
