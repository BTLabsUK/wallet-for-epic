// The phone's warning before the first file import (the history backup): once per install.
import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/import_warning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<bool> answers;

  Future<ProviderContainer> pump(WidgetTester tester, SecretStore store) async {
    answers = [];
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [secretStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () async => answers.add(await confirmImportWarning(context, ref)),
                child: const Text('import'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.text('import')));
    await c.read(appSettingsProvider.future);
    return c;
  }

  testWidgets('shows once: Cancel refuses, Continue needs the tick, then it is remembered', (tester) async {
    final store = MemorySecretStore();
    await pump(tester, store);
    await tester.tap(find.text('import'));
    await tester.pumpAndSettle();
    expect(find.text('Before you import'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(answers, [false]);

    await tester.tap(find.text('import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I have a backup of every wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(answers, [false, true]);
    expect(await store.read(AppSettingsNotifier.importWarningSeenKey), 'true');

    await tester.tap(find.text('import'));
    await tester.pumpAndSettle();
    expect(find.text('Before you import'), findsNothing);
    expect(answers, [false, true, true]);
  });
}
