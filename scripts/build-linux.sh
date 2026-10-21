#!/usr/bin/env bash
# Reproducible Linux release build: LEPIC release + `flutter build linux --release` + AppImage, all
# inside an Ubuntu 22.04 container (scripts/linux/Dockerfile). Linux builds are never made on the
# host: its newer glibc would stop the app starting on older distros.
#
# Usage: scripts/build-linux.sh [flutter build args...]
# Env:   WFE_TARGET=lib/main_desktop.dart   entry point (default: the mock-data desktop interface)
#        WFE_BUILD_LEPIC=0                  skip the LEPIC build (the mock build does not use it)
#        LEPIC_REPO=../lepic                 where the pinned LEPIC commit is read from
# Output: build-linux/WalletForEpic-<version>-x86_64.AppImage
# Caches: docker volumes wfe-linux-{pub,cargo,home,lepic-target} keep rebuilds fast.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image=wfe-linux-build:22.04
lepic_repo="${LEPIC_REPO:-$HOME/lepic}"
rev="$(tr -d '[:space:]' < "$root/tools/lepic.rev")"
src="${XDG_CACHE_HOME:-$HOME/.cache}/wfe-linux-build/lepic-$rev"

# LEPIC at the pinned commit, exported to a cache dir outside the repo, so the app's own
# (possibly stale) app/third_party/lepic clone is neither used nor touched.
if [[ ! -f "$src/.exported" ]]; then
  mkdir -p "$src"
  git -C "$lepic_repo" archive "$rev" | tar -x -C "$src"
  mkdir -p "$src/target"
  touch "$src/.exported"
fi
rust="$(sed -n 's/^channel *= *"\(.*\)"/\1/p' "$src/rust-toolchain.toml")"
flutter_v="$(tr -d '[:space:]' < "$root/scripts/linux/flutter.version")"

docker build -q -t "$image" --build-arg "RUST_VERSION=$rust" --build-arg "FLUTTER_VERSION=$flutter_v" \
  "$root/scripts/linux" >/dev/null

# The build runs on a snapshot of the committed tree (or of the working tree with WFE_WORKTREE=1),
# kept apart from the repo so it never clobbers app/build, .dart_tool or the Flutter ephemeral
# files other work in the worktree depends on, and so a half-edited file cannot break a release.
work="${XDG_CACHE_HOME:-$HOME/.cache}/wfe-linux-build/work"
stage="$(mktemp -d)"
mkdir -p "$work" "$root/build-linux"
if [[ "${WFE_WORKTREE:-0}" = 1 ]]; then
  rsync -a --exclude=/.git --exclude=/app/build --exclude=/app/.dart_tool --exclude=/app/third_party \
    --exclude=/build-linux --exclude=/app/linux/flutter/ephemeral "$root/" "$stage/"
else
  git -C "$root" archive HEAD | tar -x -C "$stage"
fi
mkdir -p "$stage/app/third_party/lepic" "$stage/app/build"
rsync -a --delete --exclude=/app/build --exclude=/app/.dart_tool --exclude=/app/third_party \
  --exclude=/app/linux/flutter/ephemeral --exclude=/build-linux "$stage/" "$work/"
rm -rf "$stage"
mkdir -p "$work/app/build" "$work/app/third_party/lepic" "$work/build-linux"
# Fresh named volumes are root-owned; hand the build-cache ones to the host user once.
docker run --rm -v wfe-linux-lepic-target:/t -v wfe-linux-build:/b -v wfe-linux-pub:/p -v wfe-linux-home:/h "$image" \
  chown "$(id -u):$(id -g)" /t /b /p /h
docker run --rm --user "$(id -u):$(id -g)" \
  -e WFE_TARGET="${WFE_TARGET:-lib/main_desktop.dart}" -e WFE_BUILD_LEPIC="${WFE_BUILD_LEPIC:-1}" \
  -v "$work:/work" \
  -v wfe-linux-build:/work/app/build \
  -v "$src:/work/app/third_party/lepic" \
  -v wfe-linux-lepic-target:/work/app/third_party/lepic/target \
  -v wfe-linux-cargo:/opt/cargo \
  -v wfe-linux-pub:/cache/pub \
  -v wfe-linux-home:/cache/home \
  "$image" /work/scripts/linux/in-container.sh "$@"
mv -f "$work"/build-linux/*.AppImage "$root/build-linux/"
ls -l "$root"/build-linux/*.AppImage
