# SPDX-License-Identifier: Apache-2.0
"""A Windows build of the LEPIC command-line wallet (`lepic.exe`) at the release's LEPIC pin, and the
reads the Windows update-trust driver makes through it once the wallet database is encrypted.

Build (once per pin, on a rig, over SSH as the builder's user; never the rig user's screen): the pin's
sources leave this machine as a `git archive` of the LEPIC clone, are unpacked and built with cargo on
the box into C:\\EpicRig\\lepic-cli\\<pin>\\lepic.exe. A folder that holds lepic.exe is a cache hit for
every later run at that pin.

Read (after the update): the store key comes from the seed, so a CLI wallet restored from the run
wallet's phrase (`wallet restore --no-scan` into a fresh folder) opens the app's encrypted store. The
app's `wallet.enc.sqlite3` and `.check` are copied (never moved, never the live folder: the running app
holds the data-dir claim) over the fresh store, and `wallet info` and `tx list` run there. The phrase
(captured at the Create wallet screen into the run's secret folder, removed at the end) and the wallet
password go in on standard input, never as an argument or a variable.

What this reads: balances (total, spendable) and the transactions (id, direction, state, amounts, fee,
slate id, transport). It does not give outputs by commitment, a transaction's counterparty or the
wallet's settings; the driver says so in its details where a check would have used them.

COMMANDS is the one place that names the CLI's invocations, so a change in the CLI at a later pin is one edit.
"""
import json
import os
import subprocess
import tomllib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
CLI_ROOT = r"C:\EpicRig\lepic-cli"
COMMANDS = {"restore": ["wallet", "restore", "--no-scan"], "info": ["wallet", "info"], "txs": ["tx", "list"]}
GLOBAL = ["--network", "mainnet", "--log-level", "error", "--output", "json"]  # --offline is a `contact` flag only


class CliError(Exception):
    pass


def pin(src=None):
    """The LEPIC commit the release is built with: tools/lepic.rev of the candidate's source (REL_CANDIDATE_SRC),
    else of this checkout."""
    for base in (src or os.environ.get("REL_CANDIDATE_SRC"), ROOT):
        if not base:
            continue
        try:
            with open(os.path.join(base, "tools", "lepic.rev")) as f:
                v = f.read().strip()
        except OSError:
            continue
        if len(v) >= 12 and all(c in "0123456789abcdef" for c in v):
            return v
    raise CliError("no tools/lepic.rev with a commit in the candidate's source or this checkout")


def lepic_repo(pin_):
    """A local LEPIC clone that holds the pin: LEPIC_REPO, the candidate's app/third_party/lepic, ~/lepic."""
    src = os.environ.get("REL_CANDIDATE_SRC") or ROOT
    for c in (os.environ.get("LEPIC_REPO"), os.path.join(src, "app", "third_party", "lepic"), os.path.expanduser("~/lepic")):
        if c and os.path.isdir(c) and subprocess.run(["git", "-C", c, "cat-file", "-e", pin_ + "^{commit}"],
                                                    capture_output=True).returncode == 0:
            return c
    raise CliError("no local LEPIC clone holds %s (set LEPIC_REPO)" % pin_)


def exe_path(pin_):
    return "%s\\%s\\lepic.exe" % (CLI_ROOT, pin_[:12])


def build_script(pin_):
    d = "%s\\%s" % (CLI_ROOT, pin_[:12])
    return r"""
$ErrorActionPreference = 'Stop'
$d = '%(d)s'
if (Test-Path -LiteralPath "$d\lepic.exe") { 'CACHED'; exit 0 }
$env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path
# LEPIC pins its own Rust (rust-toolchain.toml); the box's system Rust may be older: a toolchain copied to
# C:\EpicRig\lepic-cli\toolchain (bin\cargo.exe) goes first.
if (Test-Path -LiteralPath '%(root)s\toolchain\bin\cargo.exe') { $env:Path = '%(root)s\toolchain\bin;' + $env:Path; $env:RUSTUP_TOOLCHAIN = '' }
foreach ($t in 'cargo','git') { if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { throw "$t not found on PATH" } }
Remove-Item -Recurse -Force "$d\src" -ErrorAction SilentlyContinue
Expand-Archive -LiteralPath "$d\src.zip" -DestinationPath "$d\src" -Force
$env:CARGO_TARGET_DIR = "$d\target"
Push-Location "$d\src"
cargo build --release --locked -p lepic-cli 2>&1 | Select-Object -Last 25
if ($LASTEXITCODE -ne 0) { throw "cargo build failed ($LASTEXITCODE)" }
Pop-Location
Copy-Item "$d\target\release\lepic.exe" "$d\lepic.exe" -Force
Remove-Item -Recurse -Force "$d\src", "$d\src.zip" -ErrorAction SilentlyContinue
& "$d\lepic.exe" --version
'BUILT'
""" % {"d": d, "root": CLI_ROOT}


def ensure(rig, scratch, log, dry=False):
    """Builds lepic.exe at the pin on the rig box unless it is there. -> its path on the box."""
    p = pin()
    exe = exe_path(p)
    if dry:
        log("PLAN lepic.exe at LEPIC %s: %s (cache hit, or git archive of a local clone -> build on the box with cargo)" % (p[:12], exe))
        return exe
    have = rig.pwsh("if (Test-Path -LiteralPath '%s') { 'YES' } else { 'NO' }" % exe, check=False).strip()
    if have.endswith("YES"):
        log("lepic.exe at LEPIC %s already on the box" % p[:12])
        return exe
    repo = lepic_repo(p)
    zipf = os.path.join(scratch, "lepic-%s.zip" % p[:12])
    r = subprocess.run(["git", "-C", repo, "archive", "--format=zip", "-o", zipf, p], capture_output=True, text=True)
    if r.returncode != 0:
        raise CliError("git archive %s: %s" % (p[:12], r.stderr[-200:]))
    d = "%s\\%s" % (CLI_ROOT, p[:12])
    rig.pwsh("New-Item -ItemType Directory -Force '%s' | Out-Null" % d)
    rig.put(zipf, d + "\\src.zip")
    os.unlink(zipf)
    log("building lepic.exe at LEPIC %s on the box (cargo, a few minutes)" % p[:12])
    out = rig.pwsh(build_script(p), timeout=3000, check=False)
    if "BUILT" not in out and "CACHED" not in out:
        raise CliError("the build of lepic.exe failed: %s" % out.strip()[-600:])
    return exe


def read_script(exe, lepic_dir, run, tag, pw_file, settings_toml, phrase_file):
    """PowerShell, run by the rig's user. A fresh data folder is restored from the run wallet's phrase
    (`wallet restore --no-scan`: it makes the CLI's own vault and a store under the same seed-derived key),
    the app's encrypted store files are COPIED over the fresh store (never the live folder, never moved;
    the app's lock files stay behind), and the reads run on that. The phrase and the password come from
    the run's secret folder on standard input, never an argument."""
    dst = "%s\\cli\\%s" % (run, tag)
    glob_ = " ".join("'%s'" % a for a in GLOBAL)
    cfg = '--data-dir $dst --settings "$dst\\..\\cli-settings.toml" ' + glob_

    def call(args, stdin):
        return "%s | & '%s' %s %s 2>>$err" % (stdin, exe, cfg, " ".join("'%s'" % a for a in args))
    parts = ["'@@restore'; " + call(COMMANDS["restore"], '"$phrase`n$pw"'),
             "Get-ChildItem -LiteralPath $src -Force | Where-Object { $_.Name -like 'wallet.enc.sqlite3*' -and $_.Name -notlike '*.tmp' } "
             "| Copy-Item -Destination $dst -Force"]
    for name in ("info", "txs"):
        parts.append("'@@%s'; " % name + call(COMMANDS[name], "$pw"))
    return r"""
$ErrorActionPreference = 'Stop'
$src = '%(src)s'; $dst = '%(dst)s'
Remove-Item -Recurse -Force -LiteralPath $dst -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $dst | Out-Null
$pw = (Get-Content -Raw -LiteralPath '%(pw)s').TrimEnd("`r", "`n")
$phrase = (Get-Content -Raw -LiteralPath '%(phrase)s').TrimEnd("`r", "`n")
$err = "$dst\..\cli-stderr.txt"
if (Test-Path -LiteralPath '%(settings)s') { Copy-Item -LiteralPath '%(settings)s' "$dst\..\cli-settings.toml" -Force }
$ErrorActionPreference = 'Continue'  # redirected native stderr must not stop the script
%(parts)s
Remove-Item -Recurse -Force -LiteralPath $dst -ErrorAction SilentlyContinue
""" % {"src": lepic_dir, "dst": dst, "pw": pw_file, "phrase": phrase_file, "settings": settings_toml,
       "parts": "\n".join(parts)}


def parse(out):
    """{"info": {...}, "txs": [...]} from the script's output: each command's JSON under its @@name line."""
    res, cur, buf = {}, None, []
    for line in out.replace("\r", "").split("\n"):
        if line.startswith("@@"):
            if cur:
                res[cur] = "\n".join(buf).strip()
            cur, buf = line[2:].strip(), []
        elif cur:
            buf.append(line)
    if cur:
        res[cur] = "\n".join(buf).strip()
    try:
        info = json.loads(res["info"])
        txs = json.loads(res["txs"])
    except (KeyError, ValueError):
        raise CliError("the CLI did not answer with JSON: %s" % " | ".join(
            "%s: %s" % (k, v[:200]) for k, v in res.items()) or out[-300:])
    return {"info": info, "txs": txs.get("transactions") or []}


def shape(read, db_path):
    """The driver's database dict ({path, outputs, txs, settings, cli: True}) from a CLI read. Outputs by
    commitment and a counterparty are not in the CLI's reports (None / empty); the balance is carried
    whole in `cli_balance`."""
    acc = (read["info"].get("accounts") or [{}])[0]
    nano = 100000000

    def n(v):
        try:
            return int(round(float(v) * nano)) if v is not None else 0
        except ValueError:
            return 0
    txs = [dict(id=t["tx_id"], direction=t["direction"], state=t["state"], transport=t.get("transport"),
                credited=n(t.get("amount_credited")), debited=n(t.get("amount_debited")), fee=n(t.get("fee")),
                height=None, counterparty=None, slate=(t.get("slate_id") or "").replace("-", "").upper() or None)
           for t in read["txs"]]
    return {"path": db_path, "outputs": None, "txs": txs, "settings": {}, "cli": True,
            "cli_balance": {"total": acc.get("total"), "spendable": acc.get("spendable"),
                            "awaiting_confirmation": acc.get("awaiting_confirmation"), "locked": acc.get("locked")}}
