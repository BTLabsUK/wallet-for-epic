# Apple releases: build on a Mac, sign on Linux

How Epic Cash Desktop (macOS) and Epic Cash Mobile (iOS) are built, signed, notarised and
uploaded. Two people take part:

- **The release builder** runs a Mac (Apple silicon, macOS 26, Xcode 27). The Mac builds
  **unsigned** apps from a given commit and makes the `.dmg` of an app that is already signed. It
  never holds a signing key, a certificate's private key or an App Store Connect key.
- **The account holder** owns the Apple Developer Program membership (an organisation enrolment)
  and signs everything on a **Linux** machine: Developer ID for the macOS app and `.dmg`,
  notarisation and stapling, Apple Distribution for the iOS app, and the TestFlight upload. The
  keys stay there.

Tools: `tools/build-apple.sh` (the Mac), `tools/apple-sign.sh` with `tools/asc_upload.py` (Linux,
on [rcodesign](https://github.com/indygreg/apple-platform-rs) 0.29.0), settings from
`tools/apple-signing.env.example`. The App Store Connect drafts (`docs/apple-app-store.md`) and the
port's history (`docs/apple-port-notes.md`) are in the development repository only; the public
copy leaves `docs/` out, so the account holder shares the drafts.

Distribution: Desktop is a notarised `.dmg` from our own download page (no Mac App Store: the app
is not sandboxed, and the bundled node and tor would make the sandbox a project of its own).
Mobile goes to TestFlight, then the App Store. iOS has no Tor; the App Store build is the variant
without Tor (`WFE_TOR=0`). The macOS app is Apple silicon only (the built-in node has no Intel
build). The iPhone app is iPhone only (no iPad layout yet; adding iPad later is possible, removing
it after release may not be).

## The flow

```
release builder (Mac)                         account holder (Linux)
---------------------                         ----------------------
build-apple.sh release            ─ hand-off ─▶ apple-sign.sh check
  unsigned .app + Runner.app                     apple-sign.sh macos-app   (sign, notarise, staple)
  PROVENANCE.txt, SHA256SUMS                     apple-sign.sh ios         (sign with the profile)
                                                 apple-sign.sh ios-upload  (TestFlight)
build-apple.sh dmg-signed <tar>  ◀─ signed app ─
  the .dmg of the signed app      ─── .dmg ───▶ apple-sign.sh macos-dmg   (app in it = signed app;
                                                                            sign, notarise, staple)
build-apple.sh gatekeeper <dmg>  ◀─ final dmg ─
  Gatekeeper's verdict, install test                publish: download page, update.json
```

Why the `.dmg` goes back to the Mac: nothing on Linux can write an Apple disk image (rcodesign
signs and staples one but cannot create or change it). The Mac only packs the signed, stapled app;
the account holder then checks with 7-Zip that the app inside is file for file the one signed, and
only then signs the `.dmg`.

What the provenance gives: `PROVENANCE.txt` names the commit, the toolchain (macOS, Xcode, SDKs,
Flutter, Rust), the LEPIC and lepic-flutter commits, the pinned node and tor archives, and the
SHA-256 of every file of both apps. Builds are not bit-for-bit reproducible (Xcode and Flutter
stamp build data), so this is an audit trail and an integrity check of the hand-off, not a proof
that the source made the binary. A second builder can compare file lists to see what differs.

## What freezes at the first signed release

Before the first signed release, anything on Apple may still change: nobody runs a signed build
yet. From the first signed release on, these never change, because a change breaks updates, the
keychain, or both:

| Frozen | Why |
| --- | --- |
| Bundle ids `uk.btlabs.epiccash.desktop` and `uk.btlabs.epiccash.mobile` | The App Store record, the keychain items and the macOS data are tied to them. (`com.btlabs.epiccashwallet.macos/.ios` was suggested and is **not** used: btlabs.uk is the domain, so `uk.btlabs` is the right reverse DNS.) |
| The Team ID | macOS keychain items trust "signed by this team with this id" (the designated requirement); iOS keychain items live in the access group `<Team ID>.uk.btlabs.epiccash.mobile`. A new team = every user's stored secrets unreachable. |
| The certificate **type**: Developer ID Application (macOS), Apple Distribution (iOS) | Renewing a certificate of the same type and team keeps everything working; switching type does not. |
| The data folder `~/.epic_cash_desktop` and the app's file names and formats | As on every other platform. |
| No `keychain-access-groups` entitlement on iOS, the login keychain on macOS (`usesDataProtectionKeychain: false`) | Changing either moves where secrets are looked up. |
| The update manifest and the macOS `.dmg` name pattern | The in-app updater on macOS reads them. |

Write the Team ID into the release record when the first signed build ships.

## The release builder's Mac

### Install (once)

| What | Version | How |
| --- | --- | --- |
| macOS | 26 (Tahoe) | System Settings, General, Software Update |
| Xcode | 27.1 (any 27.x; Apple takes uploads built with Xcode 26 or newer and the iOS 26 SDK or newer) | Mac App Store, then `sudo xcode-select -s /Applications/Xcode.app`, `sudo xcodebuild -license accept`, `xcodebuild -runFirstLaunch` |
| iOS platform (Simulator runtime) | the one Xcode offers | `xcodebuild -downloadPlatform iOS` (several GB; only for the Simulator steps) |
| Flutter | **exactly 3.47.5** | `git clone -b 3.47.5 https://github.com/flutter/flutter.git ~/flutter`, add `~/flutter/bin` to `PATH`, `flutter config --no-analytics`, `flutter precache --macos --ios`, `flutter doctor` |
| Rust | rustup; the toolchain itself is pinned by LEPIC's `rust-toolchain.toml` and installs on first use | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh -s -- -y`; the `lepic` step adds the Apple targets |
| jq, git | any | `xcode-select --install` gives git; jq from Homebrew (`brew install jq`) or its release binary |
| Free disk | about 60 GB | Xcode, Flutter, Rust targets, build output |

No CocoaPods: the app uses Swift Package Manager. No Apple ID needs to be signed in to Xcode, and
no certificate is installed on this Mac.

**Do not create an Xcode project.** Flutter generated them and they are in the repository:
`app/macos/Runner.xcworkspace` (macOS) and `app/ios/Runner.xcworkspace` (iOS). Open a workspace
(not the `.xcodeproj`) only to look at settings or run on a device while debugging; releases are
always built by `tools/build-apple.sh` from the command line, so every release is built the same
way.

### Get the source

```
git clone https://gitlab.com/epic-cash-bt/wallet-for-epic.git
cd wallet-for-epic
tools/build-apple.sh doctor
```

The `sources` step clones LEPIC and lepic-flutter from their public GitLab copies at the commits
pinned in `tools/lepic.rev` and `tools/lepic-flutter.rev`. The commit ids to build are the ones on
GitLab (the published history), which the account holder gives with each release.

### A release build

The account holder sends the commit (or tag) to build. For each release, build both variants:

```
git fetch --tags origin && git checkout --detach <commit>
RELEASE_COMMIT=<commit> tools/build-apple.sh release
RELEASE_COMMIT=<commit> WFE_TOR=0 tools/build-apple.sh release
```

`release` runs: `release-check` (clean checkout at `RELEASE_COMMIT`, Flutter exactly 3.47.5,
Apple silicon, the built-in node fetched by its pinned SHA-256), `doctor`, `sources`, `lepic`
(arm64 macOS and iOS), `macos`, `ipa` (adds the wallet library's privacy manifest), and `handoff`.
The result is `build-apple/handoff/EpicCash-<version>[-notor]-<commit>/` with:

In file names here, `<v>` is the version with the variant mark: `26.10.24` for the build with
Tor, `26.10.24-notor` for the build without.

| File | What |
| --- | --- |
| `EpicCashDesktop-<v>-macos-unsigned.tar.gz` | The macOS app as built (Xcode's ad-hoc signatures only) |
| `EpicCashMobile-<v>-ios-unsigned.tar.gz` | The iOS `Runner.app` as built, unsigned |
| `PROVENANCE.txt` | Commit, toolchain, pins, every file's SHA-256 |
| `SHA256SUMS` | The three files above |

Optional before handing over: `tools/build-apple.sh smoke` (needs the Simulator) on the same
checkout.

### Hand-off

Upload both hand-off folders to the staging area (below), then send the account holder the
SHA-256 of each `SHA256SUMS` file by another channel (chat):

```
shasum -a 256 build-apple/handoff/*/SHA256SUMS
```

### The `.dmg` of the signed app

When the signed app comes back (`EpicCashDesktop-<v>-macos-signed.tar.gz` with its
`SHA256SUMS`):

```
tools/build-apple.sh dmg-signed <path to>/EpicCashDesktop-<v>-macos-signed.tar.gz
```

It checks the tar against `SHA256SUMS`, unpacks it, and requires `codesign --verify --deep
--strict`, `stapler validate` and a Gatekeeper acceptance of the app before it makes
`build-apple/dmg-signed/EpicCashDesktop-<v>-macos.dmg`. Upload that `.dmg` (and its `.sha256`)
back. Nothing is signed here.

### Gatekeeper and install check of the final `.dmg`

```
tools/build-apple.sh gatekeeper <path to>/EpicCashDesktop-<v>-macos.dmg
```

Checks the `.dmg`'s signature, its stapled ticket and Gatekeeper's verdict (`spctl`), then mounts
it and checks the app the same way. Then install it as a user would: download it in Safari (so it
gets the quarantine flag), open it, drag the app to Applications, start it. It must open with no
"cannot be opened" or "unidentified developer" warning.

## Staging area for the hand-off

A drop folder on our own download server, reached over SFTP only. The account holder creates it
(it is not created by these scripts); one possible setup:

- A user for the release builder, `sftp` only: `ForceCommand internal-sftp`, a `ChrootDirectory`
  owned by root, key authentication only (the builder's own SSH public key), no shell, no port or
  agent forwarding.
- Folders: `incoming/` (the builder writes hand-offs and `.dmg`s), `signed/` (the account holder
  writes signed apps and final files; the builder reads).
- Nothing in it is secret (unsigned and signed builds become public anyway); what matters is that
  nobody else can put files there. The hash sent over chat, the `SHA256SUMS` and the file lists in
  `PROVENANCE.txt` catch a changed file in any case.

The release builder sends the account holder an SSH public key made for this (never a private
key); the account holder sends back the server name, user and folder privately, not in any file
in the repository.

Any other channel (a shared private folder, a private GitLab project with Git LFS) works the same
way, since every step checks the hashes.

## The account holder's Linux machine

### Install (once)

| What | How |
| --- | --- |
| rcodesign 0.29.0 | `apple-codesign-0.29.0-x86_64-unknown-linux-musl.tar.gz` from the [apple-codesign/0.29.0 release](https://github.com/indygreg/apple-platform-rs/releases/tag/apple-codesign%2F0.29.0); check its SHA-256 is `dbe85cedd8ee4217b64e9a0e4c2aef92ab8bcaaa41f20bde99781ff02e600002`; put `rcodesign` on `PATH` |
| 7-Zip 23 or newer (reads APFS disk images) | the `7zip` package (`7zz`), or `7z2501-linux-x64.tar.xz` from 7-zip.org |
| openssl 3, python3, zip, unzip, tar, sha256sum | the distribution's packages |

Then `tools/apple-sign.sh doctor`.

### Keys: where they live

- One folder for everything secret, `~/.config/epic-apple-signing/` by default (settings file
  `signing.env`, keys in `keys/`), mode 700, **outside every repository**, on an encrypted disk.
  `doctor` refuses a keys folder inside a git repository and settings that are not mode 600.
- Private keys are made here and never leave: `csr` writes an RSA 2048 key encrypted with a
  passphrase you type; `p12` packs it with Apple's certificate into a `.p12` whose random password
  is in a mode-600 file beside it.
- Backup: two encrypted copies of the keys folder on separate offline media (for example two USB
  sticks with an encrypted volume), kept apart; the passphrases in the password manager. Test a
  restore once.
- The App Store Connect `.p8` key can be downloaded **once**. Keep it with the other keys.
- Revocation, if a key may have leaked: revoke the certificate at developer.apple.com
  (Certificates) and the API key in App Store Connect (Users and Access, Integrations), make new
  ones, release again. A revoked Developer ID certificate stops new installs of everything signed
  with it, so revoke only for a real leak; never for an expiry (an expired certificate's signatures
  stay valid thanks to the timestamp).

### Certificates, ids and keys (once, after Apple approves the membership)

1. Note the Team ID (Membership details) into `signing.env`.
2. **Developer ID Application** certificate (only the account holder can make one):
   `tools/apple-sign.sh csr devid`, then developer.apple.com, Certificates, +, Developer ID
   Application, profile type **G2 Sub-CA**, upload `keys/devid.csr`, download the `.cer`, then
   `tools/apple-sign.sh p12 devid <downloaded .cer>`.
3. **Apple Distribution** certificate: `tools/apple-sign.sh csr dist`, Certificates, +, Apple
   Distribution, upload `keys/dist.csr`, download, `tools/apple-sign.sh p12 dist <.cer>`.
4. Identifiers, +, App IDs, App: explicit bundle id `uk.btlabs.epiccash.mobile`, description
   "Epic Cash Mobile", no capabilities (no push yet). Also register `uk.btlabs.epiccash.desktop`
   (macOS) to hold the id.
5. Profiles, +, Distribution, **App Store Connect**, the App ID above, the Apple Distribution
   certificate; download the `.mobileprovision` into `keys/`, set `IOS_PROFILE`. It lasts a year;
   renewing it changes nothing for users.
6. App Store Connect, Apps, +, New App: iOS, name, primary language English (U.K.) or English
   (U.S.), bundle id `uk.btlabs.epiccash.mobile`, SKU (see `docs/apple-app-store.md`).
7. App Store Connect, Users and Access, Integrations, App Store Connect API: request access (only
   the account holder can), then a **Team** key (an individual key cannot notarise) with the
   **Developer** role (enough to notarise and upload; App Manager if an upload is refused). Note
   the key id and the issuer id, download `AuthKey_<id>.p8` into `keys/`, fill `ASC_*`, then
   `tools/apple-sign.sh api-key` (rcodesign's key file for notarisation).

### Dry run (any time, no Apple account)

```
tools/apple-sign.sh test-identity <scratch dir>
APPLE_SIGNING_ENV=<scratch dir>/signing.env tools/apple-sign.sh macos-app <hand-off dir>
APPLE_SIGNING_ENV=<scratch dir>/signing.env tools/apple-sign.sh ios <hand-off dir>
```

Self-signed stand-ins for both certificates and a stand-in profile: the whole signing path runs
and every check is made (including Apple's timestamp server); notarisation and upload are skipped.
The output is not trusted by any Apple device.

### A release, signing side

```
RELEASE_COMMIT=<commit> tools/apple-sign.sh check     <hand-off dir>
RELEASE_COMMIT=<commit> tools/apple-sign.sh macos-app <hand-off dir>      # each variant
#  -> apple-signed/<hand-off>/EpicCashDesktop-<v>-macos-signed.tar.gz + SHA256SUMS: to the Mac
RELEASE_COMMIT=<commit> tools/apple-sign.sh macos-dmg <hand-off dir> <.dmg from the Mac>
#  -> apple-signed/<hand-off>/EpicCashDesktop-<v>-macos.dmg (+ .sha256): to the Mac for the
#     gatekeeper step, then to the download page and update.json as on other platforms
RELEASE_COMMIT=<commit> tools/apple-sign.sh ios <hand-off dir without Tor>
tools/apple-sign.sh ios-upload apple-signed/<hand-off>/EpicCashMobile-<v>-ios.ipa   # <v> = <version>-notor
```

What `macos-app` does: checks the hand-off (hashes, file lists, the bundle id), signs every Mach-O
file (app, frameworks, `lepic_ffi`, the node, tor, libevent) inside out with the Developer ID
certificate, the **hardened runtime** and a secure timestamp, the app with
`app/macos/Runner/Release.entitlements` (no sandbox; no JIT or library-validation exceptions are
needed, since everything is signed by the same team), leaves the plugins' resource bundles to the
app's seal as Xcode does, then checks every signature, the whole resource seal, that only code and
seals changed, and notarises and staples the app.

What `ios` does: checks the hand-off and the privacy manifest of the wallet library, reads the
App Store profile (team, bundle id, the certificate in it, not expired, not a device profile),
signs with exactly the entitlements Xcode would use for an App Store build
(`application-identifier`, `com.apple.developer.team-identifier`, `get-task-allow` false,
`beta-reports-active`), embeds the profile, checks the signatures and the seal, and zips the
`.ipa`.

`ios-upload` uses the App Store Connect API's build uploads (Apple's Transporter for Linux needs an
`AppStoreInfo.plist` that only Xcode's export writes). The build appears in TestFlight after
Apple's processing (minutes to an hour); App Store Connect emails if processing finds a problem.

Exit status of `apple-sign.sh`: 0 done, 1 a check or a tool failed, 2 usage, 3 Apple refused
(notarisation or upload). The notarisation log: `rcodesign notary-log --api-key-file <json> <id>`.

## First signed release: the checklist

1. Dry run passes on the hand-off of the release commit.
2. Export compliance and the privacy label are decided (`docs/apple-app-store.md`). If the
   choice sets `ITSAppUsesNonExemptEncryption`, the dev team commits it to
   `app/ios/Runner/Info.plist`, and the release build is made from that commit or a later one.
3. macOS: `macos-app`, `dmg-signed`, `macos-dmg`, `gatekeeper` all pass; the notarisation log has
   no warnings.
4. **Update test with a funded wallet**, on the release Mac: install the last ad-hoc preview
   (26.10.x, the macOS `.dmg` on our download page), open a wallet that holds coins, note the balance; quit; install the signed `.dmg`
   over it (through the in-app update if the preview offers it, else by dragging to Applications).
   Expected: the wallets in `~/.epic_cash_desktop` are all there; the first unlock shows **one**
   macOS keychain prompt ("Epic Cash Desktop wants to use ... in your keychain"), because the
   preview's items trust only the old ad-hoc build: enter the login password and choose **Always
   Allow**. Balance and history match; a small send and a receive work. Quit and start again: **no**
   prompt this time. Then sign a second build of the same commit and install it over: still no
   prompt (this is what every later update looks like).
   If the prompt is denied, the app must not lose anything: it asks again on the next unlock
   (check this; the PIN or password still opens the wallet files).
5. iOS: install from TestFlight on a real iPhone; restore the review wallet (the account holder
   sends its phrase privately, never in a file or the repository); receive, send a small
   amount, scan a QR, Face ID unlock, lock and unlock after a restart. iOS keychain items of the
   unsigned/Simulator builds never existed on a phone, so there is nothing to migrate; from here on
   the access group is fixed by the Team ID.
6. Record in the release notes: Team ID, certificate serial numbers and expiry dates, rcodesign
   version, the hand-off's `PROVENANCE.txt`.
7. Tell preview testers about the one-time keychain prompt.
8. Freeze the Apple items in the install contract: move `macos.bundle_id`, `ios.bundle_id` and
   `ios.macos.keychain` from `not_frozen` to the frozen list in `tools/install-contract.json`, with
   the Team ID (`tools/check.sh` then guards them like the other platforms' ids).

## What still needs Apple or a Mac

| Check | Needs | When |
| --- | --- | --- |
| Notarisation of the app and the `.dmg` (Apple's verdict on the signatures made on Linux) | Apple membership, Developer ID certificate, team API key | First signed release |
| Gatekeeper acceptance, `stapler validate`, `codesign --verify --deep --strict` | A Mac (`build-apple.sh dmg-signed`, `gatekeeper`) | Every release |
| App Store Connect processing of an rcodesign-signed `.ipa` (third-party reports say TestFlight accepts it; App Review not yet tried by them) | Membership, Apple Distribution certificate, profile, API key | First TestFlight upload |
| The build-uploads API calls in `asc_upload.py` (written from Apple's reference and a working third-party client; never run against Apple yet) | API key | First TestFlight upload |
| The keychain prompt on update from ad-hoc to signed | A Mac with a funded preview wallet | First signed release |
| The release build itself with the new arm64-only setting and the privacy manifest step | The release Mac | First `release` run |

Verified on Linux without Apple (dry run on the 26.10.23 builds): both macOS variants signed with
hardened runtime and Apple's timestamp on every Mach-O file (eight in the build with Tor), resource seal complete and
unchanged, only code and seals changed; a `.dmg` signed and timestamped; the `.dmg` content check
refuses an app that is not the signed one; the iOS app signed with profile entitlements and
packed; the upload token (ES256) made and checked with openssl.

## If a step cannot be done on Linux

Default: the account holder signs everything. If Apple refuses something signed by rcodesign and
it cannot be fixed in time, the least-trust fallback for that step only:

- The account holder makes an **extra** certificate of the same type (Developer ID allows up to
  five) from a CSR the release builder creates on the Mac, so its private key is made on the Mac and
  can be revoked alone without touching the account holder's own certificate. The Mac then signs
  with `codesign` / `xcodebuild -exportArchive`; the account holder still notarises, uploads and
  publishes with the keys on Linux.
- Revoke that certificate as soon as the Linux path works again. For Developer ID, revocation also
  stops new installs of what it signed, so re-release those files signed on Linux first.

## Later

- Push notifications on iOS need an APNs key (Keys, +, Apple Push Notifications service) and the
  `aps-environment` entitlement in the App ID and profile; not built (push is off on every
  platform).
- Tor on iOS would need an in-process library (iOS cannot start a bundled tor executable).
- A Mac App Store build would need the sandbox, which the bundled node and tor do not allow today.
