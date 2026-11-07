#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# G4 update trust, Linux desktop: a user on the previous release updates to the candidate AppImage
# and keeps the wallet, balance, history, their node and Epicbox servers and settings; then (REL_FUNDS=1)
# one receive and one send on the candidate. The real release AppImages run in a sandbox (own HOME,
# Xvfb, dbus, keyring) and are driven over AT-SPI; see linux/lane.py.
#
# Env (the runner's contract):
#   REL_PREVIOUS_DIR, REL_PREVIOUS_VERSION [, REL_PREVIOUS_REF]   previous release folder (bt-wallet-<v>[-notor]-linux-x86_64.AppImage, or the name before it)
#   REL_CANDIDATE_DIR, REL_CANDIDATE_VERSION [, REL_CANDIDATE_SRC] the candidate's files
#   REL_VIA_DIR, REL_VIA_VERSION  optional: a release the user ran in between (opened once, then the candidate)
#   REL_VARIANT tor|notor        REL_CHECKS comma list (default: all eight, plus store_encrypted,app_files_kept,lan_nodes_kept,contact_note_kept for a candidate from 26.10.25; without send_ok,receive_ok when REL_FUNDS=0)
#   REL_FUNDS 1|0                1: also receive from and send to P with the candidate
#   REL_TRUST_MODE create        the create-wallet test instead: the candidate installed fresh, a new wallet
#                                to home, proof create_ok; no previous release, no funds, the phrase dropped
#   REL_TRUST_MODE flow          the same lane on one build: previous and candidate name the run's test build
#                                (release/pipeline.toml flow-*); the update is a reinstall of that build
#   REL_NODE, REL_EPICBOX        servers to use; picked here (BT Labs first) when unset
#   REL_OUT                      proof.json, trust.log, digests, shots/ (debug), screens/ (catalogue: screens.json + PNGs), P logs
#   REL_DRY_RUN=1                print the plan, touch nothing
# Optional: REL_WORK (sandboxes, default ~/.cache/rel-trust-linux), REL_KEEP_FUNDS=1 (REL_FUNDS=0:
# leave the balance in the sandbox wallet instead of sending it back to P), REL_P_TOOL, REL_P_PASS_FILE,
# REL_P_PASS_LINE, REL_P_ADDR, REL_P_SERVICE_DIR (P is the shared P service, tools/rellib/p_service.py: no lock).
# REL_RETURN_EXTRA (EPIC: a lane seed's earlier runs' inflow, sent back to P after this run's own).
#
# Exit: 0 every check in REL_CHECKS true, 1 some false, 2 could not run.
# Never prints a recovery phrase or password: they stay in the sandbox folder (mode 600).
set -uo pipefail
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
: "${REL_OUT:?REL_OUT is required}"
[ "${REL_DRY_RUN:-0}" = 1 ] || mkdir -p "$REL_OUT"
for t in python3 Xvfb dbus-daemon gnome-keyring-daemon xdotool import ssh; do
  command -v "$t" >/dev/null || { [ "${REL_DRY_RUN:-0}" = 1 ] && echo "PLAN missing tool: $t" && continue
    echo "trust-linux: missing tool $t" >&2; exit 2; }
done
if [ "${REL_DRY_RUN:-0}" != 1 ]; then
  python3 -I -c 'import gi; gi.require_version("Atspi", "2.0"); from gi.repository import Atspi; import PIL' 2>/dev/null ||
    { echo "trust-linux: python3 needs gi (Atspi 2.0) and PIL" >&2; exit 2; }
fi
umask 077
# REL_DRY_RUN=1: lane.py prints the plan (the required checks) and touches nothing.
exec python3 -I "$here/linux/lane.py"
