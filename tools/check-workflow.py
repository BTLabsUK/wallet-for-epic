#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Checks the GitHub workflows and local actions against the hosted-build safety rules.

  tools/check-workflow.py [--root DIR] [FILE...]

Scans .github/workflows/*.yml|yaml and .github/actions/*/action.yml (or the files named), and the
repository scripts their run: steps name (.sh, .ps1, .py; one level, not the scripts those call).
A hosted runner builds and checks files; it never talks to the network the wallet uses, runs the
app or its tests, or holds a secret. The rules:

  triggers      only workflow_dispatch, push (with branches, no tags) and pull_request
  permissions   a top-level block (job blocks too) within contents: read, id-token: write,
                attestations: write, actions: read
  secrets       no secrets. reference
  actions       every uses: is a local ./ action or owner/repo[/path]@<40 hex> with a version
                comment, from tools/workflow-actions.txt; no docker:// and no reusable workflows
  caps          every job has timeout-minutes <= 90; the workflow has a concurrency group; at most
                6 jobs per run (matrix axes from fromJSON(inputs.X) count the JSON array in the
                input's description)
  commands      no Tor, node, wallet or app binary, emulator, adb or avdmanager; no flutter test,
                drive or run, integration or screenshot tests; no onion address, node.btlabs.uk or
                epicbox host; no wallet send; no tor or epic package or service

Exit 0 when clean (warnings are printed), 1 on a finding, 2 without PyYAML.
"""
import argparse
import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    print("check-workflow: needs PyYAML (python3-yaml, or pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

ALLOWED_TRIGGERS = {"workflow_dispatch", "push", "pull_request"}
ALLOWED_PERMISSIONS = {"contents": "read", "id-token": "write", "attestations": "write", "actions": "read"}
LEVEL = {"none": 0, "read": 1, "write": 2}
MAX_TIMEOUT = 90
MAX_JOBS = 6
SCRIPT_EXT = (".sh", ".ps1", ".py")

# Commands a job may not start (the first word of a simple command, its basename, any case).
BANNED_COMMANDS = {
    "tor", "tor.exe", "torsocks", "epic", "epic.exe", "epic-node", "epic-node.exe",
    "btwallet", "btwallet.exe", "epic-wallet", "epic-wallet.exe", "lepic-cli", "lepic-cli.exe",
    "emulator", "emulator.exe", "adb", "adb.exe", "avdmanager", "avdmanager.bat",
}
FLUTTER_BANNED = {"test", "drive", "run"}
PACKAGE_TOOLS = {"apt", "apt-get", "dnf", "yum", "brew", "choco", "winget", "scoop", "pacman", "snap",
                 "pip", "pip3", "pipx", "npm", "cargo", "sdkmanager"}
SERVICE_TOOLS = {"systemctl", "service", "start-service", "restart-service", "sc", "sc.exe"}
BANNED_PACKAGE = re.compile(r"^(tor|tor-.*|torsocks|obfs4proxy|epic|epic-.*|.*-epic)$", re.I)
# Searched in the words of commands (comments are not words), any case.
BANNED_TEXT = [
    (re.compile(r"system-images;", re.I), "an emulator system image"),
    (re.compile(r"integration_test", re.I), "integration tests"),
    (re.compile(r"(screenshot|desktop)_tour_test", re.I), "screenshot tests"),
    (re.compile(r"tools[/\\]screens", re.I), "screenshot tools"),
    (re.compile(r"\.onion\b", re.I), "an onion address"),
    (re.compile(r"node\.btlabs\.uk", re.I), "the public node"),
    (re.compile(r"\bepicbox\.(?:[a-z0-9-]+\.)*[a-z]{2,}\b", re.I), "an Epicbox host"),
    (re.compile(r"\b(init_send_tx|send_tx|post_tx|finalize_tx|issue_send_tx)\b", re.I), "a wallet send"),
]
FILE_EXT = re.compile(r"\.(dart|rs|md|json|sh|py|ps1|yml|yaml|txt|arb|kt|swift|toml|lock)$", re.I)
SEND = re.compile(r"\b(wallet|epic-wallet|lepic-cli|tools/t)\s+(\S+\s+)*?send\b", re.I)

ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\[[^\]]*\])?\+?=")
KEYWORDS = {"if", "then", "else", "elif", "do", "while", "until", "!", "time", "fi", "done", "esac",
            "{", "}", "exec", "command", "builtin", "noglob", "local", "export", "declare",
            "readonly", "typeset", "eval"}
SKIP_COMMANDS = {"for", "select", "function", "foreach", "switch", "param", "echo", "printf",
                 "write-output", "write-host", "write-error", "write-warning", "throw", "return"}
WRAPPERS = {"sudo", "env", "nohup", "timeout", "xvfb-run", "nice", "stdbuf", "setsid", "chroot",
            "start-process", "saps", "start", "invoke-item", "ii", "call"}
SHELLS = {"bash", "sh", "zsh", "dash", "pwsh", "powershell", "pwsh.exe", "powershell.exe", "bash.exe", "cmd", "cmd.exe"}
SEPARATORS = ("&&", "||", ";;&", ";;", ";&", "|&", ";", "|", "&", "\n")


class Text:
    """A shell (bash or PowerShell) script as simple commands, each a list of words."""

    def __init__(self, src, pwsh=False):
        self.src = re.sub(r"\$\{\{.*?\}\}", "GHEXPR", src, flags=re.S)
        self.pwsh = pwsh
        self.commands = []  # [(words, quoted_first, after_amp, ending separator)]
        self._parse(self.src)

    def _parse(self, s):
        i, n = 0, len(s)
        words, quoted, cur, cur_quoted, cmd_start = [], False, None, False, True
        prev_sep = None
        heredocs = []

        def end_word():
            nonlocal cur, cur_quoted, quoted
            if cur is not None:
                if not words:
                    quoted = cur_quoted
                words.append(cur)
            cur, cur_quoted = None, False

        def end_command(sep):
            nonlocal words, quoted, cmd_start, prev_sep
            end_word()
            if words:
                self.commands.append((words, quoted, prev_sep == "&", sep))
            words, quoted, cmd_start = [], False, True
            prev_sep = sep

        while i < n:
            c = s[i]
            if c == "\\" and i + 1 < n and s[i + 1] == "\n":
                i += 2
                continue
            if self.pwsh and c == "`" and i + 1 < n and s[i + 1] == "\n":
                i += 2
                continue
            if self.pwsh and s.startswith("<#", i):
                j = s.find("#>", i + 2)
                i = n if j < 0 else j + 2
                continue
            if c == "#" and cur is None:
                j = s.find("\n", i)
                i = n if j < 0 else j
                continue
            if c in " \t\r":
                end_word()
                i += 1
                continue
            if c == "\n":
                end_command("\n")
                i += 1
                for delim in heredocs:
                    while i < n:
                        j = s.find("\n", i)
                        line = s[i:] if j < 0 else s[i:j]
                        i = n if j < 0 else j + 1
                        if line.strip() == delim:
                            break
                heredocs = []
                continue
            if not self.pwsh and s.startswith("<<", i) and not s.startswith("<<<", i):
                m = re.match(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", s[i:])
                if m:
                    heredocs.append(m.group(2))
                    end_word()
                    i += m.end()
                    continue
            if s.startswith("$(", i):
                j = self._matching(s, i + 1, "(", ")")
                self._parse(s[i + 2:j])
                cur = (cur or "") + s[i:j + 1]
                i = j + 1
                continue
            if s.startswith("${", i):
                j = self._matching(s, i + 1, "{", "}")
                cur = (cur or "") + s[i:j + 1]
                i = j + 1
                continue
            if c in "'\"":
                j = self._quote_end(s, i)
                body = s[i + 1:j]
                if c == '"':
                    k = 0
                    while True:
                        k = body.find("$(", k)
                        if k < 0:
                            break
                        e = self._matching(body, k + 1, "(", ")")
                        self._parse(body[k + 2:e])
                        k = e + 1
                if cur is None:
                    cur_quoted = True
                cur = (cur or "") + body
                i = j + 1
                continue
            if cur is None and cmd_start and not words and (s.startswith("[[", i) or s.startswith("((", i)):
                close = "]]" if c == "[" else "))"
                j = s.find(close, i + 2)
                j = n if j < 0 else j + 2
                words.append(s[i:j])
                k = i
                while (k := s.find("$(", k, j)) >= 0:
                    e = self._matching(s, k + 1, "(", ")")
                    self._parse(s[k + 2:e])
                    k = e + 1
                i = j
                continue
            if c == "(" and cur is not None and cur.endswith("=") and ASSIGN.match(cur):
                j = self._matching(s, i, "(", ")")
                cur += s[i:j + 1]
                i = j + 1
                continue
            sep = next((p for p in SEPARATORS if s.startswith(p, i)), None)
            if sep and not (sep == "&" and re.match(r"[<>]&|&>", s[i - 1:i + 2])):
                if sep == "&" and cur is not None and cur and cur[-1] in "<>":
                    cur += c
                    i += 1
                    continue
                end_command(sep)
                i += len(sep)
                continue
            if c in "(){}" and (cur is None or c in "()"):
                if c in "{}" and i + 1 < n and s[i + 1] not in " \t\r\n;":
                    cur = (cur or "") + c
                    i += 1
                    continue
                end_command(c)
                i += 1
                continue
            cur = (cur or "") + c
            cmd_start = False
            i += 1
        end_command(None)

    @staticmethod
    def _matching(s, i, open_, close):
        """The index of the bracket that closes s[i] (open_), skipping quotes."""
        depth, j = 0, i
        while j < len(s):
            c = s[j]
            if c in "'\"" and j > i:
                j = Text._quote_end(s, j) + 1
                continue
            if c == open_:
                depth += 1
            elif c == close:
                depth -= 1
                if depth == 0:
                    return j
            j += 1
        return len(s) - 1

    @staticmethod
    def _quote_end(s, i):
        q, j = s[i], i + 1
        while j < len(s):
            if q == '"' and s.startswith(("$(", "${"), j):
                j = Text._matching(s, j + 1, s[j + 1], ")" if s[j + 1] == "(" else "}") + 1
                continue
            if s[j] in "\\`" and q == '"' and j + 1 < len(s) and s[j + 1] in '"\\`$':
                j += 2
                continue
            if s[j] == q:
                return j
            j += 1
        return len(s) - 1

    def words(self):
        return [w for ws, *_ in self.commands for w in ws]


def base(word):
    return re.split(r"[/\\]", word)[-1].lower()


def command_findings(text):
    """Findings in one script: banned commands and banned text."""
    out = []
    cases, pattern = 0, False
    for words, quoted, after_amp, sep in text.commands:
        ws = list(words)
        first_quoted = quoted
        # case WORD in, then each clause's patterns up to ')' (after 'in' or ';;'): not commands.
        if not text.pwsh and ws[0] == "case":
            cases, pattern = cases + 1, sep != ")"
            continue
        if cases and ws[0] == "esac":
            cases, pattern = cases - 1, False
            continue
        if pattern:
            pattern = sep != ")"
            continue
        if cases and sep in (";;", ";&", ";;&"):
            pattern = True
        while ws:
            w, lw = ws[0], ws[0].lower()
            if ASSIGN.match(w) or lw in KEYWORDS:
                ws.pop(0)
                first_quoted = False
                continue
            if lw in WRAPPERS:
                ws.pop(0)
                while ws and (ws[0].startswith("-") or ASSIGN.match(ws[0]) or
                              (lw == "timeout" and re.match(r"^\d+[smhd]?$", ws[0]))):
                    if lw == "sudo" and ws[0] in ("-u", "-g") and len(ws) > 1:
                        ws.pop(0)
                    if lw in ("start-process", "saps") and ws[0].lower() in ("-filepath",):
                        ws.pop(0)
                        break
                    ws.pop(0)
                first_quoted = False
                continue
            break
        if not ws:
            continue
        first = ws[0]
        name = base(first)
        if name in SKIP_COMMANDS:
            continue
        if base(first) in SHELLS:
            for k, a in enumerate(ws[1:-1], 1):
                if a in ("-c", "-Command", "-command", "/c", "/C"):
                    out += command_findings(Text(ws[k + 1], pwsh=name.startswith(("pwsh", "powershell"))))
                    break
            continue
        counts = not (text.pwsh and first_quoted and not after_amp)
        if counts and (name in BANNED_COMMANDS or name.endswith(".appimage")):
            out.append(f"runs {first}")
        if counts and re.search(r"(^|[/\\])tools[/\\]t$", first):
            out.append(f"runs {first} (the app's test driver)")
        if counts and (name.startswith("flutter") or re.match(r"^\$\{?[A-Za-z_]*flutter", first, re.I)
                       or name in ("dart", "dart.exe", "dart.bat")):
            sub = next((a for a in ws[1:] if not a.startswith("-")), "")
            if sub in FLUTTER_BANNED or (name.startswith("dart") and sub == "test"):
                out.append(f"runs {first} {sub}")
        if name in PACKAGE_TOOLS and any(a.lower() in ("install", "add", "--install") for a in ws[1:]):
            bad = [a for a in ws[1:] if BANNED_PACKAGE.match(a)]
            if bad:
                out.append(f"installs {' '.join(bad)} with {first}")
        if name in SERVICE_TOOLS and any(re.match(r"^tor(@.*|\.service)?$", a, re.I) for a in ws[1:]):
            out.append(f"manages the tor service with {first}")
    joined = "\n".join(" ".join(ws) for ws, *_ in text.commands)
    for w in text.words():
        for rx, what in BANNED_TEXT:
            m = rx.search(w)
            if m and not (what == "an Epicbox host" and FILE_EXT.search(m.group(0))):
                out.append(f"{what}: {w}")
    for line in joined.splitlines():
        m = SEND.search(line)
        if m:
            out.append(f"a wallet send: {line.strip()}")
    return out


def python_findings(src):
    """Findings in a Python script: banned text outside comments and banned subprocess commands."""
    out = []
    code = "\n".join(re.sub(r"(^|\s)#.*$", "", ln) for ln in src.splitlines())
    for rx, what in BANNED_TEXT:
        for m in rx.finditer(code):
            if not (what == "an Epicbox host" and FILE_EXT.search(m.group(0))):
                out.append(f"{what}: {m.group(0)}")
    for m in re.finditer(r"[\[(]\s*['\"]([^'\"]+)['\"]", code):
        if base(m.group(1)) in BANNED_COMMANDS:
            out.append(f"runs {m.group(1)}")
    return out


class Checker:
    def __init__(self, root):
        self.root = Path(root)
        self.errors, self.warnings = [], []
        self.scripts = set()
        allowed = self.root / "tools" / "workflow-actions.txt"
        self.allowed_actions = set()
        if allowed.is_file():
            for ln in allowed.read_text().splitlines():
                ln = ln.split("#", 1)[0].strip()
                if ln:
                    self.allowed_actions.add(ln.lower())

    def err(self, where, msg):
        self.errors.append(f"{where}: {msg}")

    def files(self):
        gh = self.root / ".github"
        out = sorted(p for p in (gh / "workflows").glob("*") if p.suffix in (".yml", ".yaml"))
        return out + sorted((gh / "actions").glob("*/action.y*ml"))

    def rel(self, p):
        try:
            return str(Path(p).resolve().relative_to(self.root.resolve()))
        except ValueError:
            return str(p)

    def check_file(self, path):
        path = Path(path)
        where = self.rel(path)
        raw = path.read_text()
        try:
            doc = yaml.safe_load(raw)
        except yaml.YAMLError as e:
            self.err(where, f"not YAML: {e}")
            return
        if not isinstance(doc, dict):
            self.err(where, "not a mapping")
            return
        if re.search(r"\bsecrets\s*[.\[]", raw):
            self.err(where, "references secrets")
        for no, ln in enumerate(raw.splitlines(), 1):
            m = re.match(r"\s*(-\s+)?uses:\s*(\S+)(.*)$", ln)
            if m and not m.group(2).startswith("./") and not re.search(r"#\s*v\d", m.group(3)):
                self.err(f"{where}:{no}", f"uses {m.group(2)} without a version comment (# vX.Y.Z)")
        if "runs" in doc:
            self.check_action(where, doc)
        else:
            self.check_workflow(where, doc)

    def check_action(self, where, doc):
        runs = doc.get("runs") or {}
        if runs.get("using") != "composite":
            self.err(where, f"runs.using is {runs.get('using')!r}: only composite local actions")
            return
        for k, step in enumerate(runs.get("steps") or [], 1):
            self.check_step(f"{where} step {k}", step, step.get("shell") or "bash")

    def check_workflow(self, where, doc):
        on = doc.get("on", doc.get(True))
        if on is None:
            self.err(where, "no on:")
            on = {}
        triggers = {on: None} if isinstance(on, str) else ({t: None for t in on} if isinstance(on, list) else on)
        for t, conf in triggers.items():
            if t not in ALLOWED_TRIGGERS:
                self.err(where, f"trigger {t}: only {', '.join(sorted(ALLOWED_TRIGGERS))}")
            if t == "push" and (not isinstance(conf, dict) or not conf.get("branches") or "tags" in conf
                                or "tags-ignore" in conf or "branches-ignore" in conf):
                self.err(where, "push must name its branches (and no tags)")
        if "permissions" not in doc:
            self.err(where, "no top-level permissions")
        else:
            self.check_permissions(where, doc["permissions"])
        conc = doc.get("concurrency")
        if not (isinstance(conc, str) and conc) and not (isinstance(conc, dict) and conc.get("group")):
            self.err(where, "no concurrency group")
        inputs = {}
        if isinstance(on, dict) and isinstance(on.get("workflow_dispatch"), dict):
            inputs = on["workflow_dispatch"].get("inputs") or {}
        default_shell = ((doc.get("defaults") or {}).get("run") or {}).get("shell")
        jobs = doc.get("jobs") or {}
        total = 0
        for name, job in jobs.items():
            jw = f"{where} job {name}"
            if "uses" in job:
                self.err(jw, "calls a reusable workflow")
                continue
            t = job.get("timeout-minutes")
            if not isinstance(t, int) or isinstance(t, bool) or not 0 < t <= MAX_TIMEOUT:
                self.err(jw, f"timeout-minutes is {t!r}: needs a number up to {MAX_TIMEOUT}")
            if "permissions" in job:
                self.check_permissions(jw, job["permissions"])
            total += self.fan_out(jw, (job.get("strategy") or {}).get("matrix"), inputs)
            if "container" in job or "services" in job:
                self.err(jw, "has a container or services")
            shell = ((job.get("defaults") or {}).get("run") or {}).get("shell") or default_shell
            runs_on = str(job.get("runs-on", ""))
            for k, step in enumerate(job.get("steps") or [], 1):
                self.check_step(f"{jw} step {step.get('name') or step.get('uses') or k}", step,
                                step.get("shell") or shell or ("pwsh" if "windows" in runs_on else "bash"))
        if total > MAX_JOBS:
            self.err(where, f"up to {total} jobs per run: at most {MAX_JOBS}")

    def check_permissions(self, where, perms):
        if not isinstance(perms, dict):
            if perms not in ({}, None):
                self.err(where, f"permissions {perms!r}: list each one")
            return
        for k, v in perms.items():
            allowed = ALLOWED_PERMISSIONS.get(k)
            if v == "none":
                continue
            if allowed is None or v not in LEVEL or LEVEL[v] > LEVEL[allowed]:
                self.err(where, f"permission {k}: {v}")

    def fan_out(self, where, matrix, inputs):
        if matrix is None:
            return 1
        if isinstance(matrix, str):
            self.err(where, "a matrix from an expression: its size is unknown")
            return MAX_JOBS + 1
        n, axes = 1, 0
        for key, values in matrix.items():
            if key in ("include", "exclude"):
                continue
            axes += 1
            if isinstance(values, list):
                n *= len(values)
                continue
            m = re.fullmatch(r"\$\{\{\s*fromJSON\(\s*inputs\.([A-Za-z0-9_-]+)\s*\)\s*\}\}", str(values).strip())
            size = None
            if m and m.group(1) in inputs:
                inp = inputs[m.group(1)] or {}
                if inp.get("type") == "choice":
                    size = len(inp.get("options") or [])
                else:
                    a = re.search(r"\[[^\[\]]*\]", str(inp.get("description", "")))
                    try:
                        size = len(json.loads(a.group(0))) if a else None
                    except ValueError:
                        size = None
            if size is None:
                self.err(where, f"matrix axis {key}: its size is unknown (a list, or fromJSON(inputs.X) "
                                "whose description holds the JSON array of its values)")
                return MAX_JOBS + 1
            n *= size
        include = matrix.get("include") or []
        # Excludes are not subtracted: the count stays an upper bound.
        return (n if axes else 0) + (len(include) if isinstance(include, list) else MAX_JOBS + 1)

    def check_step(self, where, step, shell):
        uses = step.get("uses")
        if uses:
            self.check_uses(where, uses)
        run = step.get("run")
        if run is None:
            return
        shell = str(shell).split()[0].lower()
        if shell in ("bash", "sh", "pwsh", "powershell"):
            text = Text(str(run), pwsh=shell in ("pwsh", "powershell"))
            for f in command_findings(text):
                self.err(where, f)
            for script in self.named_scripts(text):
                self.check_script(where, script)
        else:
            self.err(where, f"shell {shell}: only bash, sh and pwsh are checked")

    def check_uses(self, where, uses):
        if uses.startswith("./"):
            p = self.root / uses
            if not ((p / "action.yml").is_file() or (p / "action.yaml").is_file()):
                self.err(where, f"uses {uses}: no such local action")
            return
        if uses.startswith("docker://"):
            self.err(where, f"uses {uses}: no docker actions")
            return
        m = re.fullmatch(r"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_./-]+)?)@([0-9a-f]{40})", uses)
        if not m:
            self.err(where, f"uses {uses}: pin it by its full commit SHA")
            return
        if m.group(1).lower() not in self.allowed_actions:
            self.err(where, f"uses {m.group(1)}: not in tools/workflow-actions.txt")

    def named_scripts(self, text):
        out = []
        for w in text.words():
            w = w.replace("\\", "/")
            w = re.sub(r"^(\./|\$\{?GITHUB_WORKSPACE\}?/|\$env:GITHUB_WORKSPACE/|\$\{?root\}?/|GHEXPR/)", "", w)
            if w.endswith(SCRIPT_EXT) and not re.search(r"[$*\s]", w) and not w.startswith("-"):
                out.append(w)
        return out

    def check_script(self, where, rel):
        p = self.root / rel
        if not p.is_file():
            self.warnings.append(f"{where}: names {rel}, not in the repository: not scanned")
            return
        src = p.read_text(errors="replace")
        self.scripts.add(rel)
        if rel.endswith(".py"):
            found = python_findings(src)
        else:
            found = command_findings(Text(src, pwsh=rel.endswith(".ps1")))
        for f in found:
            self.err(f"{where}: {rel}", f)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent.parent))
    ap.add_argument("files", nargs="*")
    a = ap.parse_args(argv)
    c = Checker(a.root)
    files = [Path(f) for f in a.files] or c.files()
    for f in files:
        c.check_file(f)
    for w in c.warnings:
        print(f"warning: {w}")
    for e in c.errors:
        print(f"error: {e}")
    if c.errors:
        print(f"check-workflow: {len(c.errors)} finding(s)")
        return 1
    print(f"check-workflow: ok ({len(files)} files, {len(c.scripts)} scripts scanned)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
