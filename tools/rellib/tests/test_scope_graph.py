# SPDX-License-Identifier: Apache-2.0
"""Scope validation and the graph of the real release/pipeline.toml."""
import os
import tomllib
import unittest

from support import REPO
from rellib.config import ConfigError, Pipeline, load_scope, render, scope_summary, validate_scope
from rellib.graph import build_graph

PIPE = Pipeline.load(os.path.join(REPO, "release/pipeline.toml"))


def ctx(scope):
    run = "/r/26.10.25/run-1"
    host = {"windows": {"ssh": "w", "workdir": "C:/w"}, "web": {"ssh": "s", "downloads_dir": "/d"}}
    path = {k: f"/p/{k}" for k in ("node_bin_linux", "node_bin_windows", "page_repo", "main_checkout", "worktrees")}
    return {"version": scope["version"], "commit": "a" * 40, "short": "a" * 7, "run_id": "26.10.25-run1", "run": run,
            "files": f"{run}/files", "extra": f"{run}/extra", "manifests": f"{run}/manifests", "src": "/src",
            "target": scope["publish"]["target"], "scratch": f"{run}/scratch", "notes_file": f"{run}/notes.txt",
            "previous_dir": "/prev", "previous_version": "26.10.24", "previous_ref": "v26.10.24",
            "node": "$REL_NODE", "epicbox": "$REL_EPICBOX", "host": host, "path": path}


def graph(**kw):
    s = load_scope(None, "26.10.25", **kw)
    validate_scope(s, PIPE)
    return s, build_graph(PIPE, s, ctx(s))


class ScopeTest(unittest.TestCase):
    def refused(self, fragment, **kw):
        with self.assertRaises(ConfigError) as e:
            s = load_scope(None, kw.pop("version", "26.10.25"), **kw)
            validate_scope(s, PIPE, kw.get("_at"), kw.get("_prev"))
        self.assertIn(fragment, str(e.exception))
        return str(e.exception)

    def test_defaults_are_everything_and_valid(self):
        s = load_scope(None, "26.10.25")
        self.assertEqual(validate_scope(s, PIPE, "26.10.25", "26.10.24"), [])
        self.assertTrue(all(s["platforms"].values()) and all(s["variants"].values()))
        self.assertFalse(s["stores"]["play"])

    def test_only_and_skip_platform(self):
        s = load_scope(None, "26.10.25", only="android", skip_platform=None)
        self.assertEqual([p for p, on in s["platforms"].items() if on], ["android"])
        s = load_scope(None, "26.10.25", skip_platform="macos,ios")
        self.assertFalse(s["platforms"]["macos"] or s["platforms"]["ios"])
        self.assertIn("out of scope: macos, ios", scope_summary(s))

    def test_nonsense_is_refused_with_a_reason(self):
        self.refused("not a platform", only="android,toaster")
        self.refused("no platform in scope", skip_platform="android,linux,windows,macos,ios")
        self.refused("must be YY.MM.patch", version="26.10")
        self.refused("never published live", version="26.10.25-rc1")
        msg = self.refused("cannot be skipped", skips=["build-windows=PC off"])
        self.assertIn("[platforms]", msg)
        self.refused("gates never skip", skips=["publish-gate=hurry"])
        self.refused("waive it in [proof.waive]", skips=["trust-linux=slow"])
        self.refused("no such step", skips=["build-toaster=x"])
        self.refused("give a reason", skips=["publish-source="])
        self.refused("not in scope, nothing to waive", only="android", waive=["macos=no test"])
        self.refused("publish.manifests needs android", only="linux")
        self.refused("needs both variants", no_variant="notor")
        self.refused("stores.play needs android", only="linux", sets=["publish.manifests=false", "stores.play=true"])
        self.refused("unknown key", sets=["stores.appstore=true"])

    def test_tor_only_release_without_manifests_is_fine(self):
        s = load_scope(None, "26.10.25", no_variant="notor", sets=["publish.manifests=false"])
        validate_scope(s, PIPE)
        self.assertIn("no update manifests", scope_summary(s))

    def test_version_must_match_the_commit_and_be_newer(self):
        with self.assertRaises(ConfigError) as e:
            validate_scope(load_scope(None, "26.10.25"), PIPE, "26.10.24")
        self.assertIn("differs from app/pubspec.yaml", str(e.exception))
        with self.assertRaises(ConfigError):
            validate_scope(load_scope(None, "26.10.24"), PIPE, "26.10.24", "26.10.24")
        warns = validate_scope(load_scope(None, "26.10.24", test=True), PIPE, "26.10.24", "26.10.24")
        self.assertTrue(any("TEST run only" in w for w in warns))

    def test_test_run_is_always_scratch(self):
        s = load_scope(None, "26.10.25", test=True, sets=["publish.target=live"])
        self.assertEqual(s["publish"]["target"], "scratch")

    def test_scope_file_and_unknown_keys(self):
        import tempfile
        with tempfile.NamedTemporaryFile("w", suffix=".toml", delete=False, dir=os.environ.get("TMPDIR")) as f:
            f.write('version = "26.10.25"\n[platforms]\nwindows = false\n[skip]\npublish-source = "token"\n')
        try:
            s = load_scope(f.name)
            validate_scope(s, PIPE)
            self.assertFalse(s["platforms"]["windows"])
            self.assertEqual(s["skip"], {"publish-source": "token"})
        finally:
            os.remove(f.name)
        with open(f.name, "w") as g:
            g.write('[platform]\nwindows = false\n')
        try:
            with self.assertRaises(ConfigError):
                load_scope(f.name, "26.10.25")
        finally:
            os.remove(f.name)

    def test_the_repo_scope_file_is_valid(self):
        s = load_scope(os.path.join(REPO, "release/release.toml"), "26.10.25")
        validate_scope(s, PIPE)


class GraphTest(unittest.TestCase):
    def test_full_scope_order_and_gates(self):
        s, steps = graph()
        ids = [x.id for x in steps]
        pos = {x: i for i, x in enumerate(ids)}
        for a, b in (("scope", "preflight"), ("preflight", "source-check"), ("source-check", "build-android-tor"),
                     ("build-windows-notor", "artefacts"), ("artefacts", "update-trust"), ("trust-linux-tor", "update-trust"),
                     ("update-trust", "publish-gate"), ("publish-gate", "publish-downloads"),
                     ("publish-downloads", "publish-page"), ("publish-source", "publish-manifests"),
                     ("publish-manifests", "verify-live")):
            self.assertLess(pos[a], pos[b], f"{a} before {b}")
        build = [x for x in steps if x.phase == "build"]
        self.assertFalse(any(x.base.startswith("publish-") and x.kind == "publish" for x in build))
        self.assertTrue(next(x for x in steps if x.id == "verify-live").publish)
        self.assertNotIn("store-play-tor", ids)

    def test_only_android_drops_the_rest_and_their_needs(self):
        s, steps = graph(only="android")
        ids = [x.id for x in steps]
        self.assertIn("build-android-notor", ids)
        self.assertFalse([x for x in ids if "linux" in x or "windows" in x or "apple" in x or "macos" in x])
        art = next(x for x in steps if x.id == "artefacts")
        self.assertEqual(art.needs, ["build-android-tor", "build-android-notor"])

    def test_variants_and_same_variant_needs(self):
        s, steps = graph(skip_platform="android", sets=["publish.manifests=false"], no_variant="notor")
        ids = [x.id for x in steps]
        self.assertNotIn("build-linux-notor", ids)
        sign = next(x for x in steps if x.id == "apple-sign-tor")
        self.assertEqual(sign.needs, ["apple-check-tor"])
        self.assertNotIn("manifests", ids)
        self.assertNotIn("publish-manifests", ids)

    def test_commands_are_filled_in(self):
        s, steps = graph()
        a = next(x for x in steps if x.id == "build-android-notor")
        self.assertIn("/r/26.10.25/run-1/steps/build-android-notor/out", a.run)
        self.assertEqual(a.env["WFE_TOR"], "0")
        self.assertEqual(a.outputs, ["epic-cash-mobile-26.10.25-notor-arm64-v8a.apk"])
        w = next(x for x in steps if x.id == "build-windows-tor")
        self.assertIn("C:/w/26.10.25-run1", w.run)
        t = next(x for x in steps if x.id == "trust-linux-tor")
        self.assertIn("trust-linux.sh", t.run)
        t = next(x for x in steps if x.id == "trust-windows-tor")
        self.assertIn("no update-trust driver for windows", t.run)

    def test_stores_on(self):
        s, steps = graph(sets=["stores.play=true"])
        ids = [x.id for x in steps]
        self.assertIn("build-play-tor", ids)
        self.assertIn("store-play-tor", ids)

    def test_unknown_placeholder_fails_at_plan_time(self):
        with self.assertRaises(ConfigError):
            render("x {nope}", {"a": 1}, "step t")
        self.assertEqual(render("{{a}} {a}", {"a": 1}), "{a} 1")

    def test_cycles_and_bad_steps_are_refused(self):
        bad = tomllib.loads('[step.a]\nrun="x"\nneeds=["b"]\n[step.b]\nrun="x"\nneeds=["a"]\n')
        with self.assertRaises(ConfigError):
            Pipeline(bad)
        with self.assertRaises(ConfigError):
            Pipeline(tomllib.loads('[step.a]\nrun="x"\nneeds=["zz"]\n'))
        with self.assertRaises(ConfigError):
            Pipeline(tomllib.loads('[step.a]\nkind="publish"\n'))


if __name__ == "__main__":
    unittest.main()
