// SPDX-License-Identifier: Apache-2.0
// Invoices on the desktop's LEPIC adapter: LepicDeskWallet over the real LepicWalletSession on
// a stand-in `EpicWallet` that keeps a paired contact, its waiting invoices and transactions as
// LEPIC does (RFC 11). No native library is loaded; the password is a test value.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/cancel_final.dart' show CancelResult;
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/invoice_scheduler.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show OutputWord, Tx, TxState;
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:epic_wallet/src/watch_mode.dart' show postingFor;
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _password = 'test-pass-1234';
const _shop = 'esShopKey@epicbox.example';
const _payer = 'esPayerInvoiceKey@epicbox.example';

/// The paired shop, as LEPIC names it.
const _shopContact = 'contact-shop';

lepic.WalletError _lepicError(lepic.WalletErrorKind kind) => lepic.WalletError(kind: kind, code: 0, message: kind.name);

lepic.TransactionDetails _tx({
  required int txId,
  required String slateId,
  required lepic.TxDirection direction,
  required lepic.TxStatus status,
  String? counterparty,
  BigInt? credited,
  BigInt? debited,
  BigInt? confirmedHeight,
  bool releasable = false,
  int createdAtMs = 1790000000000,
}) => lepic.TransactionDetails(
  txId: txId,
  direction: direction,
  status: status,
  slateId: slateId,
  counterparty: counterparty,
  amountCredited: credited ?? BigInt.zero,
  amountDebited: debited ?? BigInt.zero,
  fee: direction == lepic.TxDirection.outgoing ? BigInt.from(100) : null,
  createdAtMs: createdAtMs,
  confirmedHeight: confirmedHeight,
  releasable: releasable,
  undelivered: false,
  messages: const [],
  flow: lepic.TxFlow.invoice,
  origin: lepic.TxOrigin.wallet,
  transport: 'epicbox',
  outputCommits: const [],
  spentCommits: const [],
  unverified: false,
);

/// LEPIC's wallet in memory: a paired shop, its invoices, transactions and a summary. Fails any
/// other call.
class _Wallet implements lepic.EpicWallet {
  final List<lepic.ContactInvoiceView> waiting = [];
  final List<lepic.TransactionDetails> stored = [];
  final StreamController<lepic.WalletEvent> events$ = StreamController<lepic.WalletEvent>.broadcast();
  final List<String> paid = [];
  final List<int> cancelled = [];

  /// When the next payment is made.
  DateTime paidAt = DateTime.now();
  int invoiceDrains = 0;
  int paymentDrains = 0;
  BigInt awaitingFinalization = BigInt.zero;
  lepic.WalletErrorKind? drainError;

  /// When set, a cancel is refused with it after the node check (in the pool, unreachable).
  lepic.WalletErrorKind? cancelError;

  void park(String slateId, int amount, {String? reference}) => waiting.add(
    lepic.ContactInvoiceView(
      slateId: slateId,
      contactId: _shopContact,
      amount: BigInt.from(amount),
      purpose: lepic.SlatePurpose.request,
      reference: reference,
      expires: BigInt.from(DateTime.now().add(const Duration(hours: 20)).millisecondsSinceEpoch ~/ 1000),
      receivedAtMs: 1790000000000,
      sameAmount: const [],
    ),
  );

  /// The contact each transaction was sealed to.
  final Map<int, String> contactOf = {};

  @override
  Future<String?> contactOfTransaction({required int txId}) async => contactOf[txId];

  @override
  Future<List<lepic.ContactView>> contacts() async => const [
    lepic.ContactView(
      contactId: _shopContact,
      label: 'Shop',
      state: lepic.PairingState.verified,
      sas: [],
      allowInvoices: true,
      seal: lepic.SealState.on_,
      importedFromBackup: false,
      lapsed: false,
      removedByPeer: false,
      createdAtMs: 1790000000000,
    ),
  ];

  @override
  Future<List<lepic.PendingPairingView>> pairingsPending() async => const [];

  @override
  Future<List<lepic.ContactInvoiceView>> contactInvoices() async => [...waiting];

  @override
  Future<lepic.OutboxReport> contactsOutboxDeliver({required lepic.ContactRelayMode relayMode}) async =>
      const lepic.OutboxReport(delivered: 0, failed: 0, stuck: 0);

  @override
  Future<bool> restoreScanRequired() async => false;
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
  void setEpicboxOverTor({required bool enabled}) {}

  @override
  void setOnionRoutes({required List<lepic.OnionRoute> routes}) {}

  @override
  void expectTor() {}

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
  Future<bool> checkPassword({required String password}) async => password == _password;

  @override
  Future<lepic.ContactCollectReport> contactsCollect({
    required lepic.CollectTrigger trigger,
    required lepic.ContactRelayMode relayMode,
    List<String>? only,
  }) async {
    invoiceDrains++;
    if (drainError != null) throw _lepicError(drainError!);
    return const lepic.ContactCollectReport(mailboxes: 1, messages: 0, paired: 0, unreachable: [], delivered: 0, failed: []);
  }

  @override
  Future<lepic.InboxReport> drainEpicbox() async {
    paymentDrains++;
    return const lepic.InboxReport(received: 0, finalized: 0, repeated: 0, rejected: 0, held: 0, notices: 0, bounced: 0, dropped: 0);
  }

  @override
  Future<lepic.InvoiceSweep> sweepInvoices({BigInt? expirySecs}) async =>
      lepic.InvoiceSweep(deleted: const [], cancelled: Uint32List(0), cancellable: Uint32List(0));

  int feeEstimates = 0;

  @override
  Future<lepic.FeeEstimate> estimateFee({required BigInt amount, required BigInt minimumConfirmations, lepic.SendOptions? options}) async {
    feeEstimates++;
    return lepic.FeeEstimate(amount: amount, fee: BigInt.from(700000), inputCount: 1, change: BigInt.zero, locked: amount + BigInt.from(700000), changeOutputs: 1);
  }

  @override
  Future<lepic.PaidInvoice> contactPayInvoice({
    required String slateId,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
    required lepic.ContactRelayMode relayMode,
  }) async {
    paid.add(slateId);
    final invoice = waiting.firstWhere((i) => i.slateId == slateId, orElse: () => throw _lepicError(lepic.WalletErrorKind.invoiceNotFound));
    waiting.remove(invoice);
    stored.add(
      _tx(
        txId: 9,
        slateId: slateId,
        direction: lepic.TxDirection.outgoing,
        status: lepic.TxStatus.received,
        debited: amount + BigInt.from(100),
        createdAtMs: paidAt.millisecondsSinceEpoch,
      ),
    );
    contactOf[9] = invoice.contactId;
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
  Future<lepic.SelfSentTx> spendOutputsToSelf({required List<String> commitments, required int outputs, required BigInt minimumConfirmations}) async {
    spentToSelf.add([...commitments]);
    return lepic.SelfSentTx(txId: 20, receivedTxId: 21, amount: BigInt.from(19000), fee: BigInt.from(1000), inputCount: commitments.length, outputCount: outputs);
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
      counterparty: t.counterparty,
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
    return opened = LepicWalletSession(lepicWallet);
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
      final day = DateTime(2026, 10, 23);
      PayState at(DateTime now, core.InvoiceStatus s) => payState(entry(lepic.TxStatus.received), s, tip: 100, minConf: 3, overdueAt: day, now: now);
      expect(at(day.subtract(const Duration(seconds: 1)), core.InvoiceStatus.replied), PayState.delivered);
      expect(at(day, core.InvoiceStatus.replied), PayState.pastTtl);
      expect(at(day, core.InvoiceStatus.posted), PayState.posted, reason: 'the service posted it: no cancel offer');
      expect(of(entry(lepic.TxStatus.cancelled), core.InvoiceStatus.withdrawn), PayState.cancelled);
    });

    test('a paid invoice still not on the network a while after paying reads Stalled (windows-05)', () {
      final paidAt = DateTime.fromMillisecondsSinceEpoch(1790000000000);
      PayState after(Duration d, [core.InvoiceStatus s = core.InvoiceStatus.replied]) =>
          payState(entry(lepic.TxStatus.sent), s, tip: 100, minConf: 3, now: paidAt.add(d));
      expect(after(const Duration(minutes: 19)), PayState.delivered);
      expect(after(const Duration(minutes: 20)), PayState.stalled);
      expect(PayState.stalled.needsAction, isTrue);
      expect(PayState.stalled.cancellable, isFalse, reason: 'the service may still post it');
      expect(after(const Duration(hours: 1), core.InvoiceStatus.posted), PayState.posted);
      expect(after(const Duration(hours: 1), core.InvoiceStatus.replyFailed), PayState.notDelivered);
    });

    test('an unpaid request waits for its payer; once finished it is posted (windows-05)', () {
      core.TxEntry issued(lepic.TxStatus status, {String? kernel}) => lepicTxEntry(
        lepic.TransactionDetails(
          txId: 12,
          direction: lepic.TxDirection.incoming,
          status: status,
          slateId: '0a9b35d2',
          counterparty: _payer,
          amountCredited: BigInt.from(5000000),
          amountDebited: BigInt.zero,
          createdAtMs: 1790000000000,
          kernelExcess: kernel,
          releasable: false,
          undelivered: false,
          messages: const [],
          flow: lepic.TxFlow.invoice,
          origin: lepic.TxOrigin.wallet,
          transport: 'epicbox',
          outputCommits: const [],
          spentCommits: const [],
          unverified: false,
        ),
      );
      Tx desk(core.TxEntry e) => deskTx(e, tip: 100, minConf: 3, fallbackId: -1);
      expect(desk(issued(lepic.TxStatus.received)).state, TxState.waitingRecipient);
      expect(desk(issued(lepic.TxStatus.posted, kernel: '08abc')).state, TxState.posted);
      expect(desk(issued(lepic.TxStatus.finalized, kernel: '08abc')).notPosted, isTrue);
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
      lepicWallet = _Wallet();
      service = _Service(lepicWallet);
      wallet = LepicDeskWallet(
        service: service,
        walletDir: (chain) async {
          final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
          await dir.create(recursive: true);
          return dir.path;
        },
        secrets: MemorySecretStore(),
        filesDir: () async => support,
        nodePoll: const Duration(hours: 1),
        paymentsEvery: const Duration(milliseconds: 40),
      );
      // Invoices (Experimental) on: the wallet's default settings have it off.
      NetGate.setExperimental(AdvancedPrefs.none.withExperimental(AdvancedFeature.invoices, true));
      await wallet.createWallet(name: 'Main', password: _password);
      expect(await wallet.unlock(_password), isTrue);
      await _settle();
    });

    tearDown(() async {
      await wallet.dispose();
      await support.delete(recursive: true);
    });

    test('a waiting invoice reads as one to pay: the contact\'s name, the fee, a clean reference', () async {
      lepicWallet.park('inv-1', 12000, reference: 'Order\u202e 42\nthanks');
      final book = await wallet.invoices();
      final i = book.invoice('inv-1')!;
      expect(i.state, PayState.waiting);
      // The pairing names it; its mailbox is no address to show (RFC C-21).
      expect(i.label, 'Shop');
      expect(i.pairingId, _shopContact);
      expect(i.senderAddress, isEmpty);
      expect(i.fee, 700000);
      expect(i.reference, 'Order 42 thanks');
      expect(book.waiting.single.slateId, 'inv-1');
      await wallet.invoices();
      expect(lepicWallet.feeEstimates, 1, reason: 'a read does not estimate the fee again');
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
      expect(tx.incoming, isFalse, reason: 'an invoice paid is money going out');
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

    test('Invoices off: the scheduler opens no contact mailbox', () async {
      NetGate.setExperimental(AdvancedPrefs.none);
      await wallet.sync();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(lepicWallet.invoiceDrains, 0);
    });

    test('the scheduler drains the payments address while open, stops on lock, and opens no contact mailbox', () async {
      lepicWallet.stored.add(_tx(txId: 5, slateId: 'req-1', direction: lepic.TxDirection.incoming, status: lepic.TxStatus.received, counterparty: _payer, credited: BigInt.from(7000)));
      await wallet.sync();
      expect(wallet.invoiceTimersRunning, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(lepicWallet.invoiceDrains, 0, reason: 'contact invoices come with the shell\'s collect');
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
      // Finalized moments ago, its post may still be under way (Posting…): past postingFor it
      // reads Not posted.
      final later = DateTime.now().add(postingFor + const Duration(seconds: 1));
      LepicWalletSession.postingClock = () => later;
      addTearDown(() => LepicWalletSession.postingClock = DateTime.now);
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

    test('paid, then the service withdrew it while offline: its later notice offers Cancel payment', () async {
      // The payer's side of the sequence: pay, the service goes offline and withdraws, comes
      // back and refuses the payment, answering it with `withdrawn`.
      lepicWallet.park('inv-1', 12000);
      await wallet.invoices();
      final paid = await wallet.payInvoice('inv-1', amount: 12000, password: _password);
      var book = await wallet.invoices();
      expect(book.invoice('inv-1')!.state, PayState.delivered);
      expect(book.needsAction, isEmpty);
      lepicWallet.events$.add(lepic.WalletEvent(kind: lepic.WalletEventKind.invoiceWithdrawn, slateId: 'inv-1', txId: paid.txId));
      await _settle();
      book = await wallet.invoices();
      final withdrawn = book.invoice('inv-1')!;
      expect(withdrawn.state, PayState.withdrawnAfterPay);
      expect(withdrawn.state.cancellable, isTrue);
      expect(book.needsAction.single.slateId, 'inv-1');
      await wallet.cancelInvoicePayment('inv-1');
      expect(lepicWallet.cancelled, [paid.txId]);
      expect((await wallet.invoices()).invoice('inv-1')!.state, PayState.cancelled);
    });

    test('a payment no notice settles: Cancel payment once the invoice\'s time has passed', () async {
      lepicWallet
        ..park('inv-1', 12000)
        ..paidAt = DateTime.now().subtract(defaultInvoiceExpiry + const Duration(minutes: 1));
      await wallet.invoices();
      await wallet.payInvoice('inv-1', amount: 12000, password: _password);
      final book = await wallet.invoices();
      expect(book.invoice('inv-1')!.state, PayState.pastTtl);
      expect(book.needsAction.single.slateId, 'inv-1');
      lepicWallet.cancelError = lepic.WalletErrorKind.inPool;
      await expectLater(wallet.cancelInvoicePayment('inv-1'), throwsA(isA<InvoiceError>()), reason: 'LEPIC asks the node first');
    });

    test('Cancel payment spends exactly the coins the payment locked back to the wallet, in the same action', () async {
      lepicWallet.park('inv-1', 12000);
      await wallet.invoices();
      final paid = await wallet.payInvoice('inv-1', amount: 12000, password: _password);
      lepicWallet.lockedBy.addAll({'c-in-1': paid.txId!, 'c-other': 77});
      expect(await wallet.cancelInvoicePayment('inv-1'), CancelResult.spentBack);
      expect(lepicWallet.cancelled, [paid.txId]);
      expect(lepicWallet.spentToSelf, [
        ['c-in-1'],
      ], reason: 'no other coin, no extra step');
      final cancelled = (await wallet.invoices()).invoice('inv-1')!;
      expect(cancelled.state, PayState.cancelled);
      expect(cancelled.cancelNotFinal, isFalse, reason: 'its coin is spent again');
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
    var payments = 0;
    final s = InvoiceScheduler(
      drainPayments: () async => payments++,
      paymentsWanted: () => false,
      paymentsEvery: const Duration(milliseconds: 20),
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    s.stop();
    expect(payments, 0);
  });

  test('the scheduler drains the payments address while one is wanted, and not after stop', () async {
    var payments = 0;
    final s = InvoiceScheduler(
      drainPayments: () async => payments++,
      paymentsWanted: () => true,
      paymentsEvery: const Duration(milliseconds: 20),
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(payments, greaterThan(0));
    s.stop();
    expect(s.running, isFalse);
    final drains = payments;
    await Future<void>.delayed(const Duration(milliseconds: 90));
    expect(payments, drains);
  });

  test('payInvoice has one caller on the desktop: Review\'s Approve', () {
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
