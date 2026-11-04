// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'trust/contact_trust.dart' show peerCompatRetention;
import 'wallet/held_coins.dart' show heldSpendable;
import 'wallet/upkeep.dart' show releaseSenderCancelled, resendUndelivered, retrySpendBack, retryStalled;
import 'dev_networks.dart';
import 'server_list_file.dart' show useServerValues;
import 'settings_file/settings_providers.dart';
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
import 'cancel_final.dart';
import 'sender_cancel.dart';
import 'stall_retry.dart';
import 'watch_mode.dart' show BlockWatch;
import 'vault.dart';
import 'wallet_backend.dart' as backend;
import 'wallet_service.dart';

export 'models.dart' show defaultMinimumConfirmations;
import 'phrase_clipboard.dart';
import 'settings_file/host_settings.dart' show appConfig;
import 'pairing_providers.dart' show invoiceSessionProvider;
import 'devices/device_service.dart' show DeviceSyncTrigger;
import 'devices/phone_devices.dart' show deviceServiceProvider;

final BigInt minimumConfirmations = BigInt.from(defaultMinimumConfirmations);

/// The fallback the app counts with before the first balance: [minimumConfirmations].
final minimumConfirmationsProvider = Provider<BigInt>((ref) => minimumConfirmations);

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

/// `<application support>/wallets/<chain>` on a device; a fixed name
/// per chain on the web.
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

/// The network the app runs on (saved, a dev build only), and the node and Epicbox server
/// every wallet uses there: `node.use` and `epicbox.use` of the chain's settings file, shared
/// by every wallet, never a wallet's own.
final networkChoiceProvider =
    AsyncNotifierProvider<NetworkChoiceNotifier, NetworkChoice>(
      NetworkChoiceNotifier.new,
    );

class NetworkChoiceNotifier extends AsyncNotifier<NetworkChoice> {
  /// The chain a dev build runs on; mainnet when none (every release build).
  static const String networkKey = 'app.network';

  /// The chain a dev build chose last time ([networkKey]); mainnet in a release build, unless
  /// [anyBuild] (the saved choice as it is).
  static Future<Chain> savedChain(SecretStore store, {bool anyBuild = false}) async {
    if (!devNetworksBuild && !anyBuild) return Chain.mainnet;
    final saved = await store.read(networkKey);
    return Chain.values.where((c) => c.name == saved).firstOrNull ?? Chain.mainnet;
  }

  @override
  Future<NetworkChoice> build() async {
    // Only the two picks: a list edited elsewhere in the file changes no choice.
    final (node, relay) = ref.watch(hostSettingsProvider.select((s) => (s.nodeUse, s.epicboxUse)));
    final chain = await savedChain(ref.watch(secretStoreProvider), anyBuild: true);
    return NetworkChoice(preset: presetOf(chain), nodeUrl: node, relay: _relayOf(relay));
  }

  static EpicboxRelay _relayOf(String label) => EpicboxRelay.parse(label) ?? EpicboxRelay(host: label);

  /// The Epicbox server every wallet uses (`epicbox.use`).
  Future<EpicboxRelay> relayFor(NetworkPreset preset) async => _relayOf(ref.read(hostSettingsProvider).epicboxUse);

  /// Opens [chain]'s settings (a dev chain's own file) and saves it as the network of the next
  /// start. Throws [DevSettingsMissing] when a dev chain has no file; nothing changes then.
  Future<void> switchChain(Chain chain) async {
    final store = ref.read(secretStoreProvider);
    // Without a settings file open (tests), the settings in use stay.
    if (installedSettingsFile != null) await openAppSettings(store: store, devChain: devChainOf(chain));
    await store.write(networkKey, chain.name);
    ref.invalidateSelf();
  }

  /// Moves [nodeUrl] and [relay] to the top of their lists in `settings.toml`: every wallet uses
  /// the first of each.
  Future<void> save(
    NetworkPreset preset,
    String nodeUrl, {
    EpicboxRelay? relay,
  }) async {
    final r = relay ?? await relayFor(preset);
    final values = useServerValues(ref.read(hostSettingsProvider), node: nodeUrl, relay: r.label);
    if (values.isNotEmpty) await ref.read(hostSettingsProvider.notifier).setAll(values);
    logInfo(
      'network',
      // Logs reach support reports: mainnet is never named there.
      '${preset.chain == Chain.mainnet ? '' : '${preset.chain.name}, '}node ${Uri.tryParse(nodeUrl)?.host ?? '?'}, relay ${r.label}',
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

/// Whether the wallet opens with a passphrase instead of the PIN ([WalletVault.usesPassphrase]).
/// Invalidated after a PIN or passphrase change.
final usesPassphraseProvider = FutureProvider<bool>((ref) async {
  final chain = ref.watch(walletConfigProvider.select((c) => c?.chain));
  if (chain == null) return false;
  return ref.watch(vaultProvider).usesPassphrase(chain);
});

/// Whether the wallet ever had a passphrase ([WalletVault.passphraseEverUsed]): only then does
/// the unlock screen offer to switch between PIN and passphrase entry.
final passphraseEverUsedProvider = FutureProvider<bool>((ref) async {
  final chain = ref.watch(walletConfigProvider.select((c) => c?.chain));
  if (chain == null) return false;
  return ref.watch(vaultProvider).passphraseEverUsed(chain);
});

/// The node in use is on this phone or the local network (`net/local_address.dart`): Node only
/// does not say that File and QR payments use a public node.
final localNodeProvider = Provider<bool>(
  (ref) => isLocalAddressUrl(ref.watch(walletConfigProvider.select((c) => c?.nodeUrl))),
);

/// The local node's peer count while Node only ([nodePeerCount]); null otherwise or when it
/// does not say. With 0 a payment waits in the node's pool until it reconnects.
final offlineNodePeersProvider = FutureProvider.autoDispose<int?>((ref) async {
  final url = ref.watch(walletConfigProvider.select((c) => c?.nodeUrl));
  if (ref.watch(networkModeProvider) != NetworkMode.nodeOnly || url == null || !isLocalAddressUrl(url)) return null;
  return nodePeerCount(url);
});

/// The balance and history show as last known: Kill switch asks no node, so Home reads the
/// wallet's own files only and the screens mark them so.
final balanceLastKnownProvider = Provider<bool>((ref) => ref.watch(networkModeProvider) == NetworkMode.killSwitch);

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
    if (!identical(previous, session)) {
      logInfo('session', 'wallet unlocked');
      // What the wallet learned about keys silent since: dropped on every open.
      unawaited(
        session
            .forgetPeers(olderThan: peerCompatRetention)
            .catchError((Object e) => logDebug('session', 'peers not pruned: ${e.runtimeType}')),
      );
    }
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

/// The automatic release of incoming payments their senders cancelled ([SenderCancelRelease])
/// for the open wallet, kept across reloads.
final senderCancelReleaseProvider = Provider<SenderCancelRelease>((ref) {
  ref.watch(sessionProvider);
  return SenderCancelRelease();
});

/// The open wallet's cancels, with the spends back still owed ([CancelFinal]), kept across
/// reloads.
final cancelFinalProvider = Provider<CancelFinal>((ref) {
  ref.watch(sessionProvider);
  return CancelFinal();
});

class HomeNotifier extends AsyncNotifier<HomeData> {
  bool _enriching = false;

  /// Counts the builds. The notifier lives on across rebuilds, so `ref.mounted` stays true
  /// after a reload replaced a build; [_current] tells whether one is still the newest.
  int _build = 0;

  bool _current(int gen) => gen == _build && ref.mounted;

  @override
  Future<HomeData> build() async {
    final gen = ++_build;
    final session = _requireSession(ref);
    // Kill switch reads the wallet's own files only (the last known balance and history);
    // leaving it refreshes against the node again. Node only refreshes against the node in use.
    final mode = ref.watch(networkModeProvider);
    final offline = mode == NetworkMode.killSwitch;
    await _followKillSwitch(session, offline);
    final shown = state.value;
    if (!offline && shown != null && identical(shown.session, session)) {
      return _refreshed(session, gen);
    }
    final summary = await _withHeld(
      session,
      await session.summary(
        refresh: false,
        minimumConfirmations: ref.read(minimumConfirmationsProvider),
      ),
    );
    final transactions = await session.transactions(refresh: false);
    if (offline || !_current(gen)) {
      // A newer build replaced this one before it was shown: that one refreshes.
      return HomeData(summary: summary, transactions: transactions, session: session);
    }
    Future<void>.delayed(Duration.zero, () => _syncInBackground(session, gen));
    // Epicbox resends wait for Node only to end.
    if (mode != NetworkMode.nodeOnly) unawaited(_retryUndelivered(session, transactions));
    return HomeData(
      summary: summary,
      transactions: transactions,
      syncing: true,
      session: session,
    );
  }

  /// Kill switch makes the open session an offline one and leaving it an online one again
  /// ([WalletConfig.offline], through LEPIC's live server switch), once the wallet core takes
  /// it ([walletOfflineSessions]). A refusal is logged; the app's gate holds either way.
  Future<void> _followKillSwitch(WalletSession session, bool kill) async {
    final opened = ref.read(walletConfigProvider);
    if (!walletOfflineSessions || opened == null || opened.offline == kill) return;
    final next = opened.withOffline(kill);
    try {
      await session.setServers(config: next);
    } on WalletError catch (e) {
      logWarn('network', 'kill switch session not switched: ${e.kind.name}');
      return;
    }
    if (ref.mounted && ref.read(sessionProvider) == session) ref.read(walletConfigProvider.notifier).select(next);
  }

  /// [summary] with the coins a linked device is spending ([WalletSession.heldOutputs]) moved
  /// from spendable to locked: the core can spend them, but this wallet holds them back.
  Future<WalletSummary> _withHeld(WalletSession session, WalletSummary summary) async {
    final held = session.heldOutputs;
    if (held.isEmpty) return summary;
    BigInt value;
    try {
      value = await heldSpendable(session, held);
    } catch (error) {
      logWarn('home', 'held coins not read: ${error.runtimeType}');
      return summary;
    }
    if (value == BigInt.zero) return summary;
    return WalletSummary(
      lastConfirmedHeight: summary.lastConfirmedHeight,
      minimumConfirmations: summary.minimumConfirmations,
      total: summary.total,
      spendable: summary.spendable - value,
      awaitingConfirmation: summary.awaitingConfirmation,
      awaitingFinalization: summary.awaitingFinalization,
      immature: summary.immature,
      locked: summary.locked + value,
      validatedWithNode: summary.validatedWithNode,
    );
  }

  /// Refreshes against the node, publishing its progress in [syncProgressProvider], and reads
  /// the list. Build [gen]'s refresh stops once a newer build replaced it.
  Future<HomeData> _refreshed(WalletSession session, int gen) async {
    final progress = ref.read(syncProgressProvider.notifier);
    WalletSummary? summary;
    try {
      await for (final step in session.refresh(
        minimumConfirmations: ref.read(minimumConfirmationsProvider),
      )) {
        // A reload replaced this one; it shows its own progress.
        if (!_current(gen)) throw StateError('Refresh replaced');
        progress.report(step.percent);
        summary = step.summary ?? summary;
      }
    } finally {
      if (ref.mounted) progress.report(null);
    }
    if (summary == null) throw StateError('Refresh ended without balances');
    summary = await _withHeld(session, summary);
    // A refresh reads the linked devices' notices too, and sweeps their holds against
    // the chain just read.
    unawaited(ref.read(deviceServiceProvider)?.sync(DeviceSyncTrigger.refresh));
    final transactions = await session.transactions(refresh: false);
    ref.read(blockWatchProvider).saw(transactions, summary.lastConfirmedHeight, now: ref.read(clockProvider)());
    // Heights and dates for history rows come afterwards, so they never hold up the balance.
    Future<void>.delayed(Duration.zero, () => _enrich(session));
    unawaited(_retryStalled(session, transactions));
    unawaited(_releaseSenderCancelled(session, transactions));
    unawaited(_retrySpendBack(session));
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
    final retried = await resendUndelivered(session, transactions, tag: 'home');
    if (retried && ref.mounted) unawaited(reload());
  }

  /// Posts again a payment the chain has not taken and sends again a paid invoice's answer
  /// when the shared policy says it is due (stall_retry.dart), then reads the list again.
  Future<void> _retryStalled(
    WalletSession session,
    List<TxEntry> transactions,
  ) async {
    if (!ref.mounted) return;
    final sent = await retryStalled(ref.read(stallRetryProvider), session, transactions, ref.read(clockProvider)(), tag: 'home');
    if (sent && ref.mounted) unawaited(reload());
  }

  /// Releases the incoming payments their senders cancelled (sender_cancel.dart), then reads
  /// the list again when any was. A failed release is tried again at the next refresh.
  Future<void> _releaseSenderCancelled(
    WalletSession session,
    List<TxEntry> transactions,
  ) async {
    if (!ref.mounted) return;
    final released = await releaseSenderCancelled(ref.read(senderCancelReleaseProvider), session, transactions, tag: 'home');
    await _relistAfter(released);
  }

  /// Reads the list again after an automatic change [done]; a failure is logged.
  Future<void> _relistAfter(bool done) async {
    if (!done || !ref.mounted) return;
    try {
      await relist();
    } catch (error) {
      logWarn('home', 'list not read again: ${error.runtimeType}');
    }
  }

  /// Spends back the coins of a payment cancelled while the wallet is open whose spend back
  /// failed (cancel_final.dart), then reads the list again when one went.
  Future<void> _retrySpendBack(WalletSession session) async {
    await _relistAfter(await retrySpendBack(ref.read(cancelFinalProvider), session, tag: 'home'));
  }

  /// A payment's sender reports it cancelled ([paymentCancelledProvider]): the row says so at
  /// once, and the payment is released if it still waits.
  Future<void> senderCancelled() async {
    await relist();
    final shown = state.value;
    final session = shown?.session;
    if (!ref.mounted || shown == null || session == null) return;
    await _releaseSenderCancelled(session, shown.transactions);
  }

  /// The refresh after a local first load. A failure keeps the local figures and shows the
  /// error; a reload that started meanwhile replaces this one.
  Future<void> _syncInBackground(WalletSession session, int gen) async {
    if (!_current(gen)) return;
    try {
      final data = await _refreshed(session, gen);
      if (_current(gen)) state = AsyncData(data);
    } catch (error, stack) {
      if (!_current(gen)) return;
      logWarn(
        'sync',
        'refresh failed: ${describeError(englishStrings, error)}',
      );
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
  /// Reads the balance again from the wallet's own files, keeping the list, so a changed
  /// minimum confirmations re-splits spendable and confirming at once, without the node.
  /// Nothing while a load runs: that one reads the balance itself.
  Future<void> resummarize() async {
    final shown = state.value;
    final session = shown?.session;
    if (state.isLoading || shown == null || session == null) return;
    final summary = await session.summary(
      refresh: false,
      minimumConfirmations: ref.read(minimumConfirmationsProvider),
    );
    if (!ref.mounted || state.isLoading || !identical(state.value?.session, session)) return;
    final now = state.requireValue;
    state = AsyncData(
      HomeData(
        summary: summary,
        transactions: now.transactions,
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
  if (ref.watch(networkModeProvider) == NetworkMode.killSwitch) {
    throw const NetBlocked(NetworkMode.killSwitch, 'node tip');
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
  // Kill switch asks no node, also before a wallet is open; Node only none but the one in use.
  NetGate.dial(NetDial.http, config.nodeUrl);
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

  /// A server switch under way ([duringSwitch]); completes when it is done.
  Completer<void>? _switch;

  /// A server switch began since the scan's stream started: the stream it cancelled may end
  /// just before or just after the switch returns.
  bool _switched = false;

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

  /// Runs [switchServers], the open wallet's [WalletSession.setServers], which cancels a running
  /// scan (LN-01). That scan, a restore's or a Recheck balance, goes on once the switch returns,
  /// with the same start, as after a [pause]; a [stop] meanwhile still stops it.
  Future<T> duringSwitch<T>(Future<T> Function() switchServers) async {
    final done = _switch = Completer<void>();
    _switched = true;
    try {
      return await switchServers();
    } finally {
      if (identical(_switch, done)) _switch = null;
      done.complete();
    }
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
    // Recheck balance asks the node: Kill switch refuses it before it starts.
    if (NetGate.killSwitch) {
      state = const ScanState(error: NetBlocked(NetworkMode.killSwitch, 'scan'));
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
      _switched = _switch != null;
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
      // A server switch cancelled it: the same scan goes on once the switch is done.
      if (!finished && !_stopping && _switched) {
        for (var pending = _switch; pending != null; pending = _switch) {
          await pending.future;
        }
        if (!ref.mounted || !identical(ref.read(sessionProvider), session)) return false;
        if (_stopping) break;
        logInfo('scan', 'goes on after the server switch');
        state = ScanState(running: true, resuming: true, percent: state.percent);
        continue;
      }
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
    // Ended without the core's `finished` event: stopped from elsewhere (a lock, a cancel), as
    // the desktop reads it. Only a scan that reached its end says the balance was rechecked.
    if (!finished) {
      logInfo('scan', 'ended before its end: stopped');
      state = const ScanState(stopped: true);
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
    this.retrying = false,
  });

  /// Subscribed at the relay, so incoming payments and responses arrive.
  final bool connected;

  /// Was connected, lost the connection, and is retrying.
  final bool lost;

  /// Started again by the app after a loss ([ListenerNotifier.restart] quiet), not yet connected:
  /// it reads as the loss did, not as a new connection.
  final bool retrying;

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
Duration get listenerHealAfter => appConfig.listenerHealAfter;

/// The longest wait between two self-heal restarts of a listener that does not connect.
Duration get listenerHealMax => appConfig.listenerHealMax;

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
    // Node only and Kill switch: nothing listens; leaving them rebuilds this, which starts the
    // listener again.
    if (ref.watch(networkModeProvider.select((m) => m == NetworkMode.nodeOnly || m == NetworkMode.killSwitch))) {
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
      unawaited(restart(quiet: true));
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
    await restart(quiet: true);
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
  /// [listenerStopWait]. A [quiet] restart (no one asked for it) of a lost connection is marked
  /// [ListenerState.retrying], so the header holds one state while it retries instead of
  /// flickering to connecting.
  Future<void> restart({bool quiet = false}) async {
    final session = ref.read(sessionProvider);
    if (session == null || _restarting || state.offline) return;
    _restarting = true;
    final old = _events;
    final ended = _ended;
    _events = null;
    _block.reset();
    state = ListenerState(status: _connecting, last: state.last, retrying: quiet && (state.lost || state.retrying));
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
      case ListenerEventKind.repeated:
        // The same message again: LEPIC re-sent the first answer. Log only; it must not take
        // `last`, or it would replace the received payment's notice.
        logInfo('listener', 'repeated slate ${event.slateId ?? ''}');
      case ListenerEventKind.received ||
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

  /// The linked device heard the sender's report instead ([DeviceService.forwarded]): the
  /// same list read and chain check.
  Future<void> forwarded(InvoiceEvent event) => _onPosted(event);

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

/// The latest report from the sender of a payment this wallet answered that it cancelled it
/// (LEPIC's `paymentCancelled`). Each report shows on its row at once and releases the payment
/// if it still waits ([HomeNotifier.senderCancelled]); one the network has already stays.
final paymentCancelledProvider =
    NotifierProvider<PaymentCancelledNotifier, InvoiceEvent?>(
      PaymentCancelledNotifier.new,
    );

class PaymentCancelledNotifier extends Notifier<InvoiceEvent?> {
  @override
  InvoiceEvent? build() {
    final session = ref.watch(sessionProvider);
    if (session == null) return null;
    final events = session
        .invoiceEvents()
        .where((e) => e.kind == InvoiceEventKind.paymentCancelled)
        .listen((e) => unawaited(_onCancelled(e)), onError: (_) {});
    ref.onDispose(events.cancel);
    return null;
  }

  /// The linked device heard the sender's report instead ([DeviceService.forwarded]); the
  /// service dropped this device's answer, so only the list is read again.
  Future<void> forwarded(InvoiceEvent event) => _onCancelled(event);

  Future<void> _onCancelled(InvoiceEvent event) async {
    logInfo('home', 'sender reports a payment cancelled');
    try {
      await ref.read(homeProvider.notifier).senderCancelled();
    } catch (error) {
      logInfo('home', 'list not read: ${error.runtimeType}');
    }
    if (ref.mounted) state = event;
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
    // Node only and Kill switch collect nothing: the invoices already in the wallet show;
    // leaving them collects.
    if (ref.watch(networkModeProvider.select((m) => m == NetworkMode.nodeOnly || m == NetworkMode.killSwitch))) {
      return _unexpired(await session.pendingInvoices());
    }
    final report = await session.collectInvoices();
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

  /// Collects the paired contacts' mailboxes again and reloads the list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Reads the wallet's waiting invoices again without a collect: one a background collect
  /// of the contacts' mailboxes parked, or a collect's own event.
  Future<void> reload() async {
    final session = _invoiceSession(ref);
    if (session == null || !state.hasValue) return;
    final fresh = await session.pendingInvoices();
    if (ref.mounted) state = AsyncData(_unexpired(fresh));
  }

  /// Takes an invoice the user paid or declined off the list, without another collect.
  void answered(String slateId) {
    final shown = state.value;
    if (shown == null) return;
    state = AsyncData([
      for (final i in shown)
        if (i.slateId != slateId) i,
    ]);
  }
}

/// How many pending invoices wait, for Home's badge. 0 until the first collect is done.
final pendingInvoiceCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(pendingInvoicesProvider).value?.length ?? 0,
);

/// The invoice behind the transaction with that slate id, once paid, or null. Reloads when
/// a receipt or a withdrawal for it arrives: LEPIC reports those as events, which may come
/// after the collect that found them has returned.
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
    // Leaving Node only or Kill switch drains what arrived meanwhile.
    final offline = ref.watch(networkModeProvider.select((m) => m == NetworkMode.nodeOnly || m == NetworkMode.killSwitch));
    if (session != null && !offline) Future<void>.delayed(Duration.zero, drain);
    return null;
  }

  /// One drain, unless one is running. Failures are logged; the next resume tries again.
  Future<void> drain() async {
    if (!ref.mounted || _running) return;
    final session = ref.read(sessionProvider);
    if (session == null || ref.read(invoiceSessionProvider) != session || NetGate.restricted) return;
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
