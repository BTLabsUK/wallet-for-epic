// SPDX-License-Identifier: Apache-2.0
// `https://` or `http://` in front of an epic1 link (chat apps and web pages add it) is
// dropped; a host that starts with "epic1" stays an HTTP wallet address.

import 'package:epic_wallet/src/recipient.dart';
import 'package:flutter_test/flutter_test.dart';

const _bare = 'epic1qw508d6qejxtdg4y5r3zarvary0c5xw7kxw5r4tm8q9';
const _tbare = 'tepic1qw508d6qejxtdg4y5r3zarvary0c5xw7kxw5r4tm8q9';
const _link = 'epic:$_bare?epicbox=epicbox.example.org';

void main() {
  final epic1Cases = <(String, String)>[
    ('https://$_link', _link),
    ('http://epic://$_bare?epicbox=epicbox.example.org', 'epic://$_bare?epicbox=epicbox.example.org'),
    ('HTTPS://EPIC:${_bare.toUpperCase()}?EPICBOX=X', 'EPIC:${_bare.toUpperCase()}?EPICBOX=X'),
    ('https://$_bare', _bare),
    ('https://$_bare/', '$_bare/'),
    ('https://$_tbare', _tbare),
    ('https://epic:$_tbare?epicbox=x', 'epic:$_tbare?epicbox=x'),
    (_link, _link),
    (_bare, _bare),
  ];
  for (final (input, address) in epic1Cases) {
    test('"$input" is an epic1 recipient', () {
      final r = parseRecipient(input);
      expect(r.kind, RecipientKind.epic1);
      expect(r.address, address);
      expect(epic1Shaped(input), isTrue);
    });
  }

  test('address-only is kept through the prefix', () {
    expect(epic1AddressOnly('https://$_bare'), isTrue);
    expect(epic1AddressOnly('https://$_bare/'), isTrue);
    expect(epic1AddressOnly('https://epic:$_bare'), isTrue);
    expect(epic1AddressOnly('https://$_link'), isFalse);
  });

  for (final url in [
    'https://epic1.example.com',
    'https://epic1.example.com:3415/',
    'http://epic1abc.onion', // an onion stays Tor as before
    'https://$_bare.example.com',
    'https://$_bare:3415',
    'https://$_bare/v2/foreign',
    'https://tepic1.example.com',
  ]) {
    test('"$url" is not an epic1 link', () {
      expect(epic1Unwrap(url), url);
      expect(epic1Shaped(url), isFalse);
      expect(parseRecipient(url).kind, isNot(RecipientKind.epic1));
    });
  }

  test('a host stays HTTP', () {
    final r = parseRecipient('https://epic1.example.com:3415/');
    expect(r.kind, RecipientKind.http);
    expect(r.address, 'https://epic1.example.com:3415/');
  });
}
