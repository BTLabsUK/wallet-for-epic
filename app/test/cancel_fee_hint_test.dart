// SPDX-License-Identifier: Apache-2.0
// The phone's cancel confirmations (WAL-20 copy, 2026-10-30). Where the other side could still
// finish the payment (an invoice this wallet paid, a refused send released), the dialog offers
// three choices: Cancel for sure with the fee line and an info icon that opens the two ways to
// cancel, the free Stop waiting with its own line, and Keep. Stop waiting cancels (or releases)
// with nothing spent; Cancel for sure still spends the coins back. A plain cancel (a send still
// waiting) keeps one free cancel, no fee line, no icon, no Stop waiting.
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

/// The three choices, stacked main first, each inside the 360 dp screen.
void _expectThreeChoices(WidgetTester tester, {required String keep}) {
  expect(find.byKey(cancelForSureKey), findsOneWidget);
  expect(find.byKey(cancelStopWaitingKey), findsOneWidget);
  expect(find.byKey(cancelKeepKey), findsOneWidget);
  expect(find.text(_l.cancelForSure), findsOneWidget);
  expect(find.text(_l.cancelStopWaiting), findsOneWidget);
  expect(find.text(keep), findsOneWidget);
  expect(find.text(_l.cancelFeeLine), findsOneWidget);
  expect(find.text(_l.cancelStopWaitingLine), findsOneWidget);
  expect(find.byKey(cancelFeeHintKey), findsOneWidget);
  final main = tester.getRect(find.byKey(cancelForSureKey));
  final fee = tester.getRect(find.text(_l.cancelFeeLine));
  final stop = tester.getRect(find.byKey(cancelStopWaitingKey));
  final free = tester.getRect(find.text(_l.cancelStopWaitingLine));
  final dismiss = tester.getRect(find.byKey(cancelKeepKey));
  expect(main.bottom, lessThanOrEqualTo(fee.top + 1), reason: 'the fee line sits under Cancel for sure');
  expect(fee.bottom, lessThanOrEqualTo(stop.top + 1), reason: 'then Stop waiting');
  expect(stop.bottom, lessThanOrEqualTo(free.top + 1), reason: 'with its free line under it');
  expect(free.bottom, lessThanOrEqualTo(dismiss.top + 1), reason: 'Keep last');
  for (final r in [main, stop, dismiss]) {
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.right, lessThanOrEqualTo(360));
    expect(r.height, greaterThanOrEqualTo(44), reason: 'a full-size tap target');
  }
  // Beside the fee line: the icon sits on the same row as the text.
  final icon = tester.getRect(find.byKey(cancelFeeHintKey));
  expect(icon.left, greaterThanOrEqualTo(fee.right - 1));
  expect(icon.center.dy, closeTo(fee.center.dy, 12));
}

void main() {
  testWidgets('an invoice paid: one calm sentence, three choices, the info icon opens the two ways', (tester) async {
    await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    expect(find.text(_l.txDetailsCancelTitle), findsOneWidget);
    expect(find.text(_l.txDetailsCancelRequestBody), findsNWidgets(2), reason: 'the quiet line and the dialog say the same');
    expect(find.text(_l.cancelMoreInHelp), findsNWidgets(2), reason: 'the quiet line and the dialog');
    _expectThreeChoices(tester, keep: _l.txDetailsCancelKeep);
    await tester.tap(find.byKey(cancelFeeHintKey));
    await tester.pumpAndSettle();
    expect(find.byType(InfoSheet), findsOneWidget);
    expect(find.text(_l.cancelChoicesTitle), findsOneWidget);
    expect(find.text(_l.cancelChoicesWhy), findsOneWidget);
    // Two short paragraphs, one per way: what it does, what it costs, what may still happen.
    final ways = _l.cancelChoicesWhy.split('\n\n');
    expect(ways, hasLength(2));
    expect(ways.first, startsWith(_l.cancelForSure));
    expect(ways.first, contains('normal network fee'));
    expect(ways.last, startsWith(_l.cancelStopWaiting));
    expect(ways.last, contains('shows as paid'));
    // One fee line only, never a count of coins (the owner, 2026-10-30).
    expect(_l.cancelChoicesWhy, isNot(matches(RegExp(r'\d'))));
    expect(_l.cancelChoicesWhy, isNot(contains('output')));
  });

  testWidgets('Stop waiting: cancelled with nothing spent, a calm notice that it may still finish', (tester) async {
    final s = await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    await tester.tap(find.byKey(cancelStopWaitingKey));
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, [9]);
    expect(s.spentToSelf, isEmpty);
    expect(_notice(tester)?.text, _l.txDetailsStoppedWaiting);
    expect(_notice(tester)?.level, NoticeLevel.info);
  });

  testWidgets('Cancel for sure: cancelled and the coins spent back, as before', (tester) async {
    final s = await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    await tester.tap(find.byKey(cancelForSureKey));
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, [9]);
    expect(s.spentToSelf.single, [_coinA]);
    expect(_notice(tester)?.text, _l.txDetailsCancelledSpentBack);
  });

  testWidgets('Keep: nothing happens', (tester) async {
    final s = await _pump(tester, _send(flow: TxFlow.invoice));
    await _openCancel(tester);
    await tester.tap(find.byKey(cancelKeepKey));
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, isEmpty);
    expect(find.byKey(cancelForSureKey), findsNothing);
  });

  testWidgets('a send still waiting: one free cancel, no fee line, no icon, no Stop waiting', (tester) async {
    final s = await _pump(tester, _send());
    await _openCancel(tester);
    expect(find.text(_l.txDetailsCancelSendBody), findsNWidgets(2), reason: 'the quiet line and the dialog say the same');
    expect(find.text(_l.cancelFeeLine), findsNothing);
    expect(find.byKey(cancelFeeHintKey), findsNothing);
    expect(find.byType(InfoHint), findsNothing);
    expect(find.byKey(cancelStopWaitingKey), findsNothing);
    expect(find.text(_l.cancelStopWaiting), findsNothing);
    expect(find.text(_l.txDetailsCancelKeep), findsOneWidget);
    await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).last);
    await tester.pumpAndSettle();
    expect(s.cancelledTxIds, [9]);
    expect(s.spentToSelf, isEmpty);
    expect(_notice(tester)?.text, _l.txDetailsPaymentCancelled);
  });

  testWidgets('Release coins: the same three choices; Stop waiting releases with nothing spent', (tester) async {
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

  testWidgets('Release coins, Cancel for sure: released and the coins spent back', (tester) async {
    final s = await _pump(tester, _send(releasable: true));
    await tester.tap(find.widgetWithText(OutlinedButton, _l.txDetailsReleaseFunds));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(cancelForSureKey));
    await tester.pumpAndSettle();
    expect(s.releasedKeys, ['s:pay-1']);
    expect(s.spentToSelf.single, [_coinA]);
    expect(_notice(tester)?.text, _l.txDetailsReleasedSpentBack);
  });

  test('the words stay calm and plain (the owner, 2026-10-30)', () {
    final surfaces = [
      _l.txDetailsCancelRequestBody,
      _l.txDetailsCancelNotPostedBody,
      _l.txDetailsCancelSendBody,
      _l.txDetailsCancelReceiveBody,
      _l.txDetailsReleaseBody,
      _l.cancelFeeLine,
      _l.cancelStopWaitingLine,
      _l.cancelChoicesWhy,
      _l.txDetailsStoppedWaiting,
      _l.txDetailsCancelledMayComplete,
      _l.txDetailsCancelledSpentBack,
      _l.txDetailsCancelledSpendBackPending,
      _l.txDetailsReleasedSpentBack,
      _l.txDetailsReleasedSpendBackPending,
      _l.cancelNoteRequestPaid,
      _l.cancelNoteNotPostedSend,
      _l.cancelNoteSendWaiting,
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
    // The button labels: one to three words each.
    for (final s in [_l.cancelForSure, _l.cancelStopWaiting, _l.txDetailsCancelKeep]) {
      expect(s.split(' ').length, inInclusiveRange(1, 3), reason: s);
    }
  });
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}
