// Invoices on the desktop's LEPIC adapter: LepicDeskWallet over the real LepicWalletSession on
// a stand-in `EpicWallet` that keeps the invoice address, trusted list, waiting invoices and
// transactions as LEPIC does. No native library is loaded; the password is a test value.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/data/invoice_scheduler.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show DeskError, OutputWord;
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _password = 'test-pass-1234';
const _payments = 'esOwnPaymentsKey@epicbox.example';
const _shop = 'esShopKey@epicbox.example';
const _shopElsewhere = 'esShopKey@other.relay';
const _payer = 'esPayerInvoiceKey@epicbox.example';

lepic.WalletError _lepicError(lepic.WalletErrorKind kind) => lepic.WalletError(kind: kind, code: 0, message: kind.name);

lepic.TransactionDetails _tx({
  required int txId,
  required String slateId,
  required lepic.TxDirection direction,
  required lepic.TxStatus status,
  required String counterparty,
  BigInt? credited,
  BigInt? debited,
  BigInt? confirmedHeight,
  bool releasable = false,
}) => lepic.TransactionDetails(
  txId: txId,
  direction: direction,
  status: status,
  slateId: slateId,
  counterparty: counterparty,
  amountCredited: credited ?? BigInt.zero,
  amountDebited: debited ?? BigInt.zero,
  fee: direction == lepic.TxDirection.outgoing ? BigInt.from(100) : null,
  createdAtMs: 1790000000000,
  confirmedHeight: confirmedHeight,
  releasable: releasable,
  messages: const [],
  flow: lepic.TxFlow.invoice,
  origin: lepic.TxOrigin.wallet,
  transport: 'epicbox',
);

/// LEPIC's wallet in memory: the invoice half, transactions and a summary. Fails any other call.
class _Wallet implements lepic.EpicWallet {
  final List<lepic.InvoiceSender> senders = [];
  final List<lepic.IncomingInvoice> waiting = [];
  final List<lepic.TransactionDetails> stored = [];
  final StreamController<lepic.WalletEvent> events$ = StreamController<lepic.WalletEvent>.broadcast();
  final List<String> paid = [];
  final List<int> cancelled = [];
  int invoiceDrains = 0;
  int paymentDrains = 0;
  BigInt awaitingFinalization = BigInt.zero;
  lepic.WalletErrorKind? drainError;

  /// When set, a cancel is refused with it after the node check (in the pool, unreachable).
  lepic.WalletErrorKind? cancelError;

  void park(String slateId, int amount, {String from = _shopElsewhere, String? message}) => waiting.add(
    lepic.IncomingInvoice(
      slateId: slateId,
      senderAddress: from,
      amount: BigInt.from(amount),
      message: message,
      receivedAtMs: 1790000000000,
      expiresAtMs: DateTime.now().add(const Duration(hours: 20)).millisecondsSinceEpoch,
    ),
  );

  @override
  bool get isDisposed => false;
  @override
  void lock() {}
  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => events$.stream;

  @override
  Future<lepic.WalletSummary> summary({required bool refresh}) async => lepic.WalletSummary(
    lastConfirmedHeight: BigInt.from(100),
    minimumConfirmations: BigInt.from(3),
    total: BigInt.from(1000),
    spendable: BigInt.from(1000),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: awaitingFinalization,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: false,
  );

  @override
  Future<List<lepic.TransactionDetails>> transactions() async => [...stored];

  @override
  Stream<lepic.RefreshProgress> refresh() async* {
    yield lepic.RefreshProgress(percent: 100, message: 'done', summary: await summary(refresh: false));
  }

  @override
  Future<String> mnemonic({required String password}) async {
    if (password != _password) throw _lepicError(lepic.WalletErrorKind.wrongPassword);
    return 'words';
  }

  @override
  Future<String> epicboxAddress() async => _payments;
  @override
  Future<String> invoiceAddress() async => 'esOwnInvoiceKey@epicbox.example';
  @override
  Future<int> invoiceAddressIndex() async => 1;

  @override
  Future<List<lepic.InvoiceSender>> invoiceSenders() async => [...senders];

  @override
  Future<lepic.InvoiceSender> allowInvoiceSender({required String address, required String label}) async {
    final s = lepic.InvoiceSender(address: address, label: label, addedAtMs: 1790000000000);
    senders
      ..removeWhere((x) => x.address.split('@').first == address.split('@').first)
      ..add(s);
    return s;
  }

  @override
  Future<lepic.InvoiceReport> drainInvoices() async {
    invoiceDrains++;
    if (drainError != null) throw _lepicError(drainError!);
    return const lepic.InvoiceReport(parked: 0, finalized: 0, repeated: 0, rejected: 0, held: 0, dropped: 2, notices: 0, bounced: 0);
  }

  @override
  Future<lepic.InboxReport> drainEpicbox() async {
    paymentDrains++;
    return const lepic.InboxReport(received: 0, finalized: 0, repeated: 0, rejected: 0, held: 0, notices: 0, bounced: 0, dropped: 0);
  }

  @override
  Future<lepic.InvoiceSweep> sweepInvoices({BigInt? expirySecs}) async =>
      lepic.InvoiceSweep(deleted: const [], cancelled: Uint32List(0), cancellable: Uint32List(0));

  @override
  Future<List<lepic.IncomingInvoice>> pendingInvoices({BigInt? expirySecs}) async => [...waiting];

  int feeEstimates = 0;

  @override
  Future<lepic.FeeEstimate> estimateFee({required BigInt amount, required BigInt minimumConfirmations, lepic.SendOptions? options}) async {
    feeEstimates++;
    return lepic.FeeEstimate(amount: amount, fee: BigInt.from(700000), inputCount: 1, change: BigInt.zero, locked: amount + BigInt.from(700000), changeOutputs: 1);
  }

  @override
  Future<lepic.PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
  }) async {
    paid.add(slateId);
    final invoice = waiting.firstWhere((i) => i.slateId == slateId, orElse: () => throw _lepicError(lepic.WalletErrorKind.invoiceNotFound));
    waiting.remove(invoice);
    stored.add(
      _tx(txId: 9, slateId: slateId, direction: lepic.TxDirection.outgoing, status: lepic.TxStatus.received, counterparty: invoice.senderAddress, debited: amount + BigInt.from(100)),
    );
    return lepic.PaidInvoice(txId: 9, slateId: slateId, amount: amount, fee: BigInt.from(100));
  }

  /// Outputs: [lockedBy] coins locked by the payment with that tx id.
  final Map<String, int> lockedBy = {};
  final List<List<String>> spentToSelf = [];

  @override
  Future<List<lepic.WalletOutput>> outputs() async => [
    for (final MapEntry(key: commitment, value: txId) in lockedBy.entries)
      lepic.WalletOutput(
        commitment: commitment,
        value: BigInt.from(20000),
        status: lepic.OutputStatus.locked,
        category: lepic.OutputCategory.locked,
        isCoinbase: false,
        height: BigInt.from(50),
        lockHeight: BigInt.zero,
        confirmations: BigInt.from(51),
        txId: txId,
      ),
  ];

  @override
  Future<lepic.SelfSentTx> spendOutputsToSelf({required List<String> commitments, required BigInt minimumConfirmations}) async {
    spentToSelf.add([...commitments]);
    return lepic.SelfSentTx(txId: 20, receivedTxId: 21, amount: BigInt.from(19000), fee: BigInt.from(1000), inputCount: commitments.length, outputCount: 1);
  }

  @override
  Future<void> cancelTransaction({required int txId}) async {
    if (cancelError != null) throw _lepicError(cancelError!);
    cancelled.add(txId);
    final i = stored.indexWhere((t) => t.txId == txId);
    if (i < 0) return;
    final t = stored[i];
    stored[i] = _tx(
      txId: t.txId,
      slateId: t.slateId!,
      direction: t.direction,
      status: lepic.TxStatus.cancelled,
      counterparty: t.counterparty!,
      credited: t.amountCredited,
      debited: t.amountDebited,
    );
  }
}

/// Opens a [LepicWalletSession] on the stand-in for every unlock.
class _Service extends core.FakeWalletService {
  _Service(this.lepicWallet) : super(password: _password);

  final _Wallet lepicWallet;
  LepicWalletSession? opened;

  @override
  Future<core.WalletSession> open({required core.WalletConfig config, required String password}) async {
    await super.open(config: config, password: password);
    return opened = LepicWalletSession(lepicWallet, validateAddress: (_) => true);
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  group('states', () {
    core.TxEntry entry(lepic.TxStatus status, {lepic.TxDirection direction = lepic.TxDirection.outgoing, int? height, bool releasable = false}) =>
        lepicTxEntry(_tx(txId: 1, slateId: 's', direction: direction, status: status, counterparty: _shop, credited: BigInt.from(5), confirmedHeight: height == null ? null : BigInt.from(height), releasable: releasable));

    test('a paid invoice: every row of flow §4.4', () {
      PayState of(core.TxEntry e, core.InvoiceStatus s) => payState(e, s, tip: 100, minConf: 3);
      expect(of(entry(lepic.TxStatus.received), core.InvoiceStatus.replyFailed), PayState.notDelivered);
      expect(of(entry(lepic.TxStatus.received), core.InvoiceStatus.replied), PayState.delivered);
      expect(of(entry(lepic.TxStatus.received), core.InvoiceStatus.posted), PayState.posted);
      expect(of(entry(lepic.TxStatus.posted, height: 99), core.InvoiceStatus.posted), PayState.confirming);
      expect(of(entry(lepic.TxStatus.confirmed, height: 90), core.InvoiceStatus.posted), PayState.completed);
      expect(of(entry(lepic.TxStatus.received), core.InvoiceStatus.withdrawn), PayState.withdrawnAfterPay);
      expect(of(entry(lepic.TxStatus.received, releasable: true), core.InvoiceStatus.replied), PayState.pastTtl);
      expect(of(entry(lepic.TxStatus.cancelled), core.InvoiceStatus.withdrawn), PayState.cancelled);
    });

    test('an issued invoice: every row of flow §3.3', () {
      RequestState of(core.IssuedInvoiceState s, [core.TxEntry? e]) => requestState(s, e, tip: 100, minConf: 3);
      final incoming = lepic.TxDirection.incoming;
      expect(of(core.IssuedInvoiceState.waiting), RequestState.waiting);
      expect(of(core.IssuedInvoiceState.paid), RequestState.paid);
      expect(of(core.IssuedInvoiceState.paid, entry(lepic.TxStatus.posted, direction: incoming)), RequestState.confirming);
      expect(of(core.IssuedInvoiceState.paid, entry(lepic.TxStatus.posted, direction: incoming, height: 99)), RequestState.confirming);
      expect(of(core.IssuedInvoiceState.paid, entry(lepic.TxStatus.confirmed, direction: incoming, height: 90)), RequestState.completed);
      expect(of(core.IssuedInvoiceState.paid, entry(lepic.TxStatus.finalized, direction: incoming)), RequestState.notPosted);
      expect(of(core.IssuedInvoiceState.paid, entry(lepic.TxStatus.cancelled, direction: incoming)), RequestState.cancelled);
      expect(of(core.IssuedInvoiceState.declined), RequestState.declined);
      expect(of(core.IssuedInvoiceState.expired), RequestState.expired);
      expect(of(core.IssuedInvoiceState.withdrawn), RequestState.withdrawn);
      expect(of(core.IssuedInvoiceState.bounced), RequestState.bounced);
    });

    test('an unpaid invoice\'s output: its own word, in no part of the balance', () {
      final o = deskOutput(
        core.WalletOutput(
          commitment: 'c',
          value: BigInt.from(7000),
          status: core.WalletOutputStatus.unconfirmed,
          category: core.OutputCategory.unpaidInvoice,
          isCoinbase: false,
          height: BigInt.zero,
          lockHeight: BigInt.zero,
          confirmations: BigInt.zero,
        ),
        minConf: 3,
      );
      expect(o.word, OutputWord.unpaidInvoice);
      expect(o.spendable, isFalse);
      expect(lepicWalletOutput(
        lepic.WalletOutput(
          commitment: 'c',
          value: BigInt.one,
          status: lepic.OutputStatus.unconfirmed,
          category: lepic.OutputCategory.unpaidInvoice,
          isCoinbase: false,
          height: BigInt.zero,
          lockHeight: BigInt.zero,
          confirmations: BigInt.zero,
        ),
      ).category, core.OutputCategory.unpaidInvoice);
    });

    test('errors in the screens\' terms', () {
      InvoiceProblem of(core.WalletErrorKind k, {bool issuing = false}) => invoiceError(core.WalletError(kind: k, message: ''), issuing: issuing).problem;
      expect(of(core.WalletErrorKind.wrongPassword), InvoiceProblem.wrongPassword);
      expect(of(core.WalletErrorKind.transportFailed), InvoiceProblem.relayDown);
      expect(of(core.WalletErrorKind.transportFailed, issuing: true), InvoiceProblem.notDelivered);
      expect(of(core.WalletErrorKind.nodeUnreachable), InvoiceProblem.nodeDown);
      expect(of(core.WalletErrorKind.paymentExpired), InvoiceProblem.expired);
      expect(of(core.WalletErrorKind.invoiceNotFound), InvoiceProblem.alreadyAnswered);
      expect(of(core.WalletErrorKind.amountMismatch), InvoiceProblem.amountMismatch);
      expect(of(core.WalletErrorKind.invoiceAlreadyPaid), InvoiceProblem.alreadyAnswered);
      expect(of(core.WalletErrorKind.invoiceLockedAboveTip), InvoiceProblem.lockedAboveTip);
      expect(of(core.WalletErrorKind.invoiceChanged), InvoiceProblem.invalid);
      expect(of(core.WalletErrorKind.invalidSlate), InvoiceProblem.invalid);
    });
  });

  group('on a wallet', () {
    late Directory support;
    late _Wallet lepicWallet;
    late _Service service;
    late LepicDeskWallet wallet;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-invoices-test-');
      lepicWallet = _Wallet()..senders.add(lepic.InvoiceSender(address: _shop, label: 'Shop', addedAtMs: 1790000000000));
      service = _Service(lepicWallet);
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final dir = Directory('${support.path}/wallets/${chain.name}');
          await dir.create(recursive: true);
          return dir.path;
        },
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        invoicesEvery: const Duration(milliseconds: 40),
        paymentsEvery: const Duration(milliseconds: 40),
        invoiceFocus: false,
      );
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      await _settle();
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    test('a waiting invoice reads as one to pay: the trusted label and stored address, the fee', () async {
      lepicWallet.park('inv-1', 12000, message: 'Order\u202e 42\nthanks');
      final book = await wallet.invoices();
      final i = book.invoice('inv-1')!;
      expect(i.state, PayState.waiting);
      expect(i.label, 'Shop', reason: 'from the trusted list by key, never the invoice');
      expect(i.senderAddress, _shop, reason: 'the stored address, not the relay part it came from');
      expect(i.fee, 700000);
      expect(i.message, 'Order 42 thanks');
      expect(book.waiting.single.slateId, 'inv-1');
      expect(book.trusted.single.label, 'Shop');
      expect(book.trusted.single.since, DateTime.fromMillisecondsSinceEpoch(1790000000000));
      expect(book.invoiceAddress, 'esOwnInvoiceKey@epicbox.example');
      await wallet.invoices();
      expect(lepicWallet.feeEstimates, 1, reason: 'a read does not estimate the fee again');
      expect(book.invoiceIndex, 1, reason: 'from LEPIC; Settings asks a restored wallet to hand it out again');
    });

    test('pay: a wrong password pays nothing; the right one pays the invoice\'s own amount once', () async {
      lepicWallet.park('inv-1', 12000);
      await wallet.invoices();
      await expectLater(
        wallet.payInvoice('inv-1', amount: 12000, password: 'wrong-pass-1'),
        throwsA(isA<InvoiceError>().having((e) => e.problem, 'problem', InvoiceProblem.wrongPassword)),
      );
      expect(lepicWallet.paid, isEmpty);
      final paid = await wallet.payInvoice('inv-1', amount: 12000, password: _password);
      expect(lepicWallet.paid, ['inv-1']);
      expect(paid.state, PayState.delivered);
      expect(paid.label, 'Shop');
      await expectLater(
        wallet.payInvoice('inv-1', amount: 12000, password: _password),
        throwsA(isA<InvoiceError>().having((e) => e.problem, 'problem', InvoiceProblem.alreadyAnswered)),
      );
      final book = await wallet.invoices();
      expect(book.waiting, isEmpty);
      expect(book.invoice('inv-1')!.state, PayState.delivered);
      final tx = (await wallet.transactions()).single;
      expect(tx.isInvoice, isTrue);
      expect(tx.incoming, isFalse, reason: 'an invoice paid is money going out (P-1)');
    });

    test('a bounce withdraws the issued invoice once and tells once', () async {
      lepicWallet.stored.add(_tx(txId: 5, slateId: 'req-1', direction: lepic.TxDirection.incoming, status: lepic.TxStatus.received, counterparty: _payer, credited: BigInt.from(7000)));
      final notices = <InvoiceNotice>[];
      final sub = wallet.invoiceNotices().listen(notices.add);
      addTearDown(sub.cancel);
      expect((await wallet.invoices()).sent.single.state, RequestState.waiting);
      for (var n = 0; n < 2; n++) {
        lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.invoiceBounced, slateId: 'req-1'));
        await _settle();
      }
      expect(lepicWallet.cancelled, [5]);
      expect(notices.map((n) => n.kind), [InvoiceNoticeKind.bounced]);
      expect(notices.single.amount, 7000);
      expect((await wallet.invoices()).sent.single.state, RequestState.bounced);
    });

    test('a decline withdraws the issued invoice and tells', () async {
      lepicWallet.stored.add(_tx(txId: 5, slateId: 'req-1', direction: lepic.TxDirection.incoming, status: lepic.TxStatus.received, counterparty: _payer, credited: BigInt.from(7000)));
      final notices = <InvoiceNotice>[];
      final sub = wallet.invoiceNotices().listen(notices.add);
      addTearDown(sub.cancel);
      await wallet.invoices();
      lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.invoiceDeclined, slateId: 'req-1'));
      await _settle();
      expect(lepicWallet.cancelled, [5]);
      expect(notices.map((n) => n.kind), [InvoiceNoticeKind.declined]);
      expect((await wallet.invoices()).sent.single.state, RequestState.declined);
    });

    test('a service withdrawing a waiting invoice: it leaves To pay and a notice names the label', () async {
      lepicWallet.park('inv-1', 12000);
      final notices = <InvoiceNotice>[];
      final sub = wallet.invoiceNotices().listen(notices.add);
      addTearDown(sub.cancel);
      await wallet.invoices();
      lepicWallet.waiting.clear();
      lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.invoiceWithdrawn, slateId: 'inv-1'));
      await _settle();
      expect(notices.single.kind, InvoiceNoticeKind.withdrawn);
      expect(notices.single.who, 'Shop');
      final book = await wallet.invoices();
      expect(book.waiting, isEmpty);
      expect(book.invoice('inv-1')!.state, PayState.withdrawn);
    });

    test('Overview: an unpaid issued invoice is in no figure; LEPIC\'s own count shows as it is', () async {
      lepicWallet
        ..awaitingFinalization = BigInt.from(300)
        ..stored.add(_tx(txId: 5, slateId: 'req-1', direction: lepic.TxDirection.incoming, status: lepic.TxStatus.received, counterparty: _payer, credited: BigInt.from(7000)));
      await wallet.sync();
      final b = await wallet.balance();
      expect(b.awaitingFinalization, 300);
      expect(b.reportedTotal, 1000, reason: 'LEPIC\'s total has no awaiting finalization');
      final row = (await wallet.transactions()).single;
      expect(row.isInvoice, isTrue);
    });

    test('the scheduler drains on its timers while open and stops on lock', () async {
      lepicWallet.stored.add(_tx(txId: 5, slateId: 'req-1', direction: lepic.TxDirection.incoming, status: lepic.TxStatus.received, counterparty: _payer, credited: BigInt.from(7000)));
      await wallet.sync();
      expect(wallet.invoiceTimersRunning, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(lepicWallet.invoiceDrains, greaterThan(0));
      expect(lepicWallet.paymentDrains, greaterThan(0), reason: 'an issued invoice waits and the listener is off');
      await wallet.lock();
      expect(wallet.invoiceTimersRunning, isFalse);
      final drains = (lepicWallet.invoiceDrains, lepicWallet.paymentDrains);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect((lepicWallet.invoiceDrains, lepicWallet.paymentDrains), drains);
    });

    test('the issuer\'s Cancel payment on a Not posted request cancels its transaction after the node check', () async {
      lepicWallet.stored.add(_tx(txId: 5, slateId: 'req-1', direction: lepic.TxDirection.incoming, status: lepic.TxStatus.finalized, counterparty: _payer, credited: BigInt.from(7000)));
      lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.invoiceFinalized, slateId: 'req-1'));
      await _settle();
      await wallet.sync();
      expect((await wallet.invoices()).request('req-1')!.state, RequestState.notPosted);
      lepicWallet.cancelError = lepic.WalletErrorKind.inPool;
      await expectLater(wallet.cancelRequestPayment('req-1'), throwsA(isA<InvoiceError>().having((e) => e.problem, 'problem', InvoiceProblem.onItsWay)));
      lepicWallet.cancelError = lepic.WalletErrorKind.nodeUnreachable;
      await expectLater(wallet.cancelRequestPayment('req-1'), throwsA(isA<InvoiceError>().having((e) => e.problem, 'problem', InvoiceProblem.cannotCheck)));
      expect(lepicWallet.cancelled, isEmpty);
      lepicWallet.cancelError = null;
      await wallet.cancelRequestPayment('req-1');
      expect(lepicWallet.cancelled, [5]);
      expect((await wallet.invoices()).request('req-1')!.state, RequestState.cancelled);
    });

    test('a slate another install owns: one notice that names no one, nothing acted on', () async {
      final notices = <InvoiceNotice>[];
      final sub = wallet.invoiceNotices().listen(notices.add);
      addTearDown(sub.cancel);
      for (var n = 0; n < 2; n++) {
        lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.unknownSlate, slateId: 'other-1', sender: _shop, slateStage: 'I2'));
        await _settle();
      }
      lepicWallet.events$.add(const lepic.WalletEvent(kind: lepic.WalletEventKind.unknownSlate, slateId: 'other-2', sender: _shop, slateStage: 'S2'));
      await _settle();
      expect(notices.map((n) => n.kind), [InvoiceNoticeKind.unknownPayment, InvoiceNoticeKind.unknownAnswer]);
      expect(notices.every((n) => n.who.isEmpty), isTrue, reason: 'the sender is not verified');
      expect(lepicWallet.paid, isEmpty);
      expect(lepicWallet.cancelled, isEmpty);
    });

    test('Cancel payment, then Spend them to myself now: exactly the coins the payment locked (D-2)', () async {
      lepicWallet.park('inv-1', 12000);
      await wallet.invoices();
      final paid = await wallet.payInvoice('inv-1', amount: 12000, password: _password);
      lepicWallet.lockedBy.addAll({'c-in-1': paid.txId!, 'c-other': 77});
      await wallet.cancelInvoicePayment('inv-1');
      expect(lepicWallet.cancelled, [paid.txId]);
      final cancelled = (await wallet.invoices()).invoice('inv-1')!;
      expect(cancelled.state, PayState.cancelled);
      expect(cancelled.spendToSelf, isTrue, reason: 'the details offer it while the coins are known');
      final sent = await wallet.spendCancelledToSelf('inv-1');
      expect((await wallet.invoices()).invoice('inv-1')!.spendToSelf, isFalse);
      expect(lepicWallet.spentToSelf, [
        ['c-in-1'],
      ]);
      expect(sent.fee, 1000);
      await expectLater(wallet.spendCancelledToSelf('inv-1'), throwsA(isA<DeskError>()), reason: 'once only');
    });

    test('a failed check keeps the lists and says the relay', () async {
      lepicWallet.park('inv-1', 12000);
      lepicWallet.drainError = lepic.WalletErrorKind.transportFailed;
      await expectLater(wallet.checkInvoices(), throwsA(isA<InvoiceError>().having((e) => e.problem, 'problem', InvoiceProblem.relayDown)));
      final book = await wallet.invoices();
      expect(book.check, InvoiceCheck.failed);
      expect(book.waiting.single.slateId, 'inv-1');
    });
  });

  test('the scheduler leaves the payments address alone while nothing waits', () async {
    var invoices = 0, payments = 0;
    final s = InvoiceScheduler(
      drainInvoices: () async => invoices++,
      drainPayments: () async => payments++,
      paymentsWanted: () => false,
      invoicesEvery: const Duration(milliseconds: 20),
      paymentsEvery: const Duration(milliseconds: 20),
      watchFocus: false,
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    s.stop();
    expect(invoices, greaterThan(0));
    expect(payments, 0);
  });

  test('payInvoice has one caller on the desktop: Review\'s Approve (P-2)', () {
    final callers = <String>[];
    for (final f in Directory('lib/src/desktop').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final text = f.readAsStringSync();
      for (final m in RegExp(r'\.payInvoice\(|\.pay\(').allMatches(text)) {
        final line = text.substring(0, m.start).split('\n').length;
        callers.add('${f.path.replaceAll(r'\', '/')}:$line');
      }
    }
    expect(callers.map((c) => c.split(':').first).toSet(), {
      // The adapter calls the session, the state calls the adapter, the Approve dialog the state.
      'lib/src/desktop/data/lepic_desk_wallet.dart',
      'lib/src/desktop/data/invoice_state.dart',
      'lib/src/desktop/screens/invoices/pay_dialogs.dart',
      // The prototype and its screenshots, on the mock only.
      'lib/src/desktop/data/mock_wallet.dart',
      'lib/src/desktop/screens/invoices/shots_pay.dart',
    }, reason: callers.join('\n'));
    for (final file in ['lepic_desk_wallet.dart', 'invoice_state.dart', 'pay_dialogs.dart']) {
      expect(callers.where((c) => c.split(':').first.endsWith('/$file')).length, 1, reason: '$file\n${callers.join('\n')}');
    }
    expect(File('lib/src/desktop/screens/invoices/shots_pay.dart').readAsStringSync(), contains('_mock(c).payInvoice('));
  });
}
