// The warning before the first import: Welcome's Import wallets card shows it, Continue
// waits for the acknowledgement, Cancel goes nowhere, and once acknowledged it is saved with
// the app's settings and never shows again.
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/import_warning.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/welcome_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(WidgetTester tester, DeskStore store) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
      deskStoreProvider.overrideWithValue(store),
      deskBootProvider.overrideWithValue(await DeskBoot.load(store)),
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: WelcomeScreen())),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return container;
}

final _title = find.text('Before you import');
final _continue = find.widgetWithText(EButton, 'Continue');

void main() {
  testWidgets('first import: the warning, Continue only after the acknowledgement, then the wizard', (tester) async {
    final store = DeskStore(MemorySecretStore());
    final c = await _pump(tester, store);
    final start = c.read(deskNavProvider).route;
    await tester.tap(find.text('Import wallets'));
    await tester.pumpAndSettle();
    expect(_title, findsOneWidget);
    expect(find.text('This is an early version of a new app. Import only reads your old wallets and files and never deletes or changes them.'), findsOneWidget);
    expect(find.text('You import at your own risk, and we take no responsibility for any loss.'), findsOneWidget);
    expect(tester.widget<EButton>(_continue).onPressed, isNull);
    expect(c.read(deskNavProvider).route, start, reason: 'nothing opens before Continue');

    await tester.tap(find.text('I have a backup of every wallet'));
    await tester.pumpAndSettle();
    expect(tester.widget<EButton>(_continue).onPressed, isNotNull);
    await tester.tap(_continue);
    await tester.pumpAndSettle();
    expect(_title, findsNothing);
    expect(c.read(deskNavProvider).route, DeskRoute.importWallets);
    expect(c.read(deskProvider).settings.importWarningSeen, isTrue);
    expect((await store.settings()).importWarningSeen, isTrue, reason: 'saved with the settings');
  });

  testWidgets('Cancel: nothing opens, nothing is saved; the next time asks again', (tester) async {
    final store = DeskStore(MemorySecretStore());
    final c = await _pump(tester, store);
    final start = c.read(deskNavProvider).route;
    await tester.tap(find.text('Import wallets'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(EButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(_title, findsNothing);
    expect(c.read(deskNavProvider).route, start);
    expect((await store.settings()).importWarningSeen, isFalse);

    await tester.tap(find.text('Import wallets'));
    await tester.pumpAndSettle();
    expect(_title, findsOneWidget);
  });

  testWidgets('acknowledged at an earlier start: straight to the wizard', (tester) async {
    final store = DeskStore(MemorySecretStore());
    await store.saveImportWarningSeen();
    final c = await _pump(tester, store);
    await tester.tap(find.text('Import wallets'));
    await tester.pumpAndSettle();
    expect(_title, findsNothing);
    expect(c.read(deskNavProvider).route, DeskRoute.importWallets);
  });

  test('a later save of other settings keeps the flag; the dialog alone pops true only via Continue', () async {
    final store = DeskStore(MemorySecretStore());
    await store.saveImportWarningSeen();
    await store.saveSettings(const DeskSettings());
    expect((await store.settings()).importWarningSeen, isTrue);
    expect(showImportWarningDialog, isNotNull);
  });
}
