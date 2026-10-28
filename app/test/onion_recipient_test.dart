// An onion address in every form a user meets: bare, with `.onion`, with `http://`, a
// port, a trailing slash, upper case, stray whitespace. All of them become one recipient over
// Tor, shown as `<56 characters>.onion`; epicbox addresses and wallet URLs are untouched.

import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const String _name = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';
const String _onion = '$_name.onion';
final String _bob = '${'b' * 52}@epicbox.epiccash.com';

void main() {
  final l = englishStrings;
  final service = FakeWalletService();

  group('parseRecipient', () {
    for (final form in [
      _name,
      _onion,
      'http://$_onion',
      'http://$_onion/',
      'http://$_name',
      '$_onion:3415',
      'http://$_onion:3415/v2/foreign',
      _onion.toUpperCase(),
      'HTTP://${_onion.toUpperCase()}/',
      '  $_onion \n',
      'wfe7q3k2 mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion',
    ]) {
      test('"$form" is the Tor address $_onion', () {
        final to = parseRecipient(form);
        expect(to.kind, RecipientKind.tor);
        expect(to.address, _onion);
        expect(checkRecipient(l, service, form), isNull);
        expect(checkContactAddress(l, service, form), isNull);
      });
    }

    test('epicbox addresses and wallet URLs keep their kinds', () {
      expect(parseRecipient(_bob).kind, RecipientKind.epicbox);
      expect(parseRecipient('epicbox://$_bob').address, _bob);
      expect(
        parseRecipient('https://wallet.example:3415').kind,
        RecipientKind.http,
      );
      // An `https` onion is not a form LEPIC takes: a URL, refused as before.
      expect(parseRecipient('https://$_onion').kind, RecipientKind.http);
    });

    test('a cut onion is not a Tor address', () {
      final cut = parseRecipient(_name.substring(1));
      expect(cut.kind, RecipientKind.epicbox);
      expect(checkRecipient(l, service, _name.substring(1)), isNotNull);
    });
  });

  test('checkRecipient says what is wrong with an onion LEPIC refuses', () {
    final picky = _ChecksumService();
    expect(checkRecipient(l, picky, _onion), l.sendOnionIncomplete);
    expect(checkContactAddress(l, picky, _onion), l.sendOnionIncomplete);
  });

  test('shortAddress keeps the ends and the suffix of an onion', () {
    expect(shortAddress(_onion), 'wfe7q3…abcdid.onion');
    expect(shortAddress(_bob), 'bbbbbb…bbbbbb@epicbox.epiccash.com');
  });
}

/// A wallet whose onion checksum check fails every address.
class _ChecksumService extends FakeWalletService {
  @override
  bool validateOnionAddress({required String address}) => false;
}
