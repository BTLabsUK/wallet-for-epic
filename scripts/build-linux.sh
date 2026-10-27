#!/usr/bin/env bash
# Reproducible Linux release build: LEPIC release + `flutter build linux --release` + AppImage, all
# inside an Ubuntu 22.04 container (scripts/linux/Dockerfile). Linux builds are never made on the
# host: its newer glibc would stop the app starting on older distros.
#
# Usage: scripts/build-linux.sh [flutter build args...]
# Env:   WFE_TARGET=lib/main_desktop.dart   entry point
#        WFE_NODE_BIN=<path to epic>        bundle the built-in node's binary as usr/bin/bin/epic
#        WFE_BUILD_LEPIC=0                  skip the LEPIC build (the mock build does not use it)
#        WFE_TOR=0                          the build without Tor (https://docs.btlabs.uk/developers/build/variants/): no Tor bundle
#                                           (tools/fetch-tor.sh, in by default), --dart-define=WFE_TOR=false,
#                                           and -notor in the AppImage's name
#        LEPIC_REPO=../lepic                 where the pinned LEPIC commit is read from
#        LEPIC_FLUTTER_REPO=~/lepic-flutter where the pinned lepic-flutter (package:lepic) commit is read from
# Output: build-linux/EpicCashDesktop-<version>[-notor]-x86_64.AppImage
# Caches: docker volumes wfe-linux-{pub,cargo,home,lepic-target} keep rebuilds fast.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image=wfe-linux-build:22.04
lepic_repo="${LEPIC_REPO:-$HOME/lepic}"
binding_repo="${LEPIC_FLUTTER_REPO:-$HOME/lepic-flutter}"
rev="$(tr -d '[:space:]' < "$root/tools/lepic.rev")"
binding_rev="$(tr -d '[:space:]' < "$root/tools/lepic-flutter.rev")"
src="${XDG_CACHE_HOME:-$HOME/.cache}/wfe-linux-build/lepic-$rev"
binding_src="${XDG_CACHE_HOME:-$HOME/.cache}/wfe-linux-build/lepic-flutter-$binding_rev"

# LEPIC and the lepic-flutter binding at their pinned commits, exported to cache dirs outside the
# repo, so the app's own (possibly stale) app/third_party clones are neither used nor touched.
if [[ ! -f "$src/.exported" ]]; then
  mkdir -p "$src"
  # -m: files get the extraction time, not the commit time. The target volume is shared by
  # every pin, so a commit-time mtime older than the last build would leave a crate stale.
  git -C "$lepic_repo" archive "$rev" | tar -x -m -C "$src"
  mkdir -p "$src/target"
  touch "$src/.exported"
fi
if [[ ! -f "$binding_src/.exported" ]]; then
  mkdir -p "$binding_src"
  git -C "$binding_repo" archive "$binding_rev" | tar -x -m -C "$binding_src"
  touch "$binding_src/.exported"
fi
# The binding builds against its own LEPIC pin; the app's must be the same commit.
binding_pin="$(tr -d '[:space:]' < "$binding_src/lepic.rev")"
if [[ "$binding_pin" != "$rev" ]]; then
  echo "tools/lepic.rev ($rev) differs from the LEPIC pin of lepic-flutter $binding_rev ($binding_pin):" \
    "set tools/lepic.rev to the binding's lepic.rev" >&2
  exit 1
fi
rust="$(sed -n 's/^channel *= *"\(.*\)"/\1/p' "$src/rust-toolchain.toml")"
flutter_v="$(tr -d '[:space:]' < "$root/scripts/linux/flutter.version")"
# The commit, shown beside the version in the app (WFE_BUILD_ID, lib/src/app_info.dart); a
# WFE_WORKTREE=1 build of uncommitted changes says so.
build_id="$(git -C "$root" rev-parse --short=7 HEAD)"
if [[ "${WFE_WORKTREE:-0}" = 1 && -n "$(git -C "$root" status --porcelain)" ]]; then build_id+=-dirty; fi
# A rebuild of the same version: r2 from the tag v<version>-r2 on HEAD (WFE_BUILD_TAG).
build_tag="${WFE_BUILD_TAG:-$(git -C "$root" tag --points-at HEAD | sed -n 's/^v[0-9.]*-\(r[0-9][0-9]*\)$/\1/p' | head -1)}"

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
  git -C "$root" archive HEAD | tar -x -m -C "$stage"
fi
mkdir -p "$stage/app/third_party/lepic" "$stage/app/third_party/lepic-flutter" "$stage/app/build"
rsync -a --delete --exclude=/app/build --exclude=/app/.dart_tool --exclude=/app/third_party \
  --exclude=/app/linux/flutter/ephemeral --exclude=/build-linux "$stage/" "$work/"
rm -rf "$stage"
mkdir -p "$work/app/build" "$work/app/third_party/lepic" "$work/app/third_party/lepic-flutter" "$work/build-linux"
# The built-in node's epic binary (WFE_NODE_BIN, optional) goes in as node-bin/epic.
mkdir -p "$work/node-bin"
if [[ -n "${WFE_NODE_BIN:-}" ]]; then
  cp "$WFE_NODE_BIN" "$work/node-bin/epic"
  echo "node binary: $(sha256sum "$work/node-bin/epic" | cut -d' ' -f1)"
else
  : > "$work/node-bin/epic"
fi
# Tor (tools/fetch-tor.sh, checked against tools/tor-bundle.json) goes in as tor-bundle/ and ends up
# at usr/bin/bin/tor-bundle, where lib/src/tor_location.dart looks. Fetched on the host: it needs
# curl and jq, and keeps the tarball in ~/.cache/epic-gui-tor between builds.
rm -rf "$work/tor-bundle"
mkdir -p "$work/tor-bundle"
if [[ "${WFE_TOR:-1}" = 1 ]]; then
  "$root/tools/fetch-tor.sh" linux "$work/tor-bundle"
fi
# Fresh named volumes are root-owned; hand the build-cache ones to the host user once.
docker run --rm -v wfe-linux-lepic-target:/t -v wfe-linux-build:/b -v wfe-linux-pub:/p -v wfe-linux-home:/h "$image" \
  chown "$(id -u):$(id -g)" /t /b /p /h
docker run --rm --user "$(id -u):$(id -g)" \
  -e WFE_TARGET="${WFE_TARGET:-lib/main_desktop.dart}" -e WFE_BUILD_LEPIC="${WFE_BUILD_LEPIC:-1}" \
  -e WFE_BUILD_ID="$build_id" -e WFE_BUILD_TAG="$build_tag" -e WFE_TOR="${WFE_TOR:-1}" \
  -v "$work:/work" \
  -v wfe-linux-build:/work/app/build \
  -v "$src:/work/app/third_party/lepic" \
  -v "$binding_src:/work/app/third_party/lepic-flutter" \
  -v wfe-linux-lepic-target:/work/app/third_party/lepic/target \
  -v wfe-linux-cargo:/opt/cargo \
  -v wfe-linux-pub:/cache/pub \
  -v wfe-linux-home:/cache/home \
  "$image" /work/scripts/linux/in-container.sh "$@"
mv -f "$work"/build-linux/*.AppImage "$root/build-linux/"
ls -l "$root"/build-linux/*.AppImage
