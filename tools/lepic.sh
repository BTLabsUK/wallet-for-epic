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
#   tools/lepic.sh xtask <args>      cargo xtask <args> in the shared clone of the pin (vectors verify,
#                                    upstream-drift); the clone is never moved off the pin
#   tools/lepic.sh lib               print the path of the Linux library
#   tools/lepic.sh prebuild          sync, then fill the shared cache for linux; keep two keys
#   tools/lepic.sh prune-shared      remove shared builds (below) unused for LEPIC_SHARED_DAYS (14)
#   tools/lepic.sh smoke [--interop] [--rev <ref> | --dir <path>] [<out dir>]
#                                    the LEPIC core smoke: LEPIC's CLI acceptance (below)
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
#
# `smoke` is the LEPIC core smoke, for whoever changes LEPIC: run it after a LEPIC change, before
# any app or release lane. It runs LEPIC's interop/acceptance/run.sh, which drives the `lepic` CLI
# against a local Docker stack (reference node, two epic-wallets, the Epicbox relay, a private
# test chain): sends both ways over Epicbox and files, invoices both ways, cancel, restore, and
# two LEPIC wallets pairing by invite, then invoicing and paying through contact mailboxes. It
# stops at the first failing step and names it. --interop then runs interop/run.sh too, the
# scenarios against the official wallet (as long again).
#   (default)      LEPIC at the pin, tools/lepic.rev
#   --rev <ref>    a branch, tag or commit of LEPIC_REPO, else ~/lepic
#   --dir <path>   a LEPIC checkout as it is, uncommitted changes included
# The pin and --rev run from one clone per host, ~/.cache/wfe-lepic/smoke (LEPIC_SMOKE_DIR),
# moved there under its lock; --dir runs in the checkout. The stack's binaries stay in that
# tree's interop/.work (interop/build.sh, in Docker): the upstream ones are built once per
# upstream pin, lepic incrementally. The installed `lepic` is never touched: the run tests
# interop/.work/bin/lepic. The result table and logs go to <out dir> (default: a new temp dir).
# The stack takes 127.0.0.1:43413 and :3423 and refuses to start while something holds them; its
# lock is ~/.cache/wfe-lepic/lepic-acceptance.lock (TMPDIR=~/.cache/wfe-lepic for a run by hand).
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

smoke_dir="${LEPIC_SMOKE_DIR:-$shared_dir/smoke}"

# Runs one of LEPIC's stack scripts ($4...) from the tree $2, whose steps are listed in the
# array $3=( "name:function" ... ) of its step files, with its output in $out/$1.log, and stops
# it at its first failed step: the scripts log `[hh:mm:ss] <step name>` when a step starts and
# `[hh:mm:ss] FAIL: <detail>` when it fails. Stopping it runs its own teardown.
smoke_run() {
  local name="$1" logs="$2/.work/logs" t0=$SECONDS line step="" failed="" rc=0 newest names
  names="$(printf 'setup and funding\n'; sed -n "/^$3=(/,/^)/p" "$2"/*.sh | sed -n 's/^ *"\([^:"]*\):.*/\1/p')"
  shift 3
  echo "== smoke: $name"
  # The scripts' stack lock is ${TMPDIR}/<project>.lock: one TMPDIR for every smoke run on the host.
  exec {pipe}< <(TMPDIR="$shared_dir" exec timeout --kill-after=60 "${LEPIC_SMOKE_TIMEOUT:-1800}" "$@" 2>&1; echo "== exit $?")
  while IFS= read -r line <&"$pipe"; do
    printf '%s\n' "$line" >> "$out/$name.log"
    case "$line" in
      "== exit "*) rc="${line#== exit }" ;;
      "["??:??:??"] FAIL: "*)
        failed="$step: ${line#*FAIL: }"
        echo "   FAIL  $failed"
        pkill -TERM -f -- "$1" 2>/dev/null || true ;;
      "["??:??:??"] PASS: "*) echo "   ok    $step" ;;
      "["??:??:??"] "*) grep -qxF -- "${line#\[??:??:??\] }" <<<"$names" && step="${line#\[??:??:??\] }" ;;
    esac
  done
  exec {pipe}<&-
  newest="$(ls -1d "$logs"/*/ 2>/dev/null | tail -1)"
  [ -n "$newest" ] && echo "   logs: $newest"
  if [ -z "$failed" ] && [ "$rc" = 0 ]; then
    echo "== smoke: $name passed in $((SECONDS - t0))s"
    [ -f "$newest/results.txt" ] && cat "$newest/results.txt"
    return 0
  fi
  if [ -z "$failed" ]; then
    [ "$rc" = 124 ] && failed="timed out after ${LEPIC_SMOKE_TIMEOUT:-1800}s" || failed="exit $rc at: $step"
    tail -n 30 "$out/$name.log"
  fi
  echo "LEPIC core smoke FAILED after $((SECONDS - t0))s: $name: $failed (log: $out/$name.log)" >&2
  return 1
}

# Copies the smoke clone's upstream binaries (node, epic-wallet, the relay's checker) into the
# checkout $1 when they are built from the commits its interop/pins.env names and it has none
# of its own from them, so a new LEPIC worktree does not compile them again.
smoke_seed() {
  local from="$smoke_dir/interop/.work/bin" to="$1/interop/.work/bin" b want
  [ -d "$from" ] || return 0
  for b in epic:EPIC_COMMIT epic-wallet:EPIC_WALLET_COMMIT epicboxlib:EPICBOX_COMMIT; do
    want="$(. "$1/interop/pins.env" && eval echo "\${${b#*:}}")"
    [ "$(cat "$to/${b%%:*}.commit" 2>/dev/null)" != "$want" ] || continue
    [ "$(cat "$from/${b%%:*}.commit" 2>/dev/null)" = "$want" ] || continue
    mkdir -p "$to"
    cp -f "$from/${b%%:*}" "$to/${b%%:*}"
    cp -f "$from/${b%%:*}.commit" "$to/${b%%:*}.commit"
    echo "reused ${b%%:*} from $from"
  done
}

case "${1:-}" in
  smoke)
    shift
    interop=0 smoke_rev="" tree=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --interop) interop=1 ;;
        --rev) smoke_rev="${2:?--rev needs a branch, tag or commit}"; shift ;;
        --dir) tree="$(cd "${2:?--dir needs a LEPIC checkout}" && pwd)"; shift ;;
        -*) sed -n '/^# `smoke`/,/^# The stack takes/p' "$0" >&2; exit 2 ;;
        *) out="$1" ;;
      esac
      shift
    done
    out="${out:-$(mktemp -d)}"
    mkdir -p "$out"
    out="$(cd "$out" && pwd)"
    t0=$SECONDS
    if [ -z "$tree" ]; then
      tree="$smoke_dir"
      want="$rev" what="the pin"
      if [ -n "$smoke_rev" ]; then
        smoke_repo="${LEPIC_REPO:-$HOME/lepic}"
        want="$(git -C "$smoke_repo" rev-parse --verify "$smoke_rev^{commit}")" what="$smoke_rev"
      else
        smoke_repo="$source_repo"
      fi
      exec {lock}>>"$smoke_dir.lock"
      flock -n "$lock" || { echo "waiting for another smoke run from $smoke_dir"; flock "$lock"; }
      if [ ! -d "$smoke_dir/.git" ]; then
        mkdir -p "$(dirname "$smoke_dir")"
        git clone --quiet --no-checkout "$smoke_repo" "$smoke_dir"
      fi
      git -C "$smoke_dir" cat-file -e "$want^{commit}" 2>/dev/null || git -C "$smoke_dir" fetch --quiet "$smoke_repo" "$want"
      git -C "$smoke_dir" checkout --quiet --force --detach "$want"
      check_clone "$smoke_dir" "$want"
      echo "LEPIC core smoke of $what: $(git -C "$tree" log --oneline -1) in $tree"
    else
      echo "LEPIC core smoke of the checkout $tree: $(git -C "$tree" describe --always --dirty)"
      smoke_seed "$tree"
    fi
    echo "output: $out"
    echo "== smoke: build (interop/build.sh: lepic incrementally, the pinned upstream binaries once)"
    if ! "$tree/interop/build.sh" > "$out/build.log" 2>&1; then
      tail -n 30 "$out/build.log"
      echo "LEPIC core smoke FAILED: build (log: $out/build.log)" >&2
      exit 1
    fi
    echo "== smoke: build done in $((SECONDS - t0))s"
    smoke_run acceptance "$tree/interop/acceptance" STEPS \
      "$tree/interop/acceptance/run.sh" --no-build --lepic "$tree/interop/.work/bin/lepic" || exit 1
    if [ "$interop" = 1 ]; then
      smoke_run interop "$tree/interop" SCENARIOS "$tree/interop/run.sh" --no-build || exit 1
    fi
    [ "$tree" != "$smoke_dir" ] || touch "$smoke_dir.used"
    echo "LEPIC core smoke passed in $((SECONDS - t0))s"
    ;;
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
  xtask)
    shift
    [ "$#" -gt 0 ] || { sed -n '9,19p' "$0" >&2; exit 2; }
    src="$(shared_clone)"
    check_clone "$src" "$rev"
    exec {lock}>>"$src.lock"
    flock -n "$lock" || { echo "waiting for another build from $src"; flock "$lock"; }
    touch "$src.used"
    cd "$src" && cargo xtask "$@"
    ;;
  lib)
    echo "$binding/native/x86_64-unknown-linux-gnu/liblepic_ffi.so"
    ;;
  *)
    sed -n '9,17p' "$0" >&2
    exit 2
    ;;
esac
