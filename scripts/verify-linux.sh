#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Checks a Linux AppImage without starting it: name, ELF headers, the squashfs inside (read with
# unsquashfs at the offset the ELF headers give; the AppImage itself is never run), the app, LEPIC,
# the built-in node and the Tor bundle (or none), the build id, and the glibc the binaries need
# (the container is Ubuntu 22.04: nothing may need more than 2.35). scripts/build-linux.sh runs it
# on every build; it also runs on a downloaded AppImage.
#
# Usage: scripts/verify-linux.sh <bt-wallet-<version>[-notor]-linux-x86_64.AppImage>
# Env:   WFE_TOR=0|1     the build without Tor / with Tor (default 1)
#        WFE_VERSION     the version the name must carry (default: tools/version.sh name)
#        WFE_BUILD_ID    when set, libapp.so must carry it (the About line)
# Needs: readelf, objdump, python3, and unsquashfs (squashfs-tools); without unsquashfs the checks
# inside the AppImage are skipped with a "skip" line and do not fail.
# Exit 0 when every check passes; else 1, with one line per failed check on stderr.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
img="${1:-}"
[[ -f "$img" ]] || { echo "usage: $0 <file.AppImage>" >&2; exit 2; }
version="${WFE_VERSION:-$("$root/tools/version.sh" name)}"
build_id="${WFE_BUILD_ID:-}"
tor=1 variant=
if [[ "${WFE_TOR:-1}" == 0 ]]; then tor=0 variant=-notor; fi
glibc_max=2.35

fail=0 failed=()
check() { # description, condition result (0 = ok)
  if [[ "$2" == 0 ]]; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; failed+=("FAIL: $1"); fi
}
is_x86_64_elf() { readelf -h "$1" 2>/dev/null | grep -q 'Machine:.*X86-64'; }
# The highest GLIBC_x.y the binary asks for.
glibc_of() { objdump -T "$1" 2>/dev/null | grep -o 'GLIBC_[0-9][0-9.]*' | sed 's/GLIBC_//' | sort -V | tail -1; }

name="$(basename "$img")"
echo "$name"
want="bt-wallet-$version$variant-linux-x86_64.AppImage"
[[ "$name" == "$want" ]] && r=0 || r=1; check "name $want" $r
is_x86_64_elf "$img" && r=0 || r=1; check "ELF x86-64 runtime" $r

# The squashfs starts where the runtime's ELF ends (after its section headers).
offset="$(python3 -I - "$img" <<'PY'
import struct, sys
with open(sys.argv[1], "rb") as f:
    h = f.read(64)
    shoff = struct.unpack_from("<Q", h, 0x28)[0]
    shentsize, shnum = struct.unpack_from("<HH", h, 0x3A)
    off = shoff + shentsize * shnum
    f.seek(off)
    print(off if f.read(4) == b"hsqs" else "")
PY
)"
[[ -n "$offset" ]] && r=0 || r=1; check "squashfs after the runtime" $r

if [[ -z "$offset" ]]; then
  :
elif ! command -v unsquashfs >/dev/null; then
  echo "  skip the checks inside the AppImage (unsquashfs not found)"
else
  work="$(mktemp -d)"
  trap 'rm -r -- "$work"' EXIT
  listing="$(unsquashfs -o "$offset" -ls "$img")"
  has() { grep -qxF "squashfs-root/$1" <<<"$listing"; }
  for f in AppRun uk.btlabs.epiccash.desktop.desktop usr/bin/btwallet usr/bin/lib/libapp.so \
           usr/bin/lib/liblepic_ffi.so usr/bin/lib/libflutter_linux_gtk.so usr/bin/data/icudtl.dat; do
    has "$f" && r=0 || r=1; check "$f" $r
  done
  has usr/bin/bin/epic && r=0 || r=1; check "usr/bin/bin/epic (the built-in node)" $r
  if [[ $tor == 1 ]]; then
    for f in tor VERSION LICENSE.tor.txt; do
      has "usr/bin/bin/tor-bundle/$f" && r=0 || r=1; check "usr/bin/bin/tor-bundle/$f" $r
    done
  else
    grep -q '^squashfs-root/usr/bin/bin/tor-bundle' <<<"$listing" && r=1 || r=0; check "no Tor bundle" $r
  fi
  files=(usr/bin/btwallet usr/bin/lib/libapp.so usr/bin/lib/liblepic_ffi.so usr/bin/bin/epic)
  [[ $tor == 1 ]] && files+=(usr/bin/bin/tor-bundle/tor)
  unsquashfs -o "$offset" -n -f -q -d "$work/x" "$img" "${files[@]}" >/dev/null
  for f in usr/bin/btwallet usr/bin/lib/libapp.so usr/bin/lib/liblepic_ffi.so usr/bin/bin/epic; do
    [[ -f "$work/x/$f" ]] || continue
    is_x86_64_elf "$work/x/$f" && r=0 || r=1; check "$f is ELF x86-64" $r
  done
  [[ $tor == 1 ]] && { is_x86_64_elf "$work/x/usr/bin/bin/tor-bundle/tor" && r=0 || r=1; check "tor-bundle/tor is ELF x86-64" $r; }
  for f in usr/bin/btwallet usr/bin/lib/liblepic_ffi.so usr/bin/bin/epic; do
    [[ -f "$work/x/$f" ]] || continue
    g="$(glibc_of "$work/x/$f")"
    [[ -z "$g" || "$(printf '%s\n%s\n' "$g" "$glibc_max" | sort -V | tail -1)" == "$glibc_max" ]] && r=0 || r=1
    check "$f needs glibc ${g:-none} <= $glibc_max" $r
  done
  lepic_tor="$(LC_ALL=C grep -ac 'lepic_tor\|lepic-tor' "$work/x/usr/bin/lib/liblepic_ffi.so" || true)"
  if [[ $tor == 1 ]]; then
    [[ "$lepic_tor" != 0 ]] && r=0 || r=1; check "liblepic_ffi.so has LEPIC's Tor" $r
  else
    [[ "$lepic_tor" == 0 ]] && r=0 || r=1; check "liblepic_ffi.so has no Tor code" $r
  fi
  if [[ -n "$build_id" ]]; then
    [[ "$(LC_ALL=C grep -acF -- "$build_id" "$work/x/usr/bin/lib/libapp.so" || true)" != 0 ]] && r=0 || r=1
    check "build id $build_id in lib/libapp.so" $r
  fi
  if [[ -f "$root/tools/build-inputs.json" ]]; then
    echo "       node epic sha256 $(sha256sum "$work/x/usr/bin/bin/epic" | cut -d' ' -f1)"
  fi
fi
[[ $fail == 0 ]] || { printf '%s\n' "${failed[@]}" >&2; echo "verification FAILED" >&2; exit 1; }
echo "$name verified"
