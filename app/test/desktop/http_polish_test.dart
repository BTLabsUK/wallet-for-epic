// SPDX-License-Identifier: Apache-2.0
// Polish from the first real-funds HTTP test: the notice after a send, how a receipt over the
// HTTP listener is labelled, one copy button on the listener address, and an Epicbox send that
// waits for the recipient.
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart' show whoOf;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/pay_steps.dart' show DeskPaymentSteps;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

import 'review_password.dart';

core.TxEntry _entry({String? transport, String? counterparty, core.TxStatus status = core.TxStatus.awaitingConfirmation}) => core.TxEntry(
  key: 'l:7',
  id: 7,
  slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
  kind: core.TxKind.received,
  status: status,
  source: core.TxSource.wallet,
  createdAtUnix: 1700000000,
  timeUnix: 1700000000,
  confirmed: false,
  amountCredited: BigInt.from(1000000000),
  amountDebited: BigInt.zero,
  numInputs: 0,
  numOutputs: 0,
  outputCommits: const [],
  counterparty: counterparty,
  transport: transport,
  cancellable: false,
  repostable: false,
  releasable: false,
);

void main() {
  test('a receipt over the HTTP listener is an HTTP payment with no counterparty', () {
    final t = deskTx(_entry(transport: 'http'), tip: 10, minConf: 10, fallbackId: -1);
    expect(t.method, TxMethod.http);
    expect(t.counterparty, isNull);
  });

  test('a Tor transport is a Tor payment; no transport keeps the old guess', () {
    expect(deskTx(_entry(transport: 'tor'), tip: 10, minConf: 10, fallbackId: -1).method, TxMethod.tor);
    expect(deskTx(_entry(transport: 'file'), tip: 10, minConf: 10, fallbackId: -1).method, TxMethod.file);
    expect(deskTx(_entry(transport: 'epicbox', counterparty: 'esA@epicbox.example'), tip: 10, minConf: 10, fallbackId: -1).method, TxMethod.epicbox);
  });

  test('a split or consolidate is with this wallet', () {
    expect(whoOf(englishStrings, deskTx(_entry(transport: 'self'), tip: 10, minConf: 10, fallbackId: -1)), 'This wallet');
  });

  group('Send result', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]));
    tearDown(() => container.dispose());

    Future<void> send(WidgetTester tester, SendArgs args) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.runAsync(() => advancedOn(container));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SendScreen(arg: args))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      await enterReviewPassword(tester);
      await tester.tap(find.textContaining(RegExp(r'^Send \d')));
      await tester.pumpAndSettle();
    }

    // The result is the payment's live steps (wallet levels), not a line per method.
    TxState stepsState(WidgetTester tester) => tester.widget<DeskPaymentSteps>(find.byType(DeskPaymentSteps)).tx.state;

    testWidgets('an HTTP send shows its steps at posted', (tester) async {
      await send(tester, const SendArgs(method: TxMethod.http, recipient: 'https://wallet.example.org', amount: '1'));
      expect(stepsState(tester), TxState.posted);
      expect(find.textContaining('Handed to Epicbox'), findsNothing);
    });

    testWidgets('an Epicbox send shows its steps waiting for the recipient', (tester) async {
      await send(tester, const SendArgs(recipient: 'esTestAddressTestAddressTestAddressTestAddressTestAddress@epicbox.example', amount: '1'));
      expect(stepsState(tester), TxState.waitingRecipient);
    });
  });

  test('an Epicbox send waits for the recipient; an HTTP send is posted', () async {
    final wallet = MockDeskWallet(delay: Duration.zero);
    final box = await wallet.send(const SendRequest(method: TxMethod.epicbox, to: 'es1@epicbox.example', amount: 1000000000));
    final http = await wallet.send(const SendRequest(method: TxMethod.http, to: 'https://wallet.example.org', amount: 1000000000));
    expect((box as SendDone).tx.state, TxState.waitingRecipient);
    expect((http as SendDone).tx.state, TxState.posted);
  });

  testWidgets('Settings › Receiving shows no HTTP address: it lives on Receive', (tester) async {
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.runAsync(() => advancedOn(container));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsReceivingScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('st-offer-linkHttp')));
    await tester.pumpAndSettle();
    expect(find.text('http://127.0.0.1:3415'), findsNothing);
    // The one address here is the onion under Link · Tor, with Tor for payments ready.
    expect(find.byWidgetPredicate((w) => w is EAddress && !w.address.endsWith('.onion')), findsNothing);
  });
}
