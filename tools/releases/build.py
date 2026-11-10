#!/usr/bin/env python3
"""The public releases page for BT Wallet for Epic Cash (desktop and mobile).

    tools/releases/build.py add <version> <dir> [--date YYYY-MM-DD] [--github]
        Record a release from a folder holding its files and SHA256SUMS (the release lead's
        folder, e.g. /srv/wfe-release/26.10.24). Every file in SHA256SUMS whose name
        carries <version> is taken; its checksum is recomputed and must agree. The release
        replaces the files of every slot it has a file for (see keep); a slot it leaves out
        (a platform out of its scope) keeps the earlier record's files. --github adds
        the Mirror link (only once the GitHub Release exists and is public);
        a SHA256SUMS.sig in <dir> adds the signature check to every Before you install.
    tools/releases/build.py keep <version> < names
        Of the file names on stdin (the server's downloads/), print the ones the folder keeps
        once <version> is live: per slot, <version>'s files when it has any, else the newest
        version's (prune-downloads and server_sums.py use this one rule).
    tools/releases/build.py render [--out DIR]
        Write the page (index.html, style.css, page.js, theme.js, fonts/, img/) into DIR,
        the page repo's site/epic-cash/ by default ($WFE_RELEASES_SITE). Deploy from there
        with the page repo's ./deploy-epic-cash.sh.

The data is releases.json next to this script: the current release (version, date, files with
name, size and sha256), and an earlier record for each platform the current one left out. A slot
is a platform and its variant (with Tor, without; iOS has only the one without): the newest version that has a file in a slot
is the one the page offers there, and the server keeps. What a file is (platform, label, primary or folded) comes
from its name, see KINDS: a new kind of build needs one line there and nothing else.
A file added to a release after its SHA256SUMS was signed (the macOS disk images of 26.11.0) says
"unlisted": true: the page marks it as outside the signed listing.

The page is plain HTML and CSS: every download is a link, every fold a <details>. page.js adds
the copy buttons, the platform the browser reports (User-Agent Client Hints, then the user
agent) and the platform switch (the hero's tiles and the section's own, one state, no scrolling);
without it the page shows every platform the same way and every switch is a plain anchor.
No tracking, nothing loaded from another host.

The page wears the BT Wallet landing page's three looks (epiccash.btlabs.uk): Night (a), Grid (b)
and Day (c), all in one style.css under html[data-look]. theme.js applies the look this browser
picked there (localStorage btw-look, Night when none) before the first paint; page.js adds the
same quiet Look picker to the footer, which switches in place.
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
# Release files are bt-wallet-<version>[-notor]-<platform>-…; the releases before that name keep
# their epic-cash-desktop-…, EpicCashDesktop-…, epic-cash-mobile-… and EpicCashMobile-… files on
# the server and in releases.json, so both sets of patterns stay.
KINDS = [
    (rf'^bt-wallet-{V}-windows-x64-setup\.exe$', 'windows', 'Installer', True),
    (rf'^bt-wallet-{V}-notor-windows-x64-setup\.exe$', 'windows', 'Installer without Tor', False),
    (rf'^bt-wallet-{V}-(?:notor-)?windows-x64-portable\.zip$', 'windows', 'Portable, zip', False),
    (rf'^bt-wallet-{V}-linux-x86_64\.AppImage$', 'linux', 'AppImage', True),
    (rf'^bt-wallet-{V}-notor-linux-x86_64\.AppImage$', 'linux', 'AppImage without Tor', False),
    (rf'^bt-wallet-{V}-android-arm64-v8a\.apk$', 'android', 'APK, arm64', True),
    (rf'^bt-wallet-{V}-notor-android-arm64-v8a\.apk$', 'android', 'APK without Tor, arm64', False),
    (rf'^bt-wallet-{V}-(?:notor-)?android-universal\.apk$', 'android', 'APK, universal', False),
    (rf'^bt-wallet-{V}-(?:notor-)?android-x86_64\.apk$', 'android', 'APK, x86_64 (emulators)', False),
    (rf'^bt-wallet-{V}-macos\.dmg$', 'macos', 'Disk image', True),
    (rf'^bt-wallet-{V}-notor-macos\.dmg$', 'macos', 'Disk image without Tor', False),
    # iOS cannot run Tor: one IPA per release, the build without Tor, under its -notor name.
    (rf'^bt-wallet-{V}-notor-ios-unsigned\.ipa$', 'ios', 'Unsigned IPA', True),
    (rf'^bt-wallet-{V}-ios-simulator\.zip$', 'ios', 'Simulator app, for Xcode', False),
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
    ('windows', 'Windows', 'Desktop', 'Windows 10 and 11, 64-bit', False),
    ('linux', 'Linux', 'Desktop', 'x86_64, AppImage', False),
    ('android', 'Android', 'Mobile', 'Android 7 or newer, arm64', False),
    ('macos', 'macOS', 'Desktop', 'macOS 12 or newer, Apple silicon', True),
    ('ios', 'iOS', 'Mobile', 'iPhone and iPad, iOS 15 or newer', True),
]
APP = 'BT Wallet'
PLAT = {p[0]: p for p in PLATFORMS}

# The app stores, on their platform's row: (the line above the store's name, its name, its icon,
# the listing's URL). Without a URL the badge is plain text marked Coming soon; with one it links.
STORES = {
    'android': ('Get it on', 'Google Play', '<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M3.609 1.814 13.792 12 3.61 22.186a.996.996 0 0 1-.61-.92V2.734a1 1 0 0 1 .609-.92zm10.89 10.893 2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.198 2.807 1.626a1 1 0 0 1 0 1.73l-2.808 1.626L15.206 12l2.492-2.491zM5.864 2.658 16.802 8.99l-2.303 2.303-8.635-8.635z"/></svg>', 'https://play.google.com/store/apps/details?id=uk.btlabs.btwallet'),
    'ios': ('Download on the', 'App Store', None, None),
}
# Platforms the page offers only through their store: their files stay recorded (and on the
# server while keep says so) but the page shows no download, version, size or install steps.
STORE_ONLY = {'ios'}

# A release mirrored on GitHub gets a Mirror link when its record says "github": true
# (build.py add --github): the BTLabsUK Release, which tools/rel adds when release.toml
# publish.github is on.
GITHUB_RELEASE = 'https://github.com/BTLabsUK/wallet-for-epic/releases/tag/v{version}'

# BT Labs' release key in minisign's format (tools/release-files.py pubkey): it signs SHA256SUMS
# into SHA256SUMS.sig and update.json. A release whose record says "sig": true shows the check.
MINISIGN_PUBKEY = 'RWQ+swweZiIFJfbre/aOhYqQ1+82BHFnw8gF6ETbhCp5b7RB6RuMEVtP'

# The Android release key: shown so an APK can be checked against it (apksigner verify
# --print-certs). Signer certificate SHA-256, CN=BT Labs Epic Wallet, O=BT Labs.
ANDROID_CERT_SHA256 = '59e4c290f3922d8e7d3b189eb98e7002dc50754c52d612ea91e82386390ec0aa'

VERIFY_KEYS = ('windows', 'macos', 'linux', 'android')

ICONS = {
    'shield': '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3 4.5 6v5.5c0 4.5 3.1 8 7.5 9.5 4.4-1.5 7.5-5 7.5-9.5V6z"/><path d="m8.8 12 2.4 2.4 4.2-4.6"/></svg>',
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
        'run: choose <b>More info</b>, then <b>Run anyway</b>. BT LABS is too new to hold a signing certificate.</p>'
        '<p>The app installs for the current user only; no administrator rights are needed.</p>',
        'certutil -hashfile {file} SHA256'),
    'macos': (
        '<p>The disk image and the app are signed with BT LABS\' Developer ID and notarised by Apple. Open the '
        'disk image, drag the app to Applications and open it.{older}</p>'
        '<p>For Macs with Apple silicon (M1 or newer) only; an Intel Mac cannot run it.</p>'
        '<p>Coming from an older version, the keychain asks once to let the app use its saved data: '
        '<b>Always Allow</b>.</p>',
        'shasum -a 256 {file}'),
    'linux': (
        '<p>Nothing to pass. Make the file executable (right-click › Properties › Permissions › '
        '<b>Allow executing file as program</b>, or <code>chmod +x {file}</code>) and run it. '
        'It needs <code>fusermount3</code>, which default desktops have; without FUSE run it with '
        '<code>--appimage-extract-and-run</code>.</p>',
        'sha256sum {file}'),
    'android': (
        '<p>The APK is signed with BT LABS\' release key; Android refuses an update signed with a different key. '
        'To check the download, see <a href="#verify-android">Verify downloads</a>.</p>'
        '<p>Android asks to allow installs from this source (the browser or the file manager) the first time.</p>',
        'sha256sum {file}'),
    'ios': (
        '<p>The IPA is unsigned; an iPhone installs only signed apps. Sign and install it with an Apple ID through a '
        'sideloading tool such as AltStore or Sideloadly. With a free Apple ID the app stops opening after 7 days: '
        'install it again the same way, the wallet stays on the phone.</p>',
        'shasum -a 256 {file}'),
}


def mac_bundle(name):
    """The macOS fold's app bundle and its note on the older one: the disk images before the
    bt-wallet-… names (26.10.24 and earlier) install the app under its old bundle name."""
    if name.startswith('bt-wallet-'):
        return {'bundle': 'BT Wallet.app',
                'older': ' An older <b translate="no">Epic Cash Desktop.app</b> in Applications goes to the Bin.'}
    return {'bundle': 'Epic Cash Desktop.app', 'older': ''}


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


def slot(name):
    """The platform and variant a release file fills ('android', 'tor'), or None (no version in
    its name, or a file no pattern knows)."""
    plat = classify(name)[0]
    if plat == 'other' or not version_of(name):
        return None
    return plat, 'notor' if NOTOR.search(name) else 'tor'


def keep(version, names):
    """The names that stay once <version> is live: in each slot <version>'s files when it has
    any, else the newest version's. Names without a slot stay only when they carry <version>."""
    by = {}
    for n in names:
        s = slot(n)
        if s:
            by.setdefault(s, []).append(n)
    out = {n for n in names if not slot(n) and version_of(n) == version}
    for ns in by.values():
        vs = {version_of(n) for n in ns}
        want = version if version in vs else max(vs, key=vkey)
        out.update(n for n in ns if version_of(n) == want)
    return out


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
    rec = {'version': ver, 'date': date, 'files': files}
    if '--github' in args:
        rec['github'] = True
    if os.path.exists(os.path.join(d, 'SHA256SUMS.sig')):
        rec['sig'] = True
    data['releases'] = merge(data['releases'], rec)
    save(data)
    print(f'{ver}: {len(files)} files, {date}')
    for r in data['releases']:
        if r is not rec:
            print(f'  kept from {r["version"]}: {", ".join(f["name"] for f in r["files"])}')


def merge(records, rec):
    """The records once rec is live: rec, and of the others only the files keep() leaves (the
    slots rec has no file for). A record left without files goes."""
    others = [r for r in records if r['version'] != rec['version']]
    kept = keep(rec['version'], [f['name'] for r in others for f in r['files']] + [f['name'] for f in rec['files']])
    out = [rec]
    for r in others:
        fs = [f for f in r['files'] if f['name'] in kept]
        if fs:
            out.append(dict(r, files=fs))
    return out


# ---------------------------------------------------------------------------- the page

def group(releases):
    """{platform: {'primary': file or None, 'files': [...]}} in page order, plus 'other'. Every
    recorded file, each with its release's version and date (add leaves one version per slot)."""
    out = {}
    for r in releases:
        for f in r['files']:
            plat, label, primary = classify(f['name'])
            g = out.setdefault(plat, {'primary': None, 'files': []})
            entry = dict(f, label=label, primary=primary, version=r['version'], date=r['date'])
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


def file_row(e):
    return (
        f'<li class="f"><a class="fl" href="downloads/{esc(e["name"])}" download>'
        f'<span class="fk">{esc(e["label"])}</span>'
        f'<span class="fn" translate="no">{esc(e["name"])}</span>'
        f'<span class="fs">{esc(e["version"])} · {mb(e["size"])}&nbsp;MB</span></a>'
        f'<span class="sha"><span class="sha-k">SHA-256</span>'
        f'<code data-copy="SHA-256" translate="no">{e["sha256"]}</code></span>'
        + ('<span class="sha-n">Not in the signed SHA256SUMS: added after it was signed.</span>' if e.get('unlisted') else '')
        + '</li>'
    )


def notor_of(g):
    """The platform's 'without Tor' twin of its primary file, if the release has one."""
    p = g['primary']
    if not p:
        return None
    for e in g['files']:
        if e is not p and NOTOR.search(e['name']) and e['name'].replace('-notor', '') == p['name']:
            return e
    return None


def store_line(key):
    """The platform's app store badge, if it has a store."""
    if key not in STORES:
        return ''
    lead, name, icon, url = STORES[key]
    inner = (f'{icon or ICONS["macos"]}<span class="st-t"><span class="st-l">{esc(lead)}</span>'
             f'<span class="st-n">{esc(name)}</span></span>')
    if url:
        return f'<p class="store-line"><a class="store" href="{esc(url)}">{inner}</a></p>'
    return f'<p class="store-line"><span class="store">{inner}</span><span class="pill">Coming soon</span></p>'


def checksum_line(key, heading, p):
    """The primary file's SHA-256 as one line under the platform's version: the first and last
    eight characters, the whole value (with the file's name) in a small panel on hover and focus,
    and the platform's Verify link. page.js turns the short value into a copy button that copies
    data-value; without it the line is plain text and Files and checksums has the whole value."""
    sha = p['sha256']
    return (f'<p class="sum"><span class="sha-k">SHA-256</span><span class="sum-h">'
            f'<code class="sum-v" data-copy="SHA-256" data-value="{sha}" data-name="{esc(p["name"])}" translate="no">{sha[:8]}…{sha[-8:]}</code>'
            f'<span class="sum-full"><span class="sum-fn" translate="no">{esc(p["name"])}</span>'
            f'<span class="sum-fv" translate="no">{sha[:32]}<wbr>{sha[32:]}</span></span></span>'
            f'<a class="sum-verify" href="#verify{"-" + key if key in VERIFY_KEYS else ""}">Verify<span class="vh"> the {esc(heading)} download</span></a></p>')


def platform_row(key, g, latest):
    """One platform: name, requirement, version and the primary file's checksum line; the primary
    download with its size, the version without Tor beside it; then two folds: the install guide
    (Before you install) and every file with its checksum. The visitor's own platform is marked by
    page.js, never moved."""
    _, heading, kind, req, preview = PLAT.get(key, (key, 'Other files', '', '', False))
    p = g['primary']
    nt = notor_of(g)
    icon = ICONS.get(key, ICONS['other'])
    # Every platform shows its own version and date under the requirement (platforms release
    # separately); one the current release left out also carries them on the row for page.js
    # (the hero's version line).
    own = p and p['version'] != latest['version']
    out = [f'<li class="row" data-plat="{key}" id="dl-{key}"{" data-preview" if preview else ""}'
           + (f' data-version="{esc(p["version"])}" data-date="{p["date"]}" data-when="{human_date(p["date"])}"' if own else '') + '>',
           f'<div class="r-main"><span class="ico">{icon}</span><div class="r-name"><h3>{esc(heading)}'
           + (' <span class="pill">Preview</span>' if preview and p else '') + '</h3>'
           f'<p class="req">{esc(req)}</p>'
           + (f'<p class="req r-ver">Version <span translate="no">{esc(p["version"])}</span> · '
              f'<time datetime="{p["date"]}">{human_date(p["date"])}</time></p>' if p else '')
           + (checksum_line(key, heading, p) if p else '')
           + '</div>']
    if p:
        out.append(f'<div class="r-get"><a class="btn primary" href="downloads/{esc(p["name"])}" download '
                   f'data-label="{esc(p["label"])}" data-size="{mb(p["size"])}&nbsp;MB">{ICONS["down"]}'
                   f'<span>Download<span class="vh"> {APP} for {esc(heading)}</span>'
                   f'<small>{esc(p["label"])} · {esc(p["version"])} · {mb(p["size"])}&nbsp;MB</small></span></a>'
                   + (f'<a class="alt" href="downloads/{esc(nt["name"])}" download>Without Tor · {esc(nt["version"])} · {mb(nt["size"])}&nbsp;MB</a>' if nt else '')
                   + store_line(key) + '</div>')
    elif key in STORES:
        out.append(f'<div class="r-get">{store_line(key)}</div>')
    out.append('</div>')
    folds = []
    if key in BEFORE and p:
        text, cmd = BEFORE[key]
        folds.append(f'<details class="fold" data-before="{key}" id="before-{key}"><summary>Install guide</summary>'
                   f'<div class="bt">{text.format(file=esc(p["name"]), **mac_bundle(p["name"]))}</div></details>')
    if g['files']:
        folds.append(f'<details class="fold files"><summary>Files and checksums<span class="cnt">{len(g["files"])}</span></summary>'
                   '<ul class="fl-list">' + ''.join(file_row(e) for e in g['files']) + '</ul></details>')
    if folds:
        out.append('<div class="r-folds">' + '\n'.join(folds) + '</div>')
    out.append('</li>')
    return '\n'.join(out)


def platforms(g, latest):
    """Desktop, then Mobile, then any file no pattern knows."""
    groups = [('Desktop', [k for k in g if k in PLAT and PLAT[k][2] == 'Desktop']),
              ('Mobile', [k for k in g if k in PLAT and PLAT[k][2] == 'Mobile']),
              ('Other files', [k for k in g if k not in PLAT])]
    out = []
    for title, keys in groups:
        if not keys:
            continue
        out.append(f'<div class="group"><h3 class="g-h">{title}</h3><ul class="rows">')
        out += [platform_row(k, g[k], latest) for k in keys]
        out.append('</ul></div>')
    return '\n'.join(out)


def sig_check(r):
    """The signature check of SHA256SUMS, for a release published with SHA256SUMS.sig."""
    if not r.get('sig'):
        return ''
    cmd = f'minisign -Vm SHA256SUMS -x SHA256SUMS.sig -P {MINISIGN_PUBKEY}'
    return ('<p>Check the checksums themselves: download <a href="downloads/SHA256SUMS.sig" download>SHA256SUMS.sig</a> '
            'too and check its signature with BT LABS\' release key.</p>'
            f'<div class="verify"><span>Signature</span><code data-copy="command" translate="no">{esc(cmd)}</code></div>')


def cmd_block(label, cmd, key):
    return (f'<div class="verify" id="verify-{key}"><span>{esc(label)}</span>'
            f'<code data-copy="command" translate="no">{esc(cmd)}</code></div>')


def android_verify(p):
    """Phone-usable steps first (no terminal on a phone), then the computer's. The fingerprint is
    ANDROID_CERT_SHA256, the only copy in this file."""
    f = esc(p['name'])
    return f'''<div class="v-android" id="verify-android">
      <h3>Android</h3>
      <p>Installs from Google Play are verified by Play. For the APK downloaded here, check that its signing certificate has this SHA-256:</p>
      <div class="verify"><span>Certificate SHA-256</span><code data-copy="fingerprint" translate="no">{ANDROID_CERT_SHA256}</code></div>
      <ol class="v-steps">
        <li><b>On the phone:</b> install AppVerifier (open source; on F-Droid and Google Play), choose the downloaded APK in it and compare the certificate SHA-256 it shows with the one above.</li>
        <li><b>Or in Termux:</b> run <code>termux-setup-storage</code> once, then the command below. The browser's downloads are in <code>~/storage/downloads/</code>. Compare the result with the SHA-256 shown with the download.
          <div class="verify"><span>Termux</span><code data-copy="command" translate="no">sha256sum ~/storage/downloads/{f}</code></div></li>
        <li><b>On a computer:</b> <code>apksigner</code> prints the certificate; compare its SHA-256 digest with the one above.
          <div class="verify"><span>Computer</span><code data-copy="command" translate="no">apksigner verify --print-certs {f}</code></div></li>
      </ol>
    </div>'''


def verify(g, latest):
    """How to check a download: one command per system for its primary file, the phone steps for
    Android, the signature when the release has one. Always open, under its own heading."""
    blocks = []
    for key in VERIFY_KEYS:
        if key in g and g[key]['primary'] and key in BEFORE:
            p = g[key]['primary']
            if key == 'android':
                blocks.append(android_verify(p))
            else:
                blocks.append(cmd_block(PLAT[key][1], BEFORE[key][1].format(file=p['name']), key))
    late = [e for gg in g.values() for e in gg['files'] if e.get('unlisted')]
    late_note = ('<p>' + ' and '.join(f'<span translate="no">{esc(e["name"])}</span>' for e in late)
                 + ' came after SHA256SUMS was signed and are not in it: compare them with the SHA-256 shown with each file.</p>\n    ') if late else ''
    return f'''<section class="wrap verify-sec" id="verify" aria-labelledby="verify-h">
  <div class="sh"><h2 id="verify-h"><span class="k-n" aria-hidden="true">[02]</span>Verify downloads</h2></div>
  <div class="bt">
    <p>Each download's SHA-256 is on its card under All platforms (the short value copies whole) and in Files and checksums. To check a file, compute its SHA-256 and compare it with that value; <a href="downloads/SHA256SUMS" download translate="no">SHA256SUMS</a> lists {'the others' if late else 'them all'}. Commands for the primary download of each system:</p>
    {late_note}{''.join(blocks)}
    {sig_check(latest)}
  </div>
</section>'''


def mirror(r):
    links = [(GITHUB_RELEASE, 'Mirror on GitHub', r.get('github'))]
    return ''.join(f' · <a href="{url.format(version=esc(r["version"]))}" rel="noopener">{label}</a>'
                   for url, label, on in links if on)


# Release notes come from the changelog page (changelog/index.html next to the page): the entry
# with id="v<version>". Its old app names read as the app here; the changelog keeps them as written.
OLD_NAMES = [('Epic Cash Desktop and Mobile', 'both apps'), ('Epic Cash Desktop', 'the desktop app'),
             ('Epic Cash Mobile', 'the phone app')]
NOTES_MAX = 5


def changelog(out_dir):
    path = os.path.join(out_dir, 'changelog', 'index.html')
    if not os.path.exists(path):
        return ''
    with open(path, encoding='utf-8') as f:
        return f.read()


def notes(latest, log):
    """What's new: the first few points of this version's changelog entry with their group (New,
    Better, Fixed…), a link to the whole entry, and the earlier versions folded, each linking to
    its entry. Versions newer than this release (written ahead in the changelog) are left out."""
    ver = latest['version']
    m = re.search(r'<section class="ver" id="v' + re.escape(ver) + r'">(.*?)</section>', log, re.S)
    items = []
    if m:
        for head, ul in re.findall(r'<h3>(.*?)</h3>\s*<ul>(.*?)</ul>', m.group(1), re.S):
            for li in re.findall(r'<li>(.*?)</li>', ul, re.S):
                for old, new in OLD_NAMES:
                    li = li.replace(old, new)
                items.append((re.sub(r'<[^>]+>', '', head), li.strip()))
    shown = items[:NOTES_MAX]
    lis = ''.join(f'<li><span class="n-tag">{esc(t)}</span><span class="n-text">{li}</span></li>' for t, li in shown)
    more = len(items) - len(shown)
    older = [(i, d) for i, d in re.findall(r'<section class="ver" id="v([^"]+)">\s*<h2>.*?<time datetime="([^"]+)"', log, re.S)
             if vkey(i) < vkey(ver)]
    older_html = ''
    if older:
        older_html = (f'<details class="fold older"><summary>Earlier versions<span class="cnt">{len(older)}</span></summary><ul class="old-list">'
                      + ''.join(f'<li><a href="changelog/#v{esc(i)}"><span class="o-v" translate="no">{esc(i)}</span>'
                                f'<time datetime="{esc(d)}">{human_date(d)}</time></a></li>' for i, d in older)
                      + '</ul></details>')
    full = f'<a href="changelog/#v{esc(ver)}">All {len(items)} changes</a>' if more > 0 else f'<a href="changelog/#v{esc(ver)}">The full entry</a>'
    return f'''<section class="wrap notes" id="notes" aria-labelledby="notes-h">
  <div class="sh"><h2 id="notes-h"><span class="k-n" aria-hidden="true">[03]</span>What's new in <span translate="no">{esc(ver)}</span></h2><p class="sl"><time datetime="{latest['date']}">{human_date(latest['date'])}</time></p></div>
  <div class="notes-in">
    <div class="n-main">
      {'<ul class="n-list">' + lis + '</ul>' if lis else ''}
      <p class="n-more">{full}{mirror(latest)}</p>
    </div>
    <div class="n-side">
      {older_html}
      <p class="beta-note"><b>Open beta.</b> Bugs are expected; test with small amounts. Report a problem from the app: Settings › Send feedback on the phone, Settings › Help › Report a problem on the desktop.</p>
    </div>
  </div>
</section>'''


def phones(g):
    """Short install steps for the phones that have a download: the APK (and the IPA while iOS is
    not store-only)."""
    cards = []
    if 'android' in g and g['android']['primary']:
        cards.append(f'''<div class="step-card"><h3><span class="ico sm">{ICONS['android']}</span>Android</h3>
      <ol class="steps"><li>Download the APK on the phone.</li><li>Open it. Android asks once to allow installs from the browser or the file manager.</li><li>Updates install from inside the app.</li></ol>
      <p class="s-note">Signed with BT LABS' release key; the certificate fingerprint is under <a href="#verify-android">Verify downloads</a>.</p></div>''')
    if 'ios' in g and g['ios']['primary']:
        cards.append(f'''<div class="step-card"><h3><span class="ico sm">{ICONS['ios']}</span>iPhone and iPad <span class="pill">Preview</span></h3>
      <ol class="steps"><li>Download the IPA on a computer.</li><li>Sign and install it with an Apple ID through AltStore or Sideloadly.</li><li>With a free Apple ID, install it again every 7 days. The wallet stays on the phone.</li></ol>
      <p class="s-note">The IPA is unsigned; an iPhone installs only signed apps.</p></div>''')
    if not cards:
        return ''
    return f'''<div class="phones"><h3 class="g-h">On a phone</h3><div class="step-cards">{''.join(cards)}</div></div>'''


# The BT LABS mask (the brand kit's polygons) and its gold, for the header's mark.
DEFS = '''<svg class="defs" aria-hidden="true" focusable="false">
  <defs>
    <linearGradient id="bt-gold" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6d471"/><stop offset="1" stop-color="#c98a3e"/></linearGradient>
    <symbol id="bt-mask" viewBox="0 31 645 559"><polygon points="197,105.46 322.5,33 448,105.46 448,165.46 322.5,93 197,165.46"/><polygon points="58,97 187,171.48 214.27,247.22 85.27,172.74"/><polygon points="587,97 458,171.48 430.73,247.22 559.73,172.74"/><polygon points="222,256 322.5,314.02 423,256 395.73,331.74 322.5,374.02 249.27,331.74"/><polygon points="2,209 143,290.41 170.27,366.15 29.27,284.74"/><polygon points="643,209 502,290.41 474.73,366.15 615.73,284.74"/><polygon points="171,374 249,419.03 322.5,376.6 396,419.03 474,374 446.73,449.74 396,479.03 322.5,436.6 249,479.03 198.27,449.74"/><polygon points="252,487 322.5,527.7 393,487 365.73,562.74 322.5,587.7 279.27,562.74"/></symbol>
  </defs>
</svg>'''

# The landing page, for the brand and About links: absolute, since the page is also served
# under examples.btlabs.uk.
LANDING = 'https://epiccash.btlabs.uk/'


def header(up=''):
    """The landing page's header: the BT LABS mask, BT WALLET, for Epic Cash. up is '../' from
    the changelog."""
    return f'''<header class="top">
  <div class="wrap top-in">
    <a class="brand" href="{LANDING}" aria-label="BT Wallet for Epic Cash, about the wallet"><svg class="brand-mark" aria-hidden="true"><use href="#bt-mask" fill="url(#bt-gold)"/></svg><span class="brand-name" translate="no">BT Wallet</span><span class="brand-sub" translate="no">for Epic Cash</span></a>
    <nav class="top-nav" aria-label="Site"><a href="{LANDING}">About</a><a href="{up}#notes">What's new</a><a href="{up}changelog/">Changelog</a></nav>
    <a class="btn btn-sm ghost" href="{up}#latest">Downloads</a>
  </div>
</header>'''


def footer(up=''):
    """The landing page's footer: the lockup, the links, the independence line. page.js adds the
    Look picker at its end."""
    return f'''<footer class="foot">
  <div class="wrap foot-in">
    <a class="foot-lockup" href="{LANDING}" aria-label="BT Wallet for Epic Cash, about the wallet"><img class="on-dark-img" src="{up}img/bt-wallet-lockup-row-dark.svg" width="220" height="53" alt="" decoding="async"><img class="on-light-img" src="{up}img/bt-wallet-lockup-row-light.svg" width="220" height="53" alt="" decoding="async"></a>
    <nav class="foot-nav" aria-label="Links"><a href="{LANDING}">About the wallet</a><a href="{up}changelog/">Changelog</a><a href="{LANDING}screens/">Every screen</a><a href="{up}restore/">Restore map</a><a href="mailto:support@btlabs.uk" translate="no">support@btlabs.uk</a></nav>
    <p class="pub">An independent, open-source wallet by <span translate="no">BT LABS</span>. Not made by the Epic Cash project. Use it within the law where you live.</p>
  </div>
</footer>'''


def hero(latest, g, plat_line):
    """One download: page.js points the big button at the primary file of the platform the browser
    reports and fills its name, size and requirement; without it (or on an unknown system) the
    button leads to the platform list. Under it the version and date, a row of links (the
    platform's Install guide and build without Tor once page.js knows it, and Verify downloads:
    the page's one entry to the Verify section besides each card's own link), the other platforms
    as small links, and the app itself: the desktop Overview and the phone's Home from the release
    screen catalog, dark and light (the Day look shows the light pair)."""
    shot = ('<img class="on-dark-img" src="img/{d}.webp" width="{w}" height="{h}" alt="{alt}" decoding="async"{eager}>'
            '<img class="on-light-img" src="img/{d}-light.webp" width="{w}" height="{h}" alt="{alt}" decoding="async" loading="lazy">')
    desk = shot.format(d='hero-desktop', w=1280, h=800, eager=' fetchpriority="high"',
                       alt='The desktop app: the Overview with the balance, Send and Receive, and recent activity')
    phone = shot.format(d='hero-phone', w=640, h=1421, eager=' loading="lazy"',
                        alt='The phone app: the Home screen with the balance and recent activity')
    chips = ''.join(f'<li><a href="#dl-{k}" data-pick="{k}" title="{esc(PLAT[k][1])}">{ICONS[k]}<span>{esc(PLAT[k][1])}</span></a></li>'
                    for k in g if k in PLAT and g[k]['primary'])
    return f'''<section class="hero">
  <div class="wrap hero-in">
  <div class="hero-text">
    <p class="badge"><span class="dot" aria-hidden="true"></span>Open beta<span class="b-sep" aria-hidden="true"></span><span translate="no">{esc(latest['version'])}</span></p>
    <h1><span class="h1-a">Download</span> <span class="h1-b" translate="no">BT Wallet.</span></h1>
    <p class="lede">A self-custodial wallet for Epic Cash. Keys stay on your device, locked with a password.</p>
    <div class="get">
      <a class="btn primary big" id="hero-dl" href="#latest"><span class="b-ico" id="hero-dl-ico">{ICONS['down']}</span><span class="b-text"><span id="hero-dl-text">Choose your platform</span><small id="hero-dl-sub">{esc(plat_line)}</small></span></a>
      <p class="get-meta"><span id="hero-req"></span><span id="hero-ver" translate="no">{esc(latest['version'])}</span> · <time id="hero-date" datetime="{latest['date']}">{human_date(latest['date'])}</time> · <a href="#notes">What's new</a></p>
      <p class="get-alt" id="hero-alt"><a id="hero-before" href="#latest" hidden>Install guide</a><a id="hero-notor" href="#latest" hidden download>Without Tor</a><a class="get-verify" href="#verify">{ICONS['shield']}Verify downloads</a></p>
    </div>
    <div class="also"><p id="also-h">All platforms</p><ul aria-labelledby="also-h">{chips}</ul></div>
  </div>
  <div class="hero-art">
    <figure class="window">{desk}</figure>
    <figure class="phone">{phone}</figure>
  </div>
  </div>
</section>
'''


def render(out_dir):
    data = load()
    rels = sorted(data['releases'], key=lambda r: vkey(r['version']), reverse=True)
    assert rels, 'no release recorded: run add first'
    latest = rels[0]
    g = group(rels)
    for k in STORE_ONLY:
        g[k] = {'primary': None, 'files': []}
    g = {k: g[k] for k in [p[0] for p in PLATFORMS] + ['other'] if k in g}
    plat_names = [PLAT[k][1] for k in g if k in PLAT and g[k]['primary'] and not PLAT[k][4]]
    previews = [PLAT[k][1] for k in g if k in PLAT and g[k]['primary'] and PLAT[k][4]]
    plat_line = ', '.join(plat_names) + ('; ' + ' and '.join(previews) + ' preview' if previews else '')
    sizes = [e['size'] for gg in g.values() if gg['primary'] for e in [gg['primary']]]

    page = f'''<!doctype html>
<html lang="en" data-look="a">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="dark light">
<meta name="theme-color" content="#08080a">
<meta name="description" content="Download BT Wallet for Epic Cash {esc(latest['version'])}: {esc(plat_line)}. With checksums.">
<title>Download BT Wallet for Epic Cash</title>
<link rel="icon" href="img/favicon.ico" sizes="any">
<link rel="icon" href="img/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="img/apple-touch-icon.png">
<link rel="stylesheet" href="style.css">
<script src="theme.js"></script>
<script src="page.js" defer></script>
</head>
<body>
{DEFS}
<a class="skip" href="#latest">Skip to the downloads</a>

{header()}

<main>
{hero(latest, g, plat_line)}
<dl class="wrap facts">
  <div><dt>Version</dt><dd translate="no">{esc(latest['version'])}</dd></div>
  <div><dt>Released</dt><dd><time datetime="{latest['date']}">{human_date(latest['date'])}</time></dd></div>
  <div><dt>Download</dt><dd>{mb(min(sizes))}–{mb(max(sizes))}&nbsp;MB</dd></div>
  <div><dt>Status</dt><dd>Open beta</dd></div>
</dl>

<section class="wrap latest" id="latest" aria-labelledby="latest-h">
  <div class="sh"><h2 id="latest-h"><span class="k-n" aria-hidden="true">[01]</span>All platforms</h2></div>
{platforms(g, latest)}
{phones(g)}
  <div class="small-print">
    <p><b>Without Tor</b>: the same app with Tor left out, for places where Tor is unwanted or blocked. It cannot send to Tor addresses and updates itself like the normal app. Installing either over the other keeps the wallets.</p>
  </div>
</section>

{verify(g, latest)}

{notes(latest, changelog(out_dir))}
</main>

{footer()}
</body>
</html>
'''
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, 'index.html'), 'w', encoding='utf-8', newline='') as f:
        f.write(page)
    for name in ('style.css', 'page.js', 'theme.js'):
        shutil.copy(os.path.join(ASSETS, name), os.path.join(out_dir, name))
    for sub in ('fonts', 'img'):
        os.makedirs(os.path.join(out_dir, sub), exist_ok=True)
        for name in os.listdir(os.path.join(ASSETS, sub)):
            shutil.copy(os.path.join(ASSETS, sub, name), os.path.join(out_dir, sub, name))
    print(f'{out_dir}: {latest["version"]}, '
          + ', '.join(f'{k} {gg["primary"]["version"]}' for k, gg in g.items() if gg['primary']))


def main(argv):
    if not argv or argv[0] in ('-h', '--help'):
        print(__doc__)
        return 0
    cmd, args = argv[0], argv[1:]
    if cmd == 'add':
        cmd_add(args)
    elif cmd == 'keep':
        print('\n'.join(sorted(keep(args[0], [n.strip() for n in sys.stdin if n.strip()]))))
    elif cmd == 'render':
        out = args[args.index('--out') + 1] if '--out' in args else DEFAULT_OUT
        render(out)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
