// Delete wallet when the core refuses (tester report 26.10.16): the failed delete locks the
// wallet, so the dialog must not leave Settings open over a locked wallet (an endless spinner,
// no node or Epicbox, no wallet name). Unlock opens with the error instead.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _BusyCore extends MockDeskWallet {
  _BusyCore() : super(delay: Duration.zero);

  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) async {
    // As LepicDeskWallet: the open wallet locks even when the removal fails.
    await lock();
    throw const DeskError('Wallet busy. Try again in a moment.');
  }
}

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('a delete the core refuses ends on Unlock with the error, never on a locked Settings', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_BusyCore())], retry: (_, _) => null);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAccount);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
    await _settle(tester);

    showDeleteWalletDialog(tester.element(find.byType(EPage)));
    await _settle(tester);
    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(EditableText)), 'password');
    await tester.tap(find.byType(ECheckbox));
    await _settle(tester);
    await tester.tap(find.widgetWithText(EButton, 'Delete wallet'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);

    expect(container.read(deskProvider).account, isNull, reason: 'the refused delete locked the wallet');
    expect(find.text('Delete this wallet?'), findsNothing, reason: 'the dialog closed');
    expect(container.read(deskNavProvider).route, DeskRoute.unlock, reason: 'Unlock, not Settings over a locked wallet');
    expect(find.text('Wallet busy. Try again in a moment.'), findsOneWidget, reason: 'the error is shown');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
