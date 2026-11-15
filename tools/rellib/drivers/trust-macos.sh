#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# G4 update trust, macOS desktop: a user on the previous release updates to the candidate (the app quit,
# its bundle replaced, as the dmg's drag does) and keeps the wallet, balance, history, their node and
# Epicbox servers and settings; then (REL_FUNDS=1) one receive and one send on the candidate. Driven
# over ssh on a Mac (REL_MAC_SSH) in a run folder of its own under the lane folder (REL_MAC_LANE): the
# app has its own HOME and a throwaway keychain there, its window shows on the Mac's screen and is read
# and pressed through the Accessibility helper (macos/axhelper.swift, running in its own terminal pane);
# see macos/lane.py and macos/macos_platform.py.
#
# Env (the runner's contract):
#   REL_PREVIOUS_DIR, REL_PREVIOUS_VERSION   previous release folder (bt-wallet-<v>[-notor]-macos.dmg, in it or its macos/)
#   REL_CANDIDATE_DIR, REL_CANDIDATE_VERSION the candidate's files: the dmg, or a test build
#                                (bt-wallet-<id>-<variant>-macos.tar or .zip, or BT Wallet.app)
#   REL_VARIANT tor|notor        REL_CHECKS comma list (default: all eight, plus the migration checks for a
#                                candidate that encrypts the store; without send_ok,receive_ok when REL_FUNDS=0)
#   REL_FUNDS 1|0                1: also receive from and send to P with the candidate
#   REL_TRUST_MODE create        the create-wallet test instead: the candidate installed fresh, a new wallet,
#                                proof create_ok; no previous release, no funds
#   REL_TRUST_MODE flow          the same lane on one build: previous and candidate name the run's test build
#   REL_NODE, REL_EPICBOX        servers to use; picked here (BT Labs first) when unset
#   REL_OUT                      proof.json, trust.log, digests, the app's logs, macos.json, P logs
#   REL_DRY_RUN=1                print the plan, touch nothing
# Optional: REL_MAC_SSH (ssh name of the Mac; else ssh under [host.apple] in the release
# hosts file, REL_HOSTS or ~/.config/btlabs/release-hosts.toml), REL_MAC_TERM (the terminal program on the Mac whose
# panes run the app and the AX helper; else mac_term under [host.apple]), REL_MAC_LANE (the lane folder
# on the Mac, default ~/wfe-lanes/macos: bin/wfe-axhelper, ax.sock, run/<run>), REL_PREVIOUS_APP and
# REL_CANDIDATE_APP (a build file or app here, or mac:<path> for an app already on the Mac, instead of the
# folder's), REL_MAC_KEEP=1 (leave the app up and the run's apps in place), REL_P_TOOL, REL_P_PASS_FILE,
# REL_P_PASS_LINE, REL_P_LOCK.
#
# Signing: an ad hoc candidate after a Developer ID release is signed with the Developer ID on the Mac
# (build.keychain) before anything starts, so the app opens its keychain items without a prompt.
# A system dialog on the Mac's screen (keychain, Gatekeeper, privacy) fails the run at once: the app is
# stopped and the dialog cancelled. Before the run the first build is started once on a home of its own
# to see that none comes up.
#
# Exit: 0 every check in REL_CHECKS true, 1 some false, 2 could not run (proof.json written either way).
# Never prints a recovery phrase or password.
set -uo pipefail
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
: "${REL_OUT:?REL_OUT is required}"
[ "${REL_DRY_RUN:-0}" = 1 ] || mkdir -p "$REL_OUT"
umask 077
for t in python3 ssh; do
  command -v "$t" >/dev/null || { [ "${REL_DRY_RUN:-0}" = 1 ] && echo "PLAN missing tool: $t" && continue
    python3 -I "$here/macos/lane.py" fail "missing tool $t" 2>/dev/null; echo "trust-macos: missing tool $t" >&2; exit 2; }
done
if [ "${REL_DRY_RUN:-0}" != 1 ]; then
  host="$(python3 -I -c 'import sys; sys.path.insert(0, sys.argv[1]); import macos_platform as m; print(m.mac_host_name())' "$here/macos" 2>/dev/null)"
  [ -n "$host" ] || { python3 -I "$here/macos/lane.py" fail "no Mac named: set REL_MAC_SSH, or ssh under [host.apple] in the release hosts file"; echo "trust-macos: no Mac named (REL_MAC_SSH or [host.apple] ssh)" >&2; exit 2; }
  timeout 40 ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" "exit" >/dev/null 2>&1 ||
    { python3 -I "$here/macos/lane.py" fail "the Mac $host does not answer over ssh"; echo "trust-macos: $host does not answer over ssh" >&2; exit 2; }
fi
exec python3 -I "$here/macos/lane.py"
