// SPDX-License-Identifier: Apache-2.0
// Notices that reached one device only are passed on over the link (`fwd`): a payer's posted or
// cancelled report drops this device's own answer to the same payment, a contact's request to
// pay is announced. Before a delete every linked device is told; a session that closes
// mid-link lets the other device go.
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/device_store.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_devices.dart';

void main() {
  late Clock clock;
  late FakePrivateNet net;
  late Side a;
  late Side b;

  setUp(() async {
    clock = Clock();
    net = FakePrivateNet();
    a = Side('Desktop', clock: clock, net: net);
    b = Side('Phone', clock: clock, net: net);
    await linkBoth(a, b);
  });

  /// B's own answer to the payment `in-1`, still waiting for its payer.
  void bAnswered() {
    b.session.transactionsValue = [
      fakeTx(id: 9, slateId: 'in-1', kind: TxKind.received, status: TxStatus.awaitingConfirmation, amountCredited: BigInt.from(30000000), outputCommits: [cm(21)], cancellable: true),
    ];
  }

  test("the payer's cancel reached A only: passed on, B drops its own answer to that payment", () async {
    bAnswered();
    final heard = <ForwardedNotice>[];
    b.service.forwarded.listen(heard.add);
    await a.service.forward(ForwardKind.cancelled, 'in-1');
    await settle(a, b);
    expect(b.session.cancelledTxIds, [9]);
    expect(heard.single.kind, ForwardKind.cancelled);
    expect(heard.single.slateId, 'in-1');
    expect(heard.single.device, 'Desktop');
  });

  test("the payer's posted reached A only: passed on with its kernel, B drops its own answer", () async {
    bAnswered();
    final heard = <ForwardedNotice>[];
    b.service.forwarded.listen(heard.add);
    await a.service.forward(ForwardKind.posted, 'in-1', kernel: '09${'cd' * 32}');
    await settle(a, b);
    expect(b.session.cancelledTxIds, [9]);
    expect(heard.single.kind, ForwardKind.posted);
    expect(heard.single.kernel, '09${'cd' * 32}');
  });

  test('a report for a payment B never answered, or one it confirmed, changes nothing there', () async {
    b.session.transactionsValue = [
      fakeTx(id: 9, slateId: 'in-1', kind: TxKind.received, status: TxStatus.confirmed, confirmed: true, amountCredited: BigInt.from(30000000), outputCommits: [cm(21)]),
    ];
    await a.service.forward(ForwardKind.cancelled, 'in-1');
    await a.service.forward(ForwardKind.cancelled, 'never');
    await settle(a, b);
    expect(b.session.cancelledTxIds, isEmpty);
  });

  test("a contact's request to pay reached A only: B is told where to pay it", () async {
    final heard = <ForwardedNotice>[];
    b.service.forwarded.listen(heard.add);
    await a.service.forward(ForwardKind.invoice, 'inv-1');
    await settle(a, b);
    expect(heard.single.kind, ForwardKind.invoice);
    expect(heard.single.device, 'Desktop');
    expect(b.session.cancelledTxIds, isEmpty);
  });

  test('a request to pair that reached A only is listed on B; the first Pair wins, A says where', () async {
    final seenOnA = <PairingEvent>[];
    a.pairing.events().listen(seenOnA.add);
    final request = a.pairing.receiveRequest(from: 'esAnnaKey@epicbox.epiccash.com', name: 'Anna')!;
    await Future<void>.delayed(Duration.zero);
    await settle(a, b);
    final onB = (await b.pairing.requests()).single;
    expect((onB.id, onB.fromAddress, onB.claimedName, onB.inviteLink), (request.id, request.fromAddress, 'Anna', request.inviteLink));

    // B answers it: A hides its own copy and says the request was handled on B.
    final preview = await b.pairing.openRequest(onB.id);
    await b.pairing.acceptInvite(token: preview.token, name: 'Alex');
    await Future<void>.delayed(Duration.zero);
    await settle(a, b);
    expect(await a.pairing.requests(), isEmpty);
    final elsewhere = seenOnA.where((e) => e.kind == PairingEventKind.pairedElsewhere).single;
    expect((elsewhere.requestId, elsewhere.name), (request.id, 'Phone'));
    // Nothing went back to A as a new request.
    expect(seenOnA.where((e) => e.kind == PairingEventKind.requested), hasLength(1));
  });

  test("a request from someone only in B's contacts: A passes it on before it dismisses it, once", () async {
    // A's list dismisses a stranger's request as it arrives, before A's own read of the event.
    a.pairing.events().listen((e) async {
      if (e.kind != PairingEventKind.requested) return;
      final r = (await a.pairing.requests()).singleWhere((q) => q.id == e.requestId);
      await a.service.passOnRequest(r);
      await a.pairing.dismissRequest(r.id);
    });
    final request = a.pairing.receiveRequest(from: 'esAnnaKey@epicbox.epiccash.com', name: 'Anna')!;
    await Future<void>.delayed(Duration.zero);
    await settle(a, b);
    expect(await a.pairing.requests(), isEmpty, reason: 'a stranger on A');
    final onB = (await b.pairing.requests()).single;
    expect((onB.id, onB.fromAddress, onB.inviteLink), (request.id, request.fromAddress, request.inviteLink));
    // Passed on again (another read of the list): nothing new reaches B.
    await a.service.passOnRequest(request);
    await settle(a, b);
    expect(await b.pairing.requests(), hasLength(1));
  });

  test("a notice for a slate A holds nothing of goes to B as it came, and B's core applies it", () async {
    a.session.unmatchedController.add(
      const UnmatchedNotice(slateId: 'out-1', kind: 'posted', sender: 'esPayerKey@epicbox.epiccash.com', notice: '{"lepic":1,"type":"posted"}'),
    );
    await Future<void>.delayed(Duration.zero);
    await settle(a, b);
    expect(b.session.forwardedNotices.single, (sender: 'esPayerKey@epicbox.epiccash.com', notice: '{"lepic":1,"type":"posted"}'));
    expect(a.session.forwardedNotices, isEmpty);
  });

  test('two phones of one wallet get names told apart: "Received on" names one device', () async {
    String withCode(String name, String code) => '$name $code';
    final p1 = Side('Phone', clock: clock, net: net, nameWithCode: withCode);
    final p2 = Side('Phone', clock: clock, net: net, nameWithCode: withCode);
    await linkBoth(p1, p2);
    expect(p1.service.book.deviceName, 'Phone ${deviceCode(p1.service.book.deviceId)}');
    expect(p1.service.book.devices.single.name, p2.service.book.deviceName);
    expect(p1.service.book.devices.single.name, isNot(p1.service.book.deviceName));
    p1.service.dispose();
    p2.service.dispose();
  });

  test("a linked device that renames itself to this device's name is told apart by its code", () async {
    String withCode(String name, String code) => '$name $code';
    final p1 = Side('Phone', clock: clock, net: net, nameWithCode: withCode);
    final p2 = Side('Tablet', clock: clock, net: net, nameWithCode: withCode);
    await linkBoth(p1, p2);
    await p2.service.renameThis(p1.service.book.deviceName);
    await settle(p1, p2);
    expect(p1.service.book.devices.single.name, '${p1.service.book.deviceName} ${deviceCode(p2.service.book.deviceId)}');
    p1.service.dispose();
    p2.service.dispose();
  });

  test('nothing is passed on without a linked device', () async {
    final c = Side('Laptop', clock: clock, net: net);
    await c.service.load();
    await c.service.forward(ForwardKind.cancelled, 'in-1');
    expect(c.service.book.outbox, isEmpty);
    expect(c.pairing.posted, isEmpty);
  });

  test('before a delete, every linked device is told, best effort', () async {
    await a.service.unlinkAll();
    await settle(a, b);
    expect(a.service.book.devices, isEmpty);
    expect(b.service.book.devices, isEmpty);
    expect(b.service.book.removedBy, 'Desktop');
    expect(await a.pairing.privatePairings(), isEmpty);
  });

  test('a session that closes mid-link lets the other device go', () async {
    final c = Side('Laptop', clock: clock, net: net);
    final d = Side('Tablet', clock: clock, net: net);
    await c.service.load();
    await d.service.load();
    await c.service.startShowing(const ['epicbox.epiccash.com']);
    await d.service.startScanned(c.service.link!.code!);
    await c.sync();
    expect(c.service.link!.phase, LinkPhase.linking);
    // The auto-lock closes C's session: its service goes with it.
    c.service.dispose();
    await d.sync();
    await d.sync();
    expect(d.service.link!.phase, LinkPhase.failed);
    expect(d.service.link!.failure, LinkFailure.cancelled);
    // D's pairing is gone with it.
    expect(await d.pairing.privatePairings(), isEmpty);
    d.service.dispose();
  });

  test('a fresh service on the stored book reads it back with the new fields', () async {
    final again = DeviceService(host: SessionDeviceHost(a.session), store: DeviceStore(a.store, chain: Chain.floonet), defaultName: 'Desktop', clock: clock.call);
    await again.load();
    final d = again.book.devices.single;
    expect(d.name, 'Phone');
    expect(d.kind, DeviceKind.phone);
    expect(d.otherVersion, isNull);
    expect(d.early, isEmpty);
    again.dispose();
  });
}
