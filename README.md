<div align="center">

<img src="app/web/icons/icon.svg" alt="BT Wallet" width="96" height="96">

# BT Wallet

**Wallets for Epic Cash on Android, Linux, Windows and macOS, built on the LEPIC wallet core.**

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Flutter 3.47.5](https://img.shields.io/badge/flutter-3.47.5-02569B.svg)](scripts/linux/flutter.version)
[![Version 26.10](https://img.shields.io/badge/version-26.10-informational.svg)](app/pubspec.yaml)

[Download](https://epiccash.btlabs.uk/releases/) · [Wiki](https://github.com/BTLabsUK/wallet-for-epic/wiki) ·
[Build](#build-from-source) · [Documentation](https://docs.btlabs.uk) ·
[LEPIC](https://gitlab.com/epic-cash-bt/lepic) · [Security](SECURITY.md) ·
[GitHub mirror](https://github.com/BTLabsUK/wallet-for-epic)

</div>

BT Wallet (Android, Linux, Windows and macOS) is one Flutter app with
two front ends. The wallet itself is [LEPIC](https://gitlab.com/epic-cash-bt/lepic), a Rust wallet
engine that runs inside the app's process; the app calls it through its Flutter binding,
[lepic-flutter](https://gitlab.com/epic-cash-bt/lepic-flutter). The app creates and restores
wallets, scans the chain through an Epic node, and sends and receives with the standard
`epic-wallet`.

> **Status: in production.** Released as calendar versions (26.10.x) for Android, Linux and
> Windows. The macOS build (Apple silicon) and the iOS build are a preview.

## Download

Every release is on **[epiccash.btlabs.uk/releases](https://epiccash.btlabs.uk/releases/)**, with
checksums and a "Before you install" note per platform, and on the
[GitHub Releases](https://github.com/BTLabsUK/wallet-for-epic/releases) page:

| Platform | File |
|---|---|
| Windows 10 and 11 (x64) | `bt-wallet-<version>-windows-x64-setup.exe` |
| Linux (x86_64) | `bt-wallet-<version>-linux-x86_64.AppImage` |
| macOS (Apple silicon, preview) | `bt-wallet-<version>-macos.dmg` |
| Android 7.0 or newer (arm64) | `bt-wallet-<version>-android-arm64-v8a.apk` |

Each also comes as a build without Tor (`notor` in the file name). Install steps for each platform
are in the [wiki](https://github.com/BTLabsUK/wallet-for-epic/wiki).

## What it does

- **Every way to pay:** Epicbox; Link · HTTP and Link · Tor, straight to another wallet
  (compatible with `epic-wallet`'s HTTP send and listener); Direct · File Transfer, and on the
  phone Direct · QR Payment, an animated QR code between two phones.
- **Tor built in** on desktop and Android, off by default: with Tor on, Epicbox goes through it and
  the wallet gets its own `.onion` address. Network modes go further: Tor only, Node only, or Kill
  switch (nothing connects). A build without Tor exists too.
- **Its own node or a public one:** the desktop can run the Epic node it bundles; both apps can use a
  node of your own on your network, with failover between public nodes.
- **Contacts and linked devices:** the same wallet on a phone and a computer, linked so each knows
  what the other is paying. Pairing and invoices are experimental switches, off by default.
- **Moving in from older wallets:** import the seed and transaction history of the Epic Cash GUI
  wallet and `epic-wallet`, checked against a chain scan.
- **Six languages:** English, German, Polish, Russian, Chinese and Thai, with help in each.
- **Your servers in one small file:** the Node and Epicbox lists and a few on/off switches live in
  `settings.toml` in the wallet's data folder (the first server of each list is the one in use);
  on desktop it can be edited while the wallet runs. The defaults are `node.epiccash.com` and
  `epicbox.epiccash.com`. Everything else the app talks to is in the read-only
  `app/assets/config/app-config.toml`: no address is written in the code.
- **Amounts at a glance:** four decimals wherever a balance or amount is shown, all eight where
  the exact value matters (a payment's review, its file and QR code).

## Build from source

### What you need

| Tool | Version | Used for |
|---|---|---|
| Flutter | 3.47.5 (`scripts/linux/flutter.version`) | the app, every platform |
| Rust | rustup; LEPIC pins its toolchain in `rust-toolchain.toml` | the LEPIC library |
| Git, a C compiler, CMake | any recent | LEPIC and the desktop runners |
| Android SDK + NDK | Flutter's default `compileSdk` and NDK, Java 21 | Android |
| GTK 3 dev packages, clang, ninja, pkg-config | distribution packages | Linux |
| Visual Studio 2022 Build Tools (C++), CMake, Git | 2022 | Windows |
| Xcode | a current release | macOS and iOS |

`tools/env.sh` sets the usual paths (Flutter, Java, Android SDK and NDK). Each value is only a
default; set the variable to use your own.

### Linux

```bash
git clone https://gitlab.com/epic-cash-bt/wallet-for-epic && cd wallet-for-epic
. tools/env.sh
tools/lepic.sh sync            # lepic-flutter and LEPIC at the pinned commits, into app/third_party/
tools/lepic.sh build linux     # the native library for this host

cd app
flutter pub get
flutter run -d linux -t lib/main_desktop.dart
```

The `tools/lepic.rev` and `tools/lepic-flutter.rev` files pin LEPIC and the binding. By default
`tools/lepic.sh sync` clones both from GitLab (or from `~/lepic` and `~/lepic-flutter`, when
those checkouts hold the pinned commits); set `LEPIC_REPO` and `LEPIC_FLUTTER_REPO` to a local
checkout or another URL to use them instead. The release AppImage is built in an Ubuntu 22.04
container: `scripts/build-linux.sh` (needs Docker or Podman).

### Android

```bash
. tools/env.sh
tools/lepic.sh sync
tools/lepic.sh build android   # arm64-v8a, armeabi-v7a and x86_64 libraries, built with cargo-ndk
cd app && flutter run -t lib/main.dart
```

`app/tool/build_android_release.sh` builds the release APK (arm64-v8a). It needs a signing key
named by `WFE_ANDROID_KEY_PROPERTIES`; without one it stops. Store builds use `WFE_DIST`:
`play` builds the Google Play bundle, and `fdroid` the F-Droid APK. No build has Google ML Kit
or Play services: the QR scanner is camera + flutter_zxing everywhere.

### Windows

In PowerShell 7, with the tools above:

```powershell
pwsh -NoProfile -File app\tool\build_windows.ps1            # a portable folder and zip
pwsh -NoProfile -File app\tool\build_windows_release.ps1    # the Inno Setup installer (needs Inno Setup 6)
```

### macOS and iOS (preview)

```bash
tools/build-apple.sh           # doctor, sources, LEPIC for the Apple targets, the .app and .dmg, the Simulator app
tools/build-apple.sh help      # every step and setting
```

No Apple account is needed: the macOS app is signed ad hoc, and the iOS `.ipa` is unsigned.

### Without Tor

`WFE_TOR=0` builds every platform without Tor: LEPIC without its `tor` feature, no tor binary, and
`--dart-define=WFE_TOR=false`.

## Testing

```bash
cd app && flutter test         # unit and widget tests (need the Linux library from tools/lepic.sh build linux)
tools/check.sh                 # from the root: LEPIC at the pin, the analyzer, and the tests your change touches
tools/check.sh --full          # everything: the whole suite, the integration tests and the web build
tools/testbin.sh get linux|apk # the shared debug bundle or APK of HEAD, built once per commit
```

Test runs on this host take their Linux bundle and APK from `tools/testbin.sh`, never from a build
of their own ([docs/dev-tooling.md](docs/dev-tooling.md)).

Tests that need the network (`app/test/*_live_test.dart`) skip themselves unless their
environment variables are set (`WFE_LEPIC_LIB`, `WFE_LIVE_DIR`, …); `app/integration_test/` runs
on a device or desktop. Builds and tests run on our own machines, not on hosted CI: run
`tools/check.sh` before you send a change (see https://docs.btlabs.uk/developers/testing/).

## Project structure

| Path | Contents |
|---|---|
| `app/lib/` | The app: `main.dart` (phone), `main_desktop.dart` (desktop), `src/` shared code, `src/desktop/` the desktop UI |
| `app/lib/l10n/` | Translations (ARB files) and the generated localisations |
| `app/test/`, `app/integration_test/` | Unit and widget tests; tests on a device or desktop |
| `app/android/`, `app/linux/`, `app/windows/`, `app/macos/`, `app/ios/`, `app/web/` | Platform runners; `app/windows/installer/` is the Inno Setup installer |
| `app/assets/` | Fonts, icons, help pictures and password lists, each with its licence |
| `app/assets/config/` | `settings.default.toml` (the first-start copy of the user's `settings.toml`) and the built-in `app-config.toml` |
| `app/tool/` | Release builds and helper scripts |
| `tools/` | LEPIC pins and build (`lepic.sh`), Tor fetch and source build, the toolchain environment, versioning, store-build preparation |
| `scripts/` | The container build of the Linux AppImage |
| `fastlane/` | Store listing text and pictures |

## Security

Do not open public issues for vulnerabilities. [SECURITY.md](SECURITY.md) explains how to report
one privately: email support@btlabs.uk or open a confidential issue. The wallet
engine's security model is described in [LEPIC](https://gitlab.com/epic-cash-bt/lepic) and on
[docs.btlabs.uk](https://docs.btlabs.uk/developers/security-model/).

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first. Changes to the wallet
engine belong in [LEPIC](https://gitlab.com/epic-cash-bt/lepic).

## Documentation

- Wiki: installing, your first wallet, payment methods, Tor and network modes, troubleshooting,
  building and architecture: https://github.com/BTLabsUK/wallet-for-epic/wiki
- User guide and developer guide: https://docs.btlabs.uk (building from source:
  https://docs.btlabs.uk/developers/build/)
- In the app: Help, in all six languages.

## Source

GitLab is the home of the source, the issues and the merge requests:
[gitlab.com/epic-cash-bt/wallet-for-epic](https://gitlab.com/epic-cash-bt/wallet-for-epic).
GitHub holds an exact read-only copy (the same commits and tags):
[github.com/BTLabsUK/wallet-for-epic](https://github.com/BTLabsUK/wallet-for-epic), with the
release files on its Releases page as a second download place.

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE). Bundled fonts, icons, password
lists and Tor carry their own licences in `app/assets/`; the app shows them all on its licences
page (About on the desktop, Settings on the phone).

<p align="center"><sub>Made by BT Labs</sub></p>
