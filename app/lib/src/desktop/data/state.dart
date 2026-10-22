/// Riverpod state for the desktop UI: the API seam and one snapshot of the open wallet.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'desk_store.dart';
import 'mock_wallet.dart';
import 'models.dart';

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
  );
}

class DeskController extends Notifier<DeskState> {
  DeskWalletApi get api => ref.read(deskApiProvider);

  StreamSubscription<void>? _changes;
  Timer? _statusPoll;
  Timer? _reload;

  @override
  DeskState build() {
    ref.onDispose(_stopLive);
    return DeskState(settings: ref.read(deskBootProvider).settings);
  }

  /// After unlock: starts the listener when [listen] (Settings › Start Epicbox with the wallet)
  /// and keeps the status rows and lists live until [lock].
  Future<void> startLive({required bool listen}) async {
    _stopLive();
    _changes = api.changes().listen((_) {
      // Bursts of events (sync progress) reload the lists once, the status at once.
      unawaited(_loadStatus());
      _reload?.cancel();
      _reload = Timer(const Duration(milliseconds: 400), () => unawaited(_refreshQuietly()));
    });
    _statusPoll = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_loadStatus()));
    if (listen) {
      try {
        await setListening(true);
      } on Object {
        // The status row shows the listener down; Receive offers to start it again.
      }
    }
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
    await api.lock();
    state = DeskState(settings: state.settings, nodes: state.nodes, epicboxes: state.epicboxes);
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
      if (_changes != null) state = state.copyWith(balance: balance, txs: txs, contacts: contacts, nodes: nodes, epicboxes: boxes, status: await a.status());
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
      a.settings(),
      a.epicboxAddress(),
      a.wallets(),
    ]);
    state = DeskState(
      account: results[0] as WalletAccount,
      balance: results[1] as Balance,
      txs: results[2] as List<Tx>,
      contacts: results[3] as List<Contact>,
      status: results[4] as ServiceStatus,
      nodes: results[5] as List<NodeServer>,
      epicboxes: results[6] as List<EpicboxServer>,
      settings: results[7] as DeskSettings,
      epicboxAddress: results[8] as String,
      wallets: results[9] as List<WalletEntry>,
    );
  }

  /// The app-wide settings (theme, interface scale) before any wallet is open: they apply
  /// from the first screen.
  Future<void> loadSettings() async {
    if (ref.read(deskStoreProvider) != null) {
      // Read before the first frame (DeskBoot); the API was given them.
      state = state.copyWith(nodes: await api.nodes(), epicboxes: await api.epicboxes());
      return;
    }
    final s = await api.settings();
    state = state.copyWith(settings: s);
  }

  Future<void> saveSettings(DeskSettings s) async {
    state = state.copyWith(settings: s);
    await api.saveSettings(s);
    await ref.read(deskStoreProvider)?.saveSettings(s);
    if (state.account != null) state = state.copyWith(status: await api.status());
  }

  Future<void> useNode(String url) => _reopening(() => api.useNode(url));

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
    state = state.copyWith(status: await api.status());
  }

  /// Starts or stops receiving (Receive › Start listener / Stop receiving).
  Future<void> setListening(bool on) async {
    await api.setListening(on);
    state = state.copyWith(status: await api.status());
  }

  Future<void> addNode(NodeServer node) async {
    await api.addNode(node);
    state = state.copyWith(nodes: await api.nodes());
  }

  /// Sends in flight: Quit waits for them.
  int get sending => _sending;
  int _sending = 0;

  Future<SendResult> send(SendRequest r) async {
    _sending++;
    final SendResult result;
    try {
      result = await api.send(r);
    } finally {
      _sending--;
    }
    // The lists catch up; a failure here does not change what happened to the payment.
    try {
      state = state.copyWith(txs: await api.transactions(), balance: await api.balance());
    } on Object {
      // Locked meanwhile; the next refresh shows it.
    }
    return result;
  }

  Future<void> cancelTx(int id) async {
    await api.cancelTx(id);
    state = state.copyWith(txs: await api.transactions());
  }

  Future<void> saveContact(Contact c) async {
    await api.saveContact(c);
    state = state.copyWith(contacts: await api.contacts());
  }

  Future<void> deleteContact(String id) async {
    await api.deleteContact(id);
    state = state.copyWith(contacts: await api.contacts());
  }
}

final deskProvider = NotifierProvider<DeskController, DeskState>(DeskController.new);

/// The wallet's outputs (Activity › Outputs). Invalidate to reload.
final deskOutputsProvider = FutureProvider<List<Output>>((ref) => ref.read(deskApiProvider).outputs());

/// Why the wallet closed by itself (a server change could not reopen it); the app returns to
/// Unlock and shows it.
class DeskClosed extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? message) => state = message;
}

final deskClosedProvider = NotifierProvider<DeskClosed, String?>(DeskClosed.new);

/// Ends the app (Ctrl+Q) after the wallet is locked; null in the mock, which only locks.
final deskQuitProvider = Provider<Future<void> Function()?>((ref) => null);
