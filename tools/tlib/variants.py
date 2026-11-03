# SPDX-License-Identifier: Apache-2.0
"""Build variants the tests read at compile time, and the test files that need a second pass.

`--dart-define=WFE_TOR=false` builds the variant without Tor (app/lib/src/tor_build.dart:
`torBuilt`). A test file that reads `torBuilt` runs in both builds; `tools/t full` runs the
default build over every file, then this variant over the files from notor_tests().
"""
import os
import re

NOTOR_DEFINE = "WFE_TOR=false"
_READS_TOR = re.compile(r"torBuilt|tor_build\.dart")
_IMPORT = re.compile(r"""(?:import|export)\s+['"]([^'"]+)['"]""")


def _text(root, rel):
    try:
        with open(os.path.join(root, rel), encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return ""


def notor_tests(root, repo_files):
    """Repo-relative test files (app/test/**/*_test.dart) that read `torBuilt`: their text names
    torBuilt or tor_build.dart, or they import a helper under app/test/ whose text does (the signed
    update helper, test/support/signed_update.dart). Found at run time, from the files themselves."""
    tests = [p for p in repo_files if p.startswith("app/test/") and p.endswith("_test.dart")]
    helpers = {p for p in repo_files if p.startswith("app/test/") and p.endswith(".dart")
               and not p.endswith("_test.dart") and _READS_TOR.search(_text(root, p))}
    helper_names = {p[len("app/test/"):] for p in helpers}
    out = []
    for t in sorted(tests):
        text = _text(root, t)
        if _READS_TOR.search(text):
            out.append(t)
            continue
        for uri in _IMPORT.findall(text):
            if uri.startswith("package:") or uri.startswith("dart:"):
                continue
            target = os.path.normpath(os.path.join(os.path.dirname(t), uri)).replace(os.sep, "/")
            if target in helpers or any(target.endswith("/" + h) for h in helper_names):
                out.append(t)
                break
    return out
