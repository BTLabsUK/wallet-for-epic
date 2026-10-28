import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/app/app_dialogs.dart';
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart' show demoOtherWallet;
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_frame.dart' show JumpSection;
import 'package:epic_wallet/src/desktop/screens/settings/settings_about.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_account.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_appearance.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_wallets.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_phrase.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_rescan.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';

Widget deskScreen(DeskLocation at) {
  final a = at.arg;
  return switch (at.route) {
    DeskRoute.settingsNode => SettingsNodeScreen(arg: a),
    DeskRoute.settingsReceiving => SettingsReceivingScreen(arg: a),
    DeskRoute.settingsAppearance => SettingsAppearanceScreen(arg: a),
    DeskRoute.settingsAccount => SettingsAccountScreen(arg: a),
    DeskRoute.settingsWallets => SettingsWalletsScreen(arg: a),
    DeskRoute.settingsPhrase => SettingsPhraseScreen(arg: a),
    DeskRoute.settingsRescan => SettingsRescanScreen(arg: a),
    DeskRoute.settingsAbout => SettingsAboutScreen(arg: a),
    _ => SettingsHelpScreen(arg: a),
  };
}

void main() {
  final cases = <(String, DeskLocation)>[
    ('node', const DeskLocation(DeskRoute.settingsNode)),
    ('node combo', const DeskLocation(DeskRoute.settingsNode, NodeDemo.comboOpen)),
    ('node typed', const DeskLocation(DeskRoute.settingsNode, NodeDemo.typed)),
    ('node failed', const DeskLocation(DeskRoute.settingsNode, NodeDemo.pickFailed)),
    ('node builtin', const DeskLocation(DeskRoute.settingsNode, NodeDemo.builtin)),
    ('receiving', const DeskLocation(DeskRoute.settingsReceiving)),
    ('receiving combo', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.comboOpen)),
    ('receiving tor', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.torOn)),
    ('receiving down', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.epicboxDown)),
    ('receiving http on', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.httpOn)),
    ('receiving http failed', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.httpFailed)),
    ('appearance', const DeskLocation(DeskRoute.settingsAppearance)),
    ('account', const DeskLocation(DeskRoute.settingsAccount)),
    ('wallets', const DeskLocation(DeskRoute.settingsWallets)),
    ('phrase', const DeskLocation(DeskRoute.settingsPhrase)),
    ('phrase shown', const DeskLocation(DeskRoute.settingsPhrase, PhraseDemo.shown)),
    ('phrase qr', const DeskLocation(DeskRoute.settingsPhrase, PhraseDemo.qr)),
    ('rescan', const DeskLocation(DeskRoute.settingsRescan)),
    ('rescan running', const DeskLocation(DeskRoute.settingsRescan, RescanDemo.running)),
    ('about', const DeskLocation(DeskRoute.settingsAbout)),
    ('help', const DeskLocation(DeskRoute.settingsHelp)),
    ('help search', const DeskLocation(DeskRoute.settingsHelp, 'file')),
  ];
  final dialogs = <(String, Future<void> Function(BuildContext))>[
    ('chain offer', showChainOfferDialog),
    ('chain offer in use', (c) => showChainOfferDialog(c, inUse: true)),
    ('remove', (c) => showRemoveWalletDialog(c, demoOtherWallet)),
    ('remove everything', (c) => showRemoveWalletDialog(c, demoOtherWallet, mode: RemoveMode.everything)),
    ('password', showChangePasswordDialog),
    ('node synced', showNodeSyncedDialog),
    ('first scan', (c) => showFirstScanDialog(c)),
  ];

  for (final size in const [Size(1280, 800), Size(1000, 700), Size(560, 800)]) {
    for (final (name, at) in cases) {
      testWidgets('$name at ${size.width.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: deskScreen(at))),
        ));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  }

  for (final (name, open) in dialogs) {
    for (final size in const [Size(1280, 800), Size(560, 800)]) {
      testWidgets('dialog $name at ${size.width.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
        late BuildContext ctx;
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: Builder(builder: (c) { ctx = c; return const SizedBox(); }))),
        ));
        open(ctx);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  }

  // The shell with the tour open on each step, at the three layouts.
  for (final size in const [Size(1280, 800), Size(1000, 700), Size(560, 800)]) {
    // Invoices is experimental and off by default: the tour has no Invoices step then.
    final steps = deskTourStepsFor(supportsInvoices: false);
    for (final step in [0, 1, steps.length - 1]) {
      testWidgets('shell tour step $step at ${size.width.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
        container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAbout);
        container.read(deskTourProvider.notifier).open(at: step);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const DeskShell(at: DeskLocation(DeskRoute.settingsAbout))),
        ));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.text('${step + 1} of ${steps.length}'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 10));
      });
    }
  }

  // Build 6: the jump painted the whole section solid gold for seconds. Now a thin
  // outline that is gone after a second, no fill, and nothing at all with reduced motion.
  for (final reduce in [false, true]) {
    testWidgets('a jump marks its section with a fading outline only (reduced motion: $reduce)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAbout);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: child!),
          home: Consumer(builder: (_, ref, _) => DeskShell(at: ref.watch(deskNavProvider))),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      BoxDecoration cue() => tester
          .widget<DecoratedBox>(find.descendant(of: find.byType(JumpSection), matching: find.byType(DecoratedBox)).first)
          .decoration as BoxDecoration;
      container.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.node);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(JumpSection), findsOneWidget);
      expect(cue().color, isNull, reason: 'never a fill');
      expect(cue().boxShadow, isNull);
      expect(cue().border != null, !reduce);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(cue().border, isNull, reason: 'gone after a second');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  }

  testWidgets('a status row jumps into its settings section', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAbout);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const DeskApp(),
    ));
    await tester.pump(const Duration(seconds: 1));
    // The status rows are in the title bar's status list.
    await tester.tap(find.byKey(const ValueKey('bar-status')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('status-row-epicbox')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(container.read(deskNavProvider).route, DeskRoute.settingsReceiving);
    expect(container.read(settingsPrefsProvider).jump?.section, SettingsJump.epicbox);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  });
}
