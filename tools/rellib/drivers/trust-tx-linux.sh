#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# TX-1, Linux: two wallets on the candidate AppImage (lane seeds linux-tx-a and linux-tx-b, each in its
# own sandbox) pay each other 0.01 EPIC on mainnet by Epicbox, Link · HTTP, Link · Tor and File, and
# every coin P put in goes back to P in the same run; see linux/tx_lane.py.
#
# Env (the runner's contract):
#   REL_CANDIDATE_DIR, REL_CANDIDATE_VERSION   the candidate's files
#   REL_VARIANT tor              REL_FUNDS 1|0 (0: no payments, no check required; leftovers still go back)
#   REL_NODE, REL_EPICBOX        servers to use; picked here when unset (the local node when healthy)
#   REL_OUT                      proof.json (details.money: what P sent, what came back, the fees), trust.log
#   REL_TX_METHODS               optional comma list (default epicbox,http,tor,file)
#   REL_TX_PART                  optional payments|pairing|linking: that part alone, from the saved state;
#                                unset: the whole lane
#   REL_TRUST_UNTIL              optional, --test runs: stop after that phase
# Optional: REL_WORK (sandboxes, default ~/.cache/rel-trust-linux), REL_TRUST_SAVE_STATE=0, REL_P_TOOL, REL_P_PASS_FILE,
# REL_P_PASS_LINE, REL_P_ADDR, REL_P_SERVICE_DIR.
#
# Exit: 0 every check true, 1 some false or a product fault, 2 could not run.
# Never prints a recovery phrase or password: they go to the test DB only.
set -uo pipefail
here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
: "${REL_OUT:?REL_OUT is required}"
mkdir -p "$REL_OUT"
for t in python3 Xvfb dbus-daemon dbus-send gnome-keyring-daemon xdotool import; do
  command -v "$t" >/dev/null || { echo "trust-tx-linux: missing tool $t" >&2; exit 2; }
done
python3 -I -c 'import gi; gi.require_version("Atspi", "2.0"); gi.require_version("Gio", "2.0"); from gi.repository import Atspi, Gio; import PIL' 2>/dev/null ||
  { echo "trust-tx-linux: python3 needs gi (Atspi 2.0, Gio) and PIL" >&2; exit 2; }
umask 077
exec python3 -I "$here/linux/tx_lane.py"
