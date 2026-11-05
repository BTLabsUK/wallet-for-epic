#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The iOS G4 lane on the shared core (core/lane.py): ios_platform.py for the Simulator on a Mac and the
`simctl install` update, core/phone.py on WebDriverAgent for the screens, core/checks.py on the wallet's
files; the entry itself is core/phone_lane.py's. Called by ../trust-ios.sh with the REL_* environment
(see there)."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

from core import phone_lane  # noqa: E402
from ios_platform import IosPlatform  # noqa: E402

NOT_CHECKED = {}  # every check is made: settings_kept reads Settings (Platform.settings_from_ui)


def fail_closed(reason):
    """trust-ios.sh could not start the lane: result.txt and a proof.json with every required check false."""
    return phone_lane.fail_closed("ios", reason)


def proof_extra(plat):
    return {"signer": plat.certs, "simulator": plat.health}


if __name__ == "__main__":
    sys.exit(phone_lane.cli("ios", IosPlatform, proof_extra, NOT_CHECKED))
