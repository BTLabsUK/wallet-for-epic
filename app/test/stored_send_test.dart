// SPDX-License-Identifier: Apache-2.0
// What a failed HTTP send left behind is found again: LEPIC records the listener URL in full
// (scheme, port, `/v2/foreign`), also when the address was typed without a port.
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/wallet/stored_send.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Rows extends Fake implements WalletSession {
  final rows = <TxEntry>[];
  @override
  Future<List<TxEntry>> transactions({required bool refresh}) async => List.of(rows);
}

Future<StoredSend> _failedSend(String recorded, String typed, {BigInt? amount}) async {
  final session = _Rows();
  final before = await SendBefore.take(session);
  session.rows.add(fakeTx(
    id: 7,
    slateId: 'slate-7',
    kind: TxKind.sent,
    status: TxStatus.awaitingRecipient,
    amountDebited: BigInt.from(1100000000),
    fee: BigInt.from(100000000),
    numInputs: 1,
    numOutputs: 0,
    counterparty: recorded,
    cancellable: true,
  ));
  return before.leftBehind(to: typed, amount: amount ?? BigInt.from(1000000000), match: SentToMatch.host);
}

void main() {
  group('a failed HTTP send is found among the wallet rows', () {
    test('typed with its port, recorded with the endpoint', () async {
      final s = await _failedSend('https://onetime.us:443/7s626632/v2/foreign', 'https://onetime.us:443/7s626632');
      expect(s.payment?.id, 7);
    });

    test('recorded without the scheme\'s own port', () async {
      final s = await _failedSend('https://onetime.us/7s626632/v2/foreign', 'https://onetime.us:443/7s626632');
      expect(s.payment?.id, 7);
    });

    test('a listener on its own port, no path', () async {
      final s = await _failedSend('http://192.168.1.24:3415/v2/foreign', 'http://192.168.1.24:3415');
      expect(s.payment?.id, 7);
    });

    test('another path, port or amount is not the same payment', () async {
      expect((await _failedSend('https://onetime.us:443/other/v2/foreign', 'https://onetime.us:443/7s626632')).payment, isNull);
      expect((await _failedSend('https://onetime.us:8443/7s626632/v2/foreign', 'https://onetime.us:443/7s626632')).payment, isNull);
      expect((await _failedSend('https://onetime.us:443/7s626632/v2/foreign', 'https://onetime.us:443/7s626632', amount: BigInt.from(5))).payment, isNull);
    });
  });
}
