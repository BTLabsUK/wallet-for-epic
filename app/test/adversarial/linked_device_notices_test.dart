// SPDX-License-Identifier: Apache-2.0
// A linked device that turned hostile (lost, stolen, or linked by mistake) can only send
// notices. Whatever it says, it must not freeze this device's coins for good, write a payment
// row larger than its coins, steer the link to a server of its choice or spoof what the user
// reads.

import 'dart:convert';

import 'package:epic_wallet/src/devices/device_history.dart';
import 'package:epic_wallet/src/devices/device_locks.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart' show noticeWindow;
import 'package:epic_wallet/src/devices/device_wire.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/scan/scan_router.dart' show untrustedTextForbidden;
import 'package:flutter_test/flutter_test.dart';

import '../devices/two_devices.dart';

const _s1 = 'epicbox.epiccash.com';

/// One character by code point, so no invisible character sits in this file.
String _c(int codePoint) => String.fromCharCode(codePoint);

void main() {
  late Clock clock;
  late FakePrivateNet net;
  late Side a;
  late Side b;
  var seq = 0;

  setUp(() async {
    clock = Clock();
    net = FakePrivateNet();
    a = Side('Desktop', clock: clock, net: net);
    b = Side('Phone', clock: clock, net: net);
    await linkBoth(a, b);
    seq = b.service.book.devices.single.seqIn;
  });

  /// [a] says [type] with [body] to [b], numbered next, through their real pairing.
  Future<void> say(String type, Map<String, Object?> body, {String? id}) async {
    final d = b.service.book.device(a.service.book.deviceId)!;
    final env = {'v': 1, 'type': type, 'id': id ?? randomHexId(), 'seq': ++seq, 'dev': a.service.book.deviceId, 'ts': 1, 'body': body};
    b.pairing.receivePayload(d.pairings.values.first, utf8.encode(jsonEncode(env)));
    await b.sync();
  }

  // Coins on B: cm(1) 5 EPIC, cm(2) 3 EPIC, cm(3) 2 EPIC.
  final epic = BigInt.from(100000000);
  String amount(num e) => (BigInt.from(e * 100) * epic ~/ BigInt.from(100)).toString();

  group('holds', () {
    test('the_same_coin_named_many_times_counts_once_against_the_amount', () async {
      // 2 EPIC named five times is still 2 EPIC: a 10 EPIC payment on it is not believable.
      await say('send', {'slateId': 'dup', 'inputs': List.filled(5, cm(3)), 'amount': amount(9.9)});
      final shown = mergeDeviceHistory(const [], b.service.book);
      expect(b.service.book.holds, isEmpty, reason: 'the row would read ${shown.map((r) => r.amountDebited)}');
    });

    test('a_payment_larger_than_its_coins_holds_nothing', () async {
      await say('send', {'slateId': 'big', 'inputs': [cm(3)], 'amount': amount(2), 'fee': '1'});
      expect(b.service.book.holds, isEmpty);
      await say('send', {'slateId': 'ok', 'inputs': [cm(3)], 'amount': amount(1.99)});
      expect(b.service.book.holds, hasLength(1));
    });

    test('a_device_holds_at_most_its_cap_of_payments_at_once', () async {
      for (var i = 0; i < maxOpenHoldsPerDevice + 5; i++) {
        await say('send', {'slateId': 'p$i', 'inputs': [cm(1)], 'amount': '1'});
      }
      expect(b.service.book.holds.where((h) => h.state.holds), hasLength(maxOpenHoldsPerDevice));
    });

    test('coins_released_by_hand_are_never_held_again_by_a_new_notice', () async {
      await say('send', {'slateId': 'x1', 'inputs': [cm(1), cm(2)], 'amount': '1'});
      expect(b.service.book.heldCommitments, {cm(1), cm(2)});
      await b.service.releaseByHandOf(a.service.book.deviceId, 'x1');
      expect(b.service.book.heldCommitments, isEmpty);
      await say('send', {'slateId': 'x2', 'inputs': [cm(1)], 'amount': '1'});
      await say('send', {'slateId': 'x3', 'inputs': [cm(2), cm(3)], 'amount': '1'});
      expect(b.service.book.heldCommitments, isEmpty);
    });

    test('a_replayed_send_never_holds_again_after_its_release', () async {
      final id = randomHexId();
      await say('send', {'slateId': 'r', 'inputs': [cm(1)], 'amount': '1'}, id: id);
      await say('status', {'slateId': 'r', 'state': 'cancelled'});
      expect(b.service.book.heldCommitments, isEmpty);
      // The same envelope again, with a later number, and once with its own number.
      await say('send', {'slateId': 'r', 'inputs': [cm(1)], 'amount': '1'}, id: id);
      expect(b.service.book.heldCommitments, isEmpty);
    });

    test('a_notice_never_makes_this_device_spend', () async {
      await say('send', {'slateId': 's', 'inputs': [cm(1)], 'amount': '1'});
      await say('status', {'slateId': 's', 'state': 'posted', 'height': 1});
      await say('servers', {'set': ['evil.example.com'], 'version': 1 << 40});
      expect(b.session.sentAmounts, isEmpty);
      expect(b.session.epicboxSends, isEmpty);
    });

    test('a_status_cannot_release_another_devices_or_this_devices_holds', () async {
      // A hold of A's, then a status from A for a slate id it never sent.
      await say('send', {'slateId': 'mine', 'inputs': [cm(2)], 'amount': '1'});
      await say('status', {'slateId': 'not-mine', 'state': 'released'});
      expect(b.service.book.heldCommitments, {cm(2)});
    });
  });

  group('the link', () {
    test('a_server_change_waits_for_the_user_whatever_its_version', () async {
      await say('servers', {'set': ['evil.example.com'], 'version': 1 << 52});
      expect(b.service.book.servers, [_s1]);
      expect(b.service.book.devices.single.pairings.keys, [_s1]);
    });

    test('a_pairing_invite_on_a_server_outside_the_link_is_never_used', () async {
      final invite = await a.pairing.makePrivateInvite(name: 'x', homeRelay: 'evil.example.com');
      // Named as what it is: refused before it is answered.
      await say('pair2', {'inviteLink': invite.inviteLink, 'server': 'evil.example.com'});
      expect(b.service.book.devices.single.pending, isEmpty);
      // Labelled as a link server: answered, then dropped once the core names its real relay.
      await say('pair2', {'inviteLink': invite.inviteLink, 'server': _s1});
      await settle(a, b);
      final d = b.service.book.devices.single;
      expect(d.pairings.keys, [_s1]);
      final records = {for (final r in await b.pairing.privatePairings()) r.id: r};
      for (final id in d.pairingIds) {
        expect(records[id]?.homeRelay, isNot('evil.example.com'));
      }
      // One the other side never completes may wait, but is never in use.
      for (final p in d.pending) {
        expect(d.pairings.values, isNot(contains(p.pairingId)));
      }
    });

    test('a_notice_too_large_or_too_far_ahead_changes_nothing', () async {
      final name = b.service.book.devices.single.name;
      await say('rename', {'name': 'x' * 40, 'pad': 'y' * deviceNoticeMaxBytes});
      seq += noticeWindow + 10;
      await say('rename', {'name': 'Far'});
      expect(b.service.book.devices.single.name, name);
      expect(b.service.book.devices.single.waiting, isEmpty);
    });
  });

  group('what the user reads', () {
    final rlo = _c(0x202E);
    final lri = _c(0x2066);
    final zw = _c(0x200B);

    test('a_device_name_from_a_notice_carries_no_direction_or_invisible_characters', () async {
      await say('rename', {'name': 'Phone${rlo}lanigirO$zw'});
      expect(b.service.book.devices.single.name, isNot(contains(untrustedTextForbidden)));
    });

    test('a_payment_row_from_a_notice_carries_no_direction_or_invisible_characters', () async {
      await say('send', {
        'slateId': 'txt',
        'inputs': [cm(1)],
        'amount': '1',
        'counterparty': 'es${rlo}moc.liave@$lri',
        'message': 'refund\nto ${zw}me',
      });
      final row = mergeDeviceHistory(const [], b.service.book).single;
      expect(row.counterparty, isNot(contains(untrustedTextForbidden)));
      for (final m in row.messages) {
        expect(m.text, isNot(contains(untrustedTextForbidden)));
      }
    });
  });
}
