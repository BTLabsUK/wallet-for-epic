/// In-app updates for Android builds distributed outside an app store.
///
/// A release publishes `update.json` (written by `tool/release_android.sh`) next to its split
/// APKs. The app fetches it, picks the APK for this device's ABI, downloads it, checks its size
/// and SHA-256, and hands it to Android's PackageInstaller (`AppUpdater.kt`), which also insists
/// on the same package name, a higher version code and the same signing key.
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
import 'l10n.dart';

/// Where releases publish `update.json`. Override with `--dart-define=WFE_UPDATE_URL=...`.
const String updateManifestUrl = String.fromEnvironment(
  'WFE_UPDATE_URL',
  defaultValue: 'https://github.com/blacktyger/wallet-for-epic/releases/latest/download/update.json',
);

/// The installed app, as Android reports it.
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.versionCode,
    required this.versionName,
    required this.abis,
  });

  final String packageName;
  final int versionCode;
  final String versionName;

  /// Supported ABIs, most preferred first.
  final List<String> abis;
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

/// Picks the update for [app] from manifest [json], or null when it is up to date.
///
/// [manifestUrl] resolves relative APK URLs. APKs must be https unless the manifest itself was
/// served over http, which only a developer override does.
AvailableUpdate? parseUpdateManifest(
  String json,
  InstalledApp app,
  Uri manifestUrl,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    throw UpdateError((l) => l.updateManifestNotJson);
  }
  if (decoded is! Map<String, Object?>) {
    throw UpdateError((l) => l.updateManifestWrongShape);
  }
  if (decoded['packageName'] != app.packageName) {
    throw UpdateError((l) => l.updateManifestOtherApp);
  }
  final apks = decoded['apks'];
  if (apks is! List) {
    throw UpdateError((l) => l.updateManifestNoApks);
  }
  final byAbi = <String, ReleaseApk>{};
  for (final entry in apks) {
    if (entry is! Map<String, Object?>) continue;
    final abi = entry['abi'];
    final code = entry['versionCode'];
    final url = entry['url'];
    final hash = entry['sha256'];
    final size = entry['size'];
    if (abi is! String ||
        code is! int ||
        url is! String ||
        hash is! String ||
        size is! int ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      continue;
    }
    final resolved = manifestUrl.resolve(url);
    final secure =
        resolved.scheme == 'https' ||
        (resolved.scheme == 'http' && manifestUrl.scheme == 'http');
    if (!secure) continue;
    byAbi[abi] = ReleaseApk(
      abi: abi,
      versionCode: code,
      url: resolved,
      sha256: hash,
      size: size,
    );
  }
  ReleaseApk? chosen;
  for (final abi in [...app.abis, 'universal']) {
    chosen = byAbi[abi];
    if (chosen != null) break;
  }
  if (chosen == null || chosen.versionCode <= app.versionCode) return null;
  final name = decoded['versionName'];
  final notes = decoded['notes'];
  return AvailableUpdate(
    versionName: name is String ? name : '${chosen.versionCode}',
    notes: notes is String ? notes : '',
    apk: chosen,
  );
}

/// Platform side: app info and the installer. Null on platforms without in-app updates.
abstract interface class UpdatePlatform {
  Future<InstalledApp> installedApp();

  /// Installs [apk]. Returns `started`, `needsPermission`, or throws [UpdateError].
  Future<String> install(File apk);

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
    );
  }

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

final updateManifestUrlProvider = Provider<Uri>(
  (ref) => Uri.parse(updateManifestUrl),
);

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);

class UpdateNotifier extends Notifier<UpdateState> {
  StreamSubscription<({String status, String? message})>? _events;
  bool _checkedOnce = false;

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

  /// Checks once per app start; later calls do nothing. Stays quiet on failure.
  Future<void> checkOnStart() async {
    if (_checkedOnce || !supported) return;
    _checkedOnce = true;
    await check(quiet: true);
  }

  /// Fetches the manifest. With [quiet], failures and "up to date" leave the state idle.
  Future<void> check({bool quiet = false}) async {
    final platform = ref.read(updatePlatformProvider);
    if (platform == null) return;
    final busy = {
      UpdatePhase.checking,
      UpdatePhase.downloading,
      UpdatePhase.installing,
    };
    if (busy.contains(state.phase)) return;
    state = const UpdateState(UpdatePhase.checking);
    final url = ref.read(updateManifestUrlProvider);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final app = await platform.installedApp();
      final request = await client.getUrl(url);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        final code = response.statusCode;
        throw UpdateError((l) => l.updateServerHttpStatus(code));
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
      final update = parseUpdateManifest(body, app, url);
      if (!ref.mounted) return;
      state = update == null
          ? UpdateState(quiet ? UpdatePhase.idle : UpdatePhase.upToDate)
          : UpdateState(UpdatePhase.available, update: update);
    } catch (error) {
      logInfo('update', 'check failed: $error');
      if (!ref.mounted) return;
      state = quiet
          ? const UpdateState(UpdatePhase.idle)
          : UpdateState(UpdatePhase.failed, text: _describe(error));
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads and installs the available update.
  Future<void> install() async {
    final platform = ref.read(updatePlatformProvider);
    final update = state.update;
    if (platform == null || update == null) return;
    state = UpdateState(UpdatePhase.downloading, update: update, progress: 0);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final dir = Directory(
        '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}updates',
      );
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);
      final apk = File(
        '${dir.path}${Platform.pathSeparator}epic_wallet-${update.apk.versionCode}.apk',
      );
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
      if (!ref.mounted) return;
      state = UpdateState(UpdatePhase.installing, update: update);
      final status = await platform.install(apk);
      if (!ref.mounted) return;
      if (status == 'needsPermission') {
        state = UpdateState(
          UpdatePhase.available,
          update: update,
          text: (l) => l.updateNeedsPermission,
        );
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

  static String Function(AppLocalizations l) _describe(Object error) =>
      switch (error) {
        UpdateError(:final text) => text,
        SocketException() => (l) => l.updateServerUnreachable,
        TimeoutException() => (l) => l.updateServerTimeout,
        HttpException() => (l) => l.updateConnectionFailed,
        _ => (l) => l.updateCheckFailed,
      };
}
