// SPDX-License-Identifier: Apache-2.0
// A chat app auto-links a pasted Epicbox address; the prefix is dropped, real URLs stay HTTP.

import 'package:epic_wallet/src/recipient.dart';
import 'package:flutter_test/flutter_test.dart';

final String _key = 'es${'b' * 50}';
final String _addr = '$_key@epicbox.epiccash.com';

void main() {
  for (final form in [
    'http://$_addr',
    'https://$_addr',
    'https://$_addr/',
    'HTTPS://$_addr',
    ' https://$_addr \n',
  ]) {
    test('epicbox from ${form.trim()}', () {
      final r = parseRecipient(form);
      expect(r.kind, RecipientKind.epicbox);
      expect(r.address, _addr);
    });
  }

  for (final url in [
    'http://192.168.1.5:3415',
    'https://wallet.example.org',
    'http://wallet.example.org:3415/',
    'https://$_addr/path',
    'https://$_addr?x=1',
    'https://$_addr:443',
    'https://${_key}0@epicbox.epiccash.com',
    'https://short@epicbox.epiccash.com',
    'https://$_key@10.0.0.1',
  ]) {
    test('stays HTTP: $url', () {
      final r = parseRecipient(url);
      expect(r.kind, RecipientKind.http);
      expect(r.address, url);
    });
  }

  test('bare epicbox address unchanged', () {
    expect(parseRecipient(_addr).address, _addr);
    expect(parseRecipient(_addr).kind, RecipientKind.epicbox);
  });
}
