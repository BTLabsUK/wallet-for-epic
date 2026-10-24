/// The app's version and the core's, the two numbers About shows (https://docs.btlabs.uk/developers/releases/).
library;

/// The app's version, calendar versioning `YY.MM.patch` (a test build adds `-rcN`): the same
/// as `pubspec.yaml`'s `version:` before the `+`. Written by `tools/version.sh set` at release
/// time only; `tools/version.sh check` and `test/version_test.dart` fail when the two drift.
const String appVersion = '26.10.12';

/// LEPIC's version (SemVer): the workspace version in its `Cargo.toml` at the pin
/// (`tools/lepic.rev`). `tools/version.sh core` writes it after the pin moves; the check fails
/// while it differs.
const String coreVersion = '0.1.0';

/// [version] with the core's: `26.10.0 · core 0.1.0`.
String withCoreVersion(String version) => '$version · core $coreVersion';

/// Whether [version] is a test build (`26.10.0-rc1`): never offered as an update, and never
/// published to the update channel.
bool isTestVersion(String version) => version.contains('-');
