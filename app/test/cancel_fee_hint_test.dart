// SPDX-License-Identifier: Apache-2.0
// The phone's cancel confirmations (WAL-20 copy, 2026-10-30; calmer, B-04, 2026-11-01). Where
// the other side could still finish the payment (an invoice this wallet paid, a refused send
// released), the dialog has one sentence, a two-line comparison and three choices named by
// outcome: Move coins back with its fee (the one primary), Unlock coins, and the dismiss.
// Unlock cancels (or releases) with nothing spent; Move coins back still spends the coins
// back. A plain cancel (a send still waiting) keeps one free cancel and no comparison.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/cancel_dialog.dart';
import 'package:epic_wallet/src/ui/common.dart' show DangerButton;
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/notices.dart';
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
const _other = 'cc00000000000000000000000000000000000000000000000000000000000000cc';

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
    // A free coin, so the spend back has something to pay its fee from (as LEPIC needs).
    WalletOutput(
      commitment: _other,
      value: _epic(2),
      status: WalletOutputStatus.unspent,
      category: OutputCategory.spendable,
      isCoinbase: false,
      height: BigInt.from(2400000),
      lockHeight: BigInt.zero,
      confirmations: BigInt.from(100),
      txId: 3,
    ),
  ];

/// A 360 dp phone, as the tour renders it: the stacked choices must fit there.
Future<FakeWalletSession> _pump(WidgetTester tester, TxEntry tx) async {
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
  return session;
}

Notice? _notice(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(Navigator).first)).read(noticeProvider);

Future<void> _openCancel(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).first);
  await tester.pumpAndSettle();
}

/// The three choices, stacked main first, each inside the 360 dp screen, under the comparison.
void _expectThreeChoices(WidgetTester tester, {required String keep}) {
  expect(find.byKey(cancelForSureKey), findsOneWidget);
  expect(find.byKey(cancelStopWaitingKey), findsOneWidget);
  expect(find.byKey(cancelKeepKey), findsOneWidget);
  // The fee of the one locked coin spent back into one output: 0.004 EPIC, on its button.
  expect(find.descendant(of: find.byKey(cancelForSureKey), matching: find.textContaining('0.004')), findsOneWidget);
  expect(find.descendant(of: find.byKey(cancelForSureKey), matching: find.textContaining(_l.cancelMoveBack)), findsOneWidget);
  expect(find.text(_l.cancelUnlockOpen), findsOneWidget);
  expect(find.text(keep), findsOneWidget);
  expect(find.text(_l.cancelCompareMoveBack), findsOneWidget);
  expect(find.text(_l.cancelCompareUnlock), findsOneWidget);
  // No caption under a button, no info icon (B-04).
  expect(find.text(_l.cancelFeeLine), findsNothing);
  expect(find.text(_l.cancelStopWaitingLine), findsNothing);
  expect(find.byKey(cancelFeeHintKey), findsNothing);
  final compare = tester.getRect(find.text(_l.cancelCompareUnlock));
  final main = tester.getRect(find.byKey(cancelForSureKey));
  final stop = tester.getRect(find.byKey(cancelStopWaitingKey));
  final dismiss = tester.getRect(find.byKey(cancelKeepKey));
  expect(compare.bottom, lessThanOrEqualTo(main.top + 1), reason: 'the comparison above the buttons');
  expect(main.bottom, lessThanOrEqualTo(stop.top + 1), reason: 'Move coins back first');
  expect(stop.bottom, lessThanOrEqualTo(dismiss.top + 1), reason: 'the dismiss last');
  for (final r in [main, stop, dismiss]) {
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.right, lessThanOrEqualTo(360));
    expect(r.height, greaterThanOrEqualTo(44), reason: 'a full-size tap target');
  }
  expect(find.descendant(of: find.byKey(cancelForSureKey), matching: find.byType(FilledButton)), findsOneWidget, reason: 'the one primary');
}

void main() {
  testWidgets('an invoice paid: one calm sentence, the comparison, three choices named by outcome', (tester) async {
    await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    expect(find.text(_l.txDetailsCancelTitle), findsOneWidget);
    expect(find.text(_l.txDetailsCancelRequestBody), findsOneWidget, reason: 'the dialog only: no quiet line under Cancel');
    expect(find.text(_l.cancelMoreInHelp), findsOneWidget, reason: 'the dialog only');
    _expectThreeChoices(tester, keep: _l.txDetailsCancelKeep);
  });

  testWidgets('Unlock coins: cancelled with nothing spent, a calm notice that it may still finish', (tester) async {
    final s = await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    await tester.tap(find.byKey(cancelStopWaitingKey));
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, [9]);
    expect(s.spentToSelf, isEmpty);
    expect(_notice(tester)?.text, _l.txDetailsStoppedWaiting);
    expect(_notice(tester)?.level, NoticeLevel.info);
  });

  testWidgets('Move coins back: cancelled and the coins spent back, as before', (tester) async {
    final s = await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    await tester.tap(find.byKey(cancelForSureKey));
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, [9]);
    expect(s.spentToSelf.single, [_coinA]);
    expect(_notice(tester)?.text, _l.txDetailsPaymentCancelled);
  });

  testWidgets('Keep: nothing happens', (tester) async {
    final s = await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    await tester.tap(find.byKey(cancelKeepKey));
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, isEmpty);
    expect(find.byKey(cancelForSureKey), findsNothing);
  });

  testWidgets('a send still waiting: one free cancel, no comparison, no Unlock coins', (tester) async {
    final s = await _pump(tester, _send());
    await _openCancel(tester);
    expect(find.text(_l.txDetailsCancelSendBody), findsOneWidget, reason: 'the dialog only: no quiet line under Cancel');
    expect(find.text(_l.cancelFeeLine), findsNothing);
    expect(find.byKey(cancelFeeHintKey), findsNothing);
    expect(find.byType(InfoHint), findsNothing);
    expect(find.byKey(cancelStopWaitingKey), findsNothing);
    expect(find.text(_l.cancelCompareUnlock), findsNothing);
    expect(find.text(_l.txDetailsCancelKeep), findsOneWidget);
    await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).last);
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, [9]);
    expect(s.spentToSelf, isEmpty);
    expect(_notice(tester)?.text, _l.txDetailsPaymentCancelled);
  });

  testWidgets('Release coins: the same three choices; Unlock coins releases with nothing spent', (tester) async {
    final s = await _pump(tester, _send(releasable: true));
    await tester.tap(find.widgetWithText(OutlinedButton, _l.txDetailsReleaseFunds));
    await tester.pumpAndSettle();
    expect(find.text(_l.txDetailsReleaseTitle), findsOneWidget);
    expect(find.text(_l.txDetailsReleaseBody), findsOneWidget);
    expect(find.text(_l.cancelMoreInHelp), findsAtLeastNWidgets(1));
    _expectThreeChoices(tester, keep: _l.txDetailsReleaseKeepWaiting);
    await tester.tap(find.byKey(cancelStopWaitingKey));
    await tester.pumpAndSettle();
    expect(s.releasedKeys, ['s:pay-1']);
    expect(s.spentToSelf, isEmpty);
    expect(_notice(tester)?.text, _l.txDetailsStoppedWaiting);
    expect(_notice(tester)?.level, NoticeLevel.info);
  });

  testWidgets('Release coins, Move coins back: released and the coins spent back', (tester) async {
    final s = await _pump(tester, _send(releasable: true));
    await tester.tap(find.widgetWithText(OutlinedButton, _l.txDetailsReleaseFunds));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(cancelForSureKey));
    await tester.pumpAndSettle();
    expect(s.releasedKeys, ['s:pay-1']);
    expect(s.spentToSelf.single, [_coinA]);
    expect(_notice(tester)?.text, _l.txDetailsFundsReleased);
  });

  test('the words stay calm and plain (the owner, 2026-10-30)', () {
    final surfaces = [
      _l.txDetailsCancelRequestBody,
      _l.txDetailsCancelNotPostedBody,
      _l.txDetailsCancelSendBody,
      _l.txDetailsCancelReceiveBody,
      _l.txDetailsReleaseBody,
      _l.cancelCompareMoveBack,
      _l.cancelCompareUnlock,
      _l.txDetailsStoppedWaiting,
    ];
    for (final s in surfaces) {
      for (final jargon in ['signature', 'signed', 'half', 'kernel', 'output', 'input', 'finaliz', 'slate', ' we ', 'We ']) {
        expect(s, isNot(contains(jargon)), reason: '"$jargon" in: $s');
      }
      expect(s, isNot(matches(RegExp(r'\d'))), reason: 'no counts or amounts: $s');
    }
    // The dialog's one sentence stays one sentence.
    for (final s in [_l.txDetailsCancelRequestBody, _l.txDetailsCancelNotPostedBody, _l.txDetailsCancelSendBody, _l.txDetailsReleaseBody]) {
      expect(s.split('. ').length, 1, reason: s);
    }
    // The buttons are named by outcome (B-04): what happens to the coins and the payment.
    expect(_l.cancelMoveBack, contains('coins'));
    expect(_l.cancelUnlockOpen, contains('coins'));
    expect(_l.cancelMoveBackFee('0.004 EPIC'), startsWith(_l.cancelMoveBack));
    for (final s in [_l.cancelCompareMoveBack, _l.cancelCompareUnlock]) {
      expect(s.split('. ').length, 1, reason: 'one line each: $s');
    }
  });
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}
