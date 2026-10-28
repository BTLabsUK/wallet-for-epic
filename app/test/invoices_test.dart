// SPDX-License-Identifier: Apache-2.0
// The invoice service layer (I-01) against the fake: drains, pay, decline, expiry, a failed
// reply, invoices only from paired contacts with Allow invoices on, and the providers over them.
import 'dart:io';

import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/pairing_providers.dart' show invoicesOnProvider;

/// A valid epicbox address with a key made of [c].
String addr(String c, {String relay = 'epicbox.epiccash.com'}) =>
    '${'es$c'.padRight(52, c)}@$relay';

final shop = addr('S');
final exchange = addr('X');
final stranger = addr('Z');

final eight = BigInt.from(800000000);

FakeWalletSession funded({WalletHistory? history}) => FakeWalletSession(
  invoiceHistory: history,
  summary: WalletSummary(
    lastConfirmedHeight: BigInt.from(100),
    minimumConfirmations: BigInt.from(3),
    total: BigInt.from(10000000000),
    spendable: BigInt.from(10000000000),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: true,
  ),
);

/// [address] as a verified paired contact named [name] with Allow invoices on: its invoices park.
PairingRecord allow(FakeWalletSession s, String address, String name) =>
    s.pairing.seedPaired(name: name, allowInvoices: true, paymentsAddress: address);

Matcher invalidArgument(String text) => throwsA(
  isA<WalletError>()
      .having((e) => e.kind, 'kind', WalletErrorKind.invalidArgument)
      .having((e) => e.message, 'message', contains(text)),
);

Matcher _kind(WalletErrorKind kind, String text) => throwsA(
  isA<WalletError>()
      .having((e) => e.kind, 'kind', kind)
      .having((e) => e.message, 'message', contains(text)),
);

Matcher amountMismatch(String text) =>
    _kind(WalletErrorKind.amountMismatch, text);

Matcher invoiceNotFound(String text) =>
    _kind(WalletErrorKind.invoiceNotFound, text);

void main() {
  group('fake session', () {
    late FakeWalletSession s;
    late List<InvoiceEvent> events;
    late DateTime now;

    setUp(() async {
      s = funded();
      now = DateTime.utc(2026, 10, 5, 12);
      s.clock = () => now;
      events = [];
      s.invoiceEvents().listen(events.add);
      allow(s, shop, 'Shop');
    });

    test('a drain parks invoices from trusted services only', () async {
      s.relayInvoice(
        from: shop,
        slateId: 'i1',
        amount: eight,
        message: 'Order 7',
      );
      s.relayInvoice(from: stranger, slateId: 'junk', amount: eight);
      // The domain proves nothing: the key alone decides.
      s.relayInvoice(
        from: addr('S', relay: 'evil.example'),
        slateId: 'i2',
        amount: BigInt.one,
      );
      expect(
        await s.pendingInvoices(),
        isEmpty,
        reason: 'nothing before a drain',
      );

      final report = await s.drainInvoices();
      expect(report, const InvoiceDrainReport(parked: 2, dropped: 1));
      final pending = await s.pendingInvoices();
      expect([for (final i in pending) i.slateId], ['i1', 'i2']);
      expect(pending.first.senderAddress, shop);
      expect(pending.first.message, 'Order 7');
      expect(pending.first.expiresAt, now.add(const Duration(hours: 24)));
      await pumpEventQueue();
      expect(events.map((e) => (e.kind, e.slateId)), [
        (InvoiceEventKind.received, 'i1'),
        (InvoiceEventKind.received, 'i2'),
      ]);

      // A second copy of a known invoice changes nothing; an empty drain finds nothing.
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
      expect(await s.drainInvoices(), const InvoiceDrainReport());
      expect(await s.pendingInvoices(), hasLength(2));
    });

    test('pay needs the invoiced amount', () async {
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
      await s.drainInvoices();

      await expectLater(
        s.payInvoice(slateId: 'i1', amount: eight + BigInt.one),
        amountMismatch('amount does not match'),
      );
      expect(s.invoicePayments, 0);
      expect(await s.pendingInvoices(), hasLength(1), reason: 'still pending');

      final paid = await s.payInvoice(slateId: 'i1', amount: eight);
      expect(paid.status, InvoiceStatus.replied);
      expect(paid.senderAddress, shop);
      expect(s.deliveredReplies, ['i1']);
      expect(await s.pendingInvoices(), isEmpty);
      expect(await s.paidInvoice(slateId: 'i1'), paid);
      final tx = s.transactionsValue.single;
      expect((tx.id, tx.slateId, tx.kind), (paid.txId, 'i1', TxKind.sent));
      expect(tx.amountDebited, eight + s.fee);

      // Paid once: a second pay finds no pending invoice.
      await expectLater(
        s.payInvoice(slateId: 'i1', amount: eight),
        invoiceNotFound('no pending invoice'),
      );
      expect(s.invoicePayments, 1);
    });

    test('decline takes it off the list and tells the service', () async {
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
      await s.drainInvoices();
      await s.declineInvoice(slateId: 'i1');
      expect(await s.pendingInvoices(), isEmpty);
      expect(s.declinedInvoices, ['i1']);
      expect(s.invoicePayments, 0);
      await pumpEventQueue();
      expect(
        events.last,
        const InvoiceEvent(kind: InvoiceEventKind.declined, slateId: 'i1'),
      );
      await expectLater(
        s.declineInvoice(slateId: 'i1'),
        invoiceNotFound('no pending invoice'),
      );
    });

    test('an invoice expires and can no longer be paid', () async {
      s.relayInvoice(
        from: shop,
        slateId: 'i1',
        amount: eight,
        expiresIn: const Duration(hours: 2),
      );
      await s.drainInvoices();
      final invoice = (await s.pendingInvoices()).single;
      expect(invoice.timeLeftAt(now), const Duration(hours: 2));

      now = now.add(const Duration(hours: 2));
      expect(invoice.isExpiredAt(now), isTrue);
      expect(
        invoice.timeLeftAt(now.add(const Duration(minutes: 1))),
        Duration.zero,
      );
      expect(await s.pendingInvoices(), isEmpty);
      await pumpEventQueue();
      expect(
        events.last,
        const InvoiceEvent(kind: InvoiceEventKind.expired, slateId: 'i1'),
      );
      await expectLater(
        s.payInvoice(slateId: 'i1', amount: eight),
        invoiceNotFound('no pending invoice'),
      );
      expect(s.invoicePayments, 0);
    });

    test('an invoice open longer than 48 h is dropped', () async {
      s.relayInvoice(
        from: shop,
        slateId: 'max',
        amount: eight,
        expiresIn: maxInvoiceExpiry,
      );
      s.relayInvoice(
        from: shop,
        slateId: 'long',
        amount: eight,
        expiresIn: maxInvoiceExpiry + const Duration(seconds: 1),
      );
      expect(
        await s.drainInvoices(),
        const InvoiceDrainReport(parked: 1, dropped: 1),
      );
      expect([for (final i in await s.pendingInvoices()) i.slateId], ['max']);
    });

    test('a failed reply is resent without a second payment', () async {
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
      await s.drainInvoices();
      s.replyError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay unreachable',
      );

      final paid = await s.payInvoice(slateId: 'i1', amount: eight);
      expect(paid.status, InvoiceStatus.replyFailed);
      expect(s.deliveredReplies, isEmpty);
      expect(
        s.transactionsValue,
        hasLength(1),
        reason: 'the payment is stored',
      );

      // Still failing: the resend says so and the payment stays as it is.
      await expectLater(
        s.resendInvoiceReply(slateId: 'i1'),
        throwsA(
          isA<WalletError>().having(
            (e) => e.kind,
            'kind',
            WalletErrorKind.transportFailed,
          ),
        ),
      );
      expect(
        (await s.paidInvoice(slateId: 'i1'))!.status,
        InvoiceStatus.replyFailed,
      );

      s.replyError = null;
      final resent = await s.resendInvoiceReply(slateId: 'i1');
      expect(resent.status, InvoiceStatus.replied);
      expect(s.deliveredReplies, ['i1']);
      expect(s.invoicePayments, 1, reason: 'resend signs nothing');
      expect(s.transactionsValue, hasLength(1));

      // A delivered reply the service never posted goes again (linux-12), still signing
      // nothing.
      expect(await s.resendInvoiceReply(slateId: 'i1'), resent);
      expect(s.deliveredReplies, ['i1', 'i1']);
      expect(s.invoicePayments, 1);
    });

    test('notices count only from the invoice\'s own service', () async {
      allow(s, exchange, 'Exchange');
      s.relayInvoice(from: shop, slateId: 'paid', amount: eight);
      s.relayInvoice(from: shop, slateId: 'open', amount: eight);
      await s.drainInvoices();
      final paid = await s.payInvoice(slateId: 'paid', amount: eight);

      // Another trusted service, a stranger, and an unknown slate are all dropped.
      s.relayNotice(
        from: exchange,
        kind: InvoiceEventKind.posted,
        slateId: 'paid',
        kernelExcess: 'k',
      );
      s.relayNotice(
        from: stranger,
        kind: InvoiceEventKind.withdrawn,
        slateId: 'open',
      );
      s.relayNotice(from: shop, kind: InvoiceEventKind.posted, slateId: 'nope');
      // A receipt for an invoice not paid means nothing.
      s.relayNotice(from: shop, kind: InvoiceEventKind.posted, slateId: 'open');
      expect(await s.drainInvoices(), const InvoiceDrainReport(dropped: 4));
      expect(
        (await s.paidInvoice(slateId: 'paid'))!.status,
        InvoiceStatus.replied,
      );
      expect(await s.pendingInvoices(), hasLength(1));

      s.relayNotice(
        from: shop,
        kind: InvoiceEventKind.posted,
        slateId: 'paid',
        kernelExcess: '08ab',
      );
      s.relayNotice(
        from: shop,
        kind: InvoiceEventKind.withdrawn,
        slateId: 'open',
      );
      expect(await s.drainInvoices(), const InvoiceDrainReport(notices: 2));
      final receipt = (await s.paidInvoice(slateId: 'paid'))!;
      expect(
        (receipt.status, receipt.kernelExcess),
        (InvoiceStatus.posted, '08ab'),
      );
      expect(await s.pendingInvoices(), isEmpty);
      await pumpEventQueue();
      expect(events.reversed.take(2), [
        const InvoiceEvent(kind: InvoiceEventKind.withdrawn, slateId: 'open'),
        const InvoiceEvent(
          kind: InvoiceEventKind.posted,
          slateId: 'paid',
          kernelExcess: '08ab',
        ),
      ]);
      expect(s.cancelledTxIds, isEmpty);
      expect(paid.txId, isNotNull);
    });

    test('a withdrawal after payment is shown, never acted on', () async {
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
      await s.drainInvoices();
      await s.payInvoice(slateId: 'i1', amount: eight);
      s.relayNotice(
        from: shop,
        kind: InvoiceEventKind.withdrawn,
        slateId: 'i1',
      );
      await s.drainInvoices();
      expect(
        (await s.paidInvoice(slateId: 'i1'))!.status,
        InvoiceStatus.withdrawn,
      );
      expect(s.cancelledTxIds, isEmpty, reason: 'the user confirms a cancel');
    });

    test('Allow invoices off declines the open requests and drops the next', () async {
      final paired = s.pairing.records.single;
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
      await s.drainInvoices();
      expect(await s.pairing.setAllowInvoices(paired.id, false), 1);
      expect(await s.pendingInvoices(), isEmpty);
      expect(s.declinedInvoices, ['i1']);
      s.relayInvoice(from: shop, slateId: 'i2', amount: eight);
      expect((await s.drainInvoices()).dropped, 1);
      expect(s.invoicePayments, 0);
    });

    test('a paired contact not verified cannot be allowed', () async {
      final r = s.pairing.seedPaired(name: 'Tom', state: PairingState.paired, paymentsAddress: exchange);
      await expectLater(s.pairing.setAllowInvoices(r.id, true), invalidArgument('check the words'));
      s.relayInvoice(from: exchange, slateId: 'x1', amount: eight);
      expect((await s.drainInvoices()).dropped, 1);
    });

    test('a parked invoice carries its pairing and reference', () async {
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight, reference: 'NW-48213');
      await s.drainInvoices();
      final invoice = (await s.pendingInvoices()).single;
      expect(invoice.pairingId, s.pairing.records.single.id);
      expect(invoice.reference, 'NW-48213');
    });

    test('a core without invoices refuses every call', () async {
      s.invoicesSupported = false;
      expect(s.supportsInvoices, isFalse);
      await expectLater(s.drainInvoices(), throwsA(isA<WalletError>()));
      await expectLater(
        s.payInvoice(slateId: 'i1', amount: eight),
        throwsA(isA<WalletError>()),
      );
      expect(() => s.invoiceEvents(), throwsA(isA<WalletError>()));
    });
  });

  group('providers', () {
    late FakeWalletSession s;
    late ProviderContainer container;

    ProviderContainer start({bool supported = true}) {
      s = funded()..invoicesSupported = supported;
      container = ProviderContainer(overrides: [invoicesOnProvider.overrideWithValue(true)]);
      addTearDown(container.dispose);
      container.read(sessionProvider.notifier).unlocked(s);
      return container;
    }

    Future<List<PendingInvoice>> pending() async {
      container.listen(pendingInvoicesProvider, (_, _) {});
      return container.read(pendingInvoicesProvider.future);
    }

    test('the first read drains, and so does a refresh', () async {
      start();
      allow(s, shop, 'Shop');
      s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
      s.relayInvoice(from: stranger, slateId: 'junk', amount: eight);
      container.listen(pendingInvoiceCountProvider, (_, _) {});
      expect(
        container.read(pendingInvoiceCountProvider),
        0,
        reason: 'before the drain',
      );

      expect([for (final i in await pending()) i.slateId], ['i1']);
      expect(container.read(pendingInvoiceCountProvider), 1);

      s.relayInvoice(from: shop, slateId: 'i2', amount: eight);
      s.relayInvoice(from: stranger, slateId: 'junk2', amount: eight);
      await container.read(pendingInvoicesProvider.notifier).refresh();
      expect(container.read(pendingInvoicesProvider).value, hasLength(2));
      expect(container.read(pendingInvoiceCountProvider), 2);

      container.read(pendingInvoicesProvider.notifier).answered('i1');
      expect(
        [
          for (final i in container.read(pendingInvoicesProvider).value!)
            i.slateId,
        ],
        ['i2'],
      );
    });

    test('an expired invoice drops out as its time passes', () async {
      start();
      allow(s, shop, 'Shop');
      s.relayInvoice(
        from: shop,
        slateId: 'soon',
        amount: eight,
        expiresIn: const Duration(milliseconds: 60),
      );
      s.relayInvoice(from: shop, slateId: 'later', amount: eight);
      expect(await pending(), hasLength(2));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(
        [
          for (final i in container.read(pendingInvoicesProvider).value!)
            i.slateId,
        ],
        ['later'],
      );
    });

    test(
      'a receipt reaches the paid invoice\'s details on the next drain',
      () async {
        start();
        allow(s, shop, 'Shop');
        s.relayInvoice(from: shop, slateId: 'i1', amount: eight);
        await pending();
        await s.payInvoice(slateId: 'i1', amount: eight);
        container.listen(paidInvoiceProvider('i1'), (_, _) {});
        expect(
          (await container.read(paidInvoiceProvider('i1').future))!.status,
          InvoiceStatus.replied,
        );

        s.relayNotice(
          from: shop,
          kind: InvoiceEventKind.posted,
          slateId: 'i1',
          kernelExcess: '08ab',
        );
        await container.read(pendingInvoicesProvider.notifier).refresh();
        expect(
          (await container.read(paidInvoiceProvider('i1').future))!.status,
          InvoiceStatus.posted,
        );
      },
    );

    test(
      'without invoices nothing is called and everything is empty',
      () async {
        start(supported: false);
        expect(await pending(), isEmpty);
        container.listen(paidInvoiceProvider('i1'), (_, _) {});
        expect(await container.read(paidInvoiceProvider('i1').future), isNull);
        expect(container.read(pendingInvoiceCountProvider), 0);
      },
    );

    test('no invoice event, drain or notice leads to a payment', () async {
      start();
      allow(s, shop, 'Shop');
      final seen = <InvoiceEvent>[];
      s.invoiceEvents().listen(seen.add);
      container.listen(pendingInvoiceCountProvider, (_, _) {});
      container.listen(paidInvoiceProvider('i1'), (_, _) {});
      for (var n = 0; n < 3; n++) {
        s.relayInvoice(from: shop, slateId: 'i$n', amount: eight);
        s.relayNotice(
          from: shop,
          kind: InvoiceEventKind.withdrawn,
          slateId: 'i${n - 1}',
        );
        await container.read(pendingInvoicesProvider.notifier).refresh();
      }
      await pumpEventQueue();
      expect(
        seen.where((e) => e.kind == InvoiceEventKind.received),
        hasLength(3),
      );
      expect(s.invoicePayments, 0);
      expect(s.deliveredReplies, isEmpty);
      expect(s.transactionsValue, isEmpty);
    });
  });

  test('the app calls payInvoice from no file but the wallet layer', () {
    // Paying belongs to the review screen, after the PIN or biometric gate (I-03). Any other
    // caller in lib/ is a path from an invoice to a payment that skips the user.
    const allowed = {
      'lib/src/wallet_service.dart',
      'lib/src/lepic_wallet_service.dart',
      // The web client sends the review screen's call to the server, whose dispatcher hands
      // it to the wallet there. Neither starts a payment itself.
      'lib/src/remote/client.dart',
      'lib/src/remote/dispatcher.dart',
      // A pass-through that gates PIN calls on the demo server; it pays nothing itself.
      'lib/src/demo_server/gated_service.dart',
      // Approve, after askPin; test/invoice_screens_test.dart proves the gate comes first.
      'lib/src/ui/invoice_review_screen.dart',
    };
    final callers = [
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') &&
            // The desktop has its own check (test/desktop/lepic_desk_invoices_test.dart).
            !f.path.replaceAll(r'\', '/').startsWith('lib/src/desktop/') &&
            f.readAsStringSync().contains('payInvoice(') &&
            !allowed.contains(f.path.replaceAll(r'\', '/')))
          f.path,
    ];
    expect(callers, isEmpty);
  });
}
