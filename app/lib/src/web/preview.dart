// SPDX-License-Identifier: Apache-2.0
/// The wallet a `WFE_WEB_FAKE=true` web build shows: [FakeWalletService] with the desktop
/// Overview's numbers and payments, outputs, contacts, two invoices to pay and two requests
/// sent, so every phone screen can be previewed in a browser with no server. Nothing here talks
/// to the network. No release script sets the define.
library;

import '../desktop/data/mock_hosts.dart';
import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;

import '../demo.dart' show pinlessProvider;
import '../demo_fixtures.dart';
import '../levels/first_start.dart' show firstStartProvider;
import '../levels/relay_switch_providers.dart' show relaySwitchProvider;
import '../net/http_types.dart' show NetError;
import '../network.dart';
import '../pairing_fake.dart' show fakePairingLink;
import '../phone_tor.dart';
import '../relay_directory.dart';
import '../wallet_service.dart';
import 'preview_levels.dart';
import 'preview_live.dart';

/// `--dart-define=WFE_WEB_FAKE=true`: the web app runs on [previewWalletService].
const bool webFakeBackend = bool.fromEnvironment('WFE_WEB_FAKE');

/// A fresh fake wallet service. The visitor starts at first run; the PIN they choose opens the
/// preview wallet.
FakeWalletService previewWalletService() {
  final session = _previewSession();
  final service = PreviewWalletService(session: session)
    // At the preview directory's tip, so the status card reads Synced.
    ..nodeTipValue = NodeTip(height: _tip, nodeVersion: demoNodeVersion);
  session.tipService = service;
  _previewQrExchange(service, session);
  return service;
}

/// The payment and its reply of the QR method: each long enough for a few parts of the
/// animated code, so the show screen cycles and the simulated camera counts. The wallet reads
/// its own payment as one it was sent, so Scan payment QR → Accept → Show reply as QR works
/// as does Show payment QR → Scan reply QR.
void _previewQrExchange(PreviewWalletService service, FakeWalletSession session) {
  const slateId = 'a1b2c3d4-0001-4e5f-8a9b-000000000099';
  final payment = Slate(
    slateId: slateId,
    json: '{"id":"$slateId","step":"payment","pad":"${'a' * 520}"}',
  );
  final reply = Slate(
    slateId: slateId,
    json: '{"id":"$slateId","step":"response","pad":"${'b' * 330}"}',
  );
  session
    ..sendSlate = payment
    ..responseSlate = reply;
  service.slateInfos[payment.json] = SlateInfo(
    slateId: slateId,
    amount: _epic(3),
    fee: BigInt.from(8000000),
    stage: SlateStage.send,
  );
}

/// The fake wallet with a node test that takes a moment and fails for a host with `down`
/// or `bad` in it, so the pickers' Add can be tried both ways.
class PreviewWalletService extends FakeWalletService {
  PreviewWalletService({super.session});

  /// A wallet opened or made: its payments start to move ([PreviewSession.opened]).
  T _opened<T extends WalletSession>(T session) {
    if (session is PreviewSession) session.opened();
    return session;
  }

  @override
  Future<WalletSession> create({required WalletConfig config, String? mnemonic, required String password}) async =>
      _opened(await super.create(config: config, mnemonic: mnemonic, password: password));

  @override
  Future<WalletSession> open({required WalletConfig config, required String password}) async =>
      _opened(await super.open(config: config, password: password));

  @override
  Future<PinWallet> createWithPin({required WalletConfig config, String? mnemonic, required String pin}) async {
    final wallet = await super.createWithPin(config: config, mnemonic: mnemonic, pin: pin);
    _opened(wallet.session);
    return wallet;
  }

  @override
  Future<WalletSession> openWithPin({required WalletConfig config, required String pin, required String sealedPassword}) async =>
      _opened(await super.openWithPin(config: config, pin: pin, sealedPassword: sealedPassword));

  @override
  Future<NodeTip> nodeAnswer(WalletConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final host = Uri.tryParse(config.nodeUrl)?.host ?? '';
    if (host.contains('down') || host.contains('bad')) {
      throw const NetError('connection refused');
    }
    return nodeTipValue;
  }
}

/// The status site as the preview sees it: the built-in servers with one of each health,
/// one node and one relay only the directory lists (one down), and the chain at the fake
/// wallet's tip. Answers after a moment, so the lists' loading bar shows.
/// An operator's icon on the status site, as its status list names it.
ServerIcon _icon(String hash) => ServerIcon(
  hash: hash,
  urls: {
    for (final px in const [128, 256])
      px: Uri.parse(mockIconUrl(hash, px)),
  },
);

class PreviewDirectory implements RelayDirectory, NodeDirectory, NetworkDirectory {
  const PreviewDirectory();

  static const Duration _delay = Duration(milliseconds: 500);

  @override
  Future<List<NodeStatus>> nodes(String chain) async {
    await Future<void>.delayed(_delay);
    if (chain != 'mainnet') return const [];
    final checked = DateTime.now().subtract(const Duration(minutes: 2));
    final tip = _tip.toInt();
    return [
      NodeStatus(url: mockNodeAt(1), healthy: true, verified: true, operator: 'btlabs', icon: _icon('7f31acd64c95a28ca70a'), height: tip, latencyMs: 20, state: NodeHealthState.healthy, nodeVersion: demoNodeVersion, tipLag: 0, peers: 61, uptime24h: demoNodeUptime, lastCheckedAt: checked),
      NodeStatus(url: mockNodeAt(2), healthy: true, verified: true, operator: mockNodeOp(2), height: tip, latencyMs: 766, state: NodeHealthState.healthy, nodeVersion: demoNodeVersion, tipLag: 0, peers: 61, uptime24h: demoNodeUptime, lastCheckedAt: checked),
      NodeStatus(url: mockNodeAt(0), healthy: true, verified: true, operator: 'Epic Cash', icon: _icon('41bec7e038f3b806b2db'), height: tip, latencyMs: 733, state: NodeHealthState.healthy, nodeVersion: demoNodeVersion, tipLag: 0, peers: 54, uptime24h: demoNodeUptime, lastCheckedAt: checked),
      NodeStatus(url: mockNodeAt(3), healthy: true, verified: true, operator: 'Cypher Stack', icon: _icon('9a573fcde155e6753f68'), height: tip - 12, latencyMs: 1127, state: NodeHealthState.degraded, reason: 'behind', nodeVersion: demoNodeVersion, tipLag: 12, peers: 61, uptime24h: demoNodeUptime, lastCheckedAt: checked),
      NodeStatus(url: 'https://node.epic.example:3413', healthy: false, verified: false, operator: 'Example pool', state: NodeHealthState.down, reason: 'timeout', lastCheckedAt: checked),
    ];
  }

  @override
  Future<List<RelayStatus>> relays(String chain) async {
    await Future<void>.delayed(_delay);
    if (chain != 'mainnet') return const [];
    return [
      RelayStatus(relay: EpicboxRelay(host: mockBox), healthy: true, verified: true, label: 'Default relay', operator: 'Epic Cash', icon: _icon('41bec7e038f3b806b2db'), latencyMs: 766, uptime24h: 0.9966),
      RelayStatus(relay: EpicboxRelay(host: mockBoxAt(1)), healthy: true, verified: true, label: 'Stack Wallet', operator: 'Cypher Stack', icon: _icon('9a573fcde155e6753f68'), latencyMs: 488, uptime24h: 1.0),
      RelayStatus(relay: EpicboxRelay(host: mockBoxAt(2)), healthy: true, verified: true, operator: mockNodeOp(2), latencyMs: 766, uptime24h: 0.9779),
      RelayStatus(relay: EpicboxRelay(host: mockBoxAt(3)), healthy: true, verified: true, operator: 'btlabs', icon: _icon('7f31acd64c95a28ca70a'), latencyMs: 45, uptime24h: 0.9999),
      RelayStatus(relay: EpicboxRelay(host: 'epicbox.epic.example'), healthy: false, verified: false, operator: 'Example pool', uptime24h: 0.41),
    ];
  }

  @override
  Future<NetworkStatus> network(String chain) async {
    await Future<void>.delayed(_delay);
    return NetworkStatus(
      tipHeight: _tip.toInt(),
      tipAgeSeconds: 40,
      releasedNodeVersion: '4.1.1',
      releasedWalletVersion: '4.1.0',
      nodesHealthy: 5,
      nodesTotal: 6,
      epicboxHealthy: 5,
      epicboxTotal: 6,
      medianNodeLatencyMs: 733,
      forked: false,
      healthScore: 90,
    );
  }
}

final BigInt _tip = BigInt.from(demoTip);

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid-looking epicbox address: 52 base58 characters, then the relay. The tour's helper.
String _address(String seed, {String? relay}) {
  relay ??= mockBox;
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  final buffer = StringBuffer('es');
  var n = seed.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  while (buffer.length < 52) {
    n = (n * 1103515245 + 12345) & 0x7fffffff;
    buffer.write(alphabet[n % alphabet.length]);
  }
  return '$buffer@$relay';
}

/// A 66-character commitment from a seed.
String _commit(String seed) {
  const hex = '0123456789abcdef';
  final buffer = StringBuffer('09');
  var n = seed.codeUnits.fold<int>(11, (a, c) => (a * 31 + c) & 0x7fffffff);
  while (buffer.length < 66) {
    n = (n * 1103515245 + 12345) & 0x7fffffff;
    buffer.write(hex[n % 16]);
  }
  return buffer.toString();
}

PreviewSession _previewSession() {
  final tip = _tip;
  final anna = _address('anna');
  final btlabs = _address('btlabs');
  final exchange = _address('exchange');
  final coffee = _address('coffee');
  final pool = _address('pool');
  final tom = _address('tom');
  final biller = _address('northwind', relay: 'epicbox.example.com');
  final now = DateTime.now();
  int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch ~/ 1000;
  // `?pending=0..3` on the page's URL picks how many balances are pending beside the
  // spendable one (locked, then coming in, then not on chain), for design reviews of the
  // balance header; the page's default is all three.
  final pending = int.tryParse(Uri.base.queryParameters['pending'] ?? '') ?? 3;
  final locked = pending >= 1 ? _epic(15.713) : BigInt.zero;
  final confirming = pending >= 2 ? _epic(25) : BigInt.zero;
  final immature = pending >= 2 ? _epic(2) : BigInt.zero;
  final notOnChain = pending >= 3 ? _epic(12.5) : BigInt.zero;
  final session = PreviewSession(
    sender: _address('bob'),
    sendersName: 'Bob',
    summary: WalletSummary(
      lastConfirmedHeight: tip,
      minimumConfirmations: BigInt.from(3),
      total: _epic(1284.73215) + locked + confirming + immature + notOnChain,
      spendable: _epic(1284.73215),
      awaitingConfirmation: confirming,
      awaitingFinalization: notOnChain,
      immature: immature,
      locked: locked,
      validatedWithNode: true,
    ),
    transactions: [
      fakeTx(
        id: 34,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000034',
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: ago(const Duration(minutes: 4)),
        amountCredited: _epic(25),
        numOutputs: 1,
        counterparty: anna,
        messages: const [
          SlateMessage(role: SlateRole.sender, text: 'Lunch, thanks'),
        ],
        blockHeight: tip - BigInt.one,
      ),
      fakeTx(
        id: 33,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000033',
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        createdAtUnix: ago(const Duration(hours: 2, minutes: 40)),
        amountDebited: _epic(12.507),
        amountCredited: BigInt.zero,
        fee: _epic(0.007),
        numInputs: 1,
        numOutputs: 0,
        counterparty: tom,
        note: 'Second half',
        cancellable: true,
      ),
      fakeTx(
        id: 32,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000032',
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: ago(const Duration(hours: 4, minutes: 40)),
        amountDebited: _epic(3.206),
        amountCredited: _epic(12.5),
        fee: _epic(0.006),
        numInputs: 1,
        numOutputs: 1,
        counterparty: coffee,
      ),
      fakeTx(
        id: 31,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000031',
        kind: TxKind.received,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 1, hours: 1, minutes: 40)),
        amountCredited: _epic(148.73215),
        numOutputs: 1,
        counterparty: pool,
        blockHeight: tip - BigInt.from(1200),
        blockTimeUnix: ago(const Duration(days: 1, hours: 1, minutes: 40)),
        kernelExcess: _commit('kernel-31').replaceFirst('09', '08'),
        outputCommits: [_commit('out-31')],
      ),
      fakeTx(
        id: 30,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000030',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 2, hours: 5)),
        amountDebited: _epic(40.008),
        amountCredited: _epic(34.73215),
        fee: _epic(0.008),
        numInputs: 2,
        numOutputs: 1,
        counterparty: tom,
        note: 'Old laptop',
        blockHeight: tip - BigInt.from(2900),
      ),
      fakeTx(
        id: 29,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000029',
        kind: TxKind.sentCancelled,
        status: TxStatus.cancelled,
        createdAtUnix: ago(const Duration(days: 3, hours: 1)),
        amountDebited: _epic(5.006),
        fee: _epic(0.006),
        numInputs: 1,
        counterparty: exchange,
      ),
      // The chain check: another wallet on this recovery phrase spent and received coins.
      fakeTx(
        id: 40,
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        origin: TxOrigin.otherWallet,
        createdAtUnix: ago(const Duration(days: 2, hours: 9)),
        amountDebited: _epic(35.4),
        blockHeight: tip - BigInt.from(2700),
        blockTimeUnix: ago(const Duration(days: 2, hours: 9)),
        spentCommits: [_commit('spent-33')],
      ),
      fakeTx(
        id: 41,
        kind: TxKind.received,
        status: TxStatus.confirmed,
        origin: TxOrigin.otherWallet,
        createdAtUnix: ago(const Duration(days: 3, hours: 2)),
        amountCredited: _epic(6.2),
        blockHeight: tip - BigInt.from(4100),
        blockTimeUnix: ago(const Duration(days: 3, hours: 2)),
        outputCommits: [_commit('out-34')],
      ),
      fakeTx(
        id: 28,
        kind: TxKind.coinbase,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 4)),
        amountCredited: _epic(2),
        blockHeight: tip - BigInt.from(5700),
      ),
      fakeTx(
        key: 'c:restored-1',
        id: 2,
        kind: TxKind.received,
        status: TxStatus.confirmed,
        source: TxSource.restored,
        createdAtUnix: ago(const Duration(days: 6)),
        timeUnix: ago(const Duration(days: 40)),
        blockHeight: tip - BigInt.from(57600),
        blockTimeUnix: ago(const Duration(days: 40)),
        amountCredited: _epic(7.5),
        outputCommits: [_commit('out-2')],
      ),
      fakeTx(
        key: 'c:restored-2',
        id: 3,
        kind: TxKind.received,
        status: TxStatus.confirmed,
        source: TxSource.restored,
        createdAtUnix: ago(const Duration(days: 6)),
        timeUnix: ago(const Duration(days: 52)),
        blockHeight: tip - BigInt.from(74880),
        blockTimeUnix: ago(const Duration(days: 52)),
        amountCredited: _epic(2),
        outputCommits: [_commit('out-3')],
      ),
    ],
  );
  // Two labels, and the sender, method and note of one restored payment.
  session.labels['s:a1b2c3d4-0001-4e5f-8a9b-000000000031'] = 'Pool payout, March';
  session.labels['s:a1b2c3d4-0001-4e5f-8a9b-000000000032'] = 'Coffee beans';
  session.details['c:restored-1'] = (
    counterparty: exchange,
    transport: 'epicbox',
    note: 'Withdrawal from the exchange.',
  );
  session.address = _address('me');
  session.contactsValue.addAll([
    Contact(id: 'c1', name: 'Anna Kowalska', address: anna, note: 'Flatmate'),
    Contact(id: 'c2', name: 'BT Labs', address: btlabs),
    Contact(id: 'c3', name: 'Exchange deposit', address: exchange),
    Contact(id: 'c4', name: 'Merchant: Coffee', address: coffee),
    Contact(id: 'c5', name: 'Mining pool payouts', address: pool),
    Contact(id: 'c6', name: 'Tom', address: tom, note: 'Pays by file'),
    Contact(id: 'c7', name: 'Bob', address: _address('bob')),
  ]);
  // The outputs the balance is made of, as the desktop's Outputs page shows them.
  WalletOutput output(
    String seed,
    num value, {
    required int age,
    WalletOutputStatus status = WalletOutputStatus.unspent,
    OutputCategory? category = OutputCategory.spendable,
    bool coinbase = false,
    int? txId,
  }) => WalletOutput(
    commitment: _commit(seed),
    value: _epic(value),
    status: status,
    category: category,
    isCoinbase: coinbase,
    height: tip - BigInt.from(age),
    lockHeight: tip - BigInt.from(age) + (coinbase ? BigInt.from(1440) : BigInt.zero),
    mmrIndex: BigInt.from(7000000 - age),
    confirmations: status == WalletOutputStatus.unconfirmed
        ? BigInt.zero
        : BigInt.from(age + 1),
    txId: txId,
  );
  session.outputsValue.addAll([
    output('o1', 500, age: 1205, txId: 2),
    output('o2', 412.5, age: 620),
    output('o3', 212.5, age: 89, txId: 31),
    output('o4', 125, age: 42),
    output('o5', 34.73215, age: 301, txId: 30),
    output(
      'o6',
      25,
      age: 1,
      status: WalletOutputStatus.unconfirmed,
      category: OutputCategory.awaitingConfirmation,
      txId: 34,
    ),
    output(
      'o7',
      12.5,
      age: 0,
      status: WalletOutputStatus.unconfirmed,
      category: OutputCategory.awaitingFinalization,
      txId: 32,
    ),
    output(
      'o8',
      15.713,
      age: 350,
      status: WalletOutputStatus.locked,
      category: OutputCategory.locked,
      txId: 33,
    ),
    output(
      'o9',
      2,
      age: 5700,
      category: OutputCategory.immature,
      coinbase: true,
      txId: 28,
    ),
  ]);
  // Pairings (RFC 0002): Anna verified, Tom paired and not checked yet, and Northwind Exchange
  // verified with its invoices allowed; then two invoices from it and two requests this
  // wallet sent.
  session.pairing
    ..autoAnswerAfter = const Duration(seconds: 6)
    // An invite to BT Labs still in flight: its row reads Pairing…
    ..seed(
      PairingRecord(
        id: 'pairing-btlabs',
        state: PairingState.pendingInvite,
        way: PairingWay.link,
        inviter: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        label: 'BT Labs',
        contactId: 'c2',
        expiresAt: now.add(const Duration(hours: 22)),
        inviteLink: fakePairingLink('pair', {'t': 'pairing-btlabs', 'n': 'Alex', 'e': now.add(const Duration(hours: 22)).millisecondsSinceEpoch}),
      ),
    )
    ..seedPaired(name: 'Anna', contactId: 'c1', paymentsAddress: anna, verifiedAt: now.subtract(const Duration(days: 4)))
    ..seedPaired(name: 'Tom', contactId: 'c6', paymentsAddress: tom, state: PairingState.paired)
    ..seedPaired(
      name: 'Northwind Exchange',
      kind: PairingParty.exchange,
      caps: const PairingCaps(issuesInvoices: true, sharedInbox: true, sendsWithdrawals: true),
      allowInvoices: true,
      paymentsAddress: biller,
      relay: 'relay.northwind.example',
    );
  Future<void>.value()
      .then((_) {
        session
          ..relayInvoice(
            from: biller,
            slateId: 'inv-1042',
            amount: _epic(42.5),
            message: 'Deposit to your Northwind account',
            reference: 'Deposit · ref NW-48213',
            expiresIn: const Duration(hours: 23, minutes: 12),
          )
          ..relayInvoice(
            from: biller,
            slateId: 'inv-1043',
            amount: _epic(7),
            message: 'Withdrawal fee',
            expiresIn: const Duration(minutes: 38),
          );
      })
      .then(
        (_) => session.issueToContact(
          amount: _epic(25),
          address: anna,
          message: 'Concert tickets, Friday',
        ),
      )
      .then(
        (_) => session.issueToContact(
          amount: _epic(12),
          address: anna,
          message: 'Pizza',
        ),
      )
      .then((request) => session.payIssued(request.slateId));
  return session;
}

/// The overrides of a `WFE_WEB_FAKE=true` build: Tor as a played-back controller, so the Tor
/// row of the status card and Receive's Tor tab can be seen without a tor binary.
List<Override> previewOverrides() => [
  // The levels: the first-start step on every visit, the normal PIN pad (the fake wallet takes
  // any PIN), and the relay offer played in seconds.
  firstStartProvider.overrideWith(PreviewFirstStart.new),
  pinlessProvider.overrideWithValue(false),
  relaySwitchProvider.overrideWith(PreviewRelaySwitch.new),
  phoneTorProvider.overrideWith(PreviewPhoneTor.new),
  relayDirectoryProvider.overrideWithValue(const PreviewDirectory()),
];

/// Tor for the preview: off until "Tor receiving" is turned on or a send to an onion asks for
/// it, then "connecting" in steps of 20 % every 400 ms, then ready at a fixed onion. Nothing
/// runs.
class PreviewPhoneTor extends PhoneTor {
  static String get onion => mockOnion('wfepreviewk3nq7vmh2xq4cbe6ta5s3l7xw2z5pyp6uh2l3xfi3yk4qd');

  Timer? _timer;
  Completer<void>? _up;

  @override
  PhoneTorState build() {
    ref.onDispose(() => _timer?.cancel());
    return PhoneTorState(phase: PhoneTorPhase.off, onion: onion);
  }

  void _start() {
    if (state.phase == PhoneTorPhase.ready ||
        state.phase == PhoneTorPhase.starting) {
      return;
    }
    _up ??= Completer<void>();
    var progress = 0;
    state = state.copyWith(phase: PhoneTorPhase.starting, progress: () => 0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      progress += 20;
      if (progress < 100) {
        state = state.copyWith(
          phase: PhoneTorPhase.starting,
          progress: () => progress,
        );
        return;
      }
      timer.cancel();
      state = state.copyWith(phase: PhoneTorPhase.ready, progress: () => null);
      _up?.complete();
      _up = null;
    });
  }

  @override
  Future<void> setReceiving(bool on) async {
    state = state.copyWith(receiving: on);
    if (on) {
      _start();
    } else {
      _timer?.cancel();
      state = state.copyWith(phase: PhoneTorPhase.off, progress: () => null);
    }
  }

  @override
  Future<void> ensureForSend() async {
    if (state.phase == PhoneTorPhase.ready) return;
    _start();
    await _up?.future;
  }

  @override
  Future<T> whileSending<T>(Future<T> Function() send) async {
    await ensureForSend();
    return send();
  }

  @override
  Future<void> retry() async {
    state = state.copyWith(phase: PhoneTorPhase.off, progress: () => null);
    _start();
  }
}
