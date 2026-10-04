import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app_log.dart';
import 'errors.dart';
import 'l10n.dart' show englishStrings;
import 'lepic_wallet_service.dart';
import 'network.dart';
import 'secret_store.dart';
import 'vault.dart';
import 'wallet_service.dart';

/// Confirmations before an output counts as spendable. epic-wallet's CLI default.
final BigInt minimumConfirmations = BigInt.from(10);

/// Resolves, and creates if missing, the data directory of the wallet for [chain].
typedef WalletDirResolver = Future<String> Function(Chain chain);

/// `<application support>/wallets/<chain>`. One wallet per chain.
Future<String> defaultWalletDir(Chain chain) async {
  final support = await getApplicationSupportDirectory();
  final sep = Platform.pathSeparator;
  final dir = Directory('${support.path}${sep}wallets$sep${chain.name}');
  await dir.create(recursive: true);
  return dir.path;
}

final walletServiceProvider = Provider<WalletService>(
  (ref) => LepicWalletService(secrets: ref.watch(secretStoreProvider)),
);

final walletDirProvider = Provider<WalletDirResolver>(
  (ref) => defaultWalletDir,
);

final secretStoreProvider = Provider<SecretStore>(
  (ref) => const PlatformSecretStore(),
);

final biometricStoreProvider = Provider<BiometricStore>(
  (ref) => PlatformBiometricStore(),
);

final vaultProvider = Provider<WalletVault>(
  (ref) => WalletVault(
    store: ref.watch(secretStoreProvider),
    biometrics: ref.watch(biometricStoreProvider),
    service: ref.watch(walletServiceProvider),
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
    if (previous != null) logInfo('session', 'wallet locked');
    previous?.dispose();
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

class HomeNotifier extends AsyncNotifier<HomeData> {
  bool _enriching = false;

  @override
  Future<HomeData> build() async {
    final session = _requireSession(ref);
    final shown = state.value;
    if (shown != null && identical(shown.session, session)) {
      return _refreshed(session);
    }
    final summary = await session.summary(
      refresh: false,
      minimumConfirmations: minimumConfirmations,
    );
    final transactions = await session.transactions(refresh: false);
    Future<void>.delayed(Duration.zero, () => _syncInBackground(session));
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
        minimumConfirmations: minimumConfirmations,
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
    final transactions = await session.transactions(refresh: false);
    // Heights and dates for history rows come afterwards, so they never hold up the balance.
    Future<void>.delayed(Duration.zero, () => _enrich(session));
    return HomeData(
      summary: summary,
      transactions: transactions,
      session: session,
    );
  }

  /// The refresh after a local first load. A failure keeps the local figures and shows the
  /// error; a reload that started meanwhile replaces this one.
  Future<void> _syncInBackground(WalletSession session) async {
    if (!ref.mounted) return;
    try {
      final data = await _refreshed(session);
      if (ref.mounted) state = AsyncData(data);
    } catch (error, stack) {
      logWarn('sync', 'refresh failed: ${describeError(englishStrings, error)}');
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
      logInfo('history', 'enrich failed: ${describeError(englishStrings, error)}');
    } finally {
      _enriching = false;
    }
  }

  /// Refreshes against the node. Completes with an error if the refresh failed.
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final addressProvider = FutureProvider.autoDispose<String>(
  (ref) => _requireSession(ref).epicboxAddress(),
);

final nodeTipProvider = FutureProvider.autoDispose<NodeTip>((ref) {
  final config = ref.watch(walletConfigProvider);
  if (config == null) throw StateError('No network selected');
  return ref.watch(walletServiceProvider).nodeTip(config: config);
});

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
  });

  final bool running;
  final int? percent;
  final String? message;

  /// Why the last scan failed, for `describeError`.
  final Object? error;

  /// The last scan finished without an error.
  final bool done;
}

/// A scan of the chain for the open wallet's outputs, with its latest progress.
final scanProvider = NotifierProvider<ScanNotifier, ScanState>(
  ScanNotifier.new,
);

class ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() {
    ref.watch(sessionProvider);
    return const ScanState();
  }

  /// Scans from [startHeight] until the core closes the stream. Returns true on success.
  Future<bool> run({BigInt? startHeight}) async {
    final session = ref.read(sessionProvider);
    if (session == null || state.running) return false;
    state = const ScanState(running: true);
    logInfo('scan', 'started from ${startHeight ?? 'the last scanned block'}');
    // The core ends every scan with a `finished` event; on failure its message starts with
    // "Scan failed:" and the stream then closes with the error as well, which wins.
    Object? failure;
    try {
      await for (final progress in session.scan(startHeight: startHeight)) {
        if (!ref.mounted) return false;
        if (progress.finished &&
            progress.message.startsWith(scanFailedPrefix)) {
          failure = ScanFailed(
            progress.message.substring(scanFailedPrefix.length).trim(),
          );
          continue;
        }
        state = ScanState(
          running: !progress.finished,
          percent: progress.percent ?? state.percent,
          message: progress.message,
        );
      }
    } catch (error) {
      failure = error;
    }
    if (!ref.mounted) return false;
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
    this.status,
    this.last,
  });

  /// Subscribed at the relay, so incoming payments and responses arrive.
  final bool connected;

  /// Was connected, lost the connection, and is retrying.
  final bool lost;

  /// Why it is not connected, when known.
  final String? status;

  /// The latest payment event (received, finalized or failed), for a one-off notice.
  final ListenerEvent? last;
}

/// Runs the epicbox listener while a wallet is open, and refreshes balances when it receives or
/// finalizes a transaction. It stops with the session.
final listenerProvider = NotifierProvider<ListenerNotifier, ListenerState>(
  ListenerNotifier.new,
);

class ListenerNotifier extends Notifier<ListenerState> {
  StreamSubscription<ListenerEvent>? _events;

  @override
  ListenerState build() {
    final session = ref.watch(sessionProvider);
    ref.onDispose(() => _events?.cancel());
    if (session == null) return const ListenerState();
    _events = session.startListener().listen(
      _onEvent,
      onError: (Object error) {
        logWarn('listener', 'stream failed: ${describeError(englishStrings, error)}');
        state = ListenerState(
          status: describeError(englishStrings, error),
          last: state.last,
        );
      },
    );
    return const ListenerState(status: 'Connecting to the epicbox relay…');
  }

  void _onEvent(ListenerEvent event) {
    switch (event.kind) {
      case ListenerEventKind.connected:
        state = ListenerState(connected: true, last: state.last);
      case ListenerEventKind.disconnected:
        state = ListenerState(
          lost: true,
          status: 'Reconnecting to the relay: ${event.message}',
          last: state.last,
        );
      case ListenerEventKind.stopped:
        state = ListenerState(status: 'Listener stopped', last: state.last);
      case ListenerEventKind.received ||
          ListenerEventKind.finalized ||
          ListenerEventKind.expired ||
          ListenerEventKind.delayed ||
          ListenerEventKind.error:
        state = ListenerState(
          connected: state.connected,
          lost: state.lost,
          status: state.status,
          last: event,
        );
        // An error about a payment may have changed it too (an expired send is cancelled).
        if (event.kind != ListenerEventKind.error || event.slateId != null) {
          ref.invalidate(homeProvider);
        }
    }
  }
}
