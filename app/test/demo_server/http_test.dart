// SPDX-License-Identifier: Apache-2.0
// The demo API over real HTTP on a loopback port: create, status, end, the cap and the rate.

import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/demo_server/config.dart';
import 'package:epic_wallet/src/demo_server/demo_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  test('create sets the cookie with its flags, then status and end', () async {
    final h = await Harness.start();
    final v = Visitor(h);

    expect((await v.status()).json, {'state': 'none'});

    final before = DateTime.now();
    final created = await v.start();
    expect(created.status, HttpStatus.created);
    final set = created.setCookie!;
    final attrs = set.split(';').map((s) => s.trim().toLowerCase()).toList();
    expect(
      attrs,
      containsAll(['httponly', 'secure', 'samesite=strict', 'path=/']),
    );
    expect(attrs.firstWhere((a) => a.startsWith('max-age=')), 'max-age=86400');
    expect(isDemoId(v.cookie!), isTrue, reason: '32 bytes as hex');

    final expires = DateTime.fromMillisecondsSinceEpoch(
      created.json['expires']! as int,
    );
    expect(created.json['state'], 'active');
    expect(
      expires.difference(before).inMinutes,
      inInclusiveRange(24 * 60 - 1, 24 * 60),
    );
    final record = jsonDecode(
      await File('${h.server.store.dirOf(v.cookie!)}/demo.json').readAsString(),
    );
    expect(record['expires'], created.json['expires']);

    final status = await v.status();
    expect(status.json, {
      'state': 'active',
      'expires': created.json['expires'],
    });
    expect(status.headers.value(HttpHeaders.cacheControlHeader), 'no-store');

    // A second start while one is live answers the same demo.
    final again = await v.start();
    expect(again.status, HttpStatus.ok);
    expect(again.json['expires'], created.json['expires']);
    expect(h.server.liveCount, 1);

    final id = v.cookie!;
    final ended = await v.end();
    expect(ended.status, HttpStatus.noContent);
    expect(ended.setCookie, contains('Max-Age=0'));
    expect(v.cookie, isNull);
    expect(await Directory(h.server.store.dirOf(id)).exists(), isFalse);
    expect(h.server.liveCount, 0);

    // The old cookie after the end reads as ended, and is cleared.
    v.cookie = id;
    final after = await v.status();
    expect(after.json, {'state': 'ended'});
    expect(v.cookie, isNull);
    expect((await v.status()).json, {'state': 'none'});
  });

  test('every response carries the serving rules headers', () async {
    final h = await Harness.start();
    final r = await Visitor(h).call('GET', '/api/health');
    expect(r.json, {'ok': true, 'live': 0, 'cap': 300});
    final hs = r.headers;
    expect(hs.value('strict-transport-security'), isNotNull);
    expect(hs.value('x-content-type-options'), 'nosniff');
    expect(hs.value('referrer-policy'), 'strict-origin-when-cross-origin');
    expect(hs.value('cross-origin-opener-policy'), 'same-origin');
    expect(hs.value('cross-origin-embedder-policy'), isNull);
    expect(hs.value('permissions-policy'), contains('camera=()'));
    expect(
      hs.value('content-security-policy'),
      contains("frame-ancestors 'none'"),
    );
    expect(
      hs.value('content-security-policy-report-only'),
      contains("'wasm-unsafe-eval'"),
    );
    expect(
      (await Visitor(h).call('GET', '/nothing')).status,
      HttpStatus.notFound,
    );
  });

  test('the live cap answers 429 with Retry-After', () async {
    final h = await Harness.start(
      config: (root) => DemoServerConfig(
        dataRoot: root,
        port: 0,
        maxLiveDemos: 2,
        newDemosPerClientPerHour: 100,
      ),
    );
    expect((await Visitor(h).start()).status, HttpStatus.created);
    expect((await Visitor(h).start()).status, HttpStatus.created);
    final full = await Visitor(h).start();
    expect(full.status, HttpStatus.tooManyRequests);
    expect(full.json['error'], 'full');
    final retry = int.parse(full.headers.value(HttpHeaders.retryAfterHeader)!);
    expect(retry, inInclusiveRange(24 * 3600 - 60, 24 * 3600 + 1));
    expect(full.setCookie, isNull);
    expect(h.server.liveCount, 2);
  });

  test('the rate limit counts per client, from X-Forwarded-For only behind the proxy', () async {
    final h = await Harness.start(
      config: (root) => DemoServerConfig(
        dataRoot: root,
        port: 0,
        newDemosPerClientPerHour: 2,
        trustProxy: true,
      ),
    );
    Visitor from(String ip) => Visitor(h, forwardedFor: 'spoofed, $ip');
    expect((await from('203.0.113.1').start()).status, HttpStatus.created);
    expect((await from('203.0.113.1').start()).status, HttpStatus.created);
    final limited = await from('203.0.113.1').start();
    expect(limited.status, HttpStatus.tooManyRequests);
    expect(limited.json['error'], 'rate');
    final retry = int.parse(
      limited.headers.value(HttpHeaders.retryAfterHeader)!,
    );
    expect(retry, inInclusiveRange(3500, 3601));
    // Another client, by the last hop, still gets one.
    expect((await from('203.0.113.2').start()).status, HttpStatus.created);
    // No address reaches the log.
    expect(logged.where((l) => l.contains('203.0.113')), isEmpty);
  });

  test('without trust-proxy, X-Forwarded-For is ignored', () async {
    final h = await Harness.start(
      config: (root) => DemoServerConfig(
        dataRoot: root,
        port: 0,
        newDemosPerClientPerHour: 1,
      ),
    );
    expect(
      (await Visitor(h, forwardedFor: '203.0.113.1').start()).status,
      HttpStatus.created,
    );
    expect(
      (await Visitor(h, forwardedFor: '203.0.113.2').start()).status,
      HttpStatus.tooManyRequests,
    );
  });

  test('a foreign Origin cannot start or end a demo', () async {
    final h = await Harness.start();
    final evil = Visitor(h, origin: 'https://evil.example');
    expect((await evil.start()).status, HttpStatus.forbidden);
    expect(h.server.liveCount, 0);
    final v = Visitor(h);
    await v.start();
    evil.cookie = v.cookie;
    expect((await evil.end()).status, HttpStatus.forbidden);
    expect(h.server.liveCount, 1);
  });

  test('logs name a demo by its first 8 characters only', () async {
    logged.clear();
    final h = await Harness.start();
    final v = Visitor(h);
    await v.start();
    final id = v.cookie!;
    await v.end();
    expect(
      logged.where((l) => l.contains('demo ${id.substring(0, 8)} started')),
      hasLength(1),
    );
    for (final line in logged) {
      expect(line, isNot(contains(id.substring(0, 9))), reason: line);
    }
  });
}
