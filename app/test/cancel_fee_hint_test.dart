// SPDX-License-Identifier: Apache-2.0
// The fee line of a phone cancel confirmation (WAL-20 copy, 2026-10-30): when the cancel also
// moves the coins back to this wallet (an invoice this wallet paid, a refused send released),
// the dialog names the normal network fee on its own line with an info icon that opens the
// explanation as a sheet; a plain cancel (a send still waiting) has neither.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/cancel_note.dart';
import 'package:epic_wallet/src/ui/common.dart' show DangerButton;
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());
final _l = englishStrings;
final DateTime _now = DateTime(2026, 10, 30, 12);
int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

const _coinA = 'aa00000000000000000000000000000000000000000000000000000000000000aa';

/// An outgoing payment: an invoice this wallet paid, a send waiting for its answer, or with
/// [releasable] a finished send the network refused for about a day.
TxEntry _send({TxFlow flow = TxFlow.payment, bool releasable = false}) => fakeTx(
  id: 9,
  slateId: 'pay-1',
  kind: TxKind.sent,
  status: releasable ? TxStatus.awaitingConfirmation : TxStatus.awaitingRecipient,
  createdAtUnix: _at(_now.subtract(const Duration(days: 2))),
  amountDebited: _epic(3),
  fee: _epic(0.007),
  numInputs: 1,
  counterparty: 'esService@epicbox.epiccash.com',
  transport: 'epicbox',
  cancellable: !releasable,
  repostable: releasable,
  releasable: releasable,
  finalizedAtUnix: releasable ? _at(_now.subtract(const Duration(days: 1))) : null,
  flow: flow,
);

FakeWalletSession _session(TxEntry tx) => FakeWalletSession(
  summary: WalletSummary(
    lastConfirmedHeight: BigInt.from(2500000),
    minimumConfirmations: BigInt.from(3),
    total: _epic(10),
    spendable: _epic(7),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: _epic(3),
    validatedWithNode: true,
  ),
  transactions: [tx],
)..outputsValue = [
    WalletOutput(
      commitment: _coinA,
      value: _epic(3),
      status: WalletOutputStatus.locked,
      category: null,
      isCoinbase: false,
      height: BigInt.from(2400000),
      lockHeight: BigInt.zero,
      confirmations: BigInt.from(100),
      txId: 9,
    ),
  ];

Future<void> _pump(WidgetTester tester, TxEntry tx) async {
  final session = _session(tx);
  final store = MemorySecretStore();
  store.values['wallet.mainnet.backedUp'] = '1';
  final service = FakeWalletService(session: session);
  session.owner = service;
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        walletServiceProvider.overrideWithValue(service),
        secretStoreProvider.overrideWithValue(store),
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
        updatePlatformProvider.overrideWithValue(null),
        clockProvider.overrideWithValue(() => _now),
        sessionProvider.overrideWith(() => _Open(session)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TxDetailsScreen(txKey: 's:pay-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an invoice paid: the fee line with its info icon, which opens the explanation', (tester) async {
    await _pump(tester, _send(flow: TxFlow.invoice));
    await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).first);
    await tester.pumpAndSettle();
    expect(find.text(_l.txDetailsCancelRequestBody), findsOneWidget);
    expect(find.text(_l.cancelFeeLine), findsOneWidget);
    expect(find.byKey(cancelFeeHintKey), findsOneWidget);
    // Beside the fee line: the icon sits on the same row as the text.
    final line = tester.getRect(find.text(_l.cancelFeeLine));
    final icon = tester.getRect(find.byKey(cancelFeeHintKey));
    expect(icon.left, greaterThanOrEqualTo(line.right - 1));
    expect(icon.center.dy, closeTo(line.center.dy, 12));
    await tester.tap(find.byKey(cancelFeeHintKey));
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsOneWidget);
    expect(find.text(_l.sendNetworkFee), findsOneWidget);
    expect(find.text(_l.cancelFeeWhy), findsOneWidget);
    // Three short sentences: why, what the wallet does, what it costs.
    expect(_l.cancelFeeWhy.split('. ').length, 3);
    expect(_l.cancelFeeWhy, contains('normal network fee'));
  });

  testWidgets('a send still waiting: a plain cancel, no fee line, no icon', (tester) async {
    await _pump(tester, _send());
    await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).first);
    await tester.pumpAndSettle();
    expect(find.text(_l.txDetailsCancelSendBody), findsOneWidget);
    expect(find.text(_l.cancelFeeLine), findsNothing);
    expect(find.byKey(cancelFeeHintKey), findsNothing);
    expect(find.byType(InfoHint), findsNothing);
  });

  testWidgets('Release coins: the same fee line and icon, and a way to Help', (tester) async {
    await _pump(tester, _send(releasable: true));
    await tester.tap(find.widgetWithText(OutlinedButton, _l.txDetailsReleaseFunds));
    await tester.pumpAndSettle();
    expect(find.text(_l.txDetailsReleaseTitle), findsOneWidget);
    expect(find.text(_l.txDetailsReleaseBody), findsOneWidget);
    expect(find.text(_l.cancelFeeLine), findsOneWidget);
    expect(find.byKey(cancelFeeHintKey), findsOneWidget);
    expect(find.text(_l.cancelMoreInHelp), findsOneWidget);
  });
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}
