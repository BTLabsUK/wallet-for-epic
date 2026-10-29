#!/usr/bin/env python3
"""The public releases page for Epic Cash Desktop and Epic Cash Mobile.

    tools/releases/build.py add <version> <dir> [--date YYYY-MM-DD]
        Record a release from a folder holding its files and SHA256SUMS (the release lead's
        folder, e.g. /srv/wfe-release/26.10.24). Every file in SHA256SUMS whose name
        carries <version> is taken; its checksum is recomputed and must agree. Replaces an
        earlier record of the same version.
    tools/releases/build.py render [--out DIR]
        Write the page (index.html, style.css, page.js, theme.js, fonts/, img/) into DIR,
        the page repo's site/epic-cash/ by default ($WFE_RELEASES_SITE). Deploy from there
        with the page repo's ./deploy-epic-cash.sh.
    tools/releases/build.py import-listing <ls -l --time-style=+%Y-%m-%dT%H:%M output> <SHA256SUMS> [changelog.html]
        One-time import of what the server already holds (dates from the changelog's
        <time datetime> per version, else the file's time).

The data is releases.json next to this script: one record per version (version, date,
files with name, size and sha256). What a file is (platform, label, primary or folded) comes
from its name, see KINDS: a new kind of build needs one line there and nothing else.

The page is plain HTML and CSS: every download is a link, every fold a <details>. page.js adds
the copy buttons, the platform the browser reports (User-Agent Client Hints, then the user
agent) and the Other platforms switch; without it the page shows every platform the same way.
No tracking, nothing loaded from another host.
"""
import datetime as dt
import hashlib
import html
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, 'releases.json')
ASSETS = os.path.join(HERE, 'assets')
DEFAULT_OUT = os.environ.get('WFE_RELEASES_SITE') or os.path.expanduser('~/code/epic-gui-wallet-progress/site/epic-cash')

V = r'(\d+\.\d+\.\d+(?:-r\d+)?)'
# (pattern of the file name, platform, label, primary). The first match wins. A platform's
# primary file gets the big button; everything else sits in the platform's fold.
KINDS = [
    (rf'^epic-cash-desktop-{V}-windows-x64-setup\.exe$', 'windows', 'Installer', True),
    (rf'^epic-cash-desktop-{V}-notor-windows-x64-setup\.exe$', 'windows', 'Installer without Tor', False),
    (rf'^epic-cash-desktop-{V}-(?:notor-)?windows-x64-portable\.zip$', 'windows', 'Portable, zip', False),
    (rf'^.*-{V}-.*\.msix$', 'windows', 'MSIX package', False),
    (rf'^EpicCashDesktop-{V}-x86_64\.AppImage$', 'linux', 'AppImage', True),
    (rf'^EpicCashDesktop-{V}-notor-x86_64\.AppImage$', 'linux', 'AppImage without Tor', False),
    (rf'^.*-{V}-.*\.deb$', 'linux', 'Debian package', False),
    (rf'^.*-{V}-.*\.rpm$', 'linux', 'RPM package', False),
    (rf'^epic-cash-mobile-{V}-arm64-v8a\.apk$', 'android', 'APK, arm64', True),
    (rf'^epic-cash-mobile-{V}-notor-arm64-v8a\.apk$', 'android', 'APK without Tor, arm64', False),
    (rf'^epic-cash-mobile-{V}-(?:notor-)?universal\.apk$', 'android', 'APK, universal', False),
    (rf'^epic-cash-mobile-{V}-(?:notor-)?x86_64\.apk$', 'android', 'APK, x86_64 (emulators)', False),
    (rf'^EpicCashDesktop-{V}-macos\.dmg$', 'macos', 'Disk image', True),
    (rf'^EpicCashDesktop-{V}-notor-macos\.dmg$', 'macos', 'Disk image without Tor', False),
    (rf'^EpicCashMobile-{V}-ios-unsigned\.ipa$', 'ios', 'Unsigned IPA', True),
    (rf'^EpicCashMobile-{V}-notor-ios-unsigned\.ipa$', 'ios', 'Unsigned IPA without Tor', False),
    (rf'^EpicCashMobile-{V}-ios-simulator\.zip$', 'ios', 'Simulator app, for Xcode', False),
]
NOTOR = re.compile(r'-notor-')

# The platforms in the order they are shown. (key, heading, app, requirement line, preview)
PLATFORMS = [
    ('windows', 'Windows', 'Epic Cash Desktop', 'Windows 10 and 11, 64-bit', False),
    ('linux', 'Linux', 'Epic Cash Desktop', 'x86_64, AppImage', False),
    ('android', 'Android', 'Epic Cash Mobile', 'Android 7 or newer, arm64', False),
    ('macos', 'macOS', 'Epic Cash Desktop', 'macOS 12 or newer, Apple silicon and Intel', True),
    ('ios', 'iOS', 'Epic Cash Mobile', 'iPhone and iPad, iOS 15 or newer, sideloaded', True),
]
PLAT = {p[0]: p for p in PLATFORMS}

# The Android release key: shown so an APK can be checked against it (apksigner verify
# --print-certs). Signer certificate SHA-256, CN=BT Labs Epic Wallet, O=BT Labs.
ANDROID_CERT_SHA256 = '59e4c290f3922d8e7d3b189eb98e7002dc50754c52d612ea91e82386390ec0aa'

ICONS = {
    'windows': '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M3 5.3 10.4 4.3v7.2H3zm0 13.4 7.4 1V12.5H3zM11.2 4.2 21 2.8v8.7h-9.8zm0 8.3H21v8.7l-9.8-1.4z"/></svg>',
    'linux': '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" d="M12 2.6c-2.3 0-3.6 1.8-3.6 4 0 1 .2 1.7.5 2.4-1 1.3-2.4 3.4-2.8 5.5-.1.7-.1 1.4 0 2-.8.4-1.6.9-1.6 1.8 0 .8 1.2 1.1 2.6 1.4.8.2 1.8.9 2.7.9.7 0 1.2-.3 1.5-.6h1.4c.3.3.8.6 1.5.6.9 0 1.9-.7 2.7-.9 1.4-.3 2.6-.6 2.6-1.4 0-.9-.8-1.4-1.6-1.8.1-.6.1-1.3 0-2-.4-2.1-1.8-4.2-2.8-5.5.3-.7.5-1.4.5-2.4 0-2.2-1.3-4-3.6-4Z"/><path fill="currentColor" d="M10.6 7.4a.8.9 0 1 0 0 1.8.8.9 0 1 0 0-1.8Zm2.8 0a.8.9 0 1 0 0 1.8.8.9 0 1 0 0-1.8Z"/><path fill="none" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" d="M10.3 10.2 12 11.2l1.7-1"/></svg>',
    'android': '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" d="M4 17a8 8 0 0 1 16 0zM6.9 9.9 5 6.7M17.1 9.9 19 6.7"/><circle cx="9" cy="13.8" r="1" fill="currentColor"/><circle cx="15" cy="13.8" r="1" fill="currentColor"/></svg>',
    'macos': '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M16.4 12.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8C6.9 7.4 5.4 8.3 4.6 9.7c-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.5 1.3-.1 1.8-.8 3.3-.8s2 .8 3.4.8 2.3-1.3 3.1-2.5c1-1.4 1.4-2.8 1.4-2.9-.1 0-2.9-1.1-2.9-4.4ZM14.2 5.8c.7-.8 1.1-2 1-3.1-1 0-2.2.7-2.9 1.5-.6.7-1.2 1.9-1 3 1.1.1 2.2-.6 2.9-1.4Z"/></svg>',
    'ios': '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="6.5" y="2.5" width="11" height="19" rx="2.5" fill="none" stroke="currentColor" stroke-width="1.5"/><path d="M10.5 18.5h3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>',
    'other': '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" d="M13 3H6.5A1.5 1.5 0 0 0 5 4.5v15A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V9zM13 3v6h6"/></svg>',
    'down': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 4v12m0 0 5-5m-5 5-5-5M4 19h16"/></svg>',
    'sun': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>',
    'moon': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>',
}

# "Before you install": what the operating system does with an unsigned file, and how to check
# the download. {file} is the platform's primary file name. Short, factual, impersonal.
BEFORE = {
    'windows': (
        '<p>The installer is not code-signed. SmartScreen shows <b>Windows protected your PC</b> on the first '
        'run: choose <b>More info</b>, then <b>Run anyway</b>. BT Labs is too new to hold a signing certificate.</p>'
        '<p>The app installs for the current user only; no administrator rights are needed.</p>',
        'certutil -hashfile {file} SHA256'),
    'macos': (
        '<p>The disk image is not signed or notarised by Apple, so Gatekeeper blocks the first start. Open the '
        'disk image, drag <b>Epic Cash Desktop</b> to Applications and open it once. When macOS refuses, go to '
        '<b>System Settings › Privacy &amp; Security</b>, scroll to the Security section and click '
        '<b>Open Anyway</b>, then confirm with the Mac login password.</p>'
        '<p>Or in Terminal: <code>xattr -dr com.apple.quarantine "/Applications/Epic Cash Desktop.app"</code></p>'
        '<p>The keychain asks once per version to let the app use its saved data: <b>Always Allow</b>. '
        'The built-in node runs on Apple silicon only.</p>',
        'shasum -a 256 {file}'),
    'linux': (
        '<p>Nothing to pass. Make the file executable (right-click › Properties › Permissions › '
        '<b>Allow executing file as program</b>, or <code>chmod +x {file}</code>) and run it. '
        'It needs <code>fusermount3</code>, which default desktops have; without FUSE run it with '
        '<code>--appimage-extract-and-run</code>.</p>',
        'sha256sum {file}'),
    'android': (
        '<p>The APK is signed with BT Labs\' release key. Certificate SHA-256: '
        '<code class="fp" translate="no">' + ANDROID_CERT_SHA256 + '</code>. '
        '<code>apksigner verify --print-certs {file}</code> prints it; Android itself refuses an update whose key differs.</p>'
        '<p>Android asks to allow installs from this source (the browser or the file manager) the first time.</p>',
        'sha256sum {file}'),
    'ios': (
        '<p>The IPA is unsigned; an iPhone installs only signed apps. Sign and install it with an Apple ID through a '
        'sideloading tool such as AltStore or Sideloadly. With a free Apple ID the app stops opening after 7 days: '
        'install it again the same way, the wallet stays on the phone.</p>'
        '<p>Neither iOS file carries Tor; the one without Tor also leaves Tor out of the settings and help.</p>',
        'shasum -a 256 {file}'),
}


def esc(s):
    return html.escape(str(s), quote=True)


def vkey(v):
    m = re.match(r'(\d+)\.(\d+)\.(\d+)(?:-r(\d+))?$', v)
    return tuple(int(x or 0) for x in m.groups()) if m else (0, 0, 0, 0)


def classify(name):
    for pat, plat, label, primary in KINDS:
        m = re.match(pat, name)
        if m:
            return plat, label, primary
    return 'other', name, False


def version_of(name):
    m = re.search(r'-' + V + r'(?:-|\.)', name)
    return m.group(1) if m else None


def mb(size):
    return f'{size / 1e6:.1f}'


def human_date(iso):
    d = dt.date.fromisoformat(iso)
    return f'{d.day} {d.strftime("%B %Y")}'


def load():
    if not os.path.exists(DATA):
        return {'releases': []}
    with open(DATA) as f:
        return json.load(f)


def save(data):
    data['releases'].sort(key=lambda r: vkey(r['version']), reverse=True)
    for r in data['releases']:
        r['files'].sort(key=lambda f: f['name'])
    with open(DATA, 'w') as f:
        json.dump(data, f, indent=1)
        f.write('\n')


def read_sums(path):
    sums = {}
    with open(path) as f:
        for line in f:
            parts = line.split()
            if len(parts) == 2:
                sums[parts[1].lstrip('*')] = parts[0]
    return sums


# ---------------------------------------------------------------------------- commands

def cmd_add(args):
    ver, d = args[0], args[1]
    date = dt.date.today().isoformat()
    if '--date' in args:
        date = args[args.index('--date') + 1]
    dt.date.fromisoformat(date)
    sums = read_sums(os.path.join(d, 'SHA256SUMS'))
    files = []
    for name, sha in sorted(sums.items()):
        if version_of(name) != ver:
            continue
        path = os.path.join(d, name)
        h = hashlib.sha256()
        with open(path, 'rb') as f:
            for chunk in iter(lambda: f.read(1 << 20), b''):
                h.update(chunk)
        assert h.hexdigest() == sha, f'SHA256SUMS disagrees for {name}'
        files.append({'name': name, 'size': os.path.getsize(path), 'sha256': sha})
    assert files, f'no file for {ver} in {d}/SHA256SUMS'
    data = load()
    data['releases'] = [r for r in data['releases'] if r['version'] != ver]
    data['releases'].append({'version': ver, 'date': date, 'files': files})
    save(data)
    print(f'{ver}: {len(files)} files, {date}')


def cmd_import_listing(args):
    listing, sums_path = args[0], args[1]
    sums = read_sums(sums_path)
    dates = {}
    if len(args) > 2:
        log = open(args[2]).read()
        for m in re.finditer(r'id="v([\d.]+(?:-r\d+)?)".*?<time datetime="(\d{4}-\d\d-\d\d)"', log, re.S):
            dates[m.group(1)] = m.group(2)
    rel = {}
    for line in open(listing):
        parts = line.split()
        if len(parts) < 7 or not parts[0].startswith('-'):
            continue
        size, stamp, name = int(parts[4]), parts[5], parts[6]
        if name not in sums:
            continue
        ver = version_of(name)
        if not ver:
            continue
        r = rel.setdefault(ver, {'version': ver, 'date': dates.get(ver, stamp[:10]), 'files': []})
        r['files'].append({'name': name, 'size': size, 'sha256': sums[name]})
    data = load()
    known = {r['version'] for r in data['releases']}
    data['releases'] += [r for v, r in rel.items() if v not in known]
    save(data)
    print(f'{len(rel)} versions on the server, {len(rel) - len(known & set(rel))} added')


# ---------------------------------------------------------------------------- the page

def group(release):
    """{platform: {'primary': file or None, 'files': [...]}} in page order, plus 'other'."""
    out = {}
    for f in release['files']:
        plat, label, primary = classify(f['name'])
        g = out.setdefault(plat, {'primary': None, 'files': []})
        entry = dict(f, label=label, primary=primary)
        g['files'].append(entry)
        if primary:
            g['primary'] = entry
    ordered = {}
    for key, *_ in PLATFORMS:
        if key in out:
            ordered[key] = out[key]
    if 'other' in out:
        ordered['other'] = out['other']
    for g in ordered.values():
        g['files'].sort(key=lambda e: (not e['primary'], e['label']))
    return ordered


def file_row(e, with_label=True):
    return (
        f'<li class="f"><a class="fl" href="downloads/{esc(e["name"])}" download>'
        f'<span class="fk">{esc(e["label"])}</span>'
        f'<span class="fn" translate="no">{esc(e["name"])}</span>'
        f'<span class="fs">{mb(e["size"])}&nbsp;MB</span></a>'
        f'<span class="sha"><span class="sha-k">SHA-256</span>'
        f'<code data-copy translate="no">{e["sha256"]}</code></span></li>'
    )


def platform_card(key, g, latest):
    pkey, heading, app, req, preview = PLAT.get(key, (key, 'Other files', '', '', False))
    p = g['primary']
    folded = [e for e in g['files'] if not p or e['name'] != p['name']]
    icon = ICONS.get(key, ICONS['other'])
    out = [f'<article class="card" data-plat="{key}" id="dl-{key}"><div class="cm">']
    out.append(f'<header class="ch"><span class="ico">{icon}</span><div><h3>{esc(heading)}'
               + (' <span class="pill">Preview</span>' if preview else '') + '</h3>'
               f'<p class="app">{esc(app)}</p><p class="req">{esc(req)}</p></div></header>')
    if p:
        out.append(f'<a class="btn primary" href="downloads/{esc(p["name"])}" download>{ICONS["down"]}'
                   f'<span>Download <b>{esc(app)}</b> for {esc(heading)}'
                   f'<small>{esc(p["label"])} · {mb(p["size"])}&nbsp;MB · {esc(latest["version"])}</small></span></a>')
        out.append(f'<p class="fn main" translate="no">{esc(p["name"])}</p>')
    out.append('</div><div class="cf">')
    if g['files']:
        n = len(g['files'])
        out.append(f'<details class="fold files"><summary>{"All files and checksums" if folded else "Checksum"}'
                   f'<span class="cnt">{n}</span></summary><ul class="fl-list">')
        out += [file_row(e) for e in g['files']]
        out.append('</ul></details>')
    if key in BEFORE and p:
        text, cmd = BEFORE[key]
        out.append(f'<details class="fold before" data-before="{key}"><summary>Before you install</summary>'
                   f'<div class="bt">{text.format(file=esc(p["name"]))}'
                   f'<p class="verify"><span>Check the download</span><code data-copy translate="no">'
                   f'{esc(cmd.format(file=p["name"]))}</code></p></div></details>')
    out.append('</div></article>')
    return '\n'.join(out)


def older_release(r):
    g = group(r)
    plats = ''.join(f'<span class="ico sm" title="{esc(PLAT[k][1])}">{ICONS[k]}</span>' for k in g if k in PLAT)
    parts = [f'<details class="rel" id="v{esc(r["version"])}"><summary>'
             f'<span class="rv" translate="no">{esc(r["version"])}</span>'
             f'<time datetime="{r["date"]}">{human_date(r["date"])}</time>'
             f'<span class="rp" aria-hidden="true">{plats}</span>'
             f'<span class="rn">{len(r["files"])} file{"s" if len(r["files"]) != 1 else ""}</span></summary><div class="rb">'
             f'<p class="rl"><a href="changelog/#v{esc(r["version"])}">What changed in {esc(r["version"])}</a></p>']
    for k, gg in g.items():
        heading = PLAT[k][1] if k in PLAT else 'Other files'
        parts.append(f'<section class="rg"><h4>{ICONS.get(k, ICONS["other"])}{esc(heading)}</h4><ul class="fl-list">')
        parts += [file_row(e) for e in gg['files']]
        parts.append('</ul></section>')
    parts.append('</div></details>')
    return '\n'.join(parts)


def render(out_dir):
    data = load()
    rels = sorted(data['releases'], key=lambda r: vkey(r['version']), reverse=True)
    assert rels, 'no release recorded: run add first'
    latest, older = rels[0], rels[1:]
    g = group(latest)
    plat_names = [PLAT[k][1] for k in g if k in PLAT and not PLAT[k][4]]
    previews = [PLAT[k][1] for k in g if k in PLAT and PLAT[k][4]]
    cards = '\n'.join(platform_card(k, gg, latest) for k, gg in g.items())
    old = '\n'.join(older_release(r) for r in older)
    plat_line = ', '.join(plat_names) + ('; ' + ' and '.join(previews) + ' preview' if previews else '')
    total_files = sum(len(r['files']) for r in rels)

    page = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="dark light">
<meta name="theme-color" content="#08080a">
<meta name="description" content="Download Epic Cash Desktop and Epic Cash Mobile {esc(latest['version'])}: {esc(plat_line)}. Every release with checksums.">
<title>Epic Cash releases</title>
<link rel="icon" href="img/favicon.png" type="image/png">
<link rel="stylesheet" href="style.css">
<script src="theme.js"></script>
<script src="page.js" defer></script>
</head>
<body>
<a class="skip" href="#latest">Skip to the downloads</a>

<header class="top">
  <a class="brand" href="https://btlabs.uk/" aria-label="BT LABS"><img class="emblem" src="img/btlabs-emblem.png" width="32" height="32" alt="" decoding="async"><span class="brand-name" translate="no">BT LABS</span></a>
  <nav class="topnav" aria-label="Site">
    <a href="https://epiccash.btlabs.uk/">Epic Cash</a>
    <a href="changelog/">Changelog</a>
    <button class="theme" id="theme" type="button" aria-label="Switch to the light look">{ICONS['sun'].replace('<svg', '<svg class="on-dark"')}{ICONS['moon'].replace('<svg', '<svg class="on-light"')}<span class="on-dark">Light</span><span class="on-light">Dark</span></button>
  </nav>
</header>

<main>
<section class="hero">
  <p class="wordmark" translate="no"><span class="wm-name">Epic Cash</span><span class="wm-platform">Desktop and Mobile</span></p>
  <h1>Releases</h1>
  <p class="readout"><span class="bracket" aria-hidden="true">[</span><span translate="no">{esc(latest['version'])}</span><span class="bracket" aria-hidden="true">]</span><time datetime="{latest['date']}">{human_date(latest['date'])}</time><span class="plat">{esc(plat_line)}</span></p>
  <p class="beta"><span class="pill solid">Open beta</span><span>Bugs are expected; test with small amounts. Report a problem from the app: Settings › Send feedback on the phone, Settings › Help › Report a problem on the desktop.</span></p>
  <p class="mine" id="mine" hidden><span id="mine-text"></span> <button type="button" id="other" class="link">Other platforms</button></p>
</section>

<section class="latest" id="latest" aria-labelledby="latest-h">
  <div class="sh"><h2 id="latest-h">Latest <span translate="no">{esc(latest['version'])}</span></h2><a class="sl" href="changelog/#v{esc(latest['version'])}">What changed</a></div>
  <div class="cards">
{cards}
  </div>
  <p class="foot-note"><b>Without Tor</b>: the same app with Tor left out, for places where Tor is unwanted or blocked; it cannot send to Tor addresses and updates itself like the normal app. Installing either over the other keeps the wallets. <a href="downloads/SHA256SUMS" class="mono" translate="no">SHA256SUMS</a> lists every file.</p>
</section>

<section class="older" id="all" aria-labelledby="all-h">
  <div class="sh"><h2 id="all-h">Earlier releases</h2><p class="sl">{len(older)} versions · {total_files} files in all · <a href="changelog/">changelog</a></p></div>
{old}
</section>
</main>

<footer class="foot">
  <p>Wallet by <a href="https://btlabs.uk/" translate="no">BT LABS</a> · <a href="https://epiccash.btlabs.uk/">About the wallet</a> · <a href="https://epiccash.btlabs.uk/screens/">Every screen</a> · <a href="restore/">Restore map</a></p>
  <p>Contact: <a href="mailto:support@btlabs.uk">support@btlabs.uk</a> · © 2026 BT LABS</p>
</footer>
</body>
</html>
'''
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, 'index.html'), 'w') as f:
        f.write(page)
    for name in ('style.css', 'page.js', 'theme.js'):
        shutil.copy(os.path.join(ASSETS, name), os.path.join(out_dir, name))
    for sub in ('fonts', 'img'):
        os.makedirs(os.path.join(out_dir, sub), exist_ok=True)
        for name in os.listdir(os.path.join(ASSETS, sub)):
            shutil.copy(os.path.join(ASSETS, sub, name), os.path.join(out_dir, sub, name))
    print(f'{out_dir}: {latest["version"]} + {len(older)} earlier, {total_files} files')


def main(argv):
    if not argv or argv[0] in ('-h', '--help'):
        print(__doc__)
        return 0
    cmd, args = argv[0], argv[1:]
    if cmd == 'add':
        cmd_add(args)
    elif cmd == 'import-listing':
        cmd_import_listing(args)
    elif cmd == 'render':
        out = args[args.index('--out') + 1] if '--out' in args else DEFAULT_OUT
        render(out)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
