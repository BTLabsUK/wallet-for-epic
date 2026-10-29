// SPDX-License-Identifier: Apache-2.0
// Every outside service the wallet asks, with no network: the status site, the price (CoinGecko
// and BT Labs' copy), the update manifests, the support report (the desktop's update check and reach check: desk_services_offline_test.dart). Each
// must answer its own "not available" in bounded time — refused connections at once, dropped
// packets within its timeout — never hang, never throw past its contract, and answer again
// once the network is back. The real HTTP code runs; [NoNetwork] stands in for the network.
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/support_report.dart';
import 'package:flutter_test/flutter_test.dart';

import 'no_network.dart';

final String _status = File('test/fixtures/status_btlabs_2026-10-22.json').readAsStringSync();

/// A network that is out, then back: [get] for the seams that take one.
class _Net {
  bool up = false;
  int asked = 0;
  Future<HttpReply> get(Uri url, {Duration timeout = defaultHttpTimeout}) async {
    asked++;
    if (!up) throw const NetError('SocketException');
    return HttpReply(200, _status);
  }
}

void main() {
  group('plain HTTP', () {
    test('refused: httpGet and httpPost throw NetError at once', () async {
      await withoutNetwork(NetCut.refuse, (net) async {
        final g = await timed(() => httpGet(Uri.parse('https://status.example/x'), timeout: const Duration(seconds: 5)));
        expect(g.error, isA<NetError>());
        expect(g.took, lessThan(const Duration(seconds: 2)));
        final p = await timed(() => httpPost(Uri.parse('https://intake.example/x'), body: const [1], contentType: 'text/plain', timeout: const Duration(seconds: 5)));
        expect(p.error, isA<NetError>());
        expect(net.asked, ['status.example', 'intake.example']);
      });
    });

    test('dropped: httpGet ends at its timeout, not later', () async {
      await withoutNetwork(NetCut.drop, (_) async {
        final g = await timed(() => httpGet(Uri.parse('https://status.example/x'), timeout: const Duration(seconds: 2)));
        expect(g.error, isA<TimeoutException>());
        expect(g.took, lessThan(const Duration(seconds: 4)));
      });
    });
  });

  group('status site', () {
    for (final cut in NetCut.values) {
      test('${cut.name}: the lists fail in their timeout, the caller sees NetError or a timeout', () async {
        await withoutNetwork(cut, (_) async {
          final d = HttpRelayDirectory(timeout: const Duration(seconds: 2));
          final r = await timed(() => d.nodes('mainnet'));
          expect(r.error, anyOf(isA<NetError>(), isA<TimeoutException>()));
          expect(r.took, lessThan(const Duration(seconds: 4)));
        });
      });
    }

    test('back online: the next read after the cache time answers, no restart', () async {
      final net = _Net();
      var now = DateTime(2026, 10, 29, 12);
      final d = HttpRelayDirectory(get: net.get, now: () => now);
      await expectLater(d.nodes('mainnet'), throwsA(isA<NetError>()));
      net.up = true;
      // Within the cache time the failure is kept (no request per screen)...
      await expectLater(d.nodes('mainnet'), throwsA(isA<NetError>()));
      expect(net.asked, 1);
      // ...and after it the site is asked again.
      now = now.add(const Duration(minutes: 2));
      expect(await d.nodes('mainnet'), isNotEmpty);
      expect(net.asked, 2);
    });
  });

  group('price', () {
    for (final cut in NetCut.values) {
      test('${cut.name}: both sources answer null in their timeout, never throw', () async {
        await withoutNetwork(cut, (_) async {
          final r = await timed(() => TorAwarePriceSource(
                coinGecko: const CoinGeckoPriceSource(timeout: Duration(seconds: 2)),
                btlabs: BtlabsPriceSource(timeout: const Duration(seconds: 2)),
              ).price('usd'));
          expect(r.error, isNull);
          expect(r.value, isNull);
          expect(r.took, lessThan(const Duration(seconds: 6)));
        });
      });
    }
  });

  group('support report', () {
    final report = SupportReport(created: DateTime.utc(2026, 10, 29), description: 'offline test', app: const {'version': 'test'});
    test('refused: Send says offline (SupportFailure.offline)', () async {
      await withoutNetwork(NetCut.refuse, (_) async {
        final r = await timed(() => HttpSupportSender(Uri.parse('https://intake.example/r'), timeout: const Duration(seconds: 3)).send(report, appVersion: 'test'));
        expect(r.error, isA<SupportSendError>().having((e) => e.reason, 'reason', SupportFailure.offline));
        expect(r.took, lessThan(const Duration(seconds: 3)));
      });
    });
    test('dropped: Send says the server did not answer in time', () async {
      await withoutNetwork(NetCut.drop, (_) async {
        final r = await timed(() => HttpSupportSender(Uri.parse('https://intake.example/r'), timeout: const Duration(seconds: 2)).send(report, appVersion: 'test'));
        expect(r.error, isA<SupportSendError>().having((e) => e.reason, 'reason', SupportFailure.timeout));
        expect(r.took, lessThan(const Duration(seconds: 4)));
      });
    });
  });
}
