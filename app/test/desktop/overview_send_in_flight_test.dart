// A send in flight on Overview: 0.1 in one output, 0.01 sent with a 0.008 fee, not in a block
// yet. The core locks the 0.1 and counts the 0.082 change as awaiting finalization, outside
// Total: the change is the wallet's own, never money awaiting someone (tester, 26.10.17).
// Send and Receive look alike.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/overview_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _change = 8200000;

Tx _send({int? height, TxState state = TxState.posted}) => Tx(
  id: 1,
  slateId: 'a1',
  direction: TxDirection.sent,
  state: state,
  method: TxMethod.epicbox,
  amount: 1000000,
  fee: 800000,
  created: DateTime(2026, 10, 27),
  height: height,
  credited: _change,
);

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  @override
  Future<Balance> balance() async => const Balance(spendable: 0, awaitingConfirmation: 0, locked: 10000000, awaitingFinalization: _change);

  @override
  Future<List<Tx>> transactions() async => [_send()];
}

void main() {
  test('the change of a send not in a block is the wallet\'s own; a payment received is not', () {
    expect(ownChangeOffChain([_send()]), _change);
    expect(ownChangeOffChain([_send(height: 10, state: TxState.confirming)]), 0);
    expect(ownChangeOffChain([_send(state: TxState.cancelled)]), 0);
    final received = Tx(id: 2, slateId: 'b', direction: TxDirection.received, state: TxState.waitingRecipient, method: TxMethod.epicbox, amount: 5, fee: 0, created: DateTime(2026), credited: 5);
    expect(ownChangeOffChain([received]), 0);
    const b = Balance(spendable: 0, awaitingConfirmation: 0, locked: 10000000, awaitingFinalization: _change);
    expect(b.total, b.spendable + b.awaitingConfirmation + b.locked, reason: 'no double count, nothing missing');
  });

  testWidgets('Overview: Waiting for sender leaves the change out, Locked and Total keep the 0.1; Send is plain', (tester) async {
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet())]);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: OverviewScreen())),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    int cell(String label) {
      final column = find.ancestor(of: find.text(label), matching: find.byType(Column)).first;
      return tester.widget<FitMoney>(find.descendant(of: column, matching: find.byType(FitMoney))).nano;
    }

    expect(cell('Waiting for sender'), 0);
    expect(cell('Locked in sends'), 10000000);
    expect(cell('Total'), 10000000);
    final send = tester.widget<EButton>(find.widgetWithText(EButton, 'Send'));
    final receive = tester.widget<EButton>(find.widgetWithText(EButton, 'Receive'));
    expect(send.kind, receive.kind);
    expect(send.size, receive.size);
  });
}
