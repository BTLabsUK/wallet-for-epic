/// The desktop app's product name, in every desktop title, header and footer (the phone's is
/// `appTitle` in l10n: "Epic Cash Mobile"). "Epic Cash" alone is the coin and its network. The
/// runners and the installer spell it too: `windows/runner/main.cpp`, `windows/runner/Runner.rc`
/// (FileDescription only), `windows/installer/epic_wallet.iss`, `linux/runner/my_application.cc`.
/// The ids are `uk.btlabs.epiccash.desktop` and `uk.btlabs.epiccash.mobile`; the Inno AppId and
/// install folder, the secure-storage prefix and the binary names keep the old name on purpose
/// (`README.md`, "App ids and data folders").
const String appName = 'Epic Cash Desktop';

/// The short git commit a release build was made from (`--dart-define=WFE_BUILD_ID=...`, set by
/// the release scripts), empty in other builds. The version stays as it is; this tells builds of
/// one version apart.
const String appBuildId = String.fromEnvironment('WFE_BUILD_ID');

/// [version] with the build: `0.1.0 (ba10dec)`, or [version] alone without one.
String withBuildId(String version) =>
    appBuildId.isEmpty ? version : '$version ($appBuildId)';
