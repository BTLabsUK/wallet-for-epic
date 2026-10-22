/// The product's name in every title, header and footer. "Epic Cash" is the coin and its
/// network, never the app. The runners, the installer and the Android label spell it too:
/// `windows/runner/main.cpp`, `windows/installer/epic_wallet.iss`, `android/.../AndroidManifest.xml`.
const String appName = 'Epic Wallet';

/// The short git commit a release build was made from (`--dart-define=WFE_BUILD_ID=...`, set by
/// the release scripts), empty in other builds. The version stays as it is; this tells builds of
/// one version apart.
const String appBuildId = String.fromEnvironment('WFE_BUILD_ID');

/// [version] with the build: `0.1.0 (ba10dec)`, or [version] alone without one.
String withBuildId(String version) =>
    appBuildId.isEmpty ? version : '$version ($appBuildId)';
