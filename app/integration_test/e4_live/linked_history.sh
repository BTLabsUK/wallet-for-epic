#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# E4 linked history, the live check of "one row per payment" on a linked pair (floonet; or the
# tester's real pair for step 4). Run by hand after e4_live.sh steps 0-2 (both apps built from the
# RC, one wallet, linked; the floonet miner running; the stock CLI wallet C from cli_pay.sh as the
# third wallet). Kernel lookups need the RC pinned to a LEPIC with EpicWallet.kernel_on_chain and
# lepic_wallet_service.dart's "Kernel lookup (devhist)" stub wired; without it steps 1-3 still
# pass through the coins and the change, step 3c then waits for the 1,440-block fallback.
# Desktop: dk.py (AT-SPI); phone: ph.sh (wfe_qa, emulator-5556 only). Read each row's title,
# amount and status on BOTH devices: the history list, its details page, and the Home "Recent
# activity" list on the phone.
#
#  1 phone pays C    C: its address (epic-wallet --floonet -t <C> address). Phone: Send 0.1 to it
#                    over Epicbox (C's listener finalizes). At once, on the desktop: ONE row,
#                    "Sent from <phone name>  -0.1", status Waiting for a block. After the next
#                    block: Confirming 1/10 ... then Sent. Phone: its own row only, Sent.
#                    PASS when, from the send until 10 blocks after it, neither device ever shows a
#                    "Received on <phone>" or "Received by another device" row for the change (the
#                    rest of the 3 EPIC coin, about 2.9 EPIC), and the desktop row's details show
#                    the change among its outputs. Do it 3 times: a desktop scan that sees the
#                    block before its refresh sees the coins go is the case that split the row
#                    (26.10.24-r2: "+121.2180 Received on Mobile P7").
#  2 desktop pays C  The same the other way round: desktop sends 0.5 to C; the phone shows one
#                    "Sent from <desktop name>" row that confirms. No receive row on either.
#  3 cancel, resend  a) Stop C's listener. Desktop: Send 1.0 to C (it waits for C). Phone: "Sent
#                       from <desktop>", Waiting for recipient, its coins held (Home: held line).
#                    b) Desktop: Cancel it, then start C's listener and Send 1.0 to C again (LEPIC
#                       reuses the freed coin). Phone: the first row Cancelled (struck-through
#                       amount), the second follows Waiting for a block -> Confirming -> Sent.
#                       Exactly two rows for these payments on the phone, one on the desktop side.
#                    c) Once more with the phone offline (airplane mode) through the cancel and the
#                       resend; then online. Within a block of the resend confirming, the first
#                       reads Cancelled (the coin went into the second), the second Sent. Then
#                       once more where the resend spends another coin (split the desktop's
#                       coins first; the resend's details list its inputs): the first ends
#                       (Expired) about 60 blocks after it was posted, its coin free again.
#  4 old rows        On a pair still on 26.10.24-r2 with rows like the report's ("Sent from Desktop
#                    -1.0 Confirming 0/4 28 Oct", "Received on Mobile P7 +121.2180", "Sent from
#                    Mobile P7 -0.1 Waiting for a block"): update both to the RC, open each wallet
#                    once and wait one sync (5 s) and one block. PASS: every stuck row resolves
#                    (Sent with its confirmations when its kernel is on chain; Cancelled when its
#                    coin went into another payment; Expired when posted over an hour ago and not
#                    mined, its coin free again), and the change rows are gone into their sends.
#                    No file names change in the data folder; the devices record keeps its keys.
#  end               pm2 delete floo-miner; stop C's listener.
echo "see the header; run the steps by hand with dk.py, ph.sh and cli_pay.sh" >&2
