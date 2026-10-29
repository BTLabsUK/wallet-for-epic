// SPDX-License-Identifier: Apache-2.0
/// Canned answers for the desktop design run: a funded mainnet wallet with a varied history,
/// contacts, nodes and relays. Delays are short but real, so busy states show. The password
/// is anything but "wrong"; "wrong" fails the unlock.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';


import '../../advanced.dart' show NetworkMode;
import '../../devices/device_model.dart' show DeviceBook, HoldState;
import '../../devices/device_service.dart' show DeviceHost;
import '../../wallet_service.dart' show OutputCategory, WalletOutput, WalletOutputStatus, fakeAddressSignature;
import '../../network.dart' show EpicboxRelay;
import '../../models.dart' show DeviceEnding, TxEntry, PairingCaps, PairingParty, PairingSlate, PairingState, SealMode, SlatePurpose, maxMinimumConfirmations, minMinimumConfirmations;
import '../../network_gate.dart';
import '../../pairing_fake.dart';
import '../../providers.dart' show defaultMinimumConfirmations;
import '../../seed_contacts.dart';
import '../../backup_settings.dart' show mergeServerLists;
import '../../server_list.dart' show ServerKind, ServerList;
import '../../slate_files.dart' show responseFileName, sendFileName;
import '../../wallet_service.dart' show onionAddressFormat;
import 'api.dart';
import 'backup_settings_desk.dart';
import 'features.dart';
import 'http_address.dart';
import 'invoices.dart';
import 'phrase_check.dart';
import 'models.dart';

export 'invoices.dart' show InvoiceError, InvoiceProblem;

part 'mock_invoices.dart';

/// The mock wallet's canned output [i] (1 to 24), for a linked device's hold on it.
String mockCommitment(int i) => '08${List.generate(64, (k) => '0123456789abcdef'[(i * 7 + (i ~/ 16) * (k + 1) + k * 13 + k * k) % 16]).join()}';

/// The mock wallet's payments key, which a [MockPhone] of the same wallet shares.
const String mockEpicboxKey = _epicboxKey;

const _epicboxKey = 'esWnT8kBf3yXqPZ2r9cLhVd7JmK4uA6gYsN1pQeRtC5vD8xHwF2b';

/// The prototype's pairings, by id: who is paired and how (the states of a pairing).
const mockAnnaPairing = 'p-anna';
const mockNorthwindPairing = 'p-northwind';
const mockCoffeePairing = 'p-coffee';
const mockTomPairing = 'p-tom';
const mockMartaPairing = 'p-marta';

DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
    DateTime(2026, 10, 21, 14, 30).subtract(Duration(days: days, hours: hours, minutes: minutes));

int _epic(num v) => (v * nanoPerEpic).round();

/// An operator icon as status.btlabs.uk serves it, by its hash (the tour and the tests hold
/// the 128 px PNGs in test/fixtures/icons/).
ServerIcon mockServerIcon(String hash) => ServerIcon(
  hash: hash,
  urls: {for (final px in const [128, 256]) px: Uri.parse('https://status.btlabs.uk/api/v1/icons/$hash-$px.png')},
);

/// A test double that delegates to a [MockDeskWallet] (a recorder): the tour's prepare steps
/// reach the mock behind it.
abstract interface class MockBacked {
  MockDeskWallet get mock;
}

/// The mock wallet behind [api], when there is one.
MockDeskWallet? mockBehind(DeskWalletApi api) => api is MockDeskWallet ? api : (api is MockBacked ? (api as MockBacked).mock : null);

class MockDeskWallet implements DeskWalletApi {
  MockDeskWallet({this.delay = const Duration(milliseconds: 350), this.seedInvoices = true, this.otherWalletRows = false});

  /// Whether the history lists a send from another wallet and a receive by one (the chain check:
  /// another wallet on this recovery phrase). The tour turns it on; most tests leave it off.
  final bool otherWalletRows;

  /// Whether the history lists the invoices prototype's rows. A new install, with Invoices off,
  /// has none, so the screenshot tours leave them out of the shots that run with it off.
  final bool seedInvoices;

  final Duration delay;
  final _rng = Random(7);

  Future<void> _wait([double factor = 1]) => Future<void>.delayed(delay * factor);

  DeskSettings _settings = const DeskSettings();
  String _node = 'https://node.btlabs.uk';
  String _epicbox = 'epicbox.epiccash.com';
  bool _listening = true;

  /// The tour and the tests: the network blocks the relay in use, and [epicboxInstead] is the one offered.
  bool epicboxBlocked = false;
  EpicboxRelay? epicboxInstead;
  bool _http = false;
  int _nextId = 40;

  final List<Contact> _contacts = [
    Contact(id: 'c1', name: 'Anna Kowalska', address: _annaAddr, http: 'https://pay.example.net:3415', favourite: true, lastUsed: _ago(days: 1), hasPicture: true),
    Contact(id: 'c2', name: 'Mining pool payouts', address: 'esZr8mQ2pVtW5kNcY7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2b@epicbox.epicnet.us', note: 'Weekly payouts', lastUsed: _ago(days: 3)),
    Contact(id: 'c3', name: 'Exchange deposit', address: 'esQa1nB7cVxZ3mL9kJ5hG2fD8sA6pP4iU1yT7rE3wQ9eR5tY@epicbox.epiccash.com', lastUsed: _ago(days: 12)),
    Contact(id: 'c4', name: 'Tom', address: 'http://10.0.1.24:3415', epicbox: _tomAddr, note: 'Home server'),
    Contact(id: 'c5', name: 'Merchant: Coffee', address: _coffeeAddr),
    Contact(id: 'c6', name: 'Piotr Nowak', address: 'esPn4Wq8TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtK2s@epicbox.epicnet.us', tor: 'mbkzvq3uyx7nqk2ahtr4oewl6jx5fdcpsy3givn2rw7bmkhq5ufk7uyd.onion', note: 'Design work'),
    Contact(id: 'c7', name: 'Ola Wiśniewska', note: 'Stock wallet', address: _olaAddr),
    Contact(id: 'c8', name: 'Northwind Exchange', address: _northwindAddr),
    Contact(id: 'c9', name: 'Marta W.', address: 'esQka2Wq8TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3x@epicbox.epiccash.com'),
    // Seeded into every new wallet.
    Contact(id: 'btlabs', name: btLabsContact.name, address: btLabsContact.address, note: btLabsContact.note),
  ];

  late final List<Tx> _txs = [
    if (otherWalletRows) ...[
      Tx(id: 107, slateId: '', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(35.4), fee: 0, created: _ago(hours: 20), confirmations: 14, height: 2917120, otherWallet: true, confirmedAt: _ago(hours: 20)),
      Tx(id: 108, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(6.2), fee: 0, created: _ago(days: 2, hours: 3), confirmations: 410, height: 2916580, otherWallet: true, confirmedAt: _ago(days: 2, hours: 3)),
    ],
    Tx(id: 39, slateId: 'b7e2c1d4-8f3a-4e21-9c7b-5a1d2e3f4a5b', direction: TxDirection.received, state: TxState.confirming, method: TxMethod.epicbox, amount: _epic(25), fee: 0, created: _ago(minutes: 18), confirmations: _lunchConfirmations, counterparty: _contacts[0].address, contactName: 'Anna Kowalska', message: 'Lunch, thanks', height: 2914410),
    Tx(id: 38, slateId: 'a1f9e8d7-6c5b-4a39-8271-605f4e3d2c1b', direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.file, amount: _epic(12.5), fee: _epic(0.007), cancellable: true, created: _ago(hours: 3), counterparty: 'a1f9e8d7.tx'),
    Tx(id: 37, slateId: 'c3d4e5f6-0718-4293-a4b5-c6d7e8f90a1b', direction: TxDirection.sent, state: TxState.posted, method: TxMethod.epicbox, amount: _epic(3.2), fee: _epic(0.006), created: _ago(hours: 5), counterparty: _contacts[4].address, contactName: 'Merchant: Coffee'),
    Tx(id: 36, slateId: 'd4e5f607-1829-43a4-b5c6-d7e8f90a1b2c', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(148.73215), fee: 0, created: _ago(days: 1, hours: 2), confirmations: 1440, counterparty: _contacts[1].address, contactName: 'Mining pool payouts', height: 2913020, kernel: '09a1c3e5f7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3', hasProof: true, proofSender: 'esMockSender1KeyForDemoProofOnly0123456789abcdefghijklmn', proofSignature: '304402200011c2d3e4f5061728394a5b6c7d8e9f00112233445566778899aabbccddeeff0011'),
    Tx(id: 35, slateId: 'e5f60718-2a3b-44c5-d6e7-f8091a2b3c4d', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.http, amount: _epic(40), fee: _epic(0.008), created: _ago(days: 2, hours: 6), confirmations: 2810, counterparty: 'http://10.0.1.24:3415', contactName: 'Tom', height: 2911600, kernel: '08b2d4f6a8c0e2b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4', hasProof: true, proofSender: 'esMockSender2KeyForDemoProofOnly0123456789abcdefghijklmn', proofSignature: '304402200021c2d3e4f5061728394a5b6c7d8e9f00112233445566778899aabbccddeeff0011', label: 'Rent, October', manualFields: {ManualField.label}, manualEditedAt: _ago(days: 2)),
    Tx(id: 34, slateId: 'f6071829-3b4c-45d6-e7f8-091a2b3c4d5e', direction: TxDirection.sent, state: TxState.cancelled, method: TxMethod.epicbox, amount: _epic(5), fee: _epic(0.006), created: _ago(days: 3), counterparty: _contacts[2].address, contactName: 'Exchange deposit'),
    Tx(id: 101, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(2), fee: 0, created: _ago(days: 4), confirmations: 620, height: 2913794, coinbase: true, confirmedAt: _ago(days: 4)),
    Tx(id: 102, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(7.5), fee: 0, created: _ago(days: 4, hours: 6), confirmations: 900, height: 2913500, foundByScan: true, foundDuring: FoundDuring.restore, confirmedAt: _ago(days: 4, hours: 6)),
    Tx(id: 33, slateId: '0718293a-4c5d-46e7-f809-1a2b3c4d5e6f', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.tor, amount: _epic(0.5), fee: 0, created: _ago(days: 5), confirmations: 5700, counterparty: 'http://3fz7k2mq9xr4tbv6.onion', height: 2908700, kernel: '07c3e5a7b9d1f3e5a7c9b1d3f5e7a9c1b3d5e7f9a1c3b5d7e9f1a3c5b7d9e1f3a5'),
    Tx(id: 103, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(4.25), fee: 0, created: _ago(days: 6), confirmations: 8600, height: 2905800, foundByScan: true, foundDuring: FoundDuring.rescan, confirmedAt: _ago(days: 6), counterparty: _contacts[1].address, transport: 'epicbox', note: 'Weekly payout from the pool.', label: 'Pool payout, March', manualFields: {ManualField.label, ManualField.counterparty, ManualField.transport, ManualField.note}, manualEditedAt: _ago(days: 1)),
    Tx(id: 104, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(1.1), fee: 0, created: _ago(days: 7), confirmations: 10000, height: 2904400, foundByScan: true, foundDuring: FoundDuring.rescan, datedByBlock: false),
    Tx(id: 105, slateId: '', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(0.8), fee: 0, created: _ago(days: 8), confirmations: 11400, height: 2903000, foundByScan: true, confirmedAt: _ago(days: 8)),
    Tx(id: 32, slateId: '18293a4b-5d6e-47f8-091a-2b3c4d5e6f70', direction: TxDirection.received, state: TxState.confirmed, method: TxMethod.file, amount: _epic(1000), fee: 0, created: _ago(days: 9), confirmations: 11500, counterparty: 'receive_1000.slate.json', height: 2902900, kernel: '06d4f6b8a0c2e4f6b8d0a2c4e6f8b0d2a4c6e8f0b2d4a6c8e0f2b4d6a8c0e2f4b6'),
    Tx(id: 31, slateId: '293a4b5c-6e7f-4809-1a2b-3c4d5e6f7081', direction: TxDirection.sent, state: TxState.confirmed, method: TxMethod.epicbox, amount: _epic(250), fee: _epic(0.012), created: _ago(days: 14), confirmations: 18700, counterparty: _contacts[2].address, contactName: 'Exchange deposit', height: 2895700, hasProof: true, proofSender: 'esMockSender3KeyForDemoProofOnly0123456789abcdefghijklmn', proofSignature: '304402200031c2d3e4f5061728394a5b6c7d8e9f00112233445566778899aabbccddeeff0011', kernel: '05e5a7c9b1d3f5a7e9c1b3d5f7a9e1c3b5d7f9a1e3c5b7d9f1a3e5c7b9d1f3a5e7', label: 'Exchange top-up', manualFields: {ManualField.label}, manualEditedAt: _ago(days: 9)),
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
    NodeServer(url: 'https://node.btlabs.uk', label: 'BT Labs', operator: 'BT Labs', health: ServiceHealth.ok, latencyMs: 18, height: 2914414, version: '4.1.1', icon: mockServerIcon('7f31acd64c95a28ca70a'), listedAs: 'btlabs'),
    NodeServer(url: 'https://node.epicnet.us:3413', label: 'EpicNet', operator: 'EpicNet', health: ServiceHealth.ok, latencyMs: 132, height: 2914414, version: '4.1.1', listedAs: 'epicnet.us'),
    NodeServer(url: 'https://node.epiccash.com:3413', label: 'Epic Cash', operator: 'Epic Cash', health: ServiceHealth.slow, latencyMs: 940, height: 2914413, version: '4.1.1', icon: mockServerIcon('41bec7e038f3b806b2db'), listedAs: 'Epic Cash'),
    NodeServer(url: 'https://epic.stackwallet.com:3413', label: 'Cypher Stack', operator: 'Cypher Stack', health: ServiceHealth.ok, latencyMs: 210, height: 2914414, version: '4.1.0', icon: mockServerIcon('9a573fcde155e6753f68'), listedAs: 'Cypher Stack'),
    NodeServer(url: 'https://epic-node.iniaku.my.id', label: 'Iniaku pool', operator: 'Iniaku pool', health: ServiceHealth.down, version: '4.1.1', icon: mockServerIcon('73de63f69b0165b85c44'), listedAs: 'Iniaku pool'),
    NodeServer(url: 'http://10.0.1.24:3413', label: 'Home node', health: ServiceHealth.ok, latencyMs: 6, height: 2914414, version: '4.1.1', own: true),
  ];

  // As status.btlabs.uk lists them: the icons and operator names it serves; Iniaku's relay
  // with no health yet.
  final List<EpicboxServer> _epicboxes = [
    EpicboxServer(domain: 'epicbox.stackwallet.com', operator: 'Cypher Stack', health: ServiceHealth.ok, latencyMs: 141, icon: mockServerIcon('9a573fcde155e6753f68'), listedAs: 'Cypher Stack'),
    EpicboxServer(domain: 'epicbox.epicnet.us', operator: 'EpicNet', health: ServiceHealth.slow, latencyMs: 1210, listedAs: 'epicnet.us'),
    EpicboxServer(domain: 'epicbox.epiccash.com', operator: 'Epic Cash', health: ServiceHealth.ok, latencyMs: 96, icon: mockServerIcon('41bec7e038f3b806b2db'), listedAs: 'Epic Cash'),
    EpicboxServer(domain: 'epicbox.iniaku.my.id', operator: 'Iniaku pool', health: ServiceHealth.checking, icon: mockServerIcon('73de63f69b0165b85c44'), listedAs: 'Iniaku pool'),
  ];

  final List<WalletEntry> _wallets = [
    WalletEntry(id: 'legacy-mainnet', name: 'Main wallet', folder: '~/.epic_cash_desktop/wallet', network: 'mainnet', lastOpened: _ago(minutes: 20)),
    WalletEntry(id: '5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', name: 'Savings', folder: '~/.epic_cash_desktop/wallets/5a1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f', network: 'mainnet', lastOpened: _ago(days: 3)),
    WalletEntry(id: '0a1b2c3d4e5f60718293a4b5c6d7e8f9', name: 'Test', folder: '~/.epic_cash_desktop/dev/floonet/wallets/0a1b2c3d4e5f60718293a4b5c6d7e8f9', network: 'floonet', lastOpened: _ago(days: 60)),
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

  final Set<String> _setupRestored = {};

  @override
  Future<bool> setupRestored(String id) async => _setupRestored.contains(id);

  @override
  Future<void> setSetupRestored(String id) async => _setupRestored.add(id);

  @override
  Future<void> selectWallet(String id) async => _current = id;

  @override
  Future<void> renameWallet(String id, String label) async {
    await _wait(0.5);
    final i = _wallets.indexWhere((w) => w.id == id);
    if (i >= 0) _wallets[i] = _with(_wallets[i], name: label.trim());
  }

  @override
  Future<bool?> phraseIsOf(String id, List<String> phrase) async => phrase.firstOrNull != 'legal';

  /// The mock knows no phrase: one starting with "legal" is another wallet's.
  @override
  Future<void> dismissHistoryImportOffer() async {}

  @override
  Future<void> resetPassword(String id, {required List<String> phrase, required String newPassword}) async {
    await _wait(3);
    if (phrase.firstOrNull == 'legal') throw const DeskError('This phrase belongs to another wallet. Nothing was changed.', wrongPhrase: true);
    _remembered.remove(id);
    _current = id;
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

  // Import: three old wallets (four in a development build); the epic program's is in use until checked again. An old
  // password starting with "wrong" is wrong.
  static final List<OldWallet> _oldWallets = [
    OldWallet(id: 'sav', name: 'Savings', folder: '~/.epic/main/Savings', group: OldWalletGroup.gui, lastUsed: _ago(days: 39), sizeBytes: 38 << 20),
    OldWallet(id: 'eve', name: 'Everyday', folder: '~/.epic/Everyday/main', group: OldWalletGroup.gui, lastUsed: _ago(days: 19), sizeBytes: 112 << 20),
    // A test network's old wallet shows in development builds only.
    if (DeskFeatures.testNetworks) OldWallet(
      id: 'tst',
      name: 'Testing',
      folder: '~/.epic/floo',
      group: OldWalletGroup.gui,
      network: 'floonet',
      lastUsed: _ago(days: 21),
      sizeBytes: 3 << 20,
      blocked: 'Test network wallet. It can\'t be imported.',
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
    final entry = WalletEntry(id: 'imp-$id', name: name, folder: '~/.epic_cash_desktop/wallets/imp-$id', network: 'mainnet');
    _wallets.add(entry);
    _current = entry.id;
    _imported.add(entry.id);
    return ImportedWallet(
      id: entry.id,
      name: name,
      proof: const [ImportProof('Seed read'), ImportProof('Wallet created'), ImportProof('Old folder unchanged')],
      // Savings used another Epicbox server in the older app.
      oldRelay: id == 'sav' ? 'epicbox.example.org' : null, // l10n-ok: a host
      appRelay: _epicbox,
      newPassword: newPassword != null,
    );
  }

  /// Tests: the [keepOldRelay] calls, as `id:keep`.
  final List<String> relayChoices = [];

  @override
  Future<void> keepOldRelay(String id, {required bool keep}) async => relayChoices.add('$id:$keep');

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
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase, BigInt? startHeight}) async {
    restoreStartHeight = startHeight;
    final same = await walletWithPhrase(phrase);
    if (same != null) throw DeskError('This wallet is already here: ${same.name}', sameWallet: same);
    await _wait(3);
    _phrases[phraseFingerprint(phrase.join(' '))] = _addWallet(name);
  }

  /// The start height the last restore asked for (null: the whole chain).
  BigInt? restoreStartHeight;

  /// The new wallet is listed as the next free "Wallet N" (or [name]) and is the selected one.
  /// Returns its id.
  String _addWallet(String name) {
    var n = 1;
    while (_wallets.any((w) => w.name == 'Wallet $n')) {
      n++;
    }
    final label = name.trim().isEmpty ? 'Wallet $n' : name.trim();
    final id = 'new-${_wallets.length}-${DateTime.now().microsecondsSinceEpoch}';
    _wallets.add(WalletEntry(id: id, name: label, folder: '~/.epic_cash_desktop/wallets/$id', network: 'mainnet'));
    _current = id;
    return id;
  }

  @override
  Future<WalletAccount> account() async =>
      WalletAccount(id: 'legacy-mainnet', name: _wallets.where((w) => w.id == 'legacy-mainnet').firstOrNull?.name ?? 'Main wallet', network: 'mainnet', folder: '~/.epic_cash_desktop/wallet', created: DateTime(2024, 3, 14));

  @override
  Future<Balance> balance() async {
    await _wait(0.3);
    final p = proto;
    final held = _heldValue();
    final lunch = _lunchCounted ? _epic(25) : 0;
    return Balance(
      spendable: _epic(1284.73215) + lunch + p.spendDelta - held,
      awaitingConfirmation: _epic(25) - lunch + p.confirmingDelta,
      locked: _epic(15.713) + p.lockDelta + held,
      awaitingFinalization: _epic(12.5),
      immature: _epic(2),
      minConfirmations: _minConf,
    );
  }

  @override
  Future<List<Tx>> transactions() async {
    await _wait(0.5);
    proto;
    final rows = [for (final t in seedInvoices ? _txs : _txs.where((t) => t.flow != TxFlow.invoice)) t.withConfirmationsNeeded(_minConf), ..._deviceTxs()];
    return List.unmodifiable(rows..sort((a, b) => b.created.compareTo(a.created)));
  }

  @override
  Future<List<Output>> outputs() async {
    await _wait(0.5);
    final held = _heldBy();
    if (held.isEmpty) return _counted;
    return [
      for (final o in _counted)
        if (o.spendable && held.containsKey(o.commitment))
          Output(commitment: o.commitment, value: o.value, status: OutputStatus.locked, height: o.height, confirmations: o.confirmations, heldBy: held[o.commitment])
        else
          o,
    ];
  }

  // Linked devices: the book the screens keep, read here as the real adapter reads it.
  DeviceBook? Function()? _deviceBook;

  @override
  DeviceHost? deviceHost({required bool Function() online}) => _MockDeviceHost(pairing, online, walletOutputs);

  /// The canned outputs as the core lists them, for linked devices.
  Future<List<WalletOutput>> walletOutputs() async => [
    for (final o in _outputs)
      if (o.status == OutputStatus.unspent || o.status == OutputStatus.locked || o.status == OutputStatus.spent)
        WalletOutput(
          commitment: o.commitment,
          value: BigInt.from(o.value),
          status: switch (o.status) {
            OutputStatus.locked => WalletOutputStatus.locked,
            OutputStatus.spent => WalletOutputStatus.spent,
            _ => WalletOutputStatus.unspent,
          },
          category: o.status == OutputStatus.unspent ? OutputCategory.spendable : null,
          isCoinbase: false,
          height: BigInt.from(o.height ?? 0),
          lockHeight: BigInt.zero,
          confirmations: BigInt.from(o.confirmations),
          txId: o.txId,
        ),
  ];

  @override
  void useDevices(DeviceBook? Function()? book) => _deviceBook = book;

  Map<String, String> _heldBy() {
    final book = _deviceBook?.call();
    if (book == null) return const {};
    return {
      for (final h in book.holds)
        if (h.state.holds)
          for (final c in h.commitments) c: book.device(h.deviceId)?.name ?? h.deviceName ?? '',
    };
  }

  int _heldValue() {
    final held = _heldBy();
    return _outputs.where((o) => o.spendable && held.containsKey(o.commitment)).fold(0, (sum, o) => sum + o.value);
  }

  /// The other devices' payments as history rows (pending, or spent and in a block).
  List<Tx> _deviceTxs() {
    final book = _deviceBook?.call();
    if (book == null) return const [];
    return [
      for (final (i, h) in book.holds.where((h) => h.state.holds || h.state == HoldState.spent || h.state.freed).indexed)
        Tx(
          id: -100 - i,
          slateId: h.slateId,
          direction: TxDirection.sent,
          state: h.state == HoldState.spent
              ? TxState.confirmed
              : h.state.freed
              ? TxState.cancelled
              : (h.state == HoldState.posted ? TxState.posted : TxState.waitingRecipient),
          method: TxMethod.epicbox,
          amount: h.amount.toInt(),
          fee: h.fee?.toInt() ?? 0,
          created: h.createdAt ?? h.lockedAt,
          counterparty: h.counterparty,
          message: h.message,
          deviceName: book.device(h.deviceId)?.name ?? h.deviceName,
          deviceEnding: h.ending,
          deviceWhy: h.ending == DeviceEnding.failed ? h.why : null,
          key: 'd:${h.deviceId}:${h.slateId}',
        ),
    ];
  }

  /// [_outputs] counted with the wallet's minimum confirmations.
  List<Output> get _counted => [for (final o in _outputs) o.withConfirmationsNeeded(_minConf)];

  late List<Output> _outputs = _cannedOutputs();

  List<Output> _cannedOutputs() {
    final cmt = mockCommitment;
    return [
      Output(commitment: cmt(1), value: _epic(25), status: OutputStatus.confirming, height: 2914410, confirmations: _lunchConfirmations),
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

  List<Output> get _spendable => _counted.where((o) => o.spendable).toList()..sort((a, b) => a.value.compareTo(b.value));

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

  /// The wallet's minimum confirmations ([setMinimumConfirmations]).
  int _minConf = defaultMinimumConfirmations;

  /// Tests: [setMinimumConfirmations] fails, as a core error would.
  bool refuseMinConfirmations = false;

  /// The 25 EPIC lunch payment (transaction 39, the first output): in a block, a few
  /// confirmations in, so a count at or below this makes it spendable.
  static const _lunchConfirmations = 4;
  bool get _lunchCounted => _lunchConfirmations >= _minConf;

  @override
  Future<int> minimumConfirmations() async => _minConf;

  @override
  Future<void> setMinimumConfirmations(int count) async {
    await _wait(0.2);
    if (refuseMinConfirmations) throw DeskError('Could not save the setting');
    if (count < minMinimumConfirmations || count > maxMinimumConfirmations) throw DeskError('Minimum confirmations must be $minMinimumConfirmations–$maxMinimumConfirmations');
    _minConf = count;
    _changes.add(null);
  }

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
        o.withConfirmationsNeeded(_minConf).spendable
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
    // A relay added by hand is in no list: it is still the one in use.
    final box = _epicboxes.firstWhere((e) => e.domain == _epicbox, orElse: () => EpicboxServer(domain: _epicbox, health: ServiceHealth.checking));
    return ServiceStatus(
      node: node,
      nodeHealth: node.health,
      nodeHeight: 2914414,
      epicbox: box,
      epicboxHealth: _listening ? (epicboxBlocked ? ServiceHealth.down : box.health) : ServiceHealth.off,
      epicboxBlocked: _listening && epicboxBlocked,
      epicboxInstead: _listening && epicboxBlocked ? epicboxInstead : null,
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
  Future<String> epicboxAddress() async => '$_epicboxKey@$_epicbox';

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
  bool epicboxAddressOtherChain(String to) => false;

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
    if (r.method == TxMethod.file) return SendFileReady(tx, sendFileName(tx.slateId));
    // Through a pairing's mailbox: the prototype's pairing engine knows whom it went to.
    if (r.pairingId case final id?) pairing.slates[tx.slateId] = PairingSlate(pairingId: id, purpose: SlatePurpose.payment);
    return SendDone(tx);
  }

  @override
  Future<ReceivedFile> receiveFile(String fileName) async {
    await _wait(2);
    const slateId = '9a8b7c6d-5e4f-4321-8765-0fedcba98765';
    final tx = Tx(id: _nextId++, slateId: slateId, direction: TxDirection.received, state: TxState.waitingRecipient, method: TxMethod.file, amount: _epic(42), fee: 0, cancellable: true, created: DateTime.now(), counterparty: fileName);
    return ReceivedFile(tx, responseFileName(slateId));
  }

  @override
  Future<ReceivedFile> receiveText(String text) => receiveFile('pasted');

  @override
  String network = 'mainnet';

  @override
  Future<void> useNetwork(String network) async => this.network = network;

  @override
  Future<Tx> finalizeFile(String fileName) => _running(() => _finalize(fileName));

  /// The tour's and tests' answer text names its stage as a slate does (`"sta":"S2"`).
  @override
  Future<bool> isResponseText(String text) async => RegExp(r'"sta"\s*:\s*"S[23]"').hasMatch(text);

  @override
  Future<Tx> finalizeText(String text) => _running(() => _finalize('pasted'));

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

  /// Replaces row [key] with the user's entries; null when no row has that key.
  Tx? _typed(String key, Tx Function(Tx t) change) {
    final i = _txs.indexWhere((t) => t.key == key);
    if (i < 0) return null;
    return _txs[i] = change(_txs[i]);
  }

  @override
  Future<void> setTxLabel(String key, String? label) async {
    await _wait(0.3);
    final text = (label ?? '').trim();
    if (text.length > txLabelMaxLength) throw const DeskError('The label is too long');
    if (_typed(key, (t) => t.withManual(label: text, editedAtUnix: _nowUnix)) == null) throw const DeskError('No such payment');
  }

  @override
  Future<void> setTxDetails(String key, {String? counterparty, String? transport, String? note}) async {
    await _wait(0.3);
    final row = _txs.where((t) => t.key == key).firstOrNull;
    if (row == null || !row.restored) throw const DeskError('Only a payment found by a scan takes details');
    if (transport != null && transport.isNotEmpty && !txTransports.contains(transport)) throw DeskError('Unknown method $transport');
    _typed(key, (t) => t.withManual(counterparty: (counterparty ?? '').trim(), transport: (transport ?? '').trim(), note: (note ?? '').trim(), editedAtUnix: _nowUnix));
  }

  int get _nowUnix => DateTime(2026, 10, 21, 14, 30).millisecondsSinceEpoch ~/ 1000;

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
      Contact(id: id, name: contact.name, epicbox: contact.epicbox, http: contact.http, tor: contact.tor, note: contact.note, favourite: contact.favourite, lastUsed: contact.lastUsed, hasPicture: contact.hasPicture),
    );
    // A payment to one of its addresses takes its name, as the real wallet's rows do.
    for (final (i, t) in _txs.indexed) {
      if (t.pairingId == null && !t.toSelf && t.counterparty != null && contact.addresses.contains(t.counterparty)) _txs[i] = t.withManual(contactName: contact.name);
    }
    return id;
  }

  @override
  Future<void> deleteContact(String id) async {
    final gone = _contacts.where((c) => c.id == id).expand((c) => c.addresses).toSet();
    // The rows first: they are seeded from the book as it was.
    final txs = _txs;
    _contacts.removeWhere((c) => c.id == id);
    // Its payments lose the name, as the real wallet's rows do (a pairing's keep theirs there).
    for (final (i, t) in txs.indexed) {
      if (t.contactName != null && t.pairingId == null && gone.contains(t.counterparty)) txs[i] = t.withManual(contactName: null);
    }
  }

  @override
  Future<void> saveSettings(DeskSettings settings) async {
    // The network mode as the real wallet takes it: Tor only keeps the Tor switch on.
    final mode = netModeOf(settings.advanced.networkMode);
    NetGate.set(mode);
    NetGate.setPayments(settings.payments);
    NetGate.setExperimental(settings.advanced);
    if (!settings.payments.epicbox) _listening = false;
    // Link · HTTP is the one HTTP switch (the adapter): the listener follows it, on while
    // Tor is off, off at once.
    settings = settings.copyWith(directHttp: settings.payments.linkHttp, httpAutostart: settings.payments.linkHttp);
    if (!settings.payments.linkHttp) {
      _http = false;
    } else if (!_settings.payments.linkHttp && !settings.tor) {
      _http = true;
    }
    _settings = mode == NetworkMode.torOnly ? settings.copyWith(torAutostart: true) : settings;
  }

  @override
  Future<void> useNode(String url) async {
    await _wait();
    _node = url;
    // The real wallet reopens on the new node: a new session.
    _sessionRevision++;
  }

  /// Every [useNodeForSession] call, in order, for tests.
  final List<String> sessionNodes = [];

  @override
  Future<void> useNodeForSession(String url) async {
    await _wait();
    sessionNodes.add(url);
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
    epicboxBlocked = false;
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
    if (on && !_settings.payments.epicbox) throw DeskError.l10n((l) => l.netBlockEpicboxOff);
    _listening = on;
  }

  @override
  Future<void> startAutostart() async {
    if (_settings.epicboxAutostart && _settings.payments.epicbox) await setEpicboxListening(true);
    if (_settings.payments.linkHttp && !_settings.torAutostart) await setHttpListening(true);
    if (_settings.torAutostart) await setTor(true);
  }

  @override
  Future<void> setHttpListening(bool on) async {
    await _wait();
    // As the adapter: Offline on a node that is not local refuses it.
    if (on && NetGate.offline && !isLocalAddressUrl(_node)) throw DeskError.l10n((l) => l.deskShellOffline);
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
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false, BigInt? startHeight}) async* {
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

  /// Tests turn it off for a core like LEPIC's, which saves no request files.
  @override
  bool supportsRequestFiles = true;

  @override
  int get sessionRevision => _sessionRevision;
  int _sessionRevision = 0;

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
  Future<RequestFileMade> requestFile({required int amount, String? message}) async {
    await _wait(0.8);
    final r = proto.requestFile(amount, message);
    proto._changed();
    return RequestFileMade(slateId: r.slateId, json: '{"id":"${r.slateId}","sta":"I1","amt":"$amount"}'); // l10n-ok: a slate
  }

  /// The prototype's request file to pay: a file whose name or text says it is one
  /// (`request` in the name, or `"sta":"I1"` in the text), from someone unnamed.
  static const String mockRequestSlate = '9c8d7e6f-1a2b-4c3d-8e9f-0a1b2c3d4e5f'; // l10n-ok

  /// What [readRequestFile] reads, for tests; null keeps the prototype's.
  RequestFile? requestFileValue;

  RequestFile _mockRequest(String source) =>
      requestFileValue ??
      RequestFile(
        slateId: mockRequestSlate,
        amount: _epic(12.5),
        fee: _epic(0.007),
        feeKnown: true,
        message: 'Invoice 2026-118, two bags of beans', // l10n-ok: the other side's text
        json: '{"id":"$mockRequestSlate","sta":"I1"}', // l10n-ok: a slate
        source: source,
        alreadyPaid: _paidRequests.contains(mockRequestSlate),
      );

  final Set<String> _paidRequests = {};

  @override
  Future<RequestFile?> readRequestFile(String path) async {
    await _wait(0.4);
    return path.contains('request') ? _mockRequest(path) : null; // l10n-ok
  }

  @override
  Future<RequestFile?> readRequestText(String text) async =>
      RegExp(r'"sta"\s*:\s*"I1"').hasMatch(text) ? _mockRequest('pasted') : null; // l10n-ok

  @override
  Future<ReceivedFile> payRequestFile(RequestFile file, {required String password}) async {
    await _wait(1.5);
    if (password == 'wrong') throw const InvoiceError(InvoiceProblem.wrongPassword, 'Wrong password'); // l10n-ok
    if (!_paidRequests.add(file.slateId)) throw const InvoiceError(InvoiceProblem.alreadyAnswered, 'This request is already paid.'); // l10n-ok
    final tx = Tx(id: _nextId++, slateId: file.slateId, direction: TxDirection.sent, state: TxState.waitingRecipient, method: TxMethod.file, amount: file.amount, fee: file.fee, cancellable: true, created: DateTime.now(), flow: TxFlow.invoice);
    _txs.insert(0, tx);
    return ReceivedFile(tx, responseFileName(file.slateId));
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

  /// The prototype's pairing engine: the fake that plays both sides, seeded with the contacts'
  /// pairings. The Prototype panel and the tour drive its other side.
  @override
  late final FakePairing pairing = _seedPairing(FakePairing());

  FakePairing _seedPairing(FakePairing p) {
    p.clock = () => proto.now;
    p.homeRelay = _epicbox;
    p.seedPaired(id: mockAnnaPairing, name: 'Anna', contactId: 'c1', paymentsAddress: _annaAddr, verifiedAt: DateTime(2026, 10, 20));
    p.seedPaired(
      id: mockNorthwindPairing,
      name: 'Northwind Exchange',
      contactId: 'c8',
      kind: PairingParty.exchange,
      caps: const PairingCaps(issuesInvoices: true, sharedInbox: true, sendsWithdrawals: true),
      allowInvoices: true,
      paymentsAddress: _northwindAddr,
      relay: 'relay.northwind.example',
      verifiedAt: DateTime(2026, 10, 20),
    );
    p.seedPaired(
      id: mockCoffeePairing,
      name: 'Coffee Roasters',
      contactId: 'c5',
      kind: PairingParty.shop,
      caps: const PairingCaps(issuesInvoices: true),
      allowInvoices: true,
      paymentsAddress: _coffeeAddr,
      relay: 'epicbox.stackwallet.com',
      verifiedAt: DateTime(2026, 9, 2),
    );
    p.seedPaired(id: mockTomPairing, name: 'Tom', contactId: 'c4', state: PairingState.paired, paymentsAddress: _tomAddr, seal: SealMode.degraded, checkSkipped: true);
    p.seedPaired(id: mockMartaPairing, name: 'Marta', contactId: 'c9', state: PairingState.keysChanged, verifiedAt: DateTime(2026, 8, 30));
    return p;
  }

  @override
  Future<void> setInvoiceExpiry(Duration expiry) async {
    await _wait(0.2);
    proto.expiry = expiry > maxInvoiceExpiry ? maxInvoiceExpiry : expiry;
    proto._changed();
  }

  @override
  Future<List<String>> revealPhrase(String password) async {
    await _wait(2);
    if (password == 'wrong') throw StateError('Wrong password');
    return _words;
  }

  /// The id of [addSenderPostedDemo]'s payment.
  static const senderPostedDemoId = 140;

  /// For the tour: Anna's Epicbox payment, answered here, whose sender reports it posted
  ///. Only its own shots add it, so the other shots keep their rows.
  void addSenderPostedDemo() {
    if (_txs.any((t) => t.id == senderPostedDemoId)) return;
    _txs.insert(
      0,
      Tx(id: senderPostedDemoId, slateId: 'c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f', direction: TxDirection.received, state: TxState.waitingRecipient, method: TxMethod.epicbox, amount: _epic(7.25), fee: 0, created: _ago(minutes: 4), counterparty: _contacts[0].address, contactName: 'Anna Kowalska', cancellable: true, transport: 'epicbox', senderPosted: true),
    );
  }

  static const receiveHoldDemoId = 9141;
  static const receiveOfferedDemoId = 9142;

  /// For the tour: Anna's Epicbox payment, answered here [ago] (5 minutes: inside the Cancel
  /// hold; 40: Cancel offered), waiting for its sender. Only its own shots add it.
  void addReceiveCancelDemo({required int id, required Duration ago}) {
    if (_txs.any((t) => t.id == id)) return;
    _txs.insert(
      0,
      Tx(id: id, slateId: 'd2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a', direction: TxDirection.received, state: TxState.waitingRecipient, method: TxMethod.epicbox, amount: _epic(7.25), fee: 0, created: DateTime.now().subtract(ago), counterparty: _contacts[0].address, contactName: 'Anna Kowalska', cancellable: true, transport: 'epicbox'),
    );
  }

  /// The history backup record the Backup rows and the reminder show; tours and tests set it.
  HistoryBackupState backup = HistoryBackupState(lastExport: DateTime(2026, 10, 3, 14, 2), unbacked: 12, payments: 48, contacts: 6);

  /// What the next [importHistory] answers: a [HistoryImport] or a [HistoryFileError]. After a
  /// good import the same file again adds nothing.
  Object? nextImport;
  bool _historyImported = false;

  /// Fields the next [importHistory] without choices reports as differing from what the user
  /// typed (then nothing is written until it is called again with [lastUseBackup]'s choices).
  List<ImportConflict> importConflicts = const [];

  /// The choices of the last [importHistory] call.
  Map<String, bool>? lastUseBackup;

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

  /// What the old wallet's history waits for; set by a test or a preview.
  List<ImportConflict> oldHistory = const [];

  /// The choices of the last [resolveOldHistory] call, `null` for a postponed one.
  Map<String, bool>? lastUseOldWallet;

  @override
  List<ImportConflict> get oldHistoryConflicts => oldHistory;

  @override
  Future<void> resolveOldHistory(Map<String, bool>? useOldWallet) async {
    lastUseOldWallet = useOldWallet;
    oldHistory = const [];
  }

  @override
  Future<HistoryImport> importHistory(Uint8List data, {Map<String, bool>? useBackup}) async {
    await _wait(2);
    lastUseBackup = useBackup;
    if (importConflicts.isNotEmpty) {
      // Nothing is written until the user has chosen.
      if (useBackup == null) return HistoryImport(conflicts: importConflicts, applied: false);
      var replaced = 0;
      for (final c in importConflicts) {
        if (useBackup[c.id] != true) continue;
        replaced++;
        _typed(
          c.key,
          (t) => t.withManual(
            label: c.field == ManualField.label ? c.theirs : null,
            counterparty: c.field == ManualField.counterparty ? c.theirs : null,
            transport: c.field == ManualField.transport ? c.theirs : null,
            note: c.field == ManualField.note ? c.theirs : null,
            editedAtUnix: _nowUnix,
          ),
        );
      }
      importConflicts = const [];
      return HistoryImport(merged: 1, skipped: 40, replaced: replaced);
    }
    final next = nextImport;
    if (next is HistoryFileError) throw next;
    if (next is HistoryImport) return next;
    if (_historyImported) return const HistoryImport(skipped: 46);
    _historyImported = true;
    return const HistoryImport(merged: 3, added: 2, skipped: 41, contactsAdded: 1);
  }

  /// This wallet's lists, own Epicbox server and deleted seed contacts as a backup restores
  /// them ([restoreBackupItems]); tests read and set them.
  ServerList nodeList = const ServerList();
  ServerList relayList = const ServerList();
  String? ownRelay;
  final Set<String> seedsDeleted = {};

  @override
  Future<DeskBackupSettings> backupSettings() async => DeskBackupSettings(
    chain: 'mainnet',
    mine: deskBackupMap(
      _settings,
      chain: 'mainnet',
      outputs: _prefs,
      node: _node,
      relay: ownRelay ?? _epicbox,
      nodeList: nodeList,
      relayList: relayList,
      ownNodes: [for (final n in _nodes) if (n.own) n],
      invoiceExpiry: proto.expiry,
      seedsDeleted: seedsDeleted,
      ownRelay: ownRelay,
    ),
    defaults: deskBackupMap(
      const DeskSettings(),
      chain: 'mainnet',
      outputs: const OutputPrefs(),
      node: 'https://node.btlabs.uk',
      relay: 'epicbox.epiccash.com',
      nodeList: const ServerList(),
      relayList: const ServerList(),
      ownNodes: const [],
      invoiceExpiry: defaultInvoiceExpiry,
      seedsDeleted: const [],
    ),
  );

  @override
  Future<void> restoreBackupItems({ServerList? nodeList, ServerList? relayList, ({String? relay})? ownRelay, List<String>? seedsDeleted}) async {
    if (nodeList != null) this.nodeList = mergeServerLists(ServerKind.node, this.nodeList, nodeList);
    if (relayList != null) this.relayList = mergeServerLists(ServerKind.relay, this.relayList, relayList);
    if (ownRelay != null) this.ownRelay = ownRelay.relay;
    for (final id in seedsDeleted ?? const <String>[]) {
      if (this.seedsDeleted.add(id) && id == 'btlabs') _contacts.removeWhere((c) => c.id == 'btlabs');
    }
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

/// The mock's linked-devices host: the prototype's pairing engine, no coins of its own.
class _MockDeviceHost implements DeviceHost {
  _MockDeviceHost(this.pairing, this._online, this._outputs);

  @override
  final FakePairing pairing;
  final bool Function() _online;
  final Future<List<WalletOutput>> Function() _outputs;

  @override
  bool get online => _online();

  @override
  Future<String> walletKey() async => _epicboxKey;

  @override
  Future<String> signProof(List<int> message) async => fakeAddressSignature(_epicboxKey, message);

  @override
  Future<bool> verifyProof(String key, List<int> message, String signature) async => signature == fakeAddressSignature(key, message);

  @override
  Future<List<WalletOutput>> outputs() => _outputs();

  @override
  Future<List<TxEntry>> transactions() async => const [];

  @override
  Future<int?> tipHeight() async => null;

  @override
  set heldOutputs(Set<String> commitments) {}
}
