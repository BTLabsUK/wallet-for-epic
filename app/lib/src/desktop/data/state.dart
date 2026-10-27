/// Riverpod state for the desktop UI: the API seam and one snapshot of the open wallet.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'desk_store.dart';
import 'mock_wallet.dart';
import 'models.dart';
import '../../providers.dart' show defaultMinimumConfirmations;
import '../../relay_directory.dart' show statusSite;
import '../widgets/kit.dart' show DeskFeatures;
import '../../phrase_clipboard.dart';

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

  @override
  DeskState build() {
    ref.onDispose(_stopLive);
    final settings = ref.read(deskBootProvider).settings;
    statusSite.on = settings.useStatusSite;
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
    _changes = api.changes().listen((_) {
      // Bursts of events (sync progress) reload the lists once, the status at once.
      unawaited(_loadStatus());
      _reload?.cancel();
      _reload = Timer(const Duration(milliseconds: 400), () => unawaited(_refreshQuietly()));
    });
    _statusPoll = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_loadStatus()));
    // The reach, port, autostart and Tor are the opened wallet's own: read them from it.
    final own = await api.settings();
    final http = DeskFeatures.httpDirect && own.payments.linkHttp;
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
    await api.saveSettings(s);
    try {
      await api.startAutostart();
    } on Object {
      // The status rows show what did not start; Receive offers to start it again.
    }
    // Tor's now-state may have changed with its autostart.
    final tor = (await api.settings()).tor;
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

  /// Ctrl+L and Lock: the session closed, the open wallet's data dropped.
  Future<void> lock() async {
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
    // The password is checked before anything locks: a typo stays in the Delete dialog (R5).
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
      if (_changes != null) state = state.copyWith(status: s);
    } on Object {
      // Locked meanwhile.
    }
  }

  Future<void> _refreshQuietly() async {
    if (_changes == null) return;
    try {
      final a = api;
      final balance = await a.balance();
      final txs = await a.transactions();
      final contacts = await a.contacts();
      final nodes = await a.nodes();
      final boxes = await a.epicboxes();
      final status = await a.status();
      if (_changes != null) state = state.copyWith(balance: balance, txs: txs, contacts: contacts, nodes: nodes, epicboxes: boxes, status: status, oldHistory: a.oldHistoryConflicts);
    } on Object {
      // Locked meanwhile.
    }
  }

  /// Loads everything; called after unlock and by Refresh.
  Future<void> refresh() async {
    final a = api;
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
    state = DeskState(
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
    );
  }

  /// Refresh (Overview, Activity): asks the node now, then reloads everything. Rethrows why the
  /// node could not be asked; the lists are reloaded either way.
  Future<void> syncNow() async {
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
    await api.saveSettings(s);
    await ref.read(deskStoreProvider)?.saveSettings(s);
    if (state.account != null) {
      final status = await api.status();
      state = state.copyWith(status: status);
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

  Future<void> useNode(String url) => _reopening(() => api.useNode(url));

  /// Node failover's move: [url] for this session, the chosen node kept (`desk_failover.dart`).
  Future<void> useNodeForSession(String url) => _reopening(() => api.useNodeForSession(url));

  Future<void> useBuiltInNode(bool on) => _reopening(() => api.useBuiltInNode(on));

  Future<void> useEpicbox(String domain) => _reopening(() => api.useEpicbox(domain));

  /// A node or Epicbox change reopens the wallet; when that closed it, the app goes back to
  /// Unlock with the reason ([deskClosedProvider]).
  Future<void> _reopening(Future<void> Function() change) async {
    try {
      await change();
    } on DeskError catch (e) {
      if (e.locked) {
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
    await api.saveSettings(s);
    try {
      await api.setHttpListening(on);
    } on Object {
      // Refused (Offline on a node that is not local): the switch shows it stayed off (LNX-8).
      state = state.copyWith(settings: was);
      await api.saveSettings(was);
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
    final s = state.settings.copyWith(tor: on, torAutostart: on);
    state = state.copyWith(settings: s);
    if (s.torAutostart != (await api.settings()).torAutostart) await api.saveSettings(s);
    await api.setTor(on);
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
    final result = await ref.read(deskSendingProvider.notifier).during(() => api.send(r));
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

  Future<void> repostTx(int id) async {
    await api.repostTx(id);
    final txs = await api.transactions();
    state = state.copyWith(txs: txs);
  }

  Future<void> cancelTx(int id) async {
    await api.cancelTx(id);
    final txs = await api.transactions();
    state = state.copyWith(txs: txs);
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
