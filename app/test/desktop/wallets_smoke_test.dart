// Several wallets on the desktop (D9): Unlock's Wallet select and the Remove wallet dialog's two
// modes, on the mock with its calls recorded.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart' show demoOtherWallet;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder extends MockDeskWallet {
  _Recorder() : super(delay: const Duration(milliseconds: 10));

  final List<String> calls = [];

  @override
  Future<void> selectWallet(String id) {
    calls.add('select $id');
    return super.selectWallet(id);
  }

  @override
  Future<bool> unlock(String password) {
    calls.add('unlock');
    return super.unlock(password);
  }

  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) {
    calls.add('remove $id ${mode.name}');
    return super.removeWallet(id, mode, password: password);
  }
}

Future<void> _pump(WidgetTester tester, _Recorder api, Widget child) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
  ));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _wait(WidgetTester tester, [int ms = 2000]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('unlock opens the wallet picked in the Wallet select', (tester) async {
    final api = _Recorder();
    await _pump(tester, api, const UnlockScreen());
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Main wallet'), findsOneWidget);
    await tester.tap(find.text('Main wallet'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Savings').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.calls, ['select ${demoOtherWallet.id}']);
    await tester.enterText(find.byType(EditableText).first, 'wrong');
    await tester.tap(find.text('Unlock'));
    await _wait(tester);
    expect(api.calls, ['select ${demoOtherWallet.id}', 'select ${demoOtherWallet.id}', 'unlock']);
    await _end(tester);
  });

  testWidgets('remove dialog: two modes; delete needs the typed name and the tick', (tester) async {
    final api = _Recorder();
    await _pump(tester, api, Builder(builder: (c) => TextButton(onPressed: () => showRemoveWalletDialog(c, demoOtherWallet), child: const Text('open'))));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Remove from list'), findsWidgets);
    expect(find.text('Delete wallet'), findsOneWidget);
    expect(find.textContaining('this app’s files'), findsNothing);

    await tester.tap(find.text('Delete wallet'));
    await tester.pump(const Duration(milliseconds: 300));
    final button = find.widgetWithText(EButton, 'Delete wallet');
    expect(tester.widget<EButton>(button).onPressed, isNull);
    await tester.enterText(find.byType(EditableText).last, 'Savings');
    await tester.pump();
    expect(tester.widget<EButton>(button).onPressed, isNull, reason: 'the tick is still missing');
    await tester.tap(find.text('The recovery phrase is written down'));
    await tester.pump();
    expect(tester.widget<EButton>(button).onPressed, isNotNull);

    await tester.tap(find.text('Remove from list').first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(EButton, 'Remove from list'));
    await _wait(tester);
    expect(api.calls, ['remove ${demoOtherWallet.id} list']);
    expect(find.text('Savings removed from the list'), findsOneWidget);
    await _end(tester);
  });
}
