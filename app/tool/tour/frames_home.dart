// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Home, Home-busy, Contacts, Contact-Tom (the tab bar is in all of them).
part of '../screenshot_tour_test.dart';

final List<(String, _Start, _Visit)> _framesHome = [
  ('fr-Home', _Start.home, (t) => t.shot('fr-Home')),
  (
    'fr-Contacts',
    _Start.home,
    (t) async {
      // Anna's second payment came in this minute: her row says Now, as drawn.
      frameClockAt = DateTime(2026, 11, 12, 18, 13, 20);
      final container = ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first));
      await container.read(pendingInvoicesProvider.notifier).refresh();
      await t.tap(find.descendant(of: find.byType(KitTabBar), matching: find.text(t.l.contactsTitle)));
      await t.frames();
      await t.shot('fr-Contacts');
    },
  ),
  (
    'fr-Contact-Tom',
    _Start.home,
    (t) async {
      await t.tap(find.descendant(of: find.byType(KitTabBar), matching: find.text(t.l.contactsTitle)));
      await t.frames();
      // The strip comes before the list: its first "Tom" opens the page.
      await t.tap(find.text('Tom').first);
      await t.frames();
      await t.shot('fr-Contact-Tom');
    },
  ),
  (
    'fr-Home-busy',
    _Start.home,
    (t) async {
      // The relay drops after the first connect: the pill says Reconnecting.
      t.session.listenerEvents.add(const ListenerEvent(kind: ListenerEventKind.disconnected, message: 'timeout'));
      final container = ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first));
      await container.read(pendingInvoicesProvider.notifier).refresh();
      await t.frames();
      await t.shot('fr-Home-busy');
    },
  ),
];

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _homeSeeds = {
  // Three payments under way, an invoice to review, 3 confirmations to wait for.
  'fr-Home-busy': (s) {
    s.summaryValue = WalletSummary(
      lastConfirmedHeight: _tip,
      minimumConfirmations: BigInt.from(3),
      total: parseEpic('1284.7321'),
      spendable: parseEpic('1284.7321') - parseEpic('37.0'),
      awaitingConfirmation: parseEpic('37.0'),
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: parseEpic('15.713'),
      validatedWithNode: true,
    );
    s.transactionsValue = [
      // Two of three blocks: Confirming 2 of 3.
      _fTx(11, out: false, amount: 25.0, at: _at(0, 14, 48), who: _fAnna, status: TxStatus.awaitingConfirmation, height: _tip - BigInt.one),
      _fTx(12, out: true, amount: 12.5, at: _at(0, 14, 30), who: _fTom, sealed: true, status: TxStatus.awaitingRecipient),
      _fTx(13, out: false, amount: 12.0, at: _at(0, 14, 10), who: _fAnna, status: TxStatus.awaitingConfirmation),
      ...s.transactionsValue,
    ];
    _seedNorthwindAsk(s);
  },
  // The people view: Northwind asks, two payments from Anna on their way, Tom's wallet to answer,
  // Bob's sealed payment yesterday, Mira without any.
  'fr-Contact-Tom': _seedTomPage,
  'fr-Contacts': (s) {
    _seedNorthwindAsk(s);
    s.pairing.seedPaired(id: 'p-tom', name: 'Tom', contactId: 'f-tom', paymentsAddress: _fTom, nativeSlates: true);
    s.transactionsValue = [
      _fTx(11, out: false, amount: 37.0, at: _at(0, 18, 13), who: _fAnna, status: TxStatus.awaitingConfirmation),
      _fTx(13, out: false, amount: 12.0, at: _at(0, 14, 20), who: _fAnna, status: TxStatus.awaitingConfirmation),
      _fTx(12, out: true, amount: 12.5, at: _at(0, 18, 12), who: _fTom, sealed: true, status: TxStatus.awaitingRecipient),
      _fTx(6, out: false, amount: 150.0, at: _at(1, 16, 40), who: _fBob, sealed: true),
      ...s.transactionsValue,
    ];
  },
};

/// Tom is paired and sealed: a lunch he paid, a sent payment, and 12.5 still waiting on his wallet.
void _seedTomPage(FakeWalletSession s) {
  s.pairing.seedPaired(id: 'p-tom', name: 'Tom', contactId: 'f-tom', paymentsAddress: _fTom, nativeSlates: true);
  s.transactionsValue = [
    _fTx(21, out: true, amount: 12.5, at: _at(0, 18, 12), who: _fTom, note: 'Tickets', label: 'Tickets', sealed: true, status: TxStatus.awaitingRecipient),
    _fTx(22, out: true, amount: 25.0, at: _at(10, 12, 0), who: _fTom, sealed: true),
    _fTx(23, out: false, amount: 40.0, at: _at(15, 13, 0), who: _fTom, note: 'Lunch', label: 'Lunch', sealed: true),
    // The base wallet's own payment to Tom is replaced by these.
    for (final tx in s.transactionsValue)
      if (tx.counterparty != _fTom) tx,
  ];
}

/// Northwind Exchange is paired and asks for 42.5 EPIC (Home-busy's card, Contacts' gold row).
void _seedNorthwindAsk(FakeWalletSession s) {
  s.pairing.seedPaired(id: 'p-nw', name: 'Northwind Exchange', contactId: 'f-nw', paymentsAddress: _fNorthwind, allowInvoices: true);
  s.pendingInvoicesValue['inv-nw'] = PendingInvoice(
    slateId: 'inv-nw',
    senderAddress: _fNorthwind,
    amount: _epic(42.5),
    receivedAt: frameNow.subtract(const Duration(hours: 1)),
    expiresAt: frameNow.add(const Duration(hours: 23)),
    pairingId: 'p-nw',
  );
}
