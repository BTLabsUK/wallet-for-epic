// Cancel of an incoming payment (2026-10-25): once this wallet signed and returned its
// half, the sender can finalize and post at any time, so Cancel stays out of the way for
// receiveCancelHold (15 minutes) and while the sender reports it posted; a line says when it
// comes. After the hold it is a quiet button for a payment the sender never posted: LEPIC asks
// the node first, and a refusal (the network has it) is an info notice, not an error. A send's
// Cancel is unchanged.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart' show DangerButton;
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final DateTime _now = DateTime(2026, 10, 25, 12);
int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
final BigInt _tip = BigInt.from(2500000);
final _l = englishStrings;

const String _sender = 'esSenderAddressAbcdefghijkmnpqrstuvwxyz1234567890ABCDEF@epicbox.epiccash.com';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

/// Refuses cancels as LEPIC does for a payment the node's pool or chain holds (OnChain, InPool
/// reach the app as invalidArgument).
class _Session extends FakeWalletSession {
  _Session({super.summary, super.transactions, this.refuse = false});

  final bool refuse;

  @override
  Future<void> cancelTransaction({required int txId}) async {
    if (refuse) {
      cancelledTxIds.add(txId);
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'kernel on chain');
    }
    return super.cancelTransaction(txId: txId);
  }
}

/// An incoming Epicbox payment this wallet signed [ago] before [_now], waiting for its sender.
TxEntry _waiting({
  required Duration ago,
  Duration? reportedAgo,
  String transport = 'epicbox',
  TxKind kind = TxKind.received,
  TxStatus status = TxStatus.awaitingConfirmation,
}) => fakeTx(
  id: 9,
  slateId: 'waiting-1',
  kind: kind,
  status: status,
  createdAtUnix: _at(_now.subtract(ago)),
  amountCredited: kind == TxKind.received ? _epic(7.25) : BigInt.zero,
  amountDebited: kind == TxKind.sent ? _epic(7.25) : BigInt.zero,
  counterparty: _sender,
  transport: transport,
  cancellable: true,
  senderReportedPostedAtUnix: reportedAgo == null ? null : _at(_now.subtract(reportedAgo)),
);

class _Harness {
  _Harness(TxEntry tx, {bool refuse = false}) {
    session = _Session(
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
      transactions: [tx],
      refuse: refuse,
    );
    store.values['wallet.mainnet.backedUp'] = '1';
    session.owner = service;
  }

  late final _Session session;
  final store = MemorySecretStore();
  late final service = FakeWalletService(session: session);

  Future<void> pump(WidgetTester tester) async {
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
          sessionProvider.overrideWith(() => _OpenSession(session)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TxDetailsScreen(txKey: 's:waiting-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

String? _notice(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first)).read(noticeProvider)?.text;

NoticeLevel? _noticeLevel(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first)).read(noticeProvider)?.level;

Finder get _cancelButton => find.widgetWithText(ButtonStyleButton, _l.txDetailsCancelPayment);

void main() {
  group('the rule', () {
    test('holds Cancel for 15 minutes after this wallet signed, then offers it', () {
      final at5 = incomingCancelOf(_waiting(ago: const Duration(minutes: 5)), now: _now);
      expect(at5.offered, isFalse);
      expect(at5.signedAgo, const Duration(minutes: 5));
      expect(at5.holdLeft, const Duration(minutes: 10));
      expect(at5.holdMinutesLeft, 10);
      final nearly = incomingCancelOf(_waiting(ago: const Duration(minutes: 14, seconds: 30)), now: _now);
      expect(nearly.holdMinutesLeft, 1, reason: 'any part of a minute left counts as one');
      final at15 = incomingCancelOf(_waiting(ago: receiveCancelHold), now: _now);
      expect(at15.offered, isTrue);
      expect(at15.holdLeft, Duration.zero);
      expect(at15.holdMinutesLeft, 0);
    });

    test('a clock behind the record counts as just signed', () {
      final ahead = incomingCancelOf(_waiting(ago: const Duration(minutes: -3)), now: _now);
      expect(ahead.signedAgo, Duration.zero);
      expect(ahead.holdLeft, receiveCancelHold);
    });

    test('not while the sender reports it posted, however long ago it was signed', () {
      final reported = incomingCancelOf(
        _waiting(ago: const Duration(minutes: 40), reportedAgo: const Duration(minutes: 3)),
        now: _now,
      );
      expect(reported.offered, isFalse);
      expect(reported.senderReportsPosted, isTrue);
      // The report is an hour old: LEPIC stops showing it, and Cancel is back.
      final stale = incomingCancelOf(
        _waiting(ago: const Duration(minutes: 90), reportedAgo: const Duration(hours: 1)),
        now: _now,
      );
      expect(stale.offered, isTrue);
    });

    test('only an incoming payment waiting for its sender has a hold', () {
      // A send, a payment already in a block, a cancelled one: the other rules decide.
      expect(incomingCancelOf(_waiting(ago: Duration.zero, kind: TxKind.sent, status: TxStatus.awaitingRecipient), now: _now).offered, isTrue);
      final inBlock = fakeTx(id: 1, slateId: 'b', kind: TxKind.received, status: TxStatus.awaitingConfirmation, createdAtUnix: _at(_now), blockHeight: _tip, cancellable: false);
      expect(incomingCancelOf(inBlock, now: _now).offered, isTrue);
      expect(incomingCancelOf(_waiting(ago: Duration.zero, kind: TxKind.receivedCancelled, status: TxStatus.cancelled), now: _now).offered, isTrue);
    });

    test('the same hold for every receive path: Epicbox, Link (HTTP, Tor), Direct (File, QR)', () {
      for (final transport in ['epicbox', 'http', 'tor', 'file', 'qr']) {
        expect(incomingCancelOf(_waiting(ago: const Duration(minutes: 5), transport: transport), now: _now).offered, isFalse, reason: transport);
        expect(incomingCancelOf(_waiting(ago: const Duration(minutes: 15), transport: transport), now: _now).offered, isTrue, reason: transport);
      }
    });

    test('the accepted-ago line: minutes below 90, hours below 48, else days', () {
      expect(acceptedAgoText(_l, Duration.zero), 'Accepted just now.');
      expect(acceptedAgoText(_l, const Duration(minutes: 1)), 'Accepted 1 minute ago.');
      expect(acceptedAgoText(_l, const Duration(minutes: 40)), 'Accepted 40 minutes ago.');
      expect(acceptedAgoText(_l, const Duration(minutes: 89)), 'Accepted 89 minutes ago.');
      expect(acceptedAgoText(_l, const Duration(minutes: 90)), 'Accepted 2 hours ago.');
      expect(acceptedAgoText(_l, const Duration(hours: 47)), 'Accepted 47 hours ago.');
      expect(acceptedAgoText(_l, const Duration(hours: 48)), 'Accepted 2 days ago.');
    });
  });

  group('the details screen', () {
    testWidgets('inside the hold: no Cancel, a line says when it comes', (tester) async {
      final h = _Harness(_waiting(ago: const Duration(minutes: 5)));
      await h.pump(tester);
      expect(_cancelButton, findsNothing);
      expect(
        find.text('${_l.txDetailsAcceptedAgoMinutes(5)} ${_l.txDetailsCancelHold(10)}'),
        findsOneWidget,
      );
      expect(find.byKey(txDetailsCancelHoldKey), findsOneWidget);
      expect(find.text(_l.txStatusWaitingSender), findsWidgets, reason: 'the status stays the same');
    });

    testWidgets('after the hold: a quiet Cancel with what it is for', (tester) async {
      final h = _Harness(_waiting(ago: const Duration(minutes: 40)));
      await h.pump(tester);
      expect(find.byKey(txDetailsCancelReceiveKey), findsOneWidget);
      // One destructive look on both sides (UI-015): the same red Cancel as a send's.
      expect(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment), findsOneWidget);
      expect(
        find.text('${_l.txDetailsAcceptedAgoMinutes(40)} ${_l.txDetailsCancelOffered}'),
        findsOneWidget,
      );
      expect(find.byKey(txDetailsCancelHoldKey), findsNothing);
    });

    testWidgets('while the sender reports it posted: no Cancel, the line says so', (tester) async {
      final h = _Harness(_waiting(ago: const Duration(minutes: 40), reportedAgo: const Duration(minutes: 3)));
      await h.pump(tester);
      expect(_cancelButton, findsNothing);
      expect(find.text(_l.txDetailsCancelWhileReported), findsOneWidget);
      expect(find.text(_l.txStatusSenderPosted), findsWidgets);
    });

    testWidgets('the dialog warns, Keep cancels nothing, Cancel payment cancels through LEPIC', (tester) async {
      final h = _Harness(_waiting(ago: const Duration(minutes: 40)));
      await h.pump(tester);
      await tester.tap(find.byKey(txDetailsCancelReceiveKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.txDetailsCancelTitle), findsOneWidget);
      expect(find.text(_l.txDetailsCancelReceiveBody), findsOneWidget);
      expect(find.textContaining('cancels only if the network'), findsOneWidget);
      expect(find.textContaining('a later post still arrives'), findsOneWidget);
      expect(find.textContaining('week'), findsNothing);
      await tester.tap(find.text(_l.txDetailsCancelKeep));
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, isEmpty);
      await tester.tap(find.byKey(txDetailsCancelReceiveKey));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).last);
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [9]);
      expect(_notice(tester), _l.txDetailsPaymentCancelled);
      expect(_noticeLevel(tester), NoticeLevel.success);
    });

    testWidgets('a refusal (the network has it) is an info notice, and the payment stays', (tester) async {
      final h = _Harness(_waiting(ago: const Duration(minutes: 40)), refuse: true);
      await h.pump(tester);
      await tester.tap(find.byKey(txDetailsCancelReceiveKey));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DangerButton, _l.txDetailsCancelPayment).last);
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [9]);
      expect(_notice(tester), _l.txDetailsCancelRefusedOnNetwork);
      expect(_noticeLevel(tester), NoticeLevel.info);
      expect(find.byKey(txDetailsCancelReceiveKey), findsNothing, reason: 'the network has it: Cancel stays away for this visit');
    });

    testWidgets('a send waiting for its recipient keeps its Cancel and words', (tester) async {
      final h = _Harness(_waiting(ago: const Duration(minutes: 2), kind: TxKind.sent, status: TxStatus.awaitingRecipient));
      await h.pump(tester);
      expect(find.widgetWithText(OutlinedButton, _l.txDetailsCancelPayment), findsOneWidget);
      expect(find.text(_l.cancelNoteSendWaiting), findsOneWidget);
      expect(find.byKey(txDetailsCancelNoteKey), findsOneWidget);
      expect(find.byKey(txDetailsCancelHoldKey), findsNothing);
    });
  });
}
