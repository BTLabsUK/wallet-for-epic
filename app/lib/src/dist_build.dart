/// Where this build is distributed: the one build-time switch of the store builds
/// (https://docs.btlabs.uk/developers/build/variants/). `--dart-define=WFE_DIST=web` (or unset) is the build from our own
/// download page, as every build before the switch; `play` is the Google Play build, `fdroid` the
/// F-Droid and IzzyOnDroid build. The build scripts set it from their `WFE_DIST` env, and
/// android/app/build.gradle.kts reads the same dart-define.
///
/// - web: the in-app updater and its install permission.
/// - play, fdroid: no in-app updater and no install permission; the store updates the app.
/// - fdroid also reads QR codes with a free scanner instead of Google ML Kit:
///   `tools/dist-prep.sh fdroid` swaps it in the checkout before the build.
/// No build has Firebase or any other Google push code (removed in 26.10.20).
library;

/// The distribution channel of this build.
enum Dist { web, play, fdroid }

const String _distDefine = String.fromEnvironment('WFE_DIST', defaultValue: 'web');

/// This build's channel. An unknown value reads as [Dist.web]; the build scripts and Gradle
/// refuse one before it gets here.
const Dist dist = _distDefine == 'play'
    ? Dist.play
    : _distDefine == 'fdroid'
    ? Dist.fdroid
    : Dist.web;

/// The app updates itself from our update feed: only the build from our own page. A store
/// updates its own builds (Google Play allows no other way, F-Droid only an opt-in one).
const bool distUpdates = dist == Dist.web;

/// The store that updates this build, by its own name (never translated); null for the build
/// from our own page.
const String? distStore = dist == Dist.play
    ? 'Google Play'
    : dist == Dist.fdroid
    ? 'F-Droid'
    : null;
