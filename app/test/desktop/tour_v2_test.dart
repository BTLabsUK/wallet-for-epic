// SPDX-License-Identifier: Apache-2.0
// The tour, one page per step: each step opens its page and lights its area and sidebar entry,
// Next / Back / Enter / the arrow keys move, Done, Esc, Skip and a click outside end it on
// Overview, its last step is Help, it opens from Help › Show the tour again and not from Appearance, it
// opens by itself once (the seen flag survives a restart), and the Invoices step is there
// exactly when the Invoices page is.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/api.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

final _l = englishStrings;

/// A wallet that does not take invoices (the LEPIC adapter before it is wired).
class _NoInvoices extends MockDeskWallet {
  _NoInvoices() : super(delay: Duration.zero);

  @override
  bool get supportsInvoices => false;
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  DeskRoute route, {
  Size size = const Size(1280, 800),
  DeskStore? store,
  DeskWalletApi? api,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(api ?? MockDeskWallet(delay: Duration.zero)),
      if (store != null) deskStoreProvider.overrideWithValue(store),
      if (store != null) deskBootProvider.overrideWithValue(await DeskBoot.load(store)),
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    await container.read(deskProvider.notifier).refresh();
  });
  container.read(deskNavProvider.notifier).reset(route);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// The lit areas the overlay's scrim cuts out (the page area, the sidebar entry, the Settings
/// list entry).
int _holes(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(find.descendant(of: find.byType(DeskTourOverlay), matching: find.byType(CustomPaint)).first);
  return ((paint.painter as dynamic).holes as List).length;
}

Finder _inCard(String text) => find.descendant(of: find.byType(DeskTourOverlay), matching: find.text(text));

void main() {
  tearDown(() => debugTourSteps = null);

  group('steps', () {
    test('without the Invoices page: eight, Overview to Help, Advanced before Help', () {
      final steps = tourStepsFor(invoices: false);
      expect(steps.map((s) => s.title), ['Overview', 'Send', 'Receive', 'Activity', 'Contacts', 'Settings\u00a0›\u00a0Node', 'Advanced', 'Help']);
      expect(steps.map((s) => s.route), [
        DeskRoute.overview,
        DeskRoute.send,
        DeskRoute.receive,
        DeskRoute.activity,
        DeskRoute.contacts,
        DeskRoute.settingsNode,
        DeskRoute.settingsAdvanced,
        DeskRoute.settingsHelp,
      ]);
      expect(steps.first.navId, 'nav-overview');
      expect(steps.last.navId, 'nav-settings');
      expect(steps.last.subId, 'subnav-settingsHelp');
      expect(steps[5].subId, 'subnav-settingsNode');
      expect(steps[6].subId, 'subnav-settingsAdvanced');
    });

    test('with the Invoices page: nine, Invoices after Receive, lighting its tabs and sidebar entry', () {
      final steps = tourStepsFor(invoices: true);
      expect(steps.length, 9);
      expect(steps[3].title, _l.deskTourInvoicesTitle);
      expect(steps[3].targets, ['invoices-tabs']);
      expect(steps[2].title, _l.deskTourReceiveTitle);
      expect(steps[4].title, _l.deskTourActivityTitle);
      expect(steps[3].text, 'Pay an invoice someone sent, or issue one to someone who owes you. The tabs switch between the two.');
    });

    test('this build follows the routes: the step is there exactly when DeskRoute.invoices is', () {
      final has = DeskRoute.values.any((r) => r.name == 'invoices');
      expect(deskInvoicesRoute != null, has);
      expect(deskTourSteps.length, has ? 9 : 8);
      expect(deskTourSteps.any((s) => s.title == 'Invoices'), has);
      if (has) {
        final step = deskTourSteps[3];
        expect(step.route, deskInvoicesRoute);
        expect(step.navId, 'nav-invoices');
      }
    });

    test('copy: short, impersonal, no "we", no report channel', () {
      for (final s in tourStepsFor(invoices: true)) {
        expect(s.text.length, lessThan(160), reason: s.title);
        expect(s.text.split(RegExp(r'[.!?] ')).length, lessThanOrEqualTo(2), reason: s.title);
        expect(s.text, isNot(matches(RegExp(r'\b[Ww]e\b'))), reason: s.title);
        expect(s.text.toLowerCase(), isNot(contains('telegram')), reason: s.title);
      }
    });
  });

  testWidgets('the sidebar runs as the phone: Activity, Outputs, Contacts, Invoices, Send, Receive; each step lights an entry in it', (tester) async {
    // Outputs sits in the sidebar once Advanced shows it.
    final container = await _open(tester, DeskRoute.overview);
    await tester.runAsync(() => advancedOn(container, only: {AdvancedFeature.outputs}));
    await _settle(tester);
    double top(String id) => tester.getTopLeft(find.byKey(tourKey(id))).dy;
    final ids = ['nav-overview', 'nav-activity', 'nav-outputs', 'nav-contacts', 'nav-invoices', 'nav-send', 'nav-receive', 'nav-settings'];
    final tops = [for (final id in ids) top(id)];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: '${ids[i]} below ${ids[i - 1]}');
    }
    for (final step in tourStepsFor(invoices: true)) {
      expect(find.byKey(tourKey(step.navId)), findsOneWidget, reason: step.title);
    }
  });

  testWidgets('Next walks every page in order, lights the area and the sidebar entry, and ends on Help', (tester) async {
    final container = await _open(tester, DeskRoute.overview);
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    final steps = deskTourSteps;
    for (final (i, step) in steps.indexed) {
      expect(container.read(deskNavProvider).route, step.route, reason: 'step ${i + 1}');
      expect(_inCard('${i + 1} of ${steps.length}'), findsOneWidget);
      expect(_inCard(step.title), findsOneWidget);
      expect(_inCard(step.text), findsOneWidget);
      // The page area, the sidebar entry, and on a Settings page its list entry.
      expect(_holes(tester), step.subId == null ? 2 : 3, reason: 'step ${i + 1} ${step.title}');
      expect(_inCard(_l.deskTourBack), i == 0 ? findsNothing : findsOneWidget);
      final last = i == steps.length - 1;
      expect(_inCard(last ? 'Done' : _l.deskTourNext), findsOneWidget);
      await tester.tap(_inCard(last ? 'Done' : _l.deskTourNext));
      await _settle(tester);
    }
    expect(container.read(deskTourProvider).open, isFalse);
    expect(find.byType(DeskTourOverlay), findsNothing);
    expect(container.read(deskNavProvider).route, DeskRoute.overview, reason: 'Done leaves the person on Overview');
  });

  test('epic1 mode: Send and Receive light the link pages and say so, at Shallow too', () {
    final steps = deskTourStepsFor(supportsInvoices: false, epic1: true);
    final send = steps.firstWhere((s) => s.route == DeskRoute.send);
    final receive = steps.firstWhere((s) => s.route == DeskRoute.receive);
    expect(send.targets, ['e1-send-form']);
    expect(send.text, englishStrings.deskE1TourSendText);
    expect(receive.targets, ['e1-receive-link']);
    expect(receive.text, englishStrings.deskE1TourReceiveText);
    expect(steps.any((s) => s.title == 'Invoices'), isFalse);
    // Shallow keeps epic1's Send: its form shows at every view.
    final shallow = deskTourStepsFor(supportsInvoices: false, shallow: true, epic1: true);
    expect(shallow.any((s) => s.route == DeskRoute.send), isTrue);
    expect(deskTourStepsFor(supportsInvoices: false, shallow: true).any((s) => s.route == DeskRoute.send), isFalse);
  });

  testWidgets('a wallet without invoices: no Invoices step even when the page is in the app', (tester) async {
    expect(deskTourStepsFor(supportsInvoices: false).any((s) => s.title == 'Invoices'), isFalse);
    expect(deskTourStepsFor(supportsInvoices: true), same(deskTourSteps));
    final container = await _open(tester, DeskRoute.overview, api: _NoInvoices());
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    final steps = tourStepsFor(invoices: false);
    expect(_inCard('1 of ${steps.length}'), findsOneWidget);
    for (final (i, step) in steps.indexed) {
      expect(container.read(deskNavProvider).route, step.route, reason: 'step ${i + 1}');
      expect(_inCard(step.title), findsOneWidget);
      await tester.tap(_inCard(i == steps.length - 1 ? _l.commonDone : _l.deskTourNext));
      await _settle(tester);
    }
    expect(container.read(deskTourProvider).open, isFalse);
  });

  testWidgets('Back returns to the previous page; the arrow keys and Enter move too', (tester) async {
    final container = await _open(tester, DeskRoute.overview);
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.send);
    expect(_inCard('2 of ${deskTourSteps.length}'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.receive);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.send);
    await tester.tap(_inCard(_l.deskTourBack));
    await _settle(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);
    expect(_inCard('1 of ${deskTourSteps.length}'), findsOneWidget);
    // On the first step the left arrow does nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(_inCard('1 of ${deskTourSteps.length}'), findsOneWidget);
    expect(container.read(deskTourProvider).open, isTrue);
  });

  testWidgets('Esc ends it on Overview and counts as seen', (tester) async {
    final container = await _open(tester, DeskRoute.overview);
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    await tester.tap(_inCard(_l.deskTourNext));
    await _settle(tester);
    await tester.tap(_inCard(_l.deskTourNext));
    await _settle(tester);
    expect(container.read(deskNavProvider).route, DeskRoute.receive);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(container.read(deskTourProvider).open, isFalse);
    expect(container.read(deskTourProvider).seen, isTrue);
    expect(find.byType(DeskTourOverlay), findsNothing);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);
  });

  testWidgets('Skip tour ends it; so does a click on the dimmed page', (tester) async {
    final container = await _open(tester, DeskRoute.overview);
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    await tester.tap(_inCard(_l.deskTourNext));
    await _settle(tester);
    await tester.tap(_inCard(_l.deskTourSkip));
    await _settle(tester);
    expect(container.read(deskTourProvider).open, isFalse);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);

    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    expect(find.byType(DeskTourOverlay), findsOneWidget);
    // Bottom-right corner of the window: dimmed page, not the card.
    await tester.tapAt(const Offset(1270, 790));
    await _settle(tester);
    expect(container.read(deskTourProvider).open, isFalse);
  });

  testWidgets('Help › Show the tour again starts it on Overview; Appearance has no tour row', (tester) async {
    final container = await _open(tester, DeskRoute.settingsAppearance);
    expect(find.text('Show the tour'), findsNothing);
    expect(find.text('Tour'), findsNothing);
    container.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp);
    await _settle(tester);
    container.read(deskTourProvider.notifier).close();
    // Settings scrolls its own column beside the section list: bring the link in.
    await tester.ensureVisible(find.text(_l.deskSetHelpTourStart));
    await _settle(tester);
    await tester.tap(find.text(_l.deskSetHelpTourStart));
    await _settle(tester);
    expect(container.read(deskTourProvider).open, isTrue);
    expect(container.read(deskNavProvider).route, DeskRoute.overview);
    expect(_inCard('1 of ${deskTourSteps.length}'), findsOneWidget);
    expect(_inCard('Overview'), findsOneWidget);
  });

  testWidgets('with the Invoices page, the Invoices step follows Receive and runs even before its tabs are marked', (tester) async {
    // The page is not on this build: the step opens on Overview with no page area to light.
    debugTourSteps = tourStepsFor(invoices: true);
    final container = await _open(tester, DeskRoute.overview);
    container.read(deskTourProvider.notifier).open(at: 2);
    await _settle(tester);
    expect(_inCard('Receive'), findsOneWidget);
    await tester.tap(_inCard('Next'));
    await _settle(tester);
    expect(_inCard('4 of 9'), findsOneWidget);
    expect(_inCard('Invoices'), findsOneWidget);
    expect(_inCard('Next'), findsOneWidget);
    await tester.tap(_inCard('Next'));
    await _settle(tester);
    expect(_inCard('5 of 9'), findsOneWidget);
    expect(container.read(deskNavProvider).route, DeskRoute.activity);
  });

  testWidgets('narrow window (icon rail): the tour still runs, the card inside the window', (tester) async {
    final container = await _open(tester, DeskRoute.overview, size: const Size(900, 640));
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    for (var i = 0; i < deskTourSteps.length; i++) {
      final card = tester.getRect(find.ancestor(of: _inCard('${i + 1} of ${deskTourSteps.length}'), matching: find.byType(Container)).first);
      expect(card.left, greaterThanOrEqualTo(0));
      expect(card.right, lessThanOrEqualTo(900));
      expect(card.bottom, lessThanOrEqualTo(640));
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
    }
    expect(container.read(deskTourProvider).open, isFalse);
  });

  testWidgets('seen once: after a skip the next start does not open it, and Help still can', (tester) async {
    final store = DeskStore(MemorySecretStore());
    final first = await _open(tester, DeskRoute.overview, store: store);
    expect(first.read(deskTourProvider).seen, isFalse);
    first.read(deskTourProvider.notifier).open();
    await _settle(tester);
    await tester.tap(_inCard(_l.deskTourSkip));
    await _settle(tester);
    await tester.runAsync(() => pumpEventQueue());
    expect((await tester.runAsync(store.settings))!.tourSeen, isTrue);

    await tester.pumpWidget(const SizedBox());
    final second = await _open(tester, DeskRoute.overview, store: store);
    await _settle(tester);
    expect(second.read(deskTourProvider).seen, isTrue);
    expect(second.read(deskTourProvider).open, isFalse);
    expect(find.byType(DeskTourOverlay), findsNothing);
    second.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp);
    await _settle(tester);
    // Settings scrolls its own column beside the section list: bring the link in.
    await tester.ensureVisible(find.text(_l.deskSetHelpTourStart));
    await _settle(tester);
    await tester.tap(find.text(_l.deskSetHelpTourStart));
    await _settle(tester);
    expect(find.byType(DeskTourOverlay), findsOneWidget);
    expect(second.read(deskNavProvider).route, DeskRoute.overview);
  });

  testWidgets('the rings follow a window resize', (tester) async {
    final container = await _open(tester, DeskRoute.overview);
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    Rect first() {
      final paint = tester.widget<CustomPaint>(find.descendant(of: find.byType(DeskTourOverlay), matching: find.byType(CustomPaint)).first);
      return ((paint.painter as dynamic).holes as List).first.$1 as Rect;
    }

    final before = first();
    tester.view.physicalSize = const Size(1100, 700);
    await _settle(tester);
    final after = first();
    expect(after, isNot(before));
    expect(after.right, lessThanOrEqualTo(1100));
    expect(after.bottom, lessThanOrEqualTo(700));
  });

  testWidgets('the card buttons have a 44 px hit target; Help starts the tour again', (tester) async {
    final container = await _open(tester, DeskRoute.overview);
    container.read(deskTourProvider.notifier).open();
    await _settle(tester);
    // 20 px under the centre of the 36 px Skip button: outside the drawn button, inside 44.
    await tester.tapAt(tester.getCenter(_inCard(_l.deskTourSkip)) + const Offset(0, 20));
    await _settle(tester);
    expect(container.read(deskTourProvider).open, isFalse);

    container.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp);
    await _settle(tester);
    // Help › Start again: a row button (Ctl.sm, as every row control), it starts the tour.
    await tester.ensureVisible(find.text(_l.deskSetHelpTourStart));
    await _settle(tester);
    await tester.tap(find.widgetWithText(EButton, 'Start tour'));
    await _settle(tester);
    expect(container.read(deskTourProvider).open, isTrue);
  });
}
