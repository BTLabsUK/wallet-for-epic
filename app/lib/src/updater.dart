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
import 'net/http.dart';
import 'net/socks.dart' show SocksError;
import 'providers.dart' show secretStoreProvider;

/// Where releases publish the signed `update.json`. Override with
/// `--dart-define=WFE_UPDATE_URL=...`; an override must still be signed with the bundled keys.
const String updateManifestUrl = String.fromEnvironment(
  'WFE_UPDATE_URL',
  defaultValue: 'https://btlabs-epic.github.io/update.json',
);

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

/// Downloads [apk] to [target], checking size and SHA-256. Reports progress from 0 to 1.
Future<void> downloadApk(
  HttpClient client,
  ReleaseApk apk,
  File target, {
  void Function(double progress)? onProgress,
}) async {
  final partial = File('${target.path}.part');
  try {
    final request = await client.getUrl(apk.url);
    final response = await request.close();
    final code = response.statusCode;
    if (code != HttpStatus.ok) {
      await response.drain<void>();
      throw UpdateError((l) => l.updateDownloadHttpFailed(code));
    }
    final digestSink = _DigestSink();
    final hasher = sha256.startChunkedConversion(digestSink);
    final out = partial.openWrite();
    var received = 0;
    try {
      await for (final chunk in response) {
        received += chunk.length;
        if (received > apk.size) {
          throw UpdateError((l) => l.updateDownloadTooLarge);
        }
        hasher.add(chunk);
        out.add(chunk);
        onProgress?.call(received / apk.size);
      }
    } finally {
      await out.close();
    }
    hasher.close();
    if (received != apk.size) {
      throw UpdateError((l) => l.updateDownloadIncomplete);
    }
    if (digestSink.value.toString() != apk.sha256) {
      throw UpdateError((l) => l.updateDownloadDamaged);
    }
    await partial.rename(target.path);
  } on SocketException {
    throw UpdateError((l) => l.updateServerUnreachable);
  } on HttpException {
    throw UpdateError((l) => l.updateDownloadInterrupted);
  } finally {
    if (await partial.exists()) await partial.delete();
  }
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

final updatePlatformProvider = Provider<UpdatePlatform?>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  return AndroidUpdatePlatform();
});

/// Where downloads go: an `updates` folder inside it, emptied before each download.
final updateTempDirProvider = Provider<Future<Directory> Function()>(
  (ref) => getTemporaryDirectory,
);

final updateManifestUrlProvider = Provider<Uri>(
  (ref) => Uri.parse(updateManifestUrl),
);

/// The keys `update.json` must be signed with; tests use the test keyring.
final updateKeyringProvider = Provider<Keyring>((ref) => btlabsKeyring);

/// The clock the manifest's expiry is checked against.
final updateClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
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

  /// The last manifest accepted, also in an earlier run ([updateStateKey]); an older one is
  /// refused (FORMAT.md §6).
  ManifestState? _manifestState;

  /// Whether the stored state was read. Until it is, nothing is stored over it: a store that
  /// could not be read is asked again at the next check.
  bool _stateRead = false;

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

  bool get supported => ref.read(updatePlatformProvider) != null;

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
        state = UpdateState(UpdatePhase.available, update: state.update);
      default:
        // pendingUserAction: the system dialog is up. success: this process ends shortly.
        break;
    }
  }

  /// Checks each time the app is opened: at start, on each unlock, and on a resume that needs
  /// no unlock (`app/README.md` "In-app updates"). Never on a timer. Stays quiet on failure.
  Future<void> checkOnOpening() async {
    if (!supported) return;
    await check(quiet: true);
  }

  /// Fetches the manifest. With [quiet], "up to date" leaves the state idle and a failure
  /// keeps what the last check found: the update it offered, else idle. A failure that is not
  /// quiet reports itself and still keeps a known update.
  Future<void> check({bool quiet = false}) async {
    final platform = ref.read(updatePlatformProvider);
    if (platform == null) return;
    final busy = {
      UpdatePhase.checking,
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

    final url = ref.read(updateManifestUrlProvider);
    try {
      await _readState();
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

      // A plain GET: no User-Agent, no cookies, nothing about this wallet.
      final HttpReply response;
      try {
        response = await httpGet(
          url,
          timeout: const Duration(seconds: 30),
          maxBytes: btlabsMaxEnvelopeBytes,
        );
      } on NetTooLarge {
        logInfo(
          'update',
          'update.json not used: ${RejectReason.tooLarge.code}',
        );
        if (ref.mounted) noInformation();
        return;
      }
      if (response.status == HttpStatus.notFound) {
        if (ref.mounted) noInformation();
        return;
      }
      if (response.status != HttpStatus.ok) {
        final code = response.status;
        throw UpdateError((l) => l.updateServerHttpStatus(code));
      }
      final read = await readUpdateManifest(
        response.body,
        app,
        keyring: ref.read(updateKeyringProvider),
        now: ref.read(updateClockProvider)(),
        state: _manifestState,
      );
      if (!ref.mounted) return;
      if (read.rejected case final reason?) {
        // Never shown as an error: the user cannot act on it (FORMAT.md §5).
        logInfo('update', 'update.json not used: ${reason.code}');
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

  /// The app is back in front. Once the install permission was given, the update that waited
  /// for it carries on: from the kept download, or a new one if that file is gone.
  Future<void> resumed() async {
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

  void _waitForPermission(AvailableUpdate update) {
    state = UpdateState(
      UpdatePhase.needsPermission,
      update: update,
      text: (l) => l.updateAllowInstalls,
    );
  }

  Future<void> _downloadAndInstall(
    UpdatePlatform platform,
    AvailableUpdate update,
  ) async {
    state = UpdateState(UpdatePhase.downloading, update: update, progress: 0);
    // No User-Agent: the download says nothing about this app either.
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..userAgent = null;
    try {
      // Through tor while the Tor switch covers the app's requests.
      TorNet.configure(client);
      final dir = Directory(
        '${(await ref.read(updateTempDirProvider)()).path}${Platform.pathSeparator}updates',
      );
      final apk = File(
        '${dir.path}${Platform.pathSeparator}epic_wallet-${update.apk.versionCode}.apk',
      );
      // The file from before the permission trip, checked against the signed manifest again,
      // is installed as it is; anything else there goes.
      if (await apkMatches(apk, update.apk)) {
        logInfo('update', 'installing the download kept from before');
      } else {
        if (await dir.exists()) await dir.delete(recursive: true);
        await dir.create(recursive: true);
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
      state = UpdateState(UpdatePhase.installing, update: update);
      final status = await platform.install(apk);
      if (!ref.mounted) return;
      if (status == 'keyMismatch') {
        _needsReinstall(update);
      } else if (status == 'needsPermission') {
        // The installer opened the screen; the file stays for the return.
        _waitForPermission(update);
      }
    } catch (error) {
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

  static String Function(AppLocalizations l) _describe(Object error) =>
      switch (error) {
        UpdateError(:final text) => text,
        // The APK's host has no onion, so it cannot be fetched over Tor (android-16).
        SocksError(:final message) when message == SocksError.noBtLabsOnion =>
          (l) => l.updateNoTorDownload,
        SocketException() || NetError() => (l) => l.updateServerUnreachable,
        TimeoutException() => (l) => l.updateServerTimeout,
        HttpException() => (l) => l.updateConnectionFailed,
        _ => (l) => l.updateCheckFailed,
      };
}
