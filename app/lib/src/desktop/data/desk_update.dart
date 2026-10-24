/// Whether a newer Epic Cash Desktop is out, and getting it: the sidebar's notice and Settings ›
/// About › Updates. Checked shortly after the wallet opens and every [deskUpdateEvery] while the
/// app runs ([DeskUpdateController.schedule]), and when About opens. Reads the signed manifest
/// the phone's updater reads
/// ([updateManifestUrl], one constant for both), verified with the same bundled keys
/// ([updateKeyringProvider]) before anything is read from it, and only its `desktop` entry:
/// the phone's `versionName` is the Android build's. The entry is
/// `{"version": "26.10.0", "page": "…"}`, or per system `{"windows": {…}, "linux": {…}}`; a
/// manifest without it offers nothing, and one that does not verify means no information.
/// The page opens only on [deskUpdatePageHosts]; any other falls back to [deskReleasesUrl].
///
/// When the entry also names this system's release file (`url`, `sha256`, `size`) and this copy
/// can install it by itself (`desk_update_apply.dart`), the notice downloads it, checks it, and
/// offers "Restart to update"; otherwise it opens the page.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_log.dart';
import '../../app_version.dart';
import '../desk_l10n.dart' show deskStrings;
import '../../btlabs_public.dart';
import '../../net/http.dart';
import '../../updater.dart' show laterUpdateState, storedUpdateState, updateKeyringProvider, updateManifestUrl, updateStateKey;
import 'desk_store.dart';
import 'desk_update_apply.dart';
import 'state.dart' show deskProvider, deskQuitProvider;

/// This build's version, without the build id ([appVersion], pubspec's version); the sidebar,
/// About and the support report show it with the build id (`shell.dart`).
const String deskAppVersion = appVersion;

/// Where a download page may be: BT Labs' public download page and the project's own GitHub
/// accounts.
const List<String> deskUpdatePageHosts = [
  'https://examples.btlabs.uk/epic-cash-wallets/',
  'https://github.com/BTLabs-EPIC/',
  'https://github.com/blacktyger/',
];

/// Where an update is downloaded, when the manifest names no page of its own: the public
/// download page (the GitHub repository is private and has no releases).
const String deskReleasesUrl = 'https://examples.btlabs.uk/epic-cash-wallets/';

enum DeskUpdatePhase {
  idle,
  checking,
  latest,
  available,
  failed,

  /// The release file is downloading ([DeskUpdateState.progress]).
  downloading,

  /// The release file is downloaded and checked: "Restart to update".
  ready,
}

class DeskUpdateState {
  const DeskUpdateState(
    this.phase, {
    this.version,
    this.page,
    this.reason,
    this.checkedAt,
    this.file,
    this.progress,
    this.problem,
    this.download,
  });

  final DeskUpdatePhase phase;

  /// The newer version, when [DeskUpdatePhase.available].
  final String? version;

  /// Its download page.
  final String? page;

  /// Why the check failed, short.
  final String? reason;

  /// When the last check ended; null before one did.
  final DateTime? checkedAt;

  /// The release file this copy downloads and installs by itself; null when it only opens
  /// [page].
  final WalletDesktopFile? file;

  /// How much of [file] arrived, 0 to 1, while [DeskUpdatePhase.downloading].
  final double? progress;

  /// What went wrong, short: the download ([DeskUpdatePhase.available]: try again) or the
  /// install ([DeskUpdatePhase.ready]: the page instead). Null when nothing did.
  final String? problem;

  /// The checked download, when [DeskUpdatePhase.ready].
  final File? download;

  /// Whether the update can be had at all (the notice shows).
  bool get offered => phase == DeskUpdatePhase.available || phase == DeskUpdatePhase.downloading || phase == DeskUpdatePhase.ready;
}

/// The first check after the wallet opens, and the ones after it while the app runs.
const Duration deskUpdateFirst = Duration(seconds: 20);
const Duration deskUpdateEvery = Duration(hours: 6);
final deskUpdateScheduleProvider = Provider<(Duration, Duration)>((ref) => (deskUpdateFirst, deskUpdateEvery));

/// Whether the shell starts the timed checks ([DeskUpdateController.schedule]): the real app
/// only (`main_desktop.dart`), not the mock or widget tests.
final deskUpdateAutoProvider = Provider<bool>((ref) => false);

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

/// Whether version [a] is newer than [b], by number (`0.1.10` > `0.1.9`, `26.10.0` > `0.1.1`,
/// `26.10.1` > `26.10.0`); a build suffix (`+3`, ` (abc)`) is ignored. A test build
/// (`26.10.0-rc1`) is never newer: it is never offered, and it sorts below its release.
bool isNewerVersion(String a, String b) {
  String core(String v) => v.trim().split(RegExp(r'[+ ]')).first;
  final x = core(a), y = core(b);
  if (isTestVersion(x)) return false;
  List<int> parts(String v) => [for (final p in v.split('-').first.split('.')) int.tryParse(p) ?? 0];
  final px = parts(x), py = parts(y);
  for (var i = 0; i < px.length || i < py.length; i++) {
    final d = (i < px.length ? px[i] : 0) - (i < py.length ? py[i] : 0);
    if (d != 0) return d > 0;
  }
  // Same numbers: the release is newer than its test build.
  return isTestVersion(y);
}

/// Whether [url] is an https page on one of [deskUpdatePageHosts].
bool isDeskUpdatePage(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.scheme != 'https' || u.userInfo.isNotEmpty || u.hasPort) return false;
  final normal = 'https://${u.host.toLowerCase()}${u.path}';
  return deskUpdatePageHosts.any((h) => normal.toLowerCase().startsWith(h.toLowerCase()));
}

class DeskUpdateController extends Notifier<DeskUpdateState> {
  Timer? _first, _every;

  @override
  DeskUpdateState build() {
    ref.onDispose(() {
      _first?.cancel();
      _every?.cancel();
    });
    return const DeskUpdateState(DeskUpdatePhase.idle);
  }

  /// Checks [deskUpdateFirst] from now and every [deskUpdateEvery] after, once per run (the
  /// shell calls it when the wallet opens).
  void schedule() {
    if (_every != null) return;
    final (first, every) = ref.read(deskUpdateScheduleProvider);
    _first = Timer(first, () => unawaited(check()));
    _every = Timer.periodic(every, (_) => unawaited(check()));
  }

  /// Checks once per run, when About first opens.
  Future<void> checkOnce() async {
    if (state.phase == DeskUpdatePhase.idle) await check();
  }

  Future<void> check() async {
    // A download under way or done stays as it is; one whose install failed is looked for again.
    final p = state.phase;
    if (p == DeskUpdatePhase.checking || p == DeskUpdatePhase.downloading || (p == DeskUpdatePhase.ready && state.problem == null)) return;
    final last = state.checkedAt;
    state = DeskUpdateState(DeskUpdatePhase.checking, checkedAt: last);
    final url = Uri.parse(updateManifestUrl);
    DeskUpdateState next;
    try {
      final (status, body) = await ref.read(deskManifestFetchProvider)(url);
      next = await _read(status, body);
    } on TimeoutException {
      next = DeskUpdateState(DeskUpdatePhase.failed, reason: deskStrings.deskDataUpdTimeout);
    } on Object catch (e) {
      logInfo('update', 'desktop check failed: ${e.runtimeType}');
      next = DeskUpdateState(DeskUpdatePhase.failed, reason: deskStrings.deskDataUpdUnreachable);
    }
    if (!ref.mounted) return;
    final now = ref.read(deskUpdateClockProvider)();
    state = DeskUpdateState(next.phase, version: next.version, page: next.page, reason: next.reason, checkedAt: now, file: next.file);
    if (next.phase == DeskUpdatePhase.latest) unawaited(_dropDownloads());
  }

  /// This version is the latest: a download kept from before (the installer or AppImage of the
  /// update that brought it) goes.
  Future<void> _dropDownloads() async {
    if (ref.read(deskUpdateApplierProvider) == null) return;
    try {
      final dir = await ref.read(deskUpdateDirProvider)();
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object catch (e) {
      logInfo('update', 'desktop: old downloads not removed: ${e.runtimeType}');
    }
  }

  /// Downloads the offered release file and checks it: [DeskUpdatePhase.ready] when it is the
  /// one the signed manifest names, else back to [DeskUpdatePhase.available] with the
  /// [DeskUpdateState.problem]. What arrived before a stop is kept for the next try.
  Future<void> download() async {
    final s = state;
    final f = s.file;
    if (s.phase != DeskUpdatePhase.available || f == null) return;
    DeskUpdateState at(DeskUpdatePhase phase, {double? progress, String? problem, File? download}) => DeskUpdateState(
      phase,
      version: s.version,
      page: s.page,
      checkedAt: s.checkedAt,
      file: f,
      progress: progress,
      problem: problem,
      download: download,
    );
    state = at(DeskUpdatePhase.downloading, progress: 0);
    logInfo('update', 'desktop: downloading ${s.version}');
    try {
      final file = await ref.read(deskUpdateDownloaderProvider)(f, (received) {
        if (!ref.mounted) return;
        // Whole per cent steps: the sidebar repaints a hundred times at most.
        final p = (received * 100 ~/ f.size) / 100;
        if (p != state.progress) state = at(DeskUpdatePhase.downloading, progress: p);
      });
      if (!ref.mounted) return;
      state = at(DeskUpdatePhase.ready, download: file);
    } on Object catch (e) {
      logWarn('update', 'desktop: download failed: $e');
      if (ref.mounted) state = at(DeskUpdatePhase.available, problem: _downloadProblem(e));
    }
  }

  /// "Restart to update": checks the download once more and puts it in place
  /// ([DeskUpdateApplier.apply]). True when the app should now quit; false leaves the state
  /// saying why (a download that no longer matches is offered again).
  Future<bool> restart() async {
    final s = state;
    final f = s.file, file = s.download;
    final applier = ref.read(deskUpdateApplierProvider);
    if (s.phase != DeskUpdatePhase.ready || f == null || file == null || applier == null) return false;
    DeskUpdateState at(DeskUpdatePhase phase, String problem) => DeskUpdateState(
      phase,
      version: s.version,
      page: s.page,
      checkedAt: s.checkedAt,
      file: f,
      problem: problem,
      download: phase == DeskUpdatePhase.ready ? file : null,
    );
    try {
      if (!await deskFileMatches(file, f)) {
        logWarn('update', 'desktop: the download changed since it was checked; offered again');
        state = at(DeskUpdatePhase.available, deskStrings.deskUpdErrDamaged);
        return false;
      }
      // A send may have started during the re-check: never update in the middle of one.
      if (ref.read(deskProvider.notifier).sending > 0) {
        logInfo('update', 'desktop: a payment is being sent; the update waits');
        return false;
      }
      await applier.apply(file);
      logInfo('update', 'desktop: ${s.version} is being installed; the app quits');
      return true;
    } on Object catch (e) {
      logWarn('update', 'desktop: the update could not be put in place: $e');
      if (ref.mounted) state = at(DeskUpdatePhase.ready, deskStrings.deskUpdErrInstall);
      return false;
    }
  }

  static String _downloadProblem(Object e) => switch (e) {
    DeskDownloadError(kind: DeskDownloadFail.damaged) => deskStrings.deskUpdErrDamaged,
    DeskDownloadError(kind: DeskDownloadFail.status, :final status) => deskStrings.deskDataUpdStatus(status ?? 0),
    DeskDownloadError(kind: DeskDownloadFail.unreachable) || NetError() => deskStrings.deskDataUpdUnreachable,
    _ => deskStrings.deskUpdErrStopped,
  };

  /// The last manifest accepted, also in an earlier run ([updateStateKey] in the desk store);
  /// an older one is refused (FORMAT.md §6).
  ManifestState? _manifestState;

  /// Whether the stored state was read. Until it is, nothing is stored over it: a store that
  /// could not be read is asked again at the next check.
  bool _stateRead = false;

  Future<void> _readState() async {
    if (_stateRead) return;
    final store = ref.read(deskStoreProvider);
    try {
      if (store != null) _manifestState = laterUpdateState(storedUpdateState(await store.readJson(updateStateKey)), _manifestState);
      _stateRead = true;
    } on Object catch (e) {
      logWarn('update', 'desktop: stored update.json state not read: ${e.runtimeType}');
    }
  }

  /// Remembers [next], the state of a manifest that just verified, and stores it.
  Future<void> _keepState(ManifestState next) async {
    if (next == _manifestState) return;
    _manifestState = next;
    final store = ref.read(deskStoreProvider);
    if (!_stateRead || store == null) return;
    try {
      await store.writeJson(updateStateKey, next.toJson());
    } on Object catch (e) {
      logWarn('update', 'desktop: update.json state not stored: ${e.runtimeType}');
    }
  }

  /// The update the last accepted manifest offered, if any: it stays offered when a later
  /// manifest does not verify or none is published (FORMAT.md §5: keep what you have).
  DeskUpdateState? _known;

  Future<DeskUpdateState> _read(int status, String body) async {
    // No manifest published: nothing newer is known, which is no error.
    if (status == 404) return _known ?? const DeskUpdateState(DeskUpdatePhase.latest);
    if (status == deskManifestTooLarge) return _notVerified(RejectReason.tooLarge);
    if (status != 200) return DeskUpdateState(DeskUpdatePhase.failed, reason: deskStrings.deskDataUpdStatus(status));
    await _readState();
    final result = await verifyWalletUpdate(
      body,
      keyring: ref.read(updateKeyringProvider),
      state: _manifestState,
      now: ref.read(deskUpdateClockProvider)().toUtc(),
    );
    if (result is! Accepted<WalletUpdate>) return _notVerified((result as Rejected<WalletUpdate>).reason);
    await _keepState(result.state);
    _known = null;
    final mine = result.manifest.desktop?.forSystem(_system);
    if (mine == null) {
      return DeskUpdateState(DeskUpdatePhase.failed, reason: deskStrings.deskDataUpdNone);
    }
    if (!isNewerVersion(mine.version, deskAppVersion)) return const DeskUpdateState(DeskUpdatePhase.latest);
    final page = mine.page;
    return _known = DeskUpdateState(
      DeskUpdatePhase.available,
      version: mine.version,
      page: page != null && isDeskUpdatePage(page) ? page : deskReleasesUrl,
      file: await _installable(mine.file),
    );
  }

  /// [f] when this copy can download and install it by itself: an applier for this system that
  /// can work here, an app that can quit, a file of this system's kind. Null: the page only.
  Future<WalletDesktopFile?> _installable(WalletDesktopFile? f) async {
    final applier = ref.read(deskUpdateApplierProvider);
    if (f == null || applier == null || ref.read(deskQuitProvider) == null) return null;
    if (!deskUpdateFileName(f).endsWith(applier.suffix)) return null;
    try {
      return await applier.canApply() ? f : null;
    } on Object catch (e) {
      logInfo('update', 'desktop: cannot install updates here: $e');
      return null;
    }
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
