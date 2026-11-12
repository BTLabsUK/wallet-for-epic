// SPDX-License-Identifier: Apache-2.0
// Designer-frame visits: Activity and Payment-*. Add `('fr-<Frame>', _Start.home, visit)` entries
// to the list and, when a frame needs its own data, a seed to `_activitySeeds`. See tool/tour/FRAMES.md.
part of '../screenshot_tour_test.dart';

final List<(String, _Start, _Visit)> _framesActivity = [
  (
    'fr-Activity',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      await t.tap(find.descendant(of: find.byType(KitTabBar), matching: find.text(t.l.historyTitle)));
      await _clearToasts(t);
      await t.shot('fr-Activity');
    },
  ),
  (
    'fr-Payment-1-Waiting',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      await t.push(TxDetailsScreen(txKey: 's:$_payWaitingId'));
      await _clearToasts(t);
      await t.shot('fr-Payment-1-Waiting');
    },
  ),
  (
    'fr-Payment-2-Done',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      await t.push(TxDetailsScreen(txKey: 's:$_payDoneId'));
      await _clearToasts(t);
      await t.shot('fr-Payment-2-Done');
    },
  ),
  (
    'fr-Payment-3-Details',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      await t.push(TxDetailsScreen(txKey: 's:$_payDoneId'));
      await t.tapText(t.l.phonePayMore);
      await _clearToasts(t);
      await t.shot('fr-Payment-3-Details');
    },
  ),
  (
    'fr-Payment-4-Via',
    _Start.home,
    (t) async {
      await _clearToasts(t);
      await t.push(TxDetailsScreen(txKey: 's:$_payDoneId'));
      await t.tapText(t.l.phonePayRouteEpicbox);
      await _clearToasts(t);
      await t.shot('fr-Payment-4-Via');
    },
  ),
];

/// The Activity frame's wallet: three payments under way, an invoice waiting, then Today and
/// Yesterday. Three confirmations count, as "Confirming 2 of 3" says.
void _activityList(FakeWalletSession s) {
  s.summaryValue = s.summaryValue.copyWith(minimumConfirmations: BigInt.from(3));
  s.pairing.seedPaired(
    id: 'p-northwind',
    name: 'Northwind Exchange',
    contactId: 'f-nw',
    peerProfile: 2,
    allowInvoices: true,
    paymentsAddress: _fNorthwind,
  );
  s.pendingInvoicesValue['inv-1042'] = PendingInvoice(
    slateId: 'inv-1042',
    senderAddress: _fNorthwind,
    pairingId: 'p-northwind',
    amount: _epic(42.5),
    receivedAt: frameNow.subtract(const Duration(minutes: 20)),
    expiresAt: frameNow.add(const Duration(hours: 23)),
  );
  s.transactionsValue
    ..clear()
    ..addAll([
      _fTx(1, out: false, amount: 25.0, at: _at(0, 14, 48), who: _fAnna, status: TxStatus.awaitingConfirmation, depth: 1),
      _fTx(2, out: true, amount: 12.5, at: _at(0, 14, 40), who: _fTom, status: TxStatus.awaitingRecipient),
      _fTx(3, out: false, amount: 12.0, at: _at(0, 14, 30), who: _fAnna, status: TxStatus.awaitingConfirmation, pending: true),
      _fTx(4, out: true, amount: 9.294, at: _at(0, 9, 12), who: _fCoffee, note: 'Coffee beans'),
      _fTx(5, out: false, amount: 150.0, at: _at(1, 18, 30), who: _fBob, sealed: true),
      _fTx(6, out: true, amount: 10.0, at: _at(1, 11, 5), who: _fMira, status: TxStatus.cancelled),
    ]);
}

/// Per-frame data on top of the base wallet (frame_data.dart), by visit name.
final Map<String, void Function(FakeWalletSession s)> _activitySeeds = {
  'fr-Activity': _activityList,
  'fr-Payment-1-Waiting': _payWaiting,
  'fr-Payment-2-Done': _payDone,
  'fr-Payment-3-Details': _payDone,
  'fr-Payment-4-Via': _payDone,
};


/// The payment pages' frames: the open payment of Payment-1 and the finished one of Payment-2 to -4,
/// both to Tom through Epicbox (sealed), with the address Payment-3 prints.
const String _payWaitingId = 'f0000000-0000-4000-8000-0000000000a1';
const String _payDoneId = '3f9a1c00-0000-4000-8000-0000000e27b4';
final String _fTomPay = 'es7vRxu45g3aHi5nmxuvjG7nRCZWuQR2wxTzXgKguN5pTurMJ7z@$mockBox';

void _payBase(FakeWalletSession s, List<TxEntry> txs) {
  final tom = s.contactsValue.indexWhere((c) => c.id == 'f-tom');
  s.contactsValue[tom] = Contact(id: 'f-tom', name: 'Tom', address: _fTomPay);
  s.pairing.seedPaired(
    id: 'p-tom',
    name: 'Tom',
    contactId: 'f-tom',
    peerProfile: 2,
    allowInvoices: true,
    paymentsAddress: _fTomPay,
  );
  s.transactionsValue
    ..clear()
    ..addAll(txs);
}

TxEntry _payTx(
  String slateId, {
  required num amount,
  required int at,
  TxStatus status = TxStatus.confirmed,
  String? note,
  int? height,
}) {
  final fee = _epic(0.008);
  return fakeTx(
    id: 90,
    slateId: slateId,
    kind: TxKind.sent,
    status: status,
    createdAtUnix: at,
    timeUnix: at,
    blockHeight: status == TxStatus.confirmed ? _tip - BigInt.from(height ?? 5700) : null,
    blockTimeUnix: status == TxStatus.confirmed ? at : null,
    amountDebited: _epic(amount) + fee,
    amountCredited: BigInt.zero,
    fee: fee,
    numInputs: 2,
    outputCommits: [for (final c in ['a1', 'b2']) '08${c * 33}'],
    counterparty: _fTomPay,
    transport: 'epicbox',
    pairingId: 'p-tom',
    note: note,
  );
}

void _payWaiting(FakeWalletSession s) => _payBase(s, [
  _payTx(_payWaitingId, amount: 12.5, at: _at(0, 18, 12), status: TxStatus.awaitingRecipient, note: 'Tickets'),
]);

void _payDone(FakeWalletSession s) => _payBase(s, [
  _payTx(_payDoneId, amount: 25.0, at: _unix(DateTime(2026, 11, 2, 20, 31))),
]);
