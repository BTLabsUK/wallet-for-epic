import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _mainnetDir = '/fake/wallets/mainnet';
const _password = 'correct horse';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

Future<void> _pumpApp(WidgetTester tester, FakeWalletService service) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(service),
        walletDirProvider.overrideWithValue(
          (chain) async => '/fake/wallets/${chain.name}',
        ),
      ],
      child: const WalletApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the current screen's list until [finder] is built, then into view.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text));

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _reveal(tester, field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Continue from setup with an existing mainnet wallet and unlock it.
Future<void> _unlockToHome(WidgetTester tester) async {
  await _tapText(tester, 'Continue');
  await _enter(tester, 'Password', _password);
  await _tapText(tester, 'Unlock');
}

FakeWalletSession _fundedSession() => FakeWalletSession(
  summary: WalletSummary(
    lastConfirmedHeight: BigInt.from(2499990),
    minimumConfirmations: BigInt.from(10),
    total: _epic(16),
    spendable: _epic(12.5),
    awaitingConfirmation: _epic(1),
    awaitingFinalization: BigInt.zero,
    immature: _epic(0.5),
    locked: _epic(2),
    validatedWithNode: false,
  ),
  transactions: [
    TxEntry(
      id: 2,
      slateId: 'b',
      kind: TxKind.sent,
      createdAtUnix: 1790000100,
      confirmed: false,
      amountCredited: _epic(3.992),
      amountDebited: _epic(5),
      fee: _epic(0.008),
      numInputs: 1,
      numOutputs: 1,
    ),
    TxEntry(
      id: 1,
      slateId: 'a',
      kind: TxKind.received,
      createdAtUnix: 1790000000,
      confirmed: true,
      amountCredited: _epic(5),
      amountDebited: BigInt.zero,
      numInputs: 0,
      numOutputs: 1,
    ),
  ],
);

void main() {
  testWidgets('setup, create, confirm words, set password, reach home', (
    tester,
  ) async {
    final service = FakeWalletService();
    await _pumpApp(tester, service);

    expect(find.text('Mainnet'), findsOneWidget);
    expect(find.text('Usernet'), findsOneWidget);
    await _tapText(tester, 'Usernet');
    final urlField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Node URL'),
    );
    expect(urlField.controller!.text, 'http://127.0.0.1:23413');

    await _tapText(tester, 'Continue');
    expect(
      find.text('There is no wallet on Usernet on this device yet.'),
      findsOneWidget,
    );
    await _tapText(tester, 'Create a new wallet');

    final words = service.phrase.split(' ');
    expect(find.textContaining('shown only once'), findsOneWidget);
    expect(find.text('1. ${words.first}'), findsOneWidget);
    expect(find.byTooltip('Copy'), findsNothing);
    await _tapText(tester, 'I have written them down');

    // A wrong word is rejected.
    final fields = <int>[
      for (var i = 0; i < words.length; i++)
        if (find.byKey(ValueKey('confirm-word-$i')).evaluate().isNotEmpty) i,
    ];
    expect(fields, hasLength(3));
    for (final i in fields) {
      await tester.enterText(find.byKey(ValueKey('confirm-word-$i')), 'wrong');
    }
    await _tapText(tester, 'Confirm');
    expect(find.textContaining('do not match'), findsOneWidget);

    for (final i in fields) {
      await tester.enterText(find.byKey(ValueKey('confirm-word-$i')), words[i]);
    }
    await _tapText(tester, 'Confirm');

    await _enter(tester, 'Password', 'new password');
    await _enter(tester, 'Repeat password', 'different');
    await _tap(tester, find.widgetWithText(FilledButton, 'Create wallet'));
    expect(find.text('The passwords do not match.'), findsOneWidget);

    await _enter(tester, 'Repeat password', 'new password');
    await _tap(tester, find.widgetWithText(FilledButton, 'Create wallet'));

    expect(service.createdConfig?.chain, Chain.usernet);
    expect(service.createdConfig?.dataDir, '/fake/wallets/usernet');
    expect(service.createdConfig?.nodeUrl, 'http://127.0.0.1:23413');
    expect(service.createdConfig?.epicboxPort, 3423);
    expect(service.createdMnemonic == service.phrase, isTrue);
    expect(find.text('Spendable'), findsOneWidget);
    expect(find.text('No transactions yet.'), findsOneWidget);
  });

  testWidgets('restore validates the phrase and scans', (tester) async {
    final service = FakeWalletService();
    await _pumpApp(tester, service);
    await _tapText(tester, 'Continue');
    await _tapText(tester, 'Restore from recovery phrase');

    await _enter(tester, 'Recovery phrase', 'not a valid phrase');
    await _enter(tester, 'New password', 'new password');
    await _enter(tester, 'Repeat password', 'new password');
    await _tapText(tester, 'Restore');
    expect(find.textContaining('recovery phrase is not valid'), findsOneWidget);

    await _enter(
      tester,
      'Recovery phrase',
      '  ${service.phrase.toUpperCase()} ',
    );
    await _enter(tester, 'Start height (optional)', '1000');
    await _tapText(tester, 'Restore');

    expect(service.session.scanCalls, 1);
    expect(service.createdMnemonic == service.phrase, isTrue);
    expect(find.text('Spendable'), findsOneWidget);
  });

  testWidgets('unlock shows a clear error for a wrong password', (
    tester,
  ) async {
    final service = FakeWalletService(existingWallets: {_mainnetDir});
    await _pumpApp(tester, service);
    await _tapText(tester, 'Continue');
    expect(find.text('Unlock Mainnet wallet'), findsOneWidget);

    await _enter(tester, 'Password', 'guess');
    await _tapText(tester, 'Unlock');
    expect(find.text('Wrong password.'), findsOneWidget);
    expect(find.text('Spendable'), findsNothing);

    await _enter(tester, 'Password', _password);
    await _tapText(tester, 'Unlock');
    expect(find.text('Spendable'), findsOneWidget);
  });

  testWidgets('home renders balances, node tip, address and transactions', (
    tester,
  ) async {
    final session = _fundedSession();
    final service = FakeWalletService(
      existingWallets: {_mainnetDir},
      session: session,
    );
    await _pumpApp(tester, service);
    await _unlockToHome(tester);

    expect(find.text('12.5 EPIC'), findsOneWidget);
    expect(find.text('Awaiting confirmation'), findsOneWidget);
    expect(find.text('1 EPIC'), findsOneWidget);
    expect(find.text('2 EPIC'), findsOneWidget);
    expect(find.text('0.5 EPIC'), findsOneWidget);
    expect(find.textContaining('Not validated with node'), findsOneWidget);
    expect(find.text('Node tip height: 2500000'), findsOneWidget);
    expect(find.text(session.address), findsOneWidget);
    expect(find.byTooltip('Copy address'), findsOneWidget);

    await _reveal(tester, find.text('Received  +5 EPIC'));
    expect(find.text('Received  +5 EPIC'), findsOneWidget);
    expect(find.text('Sent  -1 EPIC'), findsOneWidget);
    expect(find.textContaining('Pending'), findsOneWidget);
    expect(find.textContaining('Confirmed'), findsOneWidget);
    expect(find.textContaining('Fee 0.008 EPIC'), findsOneWidget);

    await _tap(tester, find.byTooltip('Show QR code'));
    expect(
      find.bySemanticsLabel('QR code of the epicbox address'),
      findsOneWidget,
    );
    await _tapText(tester, 'Close');

    // Only the unconfirmed send can be cancelled, after confirming.
    expect(find.byTooltip('Cancel transaction'), findsOneWidget);
    await _tap(tester, find.byTooltip('Cancel transaction'));
    await _tapText(tester, 'Keep');
    expect(session.cancelledTxIds, isEmpty);
    await _tap(tester, find.byTooltip('Cancel transaction'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Cancel transaction'));
    expect(session.cancelledTxIds, [2]);
  });

  testWidgets('home full rescan streams progress', (tester) async {
    final service = FakeWalletService(existingWallets: {_mainnetDir});
    await _pumpApp(tester, service);
    await _unlockToHome(tester);

    await _tap(tester, find.byTooltip('More'));
    await _tapText(tester, 'Full rescan');
    await _tapText(tester, 'Rescan');
    expect(service.session.scanCalls, 1);
    expect(find.text('Spendable'), findsOneWidget);
  });

  testWidgets('send: amount, fee, slate, response, finalize', (tester) async {
    final session = _fundedSession();
    final service = FakeWalletService(
      existingWallets: {_mainnetDir},
      session: session,
    );
    await _pumpApp(tester, service);
    await _unlockToHome(tester);
    await _tapText(tester, 'Send');

    expect(find.textContaining('Sending takes two steps'), findsOneWidget);

    await _enter(tester, 'Amount (EPIC)', '100');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Not enough spendable funds'), findsOneWidget);

    await _enter(tester, 'Amount (EPIC)', '1.123456789');
    expect(find.text('At most 8 decimal places'), findsOneWidget);

    await _enter(tester, 'Amount (EPIC)', '1.5');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Fee: 0.008 EPIC. Total: 1.508 EPIC.'), findsOneWidget);

    await _tapText(tester, 'Create slate');
    expect(session.sentAmounts, [_epic(1.5)]);
    expect(find.text(session.sendSlate.json), findsOneWidget);
    expect(find.byTooltip('Copy slate'), findsOneWidget);

    final responseField = find.descendant(
      of: find.byType(SlateInput),
      matching: find.byType(TextField),
    );
    await tester.enterText(responseField, '{"garbage":true}');
    await _tapText(tester, 'Finalize and post');
    expect(find.textContaining('not valid for this step'), findsOneWidget);

    await tester.enterText(responseField, session.responseSlate.json);
    await _tapText(tester, 'Finalize and post');
    expect(session.finalizedSlates, [session.responseSlate.json]);
    expect(find.text('Transaction of 1.5 EPIC posted.'), findsOneWidget);

    await _tapText(tester, 'Done');
    expect(find.text('Spendable'), findsOneWidget);
  });

  testWidgets('receive: paste slate, show response', (tester) async {
    final session = _fundedSession();
    final service = FakeWalletService(
      existingWallets: {_mainnetDir},
      session: session,
    );
    await _pumpApp(tester, service);
    await _unlockToHome(tester);
    await _tapText(tester, 'Receive');

    await _tapText(tester, 'Sign slate');
    expect(find.text('Paste the slate you received.'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(SlateInput),
        matching: find.byType(TextField),
      ),
      '{"id":"incoming"}',
    );
    await _tapText(tester, 'Sign slate');
    expect(session.receivedSlates, ['{"id":"incoming"}']);
    expect(find.text(session.responseSlate.json), findsOneWidget);
    expect(find.byTooltip('Copy slate'), findsOneWidget);
  });
}
