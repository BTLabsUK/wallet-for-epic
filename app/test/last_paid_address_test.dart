// SPDX-License-Identifier: Apache-2.0
// Which of a contact's addresses Send pays first: the one its newest successful send went to.

import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _epicbox = 'esYHnzCd6PjFmUeUBxFjwApmDe5jRVWFeGGqQsvAj5zrgFWtbR2P@epicbox.example.org';
const _url = 'https://wallet.example.org';
final _contact = Contact(id: 'c1', name: 'Ana', epicbox: _epicbox, http: _url);

TxEntry _tx(String? to, int time, {TxKind kind = TxKind.sent, TxStatus status = TxStatus.confirmed}) => TxEntry(
  key: 'l:$time',
  id: time,
  kind: kind,
  status: status,
  source: TxSource.wallet,
  createdAtUnix: time,
  timeUnix: time,
  confirmed: status == TxStatus.confirmed,
  amountCredited: BigInt.zero,
  amountDebited: BigInt.from(100000000),
  numInputs: 1,
  numOutputs: 1,
  outputCommits: const [],
  counterparty: to,
  cancellable: false,
  repostable: false,
  releasable: false,
);

void main() {
  test('the newest successful send names the address', () {
    final txs = [_tx(_epicbox, 10), _tx(_url, 20), _tx(_epicbox, 5)];
    expect(lastPaidAddress(_contact, txs), _url);
  });

  test('a cancelled, received or unanswered send does not count', () {
    final txs = [
      _tx(_url, 30, status: TxStatus.cancelled),
      _tx(_url, 25, status: TxStatus.awaitingRecipient),
      _tx(_url, 20, kind: TxKind.received),
      _tx(_epicbox, 10),
    ];
    expect(lastPaidAddress(_contact, txs), _epicbox);
  });

  test('a wallet URL with its endpoint is the same address', () {
    expect(lastPaidAddress(_contact, [_tx('$_url/v2/foreign', 1)]), _url);
  });

  test('null when nothing was paid to the contact, so Send takes the first', () {
    expect(lastPaidAddress(_contact, [_tx('someone-else@epicbox.example.org', 1), _tx(null, 2)]), isNull);
    expect(lastPaidAddress(_contact, const []), isNull);
  });
}
