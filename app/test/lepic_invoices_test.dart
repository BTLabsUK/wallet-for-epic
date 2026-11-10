// SPDX-License-Identifier: Apache-2.0
// The LEPIC adapter's invoice calls over a stand-in `EpicWallet` that keeps contact invoices
// as LEPIC does (RFC 11). No native library is loaded.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _shop = 'contact-shop';

lepic.WalletError _lepicError(lepic.WalletErrorKind kind) =>
    lepic.WalletError(kind: kind, code: 0, message: kind.name);

/// LEPIC's contact invoices in memory. Fails any other native call.
class _InvoiceWallet implements lepic.EpicWallet {
  final List<lepic.ContactInvoiceView> waiting = [];
  final List<lepic.TransactionDetails> stored = [];
  final List<lepic.OutboxEntryView> outbox = [];
  final StreamController<lepic.WalletEvent> eventSink =
      StreamController<lepic.WalletEvent>.broadcast();

  /// Every `contactPayInvoice` that reached LEPIC, with its arguments.
  final List<({String slateId, BigInt amount, BigInt minConf, String? message})>
  payments = [];
  final List<BigInt> resent = [];
  final List<String> declined = [];
  final List<BigInt?> expiries = [];
  final List<lepic.CollectTrigger> collects = [];
  lepic.WalletErrorKind? payError;
  lepic.WalletErrorKind? resendError;
  bool sweepFails = false;

  void park(String slateId, BigInt amount, {String? reference}) => waiting.add(
    lepic.ContactInvoiceView(
      slateId: slateId,
      contactId: _shop,
      amount: amount,
      purpose: lepic.SlatePurpose.request,
      reference: reference,
      expires: BigInt.from(1790086400),
      receivedAtMs: 1790000000000,
      sameAmount: const [],
    ),
  );

  @override
  bool get isDisposed => false;

  @override
  void lock() {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => eventSink.stream;

  /// The balance's count, which an invoice is paid with.
  BigInt balanceConfirmations = BigInt.from(3);

  @override
  Future<lepic.WalletSummary> summary({required bool refresh}) async =>
      lepic.WalletSummary(
        lastConfirmedHeight: BigInt.from(100),
        minimumConfirmations: balanceConfirmations,
        total: BigInt.zero,
        spendable: BigInt.zero,
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: false,
      );

  final contactView = const lepic.ContactView(
    peerProfile: 0,
    contactId: _shop,
    label: 'Shop',
    state: lepic.PairingState.verified,
    status: lepic.PairingStatus.verified,
    peerFeatures: 0,
    sas: [],
    allowInvoices: true,
    seal: lepic.SealState.on_,
    importedFromBackup: false,
    lapsed: false,
    removedByPeer: false,
    createdAtMs: 1790000000000,
  );

  @override
  Future<List<lepic.ContactView>> contacts() async => [contactView];

  @override
  Future<lepic.ContactView> contact({required String contactId}) async =>
      contactView;

  @override
  Future<String?> contactOfTransaction({required int txId}) async => _shop;

  @override
  Future<List<lepic.QuarantinedMessageView>> contactQuarantine() async => const [];

  @override
  Future<lepic.ContactCollectReport> contactsCollect({
    required lepic.CollectTrigger trigger,
    required lepic.ContactRelayMode relayMode,
    List<String>? only,
  }) async {
    collects.add(trigger);
    // Two invoices arrive in the shop's mailbox.
    park('new-1', BigInt.from(7));
    park('new-2', BigInt.from(8));
    return const lepic.ContactCollectReport(
      capped: 0, kept: 0, refused: 0, timedOut: 0, notReached: 0, quarantined: 0, quarantineDropped: 0, buffered: 0, mailboxes: 1,
      messages: 2,
      paired: 0,
      unreachable: [],
      delivered: 0,
      failed: [],
      ended: [],
    );
  }

  @override
  Future<lepic.OutboxReport> contactsOutboxDeliver({
    required lepic.ContactRelayMode relayMode,
  }) async => const lepic.OutboxReport(delivered: 0, failed: 0, stuck: 0);

  @override
  Future<lepic.InvoiceSweep> sweepInvoices({BigInt? expirySecs}) async {
    expiries.add(expirySecs);
    if (sweepFails) throw _lepicError(lepic.WalletErrorKind.nodeUnreachable);
    return lepic.InvoiceSweep(
      deleted: const [],
      cancelled: Uint32List(0),
      cancellable: Uint32List(0),
    );
  }

  @override
  Future<List<lepic.ContactInvoiceView>> contactInvoices() async => [
    ...waiting,
  ];

  @override
  Future<lepic.PaidInvoice> contactPayInvoice({
    required String slateId,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
    required lepic.ContactRelayMode relayMode,
  }) async {
    payments.add((
      slateId: slateId,
      amount: amount,
      minConf: minimumConfirmations,
      message: message,
    ));
    final invoice = waiting.where((i) => i.slateId == slateId).firstOrNull;
    if (invoice == null) {
      throw _lepicError(lepic.WalletErrorKind.invoiceNotFound);
    }
    if (invoice.amount != amount) {
      throw _lepicError(lepic.WalletErrorKind.amountMismatch);
    }
    if (payError != null) throw _lepicError(payError!);
    waiting.remove(invoice);
    stored.add(
      lepic.TransactionDetails(
        txId: 9,
        direction: lepic.TxDirection.outgoing,
        status: lepic.TxStatus.received,
        slateId: slateId,
        amountCredited: BigInt.zero,
        amountDebited: amount + BigInt.one,
        fee: BigInt.one,
        createdAtMs: 1790000000000,
        releasable: false,
        undelivered: false,
        messages: const [],
        flow: lepic.TxFlow.invoice,
        origin: lepic.TxOrigin.wallet,
        outputCommits: const [],
        spentCommits: const [],
        unverified: false,
        coinbase: false,
      ),
    );
    outbox.add(
      lepic.OutboxEntryView(
        id: BigInt.from(4),
        contactId: _shop,
        slateId: slateId,
        stage: lepic.SlateStage.i2,
        state: lepic.OutboxState.queued,
        attempts: 1,
        createdAtMs: 1790000000000,
        notPostedYet: false,
      ),
    );
    return lepic.PaidInvoice(
      txId: 9,
      slateId: slateId,
      amount: amount,
      fee: BigInt.one,
      format: lepic.SlateWire.native,
    );
  }

  @override
  Future<List<lepic.TransactionDetails>> transactions() async => [...stored];

  @override
  Future<List<lepic.OutboxEntryView>> contactOutbox({
    required String contactId,
  }) async => [...outbox.where((o) => o.contactId == contactId)];

  @override
  Future<lepic.SlateWire> contactOutboxResend({
    required BigInt id,
    required lepic.ContactRelayMode relayMode,
  }) async {
    resent.add(id);
    if (resendError != null) throw _lepicError(resendError!);
    return lepic.SlateWire.native;
  }

  @override
  Future<void> contactDeclineInvoice({required String slateId}) async {
    final before = waiting.length;
    waiting.removeWhere((i) => i.slateId == slateId);
    if (waiting.length == before) {
      throw _lepicError(lepic.WalletErrorKind.invoiceNotFound);
    }
    declined.add(slateId);
  }
}

lepic.WalletEvent _event(
  lepic.WalletEventKind kind, {
  String? slateId = 'inv-1',
  int? txId,
  String? kernelExcess,
}) => lepic.WalletEvent(
  kind: kind,
  slateId: slateId,
  txId: txId,
  kernelExcess: kernelExcess,
);

/// Lets the stand-in's events reach the session and its archive writes finish.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _InvoiceWallet wallet;
  late LepicWalletSession session;

  setUp(() {
    wallet = _InvoiceWallet();
    session = LepicWalletSession(wallet);
  });

  test('a LEPIC session handles invoices', () {
    expect(session.supportsInvoices, isTrue);
  });

  group('invoice events', () {
    test('the payer\'s events map, the issuer\'s are not shown', () {
      expect(
        lepicInvoiceEvent(_event(lepic.WalletEventKind.invoiceReceived)),
        const InvoiceEvent(kind: InvoiceEventKind.received, slateId: 'inv-1'),
      );
      expect(
        lepicInvoiceEvent(
          _event(
            lepic.WalletEventKind.invoicePosted,
            txId: 9,
            kernelExcess: '08ab',
          ),
        ),
        const InvoiceEvent(
          kind: InvoiceEventKind.posted,
          slateId: 'inv-1',
          kernelExcess: '08ab',
        ),
      );
      expect(
        lepicInvoiceEvent(_event(lepic.WalletEventKind.invoiceWithdrawn))?.kind,
        InvoiceEventKind.withdrawn,
      );
      expect(
        lepicInvoiceEvent(_event(lepic.WalletEventKind.invoiceExpired))?.kind,
        InvoiceEventKind.expired,
      );
      for (final e in [
        _event(lepic.WalletEventKind.invoiceExpired, txId: 3),
        _event(lepic.WalletEventKind.invoiceFinalized, txId: 3),
        _event(lepic.WalletEventKind.invoiceDeclined, txId: 3),
        _event(lepic.WalletEventKind.transaction, txId: 3),
        _event(lepic.WalletEventKind.invoiceReceived, slateId: null),
      ]) {
        expect(lepicInvoiceEvent(e), isNull, reason: e.kind.name);
      }
    });

    test('a contact\'s invoice raises one received notice', () async {
      final seen = <InvoiceEvent>[];
      final sub = session.invoiceEvents().listen(seen.add);
      wallet.eventSink.add(
        lepic.WalletEvent(
          kind: lepic.WalletEventKind.invoiceFromContact,
          slateId: 'inv-1',
          contactId: _shop,
          amount: BigInt.from(500),
        ),
      );
      await _settle();
      await sub.cancel();
      expect(seen, [
        const InvoiceEvent(kind: InvoiceEventKind.received, slateId: 'inv-1'),
      ]);
      expect(wallet.payments, isEmpty);
    });

    test('a slate this install does not know: a notice kind by stage, told once', () async {
      lepic.WalletEvent unknown(String stage) => lepic.WalletEvent(
        kind: lepic.WalletEventKind.unknownSlate,
        slateId: 'other-1',
        sender: 'esAnyoneKey@epicbox.example',
        slateStage: stage,
      );
      expect(
        lepicInvoiceEvent(unknown('I2'))?.kind,
        InvoiceEventKind.unknownInvoicePayment,
      );
      expect(
        lepicInvoiceEvent(unknown('S2'))?.kind,
        InvoiceEventKind.unknownSendAnswer,
      );
      final seen = <InvoiceEvent>[];
      final sub = session.invoiceEvents().listen(seen.add);
      // A relay that did not settle the message delivers it again.
      wallet.eventSink
        ..add(unknown('I2'))
        ..add(unknown('I2'));
      await _settle();
      await sub.cancel();
      expect(seen.map((e) => e.kind), [InvoiceEventKind.unknownInvoicePayment]);
      expect(wallet.payments, isEmpty);
      expect(wallet.declined, isEmpty);
    });

    test('a receipt is recorded before the app hears of it', () async {
      wallet.park('inv-1', BigInt.from(500));
      await session.payInvoice(slateId: 'inv-1', amount: BigInt.from(500));
      final seen = <PaidInvoice?>[];
      final sub = session.invoiceEvents().listen(
        (e) async => seen.add(await session.paidInvoice(slateId: e.slateId)),
      );
      wallet.eventSink.add(
        _event(
          lepic.WalletEventKind.invoicePosted,
          txId: 9,
          kernelExcess: '08ab',
        ),
      );
      await _settle();
      await sub.cancel();
      expect(seen.single?.status, InvoiceStatus.posted);
      expect(seen.single?.kernelExcess, '08ab');
    });

    test('a stuck answer marks the paid invoice, a delivered one clears it', () async {
      final s = LepicWalletSession(
        wallet..park('inv-1', BigInt.from(500)),
        history: WalletHistory.memory(),
      );
      await s.payInvoice(slateId: 'inv-1', amount: BigInt.from(500));
      s.invoiceEvents().listen((_) {});
      wallet.eventSink.add(_event(lepic.WalletEventKind.outboxStuck));
      await _settle();
      expect((await s.paidInvoice(slateId: 'inv-1'))?.status, InvoiceStatus.replyFailed);
      wallet.eventSink.add(_event(lepic.WalletEventKind.outboxDelivered));
      await _settle();
      expect((await s.paidInvoice(slateId: 'inv-1'))?.status, InvoiceStatus.replied);
      s.dispose();
    });

    test(
      'a withdrawal of a paid invoice marks it, and pays or cancels nothing',
      () async {
        wallet.park('inv-1', BigInt.from(500));
        await session.payInvoice(slateId: 'inv-1', amount: BigInt.from(500));
        final events = <InvoiceEvent>[];
        final sub = session.invoiceEvents().listen(events.add);
        wallet.eventSink.add(
          _event(lepic.WalletEventKind.invoiceWithdrawn, txId: 9),
        );
        await _settle();
        await sub.cancel();
        expect(events.single.kind, InvoiceEventKind.withdrawn);
        expect(
          (await session.paidInvoice(slateId: 'inv-1'))?.status,
          InvoiceStatus.withdrawn,
        );
        expect(wallet.payments, hasLength(1));
      },
    );

    test(
      'a withdrawal of an invoice this wallet never held raises no notice',
      () async {
        final events = <InvoiceEvent>[];
        final sub = session.invoiceEvents().listen(events.add);
        wallet.eventSink.add(
          _event(lepic.WalletEventKind.invoiceWithdrawn, slateId: 'other'),
        );
        await _settle();
        await sub.cancel();
        expect(events, isEmpty);
      },
    );

    test(
      'a withdrawal of a waiting invoice raises one notice, none after a decline',
      () async {
        wallet.park('inv-1', BigInt.from(500));
        wallet.park('inv-2', BigInt.from(500));
        await session.pendingInvoices();
        await session.declineInvoice(slateId: 'inv-2');
        final events = <InvoiceEvent>[];
        final sub = session.invoiceEvents().listen(events.add);
        wallet.eventSink.add(_event(lepic.WalletEventKind.invoiceWithdrawn));
        wallet.eventSink.add(
          _event(lepic.WalletEventKind.invoiceWithdrawn, slateId: 'inv-2'),
        );
        await _settle();
        await sub.cancel();
        expect(
          events
              .where((e) => e.kind == InvoiceEventKind.withdrawn)
              .map((e) => e.slateId),
          ['inv-1'],
        );
      },
    );

    test('no event leads to a payment', () async {
      wallet.park('inv-1', BigInt.from(500));
      final events = <InvoiceEvent>[];
      final sub = session.invoiceEvents().listen(events.add);
      for (final kind in lepic.WalletEventKind.values) {
        wallet.eventSink.add(_event(kind));
      }
      await session.collectInvoices();
      await _settle();
      await sub.cancel();
      expect(events, isNotEmpty);
      expect(wallet.payments, isEmpty);
      expect(wallet.waiting, hasLength(3));
    });
  });

  group('collect and pending', () {
    test(
      'a collect asks the contacts\' mailboxes, counts what arrived and sweeps',
      () async {
        expect(
          await session.collectInvoices(),
          const InvoiceCollectReport(parked: 2),
        );
        expect(wallet.collects, [lepic.CollectTrigger.open]);
        expect(wallet.expiries, [BigInt.from(86400)]);
      },
    );

    test('a failed sweep does not fail the collect', () async {
      wallet.sweepFails = true;
      expect((await session.collectInvoices()).parked, 2);
    });

    test('the background collect of the contacts\' mailboxes sweeps too', () async {
      await session.pairing.collect(trigger: PairingCollectTrigger.foreground);
      expect(wallet.collects, [lepic.CollectTrigger.foreground]);
      expect(wallet.expiries, [BigInt.from(86400)]);
    });

    test('waiting invoices name their contact, reference and times', () async {
      wallet.park('inv-1', BigInt.from(500), reference: 'order 42');
      expect(await session.pendingInvoices(), [
        PendingInvoice(
          slateId: 'inv-1',
          senderAddress: '',
          amount: BigInt.from(500),
          receivedAt: DateTime.fromMillisecondsSinceEpoch(1790000000000),
          expiresAt: DateTime.fromMillisecondsSinceEpoch(1790086400000),
          pairingId: _shop,
          reference: 'order 42',
        ),
      ]);
      final pending = (await session.pendingInvoices()).single;
      expect(pending.pairingId, _shop);
      expect(pending.reference, 'order 42');
    });
  });

  group('pay, decline and resend', () {
    test(
      'a matching amount pays with the balance\'s confirmations and no message',
      () async {
        wallet.balanceConfirmations = BigInt.from(3);
        wallet.park('inv-1', BigInt.from(500));
        final paid = await session.payInvoice(
          slateId: 'inv-1',
          amount: BigInt.from(500),
        );
        expect(
          paid,
          PaidInvoice(
            slateId: 'inv-1',
            senderAddress: '',
            amount: BigInt.from(500),
            status: InvoiceStatus.replied,
            txId: 9,
          ),
        );
        expect(paid.pairingId, _shop);
        expect(wallet.payments.single.minConf, BigInt.from(3));
        expect(wallet.payments.single.message, isNull);
        final again = await session.paidInvoice(slateId: 'inv-1');
        expect(again, paid);
        expect(again?.pairingId, _shop);
      },
    );

    test('a wrong amount is refused and nothing is recorded', () async {
      wallet.park('inv-1', BigInt.from(500));
      await expectLater(
        session.payInvoice(slateId: 'inv-1', amount: BigInt.from(499)),
        throwsA(
          isA<WalletError>().having(
            (e) => e.kind,
            'kind',
            WalletErrorKind.amountMismatch,
          ),
        ),
      );
      expect(await session.paidInvoice(slateId: 'inv-1'), isNull);
      expect(wallet.waiting, hasLength(1));
    });

    test('an unknown invoice never reaches LEPIC\'s pay', () async {
      await expectLater(
        session.payInvoice(slateId: 'nope', amount: BigInt.one),
        throwsA(isA<WalletError>()),
      );
      expect(wallet.payments, isEmpty);
    });

    test('a contact no longer trusted is refused', () async {
      wallet
        ..park('inv-1', BigInt.from(500))
        ..payError = lepic.WalletErrorKind.contactNotVerified;
      await expectLater(
        session.payInvoice(slateId: 'inv-1', amount: BigInt.from(500)),
        throwsA(isA<WalletError>()),
      );
      expect(await session.paidInvoice(slateId: 'inv-1'), isNull);
    });

    test('Send again posts the outbox entry once more, never pays again', () async {
      wallet.park('inv-1', BigInt.from(500));
      await session.payInvoice(slateId: 'inv-1', amount: BigInt.from(500));

      wallet.resendError = lepic.WalletErrorKind.transportFailed;
      await expectLater(
        session.resendInvoiceReply(slateId: 'inv-1'),
        throwsA(
          isA<WalletError>().having(
            (e) => e.kind,
            'kind',
            WalletErrorKind.transportFailed,
          ),
        ),
      );

      wallet.resendError = null;
      final resent = await session.resendInvoiceReply(slateId: 'inv-1');
      expect(resent.status, InvoiceStatus.replied);
      await session.resendInvoiceReply(slateId: 'inv-1');
      expect(wallet.resent, [BigInt.from(4), BigInt.from(4), BigInt.from(4)]);
      expect(wallet.payments, hasLength(1));
    });

    test('a decline reaches LEPIC and is reported', () async {
      wallet.park('inv-1', BigInt.from(500));
      final events = <InvoiceEvent>[];
      final sub = session.invoiceEvents().listen(events.add);
      await session.declineInvoice(slateId: 'inv-1');
      await _settle();
      await sub.cancel();
      expect(wallet.declined, ['inv-1']);
      expect(
        events.single,
        const InvoiceEvent(kind: InvoiceEventKind.declined, slateId: 'inv-1'),
      );
      expect(wallet.payments, isEmpty);
    });
  });

  group('the history archive', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('wfe-invoice-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('a paid invoice survives a reopen', () async {
      final s = LepicWalletSession(
        wallet..park('inv-1', BigInt.from(500)),
        history: await WalletHistory.open(dir.path, Chain.floonet),
      );
      final paid = await s.payInvoice(
        slateId: 'inv-1',
        amount: BigInt.from(500),
      );
      expect(paid.format, SlateFormat.native);
      s.dispose();
      // LEPIC's store outlives the app; the archive adds the reply's state.
      final reopened = LepicWalletSession(
        wallet,
        history: await WalletHistory.open(dir.path, Chain.floonet),
      );
      expect(await reopened.paidInvoice(slateId: 'inv-1'), paid);
      reopened.dispose();
    });
  });
}
