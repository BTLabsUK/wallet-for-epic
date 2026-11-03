#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Checks a Windows installer without running it, from Linux or Git Bash: the file name, a valid PE
# header, the version resource (ProductName BT Wallet, CompanyName BT Labs, ProductVersion and the
# four-part file version, Inno pads the string with spaces and a NUL), the Inno Setup signature
# and its minor version (tools/build-inputs.json), and with WFE_UNSIGNED=1 / 0 that the Authenticode
# certificate table is empty / present. The installer's contents are compressed, so what only
# build_windows_release.ps1 checks, on Windows, stays there: btwallet.exe's own VersionInfo and
# secure-storage prefix, lepic_ffi.dll's C runtime, the bundled node and Tor, signtool verify.
#
# Usage: app/tool/verify_windows_release.sh <bt-wallet-<version>[-notor]-windows-x64-setup.exe>
# Env:   WFE_TOR=0|1       the build without Tor / with Tor (default 1; only the name differs)
#        WFE_VERSION       the version the files must carry (default: tools/version.sh name)
#        WFE_BUILD_ID      accepted; the id is inside the compressed payload and is not checked here
#        WFE_UNSIGNED=1|0  the installer must carry no / a signature (unset: not checked)
# Needs: python3 (or python). Exit 0 when every check passes; else 1, one line per failed check on
# stderr.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exe="${1:-}"
[[ -f "$exe" ]] || { echo "usage: $0 <setup.exe>" >&2; exit 2; }
py=python3
command -v "$py" >/dev/null || py=python
command -v "$py" >/dev/null || { echo "python3 not found" >&2; exit 1; }
version="${WFE_VERSION:-$("$root/tools/version.sh" name)}"
variant=
[[ "${WFE_TOR:-1}" == 0 ]] && variant=-notor
inno="$(sed -n 's/^ *"innoSetup": *"\([^"]*\)".*/\1/p' "$root/tools/build-inputs.json" 2>/dev/null | head -1)"
# YY.MM.patch.0 (the -rcN of a test build and the build number are not in a VERSIONINFO field).
file_version="${version%%-*}.0"

fail=0 failed=()
check() { # description, condition result (0 = ok)
  if [[ "$2" == 0 ]]; then echo "  ok   $1"; else echo "  FAIL $1"; fail=1; failed+=("FAIL: $1"); fi
}

name="$(basename "$exe")"
echo "$name"
want="bt-wallet-$version$variant-windows-x64-setup.exe"
[[ "$name" == "$want" ]] && r=0 || r=1; check "name $want" $r

# One line per fact: key=value.
facts="$("$py" -I - "$exe" <<'PY'
import re, struct, sys
d = open(sys.argv[1], "rb").read()
print("size=%d" % len(d))
pe = struct.unpack_from("<I", d, 0x3C)[0] if d[:2] == b"MZ" and len(d) > 0x40 else 0
ok = pe and d[pe:pe + 4] == b"PE\0\0"
print("pe=%d" % bool(ok))
if ok:
    opt = pe + 24
    magic = struct.unpack_from("<H", d, opt)[0]
    dd = opt + (96 if magic == 0x10B else 112)
    off, size = struct.unpack_from("<II", d, dd + 4 * 8)
    print("certsize=%d" % size)
i = d.find(b"\xbd\x04\xef\xfe")
if i > 0:
    ms, ls = struct.unpack_from("<II", d, i + 8)
    print("fixed=%d.%d.%d.%d" % (ms >> 16, ms & 0xFFFF, ls >> 16, ls & 0xFFFF))
for k in ("FileVersion", "ProductName", "CompanyName", "ProductVersion"):
    j = d.find(k.encode("utf-16le") + b"\x00\x00")
    if j >= 0:
        # key, NUL, (alignment NUL), value, NUL; Inno pads the value with spaces
        text = d[j + 2 * len(k):j + 2 * len(k) + 400].decode("utf-16le", "ignore").lstrip("\x00")
        print("%s=%s" % (k, text.split("\x00")[0].strip()))
m = re.search(rb"Inno Setup Setup Data \(([0-9.]+)\)", d)
print("inno=%s" % (m.group(1).decode() if m else ""))
PY
)"
get() { sed -n "s/^$1=//p" <<<"$facts" | head -1; }
size="$(get size)"
(( size > 5000000 )) && r=0 || r=1; check "size $size > 5000000" $r
[[ "$(get pe)" == 1 ]] && r=0 || r=1; check "PE header" $r
[[ "$(get ProductName)" == "BT Wallet" ]] && r=0 || r=1; check "ProductName BT Wallet" $r
[[ "$(get CompanyName)" == "BT Labs" ]] && r=0 || r=1; check "CompanyName BT Labs" $r
[[ "$(get ProductVersion)" == "${version%%-*}" ]] && r=0 || r=1; check "ProductVersion ${version%%-*}" $r
[[ "$(get FileVersion)" == "$file_version" ]] && r=0 || r=1; check "FileVersion $file_version" $r
[[ "$(get fixed)" == "$file_version" ]] && r=0 || r=1; check "fixed file version $file_version" $r
iv="$(get inno)"
if [[ -z "$inno" ]]; then
  [[ -n "$iv" ]] && r=0 || r=1; check "Inno Setup signature ($iv)" $r
else
  [[ "$iv" == "$inno" || "$iv" == "$inno".* ]] && r=0 || r=1; check "Inno Setup $inno (installer says ${iv:-none})" $r
fi
case "${WFE_UNSIGNED:-}" in
  1) [[ "$(get certsize)" == 0 ]] && r=0 || r=1; check "not signed (the release signer signs it)" $r ;;
  0) [[ "$(get certsize)" != 0 ]] && r=0 || r=1; check "Authenticode certificate table present" $r ;;
esac
[[ $fail == 0 ]] || { printf '%s\n' "${failed[@]}" >&2; echo "verification FAILED" >&2; exit 1; }
echo "$name verified"
