// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('torWay', () {
    test('nothing covered goes on the clearnet while Tor starts or failed', () {
      for (final route in torCovered) {
        expect(torWay(route, TorState.starting), TorWay.wait, reason: route.name);
        expect(torWay(route, TorState.failed), TorWay.blocked, reason: route.name);
        expect(torGoes(torWay(route, TorState.starting)), isFalse);
        expect(torGoes(torWay(route, TorState.failed)), isFalse);
        expect(torWay(route, TorState.on), TorWay.overTor, reason: route.name);
        expect(torWay(route, TorState.off), TorWay.clearnet, reason: route.name);
      }
      expect(torCovered, contains(TorRoute.epicbox));
    });

    test('the node and the app\'s own requests go over Tor', () {
      expect(torCovered, containsAll([TorRoute.epicbox, TorRoute.node, TorRoute.appHttp]));
      expect(torSkipsLocalNode, isTrue);
    });

    test('an onion needs Tor, waits for it and never goes direct', () {
      expect(torWay(TorRoute.onionDirect, TorState.off), TorWay.needsTor);
      expect(torWay(TorRoute.onionDirect, TorState.starting), TorWay.wait);
      expect(torWay(TorRoute.onionDirect, TorState.failed), TorWay.blocked);
      expect(torWay(TorRoute.onionDirect, TorState.on), TorWay.overTor);
    }, skip: !torBuilt ? 'no Tor in this build' : null);

    test('Link to https goes over Tor while Tor is on, as Epicbox does', () {
      expect(torCovered, contains(TorRoute.httpDirect));
      expect(torWay(TorRoute.httpDirect, TorState.off), TorWay.clearnet);
      expect(torWay(TorRoute.httpDirect, TorState.starting), TorWay.wait);
      expect(torWay(TorRoute.httpDirect, TorState.failed), TorWay.blocked);
      expect(torWay(TorRoute.httpDirect, TorState.on), TorWay.overTor);
    });

    test('the clearnet HTTP listener and plain http to another device are off while Tor is on', () {
      for (final route in [TorRoute.httpListener, TorRoute.plainHttpDirect]) {
        expect(torWay(route, TorState.off), TorWay.clearnet);
        for (final s in [TorState.starting, TorState.on, TorState.failed]) {
          expect(torWay(route, s), TorWay.off, reason: '${route.name} ${s.name}');
        }
      }
    });
  });

  group('priceFromBtlabs', () {
    final now = DateTime.utc(2026, 10, 23, 14, 30);
    String body({int schema = 1, String at = '2026-10-23T14:19:12Z', Object? usd = 0.747664}) =>
        '{"schema":$schema,"coin":"epic-cash","updated_at":"$at","prices":{"usd":$usd,"eur":0.66}}';

    test('reads the currency', () {
      expect(priceFromBtlabs(body(), 'usd', now: now, maxAge: const Duration(minutes: 30)), 0.747664);
      expect(priceFromBtlabs(body(), 'eur', now: now, maxAge: const Duration(minutes: 30)), 0.66);
    });

    test('no price for another schema, a stale file or a missing currency', () {
      expect(priceFromBtlabs(body(schema: 2), 'usd', now: now, maxAge: const Duration(minutes: 30)), isNull);
      expect(priceFromBtlabs(body(at: '2026-10-23T13:00:00Z'), 'usd', now: now, maxAge: const Duration(minutes: 30)), isNull);
      expect(priceFromBtlabs(body(), 'gbp', now: now, maxAge: const Duration(minutes: 30)), isNull);
      expect(priceFromBtlabs(body(usd: 0), 'usd', now: now, maxAge: const Duration(minutes: 30)), isNull);
    });
  });
}
