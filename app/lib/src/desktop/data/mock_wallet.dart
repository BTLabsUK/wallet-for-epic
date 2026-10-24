/// Canned answers for the desktop design run: a funded mainnet wallet with a varied history,
/// contacts, nodes and relays. Delays are short but real, so busy states show. The password
/// is anything but "wrong"; "wrong" fails the unlock.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';


import '../../providers.dart' show defaultMinimumConfirmations;
import '../../seed_contacts.dart';
import '../../wallet_service.dart' show onionAddressFormat;
import 'api.dart';
import 'http_address.dart';
import 'invoices.dart';
import 'phrase_check.dart';
import 'models.dart';

export 'invoices.dart' show InvoiceError, InvoiceProblem;

part 'mock_invoices.dart';

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
    Contact(id: 'c1', name: 'Anna Kowalska', address: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com', favourite: true, lastUsed: _ago(days: 1), hasPicture: true, invoiceAddress: _annaInvoice),
    Contact(id: 'c2', name: 'Mining pool payouts', address: 'esZr8mQ2pVtW5kNcY7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2b@epicbox.epicnet.us', note: 'Weekly payouts', lastUsed: _ago(days: 3)),
    Contact(id: 'c3', name: 'Exchange deposit', address: 'esQa1nB7cVxZ3mL9kJ5hG2fD8sA6pP4iU1yT7rE3wQ9eR5tY@epicbox.epiccash.com', lastUsed: _ago(days: 12)),
    Contact(id: 'c4', name: 'Tom', address: 'http://10.0.1.24:3415', note: 'Home server'),
    Contact(id: 'c5', name: 'Merchant: Coffee', address: 'esP9o78uY7tR6eW5qA4sD3fG2hJ1kL9zX9cV8bN7mQ6wE5rT@epicbox.stackwallet.com'),
    Contact(id: 'c6', name: 'Piotr Nowak', address: 'esPn4Wq8TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtK2s@epicbox.epicnet.us', note: 'Design work', invoiceAddress: _piotrInvoice),
    Contact(id: 'c7', name: 'Ola Wiśniewska', note: 'Stock wallet', address: 'esQka2kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3x@epicbox.epiccash.com', invoiceAddress: _olaInvoice),
    // Seeded into every new wallet (spec 9).
    Contact(id: 'btlabs', name: btLabsContact.name, address: btLabsContact.address, note: btLabsContact.note),
  ];

  late final List<Tx> _txs = [
    Tx(id: 39, slateId: 'b7e2c1d4-8f3a-4e21-9c7b-5a1d2e3f4a5b', direction: TxDirection.received, state: TxState.confirming, method: TxMethod.epicbox, amount: _epic(25), fee: 0, created: _ago(minutes: 18), confirmations: 2, counterparty: _contacts[0].address, contactName: 'Anna Kowalska', message: 'Lunch, thanks', height: 2914410),
    Tx(id: 38, slateId: 'a1f9e8d7-6c5b-4a39-8271-605f4e3d2c1b', direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.file, amount: _epic(12.5), fee: _epic(0.007), cancellable: true, created: _ago(hours: 3), counterparty: 'send_12.5_a1f9e8d7.slate.json'),
    Tx(id: 37, slateId: 'c3d4e5f6-0718-4293-a4b5-c6d7e8f90a1b', direction: TxDirection.sent, state: TxState.posted, method: TxMethod.epicbox, amount: _epic(3.2), fee: _epic(0.006), created: _ago(hours: 5), counterparty: _contacts[4].address, contactName: 'Merchant: Coffee'),
    Tx(id: 36, slateId: 'd4e5f607-1829-43a4-b5c6-d7e8f90a1b2c', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(148.73215), fee: 0, created: _ago(days: 1, hours: 2), confirmations: 1440, counterparty: _contacts[1].address, contactName: 'Mining pool payouts', height: 2913020, kernel: '09a1c3e5f7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3', hasProof: true),
    Tx(id: 35, slateId: 'e5f60718-2a3b-44c5-d6e7-f8091a2b3c4d', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.http, amount: _epic(40), fee: _epic(0.008), created: _ago(days: 2, hours: 6), confirmations: 2810, counterparty: 'http://10.0.1.24:3415', contactName: 'Tom', height: 2911600, kernel: '08b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4', hasProof: true),
    Tx(id: 34, slateId: 'f6071829-3b4c-45d6-e7f8-091a2b3c4d5e', direction: TxDirection.sent, state: TxState.cancelled, method: TxMethod.epicbox, amount: _epic(5), fee: _epic(0.006), created: _ago(days: 3), counterparty: _contacts[2].address, contactName: 'Exchange deposit'),
    Tx(id: 101, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(2), fee: 0, created: _ago(days: 4), confirmations: 620, height: 2913794, coinbase: true, confirmedAt: _ago(days: 4)),
    Tx(id: 102, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(7.5), fee: 0, created: _ago(days: 4, hours: 6), confirmations: 900, height: 2913500, foundByScan: true, foundDuring: FoundDuring.restore, confirmedAt: _ago(days: 4, hours: 6)),
    Tx(id: 33, slateId: '0718293a-4c5d-46e7-f809-1a2b3c4d5e6f', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.tor, amount: _epic(0.5), fee: 0, created: _ago(days: 5), confirmations: 5700, counterparty: 'http://3fz7k2mq9xr4tbv6.onion', height: 2908700, kernel: '07c3e5a7b9d1f3e5a7c9b1d3f5e7a9c1b3d5e7f9a1c3b5d7e9f1a3c5b7d9e1f3a5'),
    Tx(id: 103, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(4.25), fee: 0, created: _ago(days: 6), confirmations: 8600, height: 2905800, foundByScan: true, foundDuring: FoundDuring.rescan, confirmedAt: _ago(days: 6)),
    Tx(id: 104, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(1.1), fee: 0, created: _ago(days: 7), confirmations: 10000, height: 2904400, foundByScan: true, foundDuring: FoundDuring.rescan, datedByBlock: false),
    Tx(id: 105, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(0.8), fee: 0, created: _ago(days: 8), confirmations: 11400, height: 2903000, foundByScan: true, confirmedAt: _ago(days: 8)),
    Tx(id: 32, slateId: '18293a4b-5d6e-47f8-091a-2b3c4d5e6f70', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.file, amount: _epic(1000), fee: 0, created: _ago(days: 9), confirmations: 11500, counterparty: 'receive_1000.slate.json', height: 2902900, kernel: '06d4f6b8a0c2e4f6b8d0a2c4e6f8b0d2a4c6e8f0b2d4a6c8e0f2b4d6a8c0e2f4b6'),
    Tx(id: 31, slateId: '293a4b5c-6e7f-4809-1a2b-3c4d5e6f7081', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(250), fee: _epic(0.012), created: _ago(days: 14), confirmations: 18700, counterparty: _contacts[2].address, contactName: 'Exchange deposit', height: 2895700, hasProof: true, kernel: '05e5a7c9b1d3f5a7e9c1b3d5f7a9e1c3b5d7f9a1e3c5b7d9f1a3e5c7b9d1f3a5e7'),
    Tx(id: 30, slateId: '3a4b5c6d-7f80-491a-2b3c-4d5e6f708192', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(132.1), fee: 0, created: _ago(days: 21), confirmations: 28800, counterparty: _contacts[1].address, contactName: 'Mining pool payouts', height: 2885600, kernel: '04f6b8d0a2c4e6f8b0d2a4c6e8f0b2d4a6c8e0f2b4d6a8c0e2f4b6d8a0c2e4f6b8'),
    Tx(id: -106, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(12.5), fee: 0, created: _ago(days: 22), fromBackup: true),
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

  /// The first wallet's phrase in the mock (the BIP-39 vector of 23 "zoo" and "vote"):
  /// restoring it shows "This wallet is already here".
  static const String samePhrase =
      'zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote';

  /// Phrase fingerprint → wallet id, for the wallets this session made and [samePhrase].
  final Map<String, String> _phrases = {phraseFingerprint(samePhrase): 'legacy-mainnet'};

  WalletEntry _with(WalletEntry w, {String? name}) =>
      WalletEntry(id: w.id, name: name ?? w.name, folder: w.folder, network: w.network, current: w.id == _current, lastOpened: w.lastOpened, missing: w.missing);

  @override
  Future<List<WalletEntry>> wallets() async {
    await _wait(0.5);
    return [for (final w in _wallets) _with(w)];
  }

  final Set<String> _setupPending = {};

  @override
  Future<bool> setupPending(String id) async => _setupPending.contains(id);

  @override
  Future<void> setSetupPending(String id, bool pending) async => pending ? _setupPending.add(id) : _setupPending.remove(id);

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
  Future<void> lock() async {
    // A send or split under way finishes first, as in the real wallet.
    while (_busy > 0) {
      await (_idle ??= Completer<void>()).future;
    }
    await _wait(0.5);
  }

  int _busy = 0;
  Completer<void>? _idle;

  @override
  bool get busy => _busy > 0;

  Future<T> _running<T>(Future<T> Function() call) async {
    _busy++;
    try {
      return await call();
    } finally {
      if (--_busy == 0) {
        _idle?.complete();
        _idle = null;
      }
    }
  }

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
  Future<WalletEntry?> walletWithPhrase(List<String> words) async {
    // Instant, as the list lookup is.
    if (!checkPhrase(words)) return null;
    final id = _phrases[phraseFingerprint(words.join(' '))];
    final w = _wallets.where((w) => w.id == id).firstOrNull;
    return w == null ? null : _with(w);
  }

  @override
  bool checkPhrase(List<String> words) => bip39PhraseValid(words);

  @override
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase}) async {
    final same = await walletWithPhrase(phrase);
    if (same != null) throw DeskError('This wallet is already here: ${same.name}', sameWallet: same);
    await _wait(3);
    _phrases[phraseFingerprint(phrase.join(' '))] = _addWallet(name);
  }

  /// The new wallet is listed as the next free "Wallet N" (or [name]) and is the selected one.
  /// Returns its id.
  String _addWallet(String name) {
    var n = 1;
    while (_wallets.any((w) => w.name == 'Wallet $n')) {
      n++;
    }
    final label = name.trim().isEmpty ? 'Wallet $n' : name.trim();
    final id = 'new-${_wallets.length}-${DateTime.now().microsecondsSinceEpoch}';
    _wallets.add(WalletEntry(id: id, name: label, folder: '~/.local/share/epic-wallet/wallets/$id/mainnet', network: 'mainnet'));
    _current = id;
    return id;
  }

  @override
  Future<WalletAccount> account() async =>
      WalletAccount(id: 'legacy-mainnet', name: _wallets.where((w) => w.id == 'legacy-mainnet').firstOrNull?.name ?? 'Main wallet', network: 'mainnet', folder: '~/.epic/main/wallet_data', created: DateTime(2024, 3, 14));

  @override
  Future<Balance> balance() async {
    await _wait(0.3);
    final p = proto;
    return Balance(
      spendable: _epic(1284.73215) + p.spendDelta,
      awaitingConfirmation: _epic(25) + p.confirmingDelta,
      locked: _epic(15.713) + p.lockDelta,
      awaitingFinalization: _epic(12.5),
      immature: _epic(2),
    );
  }

  @override
  Future<List<Tx>> transactions() async {
    await _wait(0.5);
    proto;
    return List.unmodifiable(_txs);
  }

  @override
  Future<List<Output>> outputs() async {
    await _wait(0.5);
    return _outputs;
  }

  late List<Output> _outputs = _cannedOutputs();

  List<Output> _cannedOutputs() {
    String cmt(int i) => '08${List.generate(64, (k) => '0123456789abcdef'[(i * 7 + k * 13 + k * k) % 16]).join()}';
    return [
      Output(commitment: cmt(1), value: _epic(25), status: OutputStatus.confirming, height: 2914410, confirmations: 2),
      Output(commitment: cmt(2), value: _epic(12.5), status: OutputStatus.unconfirmed, awaitingFinalization: true),
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

  /// Epic's fee: 0.001 EPIC × (4 × outputs + inputs − 1).
  static int _fee(int inputs, int outputs) => _epic(0.001) * max(1, 4 * outputs + inputs - 1);

  List<Output> get _spendable => _outputs.where((o) => o.spendable).toList()..sort((a, b) => a.value.compareTo(b.value));

  @override
  Future<SendEstimate> estimateSend(int amount, {SendOptions? options}) async {
    await _wait(0.4);
    final o = options ?? const SendOptions();
    final n = o.changeOutputs;
    if (n < 1 || n > 10) throw const DeskError('Not accepted: change outputs 1 to 10');
    var sum = 0;
    var count = 0;
    for (final out in _spendable) {
      if (o.strategy == SelectionStrategy.smallest && sum >= amount + _fee(count, 1 + n)) break;
      sum += out.value;
      count++;
    }
    // Inputs that cover amount and fee exactly make no change output.
    final exact = _fee(count, 1);
    if (sum == amount + exact) return SendEstimate(amount: amount, fee: exact, inputCount: count, locked: sum);
    final fee = _fee(count, 1 + n);
    if (sum < amount + fee) throw const DeskError('Not enough funds');
    final change = sum - amount - fee;
    if (change > 0 && change < n) throw const DeskError('This send cannot be built from the coins available.', unbuildable: true);
    return SendEstimate(amount: amount, fee: fee, inputCount: count, change: change, locked: sum, changeOutputs: change == 0 ? 0 : n);
  }

  @override
  Future<OutputPrefs> outputPrefs() async => _prefs;

  OutputPrefs _prefs = const OutputPrefs();

  @override
  Future<void> saveOutputPrefs(OutputPrefs prefs) async => _prefs = prefs;

  @override
  Future<void> repostTx(int id) => _wait();

  @override
  Future<void> resendTx(int id) => _wait();

  Future<SendEstimate> _selfEstimate(int outputs) async {
    await _wait(0.4);
    final all = _spendable;
    final sum = all.fold(0, (a, o) => a + o.value);
    final fee = _fee(all.length, outputs);
    if (sum < fee + outputs) throw const DeskError('Not enough funds');
    final part = (sum - fee) ~/ outputs;
    return SendEstimate(amount: part, fee: fee, inputCount: all.length, change: sum - fee - part, locked: sum, changeOutputs: outputs - 1);
  }

  @override
  Future<SendEstimate> estimateSplit(int outputs) {
    if (outputs < 2 || outputs > 10) throw const DeskError('Not accepted: 2 to 10 outputs');
    return _selfEstimate(outputs);
  }

  @override
  Future<SelfSend> splitOutputs(int outputs) => _running(() => _split(outputs));

  Future<SelfSend> _split(int outputs) async {
    final e = await estimateSplit(outputs);
    await _wait(3);
    return _selfSent(e, outputs);
  }

  /// Locks the spendable outputs and adds [count] unconfirmed ones sharing their value less
  /// the fee, as a posted split or consolidate leaves the wallet.
  SelfSend _selfSent(SendEstimate e, int count) {
    final txId = _nextId++;
    final receivedTxId = _nextId++;
    final total = e.locked - e.fee;
    final part = total ~/ count;
    _outputs = [
      for (final o in _outputs)
        o.spendable
            ? Output(commitment: o.commitment, value: o.value, status: OutputStatus.locked, height: o.height, confirmations: o.confirmations, txId: txId)
            : o,
      for (var i = 0; i < count; i++)
        Output(
          commitment: '09${(txId * 31 + i).toRadixString(16).padLeft(64, '0')}',
          value: i == count - 1 ? total - part * (count - 1) : part,
          status: OutputStatus.unconfirmed,
          awaitingFinalization: true,
          txId: i == 0 ? receivedTxId : txId,
        ),
    ];
    return SelfSend(txId: txId, receivedTxId: receivedTxId, amount: e.amount, fee: e.fee, inputCount: e.inputCount, outputCount: count);
  }

  @override
  Future<SendEstimate> estimateConsolidate() => _selfEstimate(1);

  @override
  Future<SelfSend> consolidateOutputs() => _running(_consolidate);

  Future<SelfSend> _consolidate() async {
    final e = await estimateConsolidate();
    await _wait(3);
    return _selfSent(e, 1);
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
  Future<String> httpAddress() async => !_http ? '' : 'http://${_settings.publicMode ? '203.0.113.24' : '127.0.0.1'}:${_settings.httpPort}';

  /// A router that does not forward the port yet: the warning shows.
  @override
  Future<HttpReach?> httpReach({bool recheck = false}) async => !_http || !_settings.publicMode || _settings.tor
      ? null
      : HttpReach(port: _settings.httpPort, publicIp: '203.0.113.24', lan: '10.0.1.24', reachable: false, checkedAt: DateTime.now());

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
  Future<SendEstimate> estimateMax() async {
    final spendable = (await balance()).spendable;
    final fee = await estimateFee(spendable);
    return SendEstimate(amount: spendable - fee, fee: fee, inputCount: _spendable.length, locked: spendable);
  }

  @override
  Future<SendResult> send(SendRequest r) => _running(() => _send(r));

  Future<SendResult> _send(SendRequest r) async {
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
      // As the core: cancellable while it waits for the recipient, never once posted.
      cancellable: r.method == TxMethod.file || r.method == TxMethod.epicbox,
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
    final tx = Tx(id: _nextId++, slateId: '9a8b7c6d-5e4f-4321-8765-0fedcba98765', direction: TxDirection.received, state: TxState.waitingRecipient, method: TxMethod.file, amount: _epic(42), fee: 0, cancellable: true, created: DateTime.now(), counterparty: fileName);
    return ReceivedFile(tx, '$fileName.response');
  }

  @override
  Future<Tx> finalizeFile(String fileName) => _running(() => _finalize(fileName));

  Future<Tx> _finalize(String fileName) async {
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
      Contact(id: id, name: contact.name, address: contact.address, note: contact.note, favourite: contact.favourite, lastUsed: contact.lastUsed, hasPicture: contact.hasPicture, invoiceAddress: contact.invoiceAddress),
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
  Future<void> setEpicboxListening(bool on) async {
    await _wait(2);
    _listening = on;
  }

  @override
  Future<void> startAutostart() async {
    if (_settings.epicboxAutostart) await setEpicboxListening(true);
    if (_settings.httpAutostart && !_settings.torAutostart) await setHttpListening(true);
    if (_settings.torAutostart) await setTor(true);
  }

  @override
  Future<void> setHttpListening(bool on) async {
    await _wait();
    // As the adapter: the clearnet listener stays off while Tor is on.
    _http = on && !_settings.tor;
  }

  @override
  Future<void> setTor(bool on) async {
    await _wait();
    _settings = _settings.copyWith(tor: on);
    _http = !on && _settings.directHttp;
  }

  @override
  Future<void> setEpicboxOverTor(bool on) async {}

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
  Stream<void> changes() => _changes.stream;

  /// Background events: the prototype's other side (invoices) pings it.
  final StreamController<void> _changes = StreamController<void>.broadcast();

  // ---- Invoices (mock_invoices.dart): both sides, a movable clock and the other party.

  /// The invoices prototype. The Prototype panel drives its other side.
  late final InvoiceProto proto = InvoiceProto._(this);

  @override
  bool get supportsInvoices => true;

  /// The prototype shows its other side's moves on the page itself.
  @override
  Stream<InvoiceNotice> invoiceNotices() => const Stream.empty();

  @override
  Future<InvoiceBook> invoices() async {
    await _wait(0.2);
    return proto.book();
  }

  @override
  Future<InvoiceBook> checkInvoices() async {
    await _wait(1.2);
    final book = proto.drain();
    proto._changed();
    return book;
  }

  @override
  Future<IssuedRequest> requestPayment(PaymentRequestDraft draft) async {
    await _wait(1.6);
    final r = proto.request(draft);
    proto._changed();
    return r;
  }

  @override
  Future<void> withdrawRequest(String slateId) async {
    await _wait(0.8);
    proto.withdraw(slateId);
    proto._changed();
  }

  @override
  Future<void> cancelRequestPayment(String slateId) async {
    await _wait(1.2);
    proto.cancelRequestPayment(slateId);
    proto._changed();
  }

  @override
  Future<void> repostRequest(String slateId) async {
    await _wait(1.2);
    proto.repost(slateId);
    proto._changed();
  }

  @override
  Future<IncomingInvoice> payInvoice(String slateId, {required int amount, required String password}) async {
    await _wait(2);
    final paid = proto.pay(slateId, amount, password);
    proto._changed();
    return paid;
  }

  @override
  Future<IncomingInvoice> retryInvoiceReply(String slateId) async {
    await _wait(1.2);
    final i = proto.retry(slateId);
    proto._changed();
    return i;
  }

  @override
  Future<void> declineInvoice(String slateId) async {
    await _wait(0.8);
    proto.decline(slateId);
    proto._changed();
  }

  @override
  Future<void> cancelInvoicePayment(String slateId) async {
    await _wait(1.5);
    proto.cancelPayment(slateId);
    proto._changed();
  }

  @override
  Future<SelfSend> spendCancelledToSelf(String slateId) async {
    await _wait(2);
    final i = proto.spendToSelf(slateId);
    proto._changed();
    return SelfSend(txId: _nextId++, receivedTxId: _nextId++, amount: i.total - 700000, fee: 700000, inputCount: 1, outputCount: 1);
  }

  @override
  Future<String> rotateInvoiceAddress() async {
    await _wait(0.8);
    final a = proto.rotate();
    proto._changed();
    return a;
  }

  @override
  Future<void> trustSender(String address, String label, {String? contactId}) async {
    await _wait(0.3);
    proto.trust(address, label, contactId);
    proto._changed();
  }

  @override
  Future<void> untrustSender(String address) async {
    await _wait(0.3);
    proto.untrust(address);
    proto._changed();
  }

  @override
  Future<void> setInvoiceExpiry(Duration expiry) async {
    await _wait(0.2);
    proto.expiry = expiry > maxInvoiceExpiry ? maxInvoiceExpiry : expiry;
    proto._changed();
  }

  @override
  Future<PeerCapability> peerCapability(String address) async {
    await _wait(0.2);
    return proto.capability(address);
  }

  @override
  Future<List<String>> revealPhrase(String password) async {
    await _wait(2);
    if (password == 'wrong') throw StateError('Wrong password');
    return _words;
  }

  /// The history backup record the Backup rows and the reminder show; tours and tests set it.
  HistoryBackupState backup = HistoryBackupState(lastExport: DateTime(2026, 10, 3, 14, 2), unbacked: 12, payments: 48, contacts: 6);

  /// What the next [importHistory] answers: a [HistoryImport] or a [HistoryFileError]. After a
  /// good import the same file again adds nothing.
  Object? nextImport;
  bool _historyImported = false;

  @override
  Future<HistoryBackupState> historyBackupState() async {
    await _wait(0.5);
    return backup;
  }

  @override
  Future<Uint8List> exportHistory() async {
    await _wait(2);
    return Uint8List.fromList(utf8.encode('WFEH mock history backup'));
  }

  @override
  Future<String> exportHistoryCsv({DateTime? from, DateTime? to}) async {
    await _wait();
    final rows = [
      for (final t in _txs)
        if ((from == null || !t.created.isBefore(DateTime(from.year, from.month, from.day))) &&
            (to == null || t.created.isBefore(DateTime(to.year, to.month, to.day + 1))))
          '${t.created.toUtc().toIso8601String()},${t.incoming ? 'Received' : 'Sent'},${t.state.name},'
              '${t.incoming ? '' : '-'}${t.amount / nanoPerEpic},${t.fee / nanoPerEpic},${t.counterparty ?? ''},,${t.slateId},${t.kernel ?? ''},${t.height ?? ''}',
    ];
    return ['date,type,status,amount_epic,fee_epic,counterparty,note,slate_id,kernel,block_height', ...rows].join('\n');
  }

  @override
  Future<HistoryImport> importHistory(Uint8List data) async {
    await _wait(2);
    final next = nextImport;
    if (next is HistoryFileError) throw next;
    if (next is HistoryImport) return next;
    if (_historyImported) return const HistoryImport(skipped: 46);
    _historyImported = true;
    return const HistoryImport(merged: 3, added: 2, skipped: 41, contactsAdded: 1);
  }

  @override
  Future<void> markHistoryExported(DateTime when) async {
    backup = HistoryBackupState(lastExport: when, payments: backup.payments, contacts: backup.contacts, network: backup.network);
  }

  @override
  Future<void> dismissHistoryReminder(DateTime when) async {
    backup = HistoryBackupState(lastExport: backup.lastExport, unbacked: backup.unbacked, payments: backup.payments, contacts: backup.contacts, network: backup.network);
  }

  @override
  Future<void> changePassword(String current, String next) async {
    await _wait(2);
    if (current == 'wrong') throw const DeskError('Wrong password', wrongPassword: true);
    if (next.length < 8) throw const DeskError('Use at least 8 characters');
    _remembered.remove(_current);
  }
}
