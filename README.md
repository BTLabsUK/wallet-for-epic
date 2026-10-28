<div align="center">

<img src="app/web/icons/icon.svg" alt="Epic Cash" width="96" height="96">

# Epic Cash Desktop and Epic Cash Mobile

**Wallets for Epic Cash on Android, Linux, Windows and macOS, built on the LEPIC wallet core.**

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Flutter 3.47.5](https://img.shields.io/badge/flutter-3.47.5-02569B.svg)](scripts/linux/flutter.version)
[![Version 26.10](https://img.shields.io/badge/version-26.10-informational.svg)](app/pubspec.yaml)

[Build](#build-from-source) · [Documentation](https://docs.btlabs.uk) ·
[LEPIC](https://github.com/BTLabs-EPIC/lepic) · [Security](SECURITY.md)

</div>

Epic Cash Mobile (Android) and Epic Cash Desktop (Linux, Windows and macOS) are one Flutter app with
two front ends. The wallet itself is [LEPIC](https://github.com/BTLabs-EPIC/lepic), a Rust wallet
engine that runs inside the app's process; the app calls it through its Flutter binding,
[lepic-flutter](https://github.com/BTLabs-EPIC/lepic-flutter). The app creates and restores
wallets, scans the chain through an Epic node, and sends and receives with the standard
`epic-wallet`.

> **Status: in production.** Released as calendar versions (26.10.x) for Android, Linux and
> Windows. The macOS and iOS builds are a preview: they build and pass a smoke test, but
> are not released yet.

## What it does

- **Every way to pay:** Epicbox, slate files, QR codes (animated for large slates), and direct
  HTTP(S) and Tor (`epic-wallet`'s HTTP send and listener).
- **Tor built in** on desktop and Android: the wallet gets its own `.onion` address, and with Tor on,
  Epicbox and the node are reached through it. A build without Tor exists too.
- **Its own node or a public one:** the desktop can run the Epic node it bundles; both apps can use a
  node of your own on your network, with failover between public nodes.
- **Invoices and contacts,** with paired contacts whose keys are checked, and payment requests by
  file, Epicbox or QR.
- **Moving in from older wallets:** import the seed and transaction history of the Epic Cash GUI
  wallet and `epic-wallet`, checked against a chain scan.
- **Six languages:** English, German, Polish, Russian, Chinese and Thai, with help in each.

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
git clone https://github.com/BTLabs-EPIC/wallet-for-epic && cd wallet-for-epic
. tools/env.sh
tools/lepic.sh sync            # lepic-flutter and LEPIC at the pinned commits, into app/third_party/
tools/lepic.sh build linux     # the native library for this host

cd app
flutter pub get
flutter run -d linux -t lib/main_desktop.dart
```

The `tools/lepic.rev` and `tools/lepic-flutter.rev` files pin LEPIC and the binding. By default
`tools/lepic.sh sync` clones both from GitHub; set `LEPIC_REPO` and `LEPIC_FLUTTER_REPO` to a
local checkout or another URL to use them instead. The release AppImage is built in an Ubuntu 22.04
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
`play` builds the Google Play bundle, and `fdroid` builds the APK without Google ML Kit, after
`tools/dist-prep.sh fdroid` has prepared a clean copy of the checkout.

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
tools/check.sh                 # the full gate: version check, LEPIC build, analyzer, unit and integration tests, web build
```

Tests that need the network (`app/test/*_live_test.dart`) skip themselves unless their
environment variables are set (`WFE_LEPIC_LIB`, `WFE_LIVE_DIR`, …); `app/integration_test/` runs
on a device or desktop. Neither runs in CI.

## Project structure

| Path | Contents |
|---|---|
| `app/lib/` | The app: `main.dart` (phone), `main_desktop.dart` (desktop), `src/` shared code, `src/desktop/` the desktop UI |
| `app/lib/l10n/` | Translations (ARB files) and the generated localisations |
| `app/test/`, `app/integration_test/` | Unit and widget tests; tests on a device or desktop |
| `app/android/`, `app/linux/`, `app/windows/`, `app/macos/`, `app/ios/`, `app/web/` | Platform runners; `app/windows/installer/` is the Inno Setup installer |
| `app/assets/` | Fonts, icons, help pictures and password lists, each with its licence |
| `app/tool/` | Release builds and helper scripts |
| `tools/` | LEPIC pins and build (`lepic.sh`), Tor fetch and source build, the toolchain environment, versioning, store-build preparation |
| `scripts/` | The container build of the Linux AppImage |
| `fastlane/` | Store listing text and pictures |

## Security

Do not open public issues for vulnerabilities. [SECURITY.md](SECURITY.md) explains how to report
one privately: email support@btlabs.uk or use GitHub's private vulnerability reporting. The wallet
engine's security model is described in [LEPIC](https://github.com/BTLabs-EPIC/lepic) and on
[docs.btlabs.uk](https://docs.btlabs.uk/developers/security-model/).

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first. Changes to the wallet
engine belong in [LEPIC](https://github.com/BTLabs-EPIC/lepic).

## Documentation

- User guide and developer guide: https://docs.btlabs.uk (building from source:
  https://docs.btlabs.uk/developers/build/)
- Wiki: https://github.com/BTLabs-EPIC/wallet-for-epic/wiki

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE). Bundled fonts, icons, password
lists and Tor carry their own licences in `app/assets/`; the app shows them all on its licences
page (About on the desktop, Settings on the phone).

<p align="center"><sub>Made by BT Labs</sub></p>
