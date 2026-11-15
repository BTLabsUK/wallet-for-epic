// SPDX-License-Identifier: Apache-2.0
// Home's field, read: one test per row of the case table (home_field_cases.dart). The scan
// router and Send's recipient reader are the app's own; only the address checks are the fakes.
import 'package:epic_wallet/src/desktop/screens/wallet/home_field_parse.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/scan/scan_router.dart';
import 'package:epic_wallet/src/send_route.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home_field_cases.dart';

AddressVerdict _check(Recipient to) => switch (to.kind) {
  RecipientKind.epic1 => AddressVerdict.invalid,
  RecipientKind.epicbox => fakeEpicboxAddress(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
  RecipientKind.tor => onionAddressFormat(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
  RecipientKind.http => httpAddressComplete(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
};

HomeRead _read(String typed) => readHomeField(
  typed,
  people: [for (final c in hfContacts()) HomePerson.contact(c), for (final a in hfPastRecipients) HomePerson.past(a)],
  classify: (t) => classifyScan(t, check: _check),
  read: (t) => readRecipient(t, defaultRelay: 'epicbox.example.org', listenPort: 3415),
);

void main() {
  test('the table has 50 rows or more, with unique ids', () {
    expect(homeCases.length, greaterThanOrEqualTo(50));
    expect({for (final c in homeCases) c.id}.length, homeCases.length);
  });

  for (final c in homeCases) {
    test('${c.id} "${c.typed}" → ${c.shows}', () {
      final r = _read(c.typed);
      expect(r.kind, c.kind, reason: '$r');
      expect(r.verb, c.verb, reason: '$r');
      if (c.kind == HomeKind.person) {
        expect(r.first?.id, c.to, reason: '$r');
        if (c.list != null) expect([for (final p in r.matches) p.id], c.list, reason: '$r');
      }
      if (c.kind == HomeKind.address) {
        expect(r.address, c.to, reason: '$r');
        expect(r.recipient?.kind, c.recipient, reason: '$r');
      }
      if (c.kind == HomeKind.code) expect(r.code, c.typed.trim(), reason: '$r');
      if (c.max) {
        expect(r.amount?.max, isTrue, reason: '$r');
      } else if (c.amount != null) {
        expect(r.amount, HomeAmount(c.amount!), reason: '$r');
      } else if (c.kind != HomeKind.none && c.kind != HomeKind.blank) {
        expect(r.amount, isNull, reason: '$r');
      }
      expect(r.message, c.message, reason: '$r');
      if (c.kind == HomeKind.none && c.typed.trim().isNotEmpty) {
        // A recovery phrase is never carried on, so never shown.
        expect(r.query, c.id == 'C04' ? '' : c.typed.trim(), reason: '$r');
      }
    });
  }
}
