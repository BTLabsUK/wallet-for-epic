#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# E4 step 2: what the stock CLI says when a SECOND answer to a payment arrives. Two receiver wallets
# (R1, R2: the same seed, i.e. two installs of one wallet) each answer the same slate file; the sender
# finalizes the first answer and is then given the second. Needs E4_CLI_DIR (the sender, funded),
# and R1/R2 made as copies of one stock wallet (see the report). Prints the CLI's refusal.
set -u
CLI=${E4_CLI_BIN:-$HOME/epic/qa-funder/bin/epic-wallet}; W=${E4_WORK:?folder holding cli/ r1/ r2/}
export EPIC_WALLET_PASS=$(cat "$W/cli/.password")
(cd "$W/cli" && "$CLI" --floonet -t . send -m file -d "$W/s.tx" 1 >/dev/null 2>&1)
for r in r1 r2; do (cd "$W/$r" && "$CLI" --floonet -t . receive -i ../s.tx >/dev/null 2>&1; mv ../s.tx.response "../$r.resp"); done
cd "$W/cli"
for r in r1 r2; do echo "== finalize answer from $r"; "$CLI" --floonet -t . finalize -i "../$r.resp" 2>&1 | grep "ERROR\|Error\|completed successfully\|sent successfully" | cut -c1-300; done
