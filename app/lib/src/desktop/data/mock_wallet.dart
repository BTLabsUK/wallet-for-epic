/// Canned answers for the desktop design run: a funded mainnet wallet with a varied history,
/// contacts, nodes and relays. Delays are short but real, so busy states show. The password
/// is anything but "wrong"; "wrong" fails the unlock.
library;

import 'dart:math';

import '../../wallet_service.dart' show onionAddressFormat;
import 'api.dart';
import 'http_address.dart';
import 'phrase_check.dart';
import 'models.dart';

const _epicboxAddr = 'esWnT8kBf3yXqPZ2r9cLhVd7JmK4uA6gYsN1pQeRtC5vD8xHwF2b@epicbox.epiccash.com';

DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
    DateTime(2026, 10, 21, 14, 30).subtract(Duration(days: days, hours: hours, minutes: minutes));

int _epic(num v) => (v * nanoPerEpic).round();

class MockDeskWallet implements DeskWalletApi {
  MockDeskWallet({this.delay = const Duration(milliseconds: 350)});

  final Duration delay;
  final _rng = Random(7);

  Future<void> _wait([double factor = 1]) => Future<void>.delayed(delay * factor);

  DeskSettings _settings = const DeskSettings();
  String _node = 'https://node.btlabs.uk';
  String _epicbox = 'epicbox.epiccash.com';
  bool _listening = true;
  bool _http = false;
  int _nextId = 40;

  final List<Contact> _contacts = [
    Contact(id: 'c1', name: 'Anna Kowalska', address: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com', favourite: true, lastUsed: _ago(days: 1), hasPicture: true),
    Contact(id: 'c2', name: 'Mining pool payouts', address: 'esZr8mQ2pVtW5kNcY7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2b@epicbox.epicnet.us', note: 'Weekly payouts', lastUsed: _ago(days: 3)),
    Contact(id: 'c3', name: 'Exchange deposit', address: 'esQa1nB7cVxZ3mL9kJ5hG2fD8sA6pO4iU1yT7rE3wQ9eR5tY@epicbox.epiccash.com', lastUsed: _ago(days: 12)),
    Contact(id: 'c4', name: 'Tom', address: 'http://10.0.1.24:3415', note: 'Home server'),
    Contact(id: 'c5', name: 'Merchant: Coffee', address: 'esP9oI8uY7tR6eW5qA4sD3fG2hJ1kL0zX9cV8bN7mQ6wE5rT@epicbox.stackwallet.com'),
  ];

  late final List<Tx> _txs = [
    Tx(id: 39, slateId: 'b7e2c1d4-8f3a-4e21-9c7b-5a1d2e3f4a5b', direction: TxDirection.received, state: TxState.confirming, method: TxMethod.epicbox, amount: _epic(25), fee: 0, created: _ago(minutes: 18), confirmations: 2, counterparty: _contacts[0].address, contactName: 'Anna Kowalska', message: 'Lunch, thanks', height: 2914410),
    Tx(id: 38, slateId: 'a1f9e8d7-6c5b-4a39-8271-605f4e3d2c1b', direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.file, amount: _epic(12.5), fee: _epic(0.007), created: _ago(hours: 3), counterparty: 'send_12.5_a1f9e8d7.slate.json'),
    Tx(id: 37, slateId: 'c3d4e5f6-0718-4293-a4b5-c6d7e8f90a1b', direction: TxDirection.sent, state: TxState.posted, method: TxMethod.epicbox, amount: _epic(3.2), fee: _epic(0.006), created: _ago(hours: 5), counterparty: _contacts[4].address, contactName: 'Merchant: Coffee'),
    Tx(id: 36, slateId: 'd4e5f607-1829-43a4-b5c6-d7e8f90a1b2c', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(148.73215), fee: 0, created: _ago(days: 1, hours: 2), confirmations: 1440, counterparty: _contacts[1].address, contactName: 'Mining pool payouts', height: 2913020, kernel: '09a1c3e5f7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3', hasProof: true),
    Tx(id: 35, slateId: 'e5f60718-2a3b-44c5-d6e7-f8091a2b3c4d', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.http, amount: _epic(40), fee: _epic(0.008), created: _ago(days: 2, hours: 6), confirmations: 2810, counterparty: 'http://10.0.1.24:3415', contactName: 'Tom', height: 2911600, kernel: '08b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4', hasProof: true),
    Tx(id: 34, slateId: 'f6071829-3b4c-45d6-e7f8-091a2b3c4d5e', direction: TxDirection.sent, state: TxState.cancelled, method: TxMethod.epicbox, amount: _epic(5), fee: _epic(0.006), created: _ago(days: 3), counterparty: _contacts[2].address, contactName: 'Exchange deposit'),
    Tx(id: 101, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(2), fee: 0, created: _ago(days: 4), confirmations: 620, height: 2913794, coinbase: true, confirmedAt: _ago(days: 4)),
    Tx(id: 102, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(7.5), fee: 0, created: _ago(days: 4, hours: 6), confirmations: 900, height: 2913500, foundByScan: true, confirmedAt: _ago(days: 4, hours: 6)),
    Tx(id: 33, slateId: '0718293a-4c5d-46e7-f809-1a2b3c4d5e6f', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.tor, amount: _epic(0.5), fee: 0, created: _ago(days: 5), confirmations: 5700, counterparty: 'http://3fz7k2mq9xr4tbv6.onion', height: 2908700, kernel: '07c3e5a7b9d1f3e5a7c9b1d3f5e7a9c1b3d5e7f9a1c3b5d7e9f1a3c5b7d9e1f3a5'),
    Tx(id: 32, slateId: '18293a4b-5d6e-47f8-091a-2b3c4d5e6f70', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.file, amount: _epic(1000), fee: 0, created: _ago(days: 9), confirmations: 11500, counterparty: 'receive_1000.slate.json', height: 2902900, kernel: '06d4f6b8a0c2e4f6b8d0a2c4e6f8b0d2a4c6e8f0b2d4a6c8e0f2b4d6a8c0e2f4b6'),
    Tx(id: 31, slateId: '293a4b5c-6e7f-4809-1a2b-3c4d5e6f7081', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(250), fee: _epic(0.012), created: _ago(days: 14), confirmations: 18700, counterparty: _contacts[2].address, contactName: 'Exchange deposit', height: 2895700, hasProof: true, kernel: '05e5a7c9b1d3f5a7e9c1b3d5f7a9e1c3b5d7f9a1e3c5b7d9f1a3e5c7b9d1f3a5e7'),
    Tx(id: 30, slateId: '3a4b5c6d-7f80-491a-2b3c-4d5e6f708192', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(132.1), fee: 0, created: _ago(days: 21), confirmations: 28800, counterparty: _contacts[1].address, contactName: 'Mining pool payouts', height: 2885600, kernel: '04f6b8d0a2c4e6f8b0d2a4c6e8f0b2d4a6c8e0f2b4d6a8c0e2f4b6d8a0c2e4f6b8'),
    for (var i = 0; i < 18; i++)
      Tx(
        id: 29 - i,
        slateId: '4b5c6d7e-80${(10 + i).toString()}-4a2b-3c4d-5e6f708192a3',
        direction: i.isEven ? TxDirection.received : TxDirection.sent,
        state: TxState.confirmed,
        method: i % 3 == 0 ? TxMethod.file : TxMethod.epicbox,
        amount: _epic(10 + i * 7.25),
        fee: i.isEven ? 0 : _epic(0.006),
        created: _ago(days: 25 + i * 4),
        confirmations: 30000 + i * 5760,
        counterparty: i.isEven ? _contacts[1].address : _contacts[0].address,
        contactName: i.isEven ? 'Mining pool payouts' : 'Anna Kowalska',
        height: 2880000 - i * 5760,
      ),
  ];

  final List<NodeServer> _nodes = [
    NodeServer(url: 'https://node.btlabs.uk', label: 'BT Labs', operator: 'BT Labs', health: ServiceHealth.ok, latencyMs: 18, height: 2914414, version: '4.1.1'),
    NodeServer(url: 'https://node.epicnet.us:3413', label: 'EpicNet', operator: 'EpicNet', health: ServiceHealth.ok, latencyMs: 132, height: 2914414, version: '4.1.1'),
    NodeServer(url: 'https://node.epiccash.com:3413', label: 'Epic Cash', operator: 'Epic Cash', health: ServiceHealth.slow, latencyMs: 940, height: 2914413, version: '4.1.1'),
    NodeServer(url: 'https://epic.stackwallet.com:3413', label: 'Cypher Stack', operator: 'Cypher Stack', health: ServiceHealth.ok, latencyMs: 210, height: 2914414, version: '4.1.0'),
    NodeServer(url: 'https://epic-node.iniaku.my.id', label: 'Iniaku pool', operator: 'Iniaku pool', health: ServiceHealth.down, version: '4.1.1'),
    NodeServer(url: 'http://10.0.1.24:3413', label: 'Home node', health: ServiceHealth.ok, latencyMs: 6, height: 2914414, version: '4.1.1', own: true),
  ];

  final List<EpicboxServer> _epicboxes = [
    EpicboxServer(domain: 'epicbox.stackwallet.com', operator: 'Cypher Stack', health: ServiceHealth.ok, latencyMs: 141),
    EpicboxServer(domain: 'epicbox.epicnet.us', operator: 'EpicNet', health: ServiceHealth.slow, latencyMs: 1210),
    EpicboxServer(domain: 'epicbox.epiccash.com', operator: 'Epic Cash', health: ServiceHealth.ok, latencyMs: 96),
    EpicboxServer(domain: 'epicbox.iniaku.my.id', operator: 'Iniaku pool', health: ServiceHealth.ok, latencyMs: 360),
  ];

  final List<WalletEntry> _wallets = [
    WalletEntry(id: 'legacy-mainnet', name: 'Main wallet', folder: '~/.epic/main/wallet_data', network: 'mainnet', lastOpened: _ago(minutes: 20)),
    WalletEntry(id: '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', name: 'Savings', folder: '~/.epic/main/savings', network: 'mainnet', lastOpened: _ago(days: 30)),
    WalletEntry(id: '0a1b2c3d4e5f60718293a4b5c6d7e8f9', name: 'Test', folder: '~/.epic/floo/test', network: 'floonet', lastOpened: _ago(days: 60)),
  ];
  String _current = 'legacy-mainnet';

  WalletEntry _with(WalletEntry w, {String? name}) =>
      WalletEntry(id: w.id, name: name ?? w.name, folder: w.folder, network: w.network, current: w.id == _current, lastOpened: w.lastOpened, missing: w.missing);

  @override
  Future<List<WalletEntry>> wallets() async {
    await _wait(0.5);
    return [for (final w in _wallets) _with(w)];
  }

  @override
  Future<void> selectWallet(String id) async => _current = id;

  @override
  Future<void> renameWallet(String id, String label) async {
    await _wait(0.5);
    final i = _wallets.indexWhere((w) => w.id == id);
    if (i >= 0) _wallets[i] = _with(_wallets[i], name: label.trim());
  }

  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) async {
    await _wait(2);
    if (password == 'wrong') throw const DeskError('Wrong password', wrongPassword: true);
    _wallets.removeWhere((w) => w.id == id);
    _remembered.remove(id);
    if (_current == id && _wallets.isNotEmpty) _current = _wallets.first.id;
  }

  @override
  Future<List<WalletEntry>> findRemoved() async => const [];

  @override
  Future<void> addBack(String id) async {}

  // Import: four old wallets; the epic program's is in use until checked again. An old
  // password starting with "wrong" is wrong.
  static final List<OldWallet> _oldWallets = [
    OldWallet(id: 'sav', name: 'Savings', folder: '~/.epic/main/Savings', group: OldWalletGroup.gui, lastUsed: _ago(days: 39), sizeBytes: 38 << 20),
    OldWallet(id: 'eve', name: 'Everyday', folder: '~/.epic/Everyday/main', group: OldWalletGroup.gui, lastUsed: _ago(days: 19), sizeBytes: 112 << 20),
    OldWallet(
      id: 'tst',
      name: 'Testing',
      folder: '~/.epic/floo',
      group: OldWalletGroup.gui,
      network: 'floonet',
      lastUsed: _ago(days: 21),
      sizeBytes: 3 << 20,
      blocked: 'Test network wallet. Only mainnet wallets can be imported.',
    ),
    OldWallet(id: 'cli', name: 'Wallet (epic program)', folder: '~/.epic/main', group: OldWalletGroup.cli, lastUsed: _ago(days: 54), sizeBytes: 21 << 20, sameAs: 'Same wallet as Everyday'),
  ];
  final Set<String> _checked = {};
  final List<String> _imported = [];

  @override
  Future<List<OldWallet>> findOldWallets() async {
    await _wait(3);
    _imported.clear();
    return _oldWallets;
  }

  @override
  Future<FolderFind?> pickFolder() async {
    await _wait();
    return FolderFind(
      folder: '~/Documents/old-wallet-backup',
      wallets: [OldWallet(id: 'bak', name: 'Backup 2024', folder: '~/Documents/old-wallet-backup', group: OldWalletGroup.picked, lastUsed: _ago(days: 232), sizeBytes: 19 << 20)],
    );
  }

  @override
  Future<OldWalletUse> checkOldWallet(String id) async {
    await _wait(2);
    return id == 'cli' && _checked.add(id) ? OldWalletUse.inUse : OldWalletUse.free;
  }

  @override
  Future<ImportedWallet> importOldWallet(String id, {required String oldPassword, String? newPassword}) async {
    await _wait(3);
    if (oldPassword.startsWith('wrong')) throw const DeskError('Wrong old password', wrongPassword: true);
    if ((newPassword ?? oldPassword).length < minPasswordLength) {
      throw const DeskError('The old password is short. Choose a new one of at least $minPasswordLength characters.', newPasswordNeeded: true);
    }
    final name = _oldWallets.where((w) => w.id == id).firstOrNull?.name ?? 'Backup 2024';
    final entry = WalletEntry(id: 'imp-$id', name: name, folder: '~/.local/share/epic-wallet/wallets/imp-$id/mainnet', network: 'mainnet');
    _wallets.add(entry);
    _current = entry.id;
    _imported.add(entry.id);
    return ImportedWallet(id: entry.id, name: name, proof: const [ImportProof('Seed read'), ImportProof('Wallet created'), ImportProof('Old folder unchanged')]);
  }

  @override
  Future<void> cancelImport() async {
    await _wait();
    _wallets.removeWhere((w) => _imported.contains(w.id));
    _imported.clear();
  }

  /// Wallets remembered on this computer, and the wrong passwords counted against them.
  final Set<String> _remembered = {};
  int _fails = 0;
  String get _selected => _current;

  /// Tests: the OS store refuses to keep a password ([notRemembered]).
  bool storeRefuses = false;

  @override
  bool notRemembered = false;

  @override
  bool openedRemembered = false;

  @override
  Future<bool> unlock(String password, {bool remember = false}) async {
    await _wait(2);
    final ok = password.isNotEmpty && password != 'wrong';
    if (!ok && ++_fails >= 5) _remembered.remove(_selected);
    notRemembered = false;
    if (ok) {
      _fails = 0;
      openedRemembered = false;
      notRemembered = remember && storeRefuses;
      remember && !storeRefuses ? _remembered.add(_selected) : _remembered.remove(_selected);
    }
    return ok;
  }

  @override
  Future<bool> unlockRemembered() async {
    if (!_remembered.contains(_selected)) return false;
    await _wait(2);
    openedRemembered = true;
    return true;
  }

  @override
  Future<bool> checkPassword(String password) async {
    await _wait(1);
    return password.isNotEmpty && password != 'wrong';
  }

  @override
  Future<bool> isRemembered(String id) async => _remembered.contains(id.isEmpty ? _current : id);

  @override
  Future<void> forgetRemembered(String id) async => _remembered.remove(id.isEmpty ? _current : id);

  @override
  Future<void> lock() => _wait(0.5);

  static const _words = [
    'orbit', 'hazard', 'velvet', 'cabin', 'sudden', 'meadow', 'brick', 'gesture', 'lunar', 'invest', 'pledge', 'saddle',
    'timber', 'crisp', 'wander', 'echo', 'faculty', 'notable', 'ripple', 'garlic', 'stamp', 'dwarf', 'enjoy', 'harbor',
  ];

  @override
  Future<List<String>> newPhrase({int words = 24}) async {
    await _wait();
    return _words.take(words).toList();
  }

  @override
  Future<List<String>> createWallet({String name = '', required String password}) async {
    await _wait(3);
    _addWallet(name);
    return _words;
  }

  @override
  bool checkPhrase(List<String> words) => bip39PhraseValid(words);

  @override
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase}) async {
    await _wait(3);
    _addWallet(name);
  }

  /// The new wallet is listed as the next free "Wallet N" (or [name]) and is the selected one.
  void _addWallet(String name) {
    var n = 1;
    while (_wallets.any((w) => w.name == 'Wallet $n')) {
      n++;
    }
    final label = name.trim().isEmpty ? 'Wallet $n' : name.trim();
    final id = 'new-${_wallets.length}-${DateTime.now().microsecondsSinceEpoch}';
    _wallets.add(WalletEntry(id: id, name: label, folder: '~/.local/share/epic-wallet/wallets/$id/mainnet', network: 'mainnet'));
    _current = id;
  }

  @override
  Future<WalletAccount> account() async =>
      WalletAccount(id: 'legacy-mainnet', name: _wallets.where((w) => w.id == 'legacy-mainnet').firstOrNull?.name ?? 'Main wallet', network: 'mainnet', folder: '~/.epic/main/wallet_data', created: DateTime(2024, 3, 14));

  @override
  Future<Balance> balance() async {
    await _wait(0.3);
    return Balance(spendable: _epic(1284.73215), awaitingConfirmation: _epic(25), locked: _epic(15.713), awaitingFinalization: _epic(12.5), immature: _epic(2));
  }

  @override
  Future<List<Tx>> transactions() async {
    await _wait(0.5);
    return List.unmodifiable(_txs);
  }

  @override
  Future<List<Output>> outputs() async {
    await _wait(0.5);
    String cmt(int i) => '08${List.generate(64, (k) => '0123456789abcdef'[(i * 7 + k * 13 + k * k) % 16]).join()}';
    return [
      Output(commitment: cmt(1), value: _epic(25), status: OutputStatus.confirming, height: 2914410, confirmations: 2),
      Output(commitment: cmt(2), value: _epic(12.5), status: OutputStatus.unconfirmed),
      Output(commitment: cmt(3), value: _epic(15.713), status: OutputStatus.locked, height: 2911600, confirmations: 2810),
      Output(commitment: cmt(4), value: _epic(2), status: OutputStatus.immature, height: 2913794, confirmations: 620, lockHeight: 2915234),
      Output(commitment: cmt(5), value: _epic(148.73215), status: OutputStatus.unspent, height: 2913020, confirmations: 1394),
      Output(commitment: cmt(6), value: _epic(7.5), status: OutputStatus.unspent, height: 2913500, confirmations: 914),
      Output(commitment: cmt(7), value: _epic(0.5), status: OutputStatus.unspent, height: 2908700, confirmations: 5714),
      Output(commitment: cmt(8), value: _epic(1000), status: OutputStatus.unspent, height: 2902900, confirmations: 11514),
      Output(commitment: cmt(9), value: _epic(40.008), status: OutputStatus.spent, height: 2900100, confirmations: 14314),
      for (var i = 0; i < 16; i++)
        Output(
          commitment: cmt(10 + i),
          value: _epic(8 + i * 3.5),
          status: i % 5 == 4 ? OutputStatus.spent : OutputStatus.unspent,
          height: 2880000 - i * 5760,
          confirmations: 34414 + i * 5760,
        ),
    ];
  }

  @override
  Future<List<Contact>> contacts() async => List.unmodifiable(_contacts);

  @override
  Future<ServiceStatus> status() async {
    final node = _nodes.firstWhere((n) => n.url == _node, orElse: () => _nodes.first);
    final box = _epicboxes.firstWhere((e) => e.domain == _epicbox, orElse: () => _epicboxes.first);
    return ServiceStatus(
      node: node,
      nodeHealth: node.health,
      nodeHeight: 2914414,
      epicbox: box,
      epicboxHealth: _listening ? box.health : ServiceHealth.off,
      httpListener: _http ? ServiceHealth.ok : ServiceHealth.off,
      tor: _settings.tor ? ServiceHealth.ok : ServiceHealth.off,
      torCanSend: _settings.tor,
      lastUpdate: _ago(minutes: 1),
    );
  }

  @override
  Future<List<NodeServer>> nodes() async => List.unmodifiable(_nodes);

  @override
  Future<List<EpicboxServer>> epicboxes() async => List.unmodifiable(_epicboxes);

  @override
  Future<DeskSettings> settings() async => _settings;

  @override
  Future<String> epicboxAddress() async => _epicboxAddr;

  @override
  Future<String> httpAddress() async => !_http ? '' : 'http://${_settings.publicMode ? '10.0.1.24' : '127.0.0.1'}:${_settings.httpPort}';

  @override
  Future<String> torAddress() async => 'http://wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';

  @override
  bool isOnionAddress(String to) => onionAddressFormat(to);

  @override
  bool isEpicboxAddress(String to) => RegExp(r'^es[0-9A-Za-z]{38,58}(@[\w.-]+(:\d+)?)?$').hasMatch(to.trim());

  @override
  Future<int> estimateFee(int amount) async {
    await _wait(0.4);
    return amount > _epic(500) ? _epic(0.012) : _epic(0.006);
  }

  @override
  Future<(int, int)> estimateMax() async {
    final spendable = (await balance()).spendable;
    final fee = await estimateFee(spendable);
    return (spendable - fee, fee);
  }

  @override
  Future<SendResult> send(SendRequest r) async {
    await _wait(4);
    if (r.to != null && r.to!.contains('offline')) {
      return const SendFailed('The recipient did not answer. Nothing was sent.');
    }
    if (r.method == TxMethod.http) {
      final problem = httpAddressProblem(r.to ?? '');
      if (problem != null) return SendFailed(problem);
      if (plainHttpNeedsConsent(r.to!) && !r.allowPlainHttp) return const SendFailed('Plain HTTP not confirmed');
    }
    final tx = Tx(
      id: _nextId++,
      slateId: 'f0e1d2c3-b4a5-4697-8879-${_rng.nextInt(999999).toString().padLeft(6, '0')}a0b1c2',
      direction: TxDirection.sent,
      state: r.method == TxMethod.file || r.method == TxMethod.epicbox ? TxState.waitingRecipient : TxState.posted,
      method: r.method,
      amount: r.amount,
      fee: _epic(0.006),
      created: DateTime.now(),
      counterparty: r.to,
      message: r.message,
    );
    _txs.insert(0, tx);
    if (r.method == TxMethod.file) return SendFileReady(tx, 'send_${formatEpic(r.amount, minDecimals: 0)}_${tx.slateId.substring(0, 8)}.slate.json');
    return SendDone(tx);
  }

  @override
  Future<ReceivedFile> receiveFile(String fileName) async {
    await _wait(2);
    final tx = Tx(id: _nextId++, slateId: '9a8b7c6d-5e4f-4321-8765-0fedcba98765', direction: TxDirection.received, state: TxState.waitingRecipient, method: TxMethod.file, amount: _epic(42), fee: 0, created: DateTime.now(), counterparty: fileName);
    return ReceivedFile(tx, '$fileName.response');
  }

  @override
  Future<Tx> finalizeFile(String fileName) async {
    await _wait(2);
    return _txs.firstWhere((t) => t.id == 38);
  }

  @override
  Future<void> cancelTx(int id) async {
    await _wait();
    final i = _txs.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = _txs[i];
    _txs[i] = Tx(id: t.id, slateId: t.slateId, direction: t.direction, state: TxState.cancelled, method: t.method, amount: t.amount, fee: t.fee, created: t.created, counterparty: t.counterparty, contactName: t.contactName, message: t.message);
  }

  @override
  Future<String> exportProof(int id) async {
    await _wait();
    return '~/Documents/epic-proof-$id.json';
  }

  @override
  Future<String> saveContact(Contact contact) async {
    final id = contact.id.isEmpty ? 'c${DateTime.now().microsecondsSinceEpoch}' : contact.id;
    _contacts.removeWhere((c) => c.id == id);
    _contacts.add(
      Contact(id: id, name: contact.name, address: contact.address, note: contact.note, favourite: contact.favourite, lastUsed: contact.lastUsed, hasPicture: contact.hasPicture),
    );
    return id;
  }

  @override
  Future<void> deleteContact(String id) async => _contacts.removeWhere((c) => c.id == id);

  @override
  Future<void> saveSettings(DeskSettings settings) async => _settings = settings;

  @override
  Future<void> useNode(String url) async {
    await _wait();
    _node = url;
  }

  @override
  Future<void> useBuiltInNode(bool on) async {
    await _wait();
    _node = on ? 'http://127.0.0.1:3413' : 'https://node.btlabs.uk';
  }

  @override
  Future<NodeServer> checkNode(String url) async {
    await _wait(3);
    final known = _nodes.where((n) => n.url == url);
    if (known.isNotEmpty) return known.first;
    if (url.contains('bad')) return NodeServer(url: url, label: url, health: ServiceHealth.down);
    return NodeServer(url: url, label: Uri.tryParse(url)?.host ?? url, health: ServiceHealth.ok, latencyMs: 48, height: 2914414, version: '3.6.0', own: true);
  }

  @override
  Future<void> addNode(NodeServer node) async => _nodes.add(node);

  @override
  Future<void> useEpicbox(String domain) async {
    await _wait();
    _epicbox = domain;
  }

  @override
  Future<void> setListening(bool on) async {
    await _wait(2);
    _listening = on;
    _http = on && _settings.directHttp;
  }

  @override
  Future<void> setHttpListening(bool on) async {
    await _wait();
    _http = on;
  }

  @override
  Future<void> setTor(bool on) async {
    await _wait();
    _settings = _settings.copyWith(tor: on);
  }

  static const _scanLog = [
    'Starting UTXO scan',
    'Checking 1000 outputs, up to index 1000 (highest index: 2914414)',
    'Identified 4 wallet outputs as belonging to this wallet',
    'Checking 1000 outputs, up to index 2000 (highest index: 2914414)',
    'Identified 2 wallet outputs as belonging to this wallet',
    'Checking 1000 outputs, up to index 3000 (highest index: 2914414)',
    'Scanning for outputs, 41% complete',
  ];

  bool _scanStop = false;

  @override
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false}) async* {
    _scanStop = false;
    for (final (i, line) in _scanLog.indexed) {
      await _wait(2.5);
      if (_scanStop) return;
      yield ScanStep(line, percent: (i + 1) * 100 ~/ (_scanLog.length + 1));
    }
    await _wait(2);
    yield ScanStep(
      'Scan complete',
      percent: 100,
      finished: true,
      counts: ScanCounts(found: 6, restored: 1, unlocked: deleteUnconfirmed ? 1 : 0, deleted: deleteUnconfirmed ? 1 : 0),
    );
  }

  @override
  Future<void> stopRescan() async => _scanStop = true;

  @override
  Future<void> syncNow() => _wait(3);

  @override
  Stream<void> changes() => const Stream.empty();

  @override
  Future<List<String>> revealPhrase(String password) async {
    await _wait(2);
    if (password == 'wrong') throw StateError('Wrong password');
    return _words;
  }

  @override
  Future<void> changePassword(String current, String next) async {
    await _wait(2);
    if (current == 'wrong') throw const DeskError('Wrong password', wrongPassword: true);
    if (next.length < 8) throw const DeskError('Use at least 8 characters');
    _remembered.remove(_current);
  }
}
