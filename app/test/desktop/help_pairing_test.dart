// Help › Invoices: the section with its three topics, the flow diagram, the deep link and the
// rail width.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_invoices.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {Object? arg, double width = 1280}) async {
  tester.view.physicalSize = Size(width, 1000);
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
}

void main() {
  testWidgets('the invoices section shows its three topics, before trouble', (tester) async {
    await _pump(tester);
    expect(find.text('Invoices'), findsWidgets);
    expect(find.byType(InvoiceHelpMark), findsOneWidget);
    for (final t in ['How an invoice works', 'Why only trusted senders', 'Why a separate invoice address']) {
      expect(find.text(t, findRichText: true), findsOneWidget);
    }
    final inv = tester.getTopLeft(find.text('Why a separate invoice address', findRichText: true)).dy;
    final trouble = tester.getTopLeft(find.text('When something goes wrong').last).dy;
    expect(inv, lessThan(trouble));
    expect(find.byType(InvoiceFlowDiagram), findsNothing);
  });

  testWidgets('HelpAt opens the flow topic with its diagram', (tester) async {
    await _pump(tester, arg: const HelpAt('invoices'));
    expect(find.byType(InvoiceFlowDiagram), findsOneWidget);
    expect(find.text('Trusted senders only'), findsWidgets);
    expect(find.byWidgetPredicate((w) => w is Semantics && (w.properties.label ?? '').startsWith('The issuer sends an invoice')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening the first topic by hand shows the diagram', (tester) async {
    await _pump(tester);
    final more = find.descendant(of: find.byKey(const ValueKey('How an invoice works')), matching: find.text('Read more'));
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byType(InvoiceFlowDiagram), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('900 px wide: the flow lays out without an exception', (tester) async {
    await _pump(tester, arg: const HelpAt('invoices'), width: 900);
    expect(find.byType(InvoiceFlowDiagram), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow: the diagram goes to one column', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: buildDeskTheme(Brightness.light), home: const Scaffold(body: SingleChildScrollView(child: InvoiceFlowDiagram(confirmations: 3)))),
    );
    expect(find.text('Final after 3 confirmations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('search finds the invoice topics', () {
    final hits = searchTopics(invoiceHelpTopics(englishStrings, 3), queryWords('invoice address'));
    expect(hits.first.topic.title, 'Why a separate invoice address');
  });
}
