import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'demo.dart';
import 'errors.dart';
import 'l10n.dart' show englishStrings;
import 'network.dart';
import 'phone_tor.dart';
import 'scan/scan_checks.dart' show CodeOrigin;
import 'scan/scan_router.dart' show PaymentRequest;
import 'tor_phone.dart' show phoneTorState;
import 'tor_routes.dart';
import 'secret_store.dart';
import 'advanced.dart' show NetworkMode;
import 'net/node_peers.dart';
import 'network_gate.dart';
import 'relay_block.dart';
import 'settings.dart' show appSettingsProvider, clockProvider, networkModeProvider;
import 'stall_retry.dart';
import 'watch_mode.dart' show BlockWatch;
import 'vault.dart';
import 'wallet_backend.dart' as backend;
import 'wallet_service.dart';

export 'models.dart' show defaultMinimumConfirmations;
import 'phrase_clipboard.dart';
import 'pairing_providers.dart' show invoiceSessionProvider;
import 'devices/device_service.dart' show DeviceSyncTrigger;
import 'devices/phone_devices.dart' show deviceServiceProvider;

final BigInt minimumConfirmations = BigInt.from(defaultMinimumConfirmations);

/// The fallback the app counts with before the first balance: [minimumConfirmations], and 1 in
/// the web demo, so test coins can be spent about a block after they land.
final minimumConfirmationsProvider = Provider<BigInt>(
  (ref) => ref.watch(demoModeProvider) ? BigInt.one : minimumConfirmations,
);

/// The confirmations a coin needs to be spent and a payment to count as completed: the count
/// the balance was worked out with ([WalletSummary.minimumConfirmations], LEPIC's), so Send
/// spends exactly what the balance calls spendable and a row never says Completed while its
/// coins are still confirming. Before the first balance, [minimumConfirmationsProvider].
final countedConfirmationsProvider = Provider.autoDispose<BigInt>((ref) {
  final counted = ref.watch(
    homeProvider.select((h) => h.value?.summary.minimumConfirmations),
  );
  if (counted != null && counted > BigInt.zero) return counted;
  return ref.watch(minimumConfirmationsProvider);
});

/// Resolves, and creates if missing, the data directory of the wallet for [chain].
typedef WalletDirResolver = Future<String> Function(Chain chain);

/// LEPIC on this device, or in the browser the wallet server (`wallet_backend.dart`).
final walletServiceProvider = Provider<WalletService>(
  (ref) => backend.createWalletService(ref.watch(secretStoreProvider)),
);

/// `<application support>/wallets/<chain>` on a device; a fixed name per chain on the web.
final walletDirProvider = Provider<WalletDirResolver>(
  (ref) => backend.defaultWalletDir,
);

/// The platform keystore, or on the web the browser's `localStorage`.
final secretStoreProvider = Provider<SecretStore>(
  (ref) => backend.createSecretStore(),
);

final biometricStoreProvider = Provider<BiometricStore>(
  (ref) => PlatformBiometricStore(),
);

final vaultProvider = Provider<WalletVault>(
  (ref) => WalletVault(
    store: ref.watch(secretStoreProvider),
    biometrics: ref.watch(biometricStoreProvider),
    service: ref.watch(walletServiceProvider),
    legacyFiles: backend.legacyWalletFiles,
  ),
);

/// The network the app opens on, and the node and relay it uses there.
class NetworkChoice {
  const NetworkChoice({
    required this.preset,
    required this.nodeUrl,
    required this.relay,
  });

  final NetworkPreset preset;
  final String nodeUrl;
  final EpicboxRelay relay;

  WalletConfig config(String dataDir) =>
      preset.config(dataDir: dataDir, nodeUrl: nodeUrl, relay: relay);
}

/// The saved [NetworkChoice]. Mainnet on its default node and relay until the user picks others.
final networkChoiceProvider =
    AsyncNotifierProvider<NetworkChoiceNotifier, NetworkChoice>(
      NetworkChoiceNotifier.new,
    );

class NetworkChoiceNotifier extends AsyncNotifier<NetworkChoice> {
  static const String _networkKey = 'app.network';
  static String _nodeKey(Chain chain) => 'app.node.${chain.name}';
  static String _relayKey(Chain chain) => 'app.relay.${chain.name}';

  @override
  Future<NetworkChoice> build() async {
    // The web demo runs on floonet's own node and relay, whatever was saved; its server
    // forces them too.
    if (ref.watch(demoModeProvider)) {
      return NetworkChoice(
        preset: floonetPreset,
        nodeUrl: floonetPreset.nodeUrl,
        relay: floonetPreset.defaultRelay,
      );
    }
    final store = ref.watch(secretStoreProvider);
    final saved = await store.read(_networkKey);
    final preset = networkPresets.firstWhere(
      (p) => p.chain.name == saved,
      orElse: () => mainnetPreset,
    );
    return NetworkChoice(
      preset: preset,
      nodeUrl: await nodeUrlFor(preset),
      relay: await relayFor(preset),
    );
  }

  /// The saved node URL of [preset], or its default.
  Future<String> nodeUrlFor(NetworkPreset preset) async =>
      await ref.read(secretStoreProvider).read(_nodeKey(preset.chain)) ??
      preset.nodeUrl;

  /// The saved relay of [preset], or its default.
  Future<EpicboxRelay> relayFor(NetworkPreset preset) async {
    final saved = await ref
        .read(secretStoreProvider)
        .read(_relayKey(preset.chain));
    return (saved == null ? null : EpicboxRelay.parse(saved)) ??
        preset.defaultRelay;
  }

  Future<void> save(
    NetworkPreset preset,
    String nodeUrl, {
    EpicboxRelay? relay,
  }) async {
    // The demo's network cannot change.
    if (ref.read(demoModeProvider)) return;
    final store = ref.read(secretStoreProvider);
    final r = relay ?? await relayFor(preset);
    await store.write(_networkKey, preset.chain.name);
    await store.write(_nodeKey(preset.chain), nodeUrl);
    await store.write(_relayKey(preset.chain), r.label);
    logInfo(
      'network',
      '${preset.chain.name}, node ${Uri.tryParse(nodeUrl)?.host ?? '?'}, relay ${r.label}',
    );
    state = AsyncData(
      NetworkChoice(preset: preset, nodeUrl: nodeUrl, relay: r),
    );
  }
}

/// Network and data directory of the wallet the app works with.
final walletConfigProvider =
    NotifierProvider<WalletConfigNotifier, WalletConfig?>(
      WalletConfigNotifier.new,
    );

/// The node in use is on this phone or the local network (`net/local_address.dart`): Offline
/// still refreshes against it and lets the File method and Direct sends to local addresses run.
final localNodeProvider = Provider<bool>(
  (ref) => isLocalAddressUrl(ref.watch(walletConfigProvider.select((c) => c?.nodeUrl))),
);

/// The local node's peer count while Offline ([nodePeerCount]); null otherwise or when it does
/// not say. With 0 a payment waits in the node's pool until it reconnects.
final offlineNodePeersProvider = FutureProvider.autoDispose<int?>((ref) async {
  final url = ref.watch(walletConfigProvider.select((c) => c?.nodeUrl));
  if (ref.watch(networkModeProvider) != NetworkMode.offline || url == null || !isLocalAddressUrl(url)) return null;
  return nodePeerCount(url);
});

class WalletConfigNotifier extends Notifier<WalletConfig?> {
  @override
  WalletConfig? build() => null;

  void select(WalletConfig config) => state = config;
}

/// The open wallet, or null while locked.
final sessionProvider = NotifierProvider<SessionNotifier, WalletSession?>(
  SessionNotifier.new,
);

class SessionNotifier extends Notifier<WalletSession?> {
  @override
  WalletSession? build() => null;

  /// Makes [session] the open wallet once it has the app's Epicbox via Tor setting and, when
  /// tor starts with the wallet, knows to wait for it: its first Epicbox connection then goes
  /// through Tor, never directly first.
  Future<void> open(WalletSession session) async {
    try {
      await PhoneTor.prepare(ref, session).timeout(const Duration(seconds: 10));
    } catch (error) {
      logWarn('session', 'epicbox via tor not prepared: ${error.runtimeType}');
    }
    unlocked(session);
  }

  /// Makes [session] the open wallet, disposing any other one first.
  void unlocked(WalletSession session) {
    final previous = state;
    if (previous != null && !identical(previous, session)) previous.dispose();
    if (!identical(previous, session)) logInfo('session', 'wallet unlocked');
    state = session;
  }

  /// Disposes the open wallet, which also frees its chain for another network.
  void lock() {
    final previous = state;
    state = null;
    // A recovery phrase copied in this session leaves the clipboard with it.
    unawaited(clearCopiedPhrase());
    if (previous != null) logInfo('session', 'wallet locked');
    previous?.dispose();
  }
}

/// Why the wallet is locked, which decides whether the unlock screen starts biometrics by
/// itself: on a cold start and after the auto-lock timeout it does, after a lock the user asked
/// for it never does (the prompt would open the wallet again at once).
enum LockReason { coldStart, timeout, manual }

final lockReasonProvider = NotifierProvider<LockReasonNotifier, LockReason>(
  LockReasonNotifier.new,
);

class LockReasonNotifier extends Notifier<LockReason> {
  @override
  LockReason build() => LockReason.coldStart;

  void set(LockReason reason) => state = reason;

  /// Whether the unlock screen may start biometrics itself. It answers true once per cold
  /// start or auto-lock, so a dismissed prompt is not offered again until the next one.
  bool takeAutoPrompt() {
    final auto = state != LockReason.manual;
    state = LockReason.manual;
    return auto;
  }
}

WalletSession _requireSession(Ref ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) throw StateError('Wallet is locked');
  return session;
}

class HomeData {
  const HomeData({
    required this.summary,
    required this.transactions,
    this.syncing = false,
    this.session,
  });

  final WalletSummary summary;
  final List<TxEntry> transactions;

  /// Read from the wallet's own files; the refresh against the node is still running.
  final bool syncing;

  /// The wallet these figures belong to, so another wallet's balance is never shown as its own.
  final WalletSession? session;
}

/// Percent done of the refresh home is running against the node, or null when none runs.
final syncProgressProvider = NotifierProvider<SyncProgressNotifier, int?>(
  SyncProgressNotifier.new,
);

class SyncProgressNotifier extends Notifier<int?> {
  @override
  int? build() {
    ref.watch(sessionProvider);
    return null;
  }

  void report(int? percent) => state = percent;
}

/// Balances and the transaction log of the open wallet.
///
/// The first load reads the wallet's own files, so the balance shows at once, then refreshes
/// against the node in the background ([HomeData.syncing]). Later loads refresh in place,
/// keeping the figures on screen.
final homeProvider = AsyncNotifierProvider.autoDispose<HomeNotifier, HomeData>(
  HomeNotifier.new,
);

/// The tip each payment of the open wallet waiting for a block was first seen at, for the note
/// in its details once its watch window passed ([BlockWatch]), kept across reloads.
final blockWatchProvider = Provider<BlockWatch>((ref) {
  ref.watch(sessionProvider);
  return BlockWatch();
});

/// The automatic reposts and resends of the open wallet ([StallRetry]), kept across reloads.
final stallRetryProvider = Provider<StallRetry>((ref) {
  ref.watch(sessionProvider);
  return StallRetry();
});

class HomeNotifier extends AsyncNotifier<HomeData> {
  bool _enriching = false;

  @override
  Future<HomeData> build() async {
    final session = _requireSession(ref);
    // Offline reads the wallet's own files only, or refreshes against a local node; leaving it
    // refreshes against the node again.
    final mode = ref.watch(networkModeProvider);
    final offline = mode == NetworkMode.offline && !ref.watch(localNodeProvider);
    final shown = state.value;
    if (!offline && shown != null && identical(shown.session, session)) {
      return _refreshed(session);
    }
    final summary = await session.summary(
      refresh: false,
      minimumConfirmations: ref.read(minimumConfirmationsProvider),
    );
    final transactions = await session.transactions(refresh: false);
    if (offline) {
      return HomeData(summary: summary, transactions: transactions, session: session);
    }
    Future<void>.delayed(Duration.zero, () => _syncInBackground(session));
    // Epicbox resends wait for Offline to end.
    if (mode != NetworkMode.offline) unawaited(_retryUndelivered(session, transactions));
    return HomeData(
      summary: summary,
      transactions: transactions,
      syncing: true,
      session: session,
    );
  }

  /// Refreshes against the node, publishing its progress in [syncProgressProvider], and reads
  /// the list.
  Future<HomeData> _refreshed(WalletSession session) async {
    final progress = ref.read(syncProgressProvider.notifier);
    WalletSummary? summary;
    try {
      await for (final step in session.refresh(
        minimumConfirmations: ref.read(minimumConfirmationsProvider),
      )) {
        // A reload replaced this one; it shows its own progress.
        if (!ref.mounted) throw StateError('Refresh replaced');
        progress.report(step.percent);
        summary = step.summary ?? summary;
      }
    } finally {
      if (ref.mounted) progress.report(null);
    }
    if (summary == null) throw StateError('Refresh ended without balances');
    // A refresh reads the linked devices' notices too (D-11), and sweeps their holds against
    // the chain just read.
    unawaited(ref.read(deviceServiceProvider)?.sync(DeviceSyncTrigger.refresh));
    final transactions = await session.transactions(refresh: false);
    ref.read(blockWatchProvider).saw(transactions, summary.lastConfirmedHeight, now: ref.read(clockProvider)());
    // Heights and dates for history rows come afterwards, so they never hold up the balance.
    Future<void>.delayed(Duration.zero, () => _enrich(session));
    unawaited(_retryStalled(session, transactions));
    return HomeData(
      summary: summary,
      transactions: transactions,
      session: session,
    );
  }

  /// Once per opened wallet: sends an undelivered Epicbox payment again (a kill before the
  /// first attempt, or a relay that refused), so it does not wait for the user to notice.
  Future<void> _retryUndelivered(
    WalletSession session,
    List<TxEntry> transactions,
  ) async {
    var retried = false;
    // An HTTP or Tor send waits for the user's Send again: its recipient may be offline.
    for (final tx in transactions.where((t) => t.undelivered && t.transport == 'epicbox')) {
      try {
        await session.resendEpicbox(key: tx.key);
        retried = true;
      } catch (error) {
        logWarn('home', 'resend at start failed: ${error.runtimeType}');
      }
    }
    if (retried && ref.mounted) unawaited(reload());
  }

  /// Posts again a payment the chain has not taken and sends again a paid invoice's answer
  /// when the shared policy says it is due (stall_retry.dart), then reads the list again.
  Future<void> _retryStalled(
    WalletSession session,
    List<TxEntry> transactions,
  ) async {
    try {
      final retry = ref.read(stallRetryProvider);
      final sent = await retry.run(
        session,
        transactions,
        ref.read(clockProvider)(),
      );
      if (sent && ref.mounted) unawaited(reload());
    } catch (error) {
      logWarn('home', 'automatic retry failed: ${error.runtimeType}');
    }
  }

  /// The refresh after a local first load. A failure keeps the local figures and shows the
  /// error; a reload that started meanwhile replaces this one.
  Future<void> _syncInBackground(WalletSession session) async {
    if (!ref.mounted) return;
    try {
      final data = await _refreshed(session);
      if (ref.mounted) state = AsyncData(data);
    } catch (error, stack) {
      logWarn(
        'sync',
        'refresh failed: ${describeError(englishStrings, error)}',
      );
      if (!ref.mounted) return;
      // The local figures stay, no longer marked as syncing, under the error.
      final shown = state.value;
      if (shown != null) {
        state = AsyncData(
          HomeData(
            summary: shown.summary,
            transactions: shown.transactions,
            session: shown.session,
          ),
        );
      }
      state = AsyncError(error, stack);
    }
  }

  /// Asks the core to fill in heights and times it can look up, and reloads the list (only the
  /// list) when any row changed. Failures are ignored: the next refresh tries again.
  Future<void> _enrich(WalletSession session) async {
    if (_enriching) return;
    _enriching = true;
    try {
      final changed = await session.enrichHistory();
      if (changed == 0 || !ref.mounted) return;
      final transactions = await session.transactions(refresh: false);
      final current = state;
      // A reload that started meanwhile brings its own list and enriches again.
      if (!ref.mounted || current.isLoading || !current.hasValue) return;
      final shown = current.requireValue;
      state = AsyncData(
        HomeData(
          summary: shown.summary,
          transactions: transactions,
          syncing: shown.syncing,
          session: shown.session,
        ),
      );
    } catch (error) {
      // The list stays as it was.
      logInfo(
        'history',
        'enrich failed: ${describeError(englishStrings, error)}',
      );
    } finally {
      _enriching = false;
    }
  }

  /// Refreshes against the node. Completes with an error if the refresh failed.
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  /// Reads the list again from the wallet's own files, keeping the balance, so what LEPIC
  /// recorded without a refresh (a sender's posted report) shows at once. Nothing while a load
  /// runs: that one reads the list itself.
  Future<void> relist() async {
    final shown = state.value;
    final session = shown?.session;
    if (state.isLoading || shown == null || session == null) return;
    final transactions = await session.transactions(refresh: false);
    if (!ref.mounted || state.isLoading || !identical(state.value?.session, session)) return;
    final now = state.requireValue;
    state = AsyncData(
      HomeData(
        summary: now.summary,
        transactions: transactions,
        syncing: now.syncing,
        session: session,
      ),
    );
  }
}

/// Whether home is refreshing against the node: a reload, or the background refresh after a
/// local first load.
bool homeRefreshing(AsyncValue<HomeData> home) =>
    home.isLoading || (home.value?.syncing ?? false);

/// The relay the open wallet uses, as [walletConfigProvider] names it. Own addresses carry the
/// relay, so a provider of one watches this: a live switch reads the address again.
void _watchRelay(Ref ref) => ref.watch(
  walletConfigProvider.select((c) => (c?.epicboxDomain, c?.epicboxPort)),
);

final addressProvider = FutureProvider.autoDispose<String>((ref) {
  _watchRelay(ref);
  return _requireSession(ref).epicboxAddress();
});

/// Every output of the open wallet, from its database; reads again when home does.
final walletOutputsProvider = FutureProvider.autoDispose<List<WalletOutput>>((
  ref,
) {
  final session = _requireSession(ref);
  ref.watch(homeProvider.select((h) => h.value?.summary));
  return session.outputs();
});

/// The open wallet's node tip, asked through the wallet so it follows the wallet's Tor
/// ([WalletSession.nodeTipFor]); never asked while locked.
final nodeTipProvider = FutureProvider.autoDispose<NodeTip>((ref) {
  final session = _requireSession(ref);
  final config = ref.watch(walletConfigProvider);
  if (config == null) throw StateError('No network selected');
  if (ref.watch(networkModeProvider) == NetworkMode.offline && !isLocalAddressUrl(config.nodeUrl)) {
    throw const NetBlocked(NetworkMode.offline, 'node tip');
  }
  return session.nodeTipFor(config: config);
});

/// The tip of the node [config] names, for a test of a node typed in: through the open
/// [session] when there is one, so it follows the wallet's Tor; with none open (first run,
/// where there is no Tor switch yet) directly.
Future<NodeTip> askNodeTip(
  WalletService service,
  WalletSession? session,
  WalletConfig config,
) async {
  // Offline asks no node but a local one, also before a wallet is open.
  NetGate.check('node tip', local: isLocalAddressUrl(config.nodeUrl));
  return session != null
      ? session.nodeTipFor(config: config)
      : service.nodeTip(config: config);
}

/// Prefix of the core's final scan event when the scan failed.
const String scanFailedPrefix = 'Scan failed:';

/// A scan's progress. The screen words it from [running], [percent], [done] and [error];
/// [message] is the core's English line, for the log only.
class ScanState {
  const ScanState({
    this.running = false,
    this.percent,
    this.message,
    this.error,
    this.done = false,
    this.stopped = false,
    this.paused = false,
    this.resuming = false,
  });

  /// True from the start until the scan ends, through a pause.
  final bool running;
  final int? percent;
  final String? message;

  /// Why the last scan failed, for `describeError`.
  final Object? error;

  /// The last scan finished without an error.
  final bool done;

  /// The last scan was stopped ([ScanNotifier.stop]) before it finished. Its pages stay: the
  /// next scan with the same start goes on from there.
  final bool stopped;

  /// The app is in the background: the scan stopped at its page there, since Android cuts a
  /// background app's network, and goes on from the last stored page when the app is back
  /// ([ScanNotifier.pause]).
  final bool paused;

  /// Back from a pause: the scan started again and has not yet reported a page beyond
  /// [percent], the progress from before the pause.
  final bool resuming;
}

/// A scan of the chain for the open wallet's outputs, with its latest progress.
final scanProvider = NotifierProvider<ScanNotifier, ScanState>(
  ScanNotifier.new,
);

class ScanNotifier extends Notifier<ScanState> {
  /// [stop] was asked for the running scan.
  bool _stopping = false;

  /// The app is in the background ([pause] until [resume]).
  bool _away = false;

  /// Completes when the app is back, or the scan is stopped or its session gone.
  Completer<void>? _back;

  @override
  ScanState build() {
    ref.watch(sessionProvider);
    _stopping = false;
    _wake();
    return const ScanState();
  }

  /// Stops the running scan at its next page; [run] then answers false with
  /// [ScanState.stopped].
  void stop() {
    final session = ref.read(sessionProvider);
    if (session == null || !state.running) return;
    _stopping = true;
    logInfo('scan', 'stop asked');
    session.cancelScan();
    _wake();
  }

  /// The app went to the background (phone, `app.dart`). Android cuts a background app's
  /// network within seconds, which failed the scan there, so it stops at its page instead and
  /// [run] waits for [resume]. The core stored every page, so the scan goes on from the last
  /// one, with the same start.
  void pause() {
    if (_away) return;
    _away = true;
    if (!state.running) return;
    logInfo('scan', 'paused: the app is in the background');
    state = ScanState(running: true, paused: true, percent: state.percent);
    ref.read(sessionProvider)?.cancelScan();
  }

  /// The app is back: a paused scan goes on.
  void resume() {
    if (!_away) return;
    _away = false;
    _wake();
  }

  void _wake() {
    final back = _back;
    _back = null;
    back?.complete();
  }

  /// Scans from [startHeight] until the core closes the stream. Returns true on success.
  Future<bool> run({BigInt? startHeight}) async {
    final session = ref.read(sessionProvider);
    if (session == null || state.running) return false;
    // Recheck balance asks the node: Offline refuses it before it starts, unless it is local.
    if (NetGate.offline && !ref.read(localNodeProvider)) {
      state = const ScanState(error: NetBlocked(NetworkMode.offline, 'scan'));
      return false;
    }
    _stopping = false;
    state = const ScanState(running: true);
    // No start height: the core starts at block 0 while the restore is unfinished, otherwise
    // shortly before the last scanned block.
    logInfo('scan', 'started from ${startHeight ?? 'the core\'s default (block 0 while the restore is unfinished)'}');
    // The core ends every scan with a `finished` event; on failure its message starts with
    // "Scan failed:" and the stream then closes with the error as well, which wins.
    Object? failure;
    var finished = false;
    while (true) {
      // In the background (or paused there): wait for the app, then the same scan goes on.
      if (_away) {
        state = ScanState(running: true, paused: true, percent: state.percent);
        await (_back ??= Completer<void>()).future;
        if (!ref.mounted || !identical(ref.read(sessionProvider), session)) return false;
        if (_stopping) break;
        logInfo('scan', 'resumed from the last stored page');
        state = ScanState(running: true, resuming: true, percent: state.percent);
      }
      failure = null;
      var first = true;
      try {
        await for (final progress in session.scan(startHeight: startHeight)) {
          if (!ref.mounted) return false;
          final opening = first;
          first = false;
          if (progress.finished &&
              progress.message.startsWith(scanFailedPrefix)) {
            failure = ScanFailed(
              progress.message.substring(scanFailedPrefix.length).trim(),
            );
            continue;
          }
          if (progress.finished) finished = true;
          // Pages that land after the pause until the stop takes effect: it shows paused.
          if (_away && !finished) continue;
          // The core first reports the start height, before its first page: 0 % from block 0
          // even when it goes on from a stored page (after a pause, or the app was closed).
          // It reads as starting, or as the progress from before the pause.
          if (opening && !progress.finished && progress.percent == 0) continue;
          // A resumed scan's first pages may still lie behind the progress from before the
          // pause: that stays until a page passes it.
          final percent = progress.percent ?? state.percent;
          final behind = state.resuming &&
              !progress.finished &&
              (percent ?? 0) < (state.percent ?? 0);
          state = ScanState(
            running: !progress.finished,
            percent: behind ? state.percent : percent,
            message: progress.message,
            resuming: behind,
          );
        }
      } catch (error) {
        failure = error;
      }
      if (!ref.mounted) return false;
      // A failure while away is the network Android cut: the scan goes on at the return.
      if (finished || _stopping || !_away) break;
    }
    if (!ref.mounted) return false;
    // Balances as the scan left them: the restore's Home and Outputs read zero before it.
    ref.invalidate(homeProvider);
    if (_stopping) {
      _stopping = false;
      logInfo('scan', 'stopped');
      state = const ScanState(stopped: true);
      return false;
    }
    if (failure != null) {
      logWarn('scan', 'failed: ${describeError(englishStrings, failure)}');
      state = ScanState(error: failure);
      return false;
    }
    state = ScanState(message: state.message, done: true);
    return true;
  }
}

class ListenerState {
  const ListenerState({
    this.connected = false,
    this.lost = false,
    this.stopped = false,
    this.status,
    this.last,
    this.offline = false,
    this.blocked = false,
  });

  /// Subscribed at the relay, so incoming payments and responses arrive.
  final bool connected;

  /// Was connected, lost the connection, and is retrying.
  final bool lost;

  /// The core stopped the listener. It does not retry, and the header shows no epicbox row.
  final bool stopped;

  /// Why it is not connected, when known.
  final String? status;

  /// The network mode is Offline: no listener runs until it changes (network_gate.dart).
  final bool offline;

  /// The latest payment event (received, finalized or failed), for a one-off notice.
  final ListenerEvent? last;

  /// Not connected because this network blocks the relay: its TLS handshake is refused with
  /// an alert, attempt after attempt (relay_block.dart). Only for a direct connection.
  final bool blocked;
}

/// Runs the epicbox listener while a wallet is open, and refreshes balances when it receives or
/// finalizes a transaction. It stops with the session.
final listenerProvider = NotifierProvider<ListenerNotifier, ListenerState>(
  ListenerNotifier.new,
);

/// How long [ListenerNotifier.restart] waits for the old listener to report it stopped before
/// it starts a new one anyway.
const Duration listenerStopWait = Duration(seconds: 5);

/// How long a listener the wallet expects may go unconnected before [ListenerNotifier] restarts
/// it on its own. LEPIC retries a lost connection itself; this catches a listener that stays
/// down anyway (a dead socket it never noticed, a stream that ended, a backoff on a clock that
/// slept). Each restart that does not connect doubles the wait, up to [listenerHealMax].
const Duration listenerHealAfter = Duration(seconds: 30);

/// The longest wait between two self-heal restarts of a listener that does not connect.
const Duration listenerHealMax = Duration(minutes: 5);

class ListenerNotifier extends Notifier<ListenerState> {
  StreamSubscription<ListenerEvent>? _events;

  /// Completes when the current listener's stream reports `stopped` or ends.
  Completer<void>? _ended;
  bool _restarting = false;

  /// The connection dropped, or the network went, since the listener was last connected:
  /// LEPIC may be sleeping out its backoff, so a resume or a returning network restarts it.
  bool _down = false;

  /// Runs while the listener is not connected and the wallet expects it to be ([_heal]).
  Timer? _healTimer;

  /// Self-heal restarts since the listener was last connected: each doubles the next wait.
  int _heals = 0;

  /// Counts refused handshakes in a row, for [ListenerState.blocked].
  final RelayBlockWatch _block = RelayBlockWatch();

  /// The relays this network blocked while the wallet was open, so another is offered next
  /// (relay_block_phone.dart).
  final Set<EpicboxRelay> blockedRelays = {};

  static const String _connecting = 'Connecting to the epicbox relay…';

  @override
  ListenerState build() {
    final session = ref.watch(sessionProvider);
    ref.onDispose(() {
      _events?.cancel();
      _down = false;
      _healTimer?.cancel();
      _healTimer = null;
      _heals = 0;
      _block.reset();
    });
    if (session == null) return const ListenerState();
    // Offline: nothing listens; leaving it rebuilds this, which starts the listener again.
    if (ref.watch(networkModeProvider) == NetworkMode.offline) {
      unawaited(session.stopListener().catchError((Object _) {}));
      return const ListenerState(offline: true, status: 'Offline mode');
    }
    // Epicbox off (Settings › Transactions): the same, and the header shows Epicbox as off.
    // Settings not read yet count as on (the default), so their arrival does not restart the
    // listener that just started.
    if (ref.watch(appSettingsProvider.select((s) => s.value?.payments.epicbox ?? true)) == false) {
      unawaited(session.stopListener().catchError((Object _) {}));
      return const ListenerState(stopped: true, status: 'Epicbox off');
    }
    // Android reports the network that is up as soon as this listens; only with a drop seen
    // before is a returning network a reason to reconnect.
    final network = ref.watch(networkChangesProvider).listen((available) {
      if (available) {
        unawaited(wake('network'));
      } else {
        _down = true;
      }
    });
    ref.onDispose(network.cancel);
    // Called with the state this build returns, and with every one after it.
    listenSelf((_, next) => _heal(next));
    _listen(session);
    return const ListenerState(status: _connecting);
  }

  /// Arms the self-heal while [now] is not connected, and disarms it once it is: a listener
  /// the wallet expects that has not been connected for [listenerHealAfter] (doubling with
  /// each restart that did not help, up to [listenerHealMax]) is restarted, with a log line.
  /// Offline mode expects no listener.
  void _heal(ListenerState now) {
    // Armed only by a listener that said it is down (lost or stopped): one still making its
    // first connection is LEPIC's to finish, and says "disconnected" when that attempt fails.
    // A blocked relay is not healed: a restart changes nothing but the status, which would
    // flip to connecting and back; LEPIC keeps trying and connects once the block goes.
    if (now.connected || now.offline || now.blocked || !(now.lost || now.stopped)) {
      _healTimer?.cancel();
      _healTimer = null;
      if (now.connected) _heals = 0;
      return;
    }
    if (_healTimer != null) return;
    final wait = listenerHealAfter * (1 << _heals.clamp(0, 4));
    final after = wait > listenerHealMax ? listenerHealMax : wait;
    _healTimer = Timer(after, () {
      _healTimer = null;
      if (!ref.mounted) return;
      final state = this.state;
      if (state.connected || state.offline || state.blocked || !(state.lost || state.stopped)) {
        return;
      }
      // A connection held for Tor while it starts is not down: it waits as long as tor does.
      final torWait =
          ref.exists(phoneTorProvider) &&
          torWay(TorRoute.epicbox, phoneTorState(ref.read(phoneTorProvider))) ==
              TorWay.wait;
      if (_restarting || torWait) {
        _heal(state);
        return;
      }
      _heals++;
      logWarn(
        'listener',
        'not connected for ${after.inSeconds} s'
            '${state.status == null ? '' : ' (${state.status})'}; restarting it',
      );
      unawaited(restart());
    });
  }

  /// Restarts a listener that is down, so it reconnects now rather than after LEPIC's backoff,
  /// which grows to 60 s and does not count the time the phone slept. Called when the app
  /// comes back to the foreground and when the network returns. A listener still making its
  /// first connection and a stopped one are left alone; a connected one only when the network
  /// changed under it (its socket went with the old network, though LEPIC has not noticed).
  Future<void> wake(String why) async {
    if (!_down || state.stopped || state.offline) return;
    if (state.connected && why != 'network') return;
    // Blocked here stays blocked on a resume; another network may not block it.
    if (state.blocked && why != 'network') return;
    logInfo('listener', 'reconnect on $why');
    await restart();
  }


  void _listen(WalletSession session) {
    final ended = _ended = Completer<void>();
    void end() {
      if (!ended.isCompleted) ended.complete();
    }

    // An error already said Offline; the stream's end after it changes nothing.
    var failed = false;
    late final StreamSubscription<ListenerEvent> events;
    logInfo('listener', 'epicbox connecting');
    events = session.startListener().listen(
      (event) {
        if (event.kind == ListenerEventKind.stopped) end();
        // A listener being replaced by [restart] no longer speaks for the wallet.
        if (identical(_events, events)) _onEvent(event);
      },
      onError: (Object error) {
        if (!identical(_events, events)) return;
        failed = true;
        // Nothing listens any more: a resume or a returning network starts it again.
        _down = true;
        logWarn(
          'listener',
          'stream failed: ${describeError(englishStrings, error)}',
        );
        // Not stopped: the receive path is broken, so the header says Offline.
        state = ListenerState(
          lost: true,
          status: describeError(englishStrings, error),
          last: state.last,
        );
      },
      onDone: () {
        end();
        // Ended without a word, as LEPIC's stream does when a listener runs already: nothing
        // listens, so it counts as stopped and Receive offers Retry.
        if (identical(_events, events) && !failed && !state.stopped) {
          state = ListenerState(
            stopped: true,
            status: 'Listener stopped',
            last: state.last,
          );
        }
      },
    );
    _events = events;
  }

  /// Stops the listener and starts it again, for Retry on Receive. The core starts a second
  /// listener only once the first has stopped, so this waits for that, at most
  /// [listenerStopWait].
  Future<void> restart() async {
    final session = ref.read(sessionProvider);
    if (session == null || _restarting || state.offline) return;
    _restarting = true;
    final old = _events;
    final ended = _ended;
    _events = null;
    _block.reset();
    state = ListenerState(status: _connecting, last: state.last);
    logInfo('listener', 'restart');
    try {
      await session.stopListener();
      await ended?.future.timeout(
        listenerStopWait,
        onTimeout: () {
          logWarn(
            'listener',
            'old listener did not stop in time; starting anyway',
          );
        },
      );
    } catch (error) {
      logWarn(
        'listener',
        'stop failed: ${describeError(englishStrings, error)}',
      );
    } finally {
      _restarting = false;
    }
    // Not awaited: a cancel can take a turn of the event loop, and it changes nothing here.
    unawaited(old?.cancel());
    // A lock or another wallet meanwhile rebuilt the provider, which started its own.
    if (!ref.mounted || ref.read(sessionProvider) != session) return;
    if (_events != null) return;
    _listen(session);
  }

  /// One failed connection, with LEPIC's [reason]: whether this network now blocks the relay
  /// ([RelayBlockWatch]). Over Tor it is not this network's doing, so never.
  bool _blockedBy(String reason) {
    final overTor =
        ref.exists(phoneTorProvider) &&
        torWay(TorRoute.epicbox, phoneTorState(ref.read(phoneTorProvider))) ==
            TorWay.overTor;
    if (overTor) {
      _block.reset();
      return false;
    }
    final was = state.blocked;
    if (!_block.failed(reason)) return false;
    final config = ref.read(walletConfigProvider);
    if (config != null) {
      blockedRelays.add(EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort));
    }
    if (!was) logWarn('listener', 'this network blocks the relay (refused handshake): $reason');
    return true;
  }

  void _onEvent(ListenerEvent event) {
    switch (event.kind) {
      case ListenerEventKind.connected:
        if (!state.connected) logInfo('listener', 'epicbox subscribed');
        _down = false;
        _block.reset();
        state = ListenerState(connected: true, last: state.last);
      case ListenerEventKind.disconnected:
        // LEPIC sends one per failed attempt, between its backoff waits.
        final reason = event.reason ?? event.message;
        final wait = event.retryInMs;
        logInfo(
          'listener',
          'epicbox disconnected'
              '${reason.isEmpty ? '' : ': $reason'}'
              '${wait == null ? '' : ', LEPIC retries in $wait ms'}',
        );
        // Raw: the status shows it only once it lasts (walletStatusProvider).
        _down = true;
        state = ListenerState(
          lost: true,
          blocked: _blockedBy(reason),
          status: 'Reconnecting to the relay: ${event.message}',
          last: state.last,
        );
      case ListenerEventKind.stopped:
        logInfo('listener', 'epicbox listener stopped');
        state = ListenerState(
          stopped: true,
          status: 'Listener stopped',
          last: state.last,
        );
      case ListenerEventKind.received ||
          ListenerEventKind.repeated ||
          ListenerEventKind.finalized ||
          ListenerEventKind.expired ||
          ListenerEventKind.delayed ||
          ListenerEventKind.error:
        state = ListenerState(
          connected: state.connected,
          lost: state.lost,
          stopped: state.stopped,
          blocked: state.blocked,
          status: state.status,
          last: event,
        );
        // An error about a payment may have changed it too (an expired send is cancelled).
        // A repeat changed nothing, so it refreshes nothing.
        if (event.kind == ListenerEventKind.repeated) return;
        if (event.kind != ListenerEventKind.error || event.slateId != null) {
          ref.invalidate(homeProvider);
        }
    }
  }
}

/// The latest report from the sender of an incoming Epicbox payment that it posted the
/// transaction (LEPIC's `paymentPosted`); home words it as a notice. Advisory: the payment
/// counts once the chain confirms it. Each report shows on its row at once
/// ([HomeNotifier.relist]) and asks for one chain check, home's refresh against the node: at
/// once when none runs, else once after the running one ends, however many reports came
/// meanwhile. Never a second refresh beside a running one, and never a listener or a drain:
/// the report only comes from one, which Epicbox off ([NetGate.epicboxOff]) already refuses.
final paymentPostedProvider =
    NotifierProvider<PaymentPostedNotifier, InvoiceEvent?>(
      PaymentPostedNotifier.new,
    );

class PaymentPostedNotifier extends Notifier<InvoiceEvent?> {
  /// Waits for the running refresh to end, while a check is owed.
  ProviderSubscription<AsyncValue<HomeData>>? _owed;

  @override
  InvoiceEvent? build() {
    final session = ref.watch(sessionProvider);
    ref.onDispose(() => _owed?.close());
    if (session == null) return null;
    final events = session
        .invoiceEvents()
        .where((e) => e.kind == InvoiceEventKind.paymentPosted)
        .listen((e) => unawaited(_onPosted(e)), onError: (_) {});
    ref.onDispose(events.cancel);
    return null;
  }

  Future<void> _onPosted(InvoiceEvent event) async {
    logInfo('home', 'sender reports a payment posted');
    try {
      await ref.read(homeProvider.notifier).relist();
    } catch (error) {
      logInfo('home', 'list not read: ${error.runtimeType}');
    }
    if (!ref.mounted) return;
    _checkChain();
    state = event;
  }

  void _checkChain() {
    if (!homeRefreshing(ref.read(homeProvider))) {
      ref.invalidate(homeProvider);
      return;
    }
    if (_owed != null) return;
    _owed = ref.listen<AsyncValue<HomeData>>(homeProvider, (_, home) {
      if (homeRefreshing(home)) return;
      _owed?.close();
      _owed = null;
      ref.invalidate(homeProvider);
    });
  }
}

/// The three tabs of the wallet shell, left to right.
enum ShellTab { send, wallet, receive }

/// The tab the shell shows. Wallet, the middle one, whenever a wallet opens.
final shellTabProvider = NotifierProvider<ShellTabNotifier, ShellTab>(
  ShellTabNotifier.new,
);

class ShellTabNotifier extends Notifier<ShellTab> {
  @override
  ShellTab build() {
    ref.watch(sessionProvider);
    return ShellTab.wallet;
  }

  void go(ShellTab tab) => state = tab;
}

/// A recipient handed to the Send tab, from a scanned QR code or Send again. [id] tells two
/// hand-offs of the same text apart. A payment code ([request]) also brings an amount, a note
/// and where it came from ([origin]); it only fills the form. [pairingId] is a paired contact
/// with no address, paid through its mailbox; [text] is empty then.
typedef RecipientHandoff = ({
  int id,
  String text,
  PaymentRequest? request,
  CodeOrigin? origin,
  String? pairingId,
});

/// The latest [RecipientHandoff], until the Send form that took it is cleared.
final sendRecipientProvider =
    NotifierProvider<SendRecipientNotifier, RecipientHandoff?>(
      SendRecipientNotifier.new,
    );

class SendRecipientNotifier extends Notifier<RecipientHandoff?> {
  int _next = 0;

  @override
  RecipientHandoff? build() {
    ref.watch(sessionProvider);
    return null;
  }

  /// Hands over [text] as the recipient; [origin] when it came from a scan, paste or link.
  void hand(String text, {CodeOrigin? origin}) =>
      state = (id: _next++, text: text, request: null, origin: origin, pairingId: null);

  /// Hands over the pairing [pairingId] as the recipient: a contact with no address.
  void handPairing(String pairingId) =>
      state = (id: _next++, text: '', request: null, origin: null, pairingId: pairingId);

  /// Hands over a payment code: Send fills the address, the amount and the note.
  void handRequest(PaymentRequest request, CodeOrigin origin) => state = (
    id: _next++,
    text: request.recipient.address,
    request: request,
    origin: origin,
    pairingId: null,
  );

  void clear() => state = null;
}

// Invoices over epicbox (I-01). Every provider here is empty or null while the wallet is
// locked or its core has no invoices ([WalletSession.supportsInvoices]). None of them pays:
// paying is the review screen's call after the PIN or biometric gate, and nothing else.

/// Now, for invoice expiry. Tests and the tour override it.
final invoiceClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The open wallet when it handles invoices, else null.
WalletSession? _invoiceSession(Ref ref) => ref.watch(invoiceSessionProvider);

/// Pending invoices of the open wallet, oldest first. The first read collects the paired
/// contacts' mailboxes, and so does [PendingInvoicesNotifier.refresh] (pull to refresh, opening the
/// screen, app start); nothing listens on it in the background. An invoice drops out of the
/// list when its time runs out.
final pendingInvoicesProvider =
    AsyncNotifierProvider.autoDispose<
      PendingInvoicesNotifier,
      List<PendingInvoice>
    >(PendingInvoicesNotifier.new);

class PendingInvoicesNotifier extends AsyncNotifier<List<PendingInvoice>> {
  Timer? _expiry;

  @override
  Future<List<PendingInvoice>> build() async {
    ref.onDispose(() => _expiry?.cancel());
    final session = _invoiceSession(ref);
    if (session == null) return const [];
    // Offline drains nothing: the invoices already in the wallet show; leaving it drains.
    if (ref.watch(networkModeProvider) == NetworkMode.offline) {
      return _unexpired(await session.pendingInvoices());
    }
    final report = await session.drainInvoices();
    if (!ref.mounted) return const [];
    // A receipt or a withdrawal changes what a paid invoice's details show.
    if (report.notices > 0) ref.invalidate(paidInvoiceProvider);
    return _unexpired(await session.pendingInvoices());
  }

  /// [invoices] without the expired ones, with a timer for the next to expire.
  List<PendingInvoice> _unexpired(List<PendingInvoice> invoices) {
    _expiry?.cancel();
    final now = ref.read(invoiceClockProvider)();
    final live = [
      for (final i in invoices)
        if (!i.isExpiredAt(now)) i,
    ];
    if (live.isNotEmpty) {
      final next = live
          .map((i) => i.timeLeftAt(now))
          .reduce((a, b) => a < b ? a : b);
      _expiry = Timer(next, () {
        final shown = state.value;
        if (ref.mounted && shown != null) state = AsyncData(_unexpired(shown));
      });
    }
    return live;
  }

  /// Drains the invoice address again and reloads the list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Reads the wallet's waiting invoices again without a drain: one that arrived another way
  /// (a paired contact's mailbox) or a drain's own event (PAIR-AND-3).
  Future<void> reload() async {
    final session = _invoiceSession(ref);
    if (session == null || !state.hasValue) return;
    final fresh = await session.pendingInvoices();
    if (ref.mounted) state = AsyncData(_unexpired(fresh));
  }

  /// Takes an invoice the user paid or declined off the list, without another drain.
  void answered(String slateId) {
    final shown = state.value;
    if (shown == null) return;
    state = AsyncData([
      for (final i in shown)
        if (i.slateId != slateId) i,
    ]);
  }
}

/// How many pending invoices wait, for Home's badge. 0 until the first drain is done.
final pendingInvoiceCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(pendingInvoicesProvider).value?.length ?? 0,
);

/// The invoice behind the transaction with that slate id, once paid, or null. Reloads when
/// a receipt or a withdrawal for it arrives: LEPIC reports those as events, which may come
/// after the drain that found them has returned.
final paidInvoiceProvider = FutureProvider.autoDispose
    .family<PaidInvoice?, String>((ref, slateId) {
      final session = _invoiceSession(ref);
      if (session == null) return null;
      final events = session
          .invoiceEvents()
          .where(
            (e) =>
                e.slateId == slateId &&
                (e.kind == InvoiceEventKind.posted ||
                    e.kind == InvoiceEventKind.withdrawn),
          )
          .listen((_) => ref.invalidateSelf(), onError: (_) {});
      ref.onDispose(events.cancel);
      return session.paidInvoice(slateId: slateId);
    });

// Issuing invoices (I-05): requests this wallet sent, and the drain of the payments address
// that finalizes their payments. Empty or idle while the wallet is locked or has no
// invoices. Nothing here spends: an issuer only receives.

/// Invoices this wallet issued, newest first. Reloads on every issuer event.
final issuedInvoicesProvider =
    AsyncNotifierProvider.autoDispose<
      IssuedInvoicesNotifier,
      List<IssuedInvoice>
    >(IssuedInvoicesNotifier.new);

class IssuedInvoicesNotifier extends AsyncNotifier<List<IssuedInvoice>> {
  @override
  Future<List<IssuedInvoice>> build() async {
    final session = _invoiceSession(ref);
    if (session == null) return const [];
    final events = session.issuerEvents().listen(
      (_) => ref.invalidateSelf(),
      onError: (_) {},
    );
    ref.onDispose(events.cancel);
    return session.issuedInvoices();
  }

  WalletSession get _session =>
      _invoiceSession(ref) ?? (throw StateError('No wallet with invoices'));

  /// Withdraws a waiting request. The user confirms first.
  Future<IssuedInvoice> withdraw(String slateId) async {
    final withdrawn = await _session.withdrawInvoice(slateId: slateId);
    logInfo('invoices', 'issued invoice withdrawn');
    ref.invalidateSelf();
    await future;
    return withdrawn;
  }
}

/// The invoice this wallet issued under that slate id, for a transaction's details, or null.
/// Reloads when it changes state.
final issuedInvoiceProvider = FutureProvider.autoDispose
    .family<IssuedInvoice?, String>((ref, slateId) {
      final session = _invoiceSession(ref);
      if (session == null) return null;
      final events = session
          .issuerEvents()
          .where((e) => e.slateId == slateId)
          .listen((_) => ref.invalidateSelf(), onError: (_) {});
      ref.onDispose(events.cancel);
      return session.issuedInvoice(slateId: slateId);
    });

/// An issuer event for a notice. [id] tells two equal events apart.
typedef IssuerNotice = ({int id, IssuerEvent event});

/// The latest issuer event of the open wallet: paid, declined, withdrawn, expired or
/// bounced. Kept alive by [paymentsDrainProvider], so no event of a drain is missed.
final issuerNoticeProvider =
    NotifierProvider<IssuerNoticeNotifier, IssuerNotice?>(
      IssuerNoticeNotifier.new,
    );

class IssuerNoticeNotifier extends Notifier<IssuerNotice?> {
  int _next = 0;

  @override
  IssuerNotice? build() {
    final session = _invoiceSession(ref);
    if (session == null) return null;
    final events = session.issuerEvents().listen((event) {
      state = (id: _next++, event: event);
      // A paid request is money in: the balance and the list change.
      if (event.kind == IssuerEventKind.paid) ref.invalidate(homeProvider);
    }, onError: (_) {});
    ref.onDispose(events.cancel);
    return null;
  }
}

/// Drains the payments address when a wallet opens and, through [PaymentsDrainNotifier.drain],
/// on every resume, beside the listener: payments that arrived while the app was away are
/// finalized and posted on return. Holds the last drain's report.
final paymentsDrainProvider =
    NotifierProvider<PaymentsDrainNotifier, PaymentsDrainReport?>(
      PaymentsDrainNotifier.new,
    );

class PaymentsDrainNotifier extends Notifier<PaymentsDrainReport?> {
  bool _running = false;

  @override
  PaymentsDrainReport? build() {
    final session = _invoiceSession(ref);
    // Subscribed before the first drain, so its events reach a notice.
    ref.listen(issuerNoticeProvider, (_, _) {});
    // Leaving Offline drains what arrived meanwhile.
    final offline = ref.watch(networkModeProvider) == NetworkMode.offline;
    if (session != null && !offline) Future<void>.delayed(Duration.zero, drain);
    return null;
  }

  /// One drain, unless one is running. Failures are logged; the next resume tries again.
  Future<void> drain() async {
    if (!ref.mounted || _running) return;
    final session = ref.read(sessionProvider);
    if (session == null || ref.read(invoiceSessionProvider) != session || NetGate.offline) return;
    _running = true;
    try {
      final report = await session.drainPayments();
      if (!ref.mounted || ref.read(sessionProvider) != session) return;
      state = report;
      if (report.received > 0 || report.finalized > 0) {
        ref.invalidate(homeProvider);
      }
    } catch (error) {
      logWarn(
        'invoices',
        'payments drain failed: ${describeError(englishStrings, error)}',
      );
    } finally {
      _running = false;
    }
  }
}
