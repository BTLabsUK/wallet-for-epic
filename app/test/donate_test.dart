// SPDX-License-Identifier: Apache-2.0
// Donate (item 4): the address comes from app-config.toml, BT Labs' contact is the one in
// Contacts holding it; an old [donate] table in settings.toml is left alone.
import 'package:epic_wallet/src/donate.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

void main() {
  test('the settings files give the address', () {
    final l = DonateLink.of(testSettings());
    expect(l.address, testSettings().supportDonation);
    expect(l.any, isTrue);
    expect(const DonateLink().any, isFalse);
  });

  test("BT Labs' contact: the one holding the address; none when no contact holds it", () {
    final contacts = [('a', 'es1@x.invalid'), ('b', 'es2@x.invalid'), ('c', null)];
    String? box((String, String?) c) => c.$2;
    expect(donateContactIn(contacts, 'es2@x.invalid', box)?.$1, 'b');
    expect(donateContactIn(contacts, 'es9@x.invalid', box), isNull);
    expect(donateContactIn(contacts, null, box), isNull);
    expect(donateContactIn(const <(String, String?)>[], 'es1@x.invalid', box), isNull);
  });

  test('a [donate] table from an earlier build is not reported as unknown', () {
    final read = readSettings('[donate]\npage = "https://donate.lab.invalid/"\ncontact = "https://contact.lab.invalid/"\n', shipped: testSettings());
    expect(read.unknown, isEmpty);
    expect(read.issues, isEmpty);
  });
}
