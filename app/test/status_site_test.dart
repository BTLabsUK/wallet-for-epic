// SPDX-License-Identifier: Apache-2.0
// Settings › Privacy › Use status.btlabs.uk: off, no request reaches the site and every reader
// takes the site-down path at once; requests that do go out say nothing about the wallet.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/desk_update.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/node/node_api.dart';
import 'package:epic_wallet/src/node/node_info.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _sample = File('test/fixtures/status_btlabs_2026-10-22.json').readAsStringSync();

/// A status client that records every host it is asked for.
class _Recorder {
  _Recorder({this.reply});

  final List<String> hosts = [];
  final Future<HttpReply> Function()? reply;

  Future<HttpReply> get(Uri url, {Duration timeout = defaultHttpTimeout}) async {
    hosts.add(url.host);
    return reply != null ? reply!() : HttpReply(200, _sample);
  }
}

/// A node that answers its own foreign API.
NodeApiClient _node(String url) => NodeApiClient(
  url,
  transport: (uri, body, headers, t) async {
    final method = (jsonDecode(body) as Map)['method'];
    final ok = switch (method) {
      'get_tip' => {'height': 3764980, 'last_block_pushed': 'ab', 'total_difficulty': {}},
      'ready_for_txs' => {'ready_for_txs': true},
      'get_version' => {'node_version': '4.1.0', 'block_header_version': 6},
      'get_header' => {'height': 3764980, 'timestamp': '2026-10-22T14:16:03+00:00'},
      _ => throw StateError('$method'),
    };
    return (status: 200, body: jsonEncode({'result': {'Ok': ok}}));
  },
);

void main() {
  tearDown(() => statusSite.on = true);

  group('directory', () {
    test('off: no request, a NetError at once, every list', () async {
      final site = StatusSiteSwitch()..on = false;
      final r = _Recorder();
      final dir = HttpRelayDirectory(get: r.get, site: site);
      await expectLater(dir.nodes('mainnet'), throwsA(isA<NetError>()));
      await expectLater(dir.relays('mainnet'), throwsA(isA<NetError>()));
      await expectLater(dir.network('floonet'), throwsA(isA<NetError>()));
      expect(r.hosts, isEmpty);
    });

    test('a change applies at once, both ways, past the cache', () async {
      final site = StatusSiteSwitch();
      final r = _Recorder();
      final dir = HttpRelayDirectory(get: r.get, site: site);
      expect(await dir.nodes('mainnet'), hasLength(5));
      expect(r.hosts, ['status.btlabs.uk']);
      site.on = false;
      await expectLater(dir.nodes('mainnet'), throwsA(isA<NetError>()));
      expect(r.hosts, hasLength(1));
      site.on = true;
      expect(await dir.nodes('mainnet'), hasLength(5));
      expect(r.hosts, hasLength(2));
    });

    test('a saved off is waited for: nothing goes out while it loads', () async {
      final site = StatusSiteSwitch();
      final saved = Completer<bool>();
      site.loadFrom(saved.future);
      final r = _Recorder();
      final dir = HttpRelayDirectory(get: r.get, site: site);
      final nodes = dir.nodes('mainnet');
      saved.complete(false);
      await expectLater(nodes, throwsA(isA<NetError>()));
      expect(site.on, isFalse);
      expect(r.hosts, isEmpty);
      // Turned on later: the failure made while loading is not served from the cache.
      site.on = true;
      expect(await dir.nodes('mainnet'), hasLength(5));
    });

    test('a saved choice that cannot be read keeps the site on', () async {
      final site = StatusSiteSwitch()..loadFrom(Future.error(StateError('keystore')));
      expect(await site.allowed(), isTrue);
    });

    for (final (name, reply) in [
      ('503', () async => const HttpReply(503, 'down')),
      ('a timeout', () => Completer<HttpReply>().future),
    ]) {
      test('site down ($name): one request a minute, no retry storm', () async {
        final r = _Recorder(reply: reply);
        final dir = HttpRelayDirectory(get: r.get, timeout: const Duration(milliseconds: 30));
        for (var i = 0; i < 5; i++) {
          await expectLater(dir.nodes('mainnet'), throwsA(anything));
          await expectLater(dir.relays('mainnet'), throwsA(anything));
        }
        expect(r.hosts, hasLength(1));
      });
    }
  });

  group('over Tor', () {
    tearDown(() => TorSwitch.on = false);

    // The site over Tor is its onion, about 3 s warm and more cold: the direct limit made
    // "status.btlabs.uk not reachable" show with the site up (26.10.17).
    Future<HttpReply> slow() => Future.delayed(const Duration(milliseconds: 150), () => HttpReply(200, _sample));

    test('Tor on: a slow onion answer is read, not timed out', () async {
      TorSwitch.on = true;
      final r = _Recorder(reply: slow);
      final dir = HttpRelayDirectory(
        get: r.get,
        timeout: const Duration(milliseconds: 30),
        torTimeout: const Duration(seconds: 2),
      );
      expect(await dir.nodes('mainnet'), isNotEmpty);
    });

    // A cold onion rendezvous: tor's SOCKS error on the first try, an answer on the next.
    Future<HttpReply> Function() failOnce() {
      var calls = 0;
      return () async {
        if (calls++ == 0) throw const NetError('SocksError');
        return HttpReply(200, _sample);
      };
    }

    test('Tor on: a failed first try is tried once more', () async {
      TorSwitch.on = true;
      final r = _Recorder(reply: failOnce());
      final dir = HttpRelayDirectory(get: r.get, torRetryPause: const Duration(milliseconds: 10));
      expect(await dir.nodes('mainnet'), isNotEmpty);
      expect(r.hosts, hasLength(2));
    });

    test('Tor off: a failure is not tried again', () async {
      final r = _Recorder(reply: failOnce());
      final dir = HttpRelayDirectory(get: r.get, torRetryPause: const Duration(milliseconds: 10));
      await expectLater(dir.nodes('mainnet'), throwsA(isA<NetError>()));
      expect(r.hosts, hasLength(1));
    });

    test('Tor off: the short limit still applies', () async {
      final r = _Recorder(reply: slow);
      final dir = HttpRelayDirectory(
        get: r.get,
        timeout: const Duration(milliseconds: 30),
        torTimeout: const Duration(seconds: 2),
      );
      await expectLater(dir.nodes('mainnet'), throwsA(isA<TimeoutException>()));
    });
  });

  group('readers', () {
    test('node info off: limited info from the node itself, no error, no request', () async {
      final site = StatusSiteSwitch()..on = false;
      final r = _Recorder();
      final dir = HttpRelayDirectory(get: r.get, site: site);
      final info = await NodeInfoService(nodes: dir, network: dir, clientFor: _node).info('https://node.epiccash.com:3413', chain: 'mainnet');
      expect(info.source, NodeInfoSource.limited);
      expect(info.height, 3764980);
      expect(info.error, isNull);
      expect(r.hosts, isEmpty);
    });

    test('first run off: relay health is empty at once, the built-in relays stand', () async {
      statusSite.on = false;
      final r = _Recorder();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [relayDirectoryProvider.overrideWithValue(HttpRelayDirectory(get: r.get))],
      );
      addTearDown(container.dispose);
      final sub = container.listen(relayStatusProvider(mainnetPreset), (_, _) {});
      addTearDown(sub.close);
      await expectLater(container.read(relayStatusProvider(mainnetPreset).future), throwsA(isA<NetError>()));
      expect(r.hosts, isEmpty);
    });

    test('providers read again when the switch flips', () async {
      final r = _Recorder();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [relayDirectoryProvider.overrideWithValue(HttpRelayDirectory(get: r.get))],
      );
      addTearDown(container.dispose);
      final sub = container.listen(relayStatusProvider(mainnetPreset), (_, _) {});
      addTearDown(sub.close);
      expect(await container.read(relayStatusProvider(mainnetPreset).future), hasLength(4));
      // Mainnet also asks floonet's list for flooepicbox.btlabs.uk's health.
      final asked = r.hosts.length;
      statusSite.on = false;
      await expectLater(container.read(relayStatusProvider(mainnetPreset).future), throwsA(isA<NetError>()));
      expect(r.hosts, hasLength(asked), reason: 'switched off: no request');
    });
  });

  group('phone setting', () {
    test('on by default, saved, and applied to the switch', () async {
      final store = MemorySecretStore();
      final container = ProviderContainer(overrides: [secretStoreProvider.overrideWithValue(store)]);
      addTearDown(container.dispose);
      expect((await container.read(appSettingsProvider.future)).useStatusSite, isTrue);
      expect(await readUseStatusSite(store), isTrue);
      await container.read(appSettingsProvider.notifier).setUseStatusSite(false);
      expect(statusSite.on, isFalse);
      expect(container.read(appSettingsProvider).value!.useStatusSite, isFalse);
      expect(await readUseStatusSite(store), isFalse);
      statusSite.on = true;
      container.invalidate(appSettingsProvider);
      expect((await container.read(appSettingsProvider.future)).useStatusSite, isFalse);
      expect(statusSite.on, isFalse);
    });
  });

  group('requests', () {
    test('a GET carries no User-Agent, no cookie and no app header', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      HttpHeaders? seen;
      server.listen((request) {
        seen = request.headers;
        request.response
          ..write('{}')
          ..close();
      });
      final reply = await httpGet(Uri.parse('http://127.0.0.1:${server.port}/api/v1/status.json'));
      expect(reply.status, 200);
      expect(seen!.value(HttpHeaders.userAgentHeader), isNull);
      expect(seen!.value(HttpHeaders.cookieHeader), isNull);
      final names = <String>[];
      seen!.forEach((name, _) => names.add(name));
      // Only what any HTTP client sends.
      expect(names.toSet().difference({'host', 'accept-encoding', 'content-length'}), isEmpty);
    });

    test("the desktop's update manifest: no User-Agent, no cookie", () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      HttpHeaders? seen;
      server.listen((request) {
        seen = request.headers;
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final (status, _) = await container.read(deskManifestFetchProvider)(Uri.parse('http://127.0.0.1:${server.port}/update.json'));
      expect(status, 404);
      expect(seen!.value(HttpHeaders.userAgentHeader), isNull);
      expect(seen!.value(HttpHeaders.cookieHeader), isNull);
    });
  });
}
