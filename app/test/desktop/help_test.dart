// F20: Help as the settings design draws it: the support bar first, six sections with their
// art, lede and count, the topic set with bodies, search over the bodies, and the copy rules.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_topics.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/help_art.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pump(WidgetTester tester, {Object? arg}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: SettingsHelpScreen(key: ValueKey(arg), arg: arg))),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final topics = helpTopicsFor(3);

  test('the topic set: six sections, every topic in one, bodies with text', () {
    expect(helpSections.map((s) => s.title), [
      'Getting started',
      'How Epic Cash works',
      'Keeping the wallet safe',
      'Nodes and Epicbox',
      'When something goes wrong',
      'Maintenance',
    ]);
    expect(topics, hasLength(DeskFeatures.tor ? 20 : 19));
    for (final t in topics) {
      expect(helpSections.map((s) => s.id), contains(t.section));
      expect(t.body, isNotEmpty, reason: t.title);
      expect(t.bodyText, isNot(contains('**')), reason: t.title);
      expect(t.bodyText, isNot(contains('[[')), reason: t.title);
    }
    expect(topics.where((t) => t.handshake).single.title, 'Why does a transaction need both sides?');
  });

  test('the copy rules', () {
    for (final t in topics) {
      final all = '${t.title} ${t.short} ${t.bodyText}';
      expect(all, isNot(contains('Epic address')), reason: t.title);
      expect(all, isNot(contains('Rescan')), reason: t.title);
      // "Built-in node" is the Advanced switch's name; only the old wording is out.
      expect(all.replaceAll(RegExp(r"[Bb]uilt-in node"), ''), isNot(contains('built-in')), reason: t.title);
      expect(all, isNot(contains('listener')), reason: t.title);
      expect(all.toLowerCase(), isNot(contains(' we ')), reason: t.title);
      final low = all.toLowerCase();
      for (final m in RegExp('tor').allMatches(low)) {
        final near = low.substring((m.start - 80).clamp(0, low.length), (m.end + 80).clamp(0, low.length));
        if (RegExp(r'\btor\b').hasMatch(near)) expect(near, isNot(contains('minute')), reason: t.title);
      }
    }
    // The confirmations count follows the wallet's.
    expect(helpTopicsFor(3).firstWhere((t) => t.title == 'Confirmations').short, contains('3 confirmations'));
  });

  test('inline marks: terms and places lose their markers', () {
    final parts = helpInline('Open [[Settings › Node]] and press **Save**.');
    expect(parts.map((p) => p.text).join(), 'Open Settings › Node and press Save.');
    expect(parts.where((p) => p.place).single.text, 'Settings › Node');
    expect(parts.where((p) => p.term).single.text, 'Save');
  });

  testWidgets('the support bar first, then search, chips and the six sections with their art', (tester) async {
    await _pump(tester);
    final report = tester.getTopLeft(find.text('Report a problem').first);
    expect(report.dy, lessThan(tester.getTopLeft(find.text('Search help')).dy));
    expect(find.widgetWithText(EButton, 'Report a problem'), findsOneWidget);
    expect(find.text('Help and FAQ'), findsNothing);
    for (final s in helpSections) {
      expect(find.text(s.lede), findsOneWidget);
      expect(find.text(s.title), findsNWidgets(2), reason: 'chip and head');
    }
    expect(find.text('5 topics'), findsWidgets, reason: 'Pairing');
    expect(find.text('1 topic'), findsNWidgets(2), reason: 'Troubleshooting and Maintenance');
    expect(find.byType(HelpArt), findsNWidgets(7));
  });

  testWidgets('Read more opens the body with the stepper; Show less folds it', (tester) async {
    await _pump(tester);
    final title = find.text('Why does a transaction need both sides?');
    await tester.ensureVisible(title);
    final more = find.descendant(of: find.ancestor(of: title, matching: find.byType(Row)).first, matching: find.text('Read more'));
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
    expect(find.byType(HelpHandshake), findsOneWidget);
    expect(find.textContaining('Epic Cash uses Mimblewimble', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.byType(HelpHandshake), findsNothing);
  });

  testWidgets('a search that matches a body opens the topic; no match says so', (tester) async {
    await _pump(tester, arg: 'mimblewimble');
    expect(find.text('Topics found: 1'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('Getting started'), findsNothing, reason: 'no chips or section heads while searching');
    await _pump(tester, arg: 'zebra');
    expect(find.text('No topic matches “zebra”. Try another word.'), findsOneWidget);
  });

  testWidgets('a section chip scrolls to its section', (tester) async {
    await _pump(tester);
    final head = find.text('Troubleshooting');
    expect(tester.getTopLeft(head).dy, greaterThan(1000));
    await tester.tap(find.text('When something goes wrong').first);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(head).dy, lessThan(1000));
  });

  testWidgets('a place in a topic is a link to its page', (tester) async {
    final container = await _pump(tester, arg: 'words again');
    final link = find.text('Settings › Recovery phrase', findRichText: true);
    expect(link, findsOneWidget);
    // "Check the words again" in the Pairing topics matches too, above it.
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(container.read(deskNavProvider).route, DeskRoute.settingsPhrase);
  });

  testWidgets('the demo states open their topic', (tester) async {
    await _pump(tester, arg: HelpDemo.open);
    expect(find.byType(HelpHandshake), findsOneWidget);
    await _pump(tester, arg: HelpDemo.bottom);
    expect(find.textContaining('blocked or not allowed in some countries', findRichText: true), findsWidgets);
  });
}
