import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'errors.dart';
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
  (ref) => const RustWalletService(),
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

final vaultCryptoProvider = Provider<VaultCrypto>(
  (ref) => const RustVaultCrypto(),
);

final vaultProvider = Provider<WalletVault>(
  (ref) => WalletVault(
    store: ref.watch(secretStoreProvider),
    biometrics: ref.watch(biometricStoreProvider),
    crypto: ref.watch(vaultCryptoProvider),
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
    state = session;
  }

  /// Disposes the open wallet, which also frees its chain for another network.
  void lock() {
    final previous = state;
    state = null;
    previous?.dispose();
  }
}

WalletSession _requireSession(Ref ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) throw StateError('Wallet is locked');
  return session;
}

class HomeData {
  const HomeData({required this.summary, required this.transactions});

  final WalletSummary summary;
  final List<TxEntry> transactions;
}

/// Balances and the transaction log of the open wallet.
final homeProvider = AsyncNotifierProvider.autoDispose<HomeNotifier, HomeData>(
  HomeNotifier.new,
);

class HomeNotifier extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final session = _requireSession(ref);
    final summary = await session.summary(
      refresh: true,
      minimumConfirmations: minimumConfirmations,
    );
    final transactions = await session.transactions(refresh: false);
    return HomeData(summary: summary, transactions: transactions);
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

class ScanState {
  const ScanState({
    this.running = false,
    this.percent,
    this.message,
    this.error,
  });

  final bool running;
  final int? percent;
  final String? message;
  final String? error;
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
    state = const ScanState(running: true, message: 'Starting scan');
    // The core ends every scan with a `finished` event; on failure its message starts with
    // "Scan failed:" and the stream then closes with the error as well.
    String? failure;
    try {
      await for (final progress in session.scan(startHeight: startHeight)) {
        if (!ref.mounted) return false;
        if (progress.finished &&
            progress.message.startsWith(scanFailedPrefix)) {
          failure = progress.message;
          continue;
        }
        state = ScanState(
          running: !progress.finished,
          percent: progress.percent ?? state.percent,
          message: progress.message,
        );
      }
    } catch (error) {
      failure ??= describeError(error);
    }
    if (!ref.mounted) return false;
    if (failure != null) {
      state = ScanState(error: failure);
      return false;
    }
    state = ScanState(message: state.message);
    return true;
  }
}

/// First-run wallet creation, which runs while the user picks a PIN.
class WalletSetup {
  const WalletSetup({this.config, this.session, this.error});

  final WalletConfig? config;

  /// The created (or, after an interrupted first run, reopened) wallet.
  final WalletSession? session;
  final Object? error;

  bool get running => config != null && session == null && error == null;
}

final walletSetupProvider = NotifierProvider<WalletSetupNotifier, WalletSetup>(
  WalletSetupNotifier.new,
);

class WalletSetupNotifier extends Notifier<WalletSetup> {
  Future<String>? _password;
  Future<void>? _task;

  @override
  WalletSetup build() => const WalletSetup();

  /// Starts creating the wallet for [config] with a new random password. The password is stored
  /// before the wallet exists, so an interrupted first run resumes by opening that wallet.
  void start(WalletConfig config) {
    if (_task != null && state.config?.dataDir == config.dataDir) return;
    final vault = ref.read(vaultProvider);
    final password = vault.pendingPassword(config.chain);
    _password = password;
    state = WalletSetup(config: config);
    _task = _create(config, password);
  }

  Future<void> _create(WalletConfig config, Future<String> password) async {
    final service = ref.read(walletServiceProvider);
    try {
      final secret = await password;
      final session = await service.walletExists(config: config)
          ? await service.open(config: config, password: secret)
          : await service.create(config: config, password: secret);
      if (!ref.mounted || state.config?.dataDir != config.dataDir) {
        session.dispose();
        return;
      }
      state = WalletSetup(config: config, session: session);
    } catch (error) {
      if (ref.mounted && state.config?.dataDir == config.dataDir) {
        state = WalletSetup(config: config, error: error);
      }
    }
  }

  /// Tries the creation again after [WalletSetup.error], with the same password.
  void retry() {
    final config = state.config;
    var password = _password;
    if (config == null || password == null || state.error == null) return;
    // A failed read of the secure store is retried; a stored password is reused.
    password = password.catchError(
      (Object _) => ref.read(vaultProvider).pendingPassword(config.chain),
    );
    _password = password;
    state = WalletSetup(config: config);
    _task = _create(config, password);
  }

  /// Seals the password under [pin], and with [useBiometrics] also stores the biometric copy
  /// (which prompts). Then waits for the wallet and returns it. Returns whether biometrics were
  /// enabled.
  Future<({WalletSession session, bool biometrics})> finish({
    required String pin,
    required bool useBiometrics,
  }) async {
    if (state.error != null) retry();
    final config = state.config;
    final password = _password;
    if (config == null || password == null) {
      throw StateError('Setup not started');
    }
    final vault = ref.read(vaultProvider);
    final biometrics = await vault.seal(
      config.chain,
      pin: pin,
      password: await password,
      useBiometrics: useBiometrics,
    );
    await _task;
    final session = state.session;
    if (session == null) throw state.error ?? StateError('Wallet not created');
    _reset();
    return (session: session, biometrics: biometrics);
  }

  /// Stops caring about the wallet being set up, keeping its files and pending password. A
  /// later first run on this chain opens it again.
  Future<void> abandon() async {
    await _task;
    state.session?.dispose();
    _reset();
  }

  /// Deletes the wallet being set up, for a restore in its place. Safe because its phrase was
  /// never shown, so it cannot hold funds. Only a wallet still waiting for its PIN counts: one
  /// with a PIN, or one opened by password (made before PINs existed), is left alone.
  Future<void> discard(WalletConfig config) async {
    if (state.config?.dataDir == config.dataDir) {
      await _task;
      state.session?.dispose();
      _reset();
    }
    final vault = ref.read(vaultProvider);
    if (await vault.stage(config.chain) != VaultStage.pending) return;
    final service = ref.read(walletServiceProvider);
    if (await service.walletExists(config: config)) {
      await service.deleteWallet(config: config);
    }
    await vault.forget(config.chain);
  }

  void _reset() {
    _task = null;
    _password = null;
    state = const WalletSetup();
  }
}

/// What the epicbox listener of the open wallet is doing.
class ListenerState {
  const ListenerState({this.connected = false, this.status, this.last});

  /// Subscribed at the relay, so incoming payments and responses arrive.
  final bool connected;

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
      onError: (Object error) =>
          state = ListenerState(status: describeError(error), last: state.last),
    );
    return const ListenerState(status: 'Connecting to the epicbox relay…');
  }

  void _onEvent(ListenerEvent event) {
    switch (event.kind) {
      case ListenerEventKind.connected:
        state = ListenerState(connected: true, last: state.last);
      case ListenerEventKind.disconnected:
        state = ListenerState(
          status: 'Reconnecting to the relay: ${event.message}',
          last: state.last,
        );
      case ListenerEventKind.stopped:
        state = ListenerState(status: 'Listener stopped', last: state.last);
      case ListenerEventKind.received ||
          ListenerEventKind.finalized ||
          ListenerEventKind.error:
        state = ListenerState(
          connected: state.connected,
          status: state.status,
          last: event,
        );
        if (event.kind != ListenerEventKind.error) {
          ref.invalidate(homeProvider);
        }
    }
  }
}
