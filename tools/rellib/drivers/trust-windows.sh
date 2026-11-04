#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# G4 update trust, Windows desktop: a user on the previous release updates to the candidate the way the
# in-app updater does (its Setup with /SILENT /NORESTART /UPDATEFROMAPP=1 while the app runs) and keeps
# the wallet, balance, history, their node and Epicbox servers and settings; then (REL_FUNDS=1) one
# receive and one send on the candidate. Runs on the Windows rig as a rig session's user through that
# session's queue (in the background, Windows session 0, a per-user install in a run folder of its own
# under C:\EpicRig<k>\trust); the real app is driven blind and every step is read from its own files;
# see windows/trust.py and windows/rig.py.
#
# Env (the runner's contract):
#   REL_PREVIOUS_DIR, REL_PREVIOUS_VERSION   previous release folder (bt-wallet-<v>[-notor]-windows-x64-setup.exe, or the name before it)
#   REL_CANDIDATE_DIR, REL_CANDIDATE_VERSION the candidate's files
#   REL_VARIANT tor|notor        REL_CHECKS comma list (default: all eight, plus store_encrypted,app_files_kept,lan_nodes_kept,contact_note_kept for a candidate from 26.10.25; without send_ok,receive_ok when REL_FUNDS=0)
#   REL_FUNDS 1|0                1: also receive from and send to P with the candidate
#   REL_TRUST_MODE create        the create-wallet test instead: the candidate installed fresh, a new wallet
#                                to home, proof create_ok; no previous release, no funds, the phrase dropped
#   REL_NODE, REL_EPICBOX        servers to use; picked here (BT Labs first) when unset
#   REL_OUT                      proof.json, trust.log, digests, the app's and Setup's logs, P logs
#   REL_DRY_RUN=1                print the plan, touch nothing
# Optional: REL_WIN_HOST (ssh name of the rig, default windows-pc), REL_WIN_RIG (rig session 1..9:
# task EpicWalletRig<k>, work dir C:\EpicRig<k>; default [host.windows] rigs.<variant> in
# release-hosts.toml (REL_HOSTS), else 1; runs on rigs with the same Windows user wait for each
# other, a lock in ~/.cache/rel-trust-windows/ctl), REL_WORK (local work folders,
# default ~/.cache/rel-trust-windows), REL_KEEP_FUNDS=1, REL_P_TOOL, REL_P_PASS_FILE, REL_P_PASS_LINE,
# REL_P_ADDR, REL_P_SERVICE_DIR (P is the shared P service, tools/rellib/p_service.py: no lock).
# REL_RETURN_EXTRA (EPIC: a lane seed's earlier runs' inflow, sent back to P after this run's own).
# Dead rigs: the rig sessions' health is read first (windows/rig-health.ps1, read-only); a dead session,
# or one that does not pick up the job within REL_WIN_PICKUP_S (default 180 s on an empty queue), is
# skipped for the next in [host.windows] rigs, then 1, and named in one alert (REL_OUT/notice.json).
#
# Exit: 0 every check in REL_CHECKS true, 1 some false, 2 could not run (proof.json written either way).
# Never prints a recovery phrase or password: the wallet password stays in the local work folder (mode
# 600) and the run's secret folder on the rig (BT and epicrig only); a lane seed's phrase is typed one
# word at a time from a file there, deleted as soon as the agent has read it.
set -uo pipefail
# Break tests (core/breaks.py) never run in a release run; the engine sets REL_RUN_KIND=release for one.
if [ "${REL_RUN_KIND:-}" = release ] && [ -n "${REL_TRUST_BREAK:-}" ]; then
  echo "trust-windows: REL_TRUST_BREAK is set in a release run: break tests run in --test runs only" >&2; exit 2
fi
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
: "${REL_OUT:?REL_OUT is required}"
[ "${REL_DRY_RUN:-0}" = 1 ] || mkdir -p "$REL_OUT"
umask 077
for t in python3 ssh scp; do
  command -v "$t" >/dev/null || { [ "${REL_DRY_RUN:-0}" = 1 ] && echo "PLAN missing tool: $t" && continue
    python3 -I "$here/windows/trust.py" fail "missing tool $t" 2>/dev/null; echo "trust-windows: missing tool $t" >&2; exit 2; }
done
if [ "${REL_DRY_RUN:-0}" != 1 ]; then
  host="${REL_WIN_HOST:-windows-pc}"
  timeout 40 ssh -o BatchMode=yes -o ConnectTimeout=15 "$host" "exit" >/dev/null 2>&1 ||
    { python3 -I "$here/windows/trust.py" fail "the Windows rig $host does not answer over ssh"; echo "trust-windows: $host does not answer over ssh" >&2; exit 2; }
fi
# The shared-core lane (windows/lane.py: UI Automation by role and name). REL_TRUST_DRIVER=v1: the key-press
# driver it replaces (windows/trust.py), kept as a fallback; its Setup key path predates 26.10.25's levels.
if [ "${REL_TRUST_DRIVER:-v2}" = v1 ] || [ "${REL_DRY_RUN:-0}" = 1 ]; then exec python3 -I "$here/windows/trust.py"; fi
exec python3 -I "$here/windows/lane.py"
