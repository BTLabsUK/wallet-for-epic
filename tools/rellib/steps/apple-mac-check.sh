#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# The Mac's signed, notarised .dmg, checked on Linux before it can ship: its .sha256 and the
# REPORT agree with the file, the REPORT names the release commit and BT Labs' Team ID (on the
# dmg and on the app in it), and Gatekeeper accepted both as notarised Developer ID. Then the dmg
# goes to the step's out folder (the runner moves it into files/).
# The Mac builds from GitHub, whose ids differ from the local ones (tools/publish-github.sh
# rewrites the history), so the REPORT's commit may also be the run's commit as published:
# its line in $PUBLISH_DIR/wallet-for-epic.commit-map (default ~/publish).
# Usage: apple-mac-check.sh <results dir> <dmg name> <commit> <team id> <out dir>
set -euo pipefail
res="${1:?results dir}" dmg="${2:?dmg name}" commit="${3:?commit}" team="${4:-}" out="${5:?out dir}"
report="$res/${dmg%.dmg}.REPORT.txt"
fail() { echo "apple-mac-check: $*" >&2; exit 1; }
[[ -n "$team" && "$team" != "<unset"* ]] || fail "no Team ID: set [host.apple] team_id in release-hosts.toml"
for f in "$res/$dmg" "$res/$dmg.sha256" "$report"; do [[ -f "$f" ]] || fail "missing $(basename "$f")"; done
sum="$(sha256sum "$res/$dmg" | cut -d' ' -f1)"
[[ "$(cut -d' ' -f1 "$res/$dmg.sha256")" == "$sum" ]] || fail "$dmg.sha256 does not match the dmg"
grep -Eq "^sha256:[[:space:]]+$sum\$" "$report" || fail "the REPORT's sha256 is not the dmg's ($sum)"
cmap="${PUBLISH_DIR:-$HOME/publish}/wallet-for-epic.commit-map"
published="$( [[ -f "$cmap" ]] && awk -v c="$commit" '$1 == c { print $2; exit }' "$cmap" || true)"
said="$(sed -n 's/^commit:[[:space:]]*//p' "$report" | head -1)"
[[ -n "$said" && ( "$said" == "$commit" || "$said" == "$published" ) ]] \
  || fail "the REPORT's commit ${said:-(none)} is not $commit${published:+ or its GitHub id $published}"
n="$(grep -c "TeamIdentifier=$team\$" "$report" || true)"
(( n >= 2 )) || fail "TeamIdentifier=$team on the dmg and the app: found $n of 2"
if grep -E "^TeamIdentifier=" "$report" | grep -vq "=$team\$"; then fail "another TeamIdentifier in the REPORT"; fi
n="$(grep -c "accepted" "$report" || true)"; m="$(grep -c "source=Notarized Developer ID" "$report" || true)"
(( n >= 2 && m >= 2 )) || fail "Gatekeeper: accepted $n, Notarized Developer ID $m (want both on the dmg and the app)"
cp -f "$res/$dmg" "$out/$dmg"
echo "ok: $dmg $sum, commit $said, Team ID $team, Gatekeeper accepted (notarised)"
