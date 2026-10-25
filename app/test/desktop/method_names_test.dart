// The one naming rule for a payment method on the desktop: Epicbox, Link · HTTP, Link · Tor
// or Direct · File Transfer, in each language, in Activity, the details, the kind tag of an address and the receiving
// rail. HTTP and Tor are Link's transport and never a method on their own.
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
  'en': ['Epicbox', 'Link · HTTP', 'Link · Tor', 'Direct · File Transfer'],
  'de': ['Epicbox', 'Link · HTTP', 'Link · Tor', 'Direkt · Dateiübertragung'],
  'pl': ['Epicbox', 'Link · HTTP', 'Link · Tor', 'Bezpośrednio · Przesyłanie pliku'],
  'ru': ['Epicbox', 'Ссылка · HTTP', 'Ссылка · Tor', 'Напрямую · Передача файла'],
  'zh': ['Epicbox', '链接 · HTTP', '链接 · Tor', '直接 · 文件传输'],
  'th': ['Epicbox', 'ลิงก์ · HTTP', 'ลิงก์ · Tor', 'โดยตรง · โอนไฟล์'],
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
    testWidgets('a Link send over HTTP reads Link · HTTP, never HTTP alone', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 35));
      expect(find.text('Link · HTTP'), findsWidgets);
      expect(find.text('HTTP'), findsNothing);
      expect(find.text('Tor'), findsNothing);
    });

    testWidgets('a Link receive over Tor reads Link · Tor, never Tor alone', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 33));
      expect(find.text('Link · Tor'), findsWidgets);
      expect(find.text('Tor'), findsNothing);
      expect(find.text('HTTP'), findsNothing);
    });

    testWidgets('the table names the method in the language', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 33), locale: const Locale('de'));
      expect(find.text('Link · Tor'), findsWidgets);
      expect(find.text('Tor'), findsNothing);
    });
  });

  testWidgets('the kind tag of an address names the method by its short name, with its icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Column(children: [EKindTag(AddressKind.epicbox), EKindTag(AddressKind.http), EKindTag(AddressKind.tor)]),
      ),
    );
    expect(find.text('Epicbox'), findsOneWidget);
    expect(find.text('Link · HTTP'), findsOneWidget);
    expect(find.text('Link · Tor'), findsOneWidget);
    expect(find.text('HTTP'), findsNothing, reason: 'a sub-option never stands alone');
    expect(find.byIcon(EIcons.epicbox), findsOneWidget);
    expect(find.byIcon(EIcons.http), findsOneWidget);
    expect(find.byIcon(EIcons.tor), findsOneWidget);
    expect(find.textContaining('Link Payment'), findsNothing);
  });

  testWidgets('a compact kind tag is the icon alone, the full name in its tooltip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Column(children: [EKindTag(AddressKind.tor, compact: true)]),
      ),
    );
    expect(find.byType(Text), findsNothing);
    expect(find.byIcon(EIcons.tor), findsOneWidget);
    expect(find.byTooltip('Link · Tor'), findsOneWidget);
    expect(find.bySemanticsLabel('Link · Tor'), findsOneWidget);
  });
}
