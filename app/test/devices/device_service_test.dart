// SPDX-License-Identifier: Apache-2.0
// Linked devices end to end over the fake engine: a link needs the pictures checked on both
// devices and the same wallet; notices hold and release coins; the one receive path drops what
// it must and keeps the order (two devices at most: device_two_only_test.dart).
import 'dart:convert';

import 'package:fake_async/fake_async.dart';

import 'package:epic_wallet/src/devices/device_history.dart';
import 'package:epic_wallet/src/devices/device_locks.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/device_wire.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_devices.dart';

const _s1 = 'epicbox.epiccash.com';
const _s2 = 'epicbox.stackwallet.com';

/// [side]'s own send [slate] spending coin 2 (3 EPIC, fee included, as LEPIC lists it),
/// [cancelled] or not.
void _send(Side side, String slate, {int tx = 7, int coinNo = 2, bool cancelled = false, CancelReason reason = CancelReason.user, int? cutoff}) {
  side.session.transactionsValue = [
    fakeTx(
      id: tx,
      slateId: slate,
      kind: cancelled ? TxKind.sentCancelled : TxKind.sent,
      status: cancelled ? TxStatus.cancelled : TxStatus.awaitingRecipient,
      amountDebited: BigInt.from(300000000),
      fee: BigInt.from(800000),
      counterparty: 'esBob@epicbox.epiccash.com',
      cancelReason: cancelled ? reason : null,
      ttlCutoffHeight: cutoff == null ? null : BigInt.from(cutoff),
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

Map<String, Object?> _env(Side from, int seq, String type, Map<String, Object?> body, {int v = deviceWireVersion, String? id}) => {
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
    test('A shows, B scans: linked both ways with nothing tapped, out of the contact lists', () async {
      await linkBoth(a, b);
      expect(a.service.link!.phase, LinkPhase.done);
      expect(b.service.link!.phase, LinkPhase.done);
      expect(a.service.book.devices.single.name, 'Phone');
      expect(b.service.book.devices.single.name, 'Desktop');
      expect(a.service.book.devices.single.deviceId, b.service.book.deviceId);
      expect(b.service.book.servers, [_s1]);
      // Each hello says what its device is, for the other's icon.
      expect(a.service.book.devices.single.kind, DeviceKind.phone);
      // Private pairings never list as contacts.
      expect(await a.pairing.pairings(), isEmpty);
      expect(await b.pairing.pairings(), isEmpty);
      expect((await a.pairing.privatePairings()).single.state, PairingState.verified);
      // Linked, the four pictures are the same on both devices.
      expect(a.service.link!.sas, b.service.link!.sas);
      expect(a.service.link!.sas, hasLength(4));
    });

    test("a service let go never writes: the wallet's next service keeps the link it saved", () async {
      await linkBoth(a, b);
      final key = a.service.store.key;
      final saved = await a.store.read(key);
      final next = DeviceService(host: SessionDeviceHost(a.session), store: a.service.store, defaultName: 'Desktop', clock: clock.call);
      await next.load();
      expect(next.book.devices.single.name, 'Phone');
      // The old one goes while a run of it is still under way: what it would save stays out.
      a.service.dispose();
      await a.service.renameDevice(b.service.book.deviceId, 'stale');
      expect(await a.store.read(key), saved);
      next.dispose();
    });

    // A tester, 2026-10-28: the computer cancelled, the phone held the coins for minutes. The apps
    // set the foreground before the book is read; a service made with a device linked already
    // (a start, a wallet switch) never started its 5 s reads.
    test('a service started with a device linked reads every 5 s once its book is read', () {
      fakeAsync((time) {
        linkBoth(a, b);
        time.flushMicrotasks();
        expect(a.service.book.devices, hasLength(1));
        a.service.dispose();
        final again = DeviceService(host: SessionDeviceHost(a.session), store: a.service.store, defaultName: 'Desktop', clock: clock.call);
        again.setForeground(true);
        again.load();
        time.flushMicrotasks();
        a.pairing.calls.clear();
        time.elapse(deviceSyncEvery + const Duration(milliseconds: 100));
        expect(a.pairing.calls, contains('collectPrivate'));
        again.dispose();
      });
    });

    test("paired, each device posts its hello by itself; nothing is linked until the other's came", () async {
      await showAndScan(a, b);
      expect(a.service.link!.phase, LinkPhase.linking);
      expect(a.service.link!.sas, hasLength(4));
      expect(a.service.book.devices, isEmpty);
      // A's hello went out on its own: the pairing is confirmed on A's side.
      expect((await a.pairing.privatePairings()).single.state, PairingState.verified);
      expect(a.pairing.posted.where((p) => utf8.decode(p.bytes).contains('"hello"')), hasLength(1));
      // A private pairing has no "check later".
      expect(() => a.pairing.checkWords(a.service.link!.pairingId!, PairingCheck.skip), throwsA(isA<WalletError>()));
      // B reads its channel: its hello goes, A's is read, both are linked.
      await settle(a, b);
      expect(a.service.link!.phase, LinkPhase.done);
      expect(b.service.link!.phase, LinkPhase.done);
    });

    test("the other device's hello does not come: the link gives up after a while, as not reached", () async {
      await showAndScan(a, b);
      clock.now = clock.now.add(linkHelloWait + const Duration(seconds: 1));
      await a.sync();
      expect(a.service.link!.phase, LinkPhase.failed);
      expect(a.service.link!.failure, LinkFailure.unreachable);
      expect(await a.pairing.privatePairings(), isEmpty);
    });

    test('a code of another wallet is refused at the scan, before it is answered', () async {
      final other = Side('Phone', clock: clock, net: net, key: 'esAnotherWallet');
      await a.service.load();
      await other.service.load();
      await a.service.startShowing([_s1]);
      await other.service.startScanned(a.service.link!.code!);
      await settle(a, other);
      expect(other.service.link!.phase, LinkPhase.failed);
      expect(other.service.link!.failure, LinkFailure.otherWalletCode);
      expect(await other.pairing.privatePairings(), isEmpty);
      // The code was never answered: the showing device still waits.
      expect(a.service.link!.phase, LinkPhase.waiting);
    });

    test('a code without a fingerprint is answered, and the hello proof refuses another wallet', () async {
      final other = Side('Phone', clock: clock, net: net, key: 'esAnotherWallet');
      await a.service.load();
      await other.service.load();
      await a.service.startShowing([_s1]);
      final old = a.service.link!.code!.replaceFirst(RegExp(r'/[0-9a-f]{16}$'), '');
      await other.service.startScanned(old);
      await settle(a, other);
      expect(a.service.link!.failure, LinkFailure.otherWallet);
      expect(other.service.link!.failure, LinkFailure.otherWallet);
      expect(a.service.book.devices, isEmpty);
      expect(other.service.book.devices, isEmpty);
      expect(await a.pairing.privatePairings(), isEmpty);
    });

    for (final (what, proof) in [('no proof', null), ('a proof of another wallet', 'other'), ('a proof of another pairing', 'sas')]) {
      test('a hello with the right wallet address and $what does not link', () async {
        await showAndScan(a, b);
        // B's engine completes its side without B's service, which would post a real hello.
        await b.pairing.collectPrivate();
        final id = (await b.pairing.privatePairings()).single.id;
        final sas = a.service.link!.sas;
        // B hand-builds its hello: the right address, as anyone could, but no valid proof.
        final forged = switch (proof) {
          'other' => fakeAddressSignature('esAnotherWallet', helloTranscript(b.service.book.deviceId, sas)),
          'sas' => await b.session.signWithAddressKey(helloTranscript(b.service.book.deviceId, sas.reversed.toList())),
          _ => null,
        };
        await b.pairing.checkWords(id, PairingCheck.match);
        final hello = Notice(
          type: NoticeType.hello,
          id: randomHexId(),
          seq: 1,
          dev: b.service.book.deviceId,
          ts: 1,
          body: {'deviceId': b.service.book.deviceId, 'name': 'Phone', 'walletAddress': 'esSameWalletKey', 'servers': [_s1], 'proof': ?forged},
        );
        await b.pairing.postPayload(id: id, bytes: hello.encode());
        await a.sync();
        expect(a.service.book.devices, isEmpty);
        if (proof == null) {
          // No proof is no hello of this version: dropped, the link waits on until it gives up.
          expect(a.service.link!.phase, LinkPhase.linking);
          expect(await a.pairing.privatePairings(), hasLength(1));
        } else {
          expect(a.service.link!.failure, LinkFailure.otherWallet);
          expect(await a.pairing.privatePairings(), isEmpty);
        }
      });
    }

    test("each device's hello carries a proof the other checks with its own wallet key", () async {
      await showAndScan(a, b);
      final sas = a.service.link!.sas;
      final proof = await b.session.signWithAddressKey(helloTranscript(b.service.book.deviceId, sas));
      final key = epicboxKey(a.session.address);
      expect(await a.session.verifyAddressSignature(key: key, message: helloTranscript(b.service.book.deviceId, sas), signature: proof), isTrue);
      expect(await a.session.verifyAddressSignature(key: key, message: helloTranscript(a.service.book.deviceId, sas), signature: proof), isFalse);
      await settle(a, b);
      expect(a.service.link!.phase, LinkPhase.done);
      expect(b.service.link!.phase, LinkPhase.done);
    });

    test('a hello of another wire version ends the link and says which device to update', () async {
      await showAndScan(a, b);
      await b.pairing.collectPrivate();
      final id = (await b.pairing.privatePairings()).single.id;
      await b.pairing.checkWords(id, PairingCheck.match);
      final sas = a.service.link!.sas;
      final hello = Notice(
        v: 3,
        type: NoticeType.hello,
        id: randomHexId(),
        seq: 1,
        dev: b.service.book.deviceId,
        ts: 1,
        body: {
          'deviceId': b.service.book.deviceId,
          'name': 'Phone',
          'walletAddress': 'esSameWalletKey',
          'servers': [_s1],
          'proof': await b.session.signWithAddressKey(helloTranscript(b.service.book.deviceId, sas)),
        },
      );
      await b.pairing.postPayload(id: id, bytes: hello.encode());
      await a.sync();
      expect(a.service.link!.failure, LinkFailure.update);
      expect(await a.pairing.privatePairings(), isEmpty);
    });

    test('a contact invite does not link, and a device link does not pair a contact', () async {
      await a.service.load();
      await b.service.load();
      final contact = await a.pairing.standingCode(name: 'Anna');
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

    test('an unknown type is ignored and keeps the order', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 1, 'labels', {'x': 1}));
      _inject(a, b, _env(a, seq + 2, 'rename', {'name': 'Laptop'}));
      await b.sync();
      final d = b.service.book.devices.single;
      expect(d.name, 'Laptop');
      expect(d.seqIn, seq + 2);
      expect(d.otherVersion, isNull);
    });

    test('a notice of another wire version keeps the order and names the device to update, until one of this version comes', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 1, 'rename', {'name': 'Never'}, v: 3));
      await b.sync();
      var d = b.service.book.devices.single;
      expect(d.name, 'Desktop');
      expect(d.seqIn, seq + 1);
      expect(d.otherVersion, 3, reason: 'the screen says "Update Desktop to keep this wallet in sync"');
      // An older app writes version 1: the same line.
      _inject(a, b, _env(a, seq + 2, 'rename', {'name': 'Older'}, v: 1));
      await b.sync();
      expect(b.service.book.devices.single.otherVersion, 1);
      // Updated: its next notice reads, and the line goes.
      _inject(a, b, _env(a, seq + 3, 'rename', {'name': 'Laptop'}));
      await b.sync();
      d = b.service.book.devices.single;
      expect(d.name, 'Laptop');
      expect(d.otherVersion, isNull);
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

    test('a missing notice is given up after a few minutes', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 2, 'rename', {'name': 'Later'}));
      await b.sync();
      expect(b.service.book.devices.single.name, 'Desktop', reason: 'a rename keeps the order');
      clock.now = clock.now.add(gapWait + const Duration(seconds: 1));
      await b.sync();
      expect(b.service.book.devices.single.name, 'Later');
    });

    test('a send, an unlink and a status of a known hold apply as they come, ahead of a missing notice', () async {
      final seq = b.service.book.devices.single.seqIn;
      // The send came through, the notice before it did not: its coins are held at once.
      _inject(a, b, _env(a, seq + 2, 'send', {'slateId': 'early', 'inputs': [cm(2)], 'amount': '100'}));
      await b.sync();
      expect(b.service.book.heldCommitments, {cm(2)});
      expect(b.service.book.devices.single.seqIn, seq, reason: 'the order still waits for the missing one');
      // Its status applies at once too; one for a payment never held waits for the order.
      _inject(a, b, _env(a, seq + 4, 'status', {'slateId': 'unknown', 'state': 'cancelled'}));
      _inject(a, b, _env(a, seq + 3, 'status', {'slateId': 'early', 'state': 'cancelled'}));
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.released);
      // The missing notice comes: the order catches up without applying the early ones twice.
      _inject(a, b, _env(a, seq + 1, 'rename', {'name': 'First'}));
      await b.sync();
      final d = b.service.book.devices.single;
      expect(d.name, 'First');
      expect(d.seqIn, seq + 4);
      expect(d.waiting, isEmpty);
      expect(d.early, isEmpty);
      expect(b.service.book.holds.single.state, HoldState.released);
    });

    test('an unlink ahead of a missing notice ends the link at once', () async {
      final seq = b.service.book.devices.single.seqIn;
      _inject(a, b, _env(a, seq + 2, 'unlink', {}));
      await b.sync();
      expect(b.service.book.devices, isEmpty);
      expect(b.service.book.removedBy, 'Desktop');
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

  group('held, released, confirmed', () {
    setUp(() async => linkBoth(a, b));

    /// B's own chain check sees coin 2 spent by another wallet.
    void chainShowsSpent() {
      b.session.outputsValue = [
        for (final o in b.session.outputsValue) o.commitment == cm(2) ? coin(2, 3, status: WalletOutputStatus.spent) : o,
      ];
      b.session.transactionsValue = [
        TxEntry(
          key: 'k:chain',
          kind: TxKind.sent,
          status: TxStatus.confirmed,
          source: TxSource.wallet,
          createdAtUnix: 1790000600,
          timeUnix: 1790000600,
          confirmed: true,
          blockHeight: BigInt.from(1001),
          amountCredited: BigInt.zero,
          amountDebited: BigInt.from(300800000),
          numInputs: 1,
          numOutputs: 0,
          outputCommits: const [],
          cancellable: false,
          repostable: false,
          releasable: false,
          origin: TxOrigin.otherWallet,
          spentCommits: [cm(2)],
        ),
      ];
    }

    test('release, then the chain confirms: the same row, confirmed, once', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      final pending = mergeDeviceHistory(await b.session.transactions(refresh: false), b.service.book).single;
      await b.service.releaseByHandOf(a.service.book.deviceId, 'pay-1');
      expect(b.session.heldOutputs, isEmpty);
      final released = mergeDeviceHistory(await b.session.transactions(refresh: false), b.service.book).single;
      expect(released.status, TxStatus.cancelled);
      chainShowsSpent();
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.spent);
      final rows = mergeDeviceHistory(await b.session.transactions(refresh: false), b.service.book);
      expect(rows, hasLength(1));
      expect(rows.single.key, pending.key);
      expect(rows.single.confirmed, isTrue);
      expect(rows.single.deviceName, 'Desktop');
    });

    test('confirmed without a release', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      chainShowsSpent();
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.spent);
      expect(b.session.heldOutputs, isEmpty);
    });

    test('released by the 7-day fallback, then confirmed', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      clock.now = clock.now.add(holdMaxAge);
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.timedOut);
      chainShowsSpent();
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.spent);
      expect(mergeDeviceHistory(await b.session.transactions(refresh: false), b.service.book), hasLength(1));
    });

    test('a late notice after confirmed is ignored', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      chainShowsSpent();
      await b.sync();
      _send(a, 'pay-1', cancelled: true);
      await settle(a, b);
      expect(b.service.book.holds.single.state, HoldState.spent);
    });

    test('after a release here, a late posted does not hold the coins again', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      await b.service.releaseByHandOf(a.service.book.deviceId, 'pay-1');
      final seq = b.service.book.devices.single.seqIn + 1;
      _inject(a, b, _env(a, seq, 'status', {'slateId': 'pay-1', 'state': 'posted', 'height': 1000}));
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.byHand);
      expect(b.session.heldOutputs, isEmpty);
    });
  });

  group('the sending device ends its payment', () {
    setUp(() async => linkBoth(a, b));

    /// The row B shows for A's payment.
    Future<TxEntry> row() async => mergeDeviceHistory(await b.session.transactions(refresh: false), b.service.book).single;

    /// B's own chain check sees coin 2 spent by A after all.
    void chainShowsSpent() {
      b.session.outputsValue = [
        for (final o in b.session.outputsValue) o.commitment == cm(2) ? coin(2, 3, status: WalletOutputStatus.spent) : o,
      ];
      b.session.transactionsValue = [
        TxEntry(
          key: 'k:chain',
          kind: TxKind.sent,
          status: TxStatus.confirmed,
          source: TxSource.wallet,
          createdAtUnix: 1790000600,
          timeUnix: 1790000600,
          confirmed: true,
          blockHeight: BigInt.from(1001),
          amountCredited: BigInt.zero,
          amountDebited: BigInt.from(300800000),
          numInputs: 1,
          numOutputs: 0,
          outputCommits: const [],
          cancellable: false,
          repostable: false,
          releasable: false,
          origin: TxOrigin.otherWallet,
          spentCommits: [cm(2)],
        ),
      ];
    }

    test('A cancels: B unlocks by itself and the row reads Cancelled, no action', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      expect(b.session.heldOutputs, {cm(2)});
      expect((await row()).deviceEnding, isNull);
      _send(a, 'pay-1', cancelled: true);
      await settle(a, b);
      expect(b.session.heldOutputs, isEmpty);
      final hold = b.service.book.holds.single;
      expect(hold.state, HoldState.released);
      expect(hold.ending, DeviceEnding.cancelled);
      final r = await row();
      expect(r.status, TxStatus.cancelled);
      expect(r.deviceEnding, DeviceEnding.cancelled);
      expect(r.deviceWhy, isNull);
      expect(r.deviceName, 'Desktop');
    });

    test("A's send fails: B unlocks and the row reads Failed with A's reason code", () async {
      _send(a, 'pay-1');
      await settle(a, b);
      _send(a, 'pay-1', cancelled: true, reason: CancelReason.failed);
      await settle(a, b);
      expect(b.session.heldOutputs, isEmpty);
      final r = await row();
      expect(r.deviceEnding, DeviceEnding.failed);
      expect(r.deviceWhy, 'notDelivered');
      expect(b.service.book.holds.single.why, 'notDelivered');
    });

    test('A\'s payment expires: B unlocks and the row reads Expired', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      _send(a, 'pay-1', cancelled: true, reason: CancelReason.expiry);
      await settle(a, b);
      expect(b.session.heldOutputs, isEmpty);
      expect((await row()).deviceEnding, DeviceEnding.expired);
    });

    test('B offline during the cancel: the fallback frees the coins and the row reads Expired', () async {
      _send(a, 'pay-1', cutoff: 1100);
      await settle(a, b);
      await b.service.setPaused(true);
      _send(a, 'pay-1', cancelled: true);
      await settle(a, b);
      // B heard nothing: the coins stay held until the fallback.
      expect(b.session.heldOutputs, {cm(2)});
      b.session.summaryValue = WalletSummary(
        lastConfirmedHeight: BigInt.from(1200),
        minimumConfirmations: BigInt.from(10),
        total: BigInt.from(1000000000),
        spendable: BigInt.from(1000000000),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.expired);
      expect(b.session.heldOutputs, isEmpty);
      expect((await row()).deviceEnding, DeviceEnding.expired);
      // The notice that comes later changes nothing; the user could have released by hand earlier.
      await b.service.setPaused(false);
      await settle(a, b);
      expect(b.service.book.holds.single.state, HoldState.expired);
    });

    test('B offline: Release by hand works before any fallback', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      await b.service.setPaused(true);
      await b.service.releaseByHandOf(a.service.book.deviceId, 'pay-1');
      expect(b.session.heldOutputs, isEmpty);
      expect((await row()).deviceEnding, DeviceEnding.releasedHere);
    });

    test('A cancels too late and the payment lands: the chain wins, the same row, Confirmed', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      _send(a, 'pay-1', cancelled: true);
      await settle(a, b);
      final cancelled = await row();
      expect(cancelled.deviceEnding, DeviceEnding.cancelled);
      chainShowsSpent();
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.spent);
      final rows = mergeDeviceHistory(await b.session.transactions(refresh: false), b.service.book);
      expect(rows, hasLength(1));
      expect(rows.single.key, cancelled.key);
      expect(rows.single.confirmed, isTrue);
      expect(rows.single.deviceEnding, isNull);
      expect(rows.single.deviceName, 'Desktop');
    });

    test('a failure code outside the list, or free text, drops the notice', () async {
      _send(a, 'pay-1');
      await settle(a, b);
      final seq = b.service.book.devices.single.seqIn + 1;
      _inject(a, b, _env(a, seq, 'status', {'slateId': 'pay-1', 'state': 'failed', 'why': 'the recipient said no'}));
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.held);
      _inject(a, b, _env(a, seq + 1, 'status', {'slateId': 'pay-1', 'state': 'failed', 'why': 'refused'}));
      await b.sync();
      expect(b.service.book.holds.single.state, HoldState.released);
      expect(b.service.book.holds.single.why, 'refused');
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
}
