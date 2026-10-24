// The one naming rule for a payment method on the desktop: Epicbox, Direct · HTTP, Direct · Tor
// or File, in each language, in Activity, the details, the kind tag of an address and the receiving
// rail. HTTP and Tor are Direct's transport and never a method on their own.
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/data/method_names.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show AppLocalizations, lookupAppLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _names = <String, List<String>>{
  'en': ['Epicbox', 'Direct · HTTP', 'Direct · Tor', 'File'],
  'de': ['Epicbox', 'Direkt · HTTP', 'Direkt · Tor', 'Datei'],
  'pl': ['Epicbox', 'Bezpośrednio · HTTP', 'Bezpośrednio · Tor', 'Plik'],
  'ru': ['Epicbox', 'Напрямую · HTTP', 'Напрямую · Tor', 'Файл'],
  'zh': ['Epicbox', '直连 · HTTP', '直连 · Tor', '文件'],
  'th': ['Epicbox', 'ส่งตรง · HTTP', 'ส่งตรง · Tor', 'ไฟล์'],
};

Future<void> _pump(WidgetTester tester, Widget child, {Locale locale = const Locale('en')}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
      deskHistoryFilesProvider.overrideWithValue(MockDeskHistoryFiles()),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the desktop names a method from one mapper', () {
    for (final MapEntry(key: lang, value: names) in _names.entries) {
      test('$lang: epicbox, http, tor and file', () {
        final l = lookupAppLocalizations(Locale(lang));
        expect([for (final m in TxMethod.values) methodLabel(l, m)], names);
        expect([
          for (final t in ['epicbox', 'http', 'tor', 'file']) methodLabelOfTransport(l, t),
        ], names);
        expect(methodLabelOfTransport(l, 'other'), 'other');
      });
    }
  });

  group('Activity and the details', () {
    testWidgets('a Direct send over HTTP reads Direct · HTTP, never HTTP alone', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 35));
      expect(find.text('Direct · HTTP'), findsWidgets);
      expect(find.text('HTTP'), findsNothing);
      expect(find.text('Tor'), findsNothing);
    });

    testWidgets('a Direct receive over Tor reads Direct · Tor, never Tor alone', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 33));
      expect(find.text('Direct · Tor'), findsWidgets);
      expect(find.text('Tor'), findsNothing);
      expect(find.text('HTTP'), findsNothing);
    });

    testWidgets('the table names the method in the language', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 33), locale: const Locale('de'));
      expect(find.text('Direkt · Tor'), findsWidgets);
      expect(find.text('Direct · Tor'), findsNothing);
    });
  });

  testWidgets('the kind tag of an address row names the method its address is reached by', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Column(children: [EKindTag(AddressKind.epicbox), EKindTag(AddressKind.http), EKindTag(AddressKind.tor)]),
      ),
    );
    expect(find.text('Epicbox'), findsOneWidget);
    expect(find.text('Direct · HTTP'), findsOneWidget);
    expect(find.text('Direct · Tor'), findsOneWidget);
    expect(find.text('HTTP'), findsNothing);
    expect(find.text('Tor'), findsNothing);
  });
}
