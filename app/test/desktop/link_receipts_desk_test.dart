// SPDX-License-Identifier: Apache-2.0
// A payment made from a link, on the desktop: the optional receipt line (hidden when the name service
// cannot be told, one post per stage, stage 2 after finalize) and the silent-payee rows at 0 hours,
// 24 hours and 7 days (Cancel and send to their public Epicbox address: the cancel, then Send with the amount and the
// payee's saved address).
import 'package:epic_wallet/src/cancel_final.dart' show CancelResult;
import 'package:epic_wallet/src/desktop/data/clock.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart' show SendArgs;
import 'package:epic_wallet/src/desktop/screens/wallet/receipt_line.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/name_service/name_service.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../name_service_vectors_support.dart';
import '../support/fake_receipts.dart';

final _l = englishStrings;
final DateTime _now = DateTime(2026, 11, 1, 12);
DateTime _ago(Duration d) => _now.subtract(d);
int _unix(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
const _slate = 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1';
const _amount = 250000000;

class _Desk extends MockDeskWallet {
  _Desk() : super(delay: Duration.zero);

  final List<int> cancelled = [];

  @override
  Future<CancelResult> cancelTx(int id, {bool spendBack = true}) async {
    cancelled.add(id);
    return super.cancelTx(id, spendBack: spendBack);
  }
}

late ProviderContainer _c;
late _Desk _mock;
late FakeReceipts _receipts;
late MemoryLinkPayments _records;

Tx _payment(DateTime created, {TxState state = TxState.waitingRecipient}) => Tx(
  id: 77,
  slateId: _slate,
  direction: TxDirection.sent,
  state: state,
  method: TxMethod.epicbox,
  amount: _amount,
  fee: 7000000,
  created: created,
  cancellable: state == TxState.waitingRecipient,
);

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Opens the details of [tx]; [matchContact]: the listing address is a saved contact's.
Future<void> _open(WidgetTester tester, Tx tx, {bool tell = true, String? label = 'Corner Shop', bool matchContact = false}) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _mock = _Desk();
  final anna = (await _mock.contacts()).firstWhere((c) => c.id == 'c1');
  final v = vectorList(loadVectors(), 'payreqs');
  final req = Payreq.decode(fromHex(v.firstWhere((e) => e['id'] == 'req-basic')['hex']! as String));
  _records = MemoryLinkPayments({
    _slate: LinkPaymentRec(
      reqid: toHex(req.reqid),
      serviceKey: toHex(req.card.serviceKey),
      amount: BigInt.from(_amount),
      address: matchContact ? anna.epicbox! : 'es${'b' * 50}@epicbox.epiccash.com',
      paidAt: _unix(_ago(const Duration(hours: 1))),
    ),
  });
  _receipts = FakeReceipts(tell: tell, label: label);
  _c = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(_mock),
      deskClockProvider.overrideWithValue(() => _now),
      nameServiceReceiptsProvider.overrideWithValue(_receipts),
      linkPaymentRecordsProvider.overrideWithValue(_records),
    ],
  );
  addTearDown(_c.dispose);
  await tester.runAsync(() async {
    await _c.read(deskProvider.notifier).refresh();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: TxDetail(tx: tx))),
      ),
    ),
  );
  await _real(tester);
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUpAll(initializeDateFormatting);

  group('the receipt line', () {
    testWidgets('hidden while the name service cannot be told', (tester) async {
      await _open(tester, _payment(_ago(const Duration(hours: 1))), tell: false);
      expect(find.byKey(deskReceiptLineKey), findsNothing);
      expect(find.byKey(deskReceiptToldKey), findsNothing);
      await _end(tester);
    });

    testWidgets('unticked, nothing posted until ticked; the tick posts once and reads as done', (tester) async {
      await _open(tester, _payment(_ago(const Duration(hours: 1))));
      expect(find.byKey(deskReceiptLineKey), findsOneWidget);
      expect(tester.widget<ECheckbox>(find.byType(ECheckbox)).value, isFalse);
      expect(_receipts.posts, isEmpty);

      await tester.tap(find.byType(ECheckbox));
      await _real(tester);
      expect(_receipts.posts, hasLength(1));
      final p = NameServicePayload.decode(_receipts.posts.single.$2) as ReceiptPayload;
      expect(p.reqid, fromHex(_records.of(_slate)!.reqid));
      expect(p.stage, 1);
      expect(p.amount, BigInt.from(_amount));
      expect(p.at, BigInt.from(_records.of(_slate)!.paidAt));
      expect(find.byKey(deskReceiptToldKey), findsOneWidget);
      expect(find.byType(ECheckbox), findsNothing);
      await _end(tester);
    });

    testWidgets('after finalize: the second stage, its own line, posted with stage 2', (tester) async {
      await _open(tester, _payment(_ago(const Duration(hours: 1)), state: TxState.confirming));
      _records.records[_slate] = _records.of(_slate)!.withTold(1);
      // The first stage was told before; the line is rebuilt for stage 2.
      _c.read(linkPaymentTickProvider.notifier).bump();
      await _real(tester);
      expect(find.byKey(deskReceiptLineKey), findsOneWidget);
      await tester.tap(find.byType(ECheckbox));
      await _real(tester);
      expect(_receipts.posts, hasLength(1));
      expect((NameServicePayload.decode(_receipts.posts.single.$2) as ReceiptPayload).stage, 2);
      expect(_records.of(_slate)!.told, {1, 2});
      await _end(tester);
    });
  });

  group('a link payment the payee has not answered', () {
    testWidgets('under 24 hours: waiting for the payee by name, no offer', (tester) async {
      await _open(tester, _payment(_ago(const Duration(hours: 2))));
      expect(find.byKey(deskTxResendKey), findsNothing);
      expect(find.textContaining('Corner Shop'), findsWidgets);
      await _end(tester);
    });

    testWidgets('after 24 hours: Not answered yet; Cancel and send to their public Epicbox address cancels and opens Send with the amount', (tester) async {
      await _open(tester, _payment(_ago(const Duration(hours: 30))), matchContact: true);
      expect(find.text(_l.mailboxNotAnswered), findsWidgets);
      expect(tester.widget<EButton>(find.byKey(deskTxResendKey)).kind, EBtnKind.primary);
      await tester.tap(find.byKey(deskTxResendKey));
      await _real(tester);
      await tester.tap(find.byKey(deskMailboxResendConfirmKey));
      await _real(tester, 800);
      expect(_mock.cancelled, [77]);
      final nav = _c.read(deskNavProvider);
      expect(nav.route, DeskRoute.send);
      final args = nav.arg! as SendArgs;
      expect(args.amount, '2.5');
      expect(args.recipient, (await _mock.contacts()).firstWhere((c) => c.id == 'c1').epicbox);
      await _end(tester);
    });

    testWidgets('no saved contact for the listing address: Send opens with no address', (tester) async {
      await _open(tester, _payment(_ago(const Duration(hours: 30))));
      await tester.tap(find.byKey(deskTxResendKey));
      await _real(tester);
      await tester.tap(find.byKey(deskMailboxResendConfirmKey));
      await _real(tester, 800);
      final args = _c.read(deskNavProvider).arg! as SendArgs;
      expect(args.amount, '2.5');
      expect(args.recipient, isNull);
      await _end(tester);
    });

    testWidgets('after 7 days: never picked this up, Cancel first', (tester) async {
      await _open(tester, _payment(_ago(const Duration(days: 8))));
      expect(find.text(_l.mailboxNotPickedUp), findsWidgets);
      expect(find.text(_l.mailboxNeverPickedUp('Corner Shop')), findsOneWidget);
      expect(tester.widget<EButton>(find.byKey(deskTxResendKey)).kind, isNot(EBtnKind.primary));
      await _end(tester);
    });
  });
}
