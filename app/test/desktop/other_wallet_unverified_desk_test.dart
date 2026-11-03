// SPDX-License-Identifier: Apache-2.0
// A send by another wallet on this recovery phrase that only the node's answers show so far
// (LEPIC's unverified): the desktop row says so, until the next completed scan clears it.
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

void main() {
  Tx row({required TxDirection direction, bool unverified = false}) => Tx(
    id: 7,
    slateId: '',
    direction: direction,
    state: TxState.confirmed,
    method: TxMethod.epicbox,
    amount: 100000000,
    fee: 0,
    created: DateTime(2026, 10, 28),
    otherWallet: true,
    unverified: unverified,
  );

  test('the row names an unverified send, and only a send', () {
    final l = englishStrings;
    expect(whoOf(l, row(direction: TxDirection.sent, unverified: true)), _l.txSentFromOtherWalletUnverified);
    expect(whoOf(l, row(direction: TxDirection.sent)), _l.txSentFromOtherWallet);
    expect(whoOf(l, row(direction: TxDirection.received)), _l.txReceivedByOtherWallet);
  });
}
