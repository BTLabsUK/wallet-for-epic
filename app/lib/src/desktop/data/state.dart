/// Riverpod state for the desktop UI: the API seam and one snapshot of the open wallet.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
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

  @override
  DeskState build() => const DeskState();

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

  Future<void> saveSettings(DeskSettings s) async {
    state = state.copyWith(settings: s);
    await api.saveSettings(s);
    state = state.copyWith(status: await api.status());
  }

  Future<void> useNode(String url) async {
    await api.useNode(url);
    state = state.copyWith(status: await api.status());
  }

  Future<void> useEpicbox(String domain) async {
    await api.useEpicbox(domain);
    state = state.copyWith(status: await api.status());
  }

  Future<void> addNode(NodeServer node) async {
    await api.addNode(node);
    state = state.copyWith(nodes: await api.nodes());
  }

  Future<SendResult> send(SendRequest r) async {
    final result = await api.send(r);
    state = state.copyWith(txs: await api.transactions(), balance: await api.balance());
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
