#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Step `screens-check` of tools/rel, before the publish gate: reads the release's screen catalogue
(step `screens`, tools/screens.sh --candidate) and the real-build screens the G4 trust drivers left,
compares them with the published release's catalogue, and says what the owner should look at before
he approves. Its summary goes into the publish-gate message (builtins.gate_summary).

  screens_check.py <version> <stage dir>      (env REL_RUN REL_SRC REL_PREVIOUS_VERSION REL_DRY_RUN)

FAIL (the step fails, the gate is not asked until it is fixed, or skipped with a reason):
  tours     a tour test failed (an overflow or an exception fails its shot) or no catalogue was made
  drop      a platform has more than 10% fewer screens than the published release
  raw-key   an l10n key name on screen instead of its text
  icu       an unfilled {placeholder} on screen
  debug     debug or placeholder text (TODO, FIXME, lorem ipsum, "Instance of '", NaN, null, ...)
            (on dev, demo and experimental screens these are warnings)
WARN (shown in the gate message, never holds anything):
  gone      a screen the published release had and this one has not (renamed or removed)
  host      a domain, IP, onion or URL on a screen that did not show it in the published release
  network   mainnet / floonet / floo on a screen that did not show it in the published release
  empty     an empty-state or error text on a screen that did not show it in the published release
  l10n      keys shown on screens that a translation lacks or leaves in English
  real      real-build screens a trust driver could not take; OCR finds on them (raw keys, debug)
INFO: the visual diff (changed / new / unchanged screens) with before | after | diff images.

Writes <stage>/summary.json, <stage>/summary.txt (the gate's lines), <stage>/report/index.html
(dark, light as a toggle; images inside, so the folder can be published as it is) and, when
~/.config/btlabs/screens-publish.env sets SCREENS_REPORT_PUBLISH (a command given the report folder
and a title that prints the page's URL on its last line), <stage>/links.json. Copies the trust
drivers' screens into <catalogue>/real/<platform>-<variant>/ (never into the public gallery,
which is built from manifest.json's images only). Tour screens are test renders: they prove
nothing about an installed update; the trust checks do. Standard library and Pillow only.
"""

import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

DROP_LIMIT = 0.10          # a platform losing more than this share of its screens fails
DIFF_PIXELS = 0.001        # a screen whose pixels differ by more than this share counts as changed
MAX_DIFF_IMAGES = 400      # before | after | diff composites in the report
LIST_MAX = 12              # findings listed per kind in summary.txt

SOFT_AREAS = {"dev", "demo", "experimental"}
HOST = re.compile(r"(?:https?|wss?)://\S+|\b[a-z2-7]{16,56}\.onion\b|\b\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?\b"
                  r"|\b(?:[a-z0-9-]+\.)+(?:com|net|org|io|uk|us|id|dev|app|cash|xyz|info|me|co)\b", re.I)
NETWORK = re.compile(r"\b(mainnet|floonet|floo)\b", re.I)
DEBUG = re.compile(r"\bTODO\b|\bFIXME\b|\bXXX\b|lorem ipsum|Instance of '|_Exception\b|StackTrace|"
                   r"\bNaN\b|\bInfinity\b|^null$|^undefined$|\bnull\b(?= EPIC)|\bdebugPrint\b|"
                   r"\bassert(?:ion)? failed\b|LateInitializationError|Null check operator", re.I)
ICU = re.compile(r"\{[A-Za-z_][A-Za-z0-9_]*\}")
KEYLIKE = re.compile(r"^(?:desk|ph|phone|onb|set|adv|help|tour)[A-Z][A-Za-z0-9]+$")
EMPTY = re.compile(r"\b(?:no \w+ yet|nothing (?:here|yet)|something went wrong|failed|error|"
                   r"can[’']t (?:reach|load|open|read)|couldn[’']t|unable to|not available|unreachable|offline)\b", re.I)


def log(*a):
    print("screens-check:", *a, flush=True)


def read_json(p, default=None):
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def rows_of(cat):
    p = Path(cat) / "screens.jsonl"
    if not p.is_file():
        return {}
    out = {}
    for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            r = json.loads(line)
        except ValueError:
            continue
        out[r["code"]] = r
    return out


def area_of(row):
    parts = row["code"].split("/")
    return parts[1] if len(parts) > 2 else ""


def soft(row):
    return area_of(row) in SOFT_AREAS or row.get("experimental")


def norm_text(texts, versions):
    out = []
    for t in texts:
        for v in versions:
            if v:
                t = t.replace(v, "<version>")
        out.append(re.sub(r"\b[0-9a-f]{9,12}\b", "<commit>", t))
    return out


def tour_failures(logdir):
    """[(tour, test name, first error line)] from the JSON reporter logs of tools/screens.sh."""
    out = []
    for lp in sorted(Path(logdir).glob("*.log")) if logdir and Path(logdir).is_dir() else []:
        names, errors = {}, {}
        for line in lp.read_text(errors="replace").splitlines():
            if not line.startswith("{"):
                continue
            try:
                e = json.loads(line)
            except ValueError:
                continue
            t = e.get("type")
            if t == "testStart":
                names[e["test"]["id"]] = e["test"]["name"]
            elif t == "error":
                msg = str(e.get("error", "")).strip()
                m = re.search(r"overflowed by [0-9.]+ pixels on the \w+", msg)
                first = m.group(0) if m else (msg.splitlines() or [""])[0]
                errors.setdefault(e.get("testID"), first[:200])
            elif t == "testDone" and e.get("result") != "success" and not e.get("hidden"):
                n = names.get(e["testID"], "?")
                if not n.startswith("loading "):
                    out.append((lp.stem, n, errors.get(e["testID"], e.get("result", ""))))
    return out


def arb_keys(src):
    d = Path(src or "") / "app" / "lib" / "l10n"
    en = read_json(d / "app_en.arb", {}) or {}
    keys = {k: v for k, v in en.items() if not k.startswith("@") and isinstance(v, str)}
    langs = {}
    for p in sorted(d.glob("app_*.arb")):
        lang = p.stem[4:]
        if lang != "en":
            langs[lang] = {k: v for k, v in (read_json(p, {}) or {}).items() if not k.startswith("@")}
    return keys, langs


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def pixel_change(a, b):
    """Share of pixels that differ (1.0 when the sizes differ), or None when unreadable."""
    from PIL import Image, ImageChops
    try:
        ia, ib = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
    except OSError:
        return None
    if ia.size != ib.size:
        return 1.0
    d = ImageChops.difference(ia, ib).convert("L").point(lambda x: 255 if x > 24 else 0)
    hist = d.histogram()
    return hist[255] / float(ia.size[0] * ia.size[1])


def composite(a, b, out, width=1200):
    """before | after | diff (changed pixels in red over a dimmed after)."""
    from PIL import Image, ImageChops
    ia, ib = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
    if ia.size != ib.size:
        ia = ia.resize(ib.size)
    mask = ImageChops.difference(ia, ib).convert("L").point(lambda x: 255 if x > 24 else 0)
    red = Image.new("RGB", ib.size, (255, 40, 60))
    dim = Image.blend(ib, Image.new("RGB", ib.size, (0, 0, 0)), 0.6)
    dimg = Image.composite(red, dim, mask)
    w, h = ib.size
    sheet = Image.new("RGB", (w * 3 + 16, h), (20, 20, 24))
    for i, im in enumerate((ia, ib, dimg)):
        sheet.paste(im, (i * (w + 8), 0))
    sheet.thumbnail((width, width))
    sheet.save(out, "JPEG", quality=80)


def thumb(src, out, size=480):
    from PIL import Image
    im = Image.open(src).convert("RGB")
    im.thumbnail((size, size))
    im.save(out, "JPEG", quality=80)


def ocr(png):
    if not shutil.which("tesseract"):
        return None
    try:
        r = subprocess.run(["tesseract", str(png), "-", "--psm", "11"], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.SubprocessError):
        return None
    return [t.strip() for t in r.stdout.splitlines() if t.strip()] if r.returncode == 0 else None


def collect_real(run, cat, root, rep):
    """The trust drivers' REL_OUT/screens/ → <catalogue>/real/<platform>-<variant>/ (under the
    catalogue's lock) and the report. -> {label: info}."""
    import fcntl
    found = {}
    for sj in sorted(Path(run).glob("steps/trust-*/out/screens/screens.json")) if run else []:
        # steps/trust-<platform>-<variant>/out/screens/screens.json -> <platform>-<variant>
        label = sj.parts[-4][len("trust-"):]
        found[label] = {"dir": sj.parent, "meta": read_json(sj, {}) or {}}
    if not found:
        return {}
    if cat and Path(cat, "manifest.json").is_file():
        with open(Path(root) / ".lock", "a") as lk:
            locked, deadline = False, time.time() + 600
            while not locked and time.time() < deadline:
                try:
                    fcntl.flock(lk, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    locked = True
                except BlockingIOError:
                    time.sleep(5)
            if not locked:
                log("catalogue lock busy for 10 min: real screens not copied into the catalogue")
            else:
                real = Path(cat) / "real"
                for label, f in found.items():
                    dest = real / label
                    if dest.exists():
                        shutil.rmtree(dest)
                    shutil.copytree(f["dir"], dest)
                index = {label: f["meta"] for label, f in found.items()}
                (real / "index.json").write_text(json.dumps(index, indent=1, ensure_ascii=False))
    os.makedirs(rep / "real", exist_ok=True)
    for label, f in found.items():
        for s in f["meta"].get("shots", []):
            p = f["dir"] / s.get("file", "")
            if p.is_file():
                out = rep / "real" / f"{label}-{Path(s['file']).stem}.jpg"
                try:
                    thumb(p, out, 640)
                    s["_thumb"] = str(out.relative_to(rep))
                except OSError:
                    pass
                s["_path"] = p
    return found


def main(argv):
    if len(argv) != 3:
        print(f"usage: {argv[0]} <version> <stage dir>", file=sys.stderr)
        return 2
    version, stage = argv[1], Path(argv[2])
    run, src = os.environ.get("REL_RUN", ""), os.environ.get("REL_SRC", "")
    prev_v = os.environ.get("REL_PREVIOUS_VERSION", "")
    root = Path(os.environ.get("SCREENS_ROOT", os.path.expanduser("/tmp/epic-build/screens")))
    cat = root / version
    if os.environ.get("REL_DRY_RUN") == "1":
        log(f"dry run: would check {cat} against the published catalogue ({prev_v or 'latest'}), copy the trust "
            f"drivers' screens into {cat}/real/, write {stage}/summary.json and report/")
        return 0
    stage.mkdir(parents=True, exist_ok=True)
    rep = stage / "report"
    if rep.exists():
        shutil.rmtree(rep)
    (rep / "img").mkdir(parents=True)

    fails, warns, info = [], [], {}

    def add(level, kind, text, code=None, extra=None):
        (fails if level == "fail" else warns).append({"kind": kind, "text": text, "code": code, **(extra or {})})

    # ---- the render ----
    render = read_json(Path(run) / "steps" / "screens" / "out" / "render.json", {}) if run else {}
    rstatus = read_json(Path(run) / "steps" / "screens" / "status.json", {}) if run else {}
    if rstatus.get("status") == "skipped":
        add("warn", "tours", f"step screens was skipped ({rstatus.get('reason', '')}): no catalogue checked")
    have = (cat / "manifest.json").is_file() and (not render or render.get("ok"))
    if not have and rstatus.get("status") != "skipped":
        logs = root / f"failed-{version}.logs"
        tf = tour_failures(logs)
        add("fail", "tours", f"no catalogue for {version}" + (f": {len(tf)} tour tests failed" if tf else
                                                               f" ({render.get('note') or rstatus.get('note') or 'the render did not finish'})"))
        for tour, name, err in tf:
            add("fail", "tours", f"{tour}: {name}: {err}")
    cur = rows_of(cat) if have else {}
    if have:
        for tour, name, err in tour_failures(cat / "logs"):
            add("fail", "tours", f"{tour}: {name}: {err}")

    # ---- the baseline: the published release's catalogue ----
    base_v = prev_v if prev_v and prev_v != version and (root / prev_v / "manifest.json").is_file() else ""
    if not base_v:
        lt = os.path.basename(os.readlink(root / "latest")) if (root / "latest").is_symlink() else ""
        base_v = lt if lt and lt != version and (root / lt / "manifest.json").is_file() else ""
    base = rows_of(root / base_v) if base_v else {}
    info["baseline"] = base_v or None
    if cur and not base:
        add("warn", "gone", "no published catalogue to compare with: no diff, no gone/new screens")

    keys, langs = arb_keys(src)
    versions = [version, base_v]

    # ---- per screen ----
    for code, r in sorted(cur.items()):
        texts = r.get("text", [])
        lvl = "warn" if soft(r) else "fail"
        old = base.get(code)
        old_text = " \n".join(old.get("text", [])) if old else None
        for t in texts:
            if t in keys or KEYLIKE.match(t):
                add(lvl, "raw-key", f"{code}: “{t[:80]}”", code)
            for m in ICU.finditer(t):
                add(lvl, "icu", f"{code}: {m.group(0)} in “{t[:80]}”", code)
            m = DEBUG.search(t)
            if m:
                add(lvl, "debug", f"{code}: “{t[:80]}”", code)
        joined = " \n".join(texts)
        if base:
            for kind, rx in (("host", HOST), ("network", NETWORK), ("empty", EMPTY)):
                now = {m.group(0).lower() for m in rx.finditer(joined)}
                was = {m.group(0).lower() for m in rx.finditer(old_text)} if old_text is not None else set()
                for w in sorted(now - was):
                    add("warn", kind, f"{code}: {w}" + ("" if old else " (new screen)"), code)

    # ---- screens gone, counts ----
    if base and cur:
        for plat in sorted({c.split("/")[0] for c in base} | {c.split("/")[0] for c in cur}):
            nb = sum(1 for c in base if c.startswith(plat + "/"))
            nc = sum(1 for c in cur if c.startswith(plat + "/"))
            info.setdefault("counts", {})[plat] = {"now": nc, "before": nb}
            if nb and nc < nb * (1 - DROP_LIMIT):
                add("fail", "drop", f"{plat}: {nc} screens, the published release had {nb}")
        for code in sorted(set(base) - set(cur)):
            add("warn", "gone", code, code)

    # ---- translations of the keys the screens show ----
    shown = sorted({k for r in cur.values() for k in r.get("l10n_keys", [])})
    if shown and langs:
        l10n = {}
        for lang, tr in langs.items():
            missing = [k for k in shown if k in keys and k not in tr]
            same = [k for k in shown if k in keys and tr.get(k) == keys[k] and len(re.findall(r"[A-Za-z]{3,}", keys[k])) >= 2]
            l10n[lang] = {"missing": len(missing), "english": len(same), "examples": (missing + same)[:5]}
            if missing or same:
                add("warn", "l10n", f"{lang}: {len(missing)} keys missing, {len(same)} left in English "
                                    f"(of {len(shown)} on screens), e.g. {', '.join((missing + same)[:3])}")
        info["l10n"] = l10n

    # ---- visual diff ----
    diff = {"changed": [], "new": sorted(set(cur) - set(base)) if base else [], "unchanged": 0, "text_changed": 0}
    if base and cur:
        both = sorted(set(cur) & set(base))

        def one(code):
            a, b = root / base_v / base[code]["file"], cat / cur[code]["file"]
            if not a.is_file() or not b.is_file():
                return code, None, False
            if sha(a) == sha(b):
                return code, 0.0, False
            tc = norm_text(base[code].get("text", []), versions) != norm_text(cur[code].get("text", []), versions)
            return code, pixel_change(a, b), tc

        with ThreadPoolExecutor(max_workers=min(8, os.cpu_count() or 2)) as pool:
            for code, ch, tc in pool.map(one, both):
                if ch is None or ch > DIFF_PIXELS or tc:
                    diff["changed"].append({"code": code, "pixels": None if ch is None else round(ch, 4), "text": tc})
                    diff["text_changed"] += 1 if tc else 0
                else:
                    diff["unchanged"] += 1
        diff["changed"].sort(key=lambda d: (not d["text"], -(d["pixels"] or 1)))

        def comp(i_d):
            i, d = i_d
            out = rep / "img" / f"diff-{i:04d}.jpg"
            try:
                composite(root / base_v / base[d["code"]]["file"], cat / cur[d["code"]]["file"], out)
                d["img"] = str(out.relative_to(rep))
            except OSError:
                pass

        with ThreadPoolExecutor(max_workers=min(8, os.cpu_count() or 2)) as pool:
            list(pool.map(comp, enumerate(diff["changed"][:MAX_DIFF_IMAGES])))
    info["diff"] = {"changed": len(diff["changed"]), "new": len(diff["new"]), "unchanged": diff["unchanged"],
                    "text_changed": diff["text_changed"], "gone": sum(1 for w in warns if w["kind"] == "gone" and w["code"])}

    # Pictures of the screens a finding names (the first few of each kind).
    seen = {}
    for f in fails + warns:
        c = f.get("code")
        if c and c in cur and seen.get(f["kind"], 0) < 30:
            seen[f["kind"]] = seen.get(f["kind"], 0) + 1
            out = rep / "img" / ("shot-" + c.replace("/", "_") + ".jpg")
            if not out.exists():
                try:
                    thumb(cat / cur[c]["file"], out)
                except OSError:
                    continue
            f["img"] = str(out.relative_to(rep))

    # ---- real-build screens from the trust drivers ----
    real = collect_real(run, cat if have else None, root, rep)
    info["real"] = {}
    for label, f in real.items():
        shots, missing = f["meta"].get("shots", []), f["meta"].get("missing", [])
        info["real"][label] = {"shots": len(shots), "missing": len(missing)}
        for m in missing:
            add("warn", "real", f"{label}: no {m.get('code')} ({m.get('reason', '')})")
        for s in shots:
            words = s.get("text") or (ocr(s["_path"]) if s.get("_path") else None) or []
            for t in words:
                if KEYLIKE.match(t) or (t in keys and len(t) > 8) or DEBUG.search(t):
                    add("warn", "real", f"{label} {s.get('code')}: “{t[:80]}” (OCR)" if not s.get("text") else
                        f"{label} {s.get('code')}: “{t[:80]}”")
    for sid in sorted({p.parts[-2] for p in Path(run).glob("steps/trust-*/out")}) if run else []:
        if sid[len("trust-"):] not in real:
            add("warn", "real", f"{sid}: left no screens/ (a driver without screenshots, or it stopped early)")

    # ---- out ----
    def line_of(kind, items):
        return f"{kind} ({len(items)}): " + "; ".join(i["text"] for i in items[:LIST_MAX]) + (" …" if len(items) > LIST_MAX else "")

    def by_kind(items):
        out = {}
        for i in items:
            out.setdefault(i["kind"], []).append(i)
        return out

    d = info["diff"]
    head = (f"Screens {version} vs {base_v or 'nothing'}: {len(fails)} FAIL, {len(warns)} warn · changed {d['changed']} "
            f"(text {d['text_changed']}), new {d['new']}, gone {d['gone']}, same {d['unchanged']}")
    if info["real"]:
        head += " · real builds: " + ", ".join(f"{k} {v['shots']}" for k, v in sorted(info["real"].items()))
    lines = [head]
    for kind, items in by_kind(fails).items():
        lines.append("FAIL " + line_of(kind, items))
    for kind, items in by_kind(warns).items():
        lines.append("warn " + line_of(kind, items))
    lines = [ln[:400] for ln in lines]

    write_report(rep, version, base_v, fails, warns, diff, info, real, cur)
    url = publish_report(rep, version)
    summary = {"version": version, "baseline": base_v or None, "ok": not fails, "fails": fails, "warns": warns,
               "diff": info["diff"], "counts": info.get("counts"), "l10n": info.get("l10n"), "real": info["real"],
               "report": str(rep / "index.html"), "url": url, "lines": lines}
    for f in fails + warns:
        f.pop("_path", None)
    (stage / "summary.json").write_text(json.dumps(summary, indent=1, ensure_ascii=False, default=str))
    (stage / "summary.txt").write_text("\n".join(lines) + "\n")
    if url:
        (stage / "links.json").write_text(json.dumps([{"label": f"Screens check {version}", "url": url}]))
    print("\n".join(lines))
    log(f"report {rep / 'index.html'}" + (f" · {url}" if url else " (publish it: no SCREENS_REPORT_PUBLISH)"))
    return 1 if fails else 0


def publish_report(rep, version):
    conf = os.environ.get("SCREENS_PUBLISH_CONF", os.path.expanduser("~/.config/btlabs/screens-publish.env"))
    cmd = os.environ.get("SCREENS_REPORT_PUBLISH", "")
    if not cmd and os.path.isfile(conf):
        for line in open(conf):
            if line.startswith("SCREENS_REPORT_PUBLISH="):
                cmd = line.split("=", 1)[1].strip().strip('"').strip("'")
    if not cmd:
        return None
    try:
        r = subprocess.run(["bash", "-c", cmd + ' "$1" "$2"', "publish", str(rep), f"Screens check {version}"],
                           capture_output=True, text=True, timeout=300)
    except (OSError, subprocess.SubprocessError) as e:
        log(f"report not published: {e}")
        return None
    last = (r.stdout.strip().splitlines() or [""])[-1].strip()
    if r.returncode or not re.match(r"https?://\S+$", last):
        log(f"report not published (exit {r.returncode}): {r.stderr.strip()[:200]}")
        return None
    return last


def write_report(rep, version, base_v, fails, warns, diff, info, real, cur):
    e = html.escape

    def finding(f, level):
        img = f'<img loading="lazy" src="{e(f["img"])}" alt="">' if f.get("img") else ""
        return f'<li class="{level}"><span class="k">{e(f["kind"])}</span> {e(f["text"])}{img}</li>'

    d = info["diff"]
    parts = [f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Screens check {e(version)}</title>
<style>
:root{{--bg:#111316;--fg:#e8e8ea;--mut:#9a9ca3;--card:#1b1e23;--line:#2a2e35;--fail:#ff5c6c;--warn:#f5b84a;--ok:#4fd18b}}
:root[data-theme=light]{{--bg:#f6f6f8;--fg:#17181b;--mut:#5b5e66;--card:#fff;--line:#dcdde2;--fail:#c41e3a;--warn:#a76500;--ok:#17834a}}
body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.45 system-ui,sans-serif}}
main{{max-width:1240px;margin:0 auto;padding:16px}} h1{{font-size:20px;margin:8px 0}} h2{{font-size:16px;margin:24px 0 8px}}
.mut{{color:var(--mut)}} ul{{list-style:none;padding:0;margin:0}} li{{background:var(--card);border:1px solid var(--line);
border-radius:8px;padding:8px 10px;margin:6px 0;overflow-wrap:anywhere}} li img{{display:block;max-width:100%;margin-top:8px;border-radius:4px}}
li.fail{{border-left:4px solid var(--fail)}} li.warn{{border-left:4px solid var(--warn)}} .k{{font-weight:600;margin-right:6px}}
.stats span{{display:inline-block;margin:0 12px 6px 0}} .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:10px}}
.grid figure{{margin:0;background:var(--card);border:1px solid var(--line);border-radius:8px;padding:8px}} figure img{{max-width:100%}}
figcaption{{font-size:13px;color:var(--mut);overflow-wrap:anywhere}} button{{float:right;background:var(--card);color:var(--fg);
border:1px solid var(--line);border-radius:6px;padding:4px 10px}} details summary{{cursor:pointer;margin:8px 0}}
</style></head><body><main>
<button onclick="var r=document.documentElement;r.dataset.theme=r.dataset.theme==='light'?'dark':'light'">Light / dark</button>
<h1>Screens check {e(version)}</h1>
<p class="mut">Tour renders of the release source compared with the published release {e(base_v or '(none)')}, before the
publish gate. Test renders prove nothing about an installed update: the G4 trust checks do that.</p>
<p class="stats"><span style="color:var(--fail)">{len(fails)} fail</span><span style="color:var(--warn)">{len(warns)} warn</span>
<span>changed {d['changed']} (text {d['text_changed']})</span><span>new {d['new']}</span><span>gone {d['gone']}</span>
<span>same {d['unchanged']}</span><span>{len(cur)} screens</span></p>"""]
    if fails:
        parts.append("<h2>Fail</h2><ul>" + "".join(finding(f, "fail") for f in fails) + "</ul>")
    if warns:
        parts.append("<h2>Warnings</h2><ul>" + "".join(finding(f, "warn") for f in warns[:600]) + "</ul>")
    if real:
        parts.append("<h2>Real builds (G4 trust drivers)</h2>")
        for label, f in sorted(real.items()):
            figs = "".join(f'<figure><img loading="lazy" src="{e(s["_thumb"])}" alt=""><figcaption>{e(s.get("code", ""))} · '
                           f'{e(s.get("version", ""))}</figcaption></figure>' for s in f["meta"].get("shots", []) if s.get("_thumb"))
            parts.append(f"<h2 class='mut'>{e(label)}</h2><div class='grid'>{figs or '<p class=mut>no screens</p>'}</div>")
    if diff["changed"]:
        parts.append(f"<h2>Changed since {e(base_v)} (before · after · diff)</h2>")
        def cap(c):
            return e(c["code"]) + (" · text changed" if c["text"] else "") + \
                ("" if c["pixels"] is None else " · %.1f%% pixels" % (c["pixels"] * 100))
        figs = "".join(f'<figure><img loading="lazy" src="{e(c["img"])}" alt=""><figcaption>{cap(c)}</figcaption></figure>'
                       for c in diff["changed"] if c.get("img"))
        parts.append(f"<div class='grid'>{figs}</div>")
        rest = [c["code"] for c in diff["changed"] if not c.get("img")]
        if rest:
            parts.append(f"<details><summary>{len(rest)} more changed</summary><p>{e(', '.join(rest))}</p></details>")
    if diff["new"]:
        parts.append(f"<details><summary>{len(diff['new'])} new screens</summary><p>{e(', '.join(diff['new']))}</p></details>")
    parts.append("</main></body></html>")
    (rep / "index.html").write_text("\n".join(parts), encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main(sys.argv))
