#!/usr/bin/env python3
"""Generates the licences page (index.html, licences.css, licences.js: the site's CSP allows no inline script or style) for a build of the app.

It holds everything the app's LicenseRegistry holds: the Dart/Flutter packages' NOTICES
(from `flutter build bundle`) and the licences the app registers itself (fonts, word lists,
Tor, and the other bundled assets). The page is static, dark by default, searchable, one
collapsible block per package.

  python3 tool/licences/gen_licences.py [--out DIR] [--version X.Y.Z]

Run it from anywhere inside the app repo; it runs `flutter build bundle` and
`flutter test tool/licences/dump_licences_test.dart` in app/. Publish DIR's three files at
https://epiccash.btlabs.uk/licences/ (landing repo: site/licences/).
"""
import argparse, html, json, os, re, subprocess, sys, tempfile
from pathlib import Path

APP = Path(__file__).resolve().parents[2]


def name_of(n):  # sentence case, as the app listed it: "tor" -> "Tor"; a name with a capital stays
    return n if not n or n != n.lower() else n[0].upper() + n[1:]


def version():
    m = re.search(r"^version:\s*(\S+)", (APP / "pubspec.yaml").read_text(), re.M)
    return m.group(1).split("+")[0] if m else ""


def collect(work):
    subprocess.run(["flutter", "build", "bundle", "--target=lib/main.dart"], cwd=APP, check=True)
    out = Path(work) / "licences.json"
    env = dict(os.environ, LICENCES_JSON=str(out), LICENCES_NOTICES=str(APP / "build/flutter_assets/NOTICES.Z"))
    subprocess.run(["flutter", "test", "tool/licences/dump_licences_test.dart"], cwd=APP, env=env, check=True)
    return json.loads(out.read_text())


def render(data, ver):
    names = sorted(data, key=lambda n: name_of(n).lower())
    total = sum(len(v) for v in data.values())
    parts = []
    for n in names:
        texts = data[n]
        label = f"{len(texts)} licence" + ("" if len(texts) == 1 else "s")
        body = "".join(f"<pre>{html.escape(t)}</pre>" for t in texts)
        parts.append(
            f'<details data-name="{html.escape(name_of(n).lower(), quote=True)}" id="{html.escape(re.sub(r"[^a-z0-9]+", "-", n.lower()).strip("-"), quote=True)}">'
            f"<summary><span class=n>{html.escape(name_of(n))}</span><span class=c>{label}</span></summary>{body}</details>"
        )
    return (TEMPLATE.replace("@@VER@@", html.escape(ver)).replace("@@COUNT@@", str(len(names)))
            .replace("@@TOTAL@@", str(total)).replace("@@ITEMS@@", "\n".join(parts)))


CSS = r""":root{--bg:#14110e;--card:#1d1915;--fg:#ece5dc;--dim:#9c9286;--line:#312b24;--acc:#e0b072;color-scheme:dark}
:root[data-theme=light]{--bg:#f7f2ea;--card:#fffdf9;--fg:#2a2118;--dim:#75695c;--line:#e3d9cb;--acc:#8a5a1f;color-scheme:light}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.5 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
main{max-width:860px;margin:0 auto;padding:20px 16px 64px}
header{display:flex;gap:12px;align-items:flex-start;justify-content:space-between}
h1{font-size:1.6rem;margin:.4em 0 .2em}
p.lead{color:var(--dim);margin:0 0 16px}
button.t{background:var(--card);color:var(--fg);border:1px solid var(--line);border-radius:10px;min-height:44px;padding:0 14px;font:inherit;cursor:pointer}
.bar{position:sticky;top:0;background:var(--bg);padding:10px 0;z-index:2}
input[type=search]{width:100%;min-height:48px;border-radius:12px;border:1px solid var(--line);background:var(--card);color:var(--fg);padding:0 14px;font:inherit}
.bar .s{display:flex;gap:8px;margin-top:8px;align-items:center;color:var(--dim);font-size:.9rem}
.bar .s button{background:none;border:0;color:var(--acc);font:inherit;min-height:44px;padding:0 6px;cursor:pointer;text-decoration:underline}
details{background:var(--card);border:1px solid var(--line);border-radius:12px;margin:8px 0}
summary{display:flex;justify-content:space-between;gap:12px;align-items:center;min-height:56px;padding:8px 14px;cursor:pointer;list-style:none}
summary::-webkit-details-marker{display:none}
summary::after{content:"+";color:var(--dim);font-size:1.3rem;margin-left:auto;order:3}
details[open]>summary::after{content:"\2212"}
.n{font-weight:600;overflow-wrap:anywhere}.c{color:var(--dim);font-size:.9rem;white-space:nowrap}
pre{margin:0;padding:12px 14px;border-top:1px solid var(--line);font:12.5px/1.45 ui-monospace,"JetBrains Mono",Menlo,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere}
a{color:var(--acc)}
:focus-visible{outline:2px solid var(--acc);outline-offset:2px}
[hidden]{display:none!important}
"""

JS = r"""(function(){
var r=document.documentElement,b=document.getElementById('theme'),k='licences-theme';
function set(t){r.dataset.theme=t;b.textContent=t==='light'?'Dark':'Light'}
try{set(localStorage.getItem(k)==='light'?'light':'dark')}catch(e){set('dark')}
b.onclick=function(){var t=r.dataset.theme==='light'?'dark':'light';set(t);try{localStorage.setItem(k,t)}catch(e){}};
var items=[].slice.call(document.querySelectorAll('details')),q=document.getElementById('q'),n=document.getElementById('n'),e=document.getElementById('empty');
var texts=null;
function filter(){
 var v=q.value.trim().toLowerCase(),shown=0;
 if(v&&!texts)texts=items.map(function(d){return d.textContent.toLowerCase()});
 items.forEach(function(d,i){
  var hit=!v||d.dataset.name.indexOf(v)>=0||texts[i].indexOf(v)>=0;
  d.hidden=!hit;if(hit)shown++;
  if(v&&hit&&d.dataset.name.indexOf(v)<0)d.open=true;
 });
 n.textContent=v?shown+' of '+items.length+' packages':items.length+' packages';
 e.hidden=shown>0;
}
q.addEventListener('input',filter);
document.getElementById('all').onclick=function(){items.forEach(function(d){if(!d.hidden)d.open=true})};
document.getElementById('none').onclick=function(){items.forEach(function(d){d.open=false})};
if(location.hash){var t=document.getElementById(location.hash.slice(1));if(t)t.open=true}
filter();
})();
"""

TEMPLATE = r"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="dark light">
<title>Epic Wallet licences</title>
<meta name="description" content="Licence texts of the software in Epic Wallet @@VER@@.">
<link rel="icon" href="/favicon.svg">
<link rel="stylesheet" href="licences.css"></head><body><main>
<header><div><h1>Licences</h1>
<p class="lead">Licence texts of the software in Epic Wallet @@VER@@: @@COUNT@@ packages, @@TOTAL@@ texts. Epic Wallet itself is Apache-2.0 (<a href="https://github.com/BTLabsUK/wallet-for-epic">source</a>).</p></div>
<button class="t" id="theme" type="button" aria-label="Switch light or dark theme">Light</button></header>
<div class="bar"><input id="q" type="search" placeholder="Search packages and texts" aria-label="Search packages and texts" autocomplete="off">
<div class="s"><span id="n" role="status" aria-live="polite"></span><button type="button" id="all">Expand all</button><button type="button" id="none">Collapse all</button></div></div>
<div id="list">
@@ITEMS@@
</div>
<p id="empty" class="lead" hidden>No package matches.</p>
</main>
<script src="licences.js" defer></script></body></html>
"""

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(APP / "build/licences"))
    ap.add_argument("--version", default=None)
    a = ap.parse_args()
    with tempfile.TemporaryDirectory() as w:
        data = collect(w)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "index.html").write_text(render(data, a.version or version()), encoding="utf-8")
    (out / "licences.css").write_text(CSS, encoding="utf-8")
    (out / "licences.js").write_text(JS, encoding="utf-8")
    print(f"wrote {out / 'index.html'} ({len(data)} packages)")
