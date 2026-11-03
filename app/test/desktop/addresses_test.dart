// SPDX-License-Identifier: Apache-2.0
// parseAddress: every input row of the review's table behaves as LEPIC does.

import 'package:epic_wallet/src/desktop/data/addresses.dart';
import 'package:epic_wallet/src/desktop/data/api.dart';
import 'package:flutter_test/flutter_test.dart';

const _name = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';
const _onion = '$_name.onion';
const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';

/// Accepts what the real validators accept for these samples: an onion only when it is
/// [_onion], an epicbox address only when its key is [_key].
class _Api implements DeskWalletApi {
  @override
  bool isOnionAddress(String to) => to == _onion;
  @override
  bool isEpicboxAddress(String to) => to.split('@').first == _key;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

void main() {
  final api = _Api();

  group('Tor', () {
    for (final form in [
      _name,
      _onion,
      'http://$_onion',
      'http://$_name/',
      '$_onion:3415',
      'http://$_onion:3415/v2/foreign',
      _onion.toUpperCase(),
      'HTTP://${_onion.toUpperCase()}/',
      '  $_onion \n',
      '$_name .onion',
    ]) {
      test('"$form" is $_onion', () {
        final a = parseAddress(form, api);
        expect(a.kind, AddressKind.tor);
        expect(a.canonical, _onion);
        expect(a.complete, isTrue);
      });
    }

    test('https://onion is not a form LEPIC takes: http kind, incomplete', () {
      final a = parseAddress('https://$_onion/', api);
      expect(a.kind, AddressKind.http);
      expect(a.complete, isFalse);
    });

    test('a bad checksum is Tor but not complete', () {
      final bad = '${'a' * 55}d.onion';
      final a = parseAddress(bad, api);
      expect(a.kind, AddressKind.tor);
      expect(a.canonical, bad);
      expect(a.complete, isFalse);
    });

    test('a v2 (16 character) onion is not an address', () {
      final a = parseAddress('expyuzz4wqqyqhjn.onion', api);
      expect(a.kind, AddressKind.none);
      expect(a.complete, isFalse);
    });
  });

  group('HTTP', () {
    test('https://host is http and complete', () {
      final a = parseAddress('https://pay.example.org', api);
      expect(a.kind, AddressKind.http);
      expect(a.canonical, 'https://pay.example.org');
      expect(a.complete, isTrue);
    });
    test('an IPv4 with a port and localhost are complete', () {
      expect(parseAddress('http://192.168.1.24:3415', api).complete, isTrue);
      expect(parseAddress('http://localhost:3415', api).complete, isTrue);
    });
    test('a single-label host is http but incomplete', () {
      final a = parseAddress('http://printer', api);
      expect(a.kind, AddressKind.http);
      expect(a.complete, isFalse);
    });
    test('no host is none', () {
      expect(parseAddress('https://', api).kind, AddressKind.none);
    });
    test('whitespace is removed', () {
      expect(parseAddress(' https://pay.example.org \n', api).canonical, 'https://pay.example.org');
    });
  });

  group('Epicbox', () {
    test('key@host', () {
      final a = parseAddress('$_key@epicbox.epiccash.com', api);
      expect(a.kind, AddressKind.epicbox);
      expect(a.canonical, '$_key@epicbox.epiccash.com');
      expect(a.complete, isTrue);
    });
    test('epicbox:// is dropped', () {
      final a = parseAddress('epicbox://$_key@epicbox.epiccash.com', api);
      expect(a.kind, AddressKind.epicbox);
      expect(a.canonical, '$_key@epicbox.epiccash.com');
    });
    test('a bare key without @ is epicbox', () {
      final a = parseAddress(_key, api);
      expect(a.kind, AddressKind.epicbox);
      expect(a.canonical, _key);
      expect(a.complete, isTrue);
    });
    test('a wrong checksum is epicbox but incomplete', () {
      final a = parseAddress('${_key.substring(0, 51)}x@epicbox.epiccash.com', api);
      expect(a.kind, AddressKind.epicbox);
      expect(a.complete, isFalse);
    });
  });

  group('none', () {
    for (final text in ['', 'hello', 'es5x', 'bob@example.com', '0OIl${'1' * 50}']) {
      test('"$text"', () {
        final a = parseAddress(text, api);
        expect(a.kind, AddressKind.none);
        expect(a.complete, isFalse);
      });
    }
  });
}
