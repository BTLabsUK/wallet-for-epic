// SPDX-License-Identifier: Apache-2.0
// Payment details in every state: sent and received, for an invoice, in person, a file and a normal
// send, each waiting, posted, confirmed and cancelled. Shot ids are `pd-<method>-<direction>-<state>`.
part of '../screenshot_tour_test.dart';

const List<(String, TxStatus)> _pdStates = [
  ('waiting', TxStatus.awaitingRecipient),
  ('posted', TxStatus.awaitingConfirmation),
  ('confirmed', TxStatus.confirmed),
  ('cancelled', TxStatus.cancelled),
];

/// One visit per method and direction: it adds the four payments, then opens each in turn.
int _pdCounter = 0;

(String, _Start, _Visit) _pdVisit(String method, bool sent, {String transport = 'epicbox', TxFlow flow = TxFlow.payment, Epic1Via? via}) {
  final dir = sent ? 'sent' : 'received';
  final name = 'pd-$method-$dir';
  final pdSeq = _pdCounter++;
  return (
    name,
    _Start.home,
    (t) async {
      final base = pdSeq;
      var n = 0;
      final keys = <String>[];
      for (final (_, status) in _pdStates) {
        final id = 700 + base * 4 + n;
        final slate = 'a1b2c3d4-0007-4e5f-8a9b-${(id + 100000).toString().padLeft(12, '0')}';
        keys.add(slate);
        t.session.transactionsValue.add(
          fakeTx(
            id: id,
            slateId: slate,
            kind: sent ? TxKind.sent : TxKind.received,
            status: status,
            flow: flow,
            createdAtUnix: DateTime.now().subtract(Duration(days: 1 + n)).millisecondsSinceEpoch ~/ 1000,
            amountDebited: sent ? _epic(12.5) : null,
            amountCredited: sent ? null : _epic(12.5),
            fee: sent ? _epic(0.008) : null,
            numInputs: sent ? 1 : 0,
            numOutputs: 1,
            counterparty: _bob,
            transport: via != null ? null : transport,
            epic1Via: via,
            blockHeight: status == TxStatus.confirmed ? _tip - BigInt.from(2000) : null,
          ),
        );
        n++;
      }
      ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first)).invalidate(homeProvider);
      await t.frames();
      for (var i = 0; i < keys.length; i++) {
        await t.push(TxDetailsScreen(txKey: 's:${keys[i]}'));
        await t.shot('$name-${_pdStates[i].$1}');
        t.tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await t.frames();
      }
    },
  );
}

final List<(String, _Start, _Visit)> _paymentStates = [
  for (final sent in [true, false]) ...[
    _pdVisit('normal', sent),
    _pdVisit('invoice', sent, flow: TxFlow.invoice),
    _pdVisit('inperson', sent, via: Epic1Via.inPerson),
    _pdVisit('file', sent, transport: 'file'),
  ],
  _pdVisit('tor', true, transport: 'tor'),
  _pdVisit('http', false, transport: 'http'),
];
