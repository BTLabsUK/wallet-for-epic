// SPDX-License-Identifier: Apache-2.0
/// Riverpod state for the desktop UI: the API seam and one snapshot of the open wallet.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_service.dart' show DeviceSyncTrigger;
import '../../cancel_final.dart' show CancelResult;
import 'api.dart';
import 'devices_state.dart' show deskDeviceHandleProvider;
import 'desk_store.dart';
import 'mock_wallet.dart';
import 'node_switch.dart' show NodeSwitchStep, deskNodeSwitchProvider;
import 'models.dart';
import '../../providers.dart' show defaultMinimumConfirmations;
import '../../relay_directory.dart' show statusSite;
import '../../settings_file/network_mode_file.dart' show networkModeIn, saveNetworkMode;
import '../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../phrase_clipboard.dart';
import '../../tor_build.dart' show torBuilt;
import '../../tor_pay.dart';
import 'net_mode_view.dart' show torProcessState;

/// The wallet behind the desktop UI. Override with a LEPIC adapter to go live.
final deskApiProvider = Provider<DeskWalletApi>((ref) => MockDeskWallet());

/// Everything the screens show about the open wallet. Null fields are still loading.
class DeskState {
  const DeskState({
    this.account,
    this.balance,
    this.txs,
    this.contacts,
    this.status,
    this.nodes,
    this.epicboxes,
    this.settings = const DeskSettings(),
    this.epicboxAddress,
    this.wallets,
    this.oldHistory = const [],
    this.session = 0,
  });

  final WalletAccount? account;
  final Balance? balance;
  final List<Tx>? txs;
  final List<Contact>? contacts;
  final ServiceStatus? status;
  final List<NodeServer>? nodes;
  final List<EpicboxServer>? epicboxes;
  final DeskSettings settings;
  final String? epicboxAddress;
  final List<WalletEntry>? wallets;

  /// What the old wallet's history waits for the user to choose ("Details differ").
  final List<ImportConflict> oldHistory;

  /// The open wallet session's [DeskWalletApi.sessionRevision], as of the last unlock or reopen.
  final int session;

  /// File sends waiting for the recipient's response: the Activity badge.
  int get pendingFiles =>
      (txs ?? const []).where((t) => t.method == TxMethod.file && t.state == TxState.waitingRecipient && !t.incoming).length;

  DeskState copyWith({
    WalletAccount? account,
    Balance? balance,
    List<Tx>? txs,
    List<Contact>? contacts,
    ServiceStatus? status,
    List<NodeServer>? nodes,
    List<EpicboxServer>? epicboxes,
    DeskSettings? settings,
    String? epicboxAddress,
    List<WalletEntry>? wallets,
    List<ImportConflict>? oldHistory,
    int? session,
  }) => DeskState(
    account: account ?? this.account,
    balance: balance ?? this.balance,
    txs: txs ?? this.txs,
    contacts: contacts ?? this.contacts,
    status: status ?? this.status,
    nodes: nodes ?? this.nodes,
    epicboxes: epicboxes ?? this.epicboxes,
    settings: settings ?? this.settings,
    epicboxAddress: epicboxAddress ?? this.epicboxAddress,
    wallets: wallets ?? this.wallets,
    oldHistory: oldHistory ?? this.oldHistory,
    session: session ?? this.session,
  );
}

/// Every write awaits what it reads first and then copies the current [state]: a copy taken
/// before an await would undo whatever changed meanwhile (a settings save, such as the tour's
/// seen flag, which the next save of any setting would then write back to the store).
class DeskController extends Notifier<DeskState> {
  DeskWalletApi get api => ref.read(deskApiProvider);

  StreamSubscription<void>? _changes;
  Timer? _statusPoll;
  Timer? _reload;
  int _nodesShown = 0;
  Timer? _nodesPoll;

  @override
  DeskState build() {
    ref.onDispose(_stopLive);
    ref.onDispose(() => _nodesPoll?.cancel());
    // The status-site switch is the settings file's `status.enabled`, a hand edit too.
    final boot = ref.read(deskBootProvider).settings;
    final host = ref.read(hostSettingsProvider);
    // The network mode is settings.toml's too (`network_mode_file.dart`): a hand edit or a
    // restored backup applies at once, as the Advanced page's choice does.
    final settings = boot.copyWith(useStatusSite: host.statusEnabled, advanced: boot.advanced.withMode(networkModeIn(host)));
    statusSite.on = settings.useStatusSite;
    ref.listen(hostSettingsProvider.select((h) => h.statusEnabled), (_, on) {
      statusSite.on = on;
      if (state.settings.useStatusSite != on) state = state.copyWith(settings: state.settings.copyWith(useStatusSite: on));
    });
    ref.listen(hostSettingsProvider.select(networkModeIn), (_, mode) {
      if (state.settings.advanced.networkMode != mode) {
        unawaited(saveSettings(state.settings.copyWith(advanced: state.settings.advanced.withMode(mode))));
      }
    });
    return DeskState(settings: settings);
  }

  /// After unlock: starts every receiving method whose Start with the wallet is on (the opened
  /// wallet's own [DeskSettings.epicboxAutostart], [DeskSettings.httpAutostart] and
  /// [DeskSettings.torAutostart], through [DeskApi.startAutostart]) and keeps the status rows
  /// and lists live until [lock]. The HTTP switch starts as that says on every unlock. [listen]
  /// is the old app-wide Start Epicbox choice; it is ignored now (the wallet's own setting took
  /// it over on first read) and goes when the screens stop passing it.
  Future<void> startLive({bool? listen}) async {
    _stopLive();
    final closes = _closes;
    _changes = api.changes().listen((_) {
      // Bursts of events (sync progress) reload the lists once, the status at once.
      unawaited(_loadStatus());
      _reload?.cancel();
      _reload = Timer(const Duration(milliseconds: 400), () => unawaited(_refreshQuietly()));
    });
    _statusPoll = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_loadStatus()));
    // The reach, port, autostart and Tor are the opened wallet's own: read them from it.
    final own = await api.settings();
    // Locked meanwhile: nothing of that wallet is written or started.
    if (_closes != closes) return;
    final http = own.payments.linkHttp;
    // The method switches are the wallet's view too (app-wide, read at its unlock), so a
    // container that has not loaded settings yet does not write defaults over them.
    final s = state.settings.copyWith(
      payments: own.payments,
      publicMode: own.publicMode,
      httpPort: own.httpPort,
      httpAutostart: http,
      epicboxAutostart: own.epicboxAutostart,
      torAutostart: own.torAutostart,
      directHttp: http,
      tor: own.tor,
    );
    state = state.copyWith(settings: s);
    await _serially(() => api.saveSettings(state.settings));
    try {
      await api.startAutostart();
    } on Object {
      // The status rows show what did not start; Receive offers to start it again.
    }
    // Tor's now-state may have changed with its autostart.
    final tor = (await api.settings()).tor;
    if (_closes != closes) return;
    state = state.copyWith(settings: state.settings.copyWith(tor: tor));
  }

  void _stopLive() {
    _changes?.cancel();
    _changes = null;
    _statusPoll?.cancel();
    _statusPoll = null;
    _reload?.cancel();
    _reload = null;
  }

  /// Moves on every lock (and a reopen that closed the wallet): a load that began before it
  /// writes nothing after it ([refresh], [startLive]).
  int _closes = 0;

  /// Ctrl+L and Lock: the session closed, the open wallet's data dropped.
  Future<void> lock() async {
    _closes++;
    _stopLive();
    // A recovery phrase copied in this session leaves the clipboard with it.
    unawaited(clearCopiedPhrase());
    await api.lock();
    state = DeskState(settings: state.settings, nodes: state.nodes, epicboxes: state.epicboxes);
  }

  /// Answers "Details differ" for the old wallet's history: the choices, or null to ask later.
  Future<void> resolveOldHistory(Map<String, bool>? choices) async {
    state = state.copyWith(oldHistory: const []);
    await api.resolveOldHistory(choices);
    if (choices != null) await refresh();
  }

  /// Re-reads the wallet list (Unlock, All wallets).
  Future<List<WalletEntry>> loadWallets() async {
    final wallets = await api.wallets();
    state = state.copyWith(wallets: wallets);
    return wallets;
  }

  Future<void> renameWallet(String id, String label) async {
    await api.renameWallet(id, label);
    final open = state.account?.id == id;
    final account = open ? await api.account() : null;
    final wallets = await api.wallets();
    state = state.copyWith(account: account, wallets: wallets);
  }

  /// Removes a wallet ([WalletRemoval]); the open one is locked first, and the app shows
  /// Unlock or Welcome after.
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) async {
    final open = state.account != null && state.account?.id == id;
    // The password is checked before anything locks: a typo stays in the Delete dialog.
    if (open && mode == WalletRemoval.delete) {
      if (password == null || password.isEmpty) throw DeskError.l10n((l) => l.deskErrEnterPassword);
      if (!await api.checkPassword(password)) throw DeskError.l10n((l) => l.deskErrWrongPassword, wrongPassword: true);
    }
    try {
      await api.removeWallet(id, mode, password: password);
    } finally {
      // The adapter locks the open wallet even when the removal fails; the screen follows.
      if (open) await lock();
      await loadWallets();
    }
  }

  Future<void> _loadStatus() async {
    if (_statusPoll == null && _changes == null) return;
    try {
      final s = await api.status();
      // A reopen the wallet made by itself (node fallback, the built-in node) shows here too.
      final session = api.sessionRevision;
      // Most polls find nothing new: an equal status is not written, so nothing redraws.
      if (s == state.status && session == state.session) return;
      if (_changes != null) state = state.copyWith(status: s, session: session);
    } on Object {
      // Locked meanwhile.
    }
  }

  Future<void> _refreshQuietly() async {
    if (_changes == null) return;
    final closes = _closes;
    try {
      final a = api;
      final balance = await a.balance();
      final txs = await a.transactions();
      final contacts = await a.contacts();
      // Asking the nodes is for the Node page ([showNodes]); off it the rows keep what was read.
      final nodes = _nodesShown > 0 ? await a.nodes() : null;
      final boxes = await a.epicboxes();
      final status = await a.status();
      if (_changes != null && _closes == closes) state = state.copyWith(balance: balance, txs: txs, contacts: contacts, nodes: nodes, epicboxes: boxes, status: status, oldHistory: a.oldHistoryConflicts);
    } on Object {
      // Locked meanwhile.
    }
  }

  /// The Node page (its list and pickers) is on screen, or no longer: while it is, the nodes
  /// are read at once and every 15 s, so each one is asked again after nodeRecheck and the
  /// heights the rows compare stay fresh. Off it, nothing asks the nodes the wallet does not use.
  void showNodes(bool on) {
    if (on) {
      _nodesShown++;
    } else if (_nodesShown > 0) {
      _nodesShown--;
    }
    if (_nodesShown == 0) {
      _nodesPoll?.cancel();
      _nodesPoll = null;
      return;
    }
    if (_nodesPoll != null) return;
    unawaited(_loadNodes());
    _nodesPoll = Timer.periodic(const Duration(seconds: 15), (_) => unawaited(_loadNodes()));
  }

  Future<void> _loadNodes() async {
    try {
      final nodes = await api.nodes();
      if (_nodesShown > 0 && !listEquals(nodes, state.nodes)) state = state.copyWith(nodes: nodes);
    } on Object {
      // Locked meanwhile.
    }
  }

  /// Reads the balance and the rows again, without asking the node: linked devices changed what
  /// they show (a payment of the other device, coins it holds).
  Future<void> reloadWallet() async {
    if (_changes == null) return;
    final closes = _closes;
    try {
      final balance = await api.balance();
      final txs = await api.transactions();
      if (_changes != null && _closes == closes) state = state.copyWith(balance: balance, txs: txs);
    } on Object {
      // Locked meanwhile.
    }
  }

  /// Loads everything; called after unlock and by Refresh. A lock meanwhile drops what was
  /// read; a reopen of the wallet meanwhile (a node or Epicbox change) reads it again.
  Future<void> refresh() async {
    final a = api;
    for (var tries = 0; ; tries++) {
      final closes = _closes;
      final revision = a.sessionRevision;
      final read = await _readAll(a);
      if (_closes != closes) return;
      if (a.sessionRevision != revision && tries < 2) continue;
      state = read;
      return;
    }
  }

  /// Everything [refresh] shows, read from [a].
  Future<DeskState> _readAll(DeskWalletApi a) async {
    final results = await Future.wait<Object>([
      a.account(),
      a.balance(),
      a.transactions(),
      a.contacts(),
      a.status(),
      a.nodes(),
      a.epicboxes(),
      a.epicboxAddress(),
      a.wallets(),
    ]);
    // Read last: a save made while the lists loaded (the tour's seen flag) is in it.
    final settings = await a.settings();
    return DeskState(
      account: results[0] as WalletAccount,
      balance: results[1] as Balance,
      txs: results[2] as List<Tx>,
      contacts: results[3] as List<Contact>,
      status: results[4] as ServiceStatus,
      nodes: results[5] as List<NodeServer>,
      epicboxes: results[6] as List<EpicboxServer>,
      settings: _keepTourSeen(settings),
      epicboxAddress: results[7] as String,
      wallets: results[8] as List<WalletEntry>,
      oldHistory: a.oldHistoryConflicts,
      session: a.sessionRevision,
    );
  }

  /// Refresh (Overview, Activity): asks the node now, then reloads everything. Rethrows why the
  /// node could not be asked; the lists are reloaded either way.
  Future<void> syncNow() async {
    // The other devices are read at the same time, not after the node.
    final devices = ref.read(deskDeviceHandleProvider).service;
    if (devices != null) unawaited(devices.sync(DeviceSyncTrigger.refresh));
    try {
      await api.syncNow();
    } finally {
      await refresh();
    }
  }

  /// The app-wide settings (theme, interface scale) before any wallet is open: they apply
  /// from the first screen.
  Future<void> loadSettings() async {
    if (ref.read(deskStoreProvider) != null) {
      // Read before the first frame (DeskBoot); the API was given them.
      final nodes = await api.nodes();
      final epicboxes = await api.epicboxes();
      state = state.copyWith(nodes: nodes, epicboxes: epicboxes);
      return;
    }
    final s = await api.settings();
    state = state.copyWith(settings: s);
  }

  Future<void> saveSettings(DeskSettings s) async {
    s = _keepTourSeen(s);
    state = state.copyWith(settings: s);
    statusSite.on = s.useStatusSite;
    // Each write takes the settings as they are when its turn comes, never the copy it was
    // given: two saves close together cannot leave the older one stored.
    await _serially(() async {
      final status = state.settings.useStatusSite;
      if (ref.read(hostSettingsProvider).statusEnabled != status) {
        await ref.read(hostSettingsProvider.notifier).set('online.status_site', status);
      }
      final mode = state.settings.advanced.networkMode;
      if (networkModeIn(ref.read(hostSettingsProvider)) != mode) {
        await saveNetworkMode(mode, ref.read(hostSettingsProvider.notifier).setAll);
      }
      await api.saveSettings(state.settings);
      await ref.read(deskStoreProvider)?.saveSettings(state.settings);
    });
    if (state.account != null) {
      final status = await api.status();
      state = state.copyWith(status: status);
    }
  }

  /// The settings write running now, if any ([_serially]); completes when it ends.
  Completer<void>? _saving;

  /// Runs [write] after the settings writes before it have ended, failed or not; at once when
  /// none runs. The lock is released inside the write's own frame, never by a callback left
  /// queued behind it.
  Future<T> _serially<T>(Future<T> Function() write) async {
    for (var running = _saving; running != null; running = _saving) {
      await running.future;
    }
    final mine = _saving = Completer<void>();
    try {
      return await write();
    } finally {
      _saving = null;
      mine.complete();
    }
  }

  /// The tour was seen ([DeskTourController.markSeen], which saves it): the settings held here
  /// say so, and the next save of any setting carries it.
  void holdTourSeen() => state = state.copyWith(settings: state.settings.copyWith(tourSeen: true));

  /// The import warning was acknowledged: held here so a later save of any setting carries it.
  void holdImportWarningSeen() => state = state.copyWith(settings: state.settings.copyWith(importWarningSeen: true));

  /// [DeskSettings.tourSeen] once true stays true: a copy without it is older than the tour.
  DeskSettings _keepTourSeen(DeskSettings s) {
    if (state.settings.tourSeen && !s.tourSeen) s = s.copyWith(tourSeen: true);
    if (state.settings.importWarningSeen && !s.importWarningSeen) s = s.copyWith(importWarningSeen: true);
    return s;
  }

  /// The switch says what happens from the first moment ([deskNodeSwitchProvider]).
  Future<void> useNode(String url) =>
      ref.read(deskNodeSwitchProvider.notifier).run(NodeSwitchStep.connecting, url, () => _reopening(() => api.useNode(url)));

  /// Node failover's move: [url] for this session, the chosen node kept (`desk_failover.dart`).
  Future<void> useNodeForSession(String url) => _reopening(() => api.useNodeForSession(url));

  Future<void> useBuiltInNode(bool on) => on
      ? ref.read(deskNodeSwitchProvider.notifier).run(NodeSwitchStep.starting, null, () => _reopening(() => api.useBuiltInNode(on)))
      : _reopening(() => api.useBuiltInNode(on));

  Future<void> followBuiltInNode() => _reopening(() => api.followBuiltInNode());

  Future<void> useEpicbox(String domain) => _reopening(() => api.useEpicbox(domain));

  /// A node or Epicbox change reopens the wallet; when that closed it, the app goes back to
  /// Unlock with the reason ([deskClosedProvider]).
  Future<void> _reopening(Future<void> Function() change) async {
    try {
      await change();
    } on DeskError catch (e) {
      if (e.locked) {
        _closes++;
        _stopLive();
        state = DeskState(settings: state.settings, nodes: state.nodes, epicboxes: state.epicboxes);
        ref.read(deskClosedProvider.notifier).set(e.message);
      }
      rethrow;
    }
    // The address carries the relay: it changes with the switch. A locked wallet (first-run
    // Setup, before Unlock) has no address yet: the change was only stored.
    final status = await api.status();
    if (state.account == null) {
      state = state.copyWith(status: status);
      return;
    }
    final address = await api.epicboxAddress();
    state = state.copyWith(status: status, epicboxAddress: address, session: api.sessionRevision);
  }

  /// Starts or stops receiving (Receive › Start listener / Stop receiving). Transitional: the
  /// screens move to [setEpicboxListening].
  Future<void> setListening(bool on) async {
    await api.setListening(on);
    final status = await api.status();
    state = state.copyWith(status: status);
  }

  /// The Epicbox switch (Receive, Settings › Transactions): Epicbox receiving alone, HTTP and Tor
  /// untouched.
  Future<void> setEpicboxListening(bool on) async {
    await api.setEpicboxListening(on);
    final status = await api.status();
    state = state.copyWith(status: status);
  }

  /// The Link · HTTP switch (Settings › Transactions; Receive's Try again): the one switch
  /// for HTTP receiving, saved as `payments.linkHttp` (the listener runs now and at unlock
  /// while it is on) and the listener started or stopped with it.
  Future<void> setHttp(bool on) async {
    final was = state.settings;
    final s = was.copyWith(
      payments: was.payments.copyWith(linkHttp: on),
      directHttp: on,
      httpAutostart: on,
    );
    state = state.copyWith(settings: s);
    await _serially(() => api.saveSettings(state.settings));
    try {
      await api.setHttpListening(on);
    } on Object {
      // Refused (Offline on a node that is not local): the switch shows it stayed off (LNX-8).
      // Only the HTTP fields go back; a setting saved meanwhile stays.
      final now = state.settings;
      state = state.copyWith(
        settings: now.copyWith(
          payments: now.payments.copyWith(linkHttp: was.payments.linkHttp),
          directHttp: was.directHttp,
          httpAutostart: was.httpAutostart,
        ),
      );
      await _serially(() => api.saveSettings(state.settings));
      rethrow;
    }
    final status = await api.status();
    state = state.copyWith(status: status);
  }

  /// The one Tor switch (Settings › Privacy, Send's Turn on Tor, Retry, Turn Tor off): saved
  /// for the open wallet as on now ([DeskSettings.tor]) and at every unlock
  /// ([DeskSettings.torAutostart]), tor started or stopped with it. What it covers is
  /// `tor_routes.dart`'s.
  Future<void> setTor(bool on) async {
    state = state.copyWith(settings: state.settings.copyWith(tor: on, torAutostart: on));
    if (on != (await api.settings()).torAutostart) await _serially(() => api.saveSettings(state.settings));
    await api.setTor(on);
    final status = await api.status();
    state = state.copyWith(status: status);
  }

  /// The Link · Tor switch (Settings › Payments): saved as `payments.linkTor`, and with it tor
  /// for payments starts or stops (the adapter's rule, `torPayWantedIn`). The Tor switch of
  /// Network & privacy is untouched.
  Future<void> setLinkTor(bool on) async {
    final s = state.settings;
    if (s.payments.linkTor == on) return;
    await saveSettings(s.copyWith(payments: s.payments.copyWith(linkTor: on)));
    final status = await api.status();
    state = state.copyWith(status: status);
  }

  /// Link · Tor's Retry after tor for payments failed.
  Future<void> retryTorPay() async {
    await api.retryTorPay();
    final status = await api.status();
    state = state.copyWith(status: status);
  }

  Future<void> addNode(NodeServer node) async {
    await api.addNode(node);
    final nodes = await api.nodes();
    state = state.copyWith(nodes: nodes);
  }

  /// Sends in flight: closing the app waits for them ([deskSendingProvider]).
  int get sending => ref.read(deskSendingProvider);

  Future<SendResult> send(SendRequest r) async {
    // One read of the other devices before coins are chosen (at most 3 s): what they hold is left out.
    final devices = ref.read(deskDeviceHandleProvider).service;
    // Counted from here on, so a Quit waits for it (the read of the other devices is part of it).
    final result = await ref.read(deskSendingProvider.notifier).during(() async {
      await devices?.beforeSend();
      return api.send(r);
    });
    // The other devices hear of it at once, not at the next tick.
    if (devices != null) unawaited(devices.announceNow());
    // The lists catch up; a failure here does not change what happened to the payment.
    try {
      final txs = await api.transactions();
      final balance = await api.balance();
      state = state.copyWith(txs: txs, balance: balance);
    } on Object {
      // Locked meanwhile; the next refresh shows it.
    }
    return result;
  }

  Future<void> resendTx(int id) async {
    await api.resendTx(id);
    final txs = await api.transactions();
    state = state.copyWith(txs: txs);
  }

  /// Stores the open wallet's minimum confirmations and takes the balance and payments counted
  /// with it at once (Overview re-splits without waiting for the next sync).
  Future<void> setMinConfirmations(int count) async {
    await api.setMinimumConfirmations(count);
    final balance = await api.balance();
    final txs = await api.transactions();
    state = state.copyWith(balance: balance, txs: txs);
  }

  Future<void> repostTx(int id) async {
    await api.repostTx(id);
    final txs = await api.transactions();
    state = state.copyWith(txs: txs);
  }

  Future<CancelResult> cancelTx(int id, {bool spendBack = true}) async {
    final result = await api.cancelTx(id, spendBack: spendBack);
    // The other devices free its coins at once, not at the next tick.
    final devices = ref.read(deskDeviceHandleProvider).service;
    if (devices != null) unawaited(devices.announceNow());
    final txs = await api.transactions();
    state = state.copyWith(txs: txs);
    return result;
  }

  /// Names a payment, or removes its name (null or blank); the list shows it at once.
  Future<void> setTxLabel(String key, String? label) async {
    await api.setTxLabel(key, label);
    final txs = await api.transactions();
    state = state.copyWith(txs: txs);
  }

  /// Sets the details of a payment a scan found (see [DeskWalletApi.setTxDetails]).
  Future<void> setTxDetails(String key, {String? counterparty, String? transport, String? note}) async {
    await api.setTxDetails(key, counterparty: counterparty, transport: transport, note: note);
    final txs = await api.transactions();
    state = state.copyWith(txs: txs);
  }

  /// The contact's id as stored. The rows are read again: a payment to one of its addresses
  /// takes its name.
  Future<String> saveContact(Contact c) async {
    final id = await api.saveContact(c);
    final contacts = await api.contacts();
    final txs = state.txs == null ? null : await api.transactions();
    state = state.copyWith(contacts: contacts, txs: txs);
    return id;
  }

  Future<void> deleteContact(String id) async {
    await api.deleteContact(id);
    final contacts = await api.contacts();
    final txs = state.txs == null ? null : await api.transactions();
    state = state.copyWith(contacts: contacts, txs: txs);
  }

  /// Saves [contacts] (an import: new ones with an empty id, saved ones with what they gain)
  /// and reloads the list once, also when a save fails part way.
  Future<void> saveContacts(Iterable<Contact> contacts) async {
    try {
      for (final c in contacts) {
        await api.saveContact(c);
      }
    } finally {
      state = state.copyWith(contacts: await api.contacts());
    }
  }
}

final deskProvider = NotifierProvider<DeskController, DeskState>(DeskController.new);

/// The confirmations the open wallet's balance counts a coin spendable with (LEPIC's), or the
/// app's default before there is a balance.
int deskMinConfirmations(WidgetRef ref) =>
    ref.watch(deskProvider.select((s) => s.balance?.minConfirmations)) ?? defaultMinimumConfirmations;

/// The open wallet's outputs (the Outputs page, SmartOutputs on Send). Reloads when another
/// wallet opens or the balance moves; invalidate to reload otherwise.
final deskOutputsProvider = FutureProvider<List<Output>>((ref) {
  ref.watch(deskProvider.select((s) => (s.account?.id, s.balance)));
  return ref.read(deskApiProvider).outputs();
});

/// The open wallet's Outputs choices (strategy, Split change): the Outputs page sets them,
/// Send reads them. Reloads when another wallet opens.
class DeskOutputPrefs extends AsyncNotifier<OutputPrefs> {
  @override
  Future<OutputPrefs> build() {
    ref.watch(deskProvider.select((s) => s.account?.id));
    return ref.read(deskApiProvider).outputPrefs();
  }

  Future<void> save(OutputPrefs prefs) async {
    state = AsyncData(prefs);
    await ref.read(deskApiProvider).saveOutputPrefs(prefs);
  }
}

final deskOutputPrefsProvider = AsyncNotifierProvider<DeskOutputPrefs, OutputPrefs>(DeskOutputPrefs.new);

/// The open wallet's minimum confirmations as the core stores it (Settings › Advanced). Reloads
/// when another wallet opens or the balance's count moves; [set] shows the new count at once
/// and goes back to the old one when the core refuses it.
class DeskMinConfirmationsSetting extends AsyncNotifier<int> {
  @override
  Future<int> build() {
    ref.watch(deskProvider.select((s) => (s.account?.id, s.balance?.minConfirmations)));
    return ref.read(deskApiProvider).minimumConfirmations();
  }

  Future<void> set(int count) async {
    final before = state;
    state = AsyncData(count);
    try {
      await ref.read(deskProvider.notifier).setMinConfirmations(count);
    } on Object {
      state = before;
      rethrow;
    }
  }
}

final deskMinConfirmationsSettingProvider = AsyncNotifierProvider<DeskMinConfirmationsSetting, int>(DeskMinConfirmationsSetting.new);

/// Why the wallet closed by itself (a server change could not reopen it); the app returns to
/// Unlock and shows it.
class DeskClosed extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? message) => state = message;
}

final deskClosedProvider = NotifierProvider<DeskClosed, String?>(DeskClosed.new);

/// Payments on their way out of this wallet (Send, paying an invoice): closing waits for them.
class DeskSending extends Notifier<int> {
  @override
  int build() => 0;

  /// Runs [send], counted while it runs.
  Future<T> during<T>(Future<T> Function() send) async {
    state++;
    try {
      return await send();
    } finally {
      state--;
    }
  }
}

final deskSendingProvider = NotifierProvider<DeskSending, int>(DeskSending.new);

/// Ends the app (Ctrl+Q) after the wallet is locked; null in the mock, which only locks.
final deskQuitProvider = Provider<Future<void> Function()?>((ref) => null);

/// The wallet's onion while Link · Tor is on, `<56 characters>.onion` (known before tor runs);
/// null while it is off or not read.
final deskTorAddressProvider = FutureProvider<String?>((ref) async {
  final on = ref.watch(deskProvider.select((s) => s.account != null && s.settings.payments.linkTor));
  if (!on || !torBuilt) return null;
  try {
    final a = await ref.read(deskApiProvider).torAddress();
    return a.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/+$'), '');
  } on Object {
    return null;
  }
});

/// Tor for payments now (item 2): the Link · Tor state line and the title-bar Tor icon read it;
/// `tor_pay.dart` says what each state means.
final deskTorPayProvider = Provider<TorPay>((ref) {
  final st = ref.watch(deskProvider);
  final status = st.status;
  return torPayOf(
    linkTor: st.settings.payments.linkTor,
    built: torBuilt && (status?.torIncluded ?? true),
    mode: st.settings.advanced.networkMode,
    torSwitch: st.settings.tor || st.settings.torAutostart,
    tor: torProcessState(st.settings, status),
    published: status?.tor == ServiceHealth.ok,
    onion: ref.watch(deskTorAddressProvider).value,
    problem: status?.tor == ServiceHealth.down || status?.tor == ServiceHealth.slow ? status?.torProblem : null,
  );
});
