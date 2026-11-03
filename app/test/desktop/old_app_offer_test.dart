// SPDX-License-Identifier: Apache-2.0
// macOS: the app from before the rename, still in Applications, is offered to the Bin once.
// Nothing found shows nothing; Move to Bin asks the runner to trash it and says how it went;
// Keep is remembered; other systems never ask the runner.
import 'package:epic_wallet/src/desktop/app/old_app_offer.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart' show MemorySecretStore;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _old = '/Applications/Epic Cash Desktop.app';
final _mac = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  late List<MethodCall> calls;
  late String? found;
  late String trashAnswer;
  late MemorySecretStore store;

  setUp(() {
    resetDeskOldAppOffer();
    calls = [];
    found = _old;
    trashAnswer = 'ok';
    store = MemorySecretStore();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(oldAppChannel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'find' => found,
        'trash' => trashAnswer,
        _ => null,
      };
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(oldAppChannel, null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secretStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(onPressed: () => offerDeskOldAppRemoval(context, ref), child: const Text('start')),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
  }

  testWidgets('no old app: nothing shown', (tester) async {
    found = null;
    await pump(tester);
    await start(tester);
    expect(calls.map((c) => c.method), ['find']);
    expect(find.text('Old app found'), findsNothing);
  }, variant: _mac);

  testWidgets('old app: the dialog names it; Move to Bin trashes it and says so', (tester) async {
    await pump(tester);
    await start(tester);
    expect(find.text(_l.deskOldAppTitle), findsOneWidget);
    expect(find.text('Epic Cash Desktop is still in /Applications.'), findsOneWidget);
    expect(find.bySemanticsLabel(_l.deskOldAppTrash), findsOneWidget);
    expect(find.bySemanticsLabel(_l.deskOldAppKeep), findsOneWidget);
    await tester.tap(find.text('Move to Bin'));
    await tester.pumpAndSettle();
    expect(calls.map((c) => '${c.method}:${c.arguments}'), ['find:null', 'trash:$_old']);
    expect(find.text('Old app found'), findsNothing);
    expect(find.text('Epic Cash Desktop moved to Bin'), findsOneWidget);
    expect(store.values, isEmpty, reason: 'only Keep is remembered');
  }, variant: _mac);

  testWidgets('a failed move says the app was not moved', (tester) async {
    trashAnswer = 'failed';
    await pump(tester);
    await start(tester);
    await tester.tap(find.text(_l.deskOldAppTrash));
    await tester.pumpAndSettle();
    expect(find.text('Epic Cash Desktop could not be moved to Bin'), findsOneWidget);
    expect(find.text('Epic Cash Desktop moved to Bin'), findsNothing);
  }, variant: _mac);

  testWidgets('Keep is remembered and the dialog does not come back', (tester) async {
    await pump(tester);
    await start(tester);
    await tester.tap(find.text(_l.deskOldAppKeep));
    await tester.pumpAndSettle();
    expect(calls.map((c) => c.method), ['find'], reason: 'Keep never trashes');
    expect(store.values[deskOldAppKeptKey], 'kept');
    // The next run.
    resetDeskOldAppOffer();
    calls.clear();
    await start(tester);
    expect(calls, isEmpty);
    expect(find.text('Old app found'), findsNothing);
  }, variant: _mac);

  testWidgets('the keyboard reaches both buttons', (tester) async {
    await pump(tester);
    await start(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final first = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final second = FocusManager.instance.primaryFocus;
    expect(first, isNotNull);
    expect(second, isNot(same(first)));
    // Esc closes it with no answer: nothing stored, nothing trashed.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Old app found'), findsNothing);
    expect(calls.map((c) => c.method), ['find']);
    expect(store.values, isEmpty);
  }, variant: _mac);

  testWidgets('other systems never ask', (tester) async {
    await pump(tester);
    await start(tester);
    expect(calls, isEmpty);
    expect(find.text('Old app found'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
