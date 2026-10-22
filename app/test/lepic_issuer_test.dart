// The issuer's side of the LEPIC adapter (I-05) against a stand-in `EpicWallet`: issue,
// LEPIC's events to states, withdraw, bounces, the payments drain and sweep, reconciling
// missed events, records across a reopen, and that no issuer path spends. No native library
// is loaded.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _payments = 'ownKey0@epicbox.example';
const _invoices = 'ownKey1@epicbox.example';
const _payer = 'payerKey@epicbox.example';

lepic.WalletError _lepicError(lepic.WalletErrorKind kind) =>
    lepic.WalletError(kind: kind, code: 0, message: kind.name);

/// LEPIC's issuer half in memory. Every spending call is recorded and refused; any other
/// call not written here fails the test.
class _IssuerWallet implements lepic.EpicWallet {
  final Map<int, lepic.TransactionDetails> stored = {};
  final StreamController<lepic.WalletEvent> eventSink =
      StreamController<lepic.WalletEvent>.broadcast();

  final List<({BigInt amount, String address, String? message})> issued = [];
  final List<int> cancelled = [];
  final List<String> calls = [];

  /// Spending calls that reached LEPIC. Must stay empty.
  final List<String> spends = [];

  lepic.WalletErrorKind? issueError;
  lepic.WalletErrorKind? cancelError;
  int bounced = 0;
  int _next = 40;

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

  final StreamController<lepic.ListenerEvent> listenerSink =
      StreamController<lepic.ListenerEvent>.broadcast();

  @override
  Stream<lepic.ListenerEvent> startListener() => listenerSink.stream;

  /// What [peerCapability] answers, by address; LEPIC matches the key.
  final Map<String, lepic.PeerCapability> peers = {};

  @override
  Future<lepic.PeerCapability> peerCapability({
    required String address,
  }) async => peers[address] ?? lepic.PeerCapability.unknown;

  @override
  Future<String> epicboxAddress() async => _payments;

  @override
  Future<String> invoiceAddress() async => _invoices;

  @override
  Future<List<lepic.TransactionDetails>> transactions() async => [
    ...stored.values,
  ];

  void store(
    int txId,
    String slateId,
    lepic.TxStatus status,
    BigInt amount, {
    String? counterparty,
    String? transport = 'epicbox',
    lepic.TxFlow flow = lepic.TxFlow.payment,
    List<lepic.SlateMessage> messages = const [],
  }) => stored[txId] = lepic.TransactionDetails(
    txId: txId,
    direction: lepic.TxDirection.incoming,
    status: status,
    slateId: slateId,
    counterparty: counterparty,
    transport: transport,
    amountCredited: amount,
    amountDebited: BigInt.zero,
    createdAtMs: 1790000000000,
    releasable: false,
    messages: messages,
    flow: flow,
    origin: lepic.TxOrigin.wallet,
  );

  void setStatus(int txId, lepic.TxStatus status) {
    final t = stored[txId]!;
    store(
      txId,
      t.slateId!,
      status,
      t.amountCredited,
      counterparty: t.counterparty,
      transport: t.transport,
      flow: t.flow,
      messages: t.messages,
    );
  }

  /// Called inside [issueInvoiceEpicbox] before it fails, as a listener signing a payment
  /// at the same moment would.
  void Function()? duringIssue;

  @override
  Future<lepic.IssuedInvoice> issueInvoiceEpicbox({
    required BigInt amount,
    required String address,
    String? message,
  }) async {
    issued.add((amount: amount, address: address, message: message));
    final txId = _next++;
    final slateId = 'issued-$txId';
    // Stored before delivery, as LEPIC does, with the payer as counterparty.
    store(
      txId,
      slateId,
      lepic.TxStatus.received,
      amount,
      counterparty: address,
      flow: lepic.TxFlow.invoice,
      messages: [
        if (message != null)
          lepic.SlateMessage(role: lepic.SlateRole.receiver, text: message),
      ],
    );
    duringIssue?.call();
    if (issueError != null) throw _lepicError(issueError!);
    return lepic.IssuedInvoice(txId: txId, slateId: slateId, amount: amount);
  }

  @override
  Future<void> cancelTransaction({required int txId}) async {
    cancelled.add(txId);
    if (cancelError != null) throw _lepicError(cancelError!);
    setStatus(txId, lepic.TxStatus.cancelled);
  }

  @override
  Future<lepic.InboxReport> drainEpicbox() async {
    calls.add('drainEpicbox');
    final b = bounced;
    bounced = 0;
    return lepic.InboxReport(
      received: 1,
      finalized: 2,
      repeated: 0,
      rejected: 0,
      held: 0,
      notices: 0,
      bounced: b,
      dropped: 0,
    );
  }

  @override
  Future<lepic.InvoiceSweep> sweepInvoices({BigInt? expirySecs}) async {
    calls.add('sweepInvoices($expirySecs)');
    return lepic.InvoiceSweep(
      deleted: const [],
      cancelled: Uint32List(0),
      cancellable: Uint32List(0),
    );
  }

  @override
  Future<lepic.PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
  }) async {
    spends.add('payInvoice');
    throw StateError('an issuer path paid');
  }

  @override
  Future<lepic.SentTx> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
  }) async {
    spends.add('sendEpicbox');
    throw StateError('an issuer path sent');
  }

  @override
  Future<lepic.Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
  }) async {
    spends.add('createSendSlate');
    throw StateError('an issuer path made a send');
  }
}

lepic.WalletEvent _event(
  lepic.WalletEventKind kind, {
  String? slateId,
  int? txId,
}) => lepic.WalletEvent(kind: kind, slateId: slateId, txId: txId);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

Matcher _kind(WalletErrorKind kind) =>
    throwsA(isA<WalletError>().having((e) => e.kind, 'kind', kind));

void main() {
  late _IssuerWallet wallet;
  late LepicWalletSession session;
  late List<String> validated;
  late List<IssuerEvent> events;
  final five = BigInt.from(500000000);

  LepicWalletSession open(_IssuerWallet w, {WalletHistory? history}) =>
      LepicWalletSession(
        w,
        history: history,
        validateAddress: (a) {
          validated.add(a);
          return a.contains('@') && !a.contains(' ');
        },
      );

  setUp(() {
    validated = [];
    wallet = _IssuerWallet();
    session = open(wallet);
    events = [];
    session.issuerEvents().listen(events.add);
  });

  tearDown(() => expect(wallet.spends, isEmpty, reason: 'an issuer spent'));

  group('issue', () {
    test('sends the trimmed address and the cut message to LEPIC', () async {
      final before = DateTime.now();
      final issued = await session.issueInvoice(
        amount: five,
        address: ' $_payer ',
        message: '  ${'é' * 300} ',
      );
      expect(validated, [_payer]);
      expect(wallet.issued.single.address, _payer);
      expect(wallet.issued.single.amount, five);
      expect(wallet.issued.single.message, 'é' * 128);
      expect(issued.slateId, 'issued-40');
      expect(issued.txId, 40);
      expect(issued.payerAddress, _payer);
      expect(issued.message, 'é' * 128);
      expect(issued.state, IssuedInvoiceState.waiting);
      expect(issued.issuedAt.isBefore(before), isFalse);
      expect(issued.expiresAt.difference(issued.issuedAt), invoiceExpiry);
      expect(await session.issuedInvoice(slateId: issued.slateId), isNotNull);
    });

    test('a blank message goes as none', () async {
      await session.issueInvoice(amount: five, address: _payer, message: ' ');
      expect(wallet.issued.single.message, isNull);
    });

    test('an invalid address never reaches LEPIC', () async {
      await expectLater(
        session.issueInvoice(amount: five, address: 'not an address'),
        _kind(WalletErrorKind.invalidArgument),
      );
      expect(wallet.issued, isEmpty);
    });

    test('its own payments and invoice addresses are refused', () async {
      for (final own in [_payments, 'ownKey1@other.example']) {
        await expectLater(
          session.issueInvoice(amount: five, address: own),
          _kind(WalletErrorKind.invalidArgument),
        );
      }
      await expectLater(
        session.issueInvoice(amount: BigInt.zero, address: _payer),
        _kind(WalletErrorKind.invalidArgument),
      );
      expect(wallet.issued, isEmpty);
      expect(await session.issuedInvoices(), isEmpty);
    });

    test('an undelivered request is cancelled and leaves no record', () async {
      wallet.store(
        7,
        'older',
        lepic.TxStatus.received,
        five,
        counterparty: _payer,
      );
      // Payments for the same amount the listener signs during the call: from someone
      // else over epicbox, and from the payer's key by file.
      wallet.duringIssue = () => wallet
        ..store(
          80,
          'concurrent',
          lepic.TxStatus.received,
          five,
          counterparty: 'senderKey@epicbox.example',
        )
        ..store(
          81,
          'by-file',
          lepic.TxStatus.received,
          five,
          counterparty: _payer,
          transport: 'file',
        );
      wallet.issueError = lepic.WalletErrorKind.notDelivered;
      await expectLater(
        session.issueInvoice(amount: five, address: _payer),
        _kind(WalletErrorKind.transportFailed),
      );
      // Only the one this call stored: not an older receive, not a concurrent one.
      expect(wallet.cancelled, [40]);
      expect(wallet.stored[80]!.status, lepic.TxStatus.received);
      expect(wallet.stored[81]!.status, lepic.TxStatus.received);
      expect(await session.issuedInvoices(), isEmpty);
    });

    test('another failure cancels nothing', () async {
      wallet.issueError = lepic.WalletErrorKind.invalidArgument;
      await expectLater(
        session.issueInvoice(amount: five, address: _payer),
        _kind(WalletErrorKind.invalidArgument),
      );
      expect(wallet.cancelled, isEmpty);
    });
  });

  group('events', () {
    test('LEPIC\'s issuer events map to states, the payer\'s do not', () {
      expect(
        lepicIssuerEvent(
          _event(lepic.WalletEventKind.invoiceFinalized, slateId: 's', txId: 1),
        ),
        (slateId: 's', state: IssuedInvoiceState.paid),
      );
      expect(
        lepicIssuerEvent(
          _event(lepic.WalletEventKind.invoiceDeclined, slateId: 's', txId: 1),
        )?.state,
        IssuedInvoiceState.declined,
      );
      expect(
        lepicIssuerEvent(
          _event(lepic.WalletEventKind.invoiceExpired, slateId: 's', txId: 1),
        )?.state,
        IssuedInvoiceState.expired,
      );
      expect(
        lepicIssuerEvent(
          _event(lepic.WalletEventKind.invoiceBounced, slateId: 's', txId: 1),
        )?.state,
        IssuedInvoiceState.bounced,
      );
      for (final e in [
        // Without a txId it was an invoice to pay.
        _event(lepic.WalletEventKind.invoiceExpired, slateId: 's'),
        _event(lepic.WalletEventKind.invoiceReceived, slateId: 's'),
        _event(lepic.WalletEventKind.invoicePosted, slateId: 's', txId: 1),
        _event(lepic.WalletEventKind.invoiceWithdrawn, slateId: 's', txId: 1),
        _event(lepic.WalletEventKind.transaction, txId: 1),
        _event(lepic.WalletEventKind.invoiceFinalized, txId: 1),
      ]) {
        expect(lepicIssuerEvent(e), isNull, reason: e.kind.name);
      }
    });

    test('each event moves its request once', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      final b = await session.issueInvoice(amount: five, address: _payer);
      final c = await session.issueInvoice(amount: five, address: _payer);
      final payerEvents = <InvoiceEvent>[];
      final sub = session.invoiceEvents().listen(payerEvents.add);
      wallet.eventSink
        ..add(
          _event(
            lepic.WalletEventKind.invoiceFinalized,
            slateId: a.slateId,
            txId: a.txId,
          ),
        )
        ..add(
          _event(
            lepic.WalletEventKind.invoiceDeclined,
            slateId: b.slateId,
            txId: b.txId,
          ),
        )
        ..add(
          _event(
            lepic.WalletEventKind.invoiceExpired,
            slateId: c.slateId,
            txId: c.txId,
          ),
        )
        // Late or stray: a paid one never expires, an unknown one changes nothing.
        ..add(
          _event(
            lepic.WalletEventKind.invoiceExpired,
            slateId: a.slateId,
            txId: a.txId,
          ),
        )
        ..add(
          _event(
            lepic.WalletEventKind.invoiceFinalized,
            slateId: 'someone-else',
            txId: 99,
          ),
        );
      await _settle();
      await sub.cancel();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.paid,
          slateId: a.slateId,
          payerAddress: _payer,
        ),
        IssuerEvent(
          kind: IssuerEventKind.declined,
          slateId: b.slateId,
          payerAddress: _payer,
        ),
        IssuerEvent(
          kind: IssuerEventKind.expired,
          slateId: c.slateId,
          payerAddress: _payer,
        ),
      ]);
      final states = {
        for (final i in await session.issuedInvoices()) i.slateId: i.state,
      };
      expect(states, {
        a.slateId: IssuedInvoiceState.paid,
        b.slateId: IssuedInvoiceState.declined,
        c.slateId: IssuedInvoiceState.expired,
      });
      // A decline is final: the app withdrew it itself.
      expect(wallet.cancelled, [b.txId]);
      // The payer's stream hears nothing of the issuer's invoices.
      expect(payerEvents, isEmpty);
    });

    test('a decline whose cancel fails is still declined', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      wallet.cancelError = lepic.WalletErrorKind.onChain;
      wallet.eventSink.add(
        _event(
          lepic.WalletEventKind.invoiceDeclined,
          slateId: a.slateId,
          txId: a.txId,
        ),
      );
      await _settle();
      expect(
        (await session.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.declined,
      );
    });

    test('no LEPIC event leads to a spend', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      for (final kind in lepic.WalletEventKind.values) {
        wallet.eventSink.add(_event(kind, slateId: a.slateId, txId: a.txId));
      }
      await _settle();
      await session.drainPayments();
      await session.issuedInvoices();
      expect(wallet.spends, isEmpty);
    });
  });

  group('bounces', () {
    lepic.WalletEvent bounce(IssuedInvoice i) => _event(
      lepic.WalletEventKind.invoiceBounced,
      slateId: i.slateId,
      txId: i.txId,
    );

    test('an event marks that request, withdraws it and tells once', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      final b = await session.issueInvoice(amount: five, address: _payer);
      // LEPIC raises it again for a bounce redelivered before it was settled.
      wallet.eventSink
        ..add(bounce(a))
        ..add(bounce(a));
      await _settle();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.bounced,
          slateId: a.slateId,
          payerAddress: _payer,
        ),
      ]);
      expect(wallet.cancelled, [a.txId]);
      final states = {
        for (final i in await session.issuedInvoices()) i.slateId: i.state,
      };
      expect(states, {
        a.slateId: IssuedInvoiceState.bounced,
        b.slateId: IssuedInvoiceState.waiting,
      });
    });

    test(
      'the listener\'s bounce does the same, and with the event once',
      () async {
        final a = await session.issueInvoice(amount: five, address: _payer);
        final seen = <ListenerEvent>[];
        final sub = session.startListener().listen(seen.add);
        wallet.listenerSink
          ..add(
            lepic.ListenerEvent(
              kind: lepic.ListenerEventKind.invoiceBounced,
              txId: a.txId,
              slateId: a.slateId,
              message: 'sent back',
            ),
          )
          ..add(
            const lepic.ListenerEvent(
              kind: lepic.ListenerEventKind.connected,
              message: 'up',
            ),
          );
        // While the listener runs LEPIC raises it on the events too.
        wallet.eventSink.add(bounce(a));
        await _settle();
        await sub.cancel();
        expect(events, [
          IssuerEvent(
            kind: IssuerEventKind.bounced,
            slateId: a.slateId,
            payerAddress: _payer,
          ),
        ]);
        expect(wallet.cancelled, [a.txId]);
        // The listener's own stream shows the connection, not the bounce.
        expect([for (final e in seen) e.kind], [ListenerEventKind.connected]);
      },
    );

    test('the listener\'s bounce alone marks, withdraws and tells', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      final sub = session.startListener().listen((_) {});
      wallet.listenerSink.add(
        lepic.ListenerEvent(
          kind: lepic.ListenerEventKind.invoiceBounced,
          txId: a.txId,
          slateId: a.slateId,
          message: 'sent back',
        ),
      );
      await _settle();
      await sub.cancel();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.bounced,
          slateId: a.slateId,
          payerAddress: _payer,
        ),
      ]);
      expect(wallet.cancelled, [a.txId]);
      expect(
        (await session.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.bounced,
      );
    });

    test('a bounce for a request already ended changes nothing', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      await session.withdrawInvoice(slateId: a.slateId);
      wallet.eventSink.add(bounce(a));
      await _settle();
      expect(
        (await session.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.withdrawn,
      );
      expect(wallet.cancelled, [a.txId]);
      expect(events.map((e) => e.kind), [IssuerEventKind.withdrawn]);
    });

    test('a drain no longer raises a signal of its own', () async {
      wallet.bounced = 2;
      expect((await session.drainPayments()).bounced, 2);
      await _settle();
      expect(events, isEmpty);
    });

    test('the payer\'s capability comes from LEPIC, trimmed', () async {
      wallet.peers[_payer] = lepic.PeerCapability.noInvoices;
      expect(
        await session.peerCapability(address: ' $_payer '),
        PeerCapability.noInvoices,
      );
      expect(
        await session.peerCapability(address: 'otherKey@epicbox.example'),
        PeerCapability.unknown,
      );
    });
  });

  group('requests from LEPIC', () {
    test(
      'one without a record shows what LEPIC says, without a notice',
      () async {
        wallet
          ..store(
            60,
            'restored-waiting',
            lepic.TxStatus.received,
            five,
            counterparty: _payer,
            flow: lepic.TxFlow.invoice,
          )
          ..store(
            61,
            'restored-paid',
            lepic.TxStatus.confirmed,
            five,
            counterparty: _payer,
            flow: lepic.TxFlow.invoice,
          )
          // A plain receive is no request.
          ..store(
            62,
            'payment',
            lepic.TxStatus.received,
            five,
            counterparty: _payer,
          );
        final states = {
          for (final i in await session.issuedInvoices()) i.slateId: i.state,
        };
        expect(states, {
          'restored-waiting': IssuedInvoiceState.waiting,
          'restored-paid': IssuedInvoiceState.paid,
        });
        // It can be withdrawn like any other, and the payer's bounce still counts.
        wallet.eventSink.add(
          _event(
            lepic.WalletEventKind.invoiceBounced,
            slateId: 'restored-waiting',
            txId: 60,
          ),
        );
        await _settle();
        expect(wallet.cancelled, [60]);
        expect(events, [
          const IssuerEvent(
            kind: IssuerEventKind.bounced,
            slateId: 'restored-waiting',
            payerAddress: _payer,
          ),
        ]);
      },
    );
  });

  group('withdraw', () {
    test('cancels a waiting request and says so', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      final withdrawn = await session.withdrawInvoice(slateId: a.slateId);
      expect(withdrawn.state, IssuedInvoiceState.withdrawn);
      expect(wallet.cancelled, [a.txId]);
      await _settle();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.withdrawn,
          slateId: a.slateId,
          payerAddress: _payer,
        ),
      ]);
      // The cancelled transaction is not taken for an expiry afterwards.
      expect(
        (await session.issuedInvoices()).single.state,
        IssuedInvoiceState.withdrawn,
      );
    });

    test('refuses one that is no longer waiting, or unknown', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      wallet.eventSink.add(
        _event(
          lepic.WalletEventKind.invoiceFinalized,
          slateId: a.slateId,
          txId: a.txId,
        ),
      );
      await _settle();
      await expectLater(
        session.withdrawInvoice(slateId: a.slateId),
        _kind(WalletErrorKind.invalidArgument),
      );
      await expectLater(
        session.withdrawInvoice(slateId: 'nope'),
        _kind(WalletErrorKind.invalidArgument),
      );
      expect(wallet.cancelled, isEmpty);
    });

    test('a cancel LEPIC refuses keeps it waiting', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      wallet.cancelError = lepic.WalletErrorKind.inPool;
      await expectLater(
        session.withdrawInvoice(slateId: a.slateId),
        _kind(WalletErrorKind.invalidArgument),
      );
      expect(
        (await session.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.waiting,
      );
    });
  });

  group('payments drain', () {
    test(
      'drains the payments address, then sweeps with the app\'s expiry',
      () async {
        expect(
          await session.drainPayments(),
          const PaymentsDrainReport(received: 1, finalized: 2),
        );
        expect(wallet.calls, ['drainEpicbox', 'sweepInvoices(86400)']);
      },
    );

    test('a missed event is caught up from LEPIC\'s store', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      final b = await session.issueInvoice(amount: five, address: _payer);
      final c = await session.issueInvoice(amount: five, address: _payer);
      wallet
        ..setStatus(a.txId, lepic.TxStatus.posted)
        ..setStatus(b.txId, lepic.TxStatus.cancelled);
      final states = {
        for (final i in await session.issuedInvoices()) i.slateId: i.state,
      };
      expect(states, {
        a.slateId: IssuedInvoiceState.paid,
        b.slateId: IssuedInvoiceState.expired,
        c.slateId: IssuedInvoiceState.waiting,
      });
      await _settle();
      expect(
        events,
        unorderedEquals([
          IssuerEvent(
            kind: IssuerEventKind.paid,
            slateId: a.slateId,
            payerAddress: _payer,
          ),
          IssuerEvent(
            kind: IssuerEventKind.expired,
            slateId: b.slateId,
            payerAddress: _payer,
          ),
        ]),
      );
    });

    test('a single request is caught up too, for its details', () async {
      final a = await session.issueInvoice(amount: five, address: _payer);
      wallet.setStatus(a.txId, lepic.TxStatus.posted);
      expect(
        (await session.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.paid,
      );
      expect(await session.issuedInvoice(slateId: 'nope'), isNull);
      await _settle();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.paid,
          slateId: a.slateId,
          payerAddress: _payer,
        ),
      ]);
    });
  });

  group('records', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('wfe-issuer-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('survive a reopen with their state', () async {
      final first = open(
        wallet,
        history: await WalletHistory.open(dir.path, Chain.floonet),
      );
      final a = await first.issueInvoice(
        amount: five,
        address: _payer,
        message: 'Dinner',
      );
      await first.withdrawInvoice(slateId: a.slateId);
      final b = await first.issueInvoice(amount: five, address: _payer);
      first.dispose();

      final again = await LepicWalletSession.openOn(
        _ReopenedWallet(wallet),
        dir.path,
        Chain.floonet,
      );
      final kept = await again.issuedInvoices();
      expect([for (final i in kept) i.slateId], [b.slateId, a.slateId]);
      expect(kept.last.state, IssuedInvoiceState.withdrawn);
      expect(kept.last.message, 'Dinner');
      expect(kept.first.state, IssuedInvoiceState.waiting);
      again.dispose();
    });
  });
}

/// The same LEPIC store after the app restarted, with the index calls an open makes.
class _ReopenedWallet extends _IssuerWallet {
  _ReopenedWallet(_IssuerWallet before) {
    stored.addAll(before.stored);
  }

  @override
  Future<int> invoiceAddressIndex() async => 1;
}
