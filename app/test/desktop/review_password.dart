// Review › Send asks the wallet's password on every send; the send tests fill it in.
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Types [password] into the review's Password field (the mock takes any but "wrong").
Future<void> enterReviewPassword(WidgetTester tester, [String password = 'secret-pass']) async {
  await tester.enterText(find.descendant(of: find.widgetWithText(EField, 'Password'), matching: find.byType(TextField)), password);
  await tester.pump();
}
