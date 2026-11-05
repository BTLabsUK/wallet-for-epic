"""G1 names a G4 lane's missing previous-release file before the run starts (26.10.26 run-4 found
it after signing)."""
import pathlib
import os
import tempfile
import unittest

import support  # noqa: F401  (puts tools/ on sys.path)
from rellib.builtins import previous_input


class PreviousInputTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        for d in ("files", "extra/emulator"):
            os.makedirs(os.path.join(self.root, d))
        self.prev = {"version": "26.10.25", "dir": os.path.join(self.root, "files"), "extra": os.path.join(self.root, "extra")}

    def touch(self, rel):
        pathlib.Path(os.path.join(self.root, rel)).touch()

    def test_android_apk_in_extra(self):
        self.touch("extra/emulator/bt-wallet-26.10.25-android-x86_64.apk")
        self.touch("extra/emulator/bt-wallet-26.10.25-notor-android-x86_64.apk")
        self.assertTrue(previous_input(self.prev, "android", "tor")[0].endswith("26.10.25-android-x86_64.apk"))
        self.assertTrue(previous_input(self.prev, "android", "notor")[0].endswith("-notor-android-x86_64.apk"))

    def test_published_arm64_is_not_an_emulator_input(self):
        self.touch("files/bt-wallet-26.10.25-android-arm64-v8a.apk")
        path, looked = previous_input(self.prev, "android", "tor")
        self.assertIsNone(path)
        self.assertEqual(looked, [os.path.join(self.root, "extra", "emulator"), os.path.join(self.root, "files", "emulator")])

    def test_desktop_variant_kept_apart(self):
        self.touch("files/bt-wallet-26.10.25-notor-linux-x86_64.AppImage")
        self.touch("files/bt-wallet-26.10.25-windows-x64-setup.exe")
        self.assertIsNone(previous_input(self.prev, "linux", "tor")[0])
        self.assertIsNotNone(previous_input(self.prev, "linux", "notor")[0])
        self.assertIsNotNone(previous_input(self.prev, "windows", "tor")[0])
        self.assertIsNone(previous_input(self.prev, "windows", "notor")[0])


if __name__ == "__main__":
    unittest.main()
