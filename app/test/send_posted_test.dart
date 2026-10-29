// SPDX-License-Identifier: Apache-2.0
// The sender's posted report on an incoming Epicbox payment: the sender says it
// pushed the transaction. Advisory: the row and detail say "Sender reports posted" (info) while
// the payment waits, never received; the report asks for one chain check, never a second
// refresh beside a running one; Link and Direct payments never show it; the hour ends it.
import 'dart:async';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart' show deskTx;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_screen.dart' show senderPostedNotice;
import 'package:epic_wallet/src/ui/theme/protocol.dart' show TimelineState;
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart' show txExplanation;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:epic_wallet/src/wallet_service.dart'
    show
        FakeWalletSession,
        InvoiceEvent,
        InvoiceEventKind,
        TxEntry,
        WalletSession,
        fakeTx,
        senderReportsPosted;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

final _now = DateTime(2026, 10, 25, 12);
int _unix(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
final _l = englishStrings;

/// An incoming payment this wallet answered, waiting for its sender.
TxEntry _waiting({
  String transport = 'epicbox',
  Duration? reportedAgo = const Duration(minutes: 5),
  core.TxStatus status = core.TxStatus.awaitingConfirmation,
  BigInt? blockHeight,
  core.TxKind kind = core.TxKind.received,
  core.TxFlow flow = core.TxFlow.payment,
}) => fakeTx(
  slateId: 'posted-1',
  id: 9,
  kind: kind,
  status: status,
  blockHeight: blockHeight,
  amountCredited: BigInt.from(150000000),
  transport: transport,
  counterparty: transport == 'epicbox' ? 'esSender@epicbox.epiccash.com' : null,
  cancellable: true,
  flow: flow,
  senderReportedPostedAtUnix: reportedAgo == null ? null : _unix(_now.subtract(reportedAgo)),
);

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

/// A session whose refresh waits for [gate] when it is set, so a test can hold one running.
class _Session extends FakeWalletSession {
  _Session({super.transactions});

  Completer<void>? gate;

  @override
  Stream<core.RefreshProgress> refresh({required BigInt minimumConfirmations}) async* {
    final g = gate;
    if (g != null) await g.future;
    yield* super.refresh(minimumConfirmations: minimumConfirmations);
  }
}

void main() {
  group('the rule', () {
    test('an incoming Epicbox payment still waiting, reported under an hour ago', () {
      expect(senderReportsPosted(_waiting(), now: _now), isTrue);
      expect(senderReportsPosted(_waiting(reportedAgo: null), now: _now), isFalse);
    });

    test('ends at the hour, as LEPIC stops reporting it', () {
      expect(senderReportsPosted(_waiting(reportedAgo: const Duration(minutes: 59)), now: _now), isTrue);
      expect(senderReportsPosted(_waiting(reportedAgo: const Duration(hours: 1)), now: _now), isFalse);
    });

    test('never once the chain has it, nor for a cancelled one', () {
      expect(senderReportsPosted(_waiting(blockHeight: BigInt.from(100)), now: _now), isFalse);
      expect(senderReportsPosted(_waiting(status: core.TxStatus.confirmed), now: _now), isFalse);
      expect(
        senderReportsPosted(_waiting(status: core.TxStatus.cancelled, kind: core.TxKind.receivedCancelled), now: _now),
        isFalse,
      );
    });

    test('never for Link (HTTP, Tor) or Direct (QR Payment, File Transfer), nor a request or a send', () {
      for (final transport in ['http', 'tor', 'file', 'qr']) {
        expect(senderReportsPosted(_waiting(transport: transport), now: _now), isFalse, reason: transport);
      }
      expect(senderReportsPosted(_waiting(flow: core.TxFlow.invoice), now: _now), isFalse);
      expect(senderReportsPosted(_waiting(kind: core.TxKind.sent), now: _now), isFalse);
    });
  });

  group('LEPIC', () {
    lepic.TransactionDetails details({int? reportedAtMs}) => lepic.TransactionDetails(
      txId: 9,
      direction: lepic.TxDirection.incoming,
      status: lepic.TxStatus.received,
      slateId: 'posted-1',
      transport: 'epicbox',
      amountCredited: BigInt.from(150000000),
      amountDebited: BigInt.zero,
      createdAtMs: 1790000000000,
      releasable: false,
      undelivered: false,
      flow: lepic.TxFlow.payment,
      messages: const [],
      origin: lepic.TxOrigin.wallet,
      outputCommits: const [],
      spentCommits: const [],
      unverified: false,
      senderReportedPostedAtMs: reportedAtMs,
    );

    test('the report time comes over in seconds, and none stays none', () {
      expect(lepicTxEntry(details(reportedAtMs: 1790000123456)).senderReportedPostedAtUnix, 1790000123);
      expect(lepicTxEntry(details()).senderReportedPostedAtUnix, isNull);
    });

    test('paymentPosted is the session notice of the same name, with its kernel', () {
      expect(
        lepicInvoiceEvent(
          const lepic.WalletEvent(
            kind: lepic.WalletEventKind.paymentPosted,
            txId: 9,
            slateId: 'posted-1',
            kernelExcess: '08abc',
          ),
        ),
        const InvoiceEvent(kind: InvoiceEventKind.paymentPosted, slateId: 'posted-1', kernelExcess: '08abc'),
      );
    });
  });

  group('phone words', () {
    test('the row and the timeline say the sender reports it, never received', () {
      final tip = BigInt.from(1000);
      expect(txStatusLabel(_l, _waiting(), tip, now: _now), 'Sender reports posted');
      expect(txStatusLabel(_l, _waiting(reportedAgo: null), tip, now: _now), 'Waiting for sender');
      expect(
        txStatusLabel(_l, _waiting(reportedAgo: const Duration(hours: 2)), tip, now: _now),
        'Waiting for sender',
        reason: 'after the hour it waits again',
      );
      expect(txStatusLabel(_l, _waiting(transport: 'http'), tip, now: _now), 'Waiting for sender');
      // Once in a block it confirms as any payment, with no trace of the report.
      expect(
        txStatusLabel(_l, _waiting(blockHeight: BigInt.from(999)), tip, now: _now, target: 10),
        'Confirming 2/10',
      );
      final steps = txTimeline(_l, _waiting(), tip, now: _now)!;
      expect(steps[1].label, 'Signed and returned');
      expect(steps[1].state, TimelineState.done);
      expect(steps[2].label, 'Sender reports posted');
      expect(steps[2].state, TimelineState.current);
      expect(txExplanation(_l, _waiting(), tip, now: _now), _l.txDetailsSenderPosted);
    });

    test('the notice names the amount unless balances are hidden', () {
      expect(senderPostedNotice(_l, _waiting()), 'Sender reports 1.5000 EPIC posted.');
      expect(senderPostedNotice(_l, _waiting(), hidden: true), _l.homeNoticeSenderPosted);
      expect(senderPostedNotice(_l, null), _l.homeNoticeSenderPosted);
    });

    testWidgets('the detail badge is info and says the words', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            countedConfirmationsProvider.overrideWithValue(BigInt.from(10)),
            clockProvider.overrideWithValue(() => _now),
          ],
          child: MaterialApp(
            theme: buildWalletTheme(protocolDark, Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  TxStatusChip(tx: _waiting(), tip: BigInt.from(1000)),
                  TxStatusLine(tx: _waiting(), tip: BigInt.from(1000), date: '12:00'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final badge = tester.widget<EBadge>(find.byType(EBadge));
      expect(badge.label, 'Sender reports posted');
      expect(badge.tone, BadgeTone.info);
      expect(find.bySemanticsLabel('Sender reports posted'), findsOneWidget);
      expect(find.textContaining('Sender reports posted · 12:00', findRichText: true), findsOneWidget);
    });
  });

  group('phone chain check', () {
    late _Session session;
    late ProviderContainer c;

    Future<void> open() async {
      session = _Session(transactions: [_waiting(reportedAgo: null)]);
      c = ProviderContainer(retry: (_, _) => null, overrides: [sessionProvider.overrideWith(() => _Open(session))]);
      addTearDown(c.dispose);
      c.listen(homeProvider, (_, _) {});
      c.listen(paymentPostedProvider, (_, _) {});
      await c.read(homeProvider.future);
      await pumpEventQueue();
    }

    test('a report shows on the row at once and runs one refresh', () async {
      await open();
      final refreshes = session.refreshCalls;
      session.reportPosted(slateId: 'posted-1', kernelExcess: '08abc');
      await pumpEventQueue();
      expect(c.read(paymentPostedProvider)?.slateId, 'posted-1');
      expect(c.read(homeProvider).value!.transactions.single.senderReportedPostedAtUnix, isNotNull);
      await c.read(homeProvider.future);
      await pumpEventQueue();
      expect(session.refreshCalls, refreshes + 1);
    });

    test('reports during a running refresh give one more refresh after it, never one beside it', () async {
      await open();
      final refreshes = session.refreshCalls;
      session.gate = Completer<void>();
      c.invalidate(homeProvider);
      await pumpEventQueue();
      expect(session.refreshCalls, refreshes, reason: 'held at the gate before it counts');
      session.reportPosted(slateId: 'posted-1');
      session.reportPosted(slateId: 'posted-1');
      await pumpEventQueue();
      expect(homeRefreshing(c.read(homeProvider)), isTrue);
      final gate = session.gate!;
      session.gate = null;
      gate.complete();
      await pumpEventQueue();
      await c.read(homeProvider.future);
      await pumpEventQueue();
      // The held one and exactly one more.
      expect(session.refreshCalls, refreshes + 2);
    });

    test('another notice is no chain check', () async {
      await open();
      final refreshes = session.refreshCalls;
      session.invoiceEventsController.add(const InvoiceEvent(kind: InvoiceEventKind.receiveSuperseded, slateId: 'x'));
      await pumpEventQueue();
      expect(c.read(paymentPostedProvider), isNull);
      expect(session.refreshCalls, refreshes);
    });
  });

  group('desktop', () {
    test('a waiting incoming payment waits for its sender; a paid request stays posted', () {
      final tx = deskTx(_waiting(reportedAgo: null), tip: 1000, minConf: 10, fallbackId: -1);
      expect(tx.state, TxState.waitingRecipient);
      expect(statusOf(_l, tx).$1, 'Waiting for sender');
      final request = deskTx(
        fakeTx(slateId: 'r', kind: core.TxKind.received, status: core.TxStatus.awaitingConfirmation, flow: core.TxFlow.invoice),
        tip: 1000,
        minConf: 10,
        fallbackId: -1,
      );
      expect(request.state, TxState.posted);
    });

    test('the row says the sender reports it, in info, while it waits and under the hour', () {
      final tx = deskTx(_waiting(), tip: 1000, minConf: 10, fallbackId: -1, now: _now);
      expect(tx.senderPosted, isTrue);
      expect(statusOf(_l, tx), ('Sender reports posted', ETone.info));
      expect(deskTx(_waiting(), tip: 1000, minConf: 10, fallbackId: -1, now: _now.add(const Duration(hours: 1))).senderPosted, isFalse);
      expect(deskTx(_waiting(transport: 'tor'), tip: 1000, minConf: 10, fallbackId: -1, now: _now).senderPosted, isFalse);
    });

    testWidgets('the detail panel has the badge, the sentence and the timeline step', (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final tx = deskTx(_waiting(), tip: 1000, minConf: 10, fallbackId: -1, now: _now);
      final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SingleChildScrollView(child: TxDetail(tx: tx))),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final badge = tester.widget<EBadge>(find.byKey(const ValueKey('tx-sender-posted')));
      expect(badge.tone, ETone.info);
      expect(badge.label, 'Sender reports posted');
      expect(find.text(_l.deskTxNowSenderPosted), findsOneWidget);
      // The Posted step is current with the report under it, not done.
      expect(find.text('Sender reports posted'), findsNWidgets(2));
      expect(find.text(_l.deskTxReceived), findsNothing);
    });
  });
}
