#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Pins and builds LEPIC for the app. The app depends on package:lepic, the Flutter binding, which
# lives in its own repository and pins its LEPIC commit. This script clones lepic-flutter
# into the git-ignored app/third_party/lepic-flutter at the commit in tools/lepic-flutter.rev,
# and LEPIC into app/third_party/lepic at the commit in tools/lepic.rev, which must be the
# binding's own pin. They come from LEPIC_FLUTTER_REPO and LEPIC_REPO (a URL or a path) when set,
# else from ~/lepic-flutter and ~/lepic when those have the pinned commits, else from
# https://github.com/BTLabsUK/{lepic-flutter,lepic}.git. The binding's tool/lepic.sh then
# builds the libraries from that LEPIC clone, so neither source repository gets a new worktree, branch or build output.
#
# Usage:
#   tools/lepic.sh sync              clone or move both clones to their pinned commits
#   tools/lepic.sh build linux       liblepic_ffi.so for this host, bundled by the hook on Linux
#   tools/lepic.sh build android     the three Android ABIs into the binding's native/
#   tools/lepic.sh build all         both
#   tools/lepic.sh lib               print the path of the Linux library
#   tools/lepic.sh prebuild          sync, then fill the shared cache for linux; keep two keys
#   tools/lepic.sh prune-shared      remove shared builds (below) unused for LEPIC_SHARED_DAYS (14)
#
# The Linux library is cached in /tmp/epic-build/lepic-prebuilt/<key>/ (LEPIC_PREBUILT_DIR), keyed by
# both pins, the target, the Rust toolchain and WFE_TOR. A hit copies and checks it; a miss builds
# and stores it (temp dir, then rename). LEPIC_NO_CACHE=1 skips the cache both ways: release
# builds (tools/rel, the release scripts) set it and always build from source. Android is never cached.
#
# WFE_TOR=0 builds the libraries without LEPIC's tor feature (https://docs.btlabs.uk/developers/build/variants/): the
# binding's tool/lepic.sh reads the same switch.
#
# LEPIC_SHARED=1 (tools/check.sh and the Android release build set it) builds from a shared
# clone of the pin instead of app/third_party/lepic, so every worktree at the same pin reuses one
# cargo build: ~/.cache/wfe-lepic/<pin>-<tor|notor>/ (LEPIC_SHARED_DIR), cloned once from this
# worktree's clone and never moved off its commit. One clone per pin and variant keeps the
# sources, the features and the paths baked into xtask those of that pin; a lock per clone runs
# one build at a time and the others wait. The libraries still land in this worktree's
# lepic-flutter/native/, as without it.
#
# Android under LEPIC_SHARED=1 builds from one clone per variant and ABI instead,
# ~/.cache/wfe-lepic/android-<tor|notor>-<triple>/, moved to the pin under its lock. Its path
# stays the same from pin to pin, so a new pin rebuilds only the crates it changed, and the three
# ABIs build at once, each in its own clone and cargo target, with a third of the cores each
# (LEPIC_ANDROID_JOBS). Same features, targets and flags as one build after another.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/tools/env.sh"
clone="$root/app/third_party/lepic"
binding="$root/app/third_party/lepic-flutter"
rev="$(tr -d '[:space:]' < "$root/tools/lepic.rev")"
binding_rev="$(tr -d '[:space:]' < "$root/tools/lepic-flutter.rev")"
source_repo="$(wfe_repo "${LEPIC_REPO:-}" "$HOME/lepic" https://github.com/BTLabsUK/lepic.git "$rev")"
binding_repo="$(wfe_repo "${LEPIC_FLUTTER_REPO:-}" "$HOME/lepic-flutter" \
  https://github.com/BTLabsUK/lepic-flutter.git "$binding_rev")"
# One target directory per clone: a shared one bakes the wrong paths into xtask.
unset CARGO_TARGET_DIR

cache_root="${LEPIC_PREBUILT_DIR:-$HOME/epic-build/lepic-prebuilt}"
linux_triple=x86_64-unknown-linux-gnu

# The cache key of the Linux library: everything that changes the output.
cache_key() {
  local tor=1
  case "${WFE_TOR:-1}" in 0|false|off) tor=0 ;; esac
  printf '%s\n' "lepic=$rev" "binding=$binding_rev" "target=$linux_triple" "tor=$tor" \
    "rustc=$(cd "$clone" && rustc -Vv | tr '\n' ' ')" | sha256sum | cut -c1-24
}

cache_off() { [ -n "${LEPIC_NO_CACHE:-}" ] && [ "$LEPIC_NO_CACHE" != 0 ]; }

# Copies the cached Linux library into the binding's native/ and checks it; fails on a miss or a bad copy.
cache_restore() {
  local src="$cache_root/$1/$linux_triple" dst="$binding/native/$linux_triple"
  [ -f "$src/liblepic_ffi.so" ] || return 1
  (cd "$src" && sha256sum --check --quiet SHA256SUMS) || return 1
  mkdir -p "$dst"
  cp -f "$src"/* "$dst/"   # the library, its SHA256SUMS, FEATURES and SOURCE (hook/build.dart reads them)
  (cd "$dst" && sha256sum --check --quiet SHA256SUMS)
}

# Stores the built Linux library under key $1: a temp dir first, then one rename.
cache_store() {
  local src="$binding/native/$linux_triple" tmp
  [ -f "$src/liblepic_ffi.so" ] || return 0
  mkdir -p "$cache_root"
  tmp="$(mktemp -d "$cache_root/.tmp.XXXXXX")"
  mkdir "$tmp/$linux_triple"
  cp "$src"/* "$tmp/$linux_triple/"
  (cd "$tmp/$linux_triple" && sha256sum --check --quiet SHA256SUMS) || { rm -r "$tmp"; return 0; }
  printf 'lepic %s\nbinding %s\nbuilt %s\n' "$rev" "$binding_rev" "$(date -u +%FT%TZ)" > "$tmp/META"
  # An entry that failed its check (a miss that got here) is replaced; a good one is left.
  if [ -d "$cache_root/$1" ] && ! (cd "$cache_root/$1/$linux_triple" && sha256sum --check --quiet SHA256SUMS) 2>/dev/null; then
    rm -r "$cache_root/$1"
  fi
  if mv -T "$tmp" "$cache_root/$1" 2>/dev/null; then :; else rm -r "$tmp"; fi
}

# Keeps the two newest keys (by directory time); older ones go, each by exact path.
cache_prune() {
  local n=0 d
  [ -d "$cache_root" ] || return 0
  while IFS= read -r d; do
    n=$((n + 1))
    [ "$n" -le 2 ] && continue
    if [[ "$d" =~ ^[0-9a-f]{24}$ ]]; then rm -r "$cache_root/$d"; fi
  done < <(cd "$cache_root" && ls -1t)
}

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

# Must match android_targets in the binding's tool/lepic.sh.
android_triples=(aarch64-linux-android armv7-linux-androideabi x86_64-linux-android)

# Prints the Android clone for this variant and the triple $1, made from this worktree's clone
# on first use. It is moved to another pin only by android_build_one, under the clone's lock.
android_clone() {
  local variant=tor dir tmp
  case "${WFE_TOR:-1}" in 0|false|off) variant=notor ;; esac
  dir="$shared_dir/android-$variant-$1"
  if [ ! -d "$dir/.git" ]; then
    mkdir -p "$shared_dir"
    tmp="$dir.tmp.$$"
    git clone --quiet --no-checkout "$clone" "$tmp" >&2
    git -C "$tmp" checkout --quiet --detach "$rev"
    mv -T "$tmp" "$dir" 2>/dev/null || rm -rf -- "$tmp"   # another build made it first
  fi
  echo "$dir"
}

# Builds LEPIC for the triple $1 from its clone $2 into the binding's native/: takes the clone's
# lock, moves it to the pin (from this worktree's clone, no network) and builds.
android_build_one() {
  local lock
  exec {lock}>>"$2.lock"
  flock -n "$lock" || { echo "waiting for another build from $2"; flock "$lock"; }
  touch "$2.used"
  if [ "$(git -C "$2" rev-parse -q --verify HEAD || true)" != "$rev" ]; then
    git -C "$2" fetch --quiet "$clone" HEAD
    git -C "$2" checkout --quiet --detach "$rev"
  fi
  check_clone "$2" "$rev"
  LEPIC_DIR="$2" "$binding/tool/lepic.sh" build "$1"
}

# The three Android ABIs at once, each from its clone; their output follows in ABI order.
android_build_shared() {
  local logs t src i=0 failed=0 pids=()
  export CARGO_BUILD_JOBS="${LEPIC_ANDROID_JOBS:-$(( ($(nproc) + 2) / 3 ))}"
  logs="$(mktemp -d)"
  for t in "${android_triples[@]}"; do
    src="$(android_clone "$t")"
    echo "LEPIC $rev ($(basename "$src" | cut -d- -f2)) for $t builds from the shared clone $src"
    android_build_one "$t" "$src" > "$logs/$t.log" 2>&1 &
    pids+=("$!")
  done
  for t in "${android_triples[@]}"; do
    wait "${pids[$i]}" || failed=1
    i=$((i + 1))
    cat "$logs/$t.log"
  done
  rm -r -- "$logs"
  [ "$failed" = 0 ] || { echo "LEPIC's Android build failed (above)" >&2; exit 1; }
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
      *) sed -n '9,17p' "$0" >&2; exit 2 ;;
    esac
    # The Linux library from the prebuilt cache when it has this key (LEPIC_NO_CACHE=1 skips it).
    key="" build_linux=0
    if [ "$what" = linux ] || [ "$what" = all ]; then
      build_linux=1
      if ! cache_off; then
        key="$(cache_key)"
        if cache_restore "$key"; then
          build_linux=0
          echo "linux: from the prebuilt cache $cache_root/$key"
        fi
      fi
    fi
    if [ "$what" = linux ] && [ "$build_linux" = 0 ]; then exit 0; fi
    src="$clone"
    shared=0
    [ "${LEPIC_SHARED:-0}" = 1 ] && shared=1
    if [ "$shared" = 1 ] && [ "$build_linux" = 1 ]; then
      src="$(shared_clone)"
      check_clone "$src" "$rev"
      echo "LEPIC $rev ($(basename "$src" | sed "s/.*-//")) builds from the shared clone $src"
      exec {lock}>>"$src.lock"
      flock -n "$lock" || { echo "waiting for another build from $src"; flock "$lock"; }
      touch "$src.used"
    fi
    if [ "$build_linux" = 1 ]; then
      LEPIC_DIR="$src" "$binding/tool/lepic.sh" build linux
      [ -z "$key" ] || cache_store "$key"
      echo "linux: $binding/native/x86_64-unknown-linux-gnu/"
    fi
    if [ "$what" = android ] || [ "$what" = all ]; then
      if [ "$shared" = 1 ]; then
        android_build_shared
      else
        LEPIC_DIR="$src" "$binding/tool/lepic.sh" build android
      fi
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
  prebuild)
    "$0" sync
    LEPIC_NO_CACHE=0 LEPIC_SHARED=1 "$0" build linux
    touch "$cache_root/$(cache_key)"
    cache_prune
    echo "prebuilt cache: $cache_root"
    ;;
  lib)
    echo "$binding/native/x86_64-unknown-linux-gnu/liblepic_ffi.so"
    ;;
  *)
    sed -n '9,17p' "$0" >&2
    exit 2
    ;;
esac
