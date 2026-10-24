// The LEPIC adapter's invoice calls over a stand-in `EpicWallet` that keeps the invoice
// address, allowlist and waiting invoices as LEPIC does. No native library is loaded.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _payments = 'ownKey0@epicbox.example';
const _shop = 'shopKey@epicbox.example';

lepic.WalletError _lepicError(lepic.WalletErrorKind kind) =>
    lepic.WalletError(kind: kind, code: 0, message: kind.name);

/// LEPIC's invoice half in memory. Fails any other native call.
class _InvoiceWallet implements lepic.EpicWallet {
  int index = 1;
  final List<lepic.InvoiceSender> senders = [];
  final List<lepic.IncomingInvoice> waiting = [];
  final List<lepic.TransactionDetails> stored = [];
  final StreamController<lepic.WalletEvent> eventSink =
      StreamController<lepic.WalletEvent>.broadcast();

  /// Every `payInvoice` that reached LEPIC, with its arguments.
  final List<({String slateId, BigInt amount, BigInt minConf, String? message})>
  payments = [];
  final List<int> resent = [];
  final List<String> declined = [];
  final List<BigInt?> expiries = [];
  lepic.WalletErrorKind? payError;
  lepic.WalletErrorKind? resendError;
  lepic.WalletErrorKind? indexError;
  bool sweepFails = false;

  void park(String slateId, BigInt amount, {String? message}) => waiting.add(
    lepic.IncomingInvoice(
      slateId: slateId,
      senderAddress: _shop,
      amount: amount,
      message: message,
      receivedAtMs: 1790000000000,
      expiresAtMs: 1790086400000,
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

  @override
  Future<String> epicboxAddress() async => _payments;

  @override
  Future<String> invoiceAddress() async => 'ownKey$index@epicbox.example';

  @override
  Future<int> invoiceAddressIndex() async {
    if (indexError != null) throw _lepicError(indexError!);
    return index;
  }

  @override
  Future<void> setInvoiceAddressIndex({required int index}) async =>
      this.index = index;

  @override
  Future<String> rotateInvoiceAddress() async {
    index++;
    return invoiceAddress();
  }

  @override
  Future<List<lepic.InvoiceSender>> invoiceSenders() async => [...senders];

  @override
  Future<lepic.InvoiceSender> allowInvoiceSender({
    required String address,
    required String label,
  }) async {
    final key = address.split('@').first;
    senders.removeWhere((s) => s.address.split('@').first == key);
    final s = lepic.InvoiceSender(
      address: address,
      label: label,
      addedAtMs: 1790000000000,
    );
    senders.add(s);
    return s;
  }

  @override
  Future<bool> removeInvoiceSender({required String address}) async {
    final key = address.split('@').first;
    final before = senders.length;
    senders.removeWhere((s) => s.address.split('@').first == key);
    return senders.length < before;
  }

  @override
  Future<lepic.InvoiceReport> drainInvoices() async =>
      const lepic.InvoiceReport(
        parked: 2,
        finalized: 0,
        repeated: 1,
        rejected: 0,
        held: 0,
        dropped: 3,
        notices: 1,
        bounced: 0,
      );

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
  Future<List<lepic.IncomingInvoice>> pendingInvoices({
    BigInt? expirySecs,
  }) async {
    expiries.add(expirySecs);
    return [...waiting];
  }

  @override
  Future<lepic.PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
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
    waiting.remove(invoice);
    stored.add(
      lepic.TransactionDetails(
        txId: 9,
        direction: lepic.TxDirection.outgoing,
        status: lepic.TxStatus.received,
        slateId: slateId,
        counterparty: invoice.senderAddress,
        amountCredited: BigInt.zero,
        amountDebited: amount + BigInt.one,
        fee: BigInt.one,
        createdAtMs: 1790000000000,
        releasable: false,
        undelivered: false,
        messages: [
          if (invoice.message case final text?)
            lepic.SlateMessage(role: lepic.SlateRole.receiver, text: text),
        ],
        flow: lepic.TxFlow.invoice,
        origin: lepic.TxOrigin.wallet,
        outputCommits: const [],
      ),
    );
    if (payError != null) throw _lepicError(payError!);
    return lepic.PaidInvoice(
      txId: 9,
      slateId: slateId,
      amount: amount,
      fee: BigInt.one,
    );
  }

  @override
  Future<List<lepic.TransactionDetails>> transactions() async => [...stored];

  @override
  Future<void> resendInvoicePayment({required int txId}) async {
    resent.add(txId);
    if (resendError != null) throw _lepicError(resendError!);
  }

  @override
  Future<void> declineInvoice({required String slateId}) async {
    final before = waiting.length;
    waiting.removeWhere((i) => i.slateId == slateId);
    if (waiting.length == before) {
      throw _lepicError(lepic.WalletErrorKind.invoiceNotFound);
    }
    declined.add(slateId);
  }
}

/// A restored wallet whose history file opens to [payload].
class _ImportingWallet extends _InvoiceWallet {
  _ImportingWallet(this.payload);

  final Uint8List payload;

  @override
  Future<Uint8List> openAppData({required List<int> file}) async => payload;
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
      await session.drainInvoices();
      await _settle();
      await sub.cancel();
      expect(events, isNotEmpty);
      expect(wallet.payments, isEmpty);
      expect(wallet.waiting, hasLength(1));
    });
  });

  group('drain and pending', () {
    test(
      'a drain reports LEPIC\'s counts and sweeps with the app\'s expiry',
      () async {
        expect(
          await session.drainInvoices(),
          const InvoiceDrainReport(parked: 2, dropped: 3, notices: 1),
        );
        expect(wallet.expiries, [BigInt.from(86400)]);
      },
    );

    test('a failed sweep does not fail the drain', () async {
      wallet.sweepFails = true;
      expect((await session.drainInvoices()).parked, 2);
    });

    test('waiting invoices keep their fields and times', () async {
      wallet.park('inv-1', BigInt.from(500), message: 'order 42');
      expect(await session.pendingInvoices(), [
        PendingInvoice(
          slateId: 'inv-1',
          senderAddress: _shop,
          amount: BigInt.from(500),
          message: 'order 42',
          receivedAt: DateTime.fromMillisecondsSinceEpoch(1790000000000),
          expiresAt: DateTime.fromMillisecondsSinceEpoch(1790086400000),
        ),
      ]);
      expect(wallet.expiries, [BigInt.from(86400)]);
    });
  });

  group('pay, decline and resend', () {
    test(
      'a matching amount pays with the balance\'s confirmations and no message',
      () async {
        wallet.balanceConfirmations = BigInt.from(3);
        wallet.park('inv-1', BigInt.from(500), message: 'order 42');
        final paid = await session.payInvoice(
          slateId: 'inv-1',
          amount: BigInt.from(500),
        );
        expect(
          paid,
          PaidInvoice(
            slateId: 'inv-1',
            senderAddress: _shop,
            amount: BigInt.from(500),
            message: 'order 42',
            status: InvoiceStatus.replied,
            txId: 9,
          ),
        );
        expect(wallet.payments.single.minConf, BigInt.from(3));
        expect(wallet.payments.single.message, isNull);
        expect(await session.paidInvoice(slateId: 'inv-1'), paid);
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

    test(
      'an undelivered reply is kept, then resent without paying again',
      () async {
        wallet
          ..park('inv-1', BigInt.from(500))
          ..payError = lepic.WalletErrorKind.notDelivered;
        final paid = await session.payInvoice(
          slateId: 'inv-1',
          amount: BigInt.from(500),
        );
        expect(paid.status, InvoiceStatus.replyFailed);
        expect(paid.txId, 9);

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
        expect(
          (await session.paidInvoice(slateId: 'inv-1'))?.status,
          InvoiceStatus.replyFailed,
        );

        wallet.resendError = null;
        final resent = await session.resendInvoiceReply(slateId: 'inv-1');
        expect(resent.status, InvoiceStatus.replied);
        expect(wallet.resent, [9, 9]);
        // Delivered but not posted yet: Send again sends the same reply once more (linux-12),
        // and never pays a second time.
        await session.resendInvoiceReply(slateId: 'inv-1');
        expect(wallet.resent, [9, 9, 9]);
        expect(wallet.payments, hasLength(1));
      },
    );

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

  group('trusted services', () {
    test(
      'LEPIC gets the address and a short label, the app keeps its own',
      () async {
        final long = 'Shop ${'x' * 80}';
        final added = await session.addTrustedService(
          address: ' $_shop ',
          label: long,
        );
        final since = DateTime.fromMillisecondsSinceEpoch(1790000000000);
        expect(added, TrustedService(address: _shop, label: long, since: since));
        expect(wallet.senders.single.address, _shop);
        expect(wallet.senders.single.label.length, 64);
        expect(await session.trustedServices(), [
          TrustedService(address: _shop, label: long, since: since),
        ]);
      },
    );

    test('LEPIC\'s label stands in when the app lost its own', () async {
      wallet.senders.add(
        const lepic.InvoiceSender(address: _shop, label: 'Shop', addedAtMs: 0),
      );
      expect(await session.trustedServices(), [
        TrustedService(
          address: _shop,
          label: 'Shop',
          since: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ]);
    });

    test('the same key at another relay replaces the entry', () async {
      await session.addTrustedService(address: _shop, label: 'Shop');
      await session.addTrustedService(
        address: 'shopKey@other.example',
        label: 'Shop 2',
      );
      expect(await session.trustedServices(), [
        TrustedService(
          address: 'shopKey@other.example',
          label: 'Shop 2',
          since: DateTime.fromMillisecondsSinceEpoch(1790000000000),
        ),
      ]);
    });

    test('the wallet\'s own addresses are refused', () async {
      for (final own in [_payments, 'ownKey1@epicbox.example']) {
        await expectLater(
          session.addTrustedService(address: own, label: 'me'),
          throwsA(
            isA<WalletError>().having(
              (e) => e.kind,
              'kind',
              WalletErrorKind.invalidArgument,
            ),
          ),
        );
      }
      expect(wallet.senders, isEmpty);
    });

    test('remove drops the sender and its label', () async {
      await session.addTrustedService(address: _shop, label: 'Shop');
      await session.removeTrustedService(address: _shop);
      expect(wallet.senders, isEmpty);
      expect(await session.trustedServices(), isEmpty);
    });
  });

  group('the invoice index', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('wfe-invoice-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test(
      'a rotation is kept in wfe_meta.json and given back after a restore',
      () async {
        final history = await WalletHistory.open(dir.path, Chain.floonet);
        final first = LepicWalletSession(wallet, history: history);
        expect(await first.rotateInvoiceAddress(), 'ownKey2@epicbox.example');
        expect(await first.rotateInvoiceAddress(), 'ownKey3@epicbox.example');
        first.dispose();

        // A restore from the phrase: LEPIC starts at 1 again.
        final restored = _InvoiceWallet();
        final again = LepicWalletSession(
          restored,
          history: await WalletHistory.open(dir.path, Chain.floonet),
        );
        await again.restoreInvoiceIndex();
        expect(restored.index, 3);
        expect(await again.invoiceAddress(), 'ownKey3@epicbox.example');
        again.dispose();
      },
    );

    test('LEPIC ahead of the archive is recorded', () async {
      final history = await WalletHistory.open(dir.path, Chain.floonet);
      wallet.index = 4;
      final s = LepicWalletSession(wallet, history: history);
      await s.restoreInvoiceIndex();
      expect(history.invoiceIndex, 4);
      s.dispose();
    });

    test('opening a wallet gives LEPIC the kept index', () async {
      final history = await WalletHistory.open(dir.path, Chain.floonet);
      await history.setInvoiceIndex(3);
      history.close();
      final restored = _InvoiceWallet();
      final s = await LepicWalletSession.openOn(
        restored,
        dir.path,
        Chain.floonet,
      );
      expect(restored.index, 3);
      s.dispose();
    });

    test('importing a history file gives LEPIC its index', () async {
      final payload = HistoryPayload(
        chain: chainName(Chain.floonet),
        walletFp: walletFingerprint(_payments),
        exportedAtUnix: 1790000000,
        appVersion: historyAppVersion,
        invoiceIndex: 3,
      );
      final restored = _ImportingWallet(Uint8List.fromList(payload.encode()));
      final s = LepicWalletSession(
        restored,
        history: await WalletHistory.open(dir.path, Chain.floonet),
      );
      await s.importHistory(data: Uint8List.fromList([1, 2, 3]));
      expect(restored.index, 3);
      s.dispose();
    });

    test('without a relay the wallet still opens', () async {
      wallet.indexError = lepic.WalletErrorKind.unsupported;
      await session.restoreInvoiceIndex();
    });

    test('a paid invoice survives a reopen', () async {
      final s = LepicWalletSession(
        wallet..park('inv-1', BigInt.from(500), message: 'order 42'),
        history: await WalletHistory.open(dir.path, Chain.floonet),
      );
      final paid = await s.payInvoice(
        slateId: 'inv-1',
        amount: BigInt.from(500),
      );
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

  test('a sender label for LEPIC has no control characters', () {
    expect(lepicSenderLabel(' a\u0000b\nc '), 'a b c');
    expect(lepicSenderLabel('é' * 40).length, 32);
  });
}
