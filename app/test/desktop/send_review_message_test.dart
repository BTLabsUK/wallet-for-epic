// SPDX-License-Identifier: Apache-2.0
// A report: the review showed no trace of the message typed on Send, so the sender could not
// tell whether it would go with the payment. The review dialog lists it as typed, none when
// empty, and Send hands it to the wallet, where the transaction keeps it.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_password.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final sent = <SendRequest>[];

  @override
  Future<SendResult> send(SendRequest r) {
    sent.add(r);
    return super.send(r);
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(
      overrides: [deskApiProvider.overrideWithValue(wallet)],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, SendArgs args) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(
      () => container.read(deskProvider.notifier).refresh(),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(body: SendScreen(arg: args)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const anna =
      'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
  final dialog = find.byType(EDialog);

  testWidgets('the review shows the message as typed, wrapped whole', (
    tester,
  ) async {
    final long = List.filled(8, 'Rent for the flat in March').join(' ');
    await pump(
      tester,
      SendArgs(
        recipient: anna,
        amount: '25',
        message: ' $long ',
        step: SendStep.review,
      ),
    );
    expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Message')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text(long)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a message the review has no Message row', (
    tester,
  ) async {
    await pump(
      tester,
      const SendArgs(recipient: anna, amount: '25', step: SendStep.review),
    );
    expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Message')),
      findsNothing,
    );
  });

  testWidgets(
    'Send hands the message to the wallet, and the transaction keeps it',
    (tester) async {
      await pump(
        tester,
        const SendArgs(
          recipient: anna,
          amount: '25',
          message: 'For rent',
          step: SendStep.review,
        ),
      );
      await enterReviewPassword(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is EButton && w.label.startsWith('Send 25'),
        ),
      );
      await tester.pumpAndSettle();
      expect(wallet.sent.single.message, 'For rent');
      final txs = await tester.runAsync(() => wallet.transactions());
      expect(txs!.where((t) => t.message == 'For rent'), hasLength(1));
    },
  );

  test('Send, its review and the details name the message alike in every language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = lookupAppLocalizations(locale);
      expect(l.deskSendFactMessage, l.deskSendMessage, reason: '$locale');
      expect(l.deskTxFactMessage, l.deskSendMessage, reason: '$locale');
      expect(l.deskTxDetailsNote, isNot(l.deskSendMessage), reason: '$locale');
    }
  });

  testWidgets('the review and the details: one Message; the note is the private one', (tester) async {
    await pump(tester, const SendArgs(recipient: anna, amount: '25', message: 'For rent', step: SendStep.review));
    expect(find.descendant(of: dialog, matching: find.text('Message')), findsOneWidget);

    Tx tx({required bool incoming, bool bySender = true}) => Tx(
      id: 7,
      slateId: 'rent',
      direction: incoming ? TxDirection.received : TxDirection.sent,
      state: TxState.confirmed,
      method: TxMethod.epicbox,
      amount: 25 * nanoPerEpic,
      fee: 0,
      created: DateTime(2026, 10, 28, 9),
      confirmations: 900,
      counterparty: anna,
      message: 'For rent',
      messageBySender: bySender,
      note: 'Flat, March',
    );
    Future<void> details(Tx t) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SingleChildScrollView(child: TxDetail(tx: t)))),
      ));
      await tester.pump();
    }

    await details(tx(incoming: false));
    final message = find.byKey(const ValueKey('tx-message'));
    expect(find.text('Message'), findsOneWidget);
    expect(find.descendant(of: message, matching: find.text('For rent')), findsOneWidget);
    expect(find.descendant(of: message, matching: find.text('Sent to the recipient')), findsOneWidget);
    final note = find.byKey(const ValueKey('tx-private-note'));
    expect(find.text('Private note'), findsOneWidget);
    expect(find.descendant(of: note, matching: find.text('Flat, March')), findsOneWidget);
    expect(find.descendant(of: note, matching: find.text('Only in this app and in the exported wallet data.')), findsOneWidget);
    expect(find.text('Your message'), findsNothing);

    await details(tx(incoming: true));
    expect(find.text('From the sender'), findsOneWidget);
    // An invoice: the receiver wrote it.
    await details(tx(incoming: false, bySender: false));
    expect(find.text('From the recipient'), findsOneWidget);
  });
}
