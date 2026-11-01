#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# E4, the live linked-devices test on floonet: Linux desktop (debug, trust-linux sandbox, AT-SPI) and
# the phone (wfe_qa, debug APK, uiautomator) on ONE wallet, plus a stock epic-wallet CLI as the payer.
# The steps are run by hand in this order; each helper here is a script of its own:
#
#  0 build   flutter build linux --debug -t lib/main_desktop.dart --dart-define=WFE_DEV_NETWORKS=true
#            flutter build apk --debug --target-platform android-x64 --dart-define=WFE_DEV_NETWORKS=true
#            (the default Linux target is the PHONE app; the desktop needs -t lib/main_desktop.dart)
#            app/tool/dev_settings.sh floonet <sandbox>/home/.epic_cash_desktop   (desktop; phone_restore.sh does the phone)
#            pm2 start /opt/epic/floo-miner/ecosystem.config.cjs   ...and pm2 delete floo-miner at the end
#  1 setup   tools/rellib/drivers/linux/sandbox.py start|app; dk.py: Deep end, Network and folder > Floonet,
#            Create a new wallet, password, reveal phrase, written down, Skip setup, Unlock; phone_restore.sh
#            restores the same phrase (PHRASE_FILE, never printed)
#  2 link    desktop: Settings > This wallet > Linked devices > Open, Link a device, Copy invite; clip.py reads
#            it; adb shell am start -a android.intent.action.VIEW -d '<invite>' <phone package> stands in for
#            the scan (the emulator camera sees no screen). Both sides show Linking... then Linked to <name>.
#  3 pay     cli_pay.sh <address> 1 (the CLI wallet's own listener finalizes); cli_double_answer.sh: the CLI's
#            wording of a second answer
#  4 replace phone: Settings > This wallet > Delete wallet (airplane mode on, so the desktop keeps the phone),
#            restore (phone_restore.sh steps), phone shows its invite, desktop pastes it into Send > To:
#            "A device is linked already." Replace <name>?; then link again as in 2
#  5 listen  bg_listen.sh (ADDR_FILE=<file with the shared address>): CLI sends at 1/5/15/30/60 minutes with the
#            phone in the background, screen off, unplugged
#
# Expected: a request to pair the linked device passed on is kept in memory only on the device that got
# it that way: after that device restarts it is gone there until the sender sends a newer request.
echo "see the header; run the helpers one by one" >&2
