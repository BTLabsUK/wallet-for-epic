// SPDX-License-Identifier: Apache-2.0
part of 'mock_wallet.dart';

/// The prototype's network, set from the Prototype panel: what the next call meets.
enum ProtoNet {
  online,

  /// The node does not answer: paying and cancelling a payment are refused.
  nodeDown,

  /// The Epicbox relay does not answer: checks fail, requests are refused, replies are not
  /// delivered.
  relayDown,
}

const _coffeeAddr = 'esP9o78uY7tR6eW5qA4sD3fG2hJ1kL9zX9cV8bN7mQ6wE5rT@epicbox.stackwallet.com';
const _northwindAddr = 'esNw7kq8TzWmR2uPfVc9LdN6hJx3gA7sKeQ1oBnC5vD9rHtF7a@relay.northwind.example';
const _annaAddr = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
const _tomAddr = 'es2oC3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9UuzHYD@epicbox.epiccash.com';
const _olaAddr = 'esQka2kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3x@epicbox.epiccash.com';

/// The mock's invoices: both sides' state machines, a clock the prototype moves, and the
/// "other side" the Prototype panel plays (a payer who pays or declines, a service that bills,
/// withdraws or posts). Changes ping [MockDeskWallet.changes], so the screens reload.
class InvoiceProto {
  InvoiceProto._(this._w) {
    reset(notify: false);
  }

  final MockDeskWallet _w;

  /// The wallet's clock: the mock's fixed now (as Activity's rows use), plus the time since the
  /// prototype started, plus what the Prototype panel moved it by. Countdowns tick.
  Duration offset = Duration.zero;
  final DateTime _started = DateTime.now();
  DateTime get now => DateTime(2026, 10, 21, 14, 30).add(offset).add(DateTime.now().difference(_started));

  ProtoNet net = ProtoNet.online;

  Duration expiry = defaultInvoiceExpiry;
  DateTime? lastCheck;
  InvoiceCheck check = InvoiceCheck.ok;
  String? checkProblem;
  final List<IncomingInvoice> toPay = [];
  final List<IssuedRequest> sent = [];
  int _slate = 0;

  /// Balance moves from invoices: spendable, locked and confirming deltas in nanoepic. A
  /// confirming request with the wallet's minimum confirmations counts as spendable.
  int get spendDelta => [for (final i in toPay) if (i.state.locking || i.state == PayState.confirming || i.state == PayState.completed) -i.total].fold(0, (a, b) => a + b) +
      [for (final r in sent) if (r.state == RequestState.completed || _counted(r)) r.amount].fold(0, (a, b) => a + b);
  int get lockDelta => [for (final i in toPay) if (i.state.locking) i.total].fold(0, (a, b) => a + b);
  int get confirmingDelta => [for (final r in sent) if ((r.state == RequestState.paid || r.state == RequestState.confirming || r.state == RequestState.notPosted) && !_counted(r)) r.amount].fold(0, (a, b) => a + b);
  bool _counted(IssuedRequest r) => r.state == RequestState.confirming && r.confirmations >= _w._minConf;

  String _newSlate() {
    _slate++;
    final n = _slate.toString().padLeft(4, '0');
    return '7f3a$n-1c2d-4e5f-8a9b-0c1d2e3f4a5b';
  }

  void _changed() => _w._changes.add(null);

  /// Back to the opening state of the prototype.
  void reset({bool notify = true}) {
    offset = Duration.zero;
    net = ProtoNet.online;
    expiry = defaultInvoiceExpiry;
    lastCheck = now.subtract(const Duration(minutes: 2));
    check = InvoiceCheck.ok;
    checkProblem = null;
    _slate = 0;
    toPay
      ..clear()
      ..addAll([
        IncomingInvoice(
          slateId: _newSlate(),
          senderAddress: _northwindAddr,
          label: 'Northwind Exchange',
          pairingId: mockNorthwindPairing,
          reference: 'Deposit · ref NW-48213',
          amount: _epic(250),
          fee: _epic(0.008),
          message: 'Deposit to your Northwind account',
          receivedAt: now.subtract(const Duration(hours: 2, minutes: 40)),
          expiresAt: now.add(const Duration(hours: 14, minutes: 55)),
          state: PayState.waiting,
        ),
        IncomingInvoice(
          slateId: _newSlate(),
          senderAddress: _coffeeAddr,
          label: 'Merchant: Coffee',
          pairingId: mockCoffeePairing,
          amount: _epic(12.5),
          fee: _epic(0.006),
          message: 'Order #4471: 1 kg Huila, ground',
          receivedAt: now.subtract(const Duration(minutes: 35)),
          expiresAt: now.add(const Duration(hours: 3, minutes: 10)),
          state: PayState.waiting,
        ),
        // Paid yesterday; Activity's "Merchant: Coffee" row (tx 37) is its payment.
        IncomingInvoice(
          slateId: _w._txs.firstWhere((t) => t.id == 37).slateId,
          senderAddress: _coffeeAddr,
          label: 'Merchant: Coffee',
          pairingId: mockCoffeePairing,
          amount: _epic(3.2),
          fee: _epic(0.006),
          message: 'Flat white and croissant',
          receivedAt: now.subtract(const Duration(hours: 5, minutes: 6)),
          expiresAt: now.add(const Duration(hours: 18, minutes: 54)),
          state: PayState.posted,
          txId: 37,
          answeredAt: now.subtract(const Duration(hours: 5)),
        ),
      ]);
    sent
      ..clear()
      ..addAll([
        IssuedRequest(
          slateId: _newSlate(),
          txId: 141,
          payerAddress: _tomAddr,
          payerName: 'Tom',
          amount: _epic(150),
          message: 'Logo work, October',
          issuedAt: now.subtract(const Duration(hours: 1, minutes: 50)),
          expiresAt: now.add(const Duration(hours: 22, minutes: 10)),
          state: RequestState.waiting,
        ),
        // Anna paid; Activity's +25 row (tx 39) is the payment, confirming.
        IssuedRequest(
          slateId: _w._txs.firstWhere((t) => t.id == 39).slateId,
          txId: 39,
          payerAddress: _annaAddr,
          payerName: 'Anna Kowalska',
          amount: _epic(25),
          message: 'Lunch, thanks',
          issuedAt: now.subtract(const Duration(minutes: 40)),
          expiresAt: now.add(const Duration(hours: 23, minutes: 20)),
          state: RequestState.confirming,
          confirmations: MockDeskWallet._lunchConfirmations,
          answeredAt: now.subtract(const Duration(minutes: 18)),
        ),
        IssuedRequest(
          slateId: _newSlate(),
          txId: 142,
          payerAddress: 'esQ7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2bZr8mQ2pVtW5kNcY@epicbox.epiccash.com',
          amount: _epic(40),
          message: 'Table, Saturday market',
          issuedAt: now.subtract(const Duration(days: 1, hours: 3)),
          expiresAt: now.subtract(const Duration(hours: 3)),
          state: RequestState.expired,
          answeredAt: now.subtract(const Duration(hours: 3)),
        ),
      ]);
    _syncTxs();
    if (notify) _changed();
  }

  // ---- The wallet's side (DeskWalletApi calls).

  InvoiceBook book() => InvoiceBook(
    now: now,
    toPay: List.unmodifiable(toPay),
    sent: List.unmodifiable(sent),
    expiry: expiry,
    lastCheck: lastCheck,
    check: check,
    checkProblem: checkProblem,
  );

  InvoiceBook drain() {
    if (net == ProtoNet.relayDown) {
      check = InvoiceCheck.failed;
      checkProblem = 'relay';
      _changed();
      throw const InvoiceError(InvoiceProblem.relayDown, 'The Epicbox relay is not answering.');
    }
    check = InvoiceCheck.ok;
    checkProblem = null;
    lastCheck = now;
    _sweep();
    return book();
  }

  IssuedRequest request(PaymentRequestDraft d) {
    if (net == ProtoNet.relayDown) throw const InvoiceError(InvoiceProblem.notDelivered, 'The invoice did not reach the Epicbox server. Nothing was sent.');
    final payer = _w.pairing.records.where((r) => r.id == d.pairingId).firstOrNull;
    if (payer == null || payer.state != PairingState.verified) throw const InvoiceError(InvoiceProblem.invalid, 'The contact cannot be sent requests.');
    final r = IssuedRequest(
      slateId: _newSlate(),
      txId: _w._nextId++,
      payerAddress: payer.paymentsAddress ?? '',
      payerName: d.payerName,
      amount: d.amount,
      message: d.message,
      issuedAt: now,
      expiresAt: now.add(expiry),
      state: RequestState.waiting,
    );
    sent.insert(0, r);
    _syncTxs();
    return r;
  }

  /// A request saved as a file for anyone: waiting, with no payer.
  IssuedRequest requestFile(int amount, String? message) {
    final r = IssuedRequest(
      slateId: _newSlate(),
      txId: _w._nextId++,
      payerAddress: '',
      amount: amount,
      message: message,
      issuedAt: now,
      expiresAt: now.add(expiry),
      state: RequestState.waiting,
      byFile: true,
    );
    sent.insert(0, r);
    _syncTxs();
    return r;
  }

  /// Withdraws a waiting request.
  void withdraw(String slateId) => _setReq(slateId, (r) => r.withdrawable ? r.copyWith(state: RequestState.withdrawn, answeredAt: now) : r);

  /// Cancels the payment of a paid request that was never posted; the node is asked first.
  void cancelRequestPayment(String slateId) {
    if (net == ProtoNet.nodeDown) throw const InvoiceError(InvoiceProblem.cannotCheck, 'Cannot check the network now.');
    _setReq(slateId, (r) => r.state == RequestState.notPosted ? r.copyWith(state: RequestState.cancelled, answeredAt: now) : r);
  }

  void repost(String slateId) {
    if (net == ProtoNet.nodeDown) throw const InvoiceError(InvoiceProblem.nodeDown, 'The node is not answering.');
    _setReq(slateId, (r) => r.state == RequestState.notPosted ? r.copyWith(state: RequestState.confirming, confirmations: 0) : r);
  }

  IncomingInvoice pay(String slateId, int amount, String password) {
    final i = toPay.firstWhere((x) => x.slateId == slateId, orElse: () => throw const InvoiceError(InvoiceProblem.invalid, 'No such invoice'));
    if (password == 'wrong') throw const InvoiceError(InvoiceProblem.wrongPassword, 'Wrong password');
    if (i.state != PayState.waiting) throw const InvoiceError(InvoiceProblem.alreadyAnswered, 'This invoice was already answered.');
    if (!i.expiresAt.isAfter(now)) throw const InvoiceError(InvoiceProblem.expired, 'This invoice has expired. Nothing was paid.');
    if (amount != i.amount) throw const InvoiceError(InvoiceProblem.amountMismatch, 'The amount does not match the invoice.');
    if (net == ProtoNet.nodeDown) throw const InvoiceError(InvoiceProblem.nodeDown, 'The node is not answering. Nothing was paid.');
    final paid = i.copyWith(state: net == ProtoNet.relayDown ? PayState.notDelivered : PayState.delivered, txId: _w._nextId++, answeredAt: now);
    _setInv(slateId, (_) => paid);
    return paid;
  }

  IncomingInvoice retry(String slateId) {
    if (net == ProtoNet.relayDown) throw const InvoiceError(InvoiceProblem.relayDown, 'The Epicbox server did not take the reply.');
    _setInv(slateId, (i) => i.state == PayState.notDelivered ? i.copyWith(state: PayState.delivered) : i);
    return toPay.firstWhere((x) => x.slateId == slateId);
  }

  void decline(String slateId) => _setInv(slateId, (i) => i.state == PayState.waiting ? i.copyWith(state: PayState.declined, answeredAt: now) : i);

  void cancelPayment(String slateId) {
    final i = toPay.firstWhere((x) => x.slateId == slateId);
    if (i.state == PayState.posted || i.state == PayState.confirming || i.state == PayState.completed) {
      throw const InvoiceError(InvoiceProblem.onItsWay, 'Already on its way: it cannot be cancelled.');
    }
    if (net == ProtoNet.nodeDown) throw const InvoiceError(InvoiceProblem.cannotCheck, 'Cannot check the network now.');
    _setInv(slateId, (x) => x.state.cancellable || x.state == PayState.delivered ? x.copyWith(state: PayState.cancelled, spendToSelf: true) : x);
  }

  /// Spends a cancelled payment's coins to the wallet itself: the cancel is final.
  IncomingInvoice spendToSelf(String slateId) {
    final i = toPay.firstWhere((x) => x.slateId == slateId && x.spendToSelf, orElse: () => throw const DeskError('Nothing to spend'));
    _setInv(slateId, (x) => x.copyWith(spendToSelf: false));
    return i;
  }

  /// Expiries the wallet's sweep applies.
  void _sweep() {
    for (final r in [...sent]) {
      if (r.state == RequestState.waiting && !r.expiresAt.isAfter(now)) _setReq(r.slateId, (x) => x.copyWith(state: RequestState.expired, answeredAt: r.expiresAt), sync: false);
    }
    for (final i in [...toPay]) {
      if (i.state == PayState.waiting && !i.expiresAt.isAfter(now)) _setInv(i.slateId, (x) => x.copyWith(state: PayState.expired, answeredAt: i.expiresAt), sync: false);
      if (i.state == PayState.delivered && !i.expiresAt.isAfter(now)) _setInv(i.slateId, (x) => x.copyWith(state: PayState.pastTtl), sync: false);
    }
    _syncTxs();
  }

  // ---- The other side (the Prototype panel).

  /// Moves the clock; the next check expires what ran out.
  void advance(Duration d) {
    offset += d;
    _sweep();
    _changed();
  }

  void setNet(ProtoNet n) {
    net = n;
    if (n == ProtoNet.online && check == InvoiceCheck.failed) {
      check = InvoiceCheck.ok;
      checkProblem = null;
      lastCheck = now;
    }
    if (n == ProtoNet.relayDown) {
      check = InvoiceCheck.failed;
      checkProblem = 'relay';
    }
    _changed();
  }

  /// A paired contact the user allows bills this wallet. [same] repeats the last paid bill's
  /// sender and amount.
  void billArrives({bool same = false}) {
    if (same) {
      final last = toPay.where((i) => i.state.paid).fold<IncomingInvoice?>(null, (a, b) => a == null || (b.answeredAt ?? b.receivedAt).isAfter(a.answeredAt ?? a.receivedAt) ? b : a);
      if (last == null) return billArrives();
      toPay.add(
        IncomingInvoice(
          slateId: _newSlate(),
          senderAddress: last.senderAddress,
          label: last.label,
          pairingId: last.pairingId,
          reference: last.reference,
          amount: last.amount,
          fee: last.fee,
          message: last.message,
          receivedAt: now,
          expiresAt: now.add(expiry),
          state: PayState.waiting,
        ),
      );
    } else {
      toPay.add(
        IncomingInvoice(
          slateId: _newSlate(),
          senderAddress: _coffeeAddr,
          label: 'Merchant: Coffee',
          pairingId: mockCoffeePairing,
          amount: _epic(7.8),
          fee: _epic(0.006),
          message: cleanInvoiceText('Order #4502: 250 g Sidamo\u202e, beans'),
          receivedAt: now,
          expiresAt: now.add(expiry),
          state: PayState.waiting,
        ),
      );
    }
    lastCheck = now;
    _changed();
  }

  /// The service withdraws the oldest waiting invoice; with none waiting, the newest payment
  /// still on its way (then the wallet offers to cancel the payment).
  void serviceWithdraws() {
    final waiting = book().waiting;
    if (waiting.isNotEmpty) {
      _setInv(waiting.first.slateId, (i) => i.copyWith(state: PayState.withdrawn, answeredAt: now));
    } else {
      final paid = toPay.where((i) => i.state == PayState.delivered || i.state == PayState.notDelivered).toList();
      if (paid.isEmpty) return;
      _setInv(paid.last.slateId, (i) => i.copyWith(state: PayState.withdrawnAfterPay));
    }
    _changed();
  }

  /// The service posts the newest delivered payment and sends its receipt.
  void servicePosts() {
    final paid = toPay.where((i) => i.state == PayState.delivered).toList();
    if (paid.isEmpty) return;
    _setInv(paid.last.slateId, (i) => i.copyWith(state: PayState.posted, kernel: '09f1c3e5a7b9d1f3e5a7c9b1d3f5e7a9c1b3d5e7f9a1c3b5d7e9f1a3c5b7d9e1f3'));
    _changed();
  }

  /// [n] blocks: posted payments get in, confirming ones count up to the confirmations needed.
  void blocks(int n) {
    for (final i in [...toPay]) {
      if (i.state == PayState.posted || i.state == PayState.confirming) {
        final c = i.confirmations + n;
        _setInv(i.slateId, (x) => x.copyWith(state: c >= _w._minConf ? PayState.completed : PayState.confirming, confirmations: c), sync: false);
      }
    }
    for (final r in [...sent]) {
      if (r.state == RequestState.paid || r.state == RequestState.confirming) {
        final c = r.confirmations + n;
        _setReq(r.slateId, (x) => x.copyWith(state: c >= _w._minConf ? RequestState.completed : RequestState.confirming, confirmations: c), sync: false);
      }
    }
    _syncTxs();
    _changed();
  }

  IssuedRequest? get _oldestWaiting => sent.where((r) => r.state == RequestState.waiting).fold<IssuedRequest?>(null, (a, b) => a == null || b.issuedAt.isBefore(a.issuedAt) ? b : a);

  /// The payer of the oldest waiting request pays it: finalized and posted at once, or Not
  /// posted while the node is down.
  void payerPays() {
    final r = _oldestWaiting;
    if (r == null) return;
    _setReq(r.slateId, (x) => x.copyWith(state: net == ProtoNet.nodeDown ? RequestState.notPosted : RequestState.paid, answeredAt: now));
    _changed();
  }

  void payerDeclines() {
    final r = _oldestWaiting;
    if (r == null) return;
    _setReq(r.slateId, (x) => x.copyWith(state: RequestState.declined, answeredAt: now));
    _changed();
  }

  /// The payer's wallet cannot pay invoices and sends the oldest waiting request back.
  void payerBounces() {
    final r = _oldestWaiting;
    if (r == null) return;
    _setReq(r.slateId, (x) => x.copyWith(state: RequestState.bounced, answeredAt: now));
    _changed();
  }

  /// A payment for the newest request that ended unpaid arrives late: refused, nothing moves.
  void lateReply() {
    final r = sent.where((x) => x.state.endedUnpaid).firstOrNull;
    if (r == null) return;
    _setReq(r.slateId, (x) => x.copyWith(lateReplyRefused: true));
    _changed();
  }

  /// The app closed after Approve and before the reply went out: the oldest waiting invoice is
  /// signed and stored, not delivered. The screens show it after the next unlock.
  void closedAfterApprove() {
    final w = book().waiting;
    if (w.isEmpty) return;
    _setInv(w.first.slateId, (i) => i.copyWith(state: PayState.notDelivered, txId: _w._nextId++, answeredAt: now));
    _changed();
  }

  // ---- Keeping Activity's transactions in step.

  void _setReq(String slateId, IssuedRequest Function(IssuedRequest) f, {bool sync = true}) {
    final k = sent.indexWhere((r) => r.slateId == slateId);
    if (k < 0) return;
    sent[k] = f(sent[k]);
    if (sync) _syncTxs();
  }

  void _setInv(String slateId, IncomingInvoice Function(IncomingInvoice) f, {bool sync = true}) {
    final k = toPay.indexWhere((i) => i.slateId == slateId);
    if (k < 0) return;
    toPay[k] = f(toPay[k]);
    if (sync) _syncTxs();
  }

  /// One transaction per request sent and per invoice paid, as LEPIC keeps them.
  void _syncTxs() {
    for (final r in sent) {
      final (state, conf) = switch (r.state) {
        RequestState.waiting || RequestState.notPosted => (TxState.waitingRecipient, 0),
        RequestState.paid => (TxState.posted, 0),
        RequestState.confirming => r.confirmations == 0 ? (TxState.posted, 0) : (TxState.confirming, r.confirmations),
        RequestState.completed => (TxState.confirmed, r.confirmations),
        _ => (TxState.cancelled, 0),
      };
      _putTx(
        Tx(
          id: r.txId,
          slateId: r.slateId,
          direction: TxDirection.received,
          state: state,
          method: TxMethod.epicbox,
          amount: r.amount,
          fee: 0,
          created: r.issuedAt,
          confirmations: conf,
          counterparty: r.payerAddress,
          contactName: r.payerName,
          message: r.message,
          height: conf > 0 ? 2914414 - conf + 1 : null,
          flow: TxFlow.invoice,
        ),
      );
    }
    for (final i in toPay) {
      final id = i.txId;
      if (id == null) continue;
      final (state, conf) = switch (i.state) {
        PayState.posted => (TxState.posted, 0),
        PayState.confirming => (TxState.confirming, i.confirmations),
        PayState.completed => (TxState.confirmed, i.confirmations),
        PayState.cancelled => (TxState.cancelled, 0),
        _ => (TxState.waitingRecipient, 0),
      };
      _putTx(
        Tx(
          id: id,
          slateId: i.slateId,
          direction: TxDirection.sent,
          state: state,
          method: TxMethod.epicbox,
          amount: i.amount,
          fee: i.fee,
          created: i.answeredAt ?? i.receivedAt,
          confirmations: conf,
          counterparty: i.senderAddress,
          contactName: i.label,
          message: i.message,
          kernel: i.kernel,
          height: conf > 0 ? 2914414 - conf + 1 : null,
          flow: TxFlow.invoice,
        ),
      );
    }
  }

  void _putTx(Tx t) {
    final k = _w._txs.indexWhere((x) => x.id == t.id);
    if (k >= 0) {
      _w._txs[k] = t;
    } else {
      // Newest first, like the rest of the list.
      final at = _w._txs.indexWhere((x) => x.created.isBefore(t.created));
      _w._txs.insert(at < 0 ? _w._txs.length : at, t);
    }
  }
}
