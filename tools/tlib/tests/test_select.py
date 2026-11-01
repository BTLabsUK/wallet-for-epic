# SPDX-License-Identifier: Apache-2.0
"""tools/t's test selection: the import graph (tlib/graph.py) and the rules on top (tlib/select.py).
    python3 -m unittest discover -s tools/tlib/tests"""
import os
import shutil
import unittest

import support
from tlib import graph as g, select as s


class GraphTest(unittest.TestCase):
    def setUp(self):
        self.root = support.make_app()
        self.addCleanup(shutil.rmtree, self.root)
        self.g = g.Graph(self.root, support.files_of(self.root))

    def test_directives_stop_at_the_first_declaration(self):
        heads, _ = g.directives("// c\nimport 'a.dart';\nimport 'b.dart'\n    show B;\n\nclass X {}\nimport 'c.dart';\n")
        self.assertEqual([u for h in heads for u in g.uris(h)], ["a.dart", "b.dart"])

    def test_package_relative_conditional_and_part_edges(self):
        e = self.g.edges
        self.assertIn("app/lib/src/model.dart", e["app/lib/src/ui/home.dart"])
        self.assertEqual(e["app/lib/src/web.dart"], {"app/lib/src/web_io.dart", "app/lib/src/web_web.dart"})
        self.assertIn("app/lib/src/ui/send_parts.dart", e["app/lib/src/ui/send.dart"])
        self.assertIn(g.PKG_LEPIC, e["app/lib/src/lepic_adapter.dart"])

    def test_an_import_inside_a_string_is_not_an_edge(self):
        self.assertNotIn("app/lib/src/ui/home.dart", self.g.closure("app/test/send_test.dart"))

    def test_closure_is_transitive_and_includes_the_test_config(self):
        clo = self.g.closure("app/test/home_test.dart")
        for f in ("app/lib/src/model.dart", "app/lib/src/web_io.dart", "app/test/flutter_test_config.dart",
                  "app/test/support/settings.dart"):
            self.assertIn(f, clo)

    def test_data_literals(self):
        _, files, dirs = self.g.deps("app/test/l10n_test.dart")
        self.assertIn("app/lib/l10n", dirs)  # Directory('lib/l10n') and the interpolated path
        _, files, _ = self.g.deps("app/test/desktop/node_test.dart")
        self.assertIn("app/test/desktop/goldens/node.png", files)  # relative to the test
        _, files, _ = self.g.deps("app/test/home_test.dart")
        self.assertIn("app/assets/config/defaults.toml", files)  # through the screen it imports
        _, _, dirs = self.g.deps("app/test/fixture_test.dart")
        self.assertIn("app/test/fixtures/install", dirs)

    def test_hit(self):
        self.assertEqual(self.g.hit("app/test/home_test.dart", {"app/lib/src/model.dart"}), "app/lib/src/model.dart")
        self.assertIsNone(self.g.hit("app/test/send_test.dart", {"app/lib/src/web_io.dart"}))
        self.assertTrue(self.g.hit("app/test/fixture_test.dart", {"app/test/fixtures/install/data.json"}))
        self.assertTrue(self.g.hit("app/test/gone_test.dart", {"app/lib/src/removed.dart"}))


class SelectTest(unittest.TestCase):
    def setUp(self):
        self.root = support.make_app(git=True)
        self.addCleanup(shutil.rmtree, self.root)

    def pick(self, changed, base=None):
        return s.select(self.root, changed, base=base, sentinels=False)

    def test_a_screen_change_selects_its_tests_only(self):
        sel = self.pick(["app/lib/src/ui/home.dart"])
        self.assertEqual(set(sel.tests), {"app/test/home_test.dart"})
        self.assertEqual(sel.tests["app/test/home_test.dart"], "app/lib/src/ui/home.dart")

    def test_a_model_change_selects_every_importer(self):
        sel = self.pick(["app/lib/src/model.dart"])
        self.assertEqual(set(sel.tests), {"app/test/home_test.dart", "app/test/send_test.dart",
                                          "app/test/lepic_test.dart"})

    def test_the_test_config_reaches_every_test(self):
        sel = self.pick(["app/test/support/settings.dart"])
        self.assertEqual(len(sel.tests), len(g.Graph(self.root, support.files_of(self.root)).tests()))

    def test_pubspec_runs_everything(self):
        sel = self.pick(["app/pubspec.lock"])
        self.assertTrue(sel.full)
        self.assertIn("app/test/desktop/bye_test.dart", sel.tests)

    def test_a_lepic_pin_selects_the_tests_that_reach_the_binding(self):
        sel = self.pick(["tools/lepic.rev"])
        self.assertEqual(sel.tests, {"app/test/lepic_test.dart": "tools/lepic.rev"})

    def test_generated_strings_do_not_reach_every_screen(self):
        sel = self.pick(["app/lib/l10n/app_localizations.dart"])
        self.assertNotIn("app/test/home_test.dart", sel.tests)
        self.assertIn("app/test/l10n_test.dart", sel.tests)

    def test_a_string_change_selects_the_l10n_tests_and_the_tests_that_name_it(self):
        support.write(self.root, "app/lib/l10n/app_en.arb",
                      '{"hello": "Hello, friend", "@hello": {"description": "x"}, "bye": "Bye!"}\n')
        base = s.merge_base(self.root, "main")
        changed = s.changed_files(self.root, base)
        self.assertEqual(changed, ["app/lib/l10n/app_en.arb"])
        sel = self.pick(changed, base=base)
        self.assertIn("app/test/l10n_test.dart", sel.tests)  # reads lib/l10n
        self.assertIn("app/test/home_test.dart", sel.tests)  # checks the old English text
        self.assertIn("app/test/desktop/bye_test.dart", sel.tests)  # names the key `bye`
        self.assertNotIn("app/test/desktop/node_test.dart", sel.tests)  # `byeKey` is another word

    def test_changed_files_include_untracked_ones(self):
        support.write(self.root, "app/test/new_test.dart", "import 'package:epic_wallet/src/model.dart';\n")
        base = s.merge_base(self.root, "main")
        self.assertIn("app/test/new_test.dart", s.changed_files(self.root, base))
        self.assertIn("app/test/new_test.dart", self.pick(["app/test/new_test.dart"]).tests)

    def test_unrelated_changes_select_nothing_but_the_sentinels(self):
        sel = s.select(self.root, ["docs/TESTING.md", "bot/x.py", "app/analysis_options.yaml"])
        self.assertEqual(sel.tests, {"app/test/l10n_test.dart": "sentinel"})  # the one sentinel here
        self.assertTrue(any("analysis_options" in n for n in sel.notes))

    def test_the_sentinels_exist_in_the_repository(self):
        root = os.path.dirname(support.TOOLS)
        for t in s.SENTINELS:
            self.assertTrue(os.path.exists(os.path.join(root, t)), t)


class RealRepoTest(unittest.TestCase):
    """The graph of this checkout: fast, and the test config stays small."""

    def test_graph_of_the_repository(self):
        import time
        root = os.path.dirname(support.TOOLS)
        if not os.path.isdir(os.path.join(root, ".git")) and not os.path.isfile(os.path.join(root, ".git")):
            self.skipTest("not a checkout")
        t0 = time.time()
        gr = g.Graph(root, s.repo_files(root))
        tests = gr.tests()
        self.assertGreater(len(tests), 100)
        self.assertLess(time.time() - t0, 5)
        cfg = [f for f in gr.closure("app/test/flutter_test_config.dart") if f.startswith("app/lib/")]
        self.assertLess(len(cfg), 80, "test/flutter_test_config.dart reaches too much of lib/: every "
                        "change to those files would select every test")


if __name__ == "__main__":
    unittest.main()
