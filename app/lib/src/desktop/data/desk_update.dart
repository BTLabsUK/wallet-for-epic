/// Settings › About › Updates: whether a newer Epic Wallet is out. Check only: the desktop
/// never downloads or installs. Reads the manifest the phone's updater reads
/// ([updateManifestUrl], one constant for both), but only its `desktop` entry: the phone's
/// `versionName` is the Android build's. The entry is `{"version": "0.1.1", "page": "…"}`, or
/// per system `{"windows": {…}, "linux": {…}}`; a manifest without it offers nothing.
/// The page opens only on [deskUpdatePageHosts]; any other falls back to [deskReleasesUrl].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_log.dart';
import '../../updater.dart' show updateManifestUrl;

/// This build's version, without the build id (pubspec's version); the sidebar, About and
/// the support report show it with the build id (`shell.dart`).
const String deskAppVersion = '0.1.0';

/// Where a download page may be: the project's own GitHub accounts.
const List<String> deskUpdatePageHosts = ['https://github.com/BTLabs-EPIC/', 'https://github.com/blacktyger/'];

/// Where an update is downloaded, when the manifest names no page of its own.
const String deskReleasesUrl = 'https://github.com/blacktyger/wallet-for-epic/releases/latest';

enum DeskUpdatePhase { idle, checking, latest, available, failed }

class DeskUpdateState {
  const DeskUpdateState(this.phase, {this.version, this.page, this.reason, this.checkedAt});

  final DeskUpdatePhase phase;

  /// The newer version, when [DeskUpdatePhase.available].
  final String? version;

  /// Its download page.
  final String? page;

  /// Why the check failed, short.
  final String? reason;

  /// When the last check ended; null before one did.
  final DateTime? checkedAt;
}

/// The manifest's HTTP status and body; tests replace it.
typedef ManifestFetch = Future<(int, String)> Function(Uri url);

Future<(int, String)> _fetch(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final response = await (await client.getUrl(url)).close().timeout(const Duration(seconds: 30));
    final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 30));
    return (response.statusCode, body);
  } finally {
    client.close(force: true);
  }
}

final deskManifestFetchProvider = Provider<ManifestFetch>((ref) => _fetch);
final deskUpdateClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Whether dotted version [a] is newer than [b] (`0.1.10` > `0.1.9`); a build suffix
/// (`+3`, ` (abc)`) is ignored.
bool isNewerVersion(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.split(RegExp(r'[+ ]')).first.split('.')) int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
  ];
  final x = parts(a), y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d > 0;
  }
  return false;
}

/// Whether [url] is an https page on one of [deskUpdatePageHosts].
bool isDeskUpdatePage(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.scheme != 'https' || u.userInfo.isNotEmpty || u.hasPort) return false;
  final normal = 'https://${u.host.toLowerCase()}${u.path}';
  return deskUpdatePageHosts.any((h) => normal.toLowerCase().startsWith(h.toLowerCase()));
}

class DeskUpdateController extends Notifier<DeskUpdateState> {
  @override
  DeskUpdateState build() => const DeskUpdateState(DeskUpdatePhase.idle);

  /// Checks once per run, when About first opens.
  Future<void> checkOnce() async {
    if (state.phase == DeskUpdatePhase.idle) await check();
  }

  Future<void> check() async {
    if (state.phase == DeskUpdatePhase.checking) return;
    final last = state.checkedAt;
    state = DeskUpdateState(DeskUpdatePhase.checking, checkedAt: last);
    final url = Uri.parse(updateManifestUrl);
    DeskUpdateState next;
    try {
      final (status, body) = await ref.read(deskManifestFetchProvider)(url);
      next = _read(status, body);
    } on TimeoutException {
      next = const DeskUpdateState(DeskUpdatePhase.failed, reason: 'The update server did not answer.');
    } on Object catch (e) {
      logInfo('update', 'desktop check failed: ${e.runtimeType}');
      next = const DeskUpdateState(DeskUpdatePhase.failed, reason: 'The update server could not be reached.');
    }
    if (!ref.mounted) return;
    final now = ref.read(deskUpdateClockProvider)();
    state = DeskUpdateState(next.phase, version: next.version, page: next.page, reason: next.reason, checkedAt: now);
  }

  DeskUpdateState _read(int status, String body) {
    if (status == HttpStatus.notFound) {
      return const DeskUpdateState(DeskUpdatePhase.failed, reason: 'No update information is published yet.');
    }
    if (status != HttpStatus.ok) return DeskUpdateState(DeskUpdatePhase.failed, reason: 'The update server answered $status.');
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return const DeskUpdateState(DeskUpdatePhase.failed, reason: 'The update information is not readable.');
    }
    final desktop = json is Map<String, Object?> ? json['desktop'] : null;
    final mine = desktop is Map<String, Object?> && desktop[_system] is Map<String, Object?> ? desktop[_system] : desktop;
    if (mine is! Map<String, Object?>) {
      return const DeskUpdateState(DeskUpdatePhase.failed, reason: 'No desktop update information is published yet.');
    }
    final version = mine['version'];
    if (version is! String || version.isEmpty) {
      return const DeskUpdateState(DeskUpdatePhase.failed, reason: 'The update information has no version.');
    }
    if (!isNewerVersion(version, deskAppVersion)) return const DeskUpdateState(DeskUpdatePhase.latest);
    final page = mine['page'];
    return DeskUpdateState(DeskUpdatePhase.available, version: version, page: page is String && isDeskUpdatePage(page) ? page : deskReleasesUrl);
  }

  static String get _system => Platform.isWindows ? 'windows' : Platform.isMacOS ? 'macos' : 'linux';
}

final deskUpdateProvider = NotifierProvider<DeskUpdateController, DeskUpdateState>(DeskUpdateController.new);
