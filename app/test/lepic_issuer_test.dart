// The issuer's side of the LEPIC adapter (I-05, RFC 11.2) against a stand-in `EpicWallet`:
// requests to a paired contact, LEPIC's events to states, withdraw, bounces, the payments
// drain and sweep, reconciling missed events, records across a reopen, and that no issuer
// path spends. No native library is loaded.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

const _payer = 'contact-payer';

/// A request a restore brought back from before pairing: LEPIC kept its address.
const _restoredPayer = 'payerKey@epicbox.example';

lepic.WalletError _lepicError(lepic.WalletErrorKind kind) =>
    lepic.WalletError(kind: kind, code: 0, message: kind.name);

/// LEPIC's issuer half in memory. Every spending call is recorded and refused; any other
/// call not written here fails the test.
class _IssuerWallet implements lepic.EpicWallet {
  final Map<int, lepic.TransactionDetails> stored = {};
  final StreamController<lepic.WalletEvent> eventSink =
      StreamController<lepic.WalletEvent>.broadcast();

  final List<({BigInt amount, String contactId, String? message, BigInt? expires})>
  issued = [];
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

  /// The contact each transaction was sealed to, as LEPIC keeps it.
  final Map<int, String> contactOf = {};

  @override
  Future<String?> contactOfTransaction({required int txId}) async =>
      contactOf[txId];

  /// Outbox deliveries asked for, one after each request.
  int delivered = 0;

  @override
  Future<lepic.OutboxReport> contactsOutboxDeliver({
    required lepic.ContactRelayMode relayMode,
  }) async {
    delivered++;
    return const lepic.OutboxReport(delivered: 1, failed: 0, stuck: 0);
  }

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
    undelivered: false,
    messages: messages,
    flow: flow,
    origin: lepic.TxOrigin.wallet,
    outputCommits: const [],
    spentCommits: const [],
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

  @override
  Future<lepic.IssuedInvoice> contactIssueInvoice({
    required String contactId,
    required BigInt amount,
    String? message,
    required lepic.SlatePurpose purpose,
    String? reference,
    BigInt? expires,
    required lepic.ContactRelayMode relayMode,
  }) async {
    // A contact not paired, or one that refuses invoices, fails before anything is stored.
    if (issueError != null) throw _lepicError(issueError!);
    issued.add((
      amount: amount,
      contactId: contactId,
      message: message,
      expires: expires,
    ));
    final txId = _next++;
    final slateId = 'issued-$txId';
    // Stored and queued for the contact's mailbox; a contact has no counterparty address.
    store(
      txId,
      slateId,
      lepic.TxStatus.received,
      amount,
      transport: null,
      flow: lepic.TxFlow.invoice,
      messages: [
        if (message != null)
          lepic.SlateMessage(role: lepic.SlateRole.receiver, text: message),
      ],
    );
    contactOf[txId] = contactId;
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
  Future<lepic.PaidInvoice> contactPayInvoice({
    required String slateId,
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
    required lepic.ContactRelayMode relayMode,
  }) async {
    spends.add('contactPayInvoice');
    throw StateError('an issuer path paid');
  }

  @override
  Future<lepic.SentTx> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    lepic.SendOptions? options,
  }) async {
    spends.add('sendEpicbox');
    throw StateError('an issuer path sent');
  }

  @override
  Future<lepic.Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    lepic.SendOptions? options,
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
  late List<IssuerEvent> events;
  final five = BigInt.from(500000000);

  LepicWalletSession open(_IssuerWallet w, {WalletHistory? history}) =>
      LepicWalletSession(w, history: history);

  /// A request to the paired payer through [s] (the session by default).
  Future<IssuedInvoice> ask(
    BigInt amount, {
    String? message,
    LepicWalletSession? s,
  }) => (s ?? session).pairing.requestPayment(
    id: _payer,
    amount: amount,
    message: message,
  );

  IssuerEvent told(IssuerEventKind kind, String slateId) => IssuerEvent(
    kind: kind,
    slateId: slateId,
    payerAddress: '',
    pairingId: _payer,
  );

  setUp(() {
    wallet = _IssuerWallet();
    session = open(wallet);
    events = [];
    session.issuerEvents().listen(events.add);
  });

  tearDown(() => expect(wallet.spends, isEmpty, reason: 'an issuer spent'));

  group('issue', () {
    test('asks the contact with the cut message and an expiry', () async {
      final before = DateTime.now();
      final issued = await ask(five, message: '  ${'é' * 300} ');
      expect(wallet.issued.single.contactId, _payer);
      expect(wallet.issued.single.amount, five);
      expect(wallet.issued.single.message, 'é' * 128);
      expect(
        wallet.issued.single.expires!.toInt(),
        closeTo(before.add(invoiceExpiry).millisecondsSinceEpoch ~/ 1000, 5),
      );
      // Posted at once, not on the next collect.
      expect(wallet.delivered, 1);
      expect(issued.slateId, 'issued-40');
      expect(issued.txId, 40);
      // The pairing names the payer; its mailbox is no address to show (RFC C-21).
      expect(issued.payerAddress, isEmpty);
      expect(issued.pairingId, _payer);
      expect(issued.message, 'é' * 128);
      expect(issued.state, IssuedInvoiceState.waiting);
      expect(issued.issuedAt.isBefore(before), isFalse);
      expect(issued.expiresAt.difference(issued.issuedAt), invoiceExpiry);
      final kept = await session.issuedInvoice(slateId: issued.slateId);
      expect(kept?.pairingId, _payer);
    });

    test('a blank message goes as none', () async {
      await ask(five, message: ' ');
      expect(wallet.issued.single.message, isNull);
    });

    test('no amount never reaches LEPIC', () async {
      await expectLater(
        ask(BigInt.zero),
        _kind(WalletErrorKind.invalidArgument),
      );
      expect(wallet.issued, isEmpty);
      expect(await session.issuedInvoices(), isEmpty);
    });

    test('a contact that refuses invoices is a pairing failure, nothing kept', () async {
      wallet.issueError = lepic.WalletErrorKind.contactRefusesInvoices;
      await expectLater(ask(five), throwsA(isA<WalletError>()));
      expect(wallet.cancelled, isEmpty);
      expect(await session.issuedInvoices(), isEmpty);
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
      final a = await ask(five);
      final b = await ask(five);
      final c = await ask(five);
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
        told(IssuerEventKind.paid, a.slateId),
        told(IssuerEventKind.declined, b.slateId),
        told(IssuerEventKind.expired, c.slateId),
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
      final a = await ask(five);
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
      final a = await ask(five);
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
      final a = await ask(five);
      final b = await ask(five);
      // LEPIC raises it again for a bounce redelivered before it was settled.
      wallet.eventSink
        ..add(bounce(a))
        ..add(bounce(a));
      await _settle();
      expect(events, [
        told(IssuerEventKind.bounced, a.slateId),
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
        final a = await ask(five);
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
          told(IssuerEventKind.bounced, a.slateId),
        ]);
        expect(wallet.cancelled, [a.txId]);
        // The listener's own stream shows the connection, not the bounce.
        expect([for (final e in seen) e.kind], [ListenerEventKind.connected]);
      },
    );

    test('the listener\'s bounce alone marks, withdraws and tells', () async {
      final a = await ask(five);
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
        told(IssuerEventKind.bounced, a.slateId),
      ]);
      expect(wallet.cancelled, [a.txId]);
      expect(
        (await session.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.bounced,
      );
    });

    test('a bounce for a request already ended changes nothing', () async {
      final a = await ask(five);
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
            counterparty: _restoredPayer,
            flow: lepic.TxFlow.invoice,
          )
          ..store(
            61,
            'restored-paid',
            lepic.TxStatus.confirmed,
            five,
            counterparty: _restoredPayer,
            flow: lepic.TxFlow.invoice,
          )
          // A plain receive is no request.
          ..store(
            62,
            'payment',
            lepic.TxStatus.received,
            five,
            counterparty: _restoredPayer,
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
            payerAddress: _restoredPayer,
          ),
        ]);
      },
    );
  });

  group('withdraw', () {
    test('cancels a waiting request and says so', () async {
      final a = await ask(five);
      final withdrawn = await session.withdrawInvoice(slateId: a.slateId);
      expect(withdrawn.state, IssuedInvoiceState.withdrawn);
      expect(wallet.cancelled, [a.txId]);
      await _settle();
      expect(events, [
        told(IssuerEventKind.withdrawn, a.slateId),
      ]);
      // The cancelled transaction is not taken for an expiry afterwards.
      expect(
        (await session.issuedInvoices()).single.state,
        IssuedInvoiceState.withdrawn,
      );
    });

    test('refuses one that is no longer waiting, or unknown', () async {
      final a = await ask(five);
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
      final a = await ask(five);
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
      final a = await ask(five);
      final b = await ask(five);
      final c = await ask(five);
      wallet
        ..setStatus(a.txId!, lepic.TxStatus.posted)
        ..setStatus(b.txId!, lepic.TxStatus.cancelled);
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
          told(IssuerEventKind.paid, a.slateId),
          told(IssuerEventKind.expired, b.slateId),
        ]),
      );
    });

    test('a single request is caught up too, for its details', () async {
      final a = await ask(five);
      wallet.setStatus(a.txId!, lepic.TxStatus.posted);
      expect(
        (await session.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.paid,
      );
      expect(await session.issuedInvoice(slateId: 'nope'), isNull);
      await _settle();
      expect(events, [
        told(IssuerEventKind.paid, a.slateId),
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
      final a = await ask(five, message: 'Dinner', s: first);
      await first.withdrawInvoice(slateId: a.slateId);
      final b = await ask(five, s: first);
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
    contactOf.addAll(before.contactOf);
  }

}
