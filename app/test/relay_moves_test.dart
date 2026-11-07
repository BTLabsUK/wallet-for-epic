// SPDX-License-Identifier: Apache-2.0
// A paired contact's relay move (`relay_moves.dart`), on the fake: a domain-backed contact
// asks once and waits for Accept or Refuse; any other is moved without a word and dated for
// 30 days; a relay that is not a public DNS name is never followed; the book reads back.
import 'dart:typed_data';

import 'package:epic_wallet/src/domain_backed.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/relay_moves.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isDomainBacked', () {
    test('a BT Labs key is; another key, or none, is not', () {
      expect(isDomainBacked((peerEncKey: FakePairing.serviceKey, domainProven: false)), isTrue);
      expect(isDomainBacked((peerEncKey: Uint8List(32), domainProven: false)), isFalse);
      expect(isDomainBacked((peerEncKey: null, domainProven: false)), isFalse);
    });
  });

  group('isPublicRelayHost', () {
    test('a public DNS name, with or without a port', () {
      expect(isPublicRelayHost('epicbox.example.org'), isTrue);
      expect(isPublicRelayHost('epicbox.example.org:443'), isTrue);
    });

    for (final host in [
      '192.168.1.20',
      '10.0.0.7:443',
      '[::1]',
      'localhost',
      'relay.localhost',
      'box.local',
      'relay.lan',
      'x.internal',
      'nas.home.arpa',
      'abcdefghijklmnop.onion',
      'relay',
      '',
    ]) {
      test('not $host', () => expect(isPublicRelayHost(host), isFalse));
    }
  });

  group('on the fake', () {
    late DateTime now;
    late FakePairing api;
    late List<PairingEvent> seen;

    setUp(() {
      now = DateTime(2026, 11, 6, 12);
      api = FakeWalletSession().pairing..clock = () => now;
      seen = [];
      api.events().listen(seen.add);
    });

    test('a domain-backed contact asks once; closing it leaves it open', () async {
      final r = api.seedPaired(name: 'Shop', relay: 'old.example.org', peerEncKey: FakePairing.serviceKey);
      await api.askRelayMove(r.id, 'new.example.org');

      var p = (await api.pairings()).single;
      expect((p.homeRelay, p.relayMove), ('old.example.org', RelayMoveState.ask));
      expect(relayMoveToAsk([p])?.id, r.id);

      await api.markRelayMoveShown(r.id, 'new.example.org');
      p = (await api.pairings()).single;
      expect(p.relayMove, RelayMoveState.open);
      expect(relayMoveToAsk([p]), isNull, reason: 'never shown as a dialog again');
      expect(p.homeRelay, 'old.example.org');
    });

    test('Accept moves the contact and dates it', () async {
      final r = api.seedPaired(name: 'Shop', relay: 'old.example.org', peerEncKey: FakePairing.serviceKey);
      await api.askRelayMove(r.id, 'new.example.org');
      await api.acceptRelayMove(r.id, 'new.example.org');

      final p = (await api.pairings()).single;
      expect((p.homeRelay, p.requestedRelay, p.relayMove), ('new.example.org', null, RelayMoveState.none));
      expect(p.movedAt, now);
      expect(api.calls, contains('acceptMove:${r.id}'));
    });

    test('Refuse moves nothing; the same relay is not asked again, another one is', () async {
      final r = api.seedPaired(name: 'Shop', relay: 'old.example.org', peerEncKey: FakePairing.serviceKey);
      await api.askRelayMove(r.id, 'new.example.org');
      await api.refuseRelayMove(r.id, 'new.example.org');

      var p = (await api.pairings()).single;
      expect((p.homeRelay, p.relayMove), ('old.example.org', RelayMoveState.refused));
      expect(p.movedAt, isNull);
      expect(api.moves.book.refused, {relayMoveKey(r.id, 'new.example.org')});

      await api.askRelayMove(r.id, 'third.example.org');
      p = (await api.pairings()).single;
      expect(p.relayMove, RelayMoveState.ask);
    });

    test('any other contact is moved without a word; the date goes after 30 days', () async {
      final r = api.seedPaired(name: 'Anna', relay: 'old.example.org');
      await api.askRelayMove(r.id, 'new.example.org');

      var p = (await api.pairings()).single;
      expect((p.homeRelay, p.relayMove, p.movedAt), ('new.example.org', RelayMoveState.none, now));
      expect(api.calls, contains('move:${r.id}'));
      expect(seen.map((e) => e.kind), everyElement(PairingEventKind.contactUpdated));

      now = now.add(const Duration(days: 29));
      expect((await api.pairings()).single.movedAt, isNotNull);
      now = now.add(const Duration(days: 2));
      p = (await api.pairings()).single;
      expect(p.movedAt, isNull);
    });

    test('a relay that is not a public DNS name is not followed, from anyone', () async {
      final anna = api.seedPaired(name: 'Anna', relay: 'old.example.org');
      final shop = api.seedPaired(name: 'Shop', relay: 'old.example.org', peerEncKey: FakePairing.serviceKey);
      await api.askRelayMove(anna.id, '192.168.1.20');
      await api.askRelayMove(shop.id, 'relay.lan');
      await api.acceptRelayMove(shop.id, 'relay.lan');

      for (final p in await api.pairings()) {
        expect((p.homeRelay, p.relayMove), ('old.example.org', RelayMoveState.notPublic));
      }
      expect(api.moves.book.moved, isEmpty);
    });

    test('a move waiting from before the open settles at the first list', () async {
      api.seedPaired(name: 'Anna', relay: 'old.example.org', requestedRelay: 'new.example.org');
      api.seedPaired(name: 'Shop', relay: 'old.example.org', requestedRelay: 'new.example.org', peerEncKey: FakePairing.serviceKey);

      final shown = {for (final p in await api.pairings()) p.name: (p.homeRelay, p.relayMove)};
      expect(shown['Anna'], ('new.example.org', RelayMoveState.none));
      expect(shown['Shop'], ('old.example.org', RelayMoveState.ask));
    });

    test('settleRelayMoves says when something moved', () async {
      api.seedPaired(name: 'Anna', relay: 'old.example.org', requestedRelay: 'new.example.org');
      await Future<void>.delayed(Duration.zero);
      seen.clear();
      await api.settleRelayMoves();
      await Future<void>.delayed(Duration.zero);
      expect(seen.map((e) => e.kind), [PairingEventKind.contactUpdated]);

      seen.clear();
      await api.settleRelayMoves();
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty);
    });
  });

  group('the book', () {
    test('reads back what it wrote, under its version', () {
      final book = RelayMoveBook(
        moved: [const RelayMoveRec(id: 'p1', from: 'a.example.org', to: 'b.example.org', at: 1792900000000)],
        shown: {relayMoveKey('p2', 'c.example.org')},
        refused: {relayMoveKey('p3', 'd.example.org:8443')},
      );
      final json = book.toJson();
      expect(json['v'], RelayMoveBook.version);
      final back = RelayMoveBook.fromJson(json);
      expect(back.moved, book.moved);
      expect(back.shown, book.shown);
      expect(back.refused, book.refused);
      expect(RelayMoveBook.fromJson(null).isEmpty, isTrue);
    });

    test('drops moves older than 30 days when it records one', () {
      final book = RelayMoveBook();
      const day = 86400000;
      book.recordMove('p1', 'a.example.org', 'b.example.org', 0);
      book.recordMove('p2', 'a.example.org', 'c.example.org', 31 * day);
      expect([for (final m in book.moved) m.id], ['p2']);
    });
  });
}
