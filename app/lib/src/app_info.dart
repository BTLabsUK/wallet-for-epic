// SPDX-License-Identifier: Apache-2.0
import 'app_version.dart' show coreVersion, withCoreVersion;

/// The product name, BT Wallet, in every desktop title, header and footer (the phone's is
/// `appTitle` in l10n, the same name). "Epic Cash" alone is the coin and its network. The
/// window title the runners set before the first frame spells it too:
/// `windows/runner/main.cpp`, `linux/runner/my_application.cc`. The Windows version resource
/// (`windows/runner/Runner.rc`), the installer (`windows/installer/epic_wallet.iss`), the MSIX
/// manifest and the macOS bundle name keep "Epic Cash Desktop" until the owner decides on them:
/// the installer, the Store listing and the update checks read them. The ids are
/// `uk.btlabs.epiccash.desktop` and `uk.btlabs.epiccash.mobile`; the Inno AppId and install
/// folder, the secure-storage prefix and the binary names keep the old name on purpose
/// (`README.md`, "App ids and data folders").
const String appName = 'BT Wallet';

/// The short git commit a release build was made from (`--dart-define=WFE_BUILD_ID=...`, set by
/// the release scripts), empty in other builds. The version stays as it is; this tells builds of
/// one version apart.
const String appBuildId = String.fromEnvironment('WFE_BUILD_ID');

/// A rebuild of the same version, `r2` (`--dart-define=WFE_BUILD_TAG=...`, from the release tag
/// `v<version>-r2` on the built commit); empty for the first build of a version.
const String appBuildTag = String.fromEnvironment('WFE_BUILD_TAG');

/// [version] with the build: `0.1.0 (ba10dec)`, or [version] alone without one.
String withBuildId(String version) =>
    appBuildId.isEmpty ? version : '$version ($appBuildId)';

/// About's version line: the app's version, the app commit it was built from and the core's,
/// `26.10.25 · app 98949ac · core 0.1.0`; without a build id `26.10.25 · core 0.1.0`.
String versionLine(String version) =>
    appBuildId.isEmpty ? withCoreVersion(version) : '$version · app ${_short(appBuildId)} · core $coreVersion';

String _short(String id) => id.length > 7 ? id.substring(0, 7) : id;
