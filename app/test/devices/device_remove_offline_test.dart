// SPDX-License-Identifier: Apache-2.0
// Remove while this device is offline: the notice waits in the book with the device shown as
// being removed, goes on the next read online, and only then the device and its pairings go.
import 'dart:convert';

import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_devices.dart';

void main() {
  late Clock clock;
  late FakePrivateNet net;
  late Side a;
  late Side b;
  var online = true;

  setUp(() async {
    clock = Clock();
    net = FakePrivateNet();
    online = true;
    a = Side('Desktop', clock: clock, net: net, online: () => online);
    b = Side('Phone', clock: clock, net: net);
    await linkBoth(a, b);
  });

  test('offline Remove keeps the notice and the pairings, shows the device as being removed', () async {
    final bId = b.service.book.deviceId;
    online = false;
    await a.service.removeDevice(bId);
    expect(a.service.book.devices, isEmpty);
    expect(a.service.book.removing.single.deviceId, bId);
    expect(a.service.book.outbox.where((o) => o.deviceId == bId), isNotEmpty);
    expect(await a.pairing.privatePairings(), isNotEmpty, reason: 'the pairing carries the notice later');
    expect(a.service.canLinkMore, isTrue, reason: 'a device being removed is not a link');
    await settle(a, b);
    expect(a.service.book.removing, hasLength(1));
    expect(b.service.book.devices.single.deviceId, a.service.book.deviceId, reason: 'nothing reached the other device yet');

    // Kept in the book's file; a file from before the field reads with nothing being removed.
    final json = jsonDecode(jsonEncode(a.service.book.toJson())) as Map<String, Object?>;
    expect(DeviceBook.fromJson(json)!.removing.single.deviceId, bId);
    expect(DeviceBook.fromJson({...json}..remove('removing'))!.removing, isEmpty);
  });

  test('the next read online posts the notice, then forgets the device and unpairs', () async {
    final bId = b.service.book.deviceId;
    online = false;
    await a.service.removeDevice(bId);
    online = true;
    await settle(a, b);
    expect(a.service.book.removing, isEmpty);
    expect(a.service.book.outbox, isEmpty);
    expect(await a.pairing.privatePairings(), isEmpty);
    expect(b.service.book.devices, isEmpty);
    expect(b.service.book.removedBy, 'Desktop');
    expect(b.service.canLinkMore, isTrue);
  });

  test('Remove again on a device being removed forgets it here at once', () async {
    final bId = b.service.book.deviceId;
    online = false;
    await a.service.removeDevice(bId);
    await a.service.removeDevice(bId);
    expect(a.service.book.removing, isEmpty);
    expect(a.service.book.outbox, isEmpty);
    expect(await a.pairing.privatePairings(), isEmpty);
  });

  test("the other device's own Remove ends the removal cleanly", () async {
    final bId = b.service.book.deviceId;
    online = false;
    await a.service.removeDevice(bId);
    await b.service.removeDevice(a.service.book.deviceId);
    expect(b.service.book.devices, isEmpty);
    online = true;
    await settle(a, b);
    expect(a.service.book.removing, isEmpty);
    expect(a.service.book.outbox, isEmpty);
    expect(await a.pairing.privatePairings(), isEmpty);
    expect(b.service.book.removing, isEmpty);
  });
}
