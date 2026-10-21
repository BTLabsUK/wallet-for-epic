import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
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
    ('receiving', const DeskLocation(DeskRoute.settingsReceiving)),
    ('receiving combo', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.comboOpen)),
    ('receiving tor', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.torOn)),
    ('receiving down', const DeskLocation(DeskRoute.settingsReceiving, ReceivingDemo.epicboxDown)),
    ('appearance', const DeskLocation(DeskRoute.settingsAppearance)),
    ('account', const DeskLocation(DeskRoute.settingsAccount)),
    ('wallets', const DeskLocation(DeskRoute.settingsWallets)),
    ('phrase', const DeskLocation(DeskRoute.settingsPhrase)),
    ('phrase shown', const DeskLocation(DeskRoute.settingsPhrase, PhraseDemo.shown)),
    ('rescan', const DeskLocation(DeskRoute.settingsRescan)),
    ('rescan running', const DeskLocation(DeskRoute.settingsRescan, RescanDemo.running)),
    ('about', const DeskLocation(DeskRoute.settingsAbout)),
    ('help', const DeskLocation(DeskRoute.settingsHelp)),
  ];
  final dialogs = <(String, Future<void> Function(BuildContext))>[
    ('my node', (c) => showMyNodeDialog(c)),
    ('my node error', (c) => showMyNodeDialog(c, initial: 'http://bad:3413', showError: true)),
    ('directory', showNodeDirectoryDialog),
    ('remove', showRemoveWalletDialog),
    ('public', showPublicModeDialog),
    ('password', showChangePasswordDialog),
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
}
