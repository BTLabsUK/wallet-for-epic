// linux-08: Outputs read "Confirming 0.0000 · 1 output". The tile counted an output awaiting
// finalization (a payment received, not yet posted by its sender) but showed only the value
// confirming on chain. Its value is the confirming and the finalizing value, as the phone's.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/outputs_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  @override
  Future<Balance> balance() async => const Balance(spendable: 131900000, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 10000000);

  @override
  Future<List<Output>> outputs() async => const [
    Output(commitment: '08aa', value: 131900000, status: OutputStatus.unspent, height: 3767074, confirmations: 10),
    Output(commitment: '08bb', value: 10000000, status: OutputStatus.unconfirmed, awaitingFinalization: true),
  ];
}

void main() {
  testWidgets('Confirming shows the value of the outputs it counts', (tester) async {
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet())]);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: OutputsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    // The tile: the column holding the label, its value and its count.
    final tile = find.ancestor(of: find.text('Confirming').first, matching: find.byType(Column)).first;
    expect(find.descendant(of: tile, matching: find.text('1 output')), findsOneWidget);
    final value = tester.widget<EMoney>(find.descendant(of: tile, matching: find.byType(EMoney)));
    expect(value.nano, 10000000);
  });
}
