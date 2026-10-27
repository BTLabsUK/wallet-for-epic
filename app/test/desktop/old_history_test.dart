// The old wallet's history brings another sender or method than details the user typed: the shell
// asks with the same "Details differ" dialog as a history backup, every field starts as Mine,
// Theirs (Old wallet) applies, Cancel postpones, and nothing asks when nothing differs.
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

late MockDeskWallet _api;
late ProviderContainer _container;

/// Time passing while a spinner turns behind a dialog: pumpAndSettle would never return.
Future<void> _flow(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The answer goes out once the dialog's route has finished; the mock's calls use real timers.
Future<void> _answered(WidgetTester tester) async {
  await _flow(tester);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await _flow(tester);
}

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _api = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_api)]);
  addTearDown(_container.dispose);
  await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
  _container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAbout);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Consumer(builder: (_, ref, _) => DeskShell(at: ref.watch(deskNavProvider))),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// What the sync does when the old wallet's history differs: the controller learns of it.
Future<void> _oldWalletDiffers(WidgetTester tester) async {
  final key = _container.read(deskProvider).txs!.firstWhere((t) => t.id == 103).key;
  _api.oldHistory = [
    ImportConflict(
      key: key,
      field: ManualField.counterparty,
      mine: 'esMine@epicbox.epiccash.com',
      theirs: 'esOld@epicbox.epiccash.com',
      timeUnix: 1760100000,
      amount: BigInt.from(425000000),
    ),
    ImportConflict(
      key: key,
      field: ManualField.transport,
      mine: 'file',
      theirs: 'epicbox',
      timeUnix: 1760100000,
      amount: BigInt.from(425000000),
    ),
  ];
  await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
  await _flow(tester);
}

void main() {
  testWidgets('differing fields open Details differ with Mine selected and the old wallet as the other side', (tester) async {
    await _pumpShell(tester);
    await _oldWalletDiffers(tester);
    expect(find.text('Details differ'), findsOneWidget);
    expect(find.textContaining("The old wallet's history has other details for 1 payment you described"), findsOneWidget);
    final cards = tester.widgetList<EChoiceCard>(find.byType(EChoiceCard)).map((c) => '${c.title}:${c.selected}').toList();
    expect(cards, ['Mine:true', 'Old wallet:false', 'Mine:true', 'Old wallet:false']);
    expect(find.text('File'), findsNothing);
  });

  testWidgets('choosing the old wallet for one field applies it and keeps the other as mine', (tester) async {
    await _pumpShell(tester);
    await _oldWalletDiffers(tester);
    final key = _container.read(deskProvider).txs!.firstWhere((t) => t.id == 103).key;
    await tester.tap(find.text('Old wallet').first);
    await _flow(tester);
    await tester.tap(find.widgetWithText(EButton, 'Apply'));
    await _answered(tester);
    expect(_api.lastUseOldWallet, {'$key|counterparty': true, '$key|transport': false});
    expect(find.text('Details differ'), findsNothing);
    expect(_container.read(deskProvider).oldHistory, isEmpty);
  });

  testWidgets('Keep all mine answers every field with mine', (tester) async {
    await _pumpShell(tester);
    await _oldWalletDiffers(tester);
    final key = _container.read(deskProvider).txs!.firstWhere((t) => t.id == 103).key;
    await tester.tap(find.text('Old wallet').first);
    await tester.tap(find.widgetWithText(EButton, 'Keep all mine'));
    await _answered(tester);
    expect(_api.lastUseOldWallet, {'$key|counterparty': false, '$key|transport': false});
  });

  testWidgets('Cancel postpones: no choices go out and nothing is lost', (tester) async {
    await _pumpShell(tester);
    await _oldWalletDiffers(tester);
    await tester.tap(find.widgetWithText(EButton, 'Cancel').last);
    await _answered(tester);
    expect(find.text('Details differ'), findsNothing);
    expect(_api.lastUseOldWallet, isNull);
    expect(_api.oldHistoryConflicts, isEmpty);
  });

  testWidgets('nothing differs: no dialog', (tester) async {
    await _pumpShell(tester);
    await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
    await _flow(tester);
    expect(find.text('Details differ'), findsNothing);
    expect(_api.lastUseOldWallet, isNull);
  });
}
