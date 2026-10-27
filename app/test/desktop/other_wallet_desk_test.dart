// The chain check on the desktop: Activity names coins another wallet on this recovery phrase
// spent or received, and the details say what it is, with no recipient and no known fee.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/other_wallet_offer.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester, {Object? arg}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero, otherWalletRows: true))],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    final n = container.read(deskProvider.notifier);
    await n.refresh();
    await n.saveSettings(container.read(deskProvider).settings.copyWith(tourSeen: true));
  });
  container.read(deskNavProvider.notifier).reset(DeskRoute.activity, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('Activity lists both rows by name', (tester) async {
    await _open(tester);
    expect(find.text('Sent from another wallet'), findsWidgets);
    expect(find.text('Received by another wallet'), findsWidgets);
  });

  testWidgets('the details of a send: what it is, the fee not known, no method, the offer spot', (tester) async {
    await _open(tester, arg: 107);
    expect(find.text('Another wallet using your recovery phrase spent these coins. This wallet shows the amount that left, not who received it or the fee.'), findsOneWidget);
    expect(find.text('Not known'), findsOneWidget);
    expect(find.text('Method'), findsNothing);
    expect(find.byType(DeskSentFromOtherWalletOffer), findsOneWidget);
  });

  testWidgets('the details of a receive: what it is, no fee', (tester) async {
    await _open(tester, arg: 108);
    expect(find.text('Another wallet using your recovery phrase received these coins. This wallet shows the amount, not who sent it.'), findsOneWidget);
    expect(find.text('Not known'), findsNothing);
    expect(find.byType(DeskSentFromOtherWalletOffer), findsOneWidget);
  });
}
