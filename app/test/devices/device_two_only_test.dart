// SPDX-License-Identifier: Apache-2.0
// A wallet on two devices at most: the cap (a full device answers a third one's code to say so,
// and offers Replace), the link ending on both sides from either one, the second server made
// and made again, and a payment both devices answered shown once (one address, one relay).
import 'package:epic_wallet/src/devices/device_history.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_devices.dart';

const _s1 = 'epicbox.epiccash.com';
const _s2 = 'epicbox.stackwallet.com';

/// [side]'s own send [slate] spending coin 2.
void _send(Side side, String slate, {int tx = 7, int coinNo = 2}) {
  side.session.transactionsValue = [
    fakeTx(
      id: tx,
      slateId: slate,
      kind: TxKind.sent,
      status: TxStatus.awaitingRecipient,
      amountDebited: BigInt.from(300000000),
      fee: BigInt.from(800000),
      counterparty: 'esBob@epicbox.epiccash.com',
    ),
  ];
  side.session.outputsValue = [
    for (final o in side.session.outputsValue) o.commitment == cm(coinNo) ? coin(coinNo, 3, status: WalletOutputStatus.locked, txId: tx) : o,
  ];
}

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

  group('one linked device', () {
    test('once linked, a device shows no code; a third device\'s code it answers only to say it is full', () async {
      final c = Side('Laptop', clock: clock, net: net);
      await linkBoth(a, b);
      expect(maxLinkedDevices, 2);
      expect(a.service.canLinkMore, isFalse);
      expect(b.service.canLinkMore, isFalse);
      await a.service.startShowing(const [_s1]);
      expect(a.service.link!.failure, LinkFailure.tooMany);
      await c.service.load();
      await c.service.startShowing(const [_s1]);
      await b.service.startScanned(c.service.link!.code!);
      expect(b.service.link!.refusing, isTrue);
      await settle(b, c);
      // The third device hears why instead of waiting for the code to expire.
      expect(c.service.link!.phase, LinkPhase.failed);
      expect(c.service.link!.failure, LinkFailure.full);
      expect(c.service.link!.otherName, 'Phone');
      expect(await c.pairing.privatePairings(), isEmpty);
      // The full device shows Replace; nothing changed meanwhile.
      expect(b.service.link!.failure, LinkFailure.tooMany);
      expect(b.service.book.devices.single.name, 'Desktop');
      expect(await b.pairing.privatePairings(), hasLength(1), reason: 'only the link with Desktop');
      expect(a.service.book.devices.single.name, 'Phone');
    });

    test('Replace on the full device removes the device linked and links the new one', () async {
      final c = Side('Laptop', clock: clock, net: net);
      await linkBoth(a, b);
      await c.service.load();
      await c.service.startShowing(const [_s1]);
      await b.service.startScanned(c.service.link!.code!);
      await settle(b, c);
      expect(b.service.link!.failure, LinkFailure.tooMany);
      await b.service.replaceLinked();
      await settle(a, b);
      expect(b.service.book.devices, isEmpty);
      expect(a.service.book.devices, isEmpty);
      expect(a.service.book.removedBy, 'Phone');
      expect(b.service.link, isNull, reason: 'the code it scanned is spent: back to the start');
      // The third device shows a new code; the next scan links.
      c.service.closeLink();
      await c.service.startShowing(const [_s1]);
      await b.service.startScanned(c.service.link!.code!);
      await settle(b, c);
      expect(b.service.book.devices.single.name, 'Laptop');
      expect(c.service.book.devices.single.name, 'Phone');
    });

    test('Replace on a full device that showed a code makes a new code', () async {
      await linkBoth(a, b);
      await a.service.startShowing(const [_s1]);
      expect(a.service.link!.failure, LinkFailure.tooMany);
      await a.service.replaceLinked();
      await settle(a, b);
      expect(a.service.book.devices, isEmpty);
      expect(b.service.book.removedBy, 'Desktop');
      expect(a.service.link!.phase, LinkPhase.waiting);
      expect(a.service.link!.code, isNotNull);
    });

    for (final remover in ['Desktop', 'Phone']) {
      test('removing on $remover ends the link on both, names who removed it, and a new link works', () async {
        await linkBoth(a, b, servers: const [_s1, _s2]);
        await settle(a, b, rounds: 4);
        final (by, other) = remover == 'Desktop' ? (a, b) : (b, a);
        await by.service.removeDevice(other.service.book.deviceId);
        await settle(a, b);
        expect(a.service.book.devices, isEmpty);
        expect(b.service.book.devices, isEmpty);
        expect(other.service.book.removedBy, remover);
        expect(by.service.book.removedBy, isNull);
        expect(await by.pairing.privatePairings(), isEmpty);
        expect(a.service.canLinkMore, isTrue);
        await linkBoth(b, a, servers: const [_s2]);
        expect(a.service.book.devices.single.name, 'Phone');
        expect(a.service.book.servers, [_s2], reason: 'a new link takes the set of the device that showed the code');
        expect(b.service.book.servers, [_s2]);
      });
    }
  });

  group('the second server', () {
    test('is paired after the link, whichever device showed the code', () async {
      await linkBoth(b, a, servers: const [_s1, _s2]);
      await settle(a, b, rounds: 4);
      expect(a.service.book.devices.single.pairings.keys, unorderedEquals([_s1, _s2]));
      expect(b.service.book.devices.single.pairings.keys, unorderedEquals([_s1, _s2]));
      expect(a.service.book.devices.single.pending, isEmpty);
      expect(b.service.book.devices.single.pending, isEmpty);
    });

    test('a pairing the link lost is made again', () async {
      await linkBoth(a, b, servers: const [_s1, _s2]);
      await settle(a, b, rounds: 4);
      final lost = a.service.book.devices.single.pairings[_s2]!;
      await a.pairing.removePairing(lost);
      await settle(a, b, rounds: 5);
      for (final side in [a, b]) {
        final d = side.service.book.devices.single;
        expect(d.pairings.keys, unorderedEquals([_s1, _s2]), reason: side.name);
        expect(d.pairings[_s2], isNot(lost));
        expect(d.pending, isEmpty);
      }
    });

    test('an invite that never finishes is dropped after a while and made again', () async {
      await linkBoth(a, b, servers: const [_s1, _s2]);
      await settle(a, b, rounds: 4);
      // The inviter lost its pairing on the second server and invites again, but the other
      // device never reads it.
      final inviter = a.service.book.deviceId.compareTo(b.service.book.deviceId) < 0 ? a : b;
      final other = inviter == a ? b : a;
      await inviter.pairing.removePairing(inviter.service.book.devices.single.pairings[_s2]!);
      await inviter.sync();
      expect(inviter.service.book.devices.single.pending, hasLength(1));
      final first = inviter.service.book.devices.single.pending.single.pairingId;
      clock.now = clock.now.add(pairingWait + const Duration(seconds: 1));
      await inviter.sync();
      final again = inviter.service.book.devices.single.pending.single.pairingId;
      expect(again, isNot(first));
      await settle(inviter, other, rounds: 5);
      expect(other.service.book.devices.single.pairings.keys, unorderedEquals([_s1, _s2]));
      expect(inviter.service.book.devices.single.pairings.keys, unorderedEquals([_s1, _s2]));
    });
  });

  group('a payment both devices answered', () {
    TxEntry answer(int tx, int output) => fakeTx(
      id: tx,
      slateId: 'in-1',
      kind: TxKind.received,
      status: TxStatus.awaitingConfirmation,
      amountCredited: BigInt.from(30000000),
      outputCommits: [cm(output)],
      cancellable: true,
    );

    test('the chain shows the other answer: this one is dropped quietly, the row reads Received on the device', () async {
      await linkBoth(a, b);
      a.session.transactionsValue = [answer(5, 20)];
      b.session.transactionsValue = [answer(9, 21)];
      await settle(a, b);
      expect(b.service.book.theirReceives['in-1'], [cm(20)]);
      expect(a.service.book.theirReceives['in-1'], [cm(21)]);
      // The sender used A's answer: B's chain check lists A's output as another wallet's.
      final chain = fakeTx(
        id: 10,
        kind: TxKind.received,
        status: TxStatus.confirmed,
        confirmed: true,
        amountCredited: BigInt.from(30000000),
        outputCommits: [cm(20)],
        origin: TxOrigin.otherWallet,
        timeUnix: clock.now.millisecondsSinceEpoch ~/ 1000,
      );
      b.session.transactionsValue = [answer(9, 21), chain];
      await b.sync();
      expect(b.session.cancelledTxIds, [9]);
      final rows = mergeDeviceHistory(b.session.transactionsValue, b.service.book);
      expect(rows, hasLength(1));
      expect(rows.single.origin, TxOrigin.otherWallet);
      expect(rows.single.deviceName, 'Desktop');
      expect(rows.single.kind, TxKind.received, reason: 'never a cancelled row');
      // A's own answer stays its own receive.
      expect(mergeDeviceHistory(a.session.transactionsValue, a.service.book).single.id, 5);
      expect(a.session.cancelledTxIds, isEmpty);
    });

    test('before the chain decides, both answers stay as they are', () async {
      await linkBoth(a, b);
      a.session.transactionsValue = [answer(5, 20)];
      b.session.transactionsValue = [answer(9, 21)];
      await settle(a, b);
      expect(b.session.cancelledTxIds, isEmpty);
      expect(mergeDeviceHistory(b.session.transactionsValue, b.service.book).single.id, 9);
    });
  });

  test('coins the chain shows received read Received on the device only when it said so', () async {
    await linkBoth(a, b);
    TxEntry credit(int id, int output, {String? kernel}) => fakeTx(
      id: id,
      kind: TxKind.received,
      status: TxStatus.confirmed,
      confirmed: true,
      amountCredited: BigInt.from(2800000),
      outputCommits: [cm(output)],
      origin: TxOrigin.otherWallet,
      kernelExcess: kernel,
      timeUnix: clock.now.millisecondsSinceEpoch ~/ 1000 + 60,
    );
    // The linked device answered a payment and said which outputs are its.
    a.session.transactionsValue = [
      fakeTx(id: 5, slateId: 'in-1', kind: TxKind.received, status: TxStatus.awaitingConfirmation, amountCredited: BigInt.from(2800000), outputCommits: [cm(30)]),
    ];
    await settle(a, b);
    // The change of a payment it told about: its kernel is the hold's, so it is that payment's.
    _send(a, 'pay-1');
    await settle(a, b);
    a.session.transactionsValue = [
      fakeTx(id: 7, slateId: 'pay-1', kind: TxKind.sent, status: TxStatus.awaitingConfirmation, amountDebited: BigInt.from(300000000), fee: BigInt.from(800000), kernelExcess: '09${'ab' * 32}'),
    ];
    await settle(a, b);
    final rows = mergeDeviceHistory([credit(11, 30), credit(12, 31), credit(13, 32, kernel: '09${'ab' * 32}')], b.service.book);
    expect(rows.firstWhere((r) => r.id == 11).deviceName, 'Desktop', reason: 'an output its recv named');
    expect(rows.where((r) => r.id == 13), isEmpty, reason: 'the change of a known hold is no receive');
    expect(rows.singleWhere((r) => r.slateId == 'pay-1').outputCommits, [cm(32)], reason: 'it is part of the payment');
    expect(rows.firstWhere((r) => r.id == 12).deviceName, isNull, reason: 'anything else: received by another device');
  });
}
