# SPDX-License-Identifier: Apache-2.0
"""Entry point of tools/rel (python3 -I keeps the user's site and the cwd out of sys.path)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from rellib import pin  # noqa: E402

pin.follow(sys.argv[1:])

from rellib.cli import main  # noqa: E402

sys.exit(main())
