// SPDX-License-Identifier: Apache-2.0
// A payment made from a link, on the phone: the optional receipt line (hidden when the name service
// cannot be told, one post per stage, stage 2 after finalize, nothing again on a reopen) and the
// silent-payee rows at 0 hours, 24 hours and 7 days (Cancel and send to their public Epicbox address: the cancel, then
// Send with the amount and the payee's saved address).

import 'package:epic_wallet/src/name_service/name_service.dart';
import 'package:epic_wallet/src/history/name_service_pins.dart';
import 'package:epic_wallet/src/history/meta_store.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart' show clockProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/mailbox_resend.dart';
import 'package:epic_wallet/src/ui/receipt_line.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'name_service_vectors_support.dart';
import 'support/fake_receipts.dart';
import 'support/experimental.dart';

final AppLocalizations _l = englishStrings;
final DateTime _now = DateTime(2026, 11, 1, 12);
final Payreq _req = () {
  final v = vectorList(loadVectors(), 'payreqs');
  return Payreq.decode(fromHex(v.firstWhere((e) => e['id'] == 'req-basic')['hex']! as String));
}();

BigInt _epic(num value) => BigInt.from((value * 100000000).round());
int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
DateTime _ago(Duration d) => _now.subtract(d);

WalletSummary get _summary => WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.from(3),
  total: _epic(10),
  spendable: _epic(7),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: _epic(3),
  validatedWithNode: true,
);

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  _Harness({bool tell = true, String? label = 'Corner Shop'}) : receipts = FakeReceipts(tell: tell, label: label) {
    final meta = Meta()..recordLinkPayment(_req, _at(_ago(const Duration(hours: 1))), txId: 'pay-1');
    final r = meta.linkPayments['pay-1']!;
    // The link itself names no one: the name is the name service's, or none.
    records = MemoryLinkPayments({
      'pay-1': LinkPaymentRec(reqid: r.reqid, serviceKey: r.serviceKey, amount: r.amount, address: r.address, paidAt: r.paidAt),
    });
  }

  final session = FakeWalletSession(summary: _summary);
  final store = MemorySecretStore()..values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
  final files = FakeSlateFiles();
  late final service = FakeWalletService(session: session);
  final FakeReceipts receipts;
  late final MemoryLinkPayments records;
  late ProviderContainer container;

  LinkPaymentRec get rec => records.of('pay-1')!;

  /// The payment from the link, made [age] ago and waiting for the payee's answer.
  TxEntry waiting(Duration age) {
    final tx = fakeTx(
      id: 9,
      slateId: 'pay-1',
      kind: TxKind.sent,
      status: TxStatus.awaitingRecipient,
      createdAtUnix: _at(_ago(age)),
      amountDebited: rec.amount + _epic(0.007),
      fee: _epic(0.007),
      numInputs: 1,
      transport: 'epicbox',
      cancellable: true,
    );
    session.transactionsValue.add(tx);
    return tx;
  }

  /// The same payment finalized and posted.
  TxEntry posted() {
    final tx = fakeTx(
      id: 9,
      slateId: 'pay-1',
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: _at(_ago(const Duration(hours: 1))),
      finalizedAtUnix: _at(_ago(const Duration(minutes: 50))),
      amountDebited: rec.amount + _epic(0.007),
      fee: _epic(0.007),
      numInputs: 1,
      transport: 'epicbox',
    );
    session.transactionsValue.add(tx);
    return tx;
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    session.owner = service;
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          invoicesOnProvider.overrideWithValue(true),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          slateFilesProvider.overrideWithValue(files),
          clockProvider.overrideWithValue(() => _now),
          pairNetProvider.overrideWithValue(PairNet.online),
          sessionProvider.overrideWith(() => _Open(session)),
          nameServiceReceiptsProvider.overrideWithValue(receipts),
          linkPaymentRecordsProvider.overrideWithValue(records),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.pumpAndSettle();
  }
}

Future<void> _tick(WidgetTester tester) async {
  await tester.tap(find.byKey(receiptLineKey));
  await tester.pumpAndSettle();
}

void main() {
  group('the receipt line', () {
    testWidgets('hidden while the name service cannot be told', (tester) async {
      final h = _Harness(tell: false);
      final tx = h.waiting(const Duration(hours: 1));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.byKey(receiptLineKey), findsNothing);
      expect(find.byKey(receiptToldKey), findsNothing);
      expect(h.receipts.posts, isEmpty);
    });

    testWidgets('unticked and nothing posted until the user ticks; the tick posts once', (tester) async {
      final h = _Harness();
      final tx = h.waiting(const Duration(hours: 1));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.byKey(receiptLineKey), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(find.byKey(receiptLineKey)).value, isFalse);
      expect(h.receipts.posts, isEmpty, reason: 'never automatic');

      await _tick(tester);
      expect(h.receipts.posts, hasLength(1));
      final p = NameServicePayload.decode(h.receipts.posts.single.$2) as ReceiptPayload;
      expect(p.reqid, _req.reqid);
      expect(p.stage, 1);
      expect(p.amount, h.rec.amount);
      expect(p.at, BigInt.from(h.rec.paidAt));
      expect(find.byKey(receiptToldKey), findsOneWidget);
      expect(find.byKey(receiptLineKey), findsNothing, reason: 'no second tick offered');
      expect(h.rec.told, {1});
    });

    testWidgets('a reopen does not post again and reads as done', (tester) async {
      final h = _Harness();
      final tx = h.waiting(const Duration(hours: 1));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      await _tick(tester);
      await tester.pumpWidget(const SizedBox());
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.byKey(receiptToldKey), findsOneWidget);
      expect(find.byKey(receiptLineKey), findsNothing);
      expect(h.receipts.posts, hasLength(1));
    });

    testWidgets('stage 2 after finalize is its own, unticked line', (tester) async {
      final h = _Harness();
      h.records.records['pay-1'] = h.rec.withTold(1);
      final tx = h.posted();
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(tester.widget<CheckboxListTile>(find.byKey(receiptLineKey)).value, isFalse);
      await _tick(tester);
      expect(h.receipts.posts, hasLength(1));
      final p = NameServicePayload.decode(h.receipts.posts.single.$2) as ReceiptPayload;
      expect(p.stage, 2);
      expect(p.at, BigInt.from(tx.finalizedAtUnix!));
      expect(h.rec.told, {1, 2});
    });
  });

  group('a link payment the payee has not answered', () {
    testWidgets('under 24 hours: waiting for the payee by name, no offer', (tester) async {
      final h = _Harness();
      final tx = h.waiting(const Duration(hours: 2));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text(_l.txStatusWaitingFor('Corner Shop')), findsWidgets);
      expect(find.byKey(mailboxResendCardKey), findsNothing);
    });

    testWidgets('no name: Waiting for recipient', (tester) async {
      final h = _Harness(label: null);
      final tx = h.waiting(const Duration(hours: 2));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text('Waiting for recipient'), findsWidgets);
      expect(find.byKey(mailboxResendCardKey), findsNothing);
    });

    testWidgets('after 24 hours: Not answered yet, then Cancel and send: cancel, Send with the amount', (tester) async {
      final h = _Harness();
      h.session.contactsValue.add(Contact(id: 'c1', name: 'Shop', epicbox: h.rec.address));
      final tx = h.waiting(const Duration(hours: 30));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text(_l.mailboxNotAnswered), findsWidgets);
      expect(find.byKey(mailboxResendCardKey), findsOneWidget);
      expect(tester.widget(find.byKey(txDetailsResendKey)), isA<FilledButton>());

      await tester.tap(find.byKey(txDetailsResendKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(mailboxResendConfirmKey));
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [9]);
      final handoff = h.container.read(sendRecipientProvider)!;
      expect(handoff.request!.amount, h.rec.amount);
      expect(handoff.text, h.rec.address, reason: 'the payee’s saved contact address');
    });

    testWidgets('no matching contact: Send opens with the amount and no address', (tester) async {
      final h = _Harness();
      final tx = h.waiting(const Duration(hours: 30));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      await tester.tap(find.byKey(txDetailsResendKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(mailboxResendConfirmKey));
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [9]);
      final handoff = h.container.read(sendRecipientProvider)!;
      expect(handoff.request!.amount, h.rec.amount);
      expect(handoff.text, isEmpty);
    });

    testWidgets('after 7 days: never picked this up, Cancel first', (tester) async {
      final h = _Harness();
      final tx = h.waiting(const Duration(days: 8));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text(_l.mailboxNotPickedUp), findsWidgets);
      expect(find.text(_l.mailboxNeverPickedUp('Corner Shop')), findsOneWidget);
      expect(tester.widget(find.byKey(txDetailsResendKey)), isA<OutlinedButton>());
    });
  });
}
