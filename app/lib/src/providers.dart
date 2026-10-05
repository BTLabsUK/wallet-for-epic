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
    this.stopped = false,
    this.status,
    this.last,
  });

  /// Subscribed at the relay, so incoming payments and responses arrive.
  final bool connected;

  /// Was connected, lost the connection, and is retrying.
  final bool lost;

  /// The core stopped the listener. It does not retry, and the header shows no epicbox row.
  final bool stopped;

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

/// How long [ListenerNotifier.restart] waits for the old listener to report it stopped before
/// it starts a new one anyway.
const Duration listenerStopWait = Duration(seconds: 5);

class ListenerNotifier extends Notifier<ListenerState> {
  StreamSubscription<ListenerEvent>? _events;

  /// Completes when the current listener's stream reports `stopped` or ends.
  Completer<void>? _ended;
  bool _restarting = false;

  static const String _connecting = 'Connecting to the epicbox relay…';

  @override
  ListenerState build() {
    final session = ref.watch(sessionProvider);
    ref.onDispose(() => _events?.cancel());
    if (session == null) return const ListenerState();
    _listen(session);
    return const ListenerState(status: _connecting);
  }

  void _listen(WalletSession session) {
    final ended = _ended = Completer<void>();
    void end() {
      if (!ended.isCompleted) ended.complete();
    }

    // An error already said Offline; the stream's end after it changes nothing.
    var failed = false;
    late final StreamSubscription<ListenerEvent> events;
    events = session.startListener().listen(
      (event) {
        if (event.kind == ListenerEventKind.stopped) end();
        // A listener being replaced by [restart] no longer speaks for the wallet.
        if (identical(_events, events)) _onEvent(event);
      },
      onError: (Object error) {
        if (!identical(_events, events)) return;
        failed = true;
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
    if (session == null || _restarting) return;
    _restarting = true;
    final old = _events;
    final ended = _ended;
    _events = null;
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
/// hand-offs of the same text apart.
typedef RecipientHandoff = ({int id, String text});

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

  void hand(String text) => state = (id: _next++, text: text);

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
WalletSession? _invoiceSession(Ref ref) {
  final session = ref.watch(sessionProvider);
  return session != null && session.supportsInvoices ? session : null;
}

/// Pending invoices of the open wallet, oldest first. The first read drains the invoice
/// address, and so does [PendingInvoicesNotifier.refresh] (pull to refresh, opening the
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
    final report = await session.drainInvoices();
    if (!ref.mounted) return const [];
    if (report.dropped > 0) {
      ref.read(droppedInvoiceMessagesProvider.notifier).add(report.dropped);
    }
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

/// Messages the drains of this session dropped unread (senders not on the list, notices from
/// anyone but the invoice's service). Shown under Advanced only; the user is never told.
final droppedInvoiceMessagesProvider =
    NotifierProvider<DroppedInvoiceMessagesNotifier, int>(
      DroppedInvoiceMessagesNotifier.new,
    );

class DroppedInvoiceMessagesNotifier extends Notifier<int> {
  @override
  int build() {
    ref.watch(sessionProvider);
    return 0;
  }

  void add(int dropped) => state += dropped;
}

/// The invoice address the user hands to services, or null without invoices.
final invoiceAddressProvider = FutureProvider.autoDispose<String?>((ref) {
  final session = _invoiceSession(ref);
  return session?.invoiceAddress();
});

/// Moves to a new invoice address. The old one is abandoned: services need the new one.
Future<String> rotateInvoiceAddress(WidgetRef ref) async {
  final session = ref.read(sessionProvider);
  if (session == null) throw StateError('Wallet is locked');
  final address = await session.rotateInvoiceAddress();
  logInfo('invoices', 'invoice address rotated');
  ref.invalidate(invoiceAddressProvider);
  return address;
}

/// Trusted services with the user's labels from `wfe_meta.json`.
final trustedServicesProvider =
    AsyncNotifierProvider.autoDispose<
      TrustedServicesNotifier,
      List<TrustedService>
    >(TrustedServicesNotifier.new);

class TrustedServicesNotifier extends AsyncNotifier<List<TrustedService>> {
  @override
  Future<List<TrustedService>> build() async {
    final session = _invoiceSession(ref);
    if (session == null) return const [];
    return session.trustedServices();
  }

  WalletSession get _session =>
      _invoiceSession(ref) ?? (throw StateError('No wallet with invoices'));

  /// Allows the service at [address] under [label]. Throws [WalletError] for an address that
  /// is not an epicbox address.
  Future<TrustedService> add({
    required String address,
    required String label,
  }) async {
    final added = await _session.addTrustedService(
      address: address,
      label: label,
    );
    logInfo('invoices', 'trusted service added');
    ref.invalidateSelf();
    await future;
    return added;
  }

  Future<void> remove(String address) async {
    await _session.removeTrustedService(address: address);
    logInfo('invoices', 'trusted service removed');
    ref.invalidateSelf();
    await future;
  }
}

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
    final events = session
        .issuerEvents()
        .where((e) => e.kind != IssuerEventKind.bounced)
        .listen((_) => ref.invalidateSelf(), onError: (_) {});
    ref.onDispose(events.cancel);
    return session.issuedInvoices();
  }

  WalletSession get _session =>
      _invoiceSession(ref) ?? (throw StateError('No wallet with invoices'));

  /// Asks the payer at [address] for [amount]. Throws [WalletError] for an address that
  /// cannot take it, or when the relay did not.
  Future<IssuedInvoice> issue({
    required BigInt amount,
    required String address,
    String? message,
  }) async {
    final issued = await _session.issueInvoice(
      amount: amount,
      address: address,
      message: message,
    );
    ref.invalidateSelf();
    await future;
    return issued;
  }

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

/// The latest issuer event of the open wallet: paid, declined, withdrawn, expired, or a
/// drain's bounces. Kept alive by [paymentsDrainProvider], so no event of a drain is missed.
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
    if (session != null) Future<void>.delayed(Duration.zero, drain);
    return null;
  }

  /// One drain, unless one is running. Failures are logged; the next resume tries again.
  Future<void> drain() async {
    if (!ref.mounted || _running) return;
    final session = ref.read(sessionProvider);
    if (session == null || !session.supportsInvoices) return;
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
