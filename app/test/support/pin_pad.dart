// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/ui/kit/kit_keypad.dart';
import 'package:epic_wallet/src/ui/kit/kit_icons.dart';
import 'package:epic_wallet/src/ui/pin.dart' show PinPad;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wallet's own PIN keypad (unlock, PIN setup, restore's PIN step).
/// Where a page has a keypad of its own (the Send amount), the PIN's is the one in its [PinPad].
Finder get pinPad => find.byType(PinPad).evaluate().isNotEmpty
    ? find.descendant(of: find.byType(PinPad), matching: find.byType(KitKeypad))
    : find.byType(KitKeypad);

/// Types [pin] on the keypad, one key at a time; the PIN completes on its last digit. Does not
/// settle: callers pump as their screen needs.
Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.descendant(of: pinPad, matching: find.text(d)));
    await tester.pump();
  }
}

/// The fingerprint key of the keypad.
Finder get pinBiometricsKey => find.descendant(of: pinPad, matching: find.byIcon(KitIcons.fingerprint));

/// Answers a PIN asked on the keypad, or in the field when a passphrase is asked.
Future<void> enterPin(WidgetTester tester, String pin) async {
  if (pinPad.evaluate().isNotEmpty) {
    await typePin(tester, pin);
  } else {
    await tester.enterText(find.byType(TextField).last, pin);
  }
}
