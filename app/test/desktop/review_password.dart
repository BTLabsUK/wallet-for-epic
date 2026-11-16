// SPDX-License-Identifier: Apache-2.0
// Review › Send asks the wallet's password on every send; the send tests fill it in, and pump
// past the send.
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Types [password] into the review's Password field (the mock takes any but "wrong").
Future<void> enterReviewPassword(WidgetTester tester, [String password = 'secret-pass']) async {
  await tester.enterText(find.descendant(of: find.widgetWithText(EField, 'Password'), matching: find.byType(TextField)), password);
  await tester.pump();
}

/// Pumps a second of frames after the review's Send was pressed. Bounded: the Payment sent modal
/// that follows a send shows a spinner, which never settles.
Future<void> pumpSent(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
