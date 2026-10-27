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

    test('the node and the app\'s own requests go over Tor (E-12)', () {
      expect(torCovered, containsAll([TorRoute.epicbox, TorRoute.node, TorRoute.appHttp]));
      expect(torSkipsLocalNode, isTrue);
    });

    test('an onion needs Tor, waits for it and never goes direct', () {
      expect(torWay(TorRoute.onionDirect, TorState.off), TorWay.needsTor);
      expect(torWay(TorRoute.onionDirect, TorState.starting), TorWay.wait);
      expect(torWay(TorRoute.onionDirect, TorState.failed), TorWay.blocked);
      expect(torWay(TorRoute.onionDirect, TorState.on), TorWay.overTor);
    }, skip: !torBuilt ? 'no Tor in this build' : null);

    test('Link to http(s) stays on the clearnet in every state', () {
      for (final s in TorState.values) {
        expect(torWay(TorRoute.httpDirect, s), TorWay.clearnet, reason: s.name);
      }
      expect(torCovered, isNot(contains(TorRoute.httpDirect)));
    });

    test('push and the clearnet HTTP listener are off while Tor is on', () {
      for (final route in [TorRoute.push, TorRoute.httpListener]) {
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
      expect(priceFromBtlabs(body(), 'usd', now: now), 0.747664);
      expect(priceFromBtlabs(body(), 'eur', now: now), 0.66);
    });

    test('no price for another schema, a stale file or a missing currency', () {
      expect(priceFromBtlabs(body(schema: 2), 'usd', now: now), isNull);
      expect(priceFromBtlabs(body(at: '2026-10-23T13:00:00Z'), 'usd', now: now), isNull);
      expect(priceFromBtlabs(body(), 'gbp', now: now), isNull);
      expect(priceFromBtlabs(body(usd: 0), 'usd', now: now), isNull);
    });
  });
}
