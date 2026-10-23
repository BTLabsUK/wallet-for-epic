/// Settings › About › Updates: whether a newer Epic Wallet is out. Check only: the desktop
/// never downloads or installs. Reads the signed manifest the phone's updater reads
/// ([updateManifestUrl], one constant for both), verified with the same bundled keys
/// ([updateKeyringProvider]) before anything is read from it, and only its `desktop` entry:
/// the phone's `versionName` is the Android build's. The entry is
/// `{"version": "0.1.1", "page": "…"}`, or per system `{"windows": {…}, "linux": {…}}`; a
/// manifest without it offers nothing, and one that does not verify means no information.
/// The page opens only on [deskUpdatePageHosts]; any other falls back to [deskReleasesUrl].
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_log.dart';
import '../../btlabs_public.dart';
import '../../net/http.dart';
import '../../updater.dart' show updateKeyringProvider, updateManifestUrl;

/// This build's version, without the build id (pubspec's version); the sidebar, About and
/// the support report show it with the build id (`shell.dart`).
const String deskAppVersion = '0.1.1';

/// Where a download page may be: the project's own GitHub accounts.
const List<String> deskUpdatePageHosts = ['https://github.com/BTLabs-EPIC/', 'https://github.com/blacktyger/'];

/// Where an update is downloaded, when the manifest names no page of its own.
const String deskReleasesUrl = 'https://github.com/BTLabs-EPIC/wallet-for-epic/releases/latest';

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

/// A plain GET ([httpGet]): no User-Agent, no cookies, nothing about this wallet. A body
/// over the envelope limit is not read; it answers as [deskManifestTooLarge], which
/// [DeskUpdateController] treats as a manifest that does not verify.
Future<(int, String)> _fetch(Uri url) async {
  try {
    final reply = await httpGet(url, timeout: const Duration(seconds: 30), maxBytes: btlabsMaxEnvelopeBytes);
    return (reply.status, reply.body);
  } on NetTooLarge {
    return (deskManifestTooLarge, '');
  }
}

/// The status [ManifestFetch] reports for a body over the envelope limit (no HTTP status).
const int deskManifestTooLarge = -1;

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
      next = await _read(status, body);
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

  /// The last manifest accepted in this run; a later, older one is refused (FORMAT.md §6).
  ManifestState? _manifestState;

  /// The update the last accepted manifest offered, if any: it stays offered when a later
  /// manifest does not verify or none is published (FORMAT.md §5: keep what you have).
  DeskUpdateState? _known;

  Future<DeskUpdateState> _read(int status, String body) async {
    // No manifest published: nothing newer is known, which is no error.
    if (status == 404) return _known ?? const DeskUpdateState(DeskUpdatePhase.latest);
    if (status == deskManifestTooLarge) return _notVerified(RejectReason.tooLarge);
    if (status != 200) return DeskUpdateState(DeskUpdatePhase.failed, reason: 'The update server answered $status.');
    final result = await verifyWalletUpdate(
      body,
      keyring: ref.read(updateKeyringProvider),
      state: _manifestState,
      now: ref.read(deskUpdateClockProvider)().toUtc(),
    );
    if (result is! Accepted<WalletUpdate>) return _notVerified((result as Rejected<WalletUpdate>).reason);
    _manifestState = result.state;
    _known = null;
    final mine = result.manifest.desktop?.forSystem(_system);
    if (mine == null) {
      return const DeskUpdateState(DeskUpdatePhase.failed, reason: 'No desktop update information is published yet.');
    }
    if (!isNewerVersion(mine.version, deskAppVersion)) return const DeskUpdateState(DeskUpdatePhase.latest);
    final page = mine.page;
    return _known = DeskUpdateState(
      DeskUpdatePhase.available,
      version: mine.version,
      page: page != null && isDeskUpdatePage(page) ? page : deskReleasesUrl,
    );
  }

  /// A manifest that is unsigned, forged, expired or older than one seen in this run: no
  /// information, like no manifest at all; an update an earlier manifest offered stays
  /// offered. The reason goes to the log only (FORMAT.md §5).
  DeskUpdateState _notVerified(RejectReason reason) {
    logInfo('update', 'desktop: update.json not used: ${reason.code}');
    return _known ?? const DeskUpdateState(DeskUpdatePhase.latest);
  }

  static String get _system => kIsWeb ? 'linux' : Platform.isWindows ? 'windows' : Platform.isMacOS ? 'macos' : 'linux';
}

final deskUpdateProvider = NotifierProvider<DeskUpdateController, DeskUpdateState>(DeskUpdateController.new);
