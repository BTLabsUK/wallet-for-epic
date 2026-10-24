// android-07: a scan that finished (the restore's, or Settings' rescan) reloads the balances,
// so Home and Outputs show what it found instead of the zero read before it.
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

WalletSummary _spendable(int atomic) => WalletSummary(
  lastConfirmedHeight: BigInt.from(3767035),
  minimumConfirmations: BigInt.from(10),
  total: BigInt.from(atomic),
  spendable: BigInt.from(atomic),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

void main() {
  test('a finished scan reloads home with the balance it found', () async {
    final session = FakeWalletSession(summary: _spendable(0));
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [sessionProvider.overrideWith(() => _Open(session))],
    );
    addTearDown(c.dispose);
    c.listen(homeProvider, (_, _) {});
    await c.read(homeProvider.future);
    // Let the first load's background refresh end, as on Home before the scan finished.
    await pumpEventQueue();
    expect(c.read(homeProvider).value?.summary.spendable, BigInt.zero);

    // The scan finds 1.842 EPIC.
    session.summaryValue = _spendable(184200000);
    expect(await c.read(scanProvider.notifier).run(startHeight: BigInt.zero), isTrue);
    await pumpEventQueue();
    await c.read(homeProvider.future);
    expect(c.read(homeProvider).value?.summary.spendable, BigInt.from(184200000));
  });
}
