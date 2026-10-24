// The payment-proof dialog shows the proof the transaction carries and nothing it made up:
// the real sender, signature and kernel; a typed sender never; and without a proof an empty state.
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the dialog used to print for every payment.
const _oldSampleSender = 'esWnT8kBf3yXqPZ2r9cLhVd7JmK4uA6gYsN1pQeRtC5vD8xHwF2b';
const _oldSampleSignature = '3045022100c7a1e9f0b2d4a6c8e0f2b4d6a8c0e2f4b6d8a0c2e4f6b8d0a2c4e6f8b0d2a4c602205f';

const _sender = 'esReal1SenderAddressForThisPaymentOnly0123456789abcdefghijk';
const _signature = '3044022000aa11bb22cc33dd44ee55ff66778899aabbccddeeff00112233445566778899';
const _kernel = '09a1c3e5f7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3';

Tx _tx({
  bool hasProof = true,
  String? sender,
  String? signature,
  String? counterparty = 'esRecipientKey123@epicbox.epiccash.com',
  Set<ManualField> manual = const {},
}) => Tx(
  id: 1,
  slateId: 'abc',
  direction: TxDirection.sent,
  state: TxState.confirmed,
  method: TxMethod.epicbox,
  amount: nanoPerEpic,
  fee: 0,
  created: DateTime(2026, 10, 1),
  kernel: _kernel,
  hasProof: hasProof,
  proofSender: sender,
  proofSignature: signature,
  counterparty: counterparty,
  manualFields: manual,
);

Future<void> _open(WidgetTester tester, Tx t) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))],
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: Builder(builder: (c) => TextButton(onPressed: () => showTxProofDialog(c, t), child: const Text('open')))),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Every string the dialog paints, including long values cut by an ellipsis.
String _painted(WidgetTester tester) => [
  for (final w in tester.widgetList<Text>(find.byType(Text))) w.data ?? w.textSpan?.toPlainText() ?? '',
].join('\n');

void main() {
  testWidgets('shows the transaction\'s own sender, recipient, signature and kernel', (tester) async {
    await _open(tester, _tx(sender: _sender, signature: _signature));
    final text = _painted(tester);
    expect(text, contains(_sender));
    expect(text, contains(_signature));
    expect(text, contains(_kernel));
    expect(text, contains('esRecipientKey123'));
    expect(text, isNot(contains(_oldSampleSender)));
    expect(text, isNot(contains(_oldSampleSignature)));
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('No payment proof for this payment.'), findsNothing);
  });

  testWidgets('only the fields the proof has: no sender, no row for it', (tester) async {
    await _open(tester, _tx(signature: _signature));
    expect(find.text('Sender address'), findsNothing);
    expect(find.text('Recipient signature'), findsOneWidget);
    expect(_painted(tester), isNot(contains('-\n')));
  });

  testWidgets('a typed sender is never the proof\'s recipient', (tester) async {
    await _open(tester, _tx(sender: _sender, signature: _signature, counterparty: 'esTypedByUser@epicbox.epiccash.com', manual: {ManualField.counterparty}));
    expect(_painted(tester), isNot(contains('esTypedByUser')));
    expect(find.text('Recipient address'), findsNothing);
  });

  for (final (name, t) in [
    ('no proof flag', _tx(hasProof: false, sender: _sender, signature: _signature)),
    ('a flag but no data', _tx()),
    ('blank data', _tx(sender: '  ', signature: '')),
  ]) {
    testWidgets('unavailable ($name): the empty state, nothing to copy or export, no sample', (tester) async {
      await _open(tester, t);
      expect(find.text('No payment proof for this payment.'), findsOneWidget);
      expect(find.text('Export'), findsNothing);
      expect(find.byType(ECopyButton), findsNothing);
      final text = _painted(tester);
      expect(text, isNot(contains(_oldSampleSender)));
      expect(text, isNot(contains(_oldSampleSignature)));
      expect(text, isNot(contains('esWnT8')));
      expect(text, isNot(contains('3045022100')));
    });
  }

  test('no sample proof literal is left in the app', () {
    // Source check: the old samples were string literals in the dialog.
    // (The sender sample is the mock wallet's own address too, so it is checked in the dialog.)
    final dialog = File('lib/src/desktop/screens/wallet/tx_detail.dart').readAsStringSync();
    expect(dialog, isNot(contains(_oldSampleSender)));
    for (final f in Directory('lib/src').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      expect(f.readAsStringSync(), isNot(contains(_oldSampleSignature)), reason: f.path);
    }
  });
}
