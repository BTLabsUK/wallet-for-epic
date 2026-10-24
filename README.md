# Epic Cash Desktop and Epic Cash Mobile

A wallet for [Epic Cash](https://epiccash.com) on Android (Epic Cash Mobile) and the desktop, Linux and
Windows (Epic Cash Desktop). The interface is a Flutter app; the wallet itself is
[LEPIC](https://github.com/BTLabs-EPIC/lepic), a Rust wallet engine that the app calls through its
Flutter binding, [lepic-flutter](https://github.com/BTLabs-EPIC/lepic-flutter). Payments go over
Epicbox, files, HTTP and Tor.

Status: pre-release.

## Build

Requirements: Flutter (the version in `scripts/linux/flutter.version`), Rust (rustup; LEPIC pins its
toolchain), and for Android the Android SDK with NDK `28.2.13676358`. `tools/env.sh` sets the usual
paths; every variable it sets can be overridden from the environment.

```bash
. tools/env.sh
tools/lepic.sh sync            # clone lepic-flutter and LEPIC at the commits in tools/lepic-flutter.rev and tools/lepic.rev
tools/lepic.sh build linux     # the native library for this host (android: the three Android ABIs)

cd app
flutter pub get
flutter run -d linux -t lib/main_desktop.dart    # desktop
flutter run -t lib/main.dart                     # phone or emulator
```

Release builds:

- Linux AppImage, built in an Ubuntu 22.04 container: `scripts/build-linux.sh`
- Android APK: `app/tool/build_android_release.sh`
- Windows installer: `app/tool/build_windows_release.ps1` (on Windows)

## Test

```bash
tools/check.sh                 # the full gate: LEPIC build, analyzer, unit and integration tests, web build
cd app && flutter test         # unit and widget tests only
```

## Layout

| Path | Contents |
|---|---|
| `app/` | The Flutter app: `lib/` sources, `test/` and `integration_test/`, platform folders, `tool/` build scripts |
| `tools/` | LEPIC and lepic-flutter pins and build (`lepic.rev`, `lepic-flutter.rev`, `lepic.sh`), Tor bundle fetch, toolchain environment, versioning, `check.sh` |
| `scripts/` | Container build of the Linux AppImage |
| `services/push/` | The payment push service the phone registers with |

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE). Bundled fonts and password lists carry their own
licences next to them in `app/assets/`.
