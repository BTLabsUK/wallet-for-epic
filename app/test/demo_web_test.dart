// The web DemoApi against a fake HTTP side: the demo server's answers, the faucet's, and the
// end pushed over the wallet socket.

import 'dart:async';

import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/demo_server/server.dart' show demoEndedPush;
import 'package:epic_wallet/src/demo_web.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each request from a script and records it.
class FakeDemoHttp implements DemoHttp {
  final List<(String, Uri)> requests = [];
  final List<Object> answers = [];

  Future<DemoReply> _next(String method, Uri url) async {
    requests.add((method, url));
    final answer = answers.removeAt(0);
    if (answer is DemoReply) return answer;
    throw answer;
  }

  @override
  Future<DemoReply> api(String method, Uri url) => _next(method, url);

  @override
  Future<DemoReply> simplePost(Uri url) => _next('SIMPLE POST', url);
}

final l = englishStrings;

String textOf(Object error) => (error as LocalizedFormatException).text(l);

void main() {
  late FakeDemoHttp http;
  late StreamController<void> ended;
  late List<Uri> opened;
  late ServerDemoApi api;

  setUp(() {
    http = FakeDemoHttp();
    ended = StreamController<void>.broadcast();
    opened = [];
    api = ServerDemoApi(
      http: http,
      origin: Uri.parse('https://try.example/app/#/home'),
      ended: ended.stream,
      openLink: (uri) async => opened.add(uri),
      downloadUrl: Uri.parse('https://get.example/app.apk'),
    );
  });

  tearDown(() => ended.close());

  final demoUrl = Uri.parse('https://try.example/api/demo');

  group('status', () {
    test('none, ended and active, from same-origin /api/demo', () async {
      http.answers.addAll([
        const DemoReply(200, '{"state":"none"}'),
        const DemoReply(200, '{"state":"ended"}'),
        const DemoReply(200, '{"state":"active","expires":1791331200000}'),
      ]);
      expect(await api.status(), const DemoNone());
      expect(await api.status(), const DemoEnded());
      expect(await api.status(), DemoActive(DateTime.utc(2026, 10, 7, 0)));
      expect(http.requests, [
        ('GET', demoUrl),
        ('GET', demoUrl),
        ('GET', demoUrl),
      ]);
    });

    test('no answer, an error status or a strange body: unreachable', () async {
      http.answers.addAll([
        StateError('offline'),
        const DemoReply(502, 'bad gateway'),
        const DemoReply(200, '{"state":"active"}'),
        const DemoReply(200, 'not json'),
      ]);
      for (var i = 0; i < 4; i++) {
        final error = await api.status().then<Object>(
          (_) => fail('no error'),
          onError: (Object e) => e,
        );
        expect(textOf(error), l.demoServerUnreachable);
      }
    });
  });

  group('start', () {
    test('POST answers the new demo', () async {
      http.answers.add(
        const DemoReply(201, '{"state":"active","expires":1791331200000}'),
      );
      expect(await api.start(), DemoActive(DateTime.utc(2026, 10, 7, 0)));
      expect(http.requests.single, ('POST', demoUrl));
    });

    test('429 says full or rate, with the wait in minutes', () async {
      http.answers.addAll([
        const DemoReply(429, '{"error":"full","retryAfter":3600}'),
        const DemoReply(429, '{"error":"rate","retryAfter":61}'),
        const DemoReply(429, ''),
      ]);
      Future<String> refusal() => api.start().then<String>(
        (_) => fail('no error'),
        onError: (Object e) => textOf(e),
      );
      expect(await refusal(), l.demoStartFull(60));
      expect(await refusal(), l.demoStartTooMany(2));
      expect(await refusal(), l.demoStartFull(1));
    });

    test('another status, or no answer: unreachable', () async {
      http.answers.addAll([const DemoReply(500, ''), TimeoutException('slow')]);
      for (var i = 0; i < 2; i++) {
        await expectLater(
          api.start(),
          throwsA(
            predicate((Object e) => textOf(e) == l.demoServerUnreachable),
          ),
        );
      }
    });
  });

  test('end is a DELETE; a failure is unreachable', () async {
    http.answers.addAll([const DemoReply(204, ''), StateError('offline')]);
    await api.end();
    expect(http.requests.single, ('DELETE', demoUrl));
    await expectLater(api.end(), throwsA(isA<LocalizedFormatException>()));
  });

  group('claimTestCoins', () {
    const address =
        'esYsa7ozBHwpHTfDdyTQsw3GkVpjL1xxtnbjSq8NJAS8XcZKgSC5@flooepicbox.btlabs.uk:443';

    test('a simple POST to the faucet with the address in the query', () async {
      http.answers.add(const DemoReply(202, '{"ok":true}'));
      expect(await api.claimTestCoins(address), isA<TestCoinsPaid>());
      final (method, url) = http.requests.single;
      expect(method, 'SIMPLE POST');
      expect(url.origin, 'https://floo-explorer.btlabs.uk');
      expect(url.path, '/api/faucet/claim');
      expect(url.queryParameters, {
        'method': 'epicbox',
        'destination': address,
      });
    });

    test('429 is the cooldown, read from the body', () async {
      http.answers.addAll([
        const DemoReply(429, '{"error":"cooldown","retry_after":12}'),
        const DemoReply(429, '{"code":"cooldown","retryAfter":7.2}'),
        // The faucet's own answer, seen on 2026-10-06.
        const DemoReply(
          429,
          '{"code":"cooldown","message":"Please wait 31s between requests."}',
        ),
        const DemoReply(429, '{"code":"cooldown","message":"Wait 5 s."}'),
        const DemoReply(429, '{"code":"cooldown"}'),
        const DemoReply(429, 'Too Many Requests'),
      ]);
      Future<int> seconds() async =>
          (await api.claimTestCoins(address) as TestCoinsCooldown).seconds;
      expect(await seconds(), 12);
      expect(await seconds(), 8);
      expect(await seconds(), 31);
      expect(await seconds(), 5);
      expect(await seconds(), defaultFaucetCooldownSeconds);
      expect(await seconds(), defaultFaucetCooldownSeconds);
    });

    test('anything else, or no answer, failed', () async {
      http.answers.addAll([
        const DemoReply(400, '{"code":"bad_format"}'),
        const DemoReply(500, ''),
        StateError('CORS'),
      ]);
      for (var i = 0; i < 3; i++) {
        expect(await api.claimTestCoins(address), isA<TestCoinsFailed>());
      }
    });
  });

  test('ended, downloadUrl and openLink come from the wiring', () async {
    var ends = 0;
    api.ended.listen((_) => ends++);
    ended.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(ends, 1);
    expect(api.downloadUrl, Uri.parse('https://get.example/app.apk'));
    await api.openLink(api.downloadUrl!);
    expect(opened, [api.downloadUrl]);
  });

  test("the push name is the server's", () {
    expect(demoEndedPushName, demoEndedPush);
  });
}
