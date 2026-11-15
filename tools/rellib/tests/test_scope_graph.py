# SPDX-License-Identifier: Apache-2.0
"""Scope validation and the graph of the real release/pipeline.toml."""
import pathlib
import os
import re
import tomllib
import unittest

from support import REPO
from rellib.config import ConfigError, Pipeline, load_scope, render, scope_summary, validate_scope
from rellib.graph import build_graph

PIPE = Pipeline.load(os.path.join(REPO, "release/pipeline.toml"))


def ctx(scope):
    run = "/r/26.10.25/run-1"
    host = {"windows": {"ssh": "w", "workdir": "C:/w"}, "web": {"ssh": "s", "downloads_dir": "/d"},
            "apple": {"staging": "", "team_id": "TEAM123456"}}
    path = {k: f"/p/{k}" for k in ("node_bin_linux", "node_bin_windows", "page_repo", "main_checkout", "worktrees")}
    return {"version": scope["version"], "commit": "a" * 40, "short": "a" * 7, "run_id": "26.10.25-run1", "run": run,
            "files": f"{run}/files", "extra": f"{run}/extra", "manifests": f"{run}/manifests", "src": "/src", "rel": "/rel",
            "target": scope["publish"]["target"], "scratch": f"{run}/scratch", "notes_file": f"{run}/notes.txt",
            "previous_dir": "/prev", "previous_version": "26.10.24", "previous_ref": "v26.10.24",
            "host": host, "path": path}


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
        self.refused("cannot be skipped", skips=["trust-manifest=slow"])
        self.refused("no such step", skips=["build-toaster=x"])
        self.refused("give a reason", skips=["publish-source="])
        self.refused("publish.manifests needs android", only="linux")
        self.refused("needs both variants", no_variant="notor")
        self.refused("the one unsigned ipa is the build without Tor", sets=["apple.signed=false", "publish.manifests=false"],
                     no_variant="notor")
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
            f.write('version = "26.10.25"\n[platforms]\nwindows = false\n[publish]\ngithub = false\n[skip]\npublish-source = "token"\n')
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
                     ("build-windows-notor", "artefacts"), ("artefacts", "manifests"), ("manifests", "trust-manifest"),
                     ("trust-manifest", "publish-gate"), ("publish-gate", "publish-downloads"),
                     ("publish-downloads", "publish-page"), ("publish-source", "publish-manifests"),
                     ("publish-manifests", "verify-live")):
            self.assertLess(pos[a], pos[b], f"{a} before {b}")
        build = [x for x in steps if x.phase == "build"]
        self.assertFalse(any(x.base.startswith("publish-") and x.kind == "publish" for x in build))
        self.assertTrue(next(x for x in steps if x.id == "verify-live").publish)
        self.assertNotIn("store-play-tor", ids)

    def test_no_step_tests_a_built_binary(self):
        # The owner 2026-11-15: the pipeline builds, signs, checks signatures and hashes, and publishes.
        s, steps = graph()
        by = {x.id: x for x in steps}
        self.assertFalse([x for x in by if x.startswith(("trust-android", "trust-linux", "trust-windows", "trust-macos",
                                                         "trust-ios", "trust-pair", "update-trust", "screens-check",
                                                         "testbuild-", "flow-", "create-", "lane-"))])
        self.assertEqual(by["trust-manifest"].title, "G4 manifest signature checks")
        self.assertEqual(by["trust-manifest"].needs, ["manifests"])
        self.assertEqual(by["publish-gate"].needs, ["artefacts", "trust-manifest"])
        # Without manifests G4 is out of the graph and the gate waits for G3 alone.
        s, steps = graph(no_variant="notor", sets=["publish.manifests=false"])
        by = {x.id: x for x in steps}
        self.assertNotIn("trust-manifest", by)
        self.assertEqual(by["publish-gate"].needs, ["artefacts"])

    def test_heavy_lanes(self):
        s, steps = graph()
        # G2 and the Android builds one at a time; the Linux builds in their own lane beside them,
        # still heavy (each under build-slot).
        self.assertEqual([x.id for x in steps if x.lane == "heavy"],
                         ["source-check", "build-android-tor", "build-android-notor"])
        self.assertEqual([x.id for x in steps if x.lane == "build-linux"], ["build-linux-tor", "build-linux-notor"])
        self.assertTrue(all(x.heavy for x in steps if x.lane == "build-linux"))

    def test_release_stage_runs_g2_then_the_builds(self):
        for builds in (False, True):
            s = load_scope(None, "26.10.25")
            validate_scope(s, PIPE)
            if builds:
                s["builds"] = {"hosted": True}  # as `tools/rel start --builds hosted`
            by = {x.id: x for x in build_graph(PIPE, s, ctx(s))}
            for p in ("android", "linux", "windows"):
                for v in ("tor", "notor"):
                    self.assertIn("source-check", by[f"build-{p}-{v}"].needs, (builds, p, v))
            # The Apple builds are hand-offs to the Mac: they wait for G2 too.
            for x in ("apple-mac-tor", "apple-mac-notor", "ios-testflight"):
                self.assertIn("source-check", by[x].needs, x)
            if builds:
                self.assertEqual(by["hosted-dispatch"].needs, ["source", "source-check"])
                self.assertIn("(hosted)", by["build-android-tor"].title)
            else:
                self.assertNotIn("hosted-dispatch", by)

    def test_only_android_drops_the_rest_and_their_needs(self):
        s, steps = graph(only="android")
        ids = [x.id for x in steps]
        self.assertIn("build-android-notor", ids)
        self.assertFalse([x for x in ids if "linux" in x or "windows" in x or "apple" in x or "macos" in x])
        art = next(x for x in steps if x.id == "artefacts")
        self.assertEqual(art.needs, ["build-android-tor", "build-android-notor", "sign-android"])
        sign = next(x for x in steps if x.id == "sign-android")
        self.assertEqual((sign.needs, sign.lane, sign.kind), (["build-android-tor", "build-android-notor"], "sign", "builtin"))

    def test_variants_and_same_variant_needs(self):
        s, steps = graph(skip_platform="android", sets=["publish.manifests=false"], no_variant="notor")
        ids = [x.id for x in steps]
        self.assertNotIn("build-linux-notor", ids)
        check = next(x for x in steps if x.id == "apple-mac-check-tor")
        self.assertEqual(check.needs, ["apple-mac-tor"])
        self.assertNotIn("apple-mac-notor", ids)
        self.assertIn("ios-testflight", ids)  # iOS is only ever the build without Tor
        self.assertNotIn("manifests", ids)
        self.assertNotIn("publish-manifests", ids)

    def test_commands_are_filled_in(self):
        s, steps = graph()
        a = next(x for x in steps if x.id == "build-android-notor")
        self.assertIn("/r/26.10.25/run-1/steps/build-android-notor/out", a.run)
        self.assertEqual(a.env["WFE_TOR"], "0")
        self.assertEqual(a.outputs, ["bt-wallet-26.10.25-notor-android-arm64-v8a.apk"])
        w = next(x for x in steps if x.id == "build-windows-tor")
        self.assertIn("C:/w/26.10.25-run1", w.run)
        m = next(x for x in steps if x.id == "apple-mac-check-notor")
        self.assertIn("bt-wallet-26.10.25-notor-macos.dmg " + "a" * 40 + ' "TEAM123456"', m.run)
        self.assertEqual(m.outputs, ["bt-wallet-26.10.25-notor-macos.dmg"])

    def test_stores_on(self):
        s, steps = graph(sets=["stores.play=true"])
        ids = [x.id for x in steps]
        self.assertIn("build-play-tor", ids)
        self.assertIn("store-play-tor", ids)
        # One bundle per version code: the build with Tor only.
        self.assertNotIn("build-play-notor", ids)
        self.assertNotIn("store-play-notor", ids)
        self.assertNotIn("store-play-promote", ids)
        s, steps = graph(sets=["stores.play=true", "stores.play_promote=beta"])
        by = {x.id: x for x in steps}
        self.assertEqual(by["store-play-promote"].needs, ["store-play-tor"])
        self.assertIn("tools/play-upload.sh --promote beta", by["store-play-promote"].run)
        self.assertIn("store-play-promote", by["cleanup"].needs)
        self.assertIn("internal, then beta", scope_summary(s))
        for sets in (["stores.play_promote=beta"], ["stores.play=true", "stores.play_promote=production"]):
            with self.assertRaises(ConfigError):
                graph(sets=sets)

    def test_tag_screens_and_announce(self):
        s, steps = graph()
        by = {x.id: x for x in steps}
        ids = [x.id for x in steps]
        # The tag after the gate, before anything leaves the machine.
        self.assertEqual(by["tag"].needs, ["publish-gate"])
        self.assertIn("tag", by["publish-downloads"].needs)
        self.assertTrue(by["tag"].publish and not by["tag"].skippable and not by["tag"].warn_only)
        self.assertIn("tag.sh 26.10.25 " + "a" * 40, by["tag"].run)
        # The Telegram draft after the read-back, never holding the release.
        x = by["announce"]
        self.assertEqual(x.needs, ["verify-live"])
        self.assertTrue(x.publish and x.warn_only and x.skippable)
        self.assertIn("announce.py 26.10.25", x.run)
        self.assertIn("announce", by["cleanup"].needs)
        # The catalogue renders before the gate, beside the builds: from G2 on, in its own lane. A
        # failed render holds nothing: the gate never waits for it.
        sc = by["screens"]
        self.assertEqual((sc.lane, sc.publish, sc.warn_only, sc.skippable), ("screens", False, True, True))
        # It renders in the release checkout, so it waits for the builds made there (a tour's
        # flutter test rewrites the plugin registrants under an Android build).
        for need in ("source", "source-check", "build-android-tor", "build-linux-tor"):
            self.assertIn(need, sc.needs)
        self.assertIn("screens.sh 26.10.25 /r/26.10.25/run-1/steps/screens/out", sc.run)
        self.assertFalse(sc.heavy)  # tools/screens.sh takes its own build-slot slots
        self.assertNotIn("screens", by["publish-gate"].needs)
        # The gallery after the read-back and after the render; skipped when the render failed.
        sp = by["screens-publish"]
        self.assertEqual(sorted(sp.needs), ["screens", "verify-live"])
        self.assertEqual(sp.needs_ok, ["screens"])
        self.assertTrue(sp.publish and sp.warn_only and sp.skippable)
        self.assertIn("screens-publish.sh 26.10.25 /r/26.10.25/run-1/steps/screens-publish/out", sp.run)
        self.assertLess(ids.index("verify-live"), ids.index("screens-publish"))
        self.assertIn("screens-publish", by["cleanup"].needs)
        self.assertNotIn("screens", by["cleanup"].needs)

    def test_github_mirror_on_by_default_and_switchable_off(self):
        s, steps = graph(sets=["publish.github=false"])
        by = {x.id: x for x in steps}
        self.assertFalse(s["publish"]["github"])
        self.assertNotIn("publish-github-release", by)
        self.assertEqual(by["publish-manifests"].env["GITHUB_UPDATE_JSON"], "0")
        self.assertEqual(by["publish-page"].env["REL_GITHUB"], "0")
        self.assertNotIn("publish-github-release", by["publish-manifests"].needs)
        s, steps = graph()
        self.assertTrue(s["publish"]["github"])
        by = {x.id: x for x in steps}
        ids = [x.id for x in steps]
        gh = by["publish-github-release"]
        self.assertEqual((gh.kind, gh.host, gh.needs, gh.skippable), ("publish", "signer", ["publish-source"], True))
        self.assertIn("publish-github-release.sh 26.10.25 /r/26.10.25/run-1/files /r/26.10.25/run-1/steps/publish-github-release/out", gh.run)
        self.assertLess(ids.index("publish-source"), ids.index("publish-github-release"))
        self.assertLess(ids.index("publish-github-release"), ids.index("publish-manifests"))
        self.assertIn("publish-github-release", by["publish-manifests"].needs)
        self.assertEqual(by["publish-manifests"].env["GITHUB_UPDATE_JSON"], "1")
        self.assertEqual(by["publish-page"].env["REL_GITHUB"], "1")
        self.assertIn("GitHub release mirror", scope_summary(s))
        # The tag gets to GitHub through publish-source: skipping it with the mirror on is refused.
        with self.assertRaises(ConfigError) as e:
            graph(skips=["publish-source=token"])
        self.assertIn("publish.github needs publish-source", str(e.exception))
        with self.assertRaises(ConfigError):
            graph(sets=["publish.github=maybe"])

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


class ScriptsTest(unittest.TestCase):
    def test_apple_signed_by_default_ad_hoc_on_request(self):
        s, steps = graph()
        ids = [x.id for x in steps]
        self.assertIn("apple-mac-tor", ids)
        self.assertIn("ios-testflight", ids)
        self.assertFalse([i for i in ids if i.startswith("apple-adhoc")])
        # A test release: the Mac builds what 26.10.24 shipped (ad-hoc dmg, unsigned ipa), per variant.
        s, steps = graph(sets=["apple.signed=false"])
        by = {x.id: x for x in steps}
        for gone in ("apple-mac-tor", "apple-mac-check-tor", "ios-testflight"):
            self.assertNotIn(gone, by)
        self.assertEqual(by["apple-adhoc-notor"].kind, "handoff")
        self.assertIn("WFE_TOR=0", by["apple-adhoc-notor"].run)
        self.assertIn("macos dmg ipa", by["apple-adhoc-notor"].run)
        self.assertIn("bt-wallet-26.10.25-notor-ios-unsigned.ipa", by["apple-adhoc-notor"].results)
        self.assertEqual(by["apple-adhoc-mac-notor"].needs, ["apple-adhoc-notor"])
        self.assertEqual(by["apple-adhoc-mac-tor"].outputs, ["bt-wallet-26.10.25-macos.dmg"])
        # One iOS file: the ipa of the build without Tor. The Mac's hand-off with Tor builds the dmg only.
        self.assertEqual(by["apple-adhoc-ios-notor"].outputs, ["bt-wallet-26.10.25-notor-ios-unsigned.ipa"])
        self.assertNotIn("apple-adhoc-ios-tor", by)
        self.assertIn("WFE_TOR=1", by["apple-adhoc-tor"].run)
        self.assertIn("macos dmg  #", by["apple-adhoc-tor"].run)
        self.assertEqual(by["apple-adhoc-tor"].results, ["bt-wallet-26.10.25-macos.dmg", "results.txt", "SHA256SUMS"])
        for gate in ("artefacts", "sign-android"):
            self.assertIn("apple-adhoc-mac-tor", by[gate].needs)
            self.assertIn("apple-adhoc-ios-notor", by[gate].needs)
        self.assertIn("Apple ad hoc", scope_summary(s))
        # iOS out: the Mac still builds per variant for macOS, and no ipa check is in the graph.
        s, steps = graph(sets=["apple.signed=false"], skip_platform="ios")
        ids = [x.id for x in steps]
        self.assertIn("apple-adhoc-tor", ids)
        self.assertNotIn("apple-adhoc-ios-tor", ids)

    def test_every_script_the_pipeline_runs_is_executable(self):
        # A step whose script lost its exec bit fails with exit 126 mid-release (26.10.24 run 2).
        raw = tomllib.loads(pathlib.Path(os.path.join(REPO, "release/pipeline.toml")).read_text(encoding="utf-8"))
        cmds = [s.get("run", "") for s in raw["step"].values()]
        paths = sorted({m for c in cmds for m in re.findall(r"\{rel\}/(\S+\.(?:sh|py))", c)})
        self.assertTrue(paths)
        for p in paths:
            with self.subTest(p):
                self.assertTrue(os.access(os.path.join(REPO, p), os.X_OK), f"{p} is missing or not executable")
