# Apple builds of a release from a clean clone

The short path for a builder who has only git and a Mac: build the macOS app (with and without
Tor) and the iOS App Store build (without Tor) of one release from
github.com/BTLabsUK/wallet-for-epic. The one-time set-up (certificates, notary login, App
Store Connect record) and the reasons behind each step are in `tools/apple-release.md`.

Release 26.11.4: version `26.11.4`, iOS build number `26110400` (from `app/pubspec.yaml`; it
must be above the last upload, 26110200). Team `AM8YPW9P6T` (BT LABS LTD). Bundle ids
`uk.btlabs.btwallet.ios` (iPhone) and `uk.btlabs.btwallet.macos` (Mac).

## Tools

| What | Version |
| --- | --- |
| Mac | Apple silicon (arm64) |
| macOS | 26 (Tahoe) |
| Xcode | 27.x, `xcode-select -s /Applications/Xcode.app`, license accepted, first launch run |
| Flutter | exactly 3.47.5 (`git clone -b 3.47.5 https://github.com/flutter/flutter.git ~/flutter`) |
| Rust | rustup; LEPIC's `rust-toolchain.toml` picks 1.99.0 and the targets by itself |
| jq | any |
| Disk | about 60 GB free |

No CocoaPods: the app uses Swift Package Manager.

## Source

Before the release is tagged the release commit is the tip of `main`; after the publish, tag
`v26.11.4` names the same commit.

```
git clone https://github.com/BTLabsUK/wallet-for-epic.git && cd wallet-for-epic
git log -1 --format='%H %s'          # the release commit; app/pubspec.yaml says version: 26.11.4+26110400
cp app/Signing.xcconfig.example app/Signing.xcconfig
sed -i '' 's/^DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = AM8YPW9P6T/' app/Signing.xcconfig
tools/build-apple.sh doctor
```

`app/Signing.xcconfig` is git-ignored. Never pick the team in Xcode's Signing & Capabilities tab:
it writes into `project.pbxproj` and the release builds refuse a checkout with changes. The
LEPIC and lepic-flutter sources come from github.com/BTLabsUK at the commits pinned in
`tools/lepic.rev` and `tools/lepic-flutter.rev`; the script clones them itself.

Once the tag exists, use it instead of `main`:

```
git fetch --tags origin && git checkout --detach v26.11.4
```

## iOS: App Store build (no Tor)

```
RELEASE_VERSION=26.11.4 RELEASE_COMMIT=HEAD WFE_TOR=0 WFE_DIST=appstore tools/build-apple.sh ios-prepare
open app/ios/Runner.xcworkspace
```

In Xcode: scheme **Runner**, destination **Any iOS Device (arm64)**, Product, **Archive**. In the
Organizer: **Distribute App**, **App Store Connect**, **Upload**, automatic signing. Send the
owner the build number once App Store Connect shows it as processed. There is no iOS build with
Tor. Submit for Review is the owner's step in App Store Connect.

## macOS: notarised dmg, with and without Tor

Needs the Developer ID Application certificate for AM8YPW9P6T in the login keychain and the
notary profile `btlabs-notary` (`tools/apple-release.md`, one-time set-up, steps 5 and 7).

```
RELEASE_VERSION=26.11.4 RELEASE_COMMIT=HEAD tools/build-apple.sh mac-release
RELEASE_VERSION=26.11.4 RELEASE_COMMIT=HEAD WFE_TOR=0 tools/build-apple.sh mac-release
```

On a checkout of the tag, leave out `RELEASE_COMMIT=HEAD`. Results:
`build-apple/tor/mac-release/bt-wallet-26.11.4-macos.dmg` and
`build-apple/notor/mac-release/bt-wallet-26.11.4-notor-macos.dmg`, each with `.sha256` and
`.REPORT.txt`. The Mac app goes out as this dmg on BT Labs' download page, not the Mac App Store:
send the three files of each variant to the owner, and the `.sha256` lines by chat too.

## Before sending

- The REPORT names the release commit and `app version: 26.11.4`.
- `TeamIdentifier=AM8YPW9P6T` for the dmg and the app inside.
- Gatekeeper: `accepted`, `source=Notarized Developer ID`, for the dmg and the app.
