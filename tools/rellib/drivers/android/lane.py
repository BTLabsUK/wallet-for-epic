#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The Android G4 lane on the shared core (core/lane.py): android_platform.py for the emulator and the
`adb install -r` update, core/phone.py on uiautomator for the screens, core/checks.py on the wallet's
files; the entry itself is core/phone_lane.py's. Called by ../trust-android.sh with the REL_* environment
(see there)."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

from android_platform import AndroidPlatform  # noqa: E402
from core import checks, phone_lane  # noqa: E402,F401  (checks: read by the restore tests)
from core.phone_lane import create_mode, keep_secrets, required  # noqa: E402,F401

NOT_CHECKED = {}  # every check is made on Android: settings_kept reads Settings (Platform.settings_from_ui)


def fail_closed(reason):
    """trust-android.sh could not start the lane: result.txt and a proof.json with every required check false."""
    return phone_lane.fail_closed("android", reason)


def proof_extra(plat):
    return {"signer": plat.certs, "emulator": plat.health}


if __name__ == "__main__":
    sys.exit(phone_lane.cli("android", AndroidPlatform, proof_extra, NOT_CHECKED))
