// SPDX-License-Identifier: Apache-2.0
// Send's recipient parser: an http(s) address names its method from the scheme on, and a URL
// without a port goes to its scheme's own (443, 80); a port typed always wins. A bare local
// address keeps the listener's port. The reach check then also asks the listener's port.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/send_reach.dart';
import 'package:epic_wallet/src/send_route.dart';
import 'package:flutter_test/flutter_test.dart';

RecipientInput _read(String text) => readRecipient(text, defaultRelay: 'epicbox.example.org', listenPort: 3415);

void main() {
  group('typing an http(s) address', () {
    test('https:// alone: Link · HTTPS, port 443', () {
      final r = _read('https://');
      expect(r.kind, RecipientInputKind.invalid);
      expect(r.isAddress, isFalse);
      expect(r.typing, RecipientInputKind.https);
      expect(r.urlKind, RecipientInputKind.https);
      expect(r.host, '');
      expect(r.port, 443);
    });

    test('http:// alone: Link · HTTP', () {
      expect(_read('http://').typing, RecipientInputKind.http);
    });

    test('half an IP address: still https, the host so far', () {
      final r = _read('https://192.168.1');
      expect(r.typing, RecipientInputKind.https);
      expect(r.host, '192.168.1');
      expect(r.port, 443);
    });

    test('a port being typed is the one shown', () {
      final r = _read('https://192.168:8080');
      expect(r.typing, RecipientInputKind.https);
      expect(r.port, 8080);
    });

    test('no scheme yet: no method', () {
      expect(_read('192.168.1').typing, isNull);
      expect(_read('https:/').typing, isNull);
    });
  });

  group('default port', () {
    test('https://host: 443, the port not shown', () {
      final r = _read('https://wallet.example.org');
      expect(r.kind, RecipientInputKind.https);
      expect(r.typing, isNull);
      expect(r.port, 443);
      expect(r.portShown, '');
      expect(r.address, 'https://wallet.example.org:443');
      expect(r.notes, contains(RecipientNote.defaultPort));
    });

    test('https://host/path?x=1: 443, the path kept, the query left out', () {
      final r = _read('https://onetime.us/7s626632?x=1');
      expect(r.kind, RecipientInputKind.https);
      expect(r.port, 443);
      expect(r.path, '/7s626632');
      expect(r.address, 'https://onetime.us:443/7s626632');
      expect(r.notes, containsAll([RecipientNote.defaultPort, RecipientNote.queryLeftOut]));
    });

    test('https://IP: 443', () {
      final r = _read('https://203.0.113.5');
      expect(r.kind, RecipientInputKind.https);
      expect(r.address, 'https://203.0.113.5:443');
    });

    test('http://host without a port: 80, written for LEPIC', () {
      final r = _read('http://wallet.example.org');
      expect(r.kind, RecipientInputKind.http);
      expect(r.port, 80);
      expect(r.portShown, '');
      expect(r.address, 'http://wallet.example.org:80');
      expect(r.notes, contains(RecipientNote.defaultPort));
    });

    test('https://host:port/path: the port typed, shown', () {
      final r = _read('https://wallet.example.org:8443/p');
      expect(r.port, 8443);
      expect(r.portShown, ':8443');
      expect(r.address, 'https://wallet.example.org:8443/p');
      expect(r.notes, isNot(contains(RecipientNote.defaultPort)));
    });

    test('host:3415 without a scheme: https, the port typed', () {
      final r = _read('wallet.example.org:3415');
      expect(r.kind, RecipientInputKind.https);
      expect(r.address, 'https://wallet.example.org:3415');
      expect(r.notes, isNot(contains(RecipientNote.defaultPort)));
    });

    test('an explicit 443 is kept', () {
      final r = _read('https://wallet.example.org:443');
      expect(r.port, 443);
      expect(r.address, 'https://wallet.example.org:443');
      expect(r.notes, isNot(contains(RecipientNote.defaultPort)));
    });

    test('an explicit 80 on http is kept', () {
      expect(_read('http://203.0.113.5:80').port, 80);
    });

    test('bare host: https added, 443', () {
      final r = _read('wallet.example.org');
      expect(r.kind, RecipientInputKind.https);
      expect(r.address, 'https://wallet.example.org:443');
      expect(r.notes, containsAll([RecipientNote.httpsAdded, RecipientNote.defaultPort]));
    });

    test('bare IPv4 on the local network: http on the listener port', () {
      final r = _read('192.168.1.24');
      expect(r.kind, RecipientInputKind.http);
      expect(r.address, 'http://192.168.1.24:3415');
      expect(r.portShown, ':3415');
    });

    test('bare IPv4 with a port: the port typed', () {
      expect(_read('192.168.1.24:8080').address, 'http://192.168.1.24:8080');
    });

    test('IPv6 in brackets without a port: 443', () {
      final r = _read('https://[2001:db8::1]');
      expect(r.kind, RecipientInputKind.https);
      expect(r.address, 'https://[2001:db8::1]:443');
    });

    test('bare IPv6: http on the listener port', () {
      expect(_read('fe80::1').address, 'http://[fe80::1]:3415');
    });
  });

  group('reach fallback', () {
    late HttpServer wallet;
    setUp(() async {
      wallet = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      wallet.listen((req) async {
        await req.drain<void>();
        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'result': {'Ok': {'foreign_api_version': 2, 'supported_slate_versions': ['V4']}},
          }));
        await req.response.close();
      });
    });
    tearDown(() => wallet.close(force: true));

    RecipientInput readAt(String t) => readRecipient(t, defaultRelay: '', listenPort: wallet.port);

    test('no port given, nothing on 80: the listener port answers', () async {
      final to = readAt('http://127.0.0.1/p');
      expect(to.port, 80);
      expect(await checkWalletAnswers(to, mode: NetworkMode.standard), ReachResult.noAnswer);
      final next = await reachFallback(to, mode: NetworkMode.standard, listenPort: wallet.port);
      expect(next?.address, 'http://127.0.0.1:${wallet.port}/p');
    });

    test('a port given: no fallback', () async {
      final to = readAt('http://127.0.0.1:1/p');
      expect(await reachFallback(to, mode: NetworkMode.standard, listenPort: wallet.port), isNull);
    });

    test('as typed answers: asked there first', () async {
      final to = readAt('http://127.0.0.1:${wallet.port}/p');
      expect(await checkWalletAnswers(to, mode: NetworkMode.standard), ReachResult.answers);
    });

    test('a website answers where no port was given: the listener port is asked too', () {
      final noPort = readAt('https://onetime.us/7s626632');
      expect(reachFallbackApplies(ReachResult.notWallet, noPort), isTrue);
      expect(reachFallbackApplies(ReachResult.noAnswer, noPort), isTrue);
      expect(reachFallbackApplies(ReachResult.answers, noPort), isFalse);
      final typed = readAt('https://onetime.us:8443/7s626632');
      expect(reachFallbackApplies(ReachResult.notWallet, typed), isFalse);
      expect(reachFallbackApplies(ReachResult.noAnswer, typed), isTrue);
    });
  });

  test('contacted names the port only when it is not the scheme\'s own', () {
    RecipientInput r(String t) => readRecipient(t, defaultRelay: '', listenPort: 3415);
    expect(r('https://onetime.us/7s626632').contacted, 'onetime.us');
    expect(r('http://wallet.example.org').contacted, 'wallet.example.org');
    expect(r('https://wallet.example.org:3415/p').contacted, 'wallet.example.org:3415');
    expect(r('192.168.1.24').contacted, '192.168.1.24:3415');
  });
}
