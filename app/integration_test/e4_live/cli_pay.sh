#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# cli_pay.sh <addr> <amount> [msg]: stock epic-wallet 4.5.0 (floonet) sends over epicbox; its listener (listen.log) finalizes
cd "${E4_CLI_DIR:-$TMPDIR/cli}" && EPIC_WALLET_PASS="$(cat .password)" timeout 120 "${E4_CLI_BIN:-$HOME/epic/qa-funder/bin/epic-wallet}" --floonet -t . send -m epicbox -d "$1" ${3:+-g "$3"} "$2" 2>&1 | grep "Tx created\|ERROR\|Error" | cut -c1-200
