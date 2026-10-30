#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Pins and builds LEPIC for the app. The app depends on package:lepic, the Flutter binding, which
# lives in its own repository and pins its LEPIC commit. This script clones lepic-flutter
# into the git-ignored app/third_party/lepic-flutter at the commit in tools/lepic-flutter.rev,
# and LEPIC into app/third_party/lepic at the commit in tools/lepic.rev, which must be the
# binding's own pin. They come from LEPIC_FLUTTER_REPO and LEPIC_REPO (a URL or a path) when set,
# else from ~/lepic-flutter and ~/lepic when those have the pinned commits, else from
# https://gitlab.com/epic-cash-bt/{lepic-flutter,lepic}.git. The binding's tool/lepic.sh then
# builds the libraries from that LEPIC clone, so neither source repository gets a new worktree, branch or build output.
#
# Usage:
#   tools/lepic.sh sync              clone or move both clones to their pinned commits
#   tools/lepic.sh build linux       liblepic_ffi.so for this host, bundled by the hook on Linux
#   tools/lepic.sh build android     the three Android ABIs into the binding's native/
#   tools/lepic.sh build all         both
#   tools/lepic.sh lib               print the path of the Linux library
#   tools/lepic.sh prune-shared      remove shared builds (below) unused for LEPIC_SHARED_DAYS (14)
#
# WFE_TOR=0 builds the libraries without LEPIC's tor feature (https://docs.btlabs.uk/developers/build/variants/): the
# binding's tool/lepic.sh reads the same switch.
#
# LEPIC_SHARED=1 (tools/check.sh sets it; release builds leave it unset) builds from a shared
# clone of the pin instead of app/third_party/lepic, so every worktree at the same pin reuses one
# cargo build: ~/.cache/wfe-lepic/<pin>-<tor|notor>/ (LEPIC_SHARED_DIR), cloned once from this
# worktree's clone and never moved off its commit. One clone per pin and variant keeps the
# sources, the features and the paths baked into xtask those of that pin; a lock per clone runs
# one build at a time and the others wait. The libraries still land in this worktree's
# lepic-flutter/native/, as without it.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/tools/env.sh"
clone="$root/app/third_party/lepic"
binding="$root/app/third_party/lepic-flutter"
rev="$(tr -d '[:space:]' < "$root/tools/lepic.rev")"
binding_rev="$(tr -d '[:space:]' < "$root/tools/lepic-flutter.rev")"
source_repo="$(wfe_repo "${LEPIC_REPO:-}" "$HOME/lepic" https://gitlab.com/epic-cash-bt/lepic.git "$rev")"
binding_repo="$(wfe_repo "${LEPIC_FLUTTER_REPO:-}" "$HOME/lepic-flutter" \
  https://gitlab.com/epic-cash-bt/lepic-flutter.git "$binding_rev")"
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

shared_dir="${LEPIC_SHARED_DIR:-$HOME/.cache/wfe-lepic}"

# Prints the shared clone of the pin for this variant. The first build makes it from this
# worktree's clone (a local clone: hard links, no network) in a temporary directory and moves it
# into place whole.
shared_clone() {
  local variant=tor dir tmp
  case "${WFE_TOR:-1}" in 0|false|off) variant=notor ;; esac
  dir="$shared_dir/$rev-$variant"
  if [ ! -d "$dir/.git" ]; then
    mkdir -p "$shared_dir"
    tmp="$dir.tmp.$$"
    git clone --quiet --no-checkout "$clone" "$tmp" >&2
    git -C "$tmp" checkout --quiet --detach "$rev"
    mv -T "$tmp" "$dir" 2>/dev/null || rm -rf -- "$tmp"   # another build made it first
  fi
  echo "$dir"
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
    src="$clone"
    if [ "${LEPIC_SHARED:-0}" = 1 ]; then
      src="$(shared_clone)"
      check_clone "$src" "$rev"
      echo "LEPIC $rev ($(basename "$src" | sed "s/.*-//")) builds from the shared clone $src"
      exec {lock}>>"$src.lock"
      flock -n "$lock" || { echo "waiting for another build from $src"; flock "$lock"; }
      touch "$src.used"
    fi
    if [ "$what" = linux ] || [ "$what" = all ]; then
      LEPIC_DIR="$src" "$binding/tool/lepic.sh" build linux
      echo "linux: $binding/native/x86_64-unknown-linux-gnu/"
    fi
    if [ "$what" = android ] || [ "$what" = all ]; then
      LEPIC_DIR="$src" "$binding/tool/lepic.sh" build android
      echo "android: $binding/native/"
    fi
    ;;
  prune-shared)
    days="${LEPIC_SHARED_DAYS:-14}"
    for used in "$shared_dir"/*.used; do
      [ -e "$used" ] || continue
      dir="${used%.used}"
      [ -n "$(find "$used" -maxdepth 0 -mtime +"$days")" ] || continue
      exec {lock}>>"$dir.lock"
      if flock -n "$lock"; then   # else a build is using it
        echo "removing $dir (unused for $days days)"
        rm -rf -- "$dir"
        rm -f -- "$used" "$dir.lock"
      fi
      exec {lock}>&-
    done
    ;;
  lib)
    echo "$binding/native/x86_64-unknown-linux-gnu/liblepic_ffi.so"
    ;;
  *)
    sed -n '9,15p' "$0" >&2
    exit 2
    ;;
esac
