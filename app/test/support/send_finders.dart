// SPDX-License-Identifier: Apache-2.0
// Finders for the Send flow's controls by key, whatever the page around them looks like.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
import 'package:epic_wallet/src/ui/kit/kit_sheet.dart' show KitSheet;
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The address field of the Who step.
Finder sendTo() => find.byKey(sendRecipientFieldKey);

/// The amount field of the amount page, or of the file route's (the keypad writes into it).
Finder sendAmount() => find.byWidgetPredicate((w) => w.key == sendFileAmountFieldKey || w.key == sendAmountFieldKey);

/// The step's forward button: Review on the amount page, Continue on the others.
Finder continueButton() => find.byKey(sendReviewButtonKey).evaluate().isNotEmpty
    ? find.byKey(sendReviewButtonKey)
    : find.widgetWithText(FilledButton, englishStrings.commonContinue);

/// The text field a test names by its old label: the address and amount fields by key, any other
/// by its label.
Finder sendField(String label) {
  if (label == 'To' || label == englishStrings.sendToLabel) return sendTo();
  if (label.startsWith('Amount (')) return sendAmount();
  return find.widgetWithText(TextField, label);
}

/// Chooses Pay with a file (or Pay in person with [qr]). Where the recipient step still shows
/// the old text button (a held route) it taps that; otherwise it opens "No address?" and taps
/// the row in the sheet.
Future<void> chooseWay(WidgetTester tester, {bool qr = false}) async {
  final old = find.text(qr ? englishStrings.sendPayInPerson : englishStrings.sendPayByFile);
  final entry0 = find.text(englishStrings.sendNoAddress);
  // The list builds lazily: scroll down until the way or the "No address?" row is built.
  for (var i = 0; i < 6 && old.evaluate().isEmpty && entry0.evaluate().isEmpty && verticalScrollable().evaluate().isNotEmpty; i++) {
    await tester.drag(verticalScrollable(), const Offset(0, -300), warnIfMissed: false);
    await tester.pump();
  }
  if (old.evaluate().isEmpty) {
    final entry = find.text(englishStrings.sendNoAddress);
    if (entry.evaluate().isEmpty) {
      final shown = [for (final w in tester.widgetList<Text>(find.byType(Text))) w.data ?? w.textSpan?.toPlainText() ?? ''];
      throw TestFailure('chooseWay: no way offered here. On screen: $shown');
    }
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final row = find.text(qr ? englishStrings.phoneSendInPerson : englishStrings.phoneSendWithFile);
    // At a large text size the sheet scrolls.
    await tester.ensureVisible(row);
    await tester.pump();
    await tester.tap(row);
  } else {
    await tester.ensureVisible(old);
    await tester.pump();
    // The action bar sits over the foot of the list: lift the button clear of it.
    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final gap = tester.getCenter(old).dy - (screen - 180);
    if (gap > 0 && verticalScrollable().evaluate().isNotEmpty) {
      await tester.drag(verticalScrollable(), Offset(0, -gap), warnIfMissed: false);
      await tester.pump();
    }
    await tester.tap(old);
  }
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// The page's vertical scroller (the faces strip and the like scroll sideways).
Finder verticalScrollable() => find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical).last;

/// Back to the top of the page (the list builds lazily; a strip at the top is not built
/// while the page is scrolled down).
Future<void> scrollToTop(WidgetTester tester) async {
  if (verticalScrollable().evaluate().isEmpty) return;
  await tester.drag(verticalScrollable(), const Offset(0, 2000), warnIfMissed: false);
  await tester.pump();
}

/// Scrolls the page until [finder] is built, when it is not yet.
Future<void> buildInPage(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) return;
  if (verticalScrollable().evaluate().isEmpty) return;
  await tester.scrollUntilVisible(finder, 200, scrollable: verticalScrollable());
}

/// The unit swap under the amount figure.
Finder sendSwapButton() => find.byTooltip(englishStrings.phoneKitSwapCurrency);

/// The Max button of the Available bar.
Finder sendMaxButton() => find.text(englishStrings.sendMax);

/// The network fee as the amount page shows it (in the "Leaves … after the … fee" line, the
/// figure without its unit).
Finder feeShown(String fee) => find.textContaining('after the $fee fee', findRichText: true);

/// The forward button's onPressed (null while the page is not ready), whichever widget it is.
VoidCallback? continueOnPressed(WidgetTester tester) {
  final w = tester.widget(continueButton());
  return switch (w) {
    KitButton() => w.onPressed,
    FilledButton() => w.onPressed,
    _ => throw StateError('not a button: $w'),
  };
}

/// Picks a saved contact on the recipient step: types the name, then taps its row in the
/// Contacts group. Unlike a face, the row fills the address and stays on the step.
Future<void> pickContact(WidgetTester tester, String name) async {
  await tester.enterText(sendTo(), name);
  await tester.pump();
  final row = find.descendant(of: find.byType(InkWell), matching: find.text(name)).last;
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Leaves the Review sheet for the amount page: a tap on the dim above it.
Future<void> leaveReview(WidgetTester tester) async {
  // A toast floats over the top edge and takes the touch; let it leave first.
  await tester.pump(noticeDuration(NoticeLevel.success));
  await tester.pumpAndSettle();
  // In the strip of dim above the sheet (the screen must have no app bar over it).
  final sheetTop = tester.getTopLeft(find.byType(KitSheet)).dy;
  await tester.tapAt(Offset(10, sheetTop / 2));
  await tester.pumpAndSettle();
}


