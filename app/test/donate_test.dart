// SPDX-License-Identifier: Apache-2.0
// Donate (item 4): the page and contact page come from settings.toml, the address from
// app-config.toml; the page is asked before it opens, never in Node only or Kill switch.
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/donate.dart';
import 'package:epic_wallet/src/net/http_types.dart' show NetError;
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

void main() {
  tearDown(() => NetGate.set(null));
  const wait = Duration(seconds: 1);
  final link = DonateLink(page: Uri.parse('https://donate.lab.invalid/'), contact: Uri.parse('https://contact.lab.invalid/'), address: 'es1@relay.lab.invalid');

  test('the settings files give the page, the contact page and the address', () {
    final l = DonateLink.of(testSettings());
    expect(l.page, Uri.parse('https://donate.lab.invalid/'));
    expect(l.contact, Uri.parse('https://contact.lab.invalid/'));
    expect(l.address, testSettings().supportDonation);
    expect(l.any, isTrue);
    final none = DonateLink.of(testSettings().withValues({'donate.page': '', 'donate.contact': ''}));
    expect(none.page, isNull);
    expect(none.contact, isNull);
  });

  test('answers on 2xx and 3xx; no answer on an error status, a network error or a timeout', () async {
    expect(await checkDonatePage(link, timeout: wait, get: (_, _) async => 200), DonateCheck.answers);
    expect(await checkDonatePage(link, timeout: wait, get: (_, _) async => 301), DonateCheck.answers);
    expect(await checkDonatePage(link, timeout: wait, get: (_, _) async => 404), DonateCheck.noAnswer);
    expect(await checkDonatePage(link, timeout: wait, get: (_, _) async => throw const NetError('refused')), DonateCheck.noAnswer);
  });

  test('no page set: none, nothing asked', () async {
    var asked = false;
    final r = await checkDonatePage(DonateLink(address: link.address), timeout: wait, get: (_, _) async {
      asked = true;
      return 200;
    });
    expect(r, DonateCheck.none);
    expect(asked, isFalse);
  });

  for (final mode in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
    test('${mode.name}: skipped, nothing asked', () async {
      NetGate.set(mode);
      var asked = false;
      final r = await checkDonatePage(link, timeout: wait, get: (_, _) async {
        asked = true;
        return 200;
      });
      expect(r, DonateCheck.skipped);
      expect(asked, isFalse);
    });
  }
}
