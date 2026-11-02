// SPDX-License-Identifier: Apache-2.0
// Send's recipient parser: an http(s) address names its method from the scheme on, and a URL
// without a port goes to the listener's default (3415), never 443; a port typed always wins.
import 'package:epic_wallet/src/send_route.dart';
import 'package:flutter_test/flutter_test.dart';

RecipientInput _read(String text) => readRecipient(text, defaultRelay: 'epicbox.example.org', listenPort: 3415);

void main() {
  group('typing an http(s) address', () {
    test('https:// alone: Link · HTTPS, port 3415', () {
      final r = _read('https://');
      expect(r.kind, RecipientInputKind.invalid);
      expect(r.isAddress, isFalse);
      expect(r.typing, RecipientInputKind.https);
      expect(r.urlKind, RecipientInputKind.https);
      expect(r.host, '');
      expect(r.port, 3415);
    });

    test('http:// alone: Link · HTTP', () {
      expect(_read('http://').typing, RecipientInputKind.http);
    });

    test('half an IP address: still https, the host so far', () {
      final r = _read('https://192.168.1');
      expect(r.typing, RecipientInputKind.https);
      expect(r.host, '192.168.1');
      expect(r.port, 3415);
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
    test('https://host: 3415, written in the address', () {
      final r = _read('https://wallet.example.org');
      expect(r.kind, RecipientInputKind.https);
      expect(r.typing, isNull);
      expect(r.port, 3415);
      expect(r.address, 'https://wallet.example.org:3415');
      expect(r.notes, contains(RecipientNote.defaultPort));
    });

    test('https://IP: 3415', () {
      final r = _read('https://203.0.113.5');
      expect(r.kind, RecipientInputKind.https);
      expect(r.address, 'https://203.0.113.5:3415');
    });

    test('http://host without a port: 3415', () {
      final r = _read('http://wallet.example.org');
      expect(r.kind, RecipientInputKind.http);
      expect(r.port, 3415);
      expect(r.address, 'http://wallet.example.org:3415');
    });

    test('https://host:port: the port typed', () {
      final r = _read('https://wallet.example.org:8443');
      expect(r.port, 8443);
      expect(r.address, 'https://wallet.example.org:8443');
      expect(r.notes, isNot(contains(RecipientNote.defaultPort)));
    });

    test('an explicit 443 is kept', () {
      final r = _read('https://wallet.example.org:443');
      expect(r.port, 443);
      expect(r.address, 'https://wallet.example.org:443');
    });

    test('an explicit 80 on http is kept', () {
      expect(_read('http://203.0.113.5:80').port, 80);
    });

    test('no scheme: https added, port 3415', () {
      final r = _read('wallet.example.org');
      expect(r.kind, RecipientInputKind.https);
      expect(r.address, 'https://wallet.example.org:3415');
    });

    test('IPv6 in brackets without a port: 3415', () {
      final r = _read('https://[2001:db8::1]');
      expect(r.kind, RecipientInputKind.https);
      expect(r.address, 'https://[2001:db8::1]:3415');
    });
  });
}
