#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# A file of the Mac's ad-hoc build (pipeline step apple-adhoc: the .dmg signed ad hoc, or the
# unsigned .ipa), checked on Linux before it can ship: SHA256SUMS lists it with its sha256,
# results.txt shows release-check PASS at the release commit and version, and no step FAILed.
# Then the file goes to the step's out folder (the runner moves it into files/).
# Usage: apple-adhoc-check.sh <results dir> <file name> <commit> <version> <out dir>
set -euo pipefail
res="${1:?results dir}" name="${2:?file name}" commit="${3:?commit}" version="${4:?version}" out="${5:?out dir}"
fail() { echo "apple-adhoc-check: $*" >&2; exit 1; }
for f in "$res/$name" "$res/SHA256SUMS" "$res/results.txt"; do [[ -f "$f" ]] || fail "missing $(basename "$f")"; done
sum="$(sha256sum "$res/$name" | cut -d' ' -f1)"
grep -Eq "^$sum[[:space:]]+\*?$name\$" "$res/SHA256SUMS" || fail "SHA256SUMS has no line $sum $name"
grep -Eq "^PASS release-check ${commit:0:9} $version " "$res/results.txt" \
  || fail "results.txt has no 'PASS release-check ${commit:0:9} $version': not built from the release commit"
if grep -q "^FAIL " "$res/results.txt"; then fail "results.txt: $(grep -m1 '^FAIL ' "$res/results.txt")"; fi
case "$name" in
  *.dmg) step=dmg ;;
  *.ipa) step=ipa ;;
  *) fail "$name: neither a .dmg nor an .ipa" ;;
esac
grep -Eq "^PASS $step $name " "$res/results.txt" || fail "results.txt has no 'PASS $step $name'"
cp -f "$res/$name" "$out/$name"
echo "ok: $name $sum, commit ${commit:0:9}, version $version (ad hoc: not notarised / unsigned)"
