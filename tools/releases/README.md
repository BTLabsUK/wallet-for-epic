# The releases page

`build.py` renders the public releases page for BT Wallet for Epic Cash, in the landing page's
three looks (Night, Grid, Day; see below):
one big download for the browser's platform (its size, requirement, version and date beside
it, the other platforms as small links, the app itself: the desktop Overview and the phone's Home,
dark and light, from the release screen catalog), a row of facts (version, date, sizes, status),
every platform in one list (Desktop, then Mobile: the primary download, the one without Tor, an
Install guide fold and a Files and checksums fold), short phone install steps, a folded Verify a
download, and What's new: the first points of this version's changelog entry (read from
changelog/index.html in the output folder; its old app names read as the app) with the earlier
versions folded, each linking to its changelog entry. Served from the
release folder on the server, today at https://examples.btlabs.uk/epic-cash-wallets/ and
at https://epiccash.btlabs.uk/releases/ (same folder, so the page uses relative links only).

```
releases.json      the data: the current release (version, date, files: name, size, sha256); `add` replaces it
build.py           add / render (see its docstring)
assets/            style.css, page.js, theme.js, fonts/ (Montserrat, JetBrains Mono NL, Geist, Geist Mono,
                   Bricolage Grotesque, Inter; all OFL), img/ (the BT Wallet lockups and favicons from
                   the brand kit, and the hero's hero-desktop*.webp / hero-phone*.webp: the catalog's
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
   When the folder holds `SHA256SUMS.sig` (written by `tools/release-files.py publish`), every
   Before you install fold also shows the minisign check: then `SHA256SUMS` and
   `SHA256SUMS.sig` must be in `downloads/` on the server too. `--github` adds the Mirror
   link, only once the GitHub Release exists and logged-out visitors can open it.
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
  the copy buttons, the Look picker and the browser's own platform (User-Agent Client Hints,
  then the user agent): the hero's button downloads that platform's primary file and its row is
  marked This device; nothing moves. A link to #dl-<platform> or #before-<platform> picks that
  platform instead. Without JavaScript the hero's button leads to the platform list.
- The Android certificate fingerprint in `ANDROID_CERT_SHA256` is the release key's
  (`apksigner verify --print-certs`); change it only if the key changes.
- The app is BT Wallet; the coin is Epic Cash. Platforms say Desktop or Mobile, never "Epic Cash
  Desktop/Mobile". BT LABS in caps. The footer keeps the independence line and "Use it within
  the law where you live." No store names, no tester group.
- Three looks in one style.css under `html[data-look]`: a Night, b Grid, c Day (Day follows the
  system's dark mode, like the landing page). theme.js reads the landing page's
  `localStorage['btw-look']` before the first paint (Night when none; this origin only, so
  examples.btlabs.uk keeps its own choice); page.js adds the footer's Look picker, which
  switches in place and saves the choice.
- The changelog (in the page repo) uses the same chrome: build.py's `DEFS`, `header('../')`
  and `footer('../')`, and one inline script (the trailing-slash fix and the saved look).
- The hero shows real screens, never a mock-up: after a release that changes the Overview or
  the phone's Home, refresh the four hero images from `/tmp/epic-build/screens/latest`
  (Pillow: WEBP quality 86 desktop as is, 84 phone resized to 640 wide).
