# SPDX-License-Identifier: Apache-2.0
"""The drivers' line to the test DB (tools/rellib/testdb): events through its inbox queue.
A no-op when the DB package is missing; never raises, never blocks a lane."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
try:
    from testdb import client as _client
except Exception:  # noqa: BLE001 - the DB is optional for a lane
    _client = None


def emit(event, /, **fields):
    """Positional-only: events carry a field named kind (wallet.address)."""
    if _client is None:
        return
    try:
        _client.emit(event, source="driver", **fields)
    except Exception:  # noqa: BLE001
        pass


def read():
    """A read-only connection to the DB, or None."""
    if _client is None:
        return None
    try:
        return _client.read()
    except Exception:  # noqa: BLE001
        return None
