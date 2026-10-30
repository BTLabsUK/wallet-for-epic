// SPDX-License-Identifier: Apache-2.0
// Plain HTTP to another device: the contact's safer address is offered first, and a send to a
// contact whose onion is known asks the receiver for a payment proof.

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

  group('saferRouteFor', () {
    test('Epicbox first, then the onion, then the same wallet over https', () {
      final all = Contact(id: '1', name: 'A', http: 'http://10.0.0.5:3415', tor: _onion, epicbox: _epicbox);
      final onion = Contact(id: '2', name: 'B', http: 'http://10.0.0.6:3415', tor: _onion);
      final tls = Contact(id: '3', name: 'C', http: 'https://wallet.example:3415');
      final contacts = [all.ways, onion.ways, tls.ways];

      final a = saferRouteFor('http://10.0.0.5:3415', contacts)!;
      expect((a.name, a.recipient.kind, a.recipient.address), ('A', RecipientKind.epicbox, _epicbox));
      final b = saferRouteFor('http://10.0.0.6:3415/', contacts)!;
      expect((b.name, b.recipient.kind, b.recipient.address), ('B', RecipientKind.tor, _onion));
      final c = saferRouteFor('http://WALLET.example:3415', contacts)!;
      expect((c.name, c.recipient.kind, c.recipient.address), ('C', RecipientKind.http, 'https://wallet.example:3415'));
    });

    test('none for https, this device, an unknown wallet or a contact with plain http only', () {
      final plain = Contact(id: '1', name: 'A', http: 'http://10.0.0.5:3415');
      expect(saferRouteFor('http://10.0.0.5:3415', [plain.ways]), isNull);
      expect(saferRouteFor('http://10.0.0.9:3415', [plain.ways]), isNull);
      expect(saferRouteFor('https://10.0.0.5:3415', [plain.ways]), isNull);
      expect(saferRouteFor('http://127.0.0.1:3415', [Contact(id: '2', name: 'L', http: 'http://127.0.0.1:3415', tor: _onion).ways]), isNull);
    });
  });
}
