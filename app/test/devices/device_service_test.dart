// Linked devices end to end over the fake engine: a link needs the pictures checked on both
// devices and the same wallet; notices hold and release coins; the one receive path drops what
// it must and keeps the order; removing a device re-keys the others.
import 'dart:convert';

import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/device_wire.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_devices.dart';

const _s1 = 'epicbox.epiccash.com';
const _s2 = 'epicbox.stackwallet.com';

/// [side]'s own send [slate] of 3 EPIC spending coin 2 (as LEPIC lists it), [cancelled] or not.
void _send(Side side, String slate, {int tx = 7, int coinNo = 2, bool cancelled = false}) {
  side.session.transactionsValue = [
    fakeTx(
      id: tx,
      slateId: slate,
      kind: cancelled ? TxKind.sentCancelled : TxKind.sent,
      status: cancelled ? TxStatus.cancelled : TxStatus.awaitingRecipient,
      amountDebited: BigInt.from(300000000 + 800000),
      fee: BigInt.from(800000),
      counterparty: 'esBob@epicbox.epiccash.com',
      cancelReason: cancelled ? CancelReason.user : null,
    ),
  ];
  side.session.outputsValue = [
    for (final o in side.session.outputsValue)
      o.commitment == cm(coinNo) ? coin(coinNo, 3, status: cancelled ? WalletOutputStatus.unspent : WalletOutputStatus.locked, txId: tx) : o,
  ];
}

/// A notice from [from] to [to] through [to]'s pairing with it, as raw bytes.
void _inject(Side from, Side to, Map<String, Object?> envelope) {
  final d = to.service.book.device(from.service.book.deviceId)!;
  to.pairing.receivePayload(d.pairings.values.first, utf8.encode(jsonEncode(envelope)));
}

Map<String, Object?> _env(Side from, int seq, String type, Map<String, Object?> body, {int v = 1, String? id}) => {
  'v': v,
  'type': type,
  'id': id ?? randomHexId(),
  'seq': seq,
  'dev': from.service.book.deviceId,
  'ts': 1,
  'body': body,
};

void main() {
  late Clock clock;
  late FakePrivateNet net;
  late Side a;
  late Side b;

  setUp(() {
    clock = Clock();
    net = FakePrivateNet();
    a = Side('Desktop', clock: clock, net: net);
    b = Side('Phone', clock: clock, net: net);
  });

  group('linking', () {
    test('A shows, B scans, both check: linked both ways, out of the contact lists', () async {
      await linkBoth(a, b);
      expect(a.service.link!.phase, LinkPhase.done);
      expect(b.service.link!.phase, LinkPhase.done);
      expect(a.service.book.devices.single.name, 'Phone');
      expect(b.service.book.devices.single.name, 'Desktop');
      expect(a.service.book.devices.single.deviceId, b.service.book.deviceId);
      expect(b.service.book.servers, [_s1]);
      // Private pairings never list as contacts.
      expect(await a.pairing.pairings(), isEmpty);
      expect(await b.pairing.pairings(), isEmpty);
      expect((await a.pairing.privatePairings()).single.state, PairingState.verified);
    });

    test('nothing is linked until both devices checked the pictures', () async {
      await showAndScan(a, b);
      expect(a.service.link!.phase, LinkPhase.checking);
      expect(b.service.link!.phase, LinkPhase.checking);
      expect(a.service.link!.sas, b.service.link!.sas);
      await a.service.answerCheck(true);
      await settle(a, b);
      expect(a.service.link!.phase, LinkPhase.waitingOther);
      expect(b.service.link!.phase, LinkPhase.checking);
      expect(a.service.book.devices, isEmpty);
      expect(b.service.book.devices, isEmpty);
      // A private pairing has no "check later".
      expect(() => b.pairing.checkWords(b.service.link!.pairingId!, PairingCheck.skip), throwsA(isA<WalletError>()));
    });

    test('pictures that do not match end the link on both devices', () async {
      await showAndScan(a, b);
      await a.service.answerCheck(true);
      await b.service.answerCheck(false);
      await settle(a, b);
      expect(b.service.link!.failure, LinkFailure.mismatch);
      expect(a.service.link!.phase, LinkPhase.failed);
      expect(a.service.book.devices, isEmpty);
      expect(b.service.book.devices, isEmpty);
    });

    test('the hello wallet check refuses a device of another wallet', () async {
      final other = Side('Phone', clock: clock, net: net, key: 'esAnotherWallet');
      await linkBoth(a, other);
      expect(a.service.link!.failure, LinkFailure.otherWallet);
      expect(other.service.link!.failure, LinkFailure.otherWallet);
      expect(a.service.book.devices, isEmpty);
      expect(other.service.book.devices, isEmpty);
      expect(await a.pairing.privatePairings(), isEmpty);
    });

    test('a contact invite does not link, and a device link does not pair a contact', () async {
      await a.service.load();
      await b.service.load();
      final contact = await a.pairing.makeInvite(name: 'Anna', expiry: const Duration(hours: 1));
      await b.service.startScanned(contact.inviteLink!);
      expect(b.service.link!.failure, LinkFailure.invalidCode);
      await a.service.startShowing([_s1]);
      final private = (await a.pairing.privatePairings()).single.inviteLink!;
      expect(() => b.pairing.openInvite(private), throwsA(isA<WalletError>()));
      expect(() => b.pairing.postPayload(id: contact.id, bytes: const [1]), throwsA(isA<WalletError>()));
    });

    test('a second server is paired over the checked channel', () async {
      await linkBoth(a, b, servers: [_s1, _s2]);
      await settle(a, b, rounds: 4);
      expect(a.service.book.devices.single.pairings.keys, unorderedEquals([_s1, _s2]));
      expect(b.service.book.devices.single.pairings.keys, unorderedEquals([_s1, _s2]));
      expect(b.service.book.devices.single.pending, isEmpty);
    });
  });

  group('notices', () {
    setUp(() async => linkBoth(a, b));

    test('a send on A holds its coins on B, a cancel releases them', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      expect(b.service.book.heldCommitments, {cm(2)});
      expect(b.session.heldOutputs, {cm(2)});
      final max = await b.session.estimateMax(minimumConfirmations: BigInt.one);
      expect(max.locked, b.session.summaryValue.spendable - BigInt.from(300000000));
      _send(a, 'pay-1', cancelled: true);
      await settle(a, b);
      expect(b.service.book.holds.single.state, HoldState.released);
      expect(b.session.heldOutputs, isEmpty);
      // A notice never makes this device send anything.
      expect(b.session.sentAmounts, isEmpty);
      expect(b.session.epicboxSends, isEmpty);
    });

    test('a send for coins this wallet does not hold is dropped', () async {
      final seq = b.service.book.devices.single.seqIn + 1;
      _inject(a, b, _env(a, seq, 'send', {'slateId': 'x', 'inputs': [cm(99)], 'amount': '5'}));
      await b.sync();
      expect(b.service.book.holds, isEmpty);
    });

    test('a release for a payment the device never held is dropped', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      final seq = b.service.book.devices.single.seqIn + 1;
      _inject(a, b, _env(a, seq, 'status', {'slateId': 'other', 'state': 'cancelled'}));
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.held);
    });

    test('an unknown type and a newer version are ignored and keep the order', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 1, 'labels', {'x': 1}));
      _inject(a, b, _env(a, seq + 2, 'rename', {'name': 'Never'}, v: 2));
      _inject(a, b, _env(a, seq + 3, 'rename', {'name': 'Laptop'}));
      await b.sync();
      final d = b.service.book.devices.single;
      expect(d.name, 'Laptop');
      expect(d.seqIn, seq + 3);
    });

    test('an oversize payload is dropped', () async {
      final seq = b.service.book.devices.single.seqIn;
      final d = b.service.book.devices.single;
      b.pairing.receivePayload(d.pairings.values.first, List<int>.filled(deviceNoticeMaxBytes + 1, 0x20));
      await b.sync();
      expect(b.service.book.devices.single.seqIn, seq);
      expect(await b.pairing.payloads(), isEmpty);
    });

    test('a bad body is dropped before its handler', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 1, 'rename', {'name': 'x' * 80}));
      await b.sync();
      expect(b.service.book.devices.single.name, 'Desktop');
      expect(b.service.book.devices.single.seqIn, seq + 1);
    });

    test('a notice naming another device than its pairing is dropped', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, {..._env(a, seq + 1, 'rename', {'name': 'Spoof'}), 'dev': 'f' * 32});
      await b.sync();
      expect(b.service.book.devices.single.name, 'Desktop');
    });

    test('out of order notices apply in order', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 2, 'rename', {'name': 'Second'}));
      await b.sync();
      expect(b.service.book.devices.single.name, 'Desktop');
      _inject(a, b, _env(a, seq + 1, 'rename', {'name': 'First'}));
      await b.sync();
      expect(b.service.book.devices.single.name, 'Second');
      expect(b.service.book.devices.single.seqIn, seq + 2);
    });

    test('a missing notice is given up after an hour', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 2, 'rename', {'name': 'Later'}));
      await b.sync();
      clock.now = clock.now.add(const Duration(minutes: 61));
      await b.sync();
      expect(b.service.book.devices.single.name, 'Later');
    });

    test('a notice too far ahead is dropped', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + noticeWindow + 1, 'rename', {'name': 'Far'}));
      await b.sync();
      expect(b.service.book.devices.single.waiting, isEmpty);
    });

    test('a server change from the other device waits for the user here', () async {
      await a.service.proposeServers([_s2]);
      await settle(a, b);
      expect(b.service.book.servers, [_s1]);
      expect(b.service.book.proposal!.servers, [_s2]);
      await b.service.acceptProposal();
      await settle(a, b, rounds: 5);
      expect(a.service.book.servers, [_s2]);
      expect(b.service.book.servers, [_s2]);
      expect(a.service.book.devices.single.pairings.keys, [_s2]);
      expect(b.service.book.devices.single.pairings.keys, [_s2]);
    });
  });

  test('the copy through the second server applies once', () async {
    await linkBoth(a, b, servers: [_s1, _s2]);
    await settle(a, b, rounds: 4);
    expect(b.service.book.devices.single.pairings, hasLength(2));
    _send(a, 'pay-1');
    await a.sync();
    expect(a.pairing.posted.where((p) => utf8.decode(p.bytes).contains('"send"')), hasLength(2));
    await b.sync();
    expect(b.service.book.holds, hasLength(1));
  });

  test('only the device that held coins releases them', () async {
    final c = Side('Laptop', clock: clock, net: net);
    await linkBoth(a, b);
    await linkBoth(c, b);
    _send(a, 'pay-1');
    await settle(a, b);
    final seq = b.service.book.device(c.service.book.deviceId)!.seqIn + 1;
    _inject(c, b, _env(c, seq, 'status', {'slateId': 'pay-1', 'state': 'released'}));
    await b.sync();
    expect(b.service.book.holds.single.state, HoldState.held);
  });

  test('removing a device unpairs it on both ends and re-keys the others', () async {
    final c = Side('Laptop', clock: clock, net: net);
    await linkBoth(a, b);
    await linkBoth(a, c);
    await linkBoth(b, c);
    final oldAb = a.service.book.device(b.service.book.deviceId)!.pairings.values.single;
    await a.service.removeDevice(c.service.book.deviceId);
    for (var i = 0; i < 4; i++) {
      await a.sync();
      await b.sync();
      await c.sync();
    }
    expect(a.service.book.devices.map((d) => d.name), ['Phone']);
    expect(b.service.book.devices.map((d) => d.name), ['Desktop']);
    expect(c.service.book.devices, isEmpty);
    expect(c.service.book.removedBy, isNotNull);
    expect(await c.pairing.privatePairings(), everyElement(predicate<PairingRecord>((r) => r.removedByPeer)));
    final newAb = a.service.book.device(b.service.book.deviceId)!.pairings.values.single;
    expect(newAb, isNot(oldAb));
    expect((await a.pairing.privatePairings()).map((r) => r.id), [newAb]);
    // The re-keyed channel carries notices.
    _send(a, 'pay-2');
    await settle(a, b);
    expect(b.service.book.heldCommitments, {cm(2)});
  });
}
