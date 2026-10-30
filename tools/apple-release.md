# Apple releases: Xcode on the release Mac

How Epic Cash Desktop (macOS) and Epic Cash Mobile (iOS) are built, signed, notarised and
shipped. This is Apple's standard team flow: one person owns the account, a team member with a
Mac builds and signs with Xcode.

| Who | Role in Apple's terms | Does |
| --- | --- | --- |
| **Owner** | Account Holder of the BT Labs organisation membership | Invites the builder, makes the Developer ID certificate, decides what ships: App Store "Submit for Review" and the publish of the `.dmg` on our download page |
| **Builder** | Admin, with "Access to Certificates, Identifiers & Profiles" | Builds, signs, notarises and uploads on a Mac (Apple silicon, macOS 26, Xcode 27) |

Distribution: Desktop is a notarised `.dmg` from our own download page, with Tor and the
built-in node inside (no Mac App Store: the app is not sandboxed, and the bundled node and tor
would make the sandbox a project of its own). Mobile goes to TestFlight, then the App Store, as
the build without Tor (`WFE_TOR=0`; iOS cannot start a bundled tor). The macOS app is Apple
silicon only (the built-in node has no Intel build); the iPhone app is iPhone only.

Final ids, register exactly these: **`uk.btlabs.epiccashwallet.macos`** (Epic Cash Desktop) and
**`uk.btlabs.epiccashwallet.ios`** (Epic Cash Mobile).

The repository side: the team is never in the Xcode projects. The builder puts it in
`app/Signing.xcconfig` (git-ignored, from `app/Signing.xcconfig.example`), which both projects
include. Signing is Automatic; the macOS Release build has the hardened runtime on. A build phase
of the macOS project, "Bundle node and tor" (`app/macos/Runner/bundle-bin.sh`), copies the node
and tor that `tools/build-apple.sh` staged into `Contents/Resources/bin` and signs them before
Xcode signs the app. One in the iOS project, "lepic_ffi privacy manifest"
(`app/ios/Runner/lepic-privacy.sh`), adds the wallet library's privacy manifest and signs it
again.

## One-time set-up

Steps marked ⏳ wait for Apple to approve the membership.

1. ⏳ **Owner**: when Apple approves the enrolment, note the **Team ID** (developer.apple.com,
   Account, Membership details) and send it to the builder.
2. ⏳ **Owner**: App Store Connect, Users and Access, +: the builder's Apple ID, role **Admin**,
   tick **Access to Certificates, Identifiers & Profiles**. The builder accepts the email
   invitation.
3. **Builder**: on the Mac, Keychain Access, Certificate Assistant, *Request a Certificate From a
   Certificate Authority*: your email, common name "BT Labs Developer ID", *Saved to disk*. Send
   the `.certSigningRequest` file to the owner (it is not secret; the private key stays in your
   keychain).
4. ⏳ **Owner**: developer.apple.com, Certificates, +, **Developer ID Application**, profile type
   **G2 Sub-CA**, upload the builder's `.certSigningRequest`, download the `.cer`, send it to the
   builder. Only the Account Holder can do this: Apple's help lists "Required role: Account
   Holder" for Developer ID certificates. Admins can only use a *cloud-managed* Developer ID
   certificate, which works only inside Xcode's export. That export does not sign the node and
   tor we bundle, so it is not used here.
5. **Builder**: double-click the `.cer` (it joins its private key in the login keychain), then
   check it shows up: `security find-identity -v -p codesigning` lists
   `Developer ID Application: <BT Labs name> (<Team ID>)`. Back it up once: Keychain Access, My
   Certificates, the Developer ID entry, Export as `.p12` with a strong password, kept offline.
6. **Builder**: Xcode, Settings, Accounts, + your Apple ID; the BT Labs team appears. Xcode makes
   the Apple Development and Apple Distribution certificates itself on the first Archive.
7. **Builder**: the notarisation login, stored in the keychain. Make an app-specific password
   at account.apple.com (Sign-In and Security), then:

   ```
   xcrun notarytool store-credentials epic-notary --apple-id <your Apple ID> --team-id <Team ID>
   ```

   (it asks for the app-specific password).
8. **Builder**: the tools (table below), then the source and the team:

   ```
   git clone https://gitlab.com/epic-cash-bt/wallet-for-epic.git && cd wallet-for-epic
   cp app/Signing.xcconfig.example app/Signing.xcconfig    # set DEVELOPMENT_TEAM = <Team ID>
   tools/build-apple.sh doctor
   ```

   Do not pick the team in Xcode's Signing & Capabilities tab: that writes it into
   `project.pbxproj`, and release builds refuse a checkout with local changes.
9. **Builder**: developer.apple.com, Identifiers, +, App IDs, App: `uk.btlabs.epiccashwallet.ios`
   (iOS, "Epic Cash Mobile") and `uk.btlabs.epiccashwallet.macos` (macOS, "Epic Cash Desktop"),
   no capabilities. Then App Store Connect, Apps, +, New App: iOS, "Epic Cash Mobile", bundle id
   `uk.btlabs.epiccashwallet.ios`, SKU `epiccashmobile`.
10. **Owner**: decide export compliance and the privacy label (the App Store Connect drafts,
    `docs/apple-app-store.md` in the development repository). If the answer sets
    `ITSAppUsesNonExemptEncryption`, the dev team commits it to `app/ios/Runner/Info.plist`
    before the first upload.

### The Mac's tools

| What | Version | How |
| --- | --- | --- |
| macOS | 26 (Tahoe) | System Settings, General, Software Update |
| Xcode | 27.x | Mac App Store, then `sudo xcode-select -s /Applications/Xcode.app`, `sudo xcodebuild -license accept`, `xcodebuild -runFirstLaunch` |
| Flutter | **exactly 3.47.5** | `git clone -b 3.47.5 https://github.com/flutter/flutter.git ~/flutter`, `~/flutter/bin` on `PATH`, `flutter config --no-analytics`, `flutter precache --macos --ios` |
| Rust | rustup (LEPIC's `rust-toolchain.toml` pins the toolchain) | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh -s -- -y` |
| jq | any | `brew install jq` or its release binary |
| Free disk | about 60 GB | |

No CocoaPods (the app uses Swift Package Manager). Do not create an Xcode project: they are in
the repository, `app/ios/Runner.xcworkspace` and `app/macos/Runner.xcworkspace`.

## Each release

When the release runner (`tools/rel`) drives the release, steps 2 to 4 are its hand-offs
`apple-mac-<tor|notor>` and `ios-testflight` and its check `apple-mac-check-<variant>`: the job
and the results folders, and where the Team ID for the check is set, are in `docs/RELEASING.md`,
section Apple (development repository). By hand it is:

1. **Owner**: send the builder the commit (or tag) on GitLab to build.
2. **Builder**, macOS: on a clean checkout of that commit, build the variant with Tor and the one
   without (both are published, as on the other platforms):

   ```
   git fetch --tags origin && git checkout --detach <commit>
   RELEASE_COMMIT=<commit> tools/build-apple.sh mac-release
   RELEASE_COMMIT=<commit> WFE_TOR=0 tools/build-apple.sh mac-release
   ```

   One command does all of it: checks the checkout and the toolchain, the Developer ID
   certificate and the notary login, builds, signs every binary with Developer ID (hardened
   runtime, Apple's timestamp, inside out), notarises and staples the app, makes the `.dmg`,
   signs, notarises and staples it, then runs Gatekeeper on it. In `build-apple/mac-release/`:
   `EpicCashDesktop-<v>-macos.dmg`, `.dmg.sha256` and `.REPORT.txt` (`<v>` is `26.10.24` or
   `26.10.24-notor`). Send all three to the owner, and the `.sha256` line also by chat.
3. **Builder**, iOS:

   ```
   RELEASE_COMMIT=<commit> WFE_TOR=0 tools/build-apple.sh ios-prepare
   open app/ios/Runner.xcworkspace
   ```

   In Xcode: scheme **Runner**, destination **Any iOS Device (arm64)**, Product, **Archive**.
   When the Organizer opens: **Distribute App**, **App Store Connect**, **Upload**, automatic
   signing. The build reaches TestFlight after Apple's processing (minutes to an hour). Tell the
   owner its build number. Each upload needs a higher build number (the `+N` of the version in
   `app/pubspec.yaml`).
4. **Owner**, before the `.dmg` goes on the download page (the release gate):
   - `sha256sum -c EpicCashDesktop-<v>-macos.dmg.sha256` passes, and the hash is the one the
     builder sent by chat;
   - in the REPORT: `commit:` is the commit you asked for, and it is on GitLab;
   - `TeamIdentifier=` is the BT Labs Team ID, for the `.dmg` and for the app in it;
   - the Gatekeeper part says `accepted` and `source=Notarized Developer ID`, for the `.dmg` and
     for the app.

   Then publish as on the other platforms (download page, update manifests).
5. **Builder**: install the TestFlight build on an iPhone and test it (restore a wallet, receive,
   send a small amount, scan a QR code, Face ID unlock, lock and unlock after a restart).
6. **Owner**: App Store Connect, the app, the tested build, **Submit for Review**; release when
   Apple approves.

## First signed release: once only

From the first signed release on, these never change. A change breaks updates, the keychain, or
both.

| Frozen | Why |
| --- | --- |
| Bundle ids `uk.btlabs.epiccashwallet.macos`, `uk.btlabs.epiccashwallet.ios` | The App Store record, the keychain items and the macOS data are tied to them |
| The Team ID | macOS keychain items trust "signed by this team with this id"; iOS keychain items live in `<Team ID>.uk.btlabs.epiccashwallet.ios`. A new team = every user's stored secrets unreachable |
| The certificate **type**: Developer ID Application (macOS), Apple Distribution (iOS) | A new certificate of the same type and team (renewal, a second builder) keeps everything working; another type does not |
| The data folder `~/.epic_cash_desktop`, the login keychain on macOS, no `keychain-access-groups` on iOS | Changing them moves where data and secrets are looked up |
| The update manifest and the macOS `.dmg` name pattern | The in-app updater reads them |

Checks, on the builder's Mac, before the first `.dmg` is published:

1. **Update test with a funded wallet.** Install the last ad-hoc preview (the last 26.10.x macOS
   `.dmg` on our download page), open a wallet that holds coins, note the balance, quit. Install
   the signed `.dmg` over it (the in-app update if the preview offers it, else drag to
   Applications). Expected: the wallets in `~/.epic_cash_desktop` are all there. The first unlock
   shows **one** keychain prompt ("Epic Cash Desktop wants to use … in your keychain"), because
   the preview's items trust only the old ad-hoc build. Enter the login password and choose
   **Always Allow**. Balance and history match; a small send and a receive work. Quit and start
   again: **no** prompt. Build and sign the same commit a second time and install it over: still
   no prompt (every later update looks like this). Deny the prompt once as a test: nothing is
   lost, it asks again on the next unlock.
2. Apple's notarisation logs beside the `.dmg` (`*.notary-log.json`) have no warnings.
3. iOS: the TestFlight build passes step 5 above on a real iPhone.
4. Record in the release notes: Team ID, the Developer ID certificate's serial number and expiry,
   the REPORT. Tell preview testers about the one-time keychain prompt.
5. The dev team freezes the Apple items in `tools/install-contract.json` (`macos.bundle_id`,
   `ios.bundle_id`, `ios.macos.keychain` from not frozen to frozen, with the Team ID); from then
   on `tools/check.sh` guards them like the other platforms' ids.

## What only the Mac and Apple can prove

Checked on Linux: the Xcode projects parse with the new build phases, signing settings and
includes; the scripts pass shellcheck; the install contract is unchanged. Not checked yet, and
proven by the first real run:

| Check | Proven by |
| --- | --- |
| The "Bundle node and tor" phase copies and signs the node, tor and libevent in a `flutter build macos` and in an Xcode Archive | The first `mac-release` (its file-list check) / an Archive |
| Every Mach-O file carries the team, hardened runtime and timestamp; Apple notarises app and `.dmg` | The first `mac-release` (it checks each file before uploading) |
| Gatekeeper accepts the `.dmg` and the app | `mac-release`'s gatekeeper step, then a real download in Safari |
| The iOS Archive embeds the privacy manifest; App Store Connect processes the build | The first upload |
| The keychain prompt on update from ad-hoc to signed | The funded-wallet test above |

Other commands of `tools/build-apple.sh` (no Apple account needed): `doctor`, `macos` and `dmg`
(an ad-hoc build to try), `ios-sim`, `smoke`, `live`, `gatekeeper <dmg>`.

## Later

- Push notifications on iOS need an APNs key and the `aps-environment` entitlement; not built.
- Tor on iOS would need an in-process library.
- A Mac App Store build would need the sandbox, which the bundled node and tor do not allow today.

## Appendix: the Linux route (backup)

If no builder with a Mac and the team's certificate is available, the owner can still sign
everything on Linux with [rcodesign](https://github.com/indygreg/apple-platform-rs) 0.29.0. The
tools are kept for this: `tools/apple-sign.sh`, `tools/asc_upload.py` and
`tools/apple-signing.env.example`. Any Mac then only builds, unsigned, and never holds a key. It
was dry-run on the 26.10.23 builds with stand-in certificates; nothing signed by it has been
through Apple yet.

```
Mac (any builder)                             Owner (Linux)
-----------------                             -------------
build-apple.sh release            ─ hand-off ─▶ apple-sign.sh check
  unsigned .app + Runner.app                     apple-sign.sh macos-app   (sign, notarise, staple)
  PROVENANCE.txt, SHA256SUMS                     apple-sign.sh ios         (sign with the profile)
                                                 apple-sign.sh ios-upload  (TestFlight)
build-apple.sh dmg-signed <tar>  ◀─ signed app ─
  the .dmg of the signed app      ─── .dmg ───▶ apple-sign.sh macos-dmg   (sign, notarise, staple)
build-apple.sh gatekeeper <dmg>  ◀─ final dmg ─
```

The `.dmg` goes back to the Mac because nothing on Linux can write an Apple disk image. Every
hand-off is checked by its SHA-256 (sent by chat) and `SHA256SUMS`, so any channel works for the
files.

On the Mac: `RELEASE_COMMIT=<commit> [WFE_TOR=0] tools/build-apple.sh release` writes
`build-apple/handoff/EpicCash-<v>-<commit>/` (both unsigned apps as `.tar.gz`, `PROVENANCE.txt`
with every file's SHA-256, `SHA256SUMS`). Later, `tools/build-apple.sh dmg-signed <signed tar>`
and `tools/build-apple.sh gatekeeper <final dmg>`.

### The owner's Linux machine

#### Install (once)

| What | How |
| --- | --- |
| rcodesign 0.29.0 | `apple-codesign-0.29.0-x86_64-unknown-linux-musl.tar.gz` from the [apple-codesign/0.29.0 release](https://github.com/indygreg/apple-platform-rs/releases/tag/apple-codesign%2F0.29.0); check its SHA-256 is `dbe85cedd8ee4217b64e9a0e4c2aef92ab8bcaaa41f20bde99781ff02e600002`; put `rcodesign` on `PATH` |
| 7-Zip 23 or newer (reads APFS disk images) | the `7zip` package (`7zz`), or `7z2501-linux-x64.tar.xz` from 7-zip.org |
| openssl 3, python3, zip, unzip, tar, sha256sum | the distribution's packages |

Then `tools/apple-sign.sh doctor`.

#### Keys: where they live

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

#### Certificates, ids and keys (once, after Apple approves the membership)

1. Note the Team ID (Membership details) into `signing.env`.
2. **Developer ID Application** certificate (only the owner can make one):
   `tools/apple-sign.sh csr devid`, then developer.apple.com, Certificates, +, Developer ID
   Application, profile type **G2 Sub-CA**, upload `keys/devid.csr`, download the `.cer`, then
   `tools/apple-sign.sh p12 devid <downloaded .cer>`.
3. **Apple Distribution** certificate: `tools/apple-sign.sh csr dist`, Certificates, +, Apple
   Distribution, upload `keys/dist.csr`, download, `tools/apple-sign.sh p12 dist <.cer>`.
4. Identifiers, +, App IDs, App: explicit bundle id `uk.btlabs.epiccashwallet.ios`, description
   "Epic Cash Mobile", no capabilities (no push yet). Also register `uk.btlabs.epiccashwallet.macos`
   (macOS) to hold the id.
5. Profiles, +, Distribution, **App Store Connect**, the App ID above, the Apple Distribution
   certificate; download the `.mobileprovision` into `keys/`, set `IOS_PROFILE`. It lasts a year;
   renewing it changes nothing for users.
6. App Store Connect, Apps, +, New App: iOS, name, primary language English (U.K.) or English
   (U.S.), bundle id `uk.btlabs.epiccashwallet.ios`, SKU (see `docs/apple-app-store.md`).
7. App Store Connect, Users and Access, Integrations, App Store Connect API: request access (only
   the owner can), then a **Team** key (an individual key cannot notarise) with the
   **Developer** role (enough to notarise and upload; App Manager if an upload is refused). Note
   the key id and the issuer id, download `AuthKey_<id>.p8` into `keys/`, fill `ASC_*`, then
   `tools/apple-sign.sh api-key` (rcodesign's key file for notarisation).

#### Dry run (any time, no Apple account)

```
tools/apple-sign.sh test-identity <scratch dir>
APPLE_SIGNING_ENV=<scratch dir>/signing.env tools/apple-sign.sh macos-app <hand-off dir>
APPLE_SIGNING_ENV=<scratch dir>/signing.env tools/apple-sign.sh ios <hand-off dir>
```

Self-signed stand-ins for both certificates and a stand-in profile: the whole signing path runs
and every check is made (including Apple's timestamp server); notarisation and upload are skipped.
The output is not trusted by any Apple device.

#### A release, signing side

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

### If a step cannot be done on Linux

Default: the owner signs everything. If Apple refuses something signed by rcodesign and
it cannot be fixed in time, the least-trust fallback for that step only:

- The owner makes an **extra** certificate of the same type (Developer ID allows up to
  five) from a CSR the release builder creates on the Mac, so its private key is made on the Mac and
  can be revoked alone without touching the owner's own certificate. The Mac then signs
  with `codesign` / `xcodebuild -exportArchive`; the owner still notarises, uploads and
  publishes with the keys on Linux.
- Revoke that certificate as soon as the Linux path works again. For Developer ID, revocation also
  stops new installs of what it signed, so re-release those files signed on Linux first.
