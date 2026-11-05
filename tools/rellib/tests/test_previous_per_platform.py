"""G4 updates each platform from the newest published release that has its file: an Android-only
release (26.11.1) does not take the desktops' previous release away (26.11.0)."""
import json
import os
import tempfile
import types
import unittest

import support  # noqa: F401  (puts tools/ on sys.path)
from rellib import builtins
from rellib.engine import Engine
from rellib.graph import Step


def touch(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").close()


class PreviousPerPlatformTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.pubs = []
        self.release("26.11.0", "run-4", ["bt-wallet-{v}{s}-linux-x86_64.AppImage", "bt-wallet-{v}{s}-windows-x64-setup.exe"],
                     ["emulator/bt-wallet-{v}{s}-android-x86_64.apk"])
        self.release("26.11.1", "run-1", [], ["emulator/bt-wallet-{v}{s}-android-x86_64.apk"])
        self.pipe = types.SimpleNamespace(proof={"drivers": {"android": "a", "linux": "l", "windows": "w"}, "variants": ["tor", "notor"]},
                                          steps={})
        self.scope = {"platforms": {"android": True, "linux": True, "windows": True},
                      "variants": {"tor": True, "notor": True},
                      "proof": {"previous_dir": "", "waive": {}}}

    def release(self, version, run_id, files, extra):
        run = os.path.join(self.root, version, run_id)
        for sfx in ("", "-notor"):
            for f in files:
                touch(os.path.join(run, "files", f.format(v=version, s=sfx)))
            for f in extra:
                touch(os.path.join(run, "extra", f.format(v=version, s=sfx)))
        os.makedirs(os.path.join(run, "files"), exist_ok=True)
        self.pubs.append({"version": version, "run_id": run_id, "run": run, "tag": f"v{version}"})
        with open(os.path.join(self.root, "published.json"), "w") as f:
            json.dump(self.pubs, f)

    def pick(self, version="26.11.2"):
        overall = builtins.previous_candidates(self.root, version)[0]
        return overall, builtins.previous_by_platform(self.scope, self.pipe, self.root, version, overall)

    def test_overall_is_newest_and_each_platform_has_its_own(self):
        overall, by = self.pick()
        self.assertEqual(overall["version"], "26.11.1")
        self.assertEqual({p: b["version"] for p, b in by.items()},
                         {"android": "26.11.1", "linux": "26.11.0", "windows": "26.11.0"})
        self.assertEqual(by["linux"]["ref"], "v26.11.0")
        self.assertEqual(builtins.previous_text(overall, by), "android 26.11.1, linux 26.11.0, windows 26.11.0")

    def test_same_release_everywhere_reads_as_one_version(self):
        self.release("26.11.2", "run-1", ["bt-wallet-{v}{s}-linux-x86_64.AppImage", "bt-wallet-{v}{s}-windows-x64-setup.exe"],
                     ["emulator/bt-wallet-{v}{s}-android-x86_64.apk"])
        overall, by = self.pick("26.11.3")
        self.assertEqual(builtins.previous_text(overall, by), "26.11.2")

    def test_explicit_previous_dir_is_one_release(self):
        self.scope["proof"]["previous_dir"] = "/somewhere/26.10.24-r2"
        self.assertEqual(self.pick()[1], {})

    def test_platform_nobody_serves_gets_the_overall_previous(self):
        self.scope["platforms"]["windows"] = False
        self.scope["platforms"]["linux"] = False
        os.remove(os.path.join(self.root, "26.11.1", "run-1", "extra", "emulator", "bt-wallet-26.11.1-notor-android-x86_64.apk"))
        os.remove(os.path.join(self.root, "26.11.0", "run-4", "extra", "emulator", "bt-wallet-26.11.0-notor-android-x86_64.apk"))
        overall, by = self.pick()
        self.assertEqual(by["android"]["version"], "26.11.1")

    def test_variant_missing_in_newest_falls_to_older(self):
        os.remove(os.path.join(self.root, "26.11.1", "run-1", "extra", "emulator", "bt-wallet-26.11.1-notor-android-x86_64.apk"))
        self.assertEqual(self.pick()[1]["android"]["version"], "26.11.0")

    def test_env_per_platform_step(self):
        overall, by = self.pick()
        info = {"previous": overall, "previous_by_platform": by, "run_id": "run-1", "version": "26.11.2", "commit": "c"}
        run = types.SimpleNamespace(path="/r", files="/r/files", extra="/r/extra", info=info, step_dir=lambda s: "/r/" + s)
        eng = types.SimpleNamespace(run=run, info=info, dry=True, hosts={"host": {}}, pipeline=types.SimpleNamespace(
            proof={}, manifest_days=lambda: 1))

        def env(platform, variant, **kw):
            st = Step(id=f"trust-{platform}-{variant}", base=f"trust-{platform}", kind="command", title="", host="local",
                      lane="l", platforms=[platform], variant=variant, **kw)
            return Engine.base_env(eng, st)
        e = env("linux", "tor", proof=True)
        self.assertEqual((e["REL_PREVIOUS_VERSION"], e["REL_PREVIOUS_REF"]), ("26.11.0", "v26.11.0"))
        self.assertTrue(e["REL_PREVIOUS_DIR"].endswith("26.11.0/run-4/files"))
        e = env("android", "tor", proof=True)
        self.assertEqual(e["REL_PREVIOUS_VERSION"], "26.11.1")
        self.assertTrue(e["REL_PREVIOUS_EXTRA"].endswith("26.11.1/run-1/extra"))
        e = env("windows", "tor", env={"REL_TRUST_MODE": "create"})  # create-* is not a proof step
        self.assertEqual(e["REL_PREVIOUS_VERSION"], "26.11.0")
        st = Step(id="announce", base="announce", kind="command", title="", host="local", lane="l", platforms=[])
        self.assertEqual(Engine.base_env(eng, st)["REL_PREVIOUS_VERSION"], "26.11.1")


if __name__ == "__main__":
    unittest.main()
