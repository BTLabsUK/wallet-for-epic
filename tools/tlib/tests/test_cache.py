# SPDX-License-Identifier: Apache-2.0
"""tools/t's result cache key (tlib/cache.py).
    python3 -m unittest discover -s tools/tlib/tests"""
import os
import shutil
import tempfile
import unittest

import support
from tlib import cache, graph as g


class KeyTest(unittest.TestCase):
    def setUp(self):
        self.root = support.make_app()
        self.addCleanup(shutil.rmtree, self.root)
        self.flutter = tempfile.mkdtemp(prefix="tlib-flutter-")
        self.addCleanup(shutil.rmtree, self.flutter)
        support.write(self.flutter, "bin/cache/flutter.version.json", '{"frameworkVersion": "3.47.5"}')
        support.write(self.flutter, "bin/cache/dart-sdk/version", "3.13.4")

    def key(self, test="app/test/home_test.dart", env=None, defines=(), name=None):
        files = support.files_of(self.root)
        gr = g.Graph(self.root, files)
        ctx = cache.context_key(self.root, env or {}, self.flutter, defines, name)
        return cache.file_key(ctx, cache.Hasher(self.root, files), *gr.deps(test))

    def test_stable(self):
        self.assertEqual(self.key(), self.key())

    def test_a_file_in_the_closure_changes_it(self):
        k = self.key()
        support.write(self.root, "app/lib/src/model.dart", "class Model { int x = 1; }\n")
        self.assertNotEqual(self.key(), k)

    def test_a_file_outside_the_closure_does_not(self):
        k = self.key()
        support.write(self.root, "app/lib/src/ui/send.dart", "// another screen\n")
        support.write(self.root, "docs/x.md", "words\n")
        self.assertEqual(self.key(), k)

    def test_data_files_and_folders_change_it(self):
        k = self.key("app/test/fixture_test.dart")
        support.write(self.root, "app/test/fixtures/install/more.json", "{}\n")
        self.assertNotEqual(self.key("app/test/fixture_test.dart"), k)
        k = self.key("app/test/home_test.dart")
        support.write(self.root, "app/assets/config/defaults.toml", "a = 2\n")
        self.assertNotEqual(self.key("app/test/home_test.dart"), k)

    def test_the_context_changes_it(self):
        k = self.key()
        self.assertNotEqual(self.key(env={"WFE_TOR": "0"}), k)
        self.assertNotEqual(self.key(env={"DESK_L10N_LINT": "lib/src"}), k)
        self.assertNotEqual(self.key(defines=["WFE_DIST=play"]), k)
        self.assertNotEqual(self.key(name="one test"), k)
        self.assertEqual(self.key(env={"HOME": "/elsewhere", "WFE_TEST_TIMES": "/t.json"}), k)
        for rel, text in (("app/pubspec.lock", "packages: {x: 1}\n"), ("tools/lepic.rev", "def\n")):
            support.write(self.root, rel, text)
            self.assertNotEqual(self.key(), k, rel)
            k = self.key()
        support.write(self.flutter, "bin/cache/dart-sdk/version", "3.14.0")
        self.assertNotEqual(self.key(), k)

    def test_the_lepic_library_bytes_change_it(self):
        lib = os.path.join(self.root, "liblepic_ffi.so")
        support.write(self.root, "liblepic_ffi.so", "one")
        k = self.key(env={"WFE_LEPIC_LIB": lib})
        support.write(self.root, "liblepic_ffi.so", "two")
        self.assertNotEqual(self.key(env={"WFE_LEPIC_LIB": lib}), k)

    def test_the_lepic_library_path_and_the_history_path_do_not(self):
        # the same library in two worktrees is the same inputs; where the history is kept is not an input
        support.write(self.root, "a/liblepic_ffi.so", "same")
        support.write(self.root, "b/liblepic_ffi.so", "same")
        a, b = (os.path.join(self.root, d, "liblepic_ffi.so") for d in "ab")
        self.assertEqual(self.key(env={"WFE_LEPIC_LIB": a}), self.key(env={"WFE_LEPIC_LIB": b}))
        self.assertNotEqual(self.key(env={"WFE_LEPIC_LIB": a}), self.key())
        self.assertEqual(self.key(env={"WFE_TEST_HISTORY": "/x"}), self.key())

    def test_store_and_lookup(self):
        store = tempfile.mkdtemp(prefix="tlib-store-")
        self.addCleanup(shutil.rmtree, store)
        self.assertIsNone(cache.lookup("k1", store))
        cache.store_green("k1", {"file": "test/a_test.dart"}, store)
        self.assertEqual(cache.lookup("k1", store)["file"], "test/a_test.dart")
        os.utime(os.path.join(store, "k1.json"), (0, 0))
        cache.prune(store)
        self.assertIsNone(cache.lookup("k1", store))

    def test_combined_ignores_order(self):
        self.assertEqual(cache.combined(["a", "b"]), cache.combined(["b", "a"]))


if __name__ == "__main__":
    unittest.main()
