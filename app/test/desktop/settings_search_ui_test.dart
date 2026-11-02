// SPDX-License-Identifier: Apache-2.0
// Settings search from the keyboard: Ctrl+K focuses the field, typing lists the results, ↓
// moves the highlight and Enter opens the row's page with the row in view and its control
// focused. Esc clears, a second Esc leaves. Hidden-here results, the ⇕ control and the
// 44 px info hit area too. The pages here are stand-ins that list the registry's rows with
// their anchors; the real pages carry the same anchors.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/settings_registry.dart';
import 'package:epic_wallet/src/desktop/screens/settings/search/search_slot.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/more_options.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/desktop/desk_l10n.dart';
import 'package:epic_wallet/src/l10n.dart' show lookupAppLocalizations;
import 'package:epic_wallet/src/tor_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page with every registry row of [route], each with its anchor and a switch.
class _Page extends StatelessWidget {
  const _Page(this.route);

  final DeskRoute route;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ESetGroup(
      title: route.name,
      rows: [
        for (final e in settingsRegistry.where((e) => e.route == route))
          ESetRow(key: ValueKey('row-${e.id}'), anchor: e.id, title: e.label(l), control: ESwitch(value: false, semanticLabel: e.label(l), onChanged: (_) {})),
      ],
    );
  }
}

/// The Settings takeover in small: the field over the page, or the results while searching.
class _Takeover extends ConsumerWidget {
  const _Takeover({required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = ref.watch(deskNavProvider);
    final searching = ref.watch(settingsQueryProvider).isNotEmpty;
    return SettingsSearchKeys(
      onLeave: onLeave,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 260, child: Padding(padding: EdgeInsets.all(8), child: SettingsSearchSlot())),
          Expanded(child: SingleChildScrollView(child: searching ? const SettingsSearchResults() : _Page(at.route))),
        ],
      ),
    );
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, {WalletLevel level = WalletLevel.everything, VoidCallback? onLeave}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [
    deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero)),
    deskLevelProvider.overrideWithValue(level),
  ]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAppearance);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: _Takeover(onLeave: onLeave ?? () {}))),
  ));
  await tester.pumpAndSettle();
  return container;
}

/// Whether the focus is inside the row with [id].
bool _focusIn(WidgetTester tester, String id) {
  final row = tester.element(find.byKey(ValueKey('row-$id')));
  var inside = false;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
    if (e == row) inside = true;
    return !inside;
  });
  return inside;
}

void main() {
  testWidgets('Ctrl+K → type → ↓ → Enter lands on the row, focused', (tester) async {
    final c = await _pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final field = find.descendant(of: find.byKey(SettingsSearchSlot.fieldKey), matching: find.byType(EditableText));
    expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
    await tester.enterText(field, 'tor');
    await tester.pumpAndSettle();
    // Payments' Link · Tor first, Network & privacy's Connection mode (Tor only) next.
    expect(find.text('Connection mode'), findsOneWidget);
    expect(find.textContaining('results'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(c.read(settingsSearchCursorProvider), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(c.read(deskNavProvider).route, DeskRoute.settingsPrivacy);
    expect(c.read(settingsQueryProvider), isEmpty);
    expect(_focusIn(tester, SetId.netMode), isTrue);
    expect(tester.getRect(find.byKey(const ValueKey('row-${SetId.netMode}'))).bottom, lessThanOrEqualTo(800));
    // "tor" finds Link · Tor and Tor only, which the build without Tor leaves out.
  }, skip: !torBuilt);

  testWidgets('Esc clears the search, a second Esc leaves Settings', (tester) async {
    var left = 0;
    final c = await _pump(tester, onLeave: () => left++);
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    final field = find.descendant(of: find.byKey(SettingsSearchSlot.fieldKey), matching: find.byType(EditableText));
    await tester.enterText(field, 'theme');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(c.read(settingsQueryProvider), isEmpty);
    expect(left, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(left, 1);
  });

  testWidgets('nothing found: the query and words to try; a word searches again', (tester) async {
    final c = await _pump(tester);
    final field = find.descendant(of: find.byKey(SettingsSearchSlot.fieldKey), matching: find.byType(EditableText));
    await tester.enterText(field, 'zzqx');
    await tester.pumpAndSettle();
    expect(find.text('No setting matches “zzqx”.'), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, 'seed'));
    await tester.pumpAndSettle();
    expect(c.read(settingsQueryProvider), 'seed');
    expect(find.text('Matches “seed”'), findsWidgets);
  });

  testWidgets('a hidden-here result turns its switch on and jumps to the row (review 2)', (tester) async {
    final c = await _pump(tester);
    final adv = c.read(deskProvider).settings.advanced;
    if (adv.has(AdvancedFeature.logs)) {
      await tester.runAsync(() => c.read(deskProvider.notifier).saveSettings(c.read(deskProvider).settings.copyWith(advanced: adv.withFeature(AdvancedFeature.logs, false))));
      await tester.pump();
    }
    final field = find.descendant(of: find.byKey(SettingsSearchSlot.fieldKey), matching: find.byType(EditableText));
    await tester.enterText(field, 'log level');
    await tester.pumpAndSettle();
    expect(find.text('Hidden here'), findsOneWidget);
    expect(find.text('Advanced › Logs'), findsWidgets);
    await tester.tap(find.widgetWithText(EButton, 'Turn on'));
    await tester.pumpAndSettle();
    expect(c.read(deskProvider).settings.advanced.has(AdvancedFeature.logs), isTrue);
    expect(c.read(deskNavProvider).route, DeskRoute.settingsFiles);
    expect(_focusIn(tester, SetId.logLevel), isTrue);
  });

  testWidgets('a hidden-here result names the view that shows it', (tester) async {
    final c = await _pump(tester, level: WalletLevel.justSendReceive);
    final field = find.descendant(of: find.byKey(SettingsSearchSlot.fieldKey), matching: find.byType(EditableText));
    await tester.enterText(field, 'epicbox server');
    await tester.pumpAndSettle();
    expect(find.text('Hidden here'), findsOneWidget);
    expect(find.text('Deeper view'), findsWidgets);
    expect(find.widgetWithText(EButton, 'Show in Deeper'), findsWidgets);
    expect(c.read(settingsSearchRoutesProvider), contains(DeskRoute.settingsReceiving));
    expect(find.text('0 results'), findsNothing);
  });

  testWidgets('the ⇕ control names every gate and reveals the rows in place, marked', (tester) async {
    final l = lookupAppLocalizations(const Locale('en'));
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(
          body: ESetGroup(
            title: 'Sending',
            revealKey: 'g:send',
            rows: const [ESetRow(title: 'Default method')],
            hidden: [
              ESetRow(title: 'Outputs a send spends', advancedBy: l.deskSetSearchViewGate('Deep end')),
              ESetRow(title: 'Split change', advancedBy: l.deskSetSearchFeatGate('Send options')),
            ],
          ),
        ),
      ),
    ));
    final more = find.byType(EMoreOptions);
    expect(find.text('Split change'), findsNothing);
    expect(tester.getSize(more).width, greaterThanOrEqualTo(44));
    expect(tester.getSize(more).height, greaterThanOrEqualTo(44));
    expect(find.bySemanticsLabel('2 more options · shown with Deep end view and Advanced › Send options'), findsOneWidget);
    await tester.tap(more);
    await tester.pump();
    expect(find.text('Split change'), findsOneWidget);
    expect(find.text('Advanced › Send options'), findsOneWidget);
    expect(find.bySemanticsLabel('Hide the 2 extra options'), findsOneWidget);
  });

  testWidgets('a row’s info icon takes a press 44 px wide, the row keeps its height', (tester) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildDeskTheme(Brightness.dark),
      home: const Scaffold(body: Column(children: [ESetRow(key: ValueKey('r'), title: 'Auto-lock', hint: 'Locks after a while.'), ESetRow(key: ValueKey('p'), title: 'Plain')])),
    ));
    expect(tester.getSize(find.byKey(const ValueKey('r'))).height, tester.getSize(find.byKey(const ValueKey('p'))).height);
    final icon = tester.getRect(find.byType(EInfoHint));
    expect(icon.width, lessThan(44));
    // 10 px beyond its edge still opens it.
    await tester.tapAt(icon.centerRight + const Offset(10, 0));
    await tester.pumpAndSettle();
    expect(find.text('Locks after a while.'), findsWidgets);
  });
}
