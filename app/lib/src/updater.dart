// SPDX-License-Identifier: Apache-2.0
/// In-app updates for Android builds distributed outside an app store.
///
/// A release publishes `update.json` (written and signed by `tool/release_android.sh`) on BT
/// Labs' Pages site; the split APKs stay on the GitHub release. `update.json` is a signed
/// envelope (btlabs-public FORMAT.md §6): the app verifies it with the bundled keys
/// ([btlabsKeyring]) before it shows or downloads anything, and an unsigned, forged, expired or
/// older one means "no update information". Then it picks the APK for this device's ABI,
/// downloads it, checks its size and SHA-256, and hands it to Android's PackageInstaller
/// (`AppUpdater.kt`), which also insists on the same package name, a higher version code and
/// the same signing key.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app_log.dart';
import 'app_version.dart';
import 'btlabs_keys.dart';
import 'btlabs_public.dart';
import 'net/tor_net.dart';
import 'l10n.dart';
import 'network_gate.dart';
import 'net/http.dart';
import 'net/socks.dart' show SocksError;
import 'providers.dart' show secretStoreProvider;
import 'tor_build.dart';

/// Where releases publish the signed `update.json`, in order. Every source is read and checked
/// against the same keys and anti-rollback state; the valid copy with the highest serial is
/// used, the first source on a tie. The release lead publishes the same signed file to each
/// (https://docs.btlabs.uk/developers/releases/). Add, remove or reorder sources here only.
const List<String> updateManifestSources = [
  // BT Labs' own server, beside the download page (with Tor on, its onion).
  'https://examples.btlabs.uk/epic-cash-wallets/update.json',
  // The GitLab copy of BT Labs' signed public files, as the raw file on main. GitLab Pages
  // would need CI, which the GitLab projects never run. While the project is private this
  // answers a sign-in page, which is not a manifest, so it is skipped.
  'https://gitlab.com/epic-cash-bt/btlabs-epic.github.io/-/raw/main/update.json',
  // GitHub Pages, last: GitHub hid the site on 2026-10-28 and no app saw 26.10.20. It may
  // come back.
  'https://btlabs-epic.github.io/update.json',
];

/// `--dart-define=WFE_UPDATE_URL=...` replaces the sources with that one; it must still be
/// signed with the bundled keys.
const String _updateUrlOverride = String.fromEnvironment('WFE_UPDATE_URL');

/// [updateManifestSources] (or the override) as addresses.
final List<Uri> updateManifestUrls = [
  for (final u in _updateUrlOverride.isEmpty ? updateManifestSources : const [_updateUrlOverride]) Uri.parse(u),
];

/// The installed app, as Android reports it.
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.versionCode,
    required this.versionName,
    required this.abis,
    this.canInstall = true,
  });

  final String packageName;
  final int versionCode;
  final String versionName;

  /// Supported ABIs, most preferred first.
  final List<String> abis;

  /// Whether Android lets this app install packages (Android 8+: "allow from this source"),
  /// asked before any download, so the permission trip never costs the download.
  final bool canInstall;
}

/// One APK of a release, for one ABI (or `universal`).
class ReleaseApk {
  const ReleaseApk({
    required this.abi,
    required this.versionCode,
    required this.url,
    required this.sha256,
    required this.size,
  });

  final String abi;
  final int versionCode;
  final Uri url;
  final String sha256;
  final int size;
}

/// The update this device should install.
class AvailableUpdate {
  const AvailableUpdate({
    required this.versionName,
    required this.notes,
    required this.apk,
  });

  final String versionName;
  final String notes;
  final ReleaseApk apk;
}

/// A manifest that does not parse or does not fit this app, or a download or install that
/// failed. [text] words it for the screen in the reader's language; [message] is English, for
/// logs.
class UpdateError implements Exception {
  UpdateError(this.text) : message = text(englishStrings);

  final String Function(AppLocalizations l) text;
  final String message;

  @override
  String toString() => message;
}

/// What [readUpdateManifest] made of a fetched `update.json`.
class UpdateManifestRead {
  const UpdateManifestRead.rejected(RejectReason this.rejected)
    : update = null,
      state = null;
  const UpdateManifestRead.accepted(this.update, ManifestState this.state)
    : rejected = null;

  /// Why the manifest was not used (no update information); null when it verified.
  final RejectReason? rejected;

  /// The update for this device; null when it verified but offers nothing newer.
  final AvailableUpdate? update;

  /// What to pass as `state` to the next read in this run (FORMAT.md §5, §6).
  final ManifestState? state;
}

/// Verifies [envelope] (FORMAT.md §5 and §6) with [keyring] before reading anything from it,
/// then picks the update for [app] ([pickUpdate]). [state] is what the last read in this run
/// accepted, so an older manifest replayed later in the run is refused. [now] is the clock.
Future<UpdateManifestRead> readUpdateManifest(
  String envelope,
  InstalledApp app, {
  required Keyring keyring,
  required DateTime now,
  ManifestState? state,
}) async {
  final result = await verifyWalletUpdate(
    envelope,
    keyring: keyring,
    state: state,
    now: now.toUtc(),
  );
  return switch (result) {
    Rejected(:final reason) => UpdateManifestRead.rejected(reason),
    Accepted(:final manifest, :final state) => UpdateManifestRead.accepted(
      pickUpdate(manifest, app),
      state,
    ),
  };
}

/// Picks the update for [app] from a verified [manifest], or null when it is up to date or
/// no APK fits this device's ABIs. A manifest for another app is an [UpdateError]. A test
/// build (`26.10.0-rc1`) is never offered, whatever its version code.
AvailableUpdate? pickUpdate(WalletUpdate manifest, InstalledApp app) {
  if (manifest.packageName != app.packageName) {
    throw UpdateError((l) => l.updateManifestOtherApp);
  }
  if (isTestVersion(manifest.versionName)) return null;
  // The signed manifest's URLs are https and its hashes 64 lowercase hex (the verifier's
  // schema); unique ABIs.
  final byAbi = {for (final a in manifest.apks) a.abi: a};
  WalletApk? chosen;
  for (final abi in [...app.abis, 'universal']) {
    chosen = byAbi[abi];
    if (chosen != null) break;
  }
  if (chosen == null || chosen.versionCode <= app.versionCode) return null;
  return AvailableUpdate(
    versionName: manifest.versionName,
    notes: manifest.notes,
    apk: ReleaseApk(
      abi: chosen.abi,
      versionCode: chosen.versionCode,
      url: chosen.url,
      sha256: chosen.sha256,
      size: chosen.size,
    ),
  );
}

/// Platform side: app info and the installer. Null on platforms without in-app updates.
abstract interface class UpdatePlatform {
  Future<InstalledApp> installedApp();

  /// Installs [apk]. Returns `started`, `needsPermission`, `keyMismatch` (signed with another
  /// key than this app, so Android never installs it over it), or throws [UpdateError].
  Future<String> install(File apk);

  /// Opens the system screen where the user allows installs from this app. The app goes to the
  /// background; [UpdateNotifier.resumed] carries on when it is back.
  Future<void> requestInstallPermission();

  /// Results the installer reports later: `pendingUserAction`, `success`, `cancelled` or
  /// `failed`, with a message.
  Stream<({String status, String? message})> get installEvents;
}

class AndroidUpdatePlatform implements UpdatePlatform {
  AndroidUpdatePlatform() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'installStatus') {
        final args = Map<String, Object?>.from(call.arguments as Map);
        _events.add((
          status: args['status'] as String,
          message: args['message'] as String?,
        ));
      }
    });
  }

  static const MethodChannel _channel = MethodChannel('epic_wallet/updater');
  final _events =
      StreamController<({String status, String? message})>.broadcast();

  @override
  Stream<({String status, String? message})> get installEvents =>
      _events.stream;

  @override
  Future<InstalledApp> installedApp() async {
    final info = Map<String, Object?>.from(
      await _channel.invokeMethod<Map<Object?, Object?>>('appInfo') ?? {},
    );
    return InstalledApp(
      packageName: info['packageName'] as String,
      versionCode: (info['versionCode'] as num).toInt(),
      versionName: info['versionName'] as String? ?? '',
      abis: List<String>.from(info['abis'] as List),
      canInstall: info['canInstall'] as bool? ?? true,
    );
  }

  @override
  Future<void> requestInstallPermission() =>
      _channel.invokeMethod<void>('requestInstallPermission');

  @override
  Future<String> install(File apk) async {
    final result = Map<String, Object?>.from(
      await _channel.invokeMethod<Map<Object?, Object?>>('install', {
            'path': apk.path,
          }) ??
          {},
    );
    final status = result['status'] as String? ?? 'failed';
    if (status == 'failed') {
      // The system's own message stays English, inside the translated sentence.
      final detail = result['message'];
      throw UpdateError(
        (l) => detail == null
            ? l.updateCannotInstallUnknown
            : l.updateCannotInstall('$detail'),
      );
    }
    return status;
  }
}

/// Whether Android's installer refused an update because it is signed with another key than
/// the installed app ([message] is the installer's own, in English).
bool isKeyMismatch(String? message) =>
    message != null && message.contains('INSTALL_FAILED_UPDATE_INCOMPATIBLE');

/// The download stopped part way (the connection dropped, or Android cut the app's network
/// when it went to the background). What arrived is kept beside the target as `.part`, and
/// the next [downloadApk] carries on from there.
class UpdateInterrupted extends UpdateError {
  UpdateInterrupted(super.text, {required this.received});

  /// Bytes kept in the `.part` file.
  final int received;
}

/// Downloads [apk] to [target], checking size and SHA-256. Reports progress from 0 to 1.
///
/// What arrived before an interruption stays in `<target>.part`, and the next call asks only
/// for the rest (an HTTP Range request), so leaving the app mid-download never costs what was
/// already downloaded. A server that ignores the range sends the whole file again. A finished
/// file that does not match the manifest is dropped and downloaded once more from the start.
Future<void> downloadApk(
  HttpClient client,
  ReleaseApk apk,
  File target, {
  void Function(double progress)? onProgress,
}) async {
  final partial = File('${target.path}.part');
  var kept = await partial.exists() ? await partial.length() : 0;
  if (kept > apk.size) {
    logInfo('update', 'the kept part is larger than announced; downloading from the start');
    await partial.delete();
    kept = 0;
  }
  if (kept == apk.size) {
    // All of it arrived before the stop: nothing left to ask for.
    if (await apkMatches(partial, apk)) {
      logInfo('update', 'the kept part is the whole file and verified');
      await partial.rename(target.path);
      return;
    }
    await partial.delete();
    kept = 0;
  }
  try {
    await _fetchInto(client, apk, partial, kept, onProgress);
  } on UpdateError catch (e) {
    // A file pieced together from two downloads that does not match: once more from the start.
    if (kept == 0 || !identical(e, _damaged)) rethrow;
    logInfo('update', 'the continued download does not match the manifest; downloading from the start');
    await _fetchInto(client, apk, partial, 0, onProgress);
  }
  await partial.rename(target.path);
}

final _damaged = UpdateError((l) => l.updateDownloadDamaged);

/// Fetches [apk] into [partial], keeping its first [kept] bytes when the server sends the rest.
/// An interruption leaves [partial] for the next try ([UpdateInterrupted]); a file that is too
/// large or does not match the manifest is deleted.
Future<void> _fetchInto(
  HttpClient client,
  ReleaseApk apk,
  File partial,
  int kept,
  void Function(double progress)? onProgress,
) async {
  final digestSink = _DigestSink();
  final hasher = sha256.startChunkedConversion(digestSink);
  var received = 0;
  try {
    final request = await client.getUrl(apk.url);
    if (kept > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$kept-');
    final response = await request.close();
    final code = response.statusCode;
    final resumes =
        kept > 0 && code == HttpStatus.partialContent && _rangeStarts(response, kept, apk.size);
    if (code != HttpStatus.ok && !resumes) {
      await response.drain<void>();
      // A range the server cannot serve: the kept part is no use.
      if (code == HttpStatus.requestedRangeNotSatisfiable) await _drop(partial);
      throw UpdateError((l) => l.updateDownloadHttpFailed(code));
    }
    if (resumes) {
      logInfo('update', 'download continues at $kept of ${apk.size} bytes');
      await for (final chunk in partial.openRead()) {
        hasher.add(chunk);
      }
      received = kept;
      onProgress?.call(received / apk.size);
    } else if (kept > 0) {
      logInfo('update', 'the server sent the whole file, not the rest; downloading from the start');
    } else {
      logInfo('update', 'download starts: ${apk.size} bytes, version code ${apk.versionCode}');
    }
    final out = partial.openWrite(mode: resumes ? FileMode.append : FileMode.write);
    try {
      await for (final chunk in response) {
        received += chunk.length;
        if (received > apk.size) break;
        hasher.add(chunk);
        out.add(chunk);
        onProgress?.call(received / apk.size);
      }
    } finally {
      await out.close();
    }
    hasher.close();
    if (received > apk.size) {
      await _drop(partial);
      throw UpdateError((l) => l.updateDownloadTooLarge);
    }
    if (received != apk.size) {
      throw HttpException('the file ended at $received of ${apk.size} bytes');
    }
    if (digestSink.value.toString() != apk.sha256) {
      await _drop(partial);
      throw _damaged;
    }
    logInfo('update', 'download complete and verified: sha256 ${apk.sha256.substring(0, 12)}');
  } on SocketException catch (e) {
    throw await _stopped(partial, apk, e, (l) => l.updateServerUnreachable);
  } on HttpException catch (e) {
    throw await _stopped(partial, apk, e, (l) => l.updateDownloadInterrupted);
  } on TlsException catch (e) {
    throw await _stopped(partial, apk, e, (l) => l.updateDownloadInterrupted);
  }
}

Future<void> _drop(File file) async {
  if (await file.exists()) await file.delete();
}

/// The download stopped on [error]: what [partial] holds stays for the next try.
Future<UpdateError> _stopped(
  File partial,
  ReleaseApk apk,
  Object error,
  String Function(AppLocalizations l) text,
) async {
  final kept = await partial.exists() ? await partial.length() : 0;
  logInfo('update', 'download stopped at $kept of ${apk.size} bytes, kept for the next try: $error');
  return kept > 0 ? UpdateInterrupted(text, received: kept) : UpdateError(text);
}

/// Whether a 206 answer starts at [kept] of the [size]-byte file.
bool _rangeStarts(HttpClientResponse response, int kept, int size) {
  final range = response.headers.value(HttpHeaders.contentRangeHeader);
  final match = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(range ?? '');
  return match != null && int.parse(match[1]!) == kept && int.parse(match[3]!) == size;
}

/// Whether [file] is [apk]: present, the announced size, the announced SHA-256. A download
/// kept from before the permission trip is installed without downloading it again.
Future<bool> apkMatches(File file, ReleaseApk apk) async {
  if (!await file.exists() || await file.length() != apk.size) return false;
  final digestSink = _DigestSink();
  final hasher = sha256.startChunkedConversion(digestSink);
  await for (final chunk in file.openRead()) {
    hasher.add(chunk);
  }
  hasher.close();
  return digestSink.value.toString() == apk.sha256;
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,

  /// Android's "allow installs from this source" screen is open, or was: the update waits for
  /// the user to allow and come back ([UpdateNotifier.resumed]).
  needsPermission,
  downloading,
  installing,
  failed,
}

class UpdateState {
  const UpdateState(this.phase, {this.update, this.progress, this.text});

  final UpdatePhase phase;
  final AvailableUpdate? update;
  final double? progress;

  /// A sentence that replaces the phase's usual line: why it failed, or what to do next.
  /// Worded on the screen, in the reader's language.
  final String Function(AppLocalizations l)? text;
}

/// Null where the app cannot update itself: off Android, and in the builds without in-app
/// updates ([inAppUpdates]), whose native side has no installer.
final updatePlatformProvider = Provider<UpdatePlatform?>((ref) {
  if (!inAppUpdates || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  return AndroidUpdatePlatform();
});

/// Where downloads go: an `updates` folder inside it, emptied before each download.
final updateTempDirProvider = Provider<Future<Directory> Function()>(
  (ref) => getTemporaryDirectory,
);

/// The first source; a test that puts a server of its own here reads only that one.
final updateManifestUrlProvider = Provider<Uri>(
  (ref) => updateManifestUrls.first,
);

/// Every source the check reads ([updateManifestSources]).
final updateManifestUrlsProvider = Provider<List<Uri>>((ref) {
  final first = ref.watch(updateManifestUrlProvider);
  return first == updateManifestUrls.first ? updateManifestUrls : [first];
});

/// The keys `update.json` must be signed with; tests use the test keyring.
final updateKeyringProvider = Provider<Keyring>((ref) => btlabsKeyring);

/// The clock the manifest's expiry is checked against.
final updateClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// How long a return to the app waits for Android's word on an install it started. Leaving
/// Android's install dialog for the home screen closes it without any word, so after this the
/// update is offered again.
final updateInstallGraceProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

/// Where an APK named by the verified manifest is downloaded from: the manifest's own https
/// URL. Tests point it at a local server.
final updateApkUrlProvider = Provider<Uri Function(Uri url)>(
  (ref) =>
      (url) => url,
);

/// Where update.json's verification state (FORMAT.md §5: serial, digest, revoked keys) is kept
/// between runs, so a restart does not take an older signed manifest again, nor trust a key a
/// manifest revoked. The phone keeps it in the secret store, the desktop in its desk store.
const String updateStateKey = 'app.update_state';

/// The version whose update notice the user closed: it is not offered again by itself.
const String updateNoticeDismissedKey = 'app.update_notice_dismissed';

/// The version code of the update that sent the user to Android's "allow installs from this
/// source" screen. Allowing it there can end the app's process (Android 8–11 do), so the
/// update carries on at the next opening that finds it, not only on [UpdateNotifier.resumed].
const String updatePermissionKey = 'app.update_after_permission';

/// The stored state from its decoded JSON; null when nothing is stored. A stored value that
/// does not read as a state is logged and counts as none: the next manifest that verifies
/// writes a good one.
ManifestState? storedUpdateState(Object? json) {
  if (json == null) return null;
  final state = ManifestState.fromJson(json);
  if (state == null) logWarn('update', 'stored update.json state is not valid; ignored');
  return state;
}

/// Of the stored state and one accepted before it could be read, the one with the higher
/// serial, keeping every key either revoked.
ManifestState? laterUpdateState(ManifestState? stored, ManifestState? seen) {
  if (stored == null || seen == null) return stored ?? seen;
  final later = seen.serial > stored.serial ? seen : stored;
  return ManifestState(
    serial: later.serial,
    keyid: later.keyid,
    digest: later.digest,
    revoked: Set.unmodifiable({...stored.revoked, ...seen.revoked}),
  );
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

class UpdateNotifier extends Notifier<UpdateState> {
  StreamSubscription<({String status, String? message})>? _events;

  /// Whether the app is off the screen ([paused] until [resumed]).
  bool _away = false;

  /// A download stopped while the app was away; [resumed] carries it on.
  bool _continueOnReturn = false;

  /// The last manifest accepted, also in an earlier run ([updateStateKey]); an older one is
  /// refused (FORMAT.md §6).
  ManifestState? _manifestState;

  /// Whether the stored state was read. Until it is, nothing is stored over it: a store that
  /// could not be read is asked again at the next check.
  bool _stateRead = false;

  /// The version whose notice was closed ([updateNoticeDismissedKey]), read with the state.
  String? _dismissed;
  bool _dismissedRead = false;

  /// Whether the user closed the notice offering [version].
  bool noticeDismissed(String version) => _dismissed == version;

  /// The user closed the notice offering [version]: it stays closed for that version, also
  /// after a restart, until a check from About.
  Future<void> dismissNotice(String version) async {
    _dismissed = version;
    try {
      await ref.read(secretStoreProvider).write(updateNoticeDismissedKey, version);
    } on Object catch (e) {
      logWarn('update', 'closed notice not stored: ${e.runtimeType}');
    }
  }

  Future<void> _readDismissed() async {
    if (_dismissedRead) return;
    try {
      _dismissed = await ref.read(secretStoreProvider).read(updateNoticeDismissedKey);
      _dismissedRead = true;
    } on Object catch (e) {
      logWarn('update', 'closed notice not read: ${e.runtimeType}');
    }
  }

  Future<void> _readState() async {
    if (_stateRead) return;
    try {
      final text = await ref.read(secretStoreProvider).read(updateStateKey);
      Object? json;
      if (text != null) {
        try {
          json = jsonDecode(text);
        } on FormatException {
          json = const <String, Object?>{};
        }
      }
      _manifestState = laterUpdateState(storedUpdateState(json), _manifestState);
      _stateRead = true;
    } on Object catch (e) {
      logWarn('update', 'stored update.json state not read: ${e.runtimeType}');
    }
  }

  /// Remembers [next], the state of a manifest that just verified, and stores it.
  Future<void> _keepState(ManifestState? next) async {
    if (next == null || next == _manifestState) return;
    _manifestState = next;
    if (!_stateRead) return;
    try {
      await ref.read(secretStoreProvider).write(updateStateKey, jsonEncode(next.toJson()));
    } on Object catch (e) {
      logWarn('update', 'update.json state not stored: ${e.runtimeType}');
    }
  }

  @override
  UpdateState build() {
    final platform = ref.watch(updatePlatformProvider);
    _events = platform?.installEvents.listen(_onInstallEvent);
    ref.onDispose(() => _events?.cancel());
    return const UpdateState(UpdatePhase.idle);
  }

  /// Never in the build without Tor ([inAppUpdates]): its store updates it.
  bool get supported => inAppUpdates && ref.read(updatePlatformProvider) != null;

  void _onInstallEvent(({String status, String? message}) event) {
    switch (event.status) {
      case 'failed' when isKeyMismatch(event.message):
        _needsReinstall(state.update);
      case 'failed':
        // The installer's own message stays English, inside the translated sentence.
        final detail = event.message ?? '';
        state = UpdateState(
          UpdatePhase.failed,
          update: state.update,
          text: (l) => l.updateNotInstalled(detail),
        );
      case 'cancelled':
        // The system dialog was closed without installing: say so, Update tries again.
        state = UpdateState(
          UpdatePhase.available,
          update: state.update,
          text: (l) => l.updateInstallCancelled,
        );
      default:
        // pendingUserAction: the system dialog is up. success: this process ends shortly.
        break;
    }
  }

  /// Checks each time the app is opened: at start, on each unlock, and on a resume that needs
  /// no unlock (`app/README.md` "In-app updates"). Never on a timer. Stays quiet on failure.
  Future<void> checkOnOpening() async {
    // Offline checks nothing (network_gate.dart).
    if (!supported || NetGate.offline) return;
    await check(quiet: true);
  }

  /// Fetches the manifest. With [quiet], "up to date" leaves the state idle and a failure
  /// keeps what the last check found: the update it offered, else idle. A failure that is not
  /// quiet reports itself and still keeps a known update.
  Future<void> check({bool quiet = false}) async {
    final platform = ref.read(updatePlatformProvider);
    // No update.json is asked in the build without Tor ([inAppUpdates]).
    if (platform == null || !inAppUpdates) return;
    // An update waiting for the install permission keeps its line ([resumed] carries it on).
    final busy = {
      UpdatePhase.checking,
      UpdatePhase.needsPermission,
      UpdatePhase.downloading,
      UpdatePhase.installing,
    };
    if (busy.contains(state.phase)) return;
    // A known update stays offered (the Settings row and dot) while the check runs.
    final known = state.update;
    state = UpdateState(UpdatePhase.checking, update: known);
    // An install that started meanwhile (the resume's download beside this check) owns the
    // state from then on: its failure stays shown.
    void settle(UpdateState next) {
      if (state.phase == UpdatePhase.checking) state = next;
    }

    final urls = ref.read(updateManifestUrlsProvider);
    try {
      await _readState();
      await _readDismissed();
      // Asked for (About's Check for updates): a closed notice shows again.
      if (!quiet && _dismissed != null) {
        _dismissed = null;
        await ref.read(secretStoreProvider).delete(updateNoticeDismissedKey);
      }
      final app = await platform.installedApp();
      // No manifest published at the feed, or one that does not verify: nothing is known
      // about a newer version, which is no error. A known update stays offered.
      void noInformation() {
        settle(
          known != null
              ? UpdateState(UpdatePhase.available, update: known)
              : quiet
              ? const UpdateState(UpdatePhase.idle)
              : UpdateState(
                  UpdatePhase.upToDate,
                  text: (l) => l.updateNoInformation,
                ),
        );
      }

      // Every source ([updateManifestSources]), read and checked alike: the valid copy with the
      // highest serial is used, the first source on a tie. With none, a source that has no
      // manifest or a bad one means nothing newer is known; only every source failing is an
      // error (the first one's).
      Future<(UpdateManifestRead?, Object?)> readOne(Uri url) async {
        // A plain GET: no User-Agent, no cookies, nothing about this wallet.
        final HttpReply response;
        try {
          response = await httpGet(
            url,
            timeout: const Duration(seconds: 30),
            maxBytes: btlabsMaxEnvelopeBytes,
          );
        } on NetTooLarge {
          logInfo('update', 'update.json not used: ${RejectReason.tooLarge.code} ($url)');
          return (null, null);
        } catch (error) {
          logInfo('update', 'update.json not reached at $url: $error');
          return (null, error);
        }
        if (response.status == HttpStatus.notFound) return (null, null);
        if (response.status != HttpStatus.ok) {
          final code = response.status;
          logInfo('update', 'update.json at $url: HTTP $code');
          return (null, UpdateError((l) => l.updateServerHttpStatus(code)));
        }
        final candidate = await readUpdateManifest(
          response.body,
          app,
          keyring: ref.read(updateKeyringProvider),
          now: ref.read(updateClockProvider)(),
          state: _manifestState,
        );
        if (candidate.rejected case final reason?) {
          // Never shown as an error: the user cannot act on it (FORMAT.md §5).
          logInfo('update', 'update.json not used: ${reason.code} ($url)');
          return (null, null);
        }
        return (candidate, null);
      }

      final results = await Future.wait([for (final url in urls) readOne(url)]);
      if (!ref.mounted) return;
      UpdateManifestRead? read;
      for (final (candidate, _) in results) {
        if (candidate == null) continue;
        if (read == null || candidate.state!.serial > read.state!.serial) read = candidate;
      }
      if (read == null) {
        if (results.every((r) => r.$2 != null)) throw results.first.$2!;
        noInformation();
        return;
      }
      await _keepState(read.state);
      if (!ref.mounted) return;
      final apkUrl = ref.read(updateApkUrlProvider);
      final picked = read.update;
      final update = picked == null
          ? null
          : AvailableUpdate(
              versionName: picked.versionName,
              notes: picked.notes,
              apk: ReleaseApk(
                abi: picked.apk.abi,
                versionCode: picked.apk.versionCode,
                url: apkUrl(picked.apk.url),
                sha256: picked.apk.sha256,
                size: picked.apk.size,
              ),
            );
      settle(
        update == null
            ? UpdateState(quiet ? UpdatePhase.idle : UpdatePhase.upToDate)
            : UpdateState(UpdatePhase.available, update: update),
      );
      // The permission screen ended the app before it could carry on: now it can.
      final asked = await _permissionAsked();
      if (asked == null || !ref.mounted) return;
      if (update == null || asked != update.apk.versionCode) {
        await _notePermissionAsked(null);
      } else if (app.canInstall && state.phase == UpdatePhase.available) {
        logInfo('update', 'install allowed while the app was closed; carrying on');
        await _downloadAndInstall(platform, update);
      }
    } catch (error) {
      logInfo('update', 'check failed: $error');
      if (!ref.mounted) return;
      settle(
        quiet
          ? known == null
                ? const UpdateState(UpdatePhase.idle)
                : UpdateState(UpdatePhase.available, update: known)
          // Settings keeps its row and dot; Try again then installs the known update.
          : UpdateState(
              UpdatePhase.failed,
              update: known,
              text: _describe(error),
            ),
      );
    }
  }

  /// Installs the available update: first the permission to install, asked before any
  /// download (Android 8+), then the download, unless the file from a previous try is still
  /// there and matches the manifest, then Android's installer.
  Future<void> install() async {
    final platform = ref.read(updatePlatformProvider);
    final update = state.update;
    if (platform == null || update == null) return;
    if (state.phase == UpdatePhase.downloading ||
        state.phase == UpdatePhase.installing) {
      return;
    }
    try {
      if (!(await platform.installedApp()).canInstall) {
        await platform.requestInstallPermission();
        if (ref.mounted) _waitForPermission(update);
        return;
      }
    } catch (error) {
      logWarn('update', 'install permission unknown: $error');
      // Asked again by the installer itself, which opens the screen.
    }
    await _downloadAndInstall(platform, update);
  }

  /// The app left the screen ([resumed] is its return).
  void paused() => _away = true;

  /// The app is back in front. A download that stopped while it was away carries on from what
  /// arrived. Once the install permission was given, the update that waited for it carries on:
  /// from the kept download, or a new one if that file is gone.
  Future<void> resumed() async {
    _away = false;
    if (_continueOnReturn) {
      _continueOnReturn = false;
      final platform = ref.read(updatePlatformProvider);
      final update = state.update;
      if (platform != null && update != null && state.phase == UpdatePhase.available) {
        logInfo('update', 'back in the app: the download carries on');
        // Before any await, so the check on return finds it busy.
        return _downloadAndInstall(platform, update);
      }
    }
    if (state.phase == UpdatePhase.installing) return _awaitInstallWord(state);
    if (state.phase != UpdatePhase.needsPermission) return;
    final platform = ref.read(updatePlatformProvider);
    final update = state.update;
    if (platform == null || update == null) return;
    try {
      if (!(await platform.installedApp()).canInstall) return;
    } catch (error) {
      logWarn('update', 'install permission unknown: $error');
      return;
    }
    if (ref.mounted) await _downloadAndInstall(platform, update);
  }

  /// Back in the app while Android's installer has said nothing: an install the user confirmed
  /// ends this process soon; one whose dialog was closed (the home screen) never says so.
  Future<void> _awaitInstallWord(UpdateState installing) async {
    await Future<void>.delayed(ref.read(updateInstallGraceProvider));
    if (!ref.mounted || !identical(state, installing)) return;
    logInfo('update', 'no word from the installer; offering the update again');
    state = UpdateState(
      UpdatePhase.available,
      update: installing.update,
      text: (l) => l.updateInstallCancelled,
    );
  }

  void _waitForPermission(AvailableUpdate update) {
    state = UpdateState(
      UpdatePhase.needsPermission,
      update: update,
      text: (l) => l.updateAllowInstalls,
    );
    unawaited(_notePermissionAsked(update.apk.versionCode));
  }

  Future<int?> _permissionAsked() async {
    try {
      return int.tryParse(await ref.read(secretStoreProvider).read(updatePermissionKey) ?? '');
    } on Object catch (e) {
      logWarn('update', 'permission note not read: ${e.runtimeType}');
      return null;
    }
  }

  /// Notes [versionCode] as waiting for the permission; null forgets it.
  Future<void> _notePermissionAsked(int? versionCode) async {
    try {
      final store = ref.read(secretStoreProvider);
      if (versionCode == null) {
        await store.delete(updatePermissionKey);
      } else {
        await store.write(updatePermissionKey, '$versionCode');
      }
    } on Object catch (e) {
      logWarn('update', 'permission note not stored: ${e.runtimeType}');
    }
  }

  Future<void> _downloadAndInstall(
    UpdatePlatform platform,
    AvailableUpdate update,
  ) async {
    state = UpdateState(UpdatePhase.downloading, update: update, progress: 0);
    unawaited(_notePermissionAsked(null));
    // With Tor on and not connected yet, held until it is: never direct meanwhile.
    await TorNet.untilConnected();
    // No User-Agent: the download says nothing about this app either. Over Tor the first
    // connection to an onion can take longer than a direct one.
    final client = HttpClient()
      ..connectionTimeout = TorNet.mode == TorNetMode.tor
          ? const Duration(seconds: 90)
          : const Duration(seconds: 15)
      ..userAgent = null;
    try {
      // Through tor while the Tor switch covers the app's requests: BT Labs' servers at their
      // onions (the signed list, then the built-in table), the rest through an exit.
      TorNet.configure(client);
      final dir = Directory(
        '${(await ref.read(updateTempDirProvider)()).path}${Platform.pathSeparator}updates',
      );
      // Named by version and hash, so a part kept from another build is never continued.
      final apk = File(
        '${dir.path}${Platform.pathSeparator}'
        'epic_wallet-${update.apk.versionCode}-${update.apk.sha256.substring(0, 12)}.apk',
      );
      await dir.create(recursive: true);
      // Older downloads go; this one's file and its part stay.
      await for (final entry in dir.list()) {
        if (entry.path != apk.path && entry.path != '${apk.path}.part') {
          await entry.delete(recursive: true);
        }
      }
      // The verified file from an earlier try installs as it is, checked against the signed
      // manifest again.
      if (await apkMatches(apk, update.apk)) {
        logInfo('update', 'installing the verified download kept from before');
      } else {
        if (await apk.exists()) {
          logInfo('update', 'the kept download does not match the manifest; downloading it again');
          await apk.delete();
        }
        await downloadApk(
          client,
          update.apk,
          apk,
          onProgress: (p) {
            if (ref.mounted) {
              state = UpdateState(
                UpdatePhase.downloading,
                update: update,
                progress: p,
              );
            }
          },
        );
      }
      if (!ref.mounted) return;
      // "Installing version X…" while Android's installer opens; it fails plainly if not.
      state = UpdateState(UpdatePhase.installing, update: update);
      final status = await platform.install(apk);
      logInfo('update', 'handed to Android\'s installer: $status');
      if (!ref.mounted) return;
      if (status == 'keyMismatch') {
        _needsReinstall(update);
      } else if (status == 'needsPermission') {
        // The installer opened the screen; the file stays for the return.
        _waitForPermission(update);
      }
    } catch (error) {
      if (_away && ref.mounted && _carriesOn(error)) {
        // Android cuts a background app's network a few seconds after it leaves the screen
        // (15+): what arrived is kept, and the download carries on at the return ([resumed]).
        logInfo('update', 'the download stopped while the app was in the background; it carries on at the return');
        _continueOnReturn = true;
        state = UpdateState(UpdatePhase.available, update: update, text: _describe(error));
        return;
      }
      logWarn('update', 'install failed: $error');
      if (ref.mounted) {
        state = UpdateState(
          UpdatePhase.failed,
          update: update,
          text: _describe(error),
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  /// The update is signed with another key than this app. Android refuses to install it over
  /// this one, so the only way to it is a reinstall, which removes this wallet from the device.
  void _needsReinstall(AvailableUpdate? update) {
    logWarn(
      'update',
      'the update is signed with another key; a reinstall is needed',
    );
    state = UpdateState(
      UpdatePhase.failed,
      update: update,
      text: (l) => l.updateNeedsReinstall,
    );
  }

  /// Whether [error] is the network going away, which a return to the app can carry on from.
  static bool _carriesOn(Object error) =>
      error is UpdateInterrupted ||
      error is SocketException ||
      (error is SocksError && error.message != SocksError.noBtLabsOnion) ||
      error is NetError ||
      error is TimeoutException ||
      error is HttpException ||
      (error is UpdateError && error.message == englishStrings.updateServerUnreachable);

  static String Function(AppLocalizations l) _describe(Object error) =>
      switch (error) {
        UpdateError(:final text) => text,
        // The APK's host is a BT Labs server without an onion: it cannot be fetched over Tor.
        SocksError(:final message) when message == SocksError.noBtLabsOnion =>
          (l) => l.updateNoTorDownload,
        SocketException() || NetError() => (l) => l.updateServerUnreachable,
        TimeoutException() => (l) => l.updateServerTimeout,
        HttpException() => (l) => l.updateConnectionFailed,
        _ => (l) => l.updateCheckFailed,
      };
}
