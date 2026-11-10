// SPDX-License-Identifier: Apache-2.0
// Coins a linked device is spending count as locked on Home, not as spendable now (the core can
// still spend them; this wallet holds them back). They stay in the balance figure.
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/shell_header.dart' show walletFigure;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

WalletOutput _coin(String commitment, int atomic) => WalletOutput(
  commitment: commitment,
  value: BigInt.from(atomic),
  status: WalletOutputStatus.unspent,
  category: OutputCategory.spendable,
  isCoinbase: false,
  height: BigInt.from(500),
  lockHeight: BigInt.from(500),
  confirmations: BigInt.from(20),
);

void main() {
  test('held coins move from available to locked on Home', () async {
    final session = FakeWalletSession(
      summary: WalletSummary(
        lastConfirmedHeight: BigInt.from(520),
        minimumConfirmations: BigInt.from(10),
        total: BigInt.from(300000000),
        spendable: BigInt.from(300000000),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      ),
    );
    session.outputsValue = [_coin('aa', 100000000), _coin('bb', 200000000)];
    session.heldOutputs = {'aa'};
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [sessionProvider.overrideWith(() => _Open(session))],
    );
    addTearDown(c.dispose);
    c.listen(homeProvider, (_, _) {});
    final home = await c.read(homeProvider.future);
    expect(home.summary.spendable, BigInt.from(200000000));
    expect(home.summary.locked, BigInt.from(100000000));
    expect(home.summary.total, BigInt.from(300000000));
    // Holding never drops the balance figure: the held coin stays in it.
    expect(home.summary.held, BigInt.from(100000000));
    expect(walletFigure(home.summary, BigInt.zero), BigInt.from(300000000));
  });
}
