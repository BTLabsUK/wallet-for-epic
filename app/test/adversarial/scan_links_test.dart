// SPDX-License-Identifier: Apache-2.0
// Hostile scans, pastes and links: what a QR code, a shared message or another app's link can
// and cannot make the wallet do. Each case is a text a bad actor controls; the router must read
// it as something harmless or refuse it.

import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/scan/incoming_link.dart';
import 'package:epic_wallet/src/scan/scan_router.dart';
import 'package:epic_wallet/src/scan/scan_text.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';
const _e = '$_key@epicbox.epiccash.com';

AddressVerdict _check(Recipient to) => switch (to.kind) {
  RecipientKind.epicbox => fakeEpicboxAddress(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
  RecipientKind.tor => onionAddressFormat(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
  RecipientKind.http => httpAddressComplete(to.address) ? AddressVerdict.valid : AddressVerdict.invalid,
};

ScannedCode _scan(String text) => classifyScan(text, check: _check);

/// One character by code point, so no invisible character sits in this file.
String _c(int codePoint) => String.fromCharCode(codePoint);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('amounts in a payment code', () {
    // Each one is an amount some parser somewhere reads as a number; the code must carry none.
    final odd = <String>[
      '1e3', '1E3', '1e-8', '0x10', '0b1', '0o7', 'Infinity', '-Infinity', 'NaN', '-1', '+1',
      '1_000', '1 000', '1,000', '1.000,5', '１', '١', '٣.٥', '۱', '१', '1.5.5', '.5', '5.',
      '00.5', '01', '1/2', '½', '1%', '1e', 'e1', '1..2', '1.0e2', '  1', '1 ',
      '9' * 65, '0.000000001',
    ];
    for (final amount in odd) {
      test('refuses_a_code_amount_${amount.codeUnits.join('_')}', () {
        final code = _scan('epic:$_e?amount=${encodeUriValue(amount)}');
        expect(code, isA<PaymentRequest>(), reason: 'the address alone still fills Send');
        final pay = code as PaymentRequest;
        expect(pay.amount, isNull, reason: 'amount "$amount" must never prefill Send');
        expect(pay.problems, isNotEmpty, reason: 'the user is told the amount was dropped');
      });
    }

    test('reads_an_encoded_amount_once_and_strictly', () {
      // %31%65%33 is "1e3" after one decode: still refused.
      expect((_scan('epic:$_e?amount=%31%65%33') as PaymentRequest).amount, isNull);
      // A NUL after the digits is not a shorter amount.
      expect((_scan('epic:$_e?amount=1%00') as PaymentRequest).amount, isNull);
      // %2531 is "%31" after one decode, not "1".
      expect((_scan('epic:$_e?amount=%2531') as PaymentRequest).amount, isNull);
    });

    test('never_prefills_more_than_the_supply_ceiling', () {
      final pay = _scan('epic:$_e?amount=${maxUriAmountEpic + 1}') as PaymentRequest;
      expect(pay.amount, isNull);
      expect(pay.problems, contains(RequestProblem.amountTooLarge));
      final top = _scan('epic:$_e?amount=$maxUriAmountEpic.00000001') as PaymentRequest;
      expect(top.amount, isNull);
    });

    test('a_second_amount_in_any_case_refuses_the_whole_code', () {
      for (final q in ['amount=1&AMOUNT=1000', 'Amount=1&amount=1000', 'amount=1&amount=1']) {
        expect(_scan('epic:$_e?$q'), isA<UnknownCode>(), reason: q);
      }
    });

    test('an_amount_after_the_fragment_is_not_read', () {
      final pay = _scan('epic:$_e?amount=1#&amount=1000') as PaymentRequest;
      expect(pay.amount, atomicPerEpic);
    });
  });

  group('typed amounts', () {
    for (final bad in ['1e3', '-1', '+1', '１', '١', 'NaN', '0x10', '1 000', '1.2.3', '1.000000001']) {
      test('refuses_a_typed_amount_${bad.codeUnits.join('_')}', () {
        expect(() => parseEpic(bad), throwsFormatException);
      });
    }
  });

  group('addresses', () {
    test('refuses_an_address_with_invisible_or_lookalike_characters', () {
      final sneaky = <String>[
        '${_key.substring(0, 10)}${_c(0x200B)}${_key.substring(10)}@epicbox.epiccash.com',
        '$_key@epicbox.epiccash.com${_c(0x202E)}',
        '$_key@epicbox.epic${_c(0x0441)}ash.com', // Cyrillic с
        '${_key.replaceFirst('W', _c(0xFF37))}@epicbox.epiccash.com', // full-width W
      ];
      for (final s in sneaky) {
        expect(_scan(s), isNot(isA<ScannedAddress>()), reason: s.runes.toList().toString());
        expect(_scan('epic:$s'), isNot(isA<PaymentRequest>()), reason: s.runes.toList().toString());
      }
    });

    test('a_direct_address_cannot_hide_its_host', () {
      for (final d in [
        'http://epicbox.epiccash.com@1.2.3.4:3415',
        'http://1.2.3.4:3415#@epicbox.epiccash.com',
        'http://1.2.3.4:3415?@epicbox.epiccash.com',
        'http://[::ffff:1.2.3.4]:3415',
        'http://1.2.3.4:',
        'http://1.2.3.4:0',
        'http://1.2.3.4:65536',
      ]) {
        expect(_scan(d), isA<UnknownCode>(), reason: d);
        final pay = _scan('epic:$_e?method=direct&direct=${encodeUriValue(d)}') as PaymentRequest;
        expect(pay.direct, isNull, reason: d);
      }
    });

    test('a_long_label_never_stands_in_for_the_address', () {
      // The label is the payee's own claim; it is cleaned, capped and never an address.
      final pay = _scan('epic:$_e?label=${encodeUriValue('Pay ${'esX' * 30}@epicbox.btlabs.uk')}') as PaymentRequest;
      expect(pay.recipient.address, _e);
      expect(pay.label, isNull, reason: 'over the label cap, dropped');
    });
  });

  group('scheme confusion', () {
    test('a_payment_code_whose_note_holds_a_pairing_link_stays_a_payment', () {
      // A payee's note is untrusted text: it must not turn a payment QR into a pairing invite.
      final code = _scan('epic:$_e?amount=1&message=hi+epiccash://pair/1/AbCdEfGh123');
      expect(code, isA<PaymentRequest>());
      expect((code as PaymentRequest).amount, atomicPerEpic);
    });

    test('a_payment_code_with_a_slate_marker_in_its_note_stays_a_payment', () {
      final code = _scan('epic:$_e?message=%7B%22ver%22%3A1%7D');
      expect(code, isA<PaymentRequest>());
    });

    test('other_schemes_wrapping_an_epic_code_are_not_payments', () {
      for (final t in [
        'intent:$_e#Intent;scheme=epic;end',
        'https://example.com/?u=epic:$_e',
        'file:///sdcard/epic:$_e',
        'javascript:epic:$_e',
        'epic:javascript:alert(1)',
        'epic:file:///etc/passwd',
        'epic:http://user@1.2.3.4:3415',
      ]) {
        expect(_scan(t), isNot(isA<PaymentRequest>()), reason: t);
      }
    });

    test('the_preview_of_an_unknown_code_cannot_reverse_on_screen', () {
      final shown = scanPreview('abc${_c(0x202E)}gnp.exe${_c(0x2066)}x${_c(0x200F)}');
      expect(shown, 'abcgnp.exex');
      expect(scanPreview('x' * 10000).runes.length, scanPreviewLength + 1);
    });

    test('a_huge_or_binary_text_is_refused_without_throwing', () {
      expect(_scan('epic:$_e?message=${'%F0%9F%98%80' * 20000}'), isA<UnknownCode>());
      expect(_scan(String.fromCharCodes(List.generate(5000, (i) => i % 0xD800))), isA<UnknownCode>());
      expect(_scan('epic:$_e?${List.filled(2000, 'a=1').join('&')}'), isA<UnknownCode>(), reason: 'past the longest text read');
    });
  });

  group('links from other apps', () {
    late ProviderContainer c;
    late DateTime now;
    setUp(() {
      now = DateTime.utc(2026, 10, 28, 12);
      c = ProviderContainer(overrides: [linkClockProvider.overrideWithValue(() => now)]);
    });
    tearDown(() => c.dispose());

    IncomingLinkNotifier n() => c.read(incomingLinkProvider.notifier);

    test('a_link_arriving_during_a_confirmation_never_replaces_what_is_confirmed', () {
      n().deliver('epic:$_e?amount=1');
      expect(c.read(incomingLinkProvider)!.text, 'epic:$_e?amount=1');
      c.read(linkBusyProvider.notifier).set(true);
      now = now.add(const Duration(seconds: 5));
      n().deliver('epic:$_e?amount=1000');
      // The held link is the one the user saw first; the late one is dropped and counted.
      expect(c.read(incomingLinkProvider)!.text, 'epic:$_e?amount=1');
      expect(c.read(linkDroppedBusyProvider), 1);
    });

    test('a_flood_of_links_holds_at_most_three_per_half_minute', () {
      var accepted = 0;
      String? last;
      for (var i = 0; i < 50; i++) {
        now = now.add(const Duration(milliseconds: 2100));
        n().deliver('epic:$_e?amount=$i');
        final held = c.read(incomingLinkProvider)?.text;
        if (held != last) accepted++;
        last = held;
      }
      // 50 links over 105 s: at most 3 in any 30 s window.
      expect(accepted, lessThanOrEqualTo(12));
    });

    test('a_stale_link_is_never_routed_after_unlock', () {
      n().deliver('epic:$_e?amount=5');
      now = now.add(linkMaxAge + const Duration(seconds: 1));
      expect(n().take(), isNull);
    });
  });
}
