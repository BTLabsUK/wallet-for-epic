// SPDX-License-Identifier: Apache-2.0
// A Tor send to a published onion failed once with onionUnreachable in the 2026-10-29 soak
// (1 of 11). The send now tries the stored payment once more after a wait, then fails as before.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _unreached = WalletError(kind: WalletErrorKind.onionUnreachable, message: 'not reached');

TxEntry _waiting(int id) => fakeTx(key: 'l:$id', id: id, kind: TxKind.sent, status: TxStatus.awaitingRecipient);

void main() {
  test('an onion not reached: the stored send goes once more, after the wait', () async {
    final txs = [_waiting(1)];
    final resent = <int>[];
    final sent = await sendTorRetryingOnce(
      transactions: () async => List.of(txs),
      send: () async {
        txs.add(_waiting(2));
        throw _unreached;
      },
      resend: (id) async {
        resent.add(id);
        return HttpSent(txId: id, slateId: 's', posted: true);
      },
      wait: Duration.zero,
    );
    expect(resent, [2], reason: 'the new one, not the older waiting send');
    expect(sent.posted, isTrue);
  });

  test('the second try failing too is the answer; nothing else is tried', () async {
    final txs = <TxEntry>[];
    var resends = 0;
    await expectLater(
      sendTorRetryingOnce(
        transactions: () async => List.of(txs),
        send: () async {
          txs.add(_waiting(3));
          throw _unreached;
        },
        resend: (id) async {
          resends++;
          throw _unreached;
        },
        wait: Duration.zero,
      ),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.onionUnreachable)),
    );
    expect(resends, 1);
  });

  test('other failures, or no stored send, are not tried again', () async {
    var resends = 0;
    Future<HttpSent> resend(int id) async {
      resends++;
      return HttpSent(txId: id, slateId: 's', posted: true);
    }

    await expectLater(
      sendTorRetryingOnce(
        transactions: () async => const [],
        send: () async => throw const WalletError(kind: WalletErrorKind.transportFailed, message: 'refused'),
        resend: resend,
        wait: Duration.zero,
      ),
      throwsA(isA<WalletError>()),
    );
    await expectLater(
      sendTorRetryingOnce(transactions: () async => const [], send: () async => throw _unreached, resend: resend, wait: Duration.zero),
      throwsA(isA<WalletError>()),
    );
    expect(resends, 0);
  });
}
