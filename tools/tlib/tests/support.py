# SPDX-License-Identifier: Apache-2.0
"""Fixtures for tools/t's tests: a small fake app in a temporary folder.

Run them from the repository root (tools/check.sh does when tools/ changed, and in --full):
    python3 -m unittest discover -s tools/tlib/tests
without -t: this folder is not a package and the tests import support from it."""
import os
import subprocess
import sys
import tempfile
import textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, TOOLS)


def write(root, rel, text):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(textwrap.dedent(text).lstrip("\n"))


# A fake app: two screens over a model, a lepic adapter, tests for each, a golden, fixtures.
APP = {
    "app/pubspec.yaml": "name: epic_wallet\n",
    "app/pubspec.lock": "packages: {}\n",
    "app/lib/src/model.dart": "class Model {}\n",
    "app/lib/src/web_io.dart": "const io = 1;\n",
    "app/lib/src/web_web.dart": "const io = 2;\n",
    "app/lib/src/web.dart": "export 'web_io.dart' if (dart.library.js_interop) 'web_web.dart';\n",
    "app/lib/src/lepic_adapter.dart": """
        import 'package:lepic/lepic.dart' as lepic;
        import 'model.dart';
        """,
    "app/lib/src/ui/home.dart": """
        // SPDX-License-Identifier: Apache-2.0
        import 'package:flutter/material.dart';

        import '../model.dart';
        import '../web.dart'
            show io;
        const asset = 'assets/config/defaults.toml';
        """,
    "app/lib/src/ui/send.dart": """
        import 'package:epic_wallet/src/model.dart';
        part 'send_parts.dart';
        final s = '''
        import 'package:epic_wallet/src/ui/home.dart';
        ''';
        """,
    "app/lib/src/ui/send_parts.dart": "part of 'send.dart';\nimport_this_is_not = 1;\n",
    "app/lib/l10n/app_en.arb": '{"hello": "Hello there, friend", "@hello": {"description": "x"}, "bye": "Bye"}\n',
    "app/lib/l10n/app_de.arb": '{"hello": "Hallo, Freund", "bye": "Tschüss"}\n',
    "app/lib/l10n/app_localizations.dart": "abstract class AppLocalizations {}\n",
    "app/assets/config/defaults.toml": "a = 1\n",
    "app/test/flutter_test_config.dart": "import 'support/settings.dart';\n",
    "app/test/support/settings.dart": "const x = 1;\n",
    "app/test/home_test.dart": """
        import 'package:epic_wallet/src/ui/home.dart';
        import 'package:epic_wallet/l10n/app_localizations.dart';
        void main() { expect(find.text('Hello there, friend'), findsOne); }
        """,
    "app/test/send_test.dart": "import 'package:epic_wallet/src/ui/send.dart';\n",
    "app/test/lepic_test.dart": "import 'package:epic_wallet/src/lepic_adapter.dart';\n",
    "app/test/l10n_test.dart": "final dir = Directory('lib/l10n');\nfinal en = 'lib/l10n/app_$code.arb';\n",
    "app/test/fixture_test.dart": "final d = 'test/fixtures/install';\n",
    "app/test/fixtures/install/data.json": "{}\n",
    "app/test/desktop/node_test.dart": """
        void main() { expectLater(x, matchesGoldenFile('goldens/node.png')); l.byeKey; }
        """,
    "app/test/desktop/goldens/node.png": "png",
    "app/test/desktop/bye_test.dart": "void main() { l.bye; }\n",
    "app/test/gone_test.dart": "import 'package:epic_wallet/src/removed.dart';\n",
    "tools/lepic.rev": "abc\n",
}


def make_app(extra=None, git=False):
    """A temporary repository holding APP (plus `extra`); with `git`, committed on main."""
    root = tempfile.mkdtemp(prefix="tlib-test-")
    for rel, text in {**APP, **(extra or {})}.items():
        write(root, rel, text)
    if git:
        run = lambda *a: subprocess.run(["git", "-C", root, *a], check=True, capture_output=True)  # noqa: E731
        run("init", "-q", "-b", "main")
        run("-c", "user.email=t@t", "-c", "user.name=t", "add", "-A")
        run("-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", "base")
    return root


def files_of(root):
    out = []
    for d, _, names in os.walk(root):
        if "/.git/" in d.replace(os.sep, "/") + "/":
            continue
        for n in names:
            out.append(os.path.relpath(os.path.join(d, n), root).replace(os.sep, "/"))
    return sorted(out)
