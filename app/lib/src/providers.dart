import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'errors.dart';
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

/// Network and data directory picked on the setup screen.
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
