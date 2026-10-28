#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Builds tor for Android from source, as a drop-in for the Tor Project's prebuilt libTor.so that
# tools/fetch-tor.sh android puts in place (F-Droid accepts no prebuilt binaries). The output has
# the same layout: <jniLibs dir>/<abi>/libtor.so, a PIE executable linked statically against
# OpenSSL, libevent and zlib (only libc, libm and libdl from Android), LOAD segments aligned to
# 16 KB, stripped; and Tor's licence as <jniLibs dir>/LICENSE.tor.txt. zstd, liblzma, systemd and
# seccomp are left out; tor's relay and dirauth modules stay in, as in the prebuilt.
#
# Usage: tools/build-tor-android.sh [--work <dir>] <jniLibs dir>
# Env:   TOR_ANDROID_ABIS   ABIs to build (default "arm64-v8a x86_64"; also armeabi-v7a, x86)
#        TOR_ANDROID_API    API level (default 24, Flutter's flutter.minSdkVersion that the app uses)
#        ANDROID_NDK_HOME   the NDK (tools/env.sh sets it; ANDROID_NDK_ROOT is also read)
#        TOR_SRC_CACHE      where tarballs are kept (default ~/.cache/epic-tor-src); a cached
#                           tarball is used only when its hash matches tools/tor-src.json
#        TOR_SRC_DIR, OPENSSL_SRC_DIR, LIBEVENT_SRC_DIR, ZLIB_SRC_DIR
#                           an unpacked source tree to use instead of the pinned tarball (F-Droid
#                           srclibs: git checkouts at the tags in tools/tor-src.json). The tree is
#                           copied into the work dir and never written to. A tor or libevent tree
#                           without ./configure (a git checkout) is bootstrapped with autogen.sh,
#                           which needs autoconf, automake and libtool.
#        JOBS               parallel make jobs (default: nproc)
#        SOURCE_DATE_EPOCH  default: sourceDateEpoch in tools/tor-src.json (tor's release day)
# The work dir (default: a new dir under $TMPDIR, removed on success) is the only place written
# to besides the output; the output is written only once every ABI built.
#
# Reproducible: the same sources, NDK and API give the same libtor.so in any work dir. Build paths
# are mapped away (-ffile-prefix-map, in compiler wrappers so OpenSSL's recorded compiler line
# holds no path), every install prefix is the fixed /usr/local/epic-tor (staged with DESTDIR),
# llvm-ar is deterministic, SOURCE_DATE_EPOCH fixes OpenSSL's build date, and the result is
# stripped with llvm-strip.
#
# The pins in tools/tor-src.json are SHA-256 only; this script checks no signature. They were
# written after a by-hand check, to be repeated when moving to new versions:
#   export GNUPGHOME=$(mktemp -d)
#   gpg --keyserver hkps://keys.openpgp.org --recv-keys <each fingerprint in signingKeys>
#   curl -fLO <url> and <url>.asc (tor: <url>.sha256sum and <url>.sha256sum.asc)
#   gpg --verify <file>.asc <file>     (Good signature from a listed key, or stop)
#   tor only: sha256sum -c tor-<version>.tar.gz.sha256sum
#   sha256sum <tarball> into tools/tor-src.json; for tor also the LICENSE hash (`license`).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
pins="$root/tools/tor-src.json"
usage="usage: $0 [--work <dir>] <jniLibs dir>"
work=
out=
while [[ $# -gt 0 ]]; do
  case "$1" in
    --work) work="${2:?$usage}"; shift 2 ;;
    -h|--help) echo "$usage"; exit 0 ;;
    -*) echo "$usage" >&2; exit 2 ;;
    *) [[ -z "$out" ]] || { echo "$usage" >&2; exit 2; }; out="$1"; shift ;;
  esac
done
[[ -n "$out" ]] || { echo "$usage" >&2; exit 2; }

abis="${TOR_ANDROID_ABIS:-arm64-v8a x86_64}"
api="${TOR_ANDROID_API:-24}"
ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
[[ -n "$ndk" && -f "$ndk/source.properties" ]] || { echo "set ANDROID_NDK_HOME (. tools/env.sh)" >&2; exit 1; }
ndk="$(cd "$ndk" && pwd -P)"
ndkbin="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
[[ -x "$ndkbin/clang" ]] || { echo "no NDK clang in $ndkbin" >&2; exit 1; }
jobs="${JOBS:-$(nproc)}"
cache="${TOR_SRC_CACHE:-$HOME/.cache/epic-tor-src}"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(jq -r .sourceDateEpoch "$pins")}"
export LC_ALL=C TZ=UTC
umask 022
prefix=/usr/local/epic-tor

for abi in $abis; do
  case "$abi" in arm64-v8a|x86_64|armeabi-v7a|x86) ;; *) echo "unknown ABI $abi" >&2; exit 2 ;; esac
done

keep_work=
if [[ -n "$work" ]]; then
  keep_work=1
  mkdir -p "$work"
  work="$(cd "$work" && pwd -P)"
  [[ -z "$(ls -A "$work")" ]] || { echo "work dir $work is not empty" >&2; exit 1; }
else
  work="$(mktemp -d)"
  work="$(cd "$work" && pwd -P)"
  trap '[[ $? -eq 0 ]] && rm -rf -- "$work" || echo "work dir kept: $work" >&2' EXIT
fi
echo "work dir $work"

hash_of() { sha256sum "$1" | cut -d' ' -f1; }
pin() { jq -r ".libs.$1.$2 // empty" "$pins"; }

# fetch <lib>: the pinned tarball in the cache, hash-checked.
fetch() {
  local lib="$1" url mirror want file
  url="$(pin "$lib" url)"
  mirror="$(pin "$lib" mirror)"
  want="$(pin "$lib" sha256)"
  file="$cache/$(basename "$url")"
  mkdir -p "$cache"
  if [[ ! -f "$file" || "$(hash_of "$file")" != "$want" ]]; then
    local ok='' u
    for u in "$url" $mirror; do
      echo "downloading $u"
      if curl -fsSL --proto '=https' --proto-redir '=https' --retry 2 --connect-timeout 20 -o "$file.part" "$u"; then
        ok=1
        break
      fi
    done
    [[ -n "$ok" ]] || { rm -f -- "$file.part"; echo "download of $lib failed" >&2; exit 1; }
    mv -f "$file.part" "$file"
  fi
  local got
  got="$(hash_of "$file")"
  if [[ "$got" != "$want" ]]; then
    rm -f -- "$file"
    echo "$lib tarball hash mismatch: $got, pinned $want (removed)" >&2
    exit 1
  fi
  echo "$lib tarball ok $got"
}

# unpack <lib> <SRC_DIR override>: a clean tree at $work/src/<lib>.
unpack() {
  local lib="$1" dir="$2" dest="$work/src/$1"
  mkdir -p "$work/src"
  if [[ -n "$dir" ]]; then
    [[ -d "$dir" ]] || { echo "$lib source dir $dir not found" >&2; exit 1; }
    echo "$lib from $dir"
    cp -a "$dir" "$dest"
    rm -rf -- "$dest/.git"
  else
    fetch "$lib"
    mkdir -p "$dest"
    tar -xzf "$cache/$(basename "$(pin "$lib" url)")" -C "$dest" --strip-components=1 --no-same-owner
  fi
}

unpack tor "${TOR_SRC_DIR:-}"
unpack openssl "${OPENSSL_SRC_DIR:-}"
unpack libevent "${LIBEVENT_SRC_DIR:-}"
unpack zlib "${ZLIB_SRC_DIR:-}"
for lib in tor libevent; do
  if [[ ! -x "$work/src/$lib/configure" ]]; then
    echo "$lib: no configure, running autogen.sh"
    (cd "$work/src/$lib" && ./autogen.sh)
  fi
done
if [[ -n "${TOR_SRC_DIR:-}" ]]; then
  got="$(hash_of "$work/src/tor/LICENSE")"
  [[ "$got" == "$(pin tor license)" ]] || echo "note: tor LICENSE hash $got differs from the pin" >&2
fi

# build_abi <abi>: deps staged in $work/<abi>/stage$prefix, tor binary at $work/<abi>/libtor.so.
build_abi() {
  local abi="$1" triple ossl_target
  case "$abi" in
    arm64-v8a)   triple=aarch64-linux-android;     ossl_target=android-arm64 ;;
    x86_64)      triple=x86_64-linux-android;      ossl_target=android-x86_64 ;;
    armeabi-v7a) triple=armv7a-linux-androideabi;  ossl_target=android-arm ;;
    x86)         triple=i686-linux-android;        ossl_target=android-x86 ;;
  esac
  local base="$work/$abi" bin="$work/$abi/bin"
  local stage="$base/stage" dep="$base/stage$prefix"
  mkdir -p "$bin" "$stage"
  cp -a "$work/src" "$base/src"

  # Compiler wrappers, found by name on PATH so no build path ends up in a recorded command
  # line; OpenSSL's android targets pick "<triple><api>-clang" from PATH themselves.
  local cc="$triple$api-clang" t
  for t in clang clang++; do
    cat > "$bin/$triple$api-$t" <<EOF
#!/bin/sh
exec "$ndkbin/$triple$api-$t" -ffile-prefix-map=$work=/build -ffile-prefix-map=$ndk=/ndk "\$@"
EOF
    chmod +x "$bin/$triple$api-$t"
  done

  local ldflags="-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384 -Wl,-z,now -Wl,--build-id=sha1"
  local env=(env "PATH=$bin:$ndkbin:$PATH" "ANDROID_NDK_ROOT=$ndk" "ANDROID_NDK_HOME=$ndk"
             CC="$cc" AR=llvm-ar RANLIB=llvm-ranlib NM=llvm-nm STRIP=llvm-strip
             LDFLAGS="$ldflags")

  echo "== $abi: zlib"
  (cd "$base/src/zlib" &&
    "${env[@]}" CHOST="$triple" CFLAGS="-O2 -fPIC" ./configure --static --prefix="$prefix" &&
    "${env[@]}" make -j"$jobs" libz.a &&
    "${env[@]}" make install DESTDIR="$stage")

  echo "== $abi: openssl"
  (cd "$base/src/openssl" &&
    "${env[@]}" ./Configure "$ossl_target" -D__ANDROID_API__="$api" \
      no-shared no-tests no-apps no-docs no-ui-console no-engine no-module no-comp \
      --prefix="$prefix" --openssldir="$prefix/ssl" --libdir=lib &&
    "${env[@]}" make -j"$jobs" build_libs &&
    "${env[@]}" make install_dev DESTDIR="$stage")

  echo "== $abi: libevent"
  (cd "$base/src/libevent" &&
    "${env[@]}" CFLAGS="-O2 -fPIC" ./configure --host="$triple" --prefix="$prefix" \
      --disable-shared --enable-static --with-pic --disable-openssl --disable-mbedtls \
      --disable-samples --disable-libevent-regress --disable-debug-mode &&
    "${env[@]}" make -j"$jobs" &&
    "${env[@]}" make install DESTDIR="$stage")

  echo "== $abi: tor"
  # Cross-compiling, tor's configure cannot run its integer/pointer checks; Android on these
  # ABIs is two's complement with all-zero NULL and 0.0.
  (cd "$base/src/tor" &&
    "${env[@]}" CFLAGS="-O2" LIBS="-ldl" \
      tor_cv_null_is_zero=yes tor_cv_dbl0_is_zero=yes tor_cv_twos_complement=yes \
      tor_cv_sign_extend=yes tor_cv_malloc_zero_works=yes \
      ./configure --host="$triple" --prefix="$prefix" \
      --enable-static-openssl --with-openssl-dir="$dep" \
      --enable-static-libevent --with-libevent-dir="$dep" \
      --enable-static-zlib --with-zlib-dir="$dep" \
      --disable-zstd --disable-lzma --disable-systemd --disable-seccomp --disable-libscrypt \
      --disable-asciidoc --disable-manpage --disable-html-manual --disable-unittests \
      --disable-tool-name-check &&
    "${env[@]}" make -j"$jobs" src/app/tor)

  "$ndkbin/llvm-strip" --strip-all -o "$base/libtor.so" "$base/src/tor/src/app/tor"
  touch -d "@$SOURCE_DATE_EPOCH" "$base/libtor.so"
  check_abi "$abi" "$base/libtor.so"
}

# check_abi <abi> <file>: the shape tools/fetch-tor.sh's prebuilt has, or fail.
check_abi() {
  local abi="$1" f="$2" readelf="$ndkbin/llvm-readelf" needed lib
  "$readelf" -h "$f" | grep -q 'DYN (Shared object file)\|DYN (Position-Independent' ||
    { echo "$abi: not a PIE executable" >&2; exit 1; }
  "$readelf" -d "$f" | grep -q 'FLAGS_1.*PIE' || { echo "$abi: not PIE" >&2; exit 1; }
  needed="$("$readelf" -d "$f" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p' | sort | tr '\n' ' ')"
  for lib in $needed; do
    case "$lib" in libc.so|libm.so|libdl.so) ;; *) echo "$abi: needs $lib (only libc/libm/libdl allowed)" >&2; exit 1 ;; esac
  done
  local align
  for align in $("$readelf" -lW "$f" | awk '$1 == "LOAD" { print $NF }'); do
    (( align >= 16384 )) || { echo "$abi: LOAD segment aligned to $align, under 16 KB" >&2; exit 1; }
  done
  echo "$abi: libtor.so ok, NEEDED $needed, LOAD aligned >= 16 KB, sha256 $(hash_of "$f")"
}

for abi in $abis; do
  build_abi "$abi"
done

mkdir -p "$out"
for abi in $abis; do
  mkdir -p "$out/$abi"
  install -p -m 0755 "$work/$abi/libtor.so" "$out/$abi/libtor.so"
done
install -m 0644 "$work/src/tor/LICENSE" "$out/LICENSE.tor.txt"
echo "tor $(pin tor version) for $abis (API $api) in $out"
[[ -z "$keep_work" ]] || echo "work dir kept: $work"
