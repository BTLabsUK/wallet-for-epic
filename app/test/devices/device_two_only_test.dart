// SPDX-License-Identifier: Apache-2.0
// A wallet on two devices at most: the cap, the link ending on both sides from either one, the
// second server made and made again, the relay question when both use one relay, and a payment
// both devices answered shown once.
import 'package:epic_wallet/src/devices/device_history.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_devices.dart';

const _s1 = 'epicbox.epiccash.com';
const _s2 = 'epicbox.stackwallet.com';

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
    test('once linked, neither device shows nor answers another code', () async {
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
      expect(b.service.link!.failure, LinkFailure.tooMany);
      expect(b.service.book.devices.single.name, 'Desktop');
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
      // The invite went out but the other device never read it.
      final inviter = a.service.book.deviceId.compareTo(b.service.book.deviceId) < 0 ? a : b;
      final other = inviter == a ? b : a;
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

  group('relays', () {
    test('both on one relay: only the device being linked asks', () async {
      await linkBoth(a, b);
      await settle(a, b);
      expect(b.service.relayClash, _s1);
      expect(a.service.relayClash, isNull);
      expect(a.service.book.devices.single.relay, _s1);
      expect(b.service.book.devices.single.relay, _s1);
    });

    test('different relays: nobody asks', () async {
      b.session.address = 'esSameWalletKey@$_s2';
      await linkBoth(a, b);
      await settle(a, b);
      expect(a.service.relayClash, isNull);
      expect(b.service.relayClash, isNull);
      expect(a.service.book.devices.single.relay, _s2);
    });

    test('Keep: not asked again for the same relay; a change on either device asks again', () async {
      await linkBoth(a, b);
      await b.service.keepRelay();
      await settle(a, b);
      expect(b.service.relayClash, isNull);
      expect(b.service.book.relayKept, _s1);
      // A moves away: nothing to ask; A moves back: B, the other side, asks again.
      a.session.address = 'esSameWalletKey@$_s2';
      await settle(a, b);
      expect(b.service.book.devices.single.relay, _s2);
      expect(b.service.relayClash, isNull);
      expect(b.service.book.relayKept, isNull);
      a.session.address = 'esSameWalletKey@$_s1';
      await settle(a, b);
      expect(b.service.relayClash, _s1);
      expect(a.service.relayClash, isNull, reason: 'the device that changed does not ask');
    });

    test('Use: the device moved, the other hears its relay, the question goes on both', () async {
      await linkBoth(a, b);
      b.session.address = 'esSameWalletKey@$_s2';
      await b.service.relayMoved();
      await settle(a, b);
      expect(b.service.relayClash, isNull);
      expect(a.service.relayClash, isNull);
      expect(a.service.book.devices.single.relay, _s2);
    });

    test('a later change onto the linked device\'s relay asks there', () async {
      b.session.address = 'esSameWalletKey@$_s2';
      await linkBoth(a, b);
      await settle(a, b);
      expect(b.service.relayClash, isNull);
      b.session.address = 'esSameWalletKey@$_s1';
      await settle(a, b);
      expect(a.service.relayClash, _s1);
      expect(b.service.relayClash, isNull);
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

  test('coins received by the linked device read Received on it, not by another wallet', () async {
    await linkBoth(a, b);
    final change = fakeTx(
      id: 11,
      kind: TxKind.received,
      status: TxStatus.confirmed,
      confirmed: true,
      amountCredited: BigInt.from(2800000),
      outputCommits: [cm(30)],
      origin: TxOrigin.otherWallet,
      timeUnix: clock.now.millisecondsSinceEpoch ~/ 1000 + 60,
    );
    final before = fakeTx(
      id: 12,
      kind: TxKind.received,
      status: TxStatus.confirmed,
      confirmed: true,
      amountCredited: BigInt.from(2800000),
      outputCommits: [cm(31)],
      origin: TxOrigin.otherWallet,
      timeUnix: clock.now.millisecondsSinceEpoch ~/ 1000 - 86400,
    );
    final rows = mergeDeviceHistory([change, before], b.service.book);
    expect(rows.firstWhere((r) => r.id == 11).deviceName, 'Desktop');
    expect(rows.firstWhere((r) => r.id == 12).deviceName, isNull, reason: 'before the link: another wallet');
  });
}
