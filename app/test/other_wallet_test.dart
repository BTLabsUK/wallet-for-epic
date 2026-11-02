// SPDX-License-Identifier: Apache-2.0
// The chain check on the phone: coins another wallet on this recovery phrase spent or received.
// The history row names it, the details say what it is and what is not known, the row after
// that is a spot for the Linked devices offer; a failed post says why.
import 'package:epic_wallet/src/errors.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/ui/common.dart' show txSpokenLabel, txTitle;
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/sent_from_other_wallet.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final BigInt _tip = BigInt.from(2500000);

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

List<TxEntry> _rows() => [
  fakeTx(
    id: 1,
    kind: TxKind.sent,
    status: TxStatus.confirmed,
    origin: TxOrigin.otherWallet,
    createdAtUnix: 1790000000,
    amountDebited: _epic(35.4),
    blockHeight: _tip - BigInt.from(20),
    blockTimeUnix: 1790000000,
  ),
  fakeTx(
    id: 2,
    kind: TxKind.received,
    status: TxStatus.confirmed,
    origin: TxOrigin.otherWallet,
    createdAtUnix: 1789990000,
    amountCredited: _epic(6.2),
    blockHeight: _tip - BigInt.from(30),
    blockTimeUnix: 1789990000,
  ),
];

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: _tip,
      minimumConfirmations: BigInt.from(3),
      total: _epic(10),
      spendable: _epic(10),
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: true,
    ),
    transactions: _rows(),
  );
  final store = MemorySecretStore()..values['wallet.mainnet.backedUp'] = '1';
  final service = FakeWalletService(session: session);
  session.owner = service;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        walletServiceProvider.overrideWithValue(service),
        secretStoreProvider.overrideWithValue(store),
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
        updatePlatformProvider.overrideWithValue(null),
        sessionProvider.overrideWith(() => _OpenSession(session)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the history rows name the other wallet, with no address and the direction\'s amount', (tester) async {
    await _pump(tester, const HistoryScreen());
    expect(find.text('Sent from another device'), findsOneWidget);
    expect(find.text('Received by another device'), findsOneWidget);
    expect(find.textContaining('35.4'), findsWidgets);
    expect(find.textContaining('6.2'), findsWidgets);
  });

  testWidgets('a sent row\'s details: what it is, no recipient, no known fee, the offer spot at the end', (tester) async {
    await _pump(tester, const TxDetailsScreen(txKey: 'l:1'));
    expect(find.text('Sent from another device'), findsWidgets);
    expect(find.text('Sent from another device with this wallet’s recovery phrase. Only the amount is known.'), findsOneWidget);
    expect(find.text('Sent to'), findsNothing);
    expect(find.text('Fee'), findsOneWidget);
    expect(find.text('Not known'), findsOneWidget);
    expect(find.byType(SentFromOtherWalletOffer), findsOneWidget);
  });

  testWidgets('a received row\'s details: what it is, no sender, no fee row', (tester) async {
    await _pump(tester, const TxDetailsScreen(txKey: 'l:2'));
    expect(find.text('Received by another device'), findsWidgets);
    expect(find.text('Received by another device with this wallet’s recovery phrase. Only the amount is known.'), findsOneWidget);
    expect(find.text('Received from'), findsNothing);
    expect(find.text('Fee'), findsNothing);
    expect(find.byType(SentFromOtherWalletOffer), findsOneWidget);
  });

  test('the spoken rows and the error text', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final sent = _rows()[0], received = _rows()[1];
    expect(txTitle(l, sent), 'Sent from another device');
    expect(txTitle(l, received), 'Received by another device');
    String say(TxEntry tx) => txSpokenLabel(l, tx, who: null, date: 'Today', status: 'Completed', hidden: false);
    expect(say(sent), startsWith('Sent from another device'));
    expect(say(received), startsWith('Received by another device'));
    expect(
      describeError(l, const WalletError(kind: WalletErrorKind.inputsSpentElsewhere, message: 'spent')),
      'The node shows these coins already spent, and this wallet did not spend them. Most likely another wallet using your recovery phrase did.',
    );
  });

  test('a send only the node shows so far reads unverified, row and details; a received one does not', () {
    final l = lookupAppLocalizations(const Locale('en'));
    TxEntry row({required bool sent, bool unverified = true}) => fakeTx(
      id: 3,
      kind: sent ? TxKind.sent : TxKind.received,
      status: TxStatus.confirmed,
      origin: TxOrigin.otherWallet,
      createdAtUnix: 1790000000,
      amountDebited: sent ? _epic(1) : BigInt.zero,
      amountCredited: sent ? BigInt.zero : _epic(1),
      blockHeight: _tip - BigInt.from(5),
      unverified: unverified,
    );
    expect(txTitle(l, row(sent: true)), 'Sent from another device · unverified');
    expect(txExplanation(l, row(sent: true), _tip), endsWith('Recheck balance to confirm it.'));
    expect(txTitle(l, row(sent: true, unverified: false)), 'Sent from another device');
    expect(txExplanation(l, row(sent: true, unverified: false), _tip), isNot(contains('Unverified')));
    expect(txTitle(l, row(sent: false)), isNot(contains('unverified')));
  });
}
