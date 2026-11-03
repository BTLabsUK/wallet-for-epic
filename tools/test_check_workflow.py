# SPDX-License-Identifier: Apache-2.0
# Unit tests for check-workflow.py: each rule on small workflows and scripts, and the repository's
# own workflows and actions, which must pass.
#   python3 -m unittest tools/test_check_workflow.py
import importlib.util
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("check_workflow", HERE / "check-workflow.py")
cw = importlib.util.module_from_spec(spec)
sys.modules["check_workflow"] = cw
spec.loader.exec_module(cw)

SHA = "3d3c42e5aac5ba805825da76410c181273ba90b1"
GOOD = f"""
name: build
on:
  workflow_dispatch:
    inputs:
      variants:
        description: JSON subset of ["tor","notor"]
        required: true
        type: string
permissions:
  contents: read
  id-token: write
  attestations: write
concurrency:
  group: build
jobs:
  a:
    runs-on: ubuntu-24.04
    timeout-minutes: 75
    strategy:
      matrix:
        variant: ${{{{ fromJSON(inputs.variants) }}}}
    steps:
      - uses: actions/checkout@{SHA} # v7.0.1
      - run: |
          tools/fetch-tor.sh linux "$RUNNER_TEMP/tor"
          WFE_EMULATOR_X86_64=1 app/tool/build.sh
"""


def commands(src, pwsh=False):
    return cw.command_findings(cw.Text(textwrap.dedent(src), pwsh=pwsh))


class Repo:
    """A temporary repository with a workflow and the files it names."""

    def __init__(self, workflow, files=None):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        (root / ".github" / "workflows").mkdir(parents=True)
        (root / ".github" / "workflows" / "w.yml").write_text(textwrap.dedent(workflow))
        (root / "tools").mkdir()
        (root / "tools" / "workflow-actions.txt").write_text("actions/checkout\n")
        for rel, text in (files or {}).items():
            (root / rel).parent.mkdir(parents=True, exist_ok=True)
            (root / rel).write_text(textwrap.dedent(text))
        self.checker = cw.Checker(root)
        for f in self.checker.files():
            self.checker.check_file(f)
        self.tmp.cleanup()

    @property
    def errors(self):
        return "\n".join(self.checker.errors)


class WorkflowRules(unittest.TestCase):
    def test_good(self):
        r = Repo(GOOD, {"tools/fetch-tor.sh": "tar -xzf x tor\n", "app/tool/build.sh": "flutter build apk\n"})
        self.assertEqual(r.checker.errors, [])
        self.assertEqual(r.checker.scripts, {"tools/fetch-tor.sh", "app/tool/build.sh"})

    def test_triggers(self):
        for on, bad in [("schedule:\n    - cron: '0 0 * * *'", True), ("pull_request_target:", True),
                        ("workflow_run:\n    workflows: [x]", True), ("push:\n    tags: ['v*']", True),
                        ("push:\n    branches: [main]", False), ("pull_request:", False), ("[workflow_dispatch, issue_comment]", True)]:
            r = Repo(GOOD.replace("on:\n  workflow_dispatch:", f"on:\n  {on}\n  workflow_dispatch:")
                     if not on.startswith("[") else GOOD.replace("on:\n  workflow_dispatch:\n", f"on: {on}\nx:\n"))
            self.assertEqual("trigger" in r.errors or "push must" in r.errors, bad, on)

    def test_permissions(self):
        self.assertIn("no top-level permissions", Repo(GOOD.replace("permissions:\n", "perms:\n")).errors)
        self.assertIn("permission contents: write", Repo(GOOD.replace("contents: read", "contents: write")).errors)
        self.assertIn("permission packages: write", Repo(GOOD.replace("contents: read", "contents: read\n  packages: write")).errors)
        self.assertIn("list each one", Repo(GOOD.replace("permissions:\n  contents: read\n  id-token: write\n  attestations: write\n",
                                                          "permissions: write-all\n")).errors)
        self.assertEqual(Repo(GOOD.replace("contents: read", "contents: read\n  actions: read")).checker.errors, [])

    def test_secrets(self):
        self.assertIn("references secrets", Repo(GOOD + "        env:\n          T: ${{ secrets.TOKEN }}\n").errors)
        self.assertIn("references secrets", Repo(GOOD + "        env:\n          T: ${{ secrets['TOKEN'] }}\n").errors)

    def test_uses(self):
        self.assertIn("full commit SHA", Repo(GOOD.replace(f"@{SHA}", "@v7")).errors)
        self.assertIn("version comment", Repo(GOOD.replace(" # v7.0.1", "")).errors)
        self.assertIn("not in tools/workflow-actions.txt", Repo(GOOD.replace("actions/checkout", "evil/checkout")).errors)
        self.assertIn("no such local action", Repo(GOOD.replace(f"actions/checkout@{SHA} # v7.0.1", "./.github/actions/x")).errors)
        self.assertIn("no docker actions", Repo(GOOD.replace(f"actions/checkout@{SHA} # v7.0.1", "docker://alpine:3 # v3")).errors)

    def test_caps(self):
        self.assertIn("timeout-minutes is None", Repo(GOOD.replace("    timeout-minutes: 75\n", "")).errors)
        self.assertIn("timeout-minutes is 120", Repo(GOOD.replace("timeout-minutes: 75", "timeout-minutes: 120")).errors)
        self.assertIn("no concurrency group", Repo(GOOD.replace("concurrency:\n  group: build\n", "")).errors)

    def test_fan_out(self):
        job = GOOD[GOOD.index("  a:\n"):]
        three = GOOD + job.replace("  a:", "  b:") + job.replace("  a:", "  c:")
        self.assertEqual(Repo(three).checker.errors, [])  # 3 jobs x 2 variants
        self.assertIn("up to 8 jobs", Repo(three + job.replace("  a:", "  d:")).errors)
        self.assertIn("up to 9 jobs", Repo(GOOD.replace("variant: ${{ fromJSON(inputs.variants) }}",
                                                        "variant: [1, 2, 3]\n        os: [a, b, c]")).errors)
        self.assertIn("size is unknown", Repo(GOOD.replace('JSON subset of ["tor","notor"]', "the variants")).errors)
        self.assertIn("size is unknown", Repo(GOOD.replace("variants)", "other)")).errors)

    def test_reusable_workflow(self):
        self.assertIn("reusable workflow", Repo(GOOD + "  r:\n    uses: o/r/.github/workflows/x.yml@main\n").errors)

    def test_named_script_scanned(self):
        r = Repo(GOOD, {"tools/fetch-tor.sh": "tar -xzf x tor\n", "app/tool/build.sh": "adb install x.apk\n"})
        self.assertIn("app/tool/build.sh: runs adb", r.errors)

    def test_missing_script_warns(self):
        r = Repo(GOOD, {"tools/fetch-tor.sh": "true\n"})
        self.assertEqual(r.checker.errors, [])
        self.assertIn("app/tool/build.sh, not in the repository", "\n".join(r.checker.warnings))


class Commands(unittest.TestCase):
    def assertBanned(self, src, what, pwsh=False):
        found = commands(src, pwsh)
        self.assertTrue(any(what in f for f in found), f"{what!r} not in {found} for {src!r}")

    def assertClean(self, src, pwsh=False):
        self.assertEqual(commands(src, pwsh), [], src)

    def test_banned_commands(self):
        for src in ["tor --version", "sudo -E tor -f torrc", "timeout 60 ./bin/tor", "x=1 epic-node --chain main",
                    "out=$(epic --version)", "if adb devices; then :; fi", "nohup emulator -avd x &",
                    "echo y | avdmanager create avd -n x", "./build/btwallet --help", "build-linux/bt.AppImage",
                    "env A=1 epic-wallet info", "lepic-cli balance", "(cd x && tools/t affected)",
                    "xvfb-run -a flutter test", '"$flutter" test', "flutter.bat drive", "flutter run -d linux",
                    "bash -c 'tor --help'", '[[ $(tor --version) ]]', 'for f in a; do adb shell; done',
                    "case $x in a) tor ;; esac"]:
            with self.subTest(src=src):
                self.assertTrue(commands(src), src)

    def test_banned_text(self):
        self.assertBanned("curl http://abcdefghijklmnop.onion/x", "onion")
        self.assertBanned("curl https://node.btlabs.uk:3413/v2", "public node")
        self.assertBanned("wget epicbox.epiccash.com", "Epicbox host")
        self.assertBanned("flutter drive --target integration_test/x_test.dart", "integration tests")
        self.assertBanned('sdkmanager "system-images;android-35;google_apis;x86_64"', "emulator system image")
        self.assertBanned("python3 tools/screens/shoot.py", "screenshot tools")
        self.assertBanned("curl -d '{\"method\":\"init_send_tx\"}' http://localhost", "wallet send")
        self.assertBanned("epic-wallet -p x send -m file 1", "runs epic-wallet")
        self.assertBanned("sudo apt-get install -y tor", "installs tor")
        self.assertBanned("sudo systemctl start tor@default", "tor service")

    def test_build_lines_pass(self):
        self.assertClean("""
            # tor and the node are packed, not run: no .onion here, nor epicbox.example.com
            tools/fetch-tor.sh android "$jni"
            emulator=()
            [[ "${WFE_EMULATOR_X86_64:-}" == 1 ]] && emulator=(x86_64)
            abis=(tor notor)
            tor=1 variant=
            case "${WFE_TOR:-1}" in 0|false|off) tor=0 ;; tor) x=1 ;; esac
            for f in tor VERSION LICENSE.tor.txt; do check "$f"; done
            tar -xzf "$file" -C "$work" tor docs/tor.txt
            [[ "$v" =~ ^(tor|notor)$ ]] || exit 1
            echo "run tor later" >&2
            python3 - <<'EOF'
            import subprocess; subprocess.run(["tor"])
            EOF
            flutter build apk --release
            "$flutter" precache --android
            cp lib/src/epicbox.dart x
            """)

    def test_powershell(self):
        self.assertClean("""
            foreach ($f in 'btwallet.exe', 'flutter_windows.dll') { Test-Path "$rel\\$f" }
            $info = (Get-Item "$rel\\btwallet.exe").VersionInfo
            if (-not (Test-Path "$TorBundle\\tor.exe")) { throw "$TorBundle\\tor.exe is missing" }
            Write-Output "bundled tor.exe"
            <# tor.exe --help #>
            """, pwsh=True)
        self.assertBanned('& "$rel\\btwallet.exe" --version', "btwallet.exe", pwsh=True)
        self.assertBanned('Start-Process -FilePath "$dir\\tor.exe"', "tor.exe", pwsh=True)
        self.assertBanned("$out = & $adb devices; adb.exe shell", "adb.exe", pwsh=True)


class RepositoryFiles(unittest.TestCase):
    def test_repository_is_clean(self):
        c = cw.Checker(HERE.parent)
        files = c.files()
        self.assertTrue(any(f.name == "build.yml" for f in files))
        for f in files:
            c.check_file(f)
        self.assertEqual(c.errors, [])
        self.assertEqual(c.warnings, [])
        for script in ("app/tool/build_android_release.sh", "app/tool/build_windows_release.ps1",
                       "scripts/build-linux.sh", "tools/fetch-tor.sh"):
            self.assertIn(script, c.scripts)


if __name__ == "__main__":
    unittest.main()
