#!/usr/bin/env bash
# Checks from Linux that LEPIC builds for the Apple targets, with no Apple SDK: a quick early
# check, never the libraries an app ships (tools/build-apple.sh builds those on the Mac).
#   aarch64-apple-darwin, x86_64-apple-darwin  linked liblepic_ffi.dylib, cargo-zigbuild (zig
#                                              carries the macOS headers and link stubs)
#   aarch64-apple-ios, aarch64-apple-ios-sim   liblepic_ffi.a only (no link step): clang with
#                                              zig's macOS headers as a stand-in SDKROOT
# Notes and results: docs/apple-port-notes.md.
#
# Usage: tools/apple-cross-check.sh [target...]   (default: all four)
# Env:   ZIG_DIR=<zig folder>   default ~/.local/opt/zig-x86_64-linux-0.15.2
#        OUT=<dir>              cargo target dir (default $TMPDIR/apple-cross or
#                               ~/.cache/apple-cross); about 3 GB per target
# Needs: rustup targets for LEPIC's toolchain, cargo-zigbuild, clang, llvm-ar-20. Run it through
# build-slot on the build host.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
. "$(git rev-parse --show-toplevel)/tools/env.sh"
lepic="$root/app/third_party/lepic"
zig_dir="${ZIG_DIR:-$HOME/.local/opt/zig-x86_64-linux-0.15.2}"
out="${OUT:-${TMPDIR:-$HOME/.cache}/apple-cross}"
sdk="$out/stand-in-sdk"
[ -f "$lepic/Cargo.toml" ] || { echo "no LEPIC clone: tools/lepic.sh sync" >&2; exit 1; }
[ -x "$zig_dir/zig" ] || { echo "no zig in $zig_dir" >&2; exit 1; }
export PATH="$zig_dir:$PATH" CARGO_TARGET_DIR="$out/target"
export MACOSX_DEPLOYMENT_TARGET=12.0 IPHONEOS_DEPLOYMENT_TARGET=15.0

[ $# -gt 0 ] || set -- aarch64-apple-darwin x86_64-apple-darwin aarch64-apple-ios aarch64-apple-ios-sim
for t in "$@"; do
  echo "== $t"
  case "$t" in
    *-apple-darwin)
      (cd "$lepic" && cargo zigbuild --package lepic-ffi --lib --locked --release --target "$t")
      file "$CARGO_TARGET_DIR/$t/release/liblepic_ffi.dylib"
      ;;
    *-apple-ios|*-apple-ios-sim)
      if [ ! -d "$sdk/usr/include" ]; then
        mkdir -p "$sdk/usr"
        cp -a "$zig_dir/lib/libc/include/any-macos-any" "$sdk/usr/include"
      fi
      tt="${t//-/_}"
      (cd "$lepic" && env SDKROOT="$sdk" "CC_$tt=clang" "AR_$tt=llvm-ar-20" \
        cargo rustc --package lepic-ffi --lib --locked --release --target "$t" --crate-type staticlib)
      ls -l "$CARGO_TARGET_DIR/$t/release/liblepic_ffi.a"
      ;;
    *) echo "not an Apple target: $t" >&2; exit 2 ;;
  esac
done
