# The releases page

`build.py` renders the public releases page for Epic Cash Desktop and Epic Cash Mobile:
a hero with the download for the browser's platform and the app itself (the desktop Overview
and the phone's Home, dark and light, from the release screen catalog), one tile per platform,
then the current release only, with one primary download per platform and the rest folded,
checksums, a Before you install fold per platform, one changelog link (the way to history). Served from the
release folder on the server, today at https://examples.btlabs.uk/epic-cash-wallets/ and
at https://epiccash.btlabs.uk/releases/ (same folder, so the page uses relative links only).

```
releases.json      the data: the current release (version, date, files: name, size, sha256); `add` replaces it
build.py           add / render (see its docstring)
assets/            style.css, page.js, theme.js, fonts/ (Montserrat, JetBrains Mono NL, OFL), img/
                   (brand, and the hero's hero-desktop*.webp / hero-phone*.webp: the catalog's
                   desktop/overview/main and phone/home/main, dark and light, phone at 640 px wide)
```

## A new release

`tools/rel` does this as its `publish-page` and `prune-downloads` steps (docs/RELEASING.md;
`publish-page` also commits `releases.json` on main, step 4);
the page lists only the files of the release folder, so a release that leaves a platform out
needs the page settled first (the manifests keep that platform's live entry, prune keeps its
files). By hand:

1. `tools/releases/build.py add 26.10.24 /srv/wfe-release/26.10.24` (the folder with
   the files and SHA256SUMS; `--date` if not today). Checksums are recomputed and must agree.
   When the folder holds `SHA256SUMS.sig` (written by `tools/gitlab-release.py publish`), every
   Before you install fold also shows the minisign check: then `SHA256SUMS` and
   `SHA256SUMS.sig` must be in `downloads/` on the server too. `--gitlab` / `--github` add the
   Mirror links, only once that host's release exists and logged-out visitors can open it.
2. `tools/releases/build.py render` writes the page into the page repo's `site/epic-cash/`
   (`~/code/epic-gui-wallet-progress`, or `$WFE_RELEASES_SITE`). Add the version's entry to
   `site/epic-cash/changelog/index.html` there (`id="v26.10.24"`: the page links it).
3. In the page repo: commit, then `./deploy-epic-cash.sh`. It leaves downloads/ and
   update.json alone and checks the live URLs.
4. Commit `releases.json` here.
5. Prune the server: the page keeps no history, so the previous version's files leave
   `downloads/` (keep anything an update manifest still names: update.json at examples,
   /api/v1/update.json, the mirrors' update.json and update-v2.json). Keep a local copy of
   each removed file with its checksum under `/tmp/epic-build/wfe-release-archive/<version>/`
   first. Old version URLs answering 404 is intended.

A new kind of build (a portable zip, an MSIX, a .deb, a universal APK) needs one line in
`KINDS` in build.py: the file-name pattern, its platform, its label and whether it is the
platform's primary download. A file no pattern knows still appears, under Other files.

## Rules the page keeps

- Relative links only (`downloads/…`, `changelog/`): the page is served under two hosts.
- No inline script (theme.js is external), no tracking, nothing from another host; fonts are
  self-hosted. Every download is a plain link and every fold a `<details>`: page.js only adds
  the copy buttons and puts the browser's own platform first (User-Agent Client Hints, then
  the user agent): the hero's button downloads that platform's primary file, Before you
  install leads to its fold, its card goes first; a platform tile picks another. Without
  JavaScript the hero's button leads to the platform list and every platform is shown the
  same way.
- The Android certificate fingerprint in `ANDROID_CERT_SHA256` is the release key's
  (`apksigner verify --print-certs`); change it only if the key changes.
- App names are Epic Cash Desktop and Epic Cash Mobile. No store names, no tester group.
- The hero shows real screens, never a mock-up: after a release that changes the Overview or
  the phone's Home, refresh the four hero images from `/tmp/epic-build/screens/latest`
  (Pillow: WEBP quality 86 desktop as is, 84 phone resized to 640 wide).
