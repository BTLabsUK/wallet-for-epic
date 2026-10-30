// SPDX-License-Identifier: Apache-2.0
// A send to a contact whose onion is known asks the receiver for a payment proof.

import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:flutter_test/flutter_test.dart';

// The onion of the ed25519 key 00 01 02 … 1f, with its checksum and version.
const String _onion = 'aaaqeayeaudaocajbifqydiob4ibceqtcqkrmfyydenbwha5dyp3kead.onion';
const String _key = '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
final String _epicbox = '${'b' * 52}@epicbox.epiccash.com';

void main() {
  group('proofAddressOfOnion', () {
    test('is the onion\'s public key in hex, in any of its forms', () {
      for (final form in [_onion, _onion.substring(0, 56), 'http://$_onion:3415/', _onion.toUpperCase()]) {
        expect(proofAddressOfOnion(form), _key, reason: form);
      }
    });

    test('is null for anything that is not an onion', () {
      expect(proofAddressOfOnion('http://10.0.0.5:3415'), isNull);
      expect(proofAddressOfOnion(_epicbox), isNull);
      expect(proofAddressOfOnion(''), isNull);
    });
  });

  group('proofAddressFor', () {
    final bob = Contact(id: '1', name: 'Bob', http: 'http://10.0.0.5:3415', tor: _onion);

    test('an onion, and a wallet URL whose contact has one', () {
      expect(proofAddressFor(const Recipient(RecipientKind.tor, _onion), const []), _key);
      expect(proofAddressFor(const Recipient(RecipientKind.http, 'HTTP://10.0.0.5:3415/'), [bob.ways]), _key);
      expect(proofAddressFor(const Recipient(RecipientKind.http, 'https://10.0.0.5:3415'), [bob.ways]), _key);
    });

    test('none for an unknown wallet URL or Epicbox', () {
      expect(proofAddressFor(const Recipient(RecipientKind.http, 'http://10.0.0.6:3415'), [bob.ways]), isNull);
      expect(proofAddressFor(Recipient(RecipientKind.epicbox, _epicbox), [bob.ways]), isNull);
    });
  });
}
