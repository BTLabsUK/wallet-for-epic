// SPDX-License-Identifier: Apache-2.0
// The test drivers' ids (lib/src/trust_ids.dart) change nothing a screen reader gets: each screen
// that carries ids is built with them and without them (trustIdsOn), and the two semantics trees
// are equal once the identifiers are left out: the same nodes, nesting, roles, states, labels,
// values, hints, tooltips and actions. In a84d404d7 an id on EInput made a password field's row
// take its show/hide button's role and label, with the field inside the button.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/app/shots.dart' show DeskShot;
import 'package:epic_wallet/src/desktop/app/tour.dart' show deskTourProvider;
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';
import 'package:epic_wallet/src/desktop/widgets/fields.dart' show EInput;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/trust_ids.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart';
import 'package:epic_wallet/src/ui/first_run_screen.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/level_step_screen.dart';
import 'package:epic_wallet/src/ui/restore_screen.dart' show RestoreScreen;
import 'package:epic_wallet/src/ui/scan_start.dart' show ScanStart;
import 'package:epic_wallet/src/ui/scan_screen.dart' show FakeQrScanner, qrScannerProvider;
import 'package:epic_wallet/src/ui/settings_history.dart' show FakeHistoryFiles, historyFilesProvider;
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/advanced.dart' show AdvancedPrefs;
import 'package:epic_wallet/src/ui/tour/phone_tour.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tree under the root as lines: one per node, indented by depth, with everything a screen
/// reader gets except the identifier and the geometry.
String _tree(WidgetTester tester) {
  final out = StringBuffer();
  void walk(SemanticsNode n, int depth) {
    final d = n.getSemanticsData();
    final f = d.flagsCollection;
    final flags = [
      if (f.isButton) 'button',
      if (f.isLink) 'link',
      if (f.isTextField) 'textField',
      if (f.isObscured) 'obscured',
      if (f.isReadOnly) 'readOnly',
      if (f.isMultiline) 'multiline',
      if (f.isHeader) 'header',
      if (f.isImage) 'image',
      if (f.isSlider) 'slider',
      if (f.isInMutuallyExclusiveGroup) 'exclusive',
      if (f.isFocused.name != 'none') 'focusable',
      if (f.isEnabled.name != 'none') 'enabled:${f.isEnabled.name}',
      if (f.isChecked.name != 'none') 'checked:${f.isChecked.name}',
      if (f.isToggled.name != 'none') 'toggled:${f.isToggled.name}',
      if (f.isSelected.name != 'none') 'selected:${f.isSelected.name}',
      if (f.isExpanded.name != 'none') 'expanded:${f.isExpanded.name}',
      if (f.isLiveRegion) 'liveRegion',
      if (f.scopesRoute) 'scopesRoute',
      if (f.namesRoute) 'namesRoute',
      if (f.isHidden) 'hidden',
    ];
    final actions = [
      for (final a in SemanticsAction.values)
        if (d.hasAction(a)) a.name,
    ];
    out.writeln([
      '  ' * depth,
      if (flags.isNotEmpty) '[${flags.join(' ')}]',
      if (actions.isNotEmpty) '{${actions.join(' ')}}',
      if (d.label.isNotEmpty) 'label="${d.label}"',
      if (d.value.isNotEmpty) 'value="${d.value}"',
      if (d.hint.isNotEmpty) 'hint="${d.hint}"',
      if (d.tooltip.isNotEmpty) 'tooltip="${d.tooltip}"',
      if (d.role.name != 'none') 'role=${d.role.name}',
    ].join(' '));
    n.visitChildren((c) {
      walk(c, depth + 1);
      return true;
    });
  }

  walk(tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!, 0);
  return out.toString();
}

/// The lines of [b] that differ from [a]'s, around the first difference.
String _diff(String a, String b) {
  final x = a.split('\n');
  final y = b.split('\n');
  var i = 0;
  while (i < x.length && i < y.length && x[i] == y[i]) {
    i++;
  }
  String around(List<String> l) => l.sublist((i - 3).clamp(0, l.length), (i + 6).clamp(0, l.length)).join('\n');
  return 'line ${i + 1}\nwithout ids:\n${around(x)}\nwith ids:\n${around(y)}';
}

/// Builds the screen with ids off, then on, and expects one tree; [ids] must be on it.
Future<void> _same(WidgetTester tester, Future<void> Function() open, Future<void> Function() close, List<String> ids) async {
  final handle = tester.ensureSemantics();
  addTearDown(() => trustIdsOn = true);
  trustIdsOn = false;
  await open();
  final without = _tree(tester);
  for (final id in ids) {
    expect(find.bySemanticsIdentifier(id), findsNothing, reason: '$id with ids off');
  }
  await close();
  trustIdsOn = true;
  await open();
  final withIds = _tree(tester);
  for (final id in ids) {
    expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
    // The id names the control's own node, not an empty one around it.
    final d = tester.getSemantics(find.bySemanticsIdentifier(id)).getSemanticsData();
    expect(d.label.isNotEmpty || d.value.isNotEmpty || d.tooltip.isNotEmpty, isTrue, reason: '$id names an empty node');
  }
  await close();
  handle.dispose();
  expect(withIds == without, isTrue, reason: _diff(without, withIds));
}

// ---- Desktop: the catalogue's shots, as test/trust_ids_test.dart opens them.

final _shots = <String, DeskShot>{
  for (final s in [...onboardingShots, ...settingsShots, ...transferShots, ...walletShots]) s.id: s,
};

Future<ProviderContainer> _openDesk(WidgetTester tester, DeskShot shot) async {
  tester.view.physicalSize = Size(shot.width, shot.height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    }
  }

  final container = ProviderContainer(retry: (_, _) => null);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  if (shot.before != null) await tester.runAsync(() => shot.before!(container));
  container.read(deskNavProvider.notifier)
    ..reset(DeskRoute.overview)
    ..go(shot.route, shot.arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await settle();
  final ctx = tester.element(find.byType(DeskRoot));
  if (shot.prepare != null) {
    await tester.runAsync(() => shot.prepare!(container, ctx));
    await settle();
  }
  if (shot.dialog != null) {
    shot.dialog!(ctx);
    await settle();
  }
  return container;
}

Future<void> _closeDesk(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

// ---- Phone: an open fake wallet, as test/phone_tour_test.dart pumps Home.

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets', nodeUrl: 'https://node');
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

Future<void> _openPhone(WidgetTester tester, Widget home, {bool open = true, bool tour = false}) async {
  tester.view.physicalSize = const Size(412, 915) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = FakeWalletSession();
  final store = MemorySecretStore()..values['wallet.mainnet.backedUp'] = '1';
  // Every switch of Advanced shown, so its page has all its rows.
  store.values['app.advanced_prefs'] = AdvancedPrefs.all.encode();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        phoneTourAutoProvider.overrideWithValue(tour),
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        walletServiceProvider.overrideWithValue(FakeWalletService(session: session)),
        secretStoreProvider.overrideWithValue(store),
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
        updatePlatformProvider.overrideWithValue(null),
        priceSourceProvider.overrideWithValue(_NoPrice()),
        qrScannerProvider.overrideWithValue(FakeQrScanner()),
        slateFilesProvider.overrideWithValue(FakeSlateFiles()),
        historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
        if (open) sessionProvider.overrideWith(() => _Open(session)),
        walletConfigProvider.overrideWith(_Config.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (tour) {
    await tester.pump(phoneTourStartDelay + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }
}

Future<void> _closePhone(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  // Shot -> the ids on it (test/trust_ids_test.dart's screens).
  final desk = <String, List<String>>{
    '01-welcome': ['g4.welcome.create', 'g4.welcome.restore', 'g4.welcome.import'],
    '02a-create': ['g4.account.password', 'g4.account.confirm', 'g4.create.submit'],
    '02b-create-phrase': ['g4.create.reveal'],
    '02c-create-phrase-shown': ['g4.create.written', 'g4.create.continue'],
    '03-restore': ['g4.restore.phrase', 'g4.restore.next'],
    '03c-restore-password': [
      'g4.restore.password', 'g4.restore.passwordConfirm', 'g4.restore.continue', 'g4.restore.start', 'g4.restore.info',
    ],
    '04g-setup-resumed': ['g4.setup.skip'],
    '05-unlock': ['g4.unlock.password', 'g4.unlock.submit'],
    '10-overview': ['g4.nav.overview', 'g4.nav.settings', 'g4.overview.refresh', 'g4.overview.available'],
    '13-send': ['g4.send.to', 'g4.send.amount', 'g4.send.max', 'g4.send.review'],
    '16-send-review': ['g4.send.password', 'g4.send.confirm'],
    '16c-send-done': ['g4.send.another'],
    '17-receive': ['g4.receive.address'],
    '22-settings-node': ['g4.server.node', 'g4.settings.section.node'],
    '22c-node-typed': ['g4.server.search', 'g4.server.node.add'],
    '23-settings-receiving': ['g4.server.epicbox', 'g4.confirmations.fewer', 'g4.confirmations.more'],
    '23b-epicbox-combobox-open': ['g4.server.epicbox', 'g4.server.search'],
    '23j-epicbox-picked': ['g4.server.epicbox.switch'],
    '24-settings-appearance': ['g4.appearance.theme.system', 'g4.appearance.theme.dark', 'g4.appearance.theme.light'],
    '25-settings-account': ['g4.wallet.label'],
    '43-advanced': ['g4.advanced.technical', 'g4.level.stop.1', 'g4.level.stop.2', 'g4.level.stop.3'],
  };

  group('desktop', () {
    for (final e in desk.entries) {
      testWidgets('${e.key}: the same tree with and without ids', (tester) async {
        final shot = _shots[e.key];
        expect(shot, isNotNull, reason: 'no shot ${e.key}');
        await _same(tester, () => _openDesk(tester, shot!), () => _closeDesk(tester), e.value);
      });
    }

    testWidgets('the wallet name edited: Save', (tester) async {
      Future<void> open() async {
        await _openDesk(tester, _shots['25-settings-account']!);
        final field = find.byWidgetPredicate((w) => w is EInput && w.semanticsId == TrustIds.walletLabel);
        await tester.enterText(find.descendant(of: field, matching: find.byType(EditableText)), 'Renamed wallet');
        await tester.pump(const Duration(milliseconds: 200));
      }

      await _same(tester, open, () => _closeDesk(tester), ['g4.wallet.label.save']);
    });

    testWidgets('Restore\u2019s start opened, then by height; the info popover', (tester) async {
      Future<void> open({bool height = false, bool info = false}) async {
        await _openDesk(tester, _shots['03c-restore-password']!);
        // The fold's first frame is at elapsed 0: one frame to start, one to open.
        await tester.tap(find.byKey(info ? ScanStart.infoKey : ScanStart.changeKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        if (height) {
          await tester.tap(find.text(englishStrings.restoreStartByHeight));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }
      }

      await _same(tester, open, () => _closeDesk(tester), [
        'g4.restore.by.month', 'g4.restore.by.height', 'g4.restore.month',
      ]);
      await _same(tester, () => open(height: true), () => _closeDesk(tester), ['g4.restore.height']);
      await _same(tester, () => open(info: true), () => _closeDesk(tester), ['g4.restore.fromStart']);
    });

    testWidgets('the tour: Skip', (tester) async {
      Future<void> open() async {
        final container = await _openDesk(tester, _shots['10-overview']!);
        container.read(deskTourProvider.notifier).open();
        await tester.pump(const Duration(milliseconds: 600));
      }

      await _same(tester, open, () => _closeDesk(tester), ['g4.tour.skip']);
    });
  });

  group('phone', () {
    testWidgets('Home with the tour: Lock, Settings, Contacts, Skip', (tester) async {
      await _same(
        tester,
        () => _openPhone(tester, const HomeScreen(), tour: true),
        () => _closePhone(tester),
        ['g4.home.lock', 'g4.home.settings', 'g4.home.contacts', 'g4.tour.skip'],
      );
    });

    testWidgets('Settings: the section rows', (tester) async {
      await _same(tester, () => _openPhone(tester, const SettingsScreen()), () => _closePhone(tester), [
        TrustIds.settingsSection(SettingsSection.advanced.name),
      ]);
    });

    testWidgets('Settings › Advanced: level, technical details, confirmations', (tester) async {
      await _same(
        tester,
        () => _openPhone(tester, const SettingsSectionScreen(section: SettingsSection.advanced)),
        () => _closePhone(tester),
        ['g4.advanced.level', 'g4.advanced.technical', 'g4.confirmations.fewer', 'g4.confirmations.more'],
      );
    });

    testWidgets('Settings › Display: theme', (tester) async {
      await _same(
        tester,
        () => _openPhone(tester, const SettingsSectionScreen(section: SettingsSection.display)),
        () => _closePhone(tester),
        ['g4.appearance.theme'],
      );
    });

    testWidgets('Backup: agree and show', (tester) async {
      await _same(
        tester,
        () => _openPhone(tester, const BackupScreen()),
        () => _closePhone(tester),
        ['g4.backup.agree', 'g4.backup.show'],
      );
    });

    testWidgets('First run: create and restore', (tester) async {
      await _same(
        tester,
        () => _openPhone(tester, const FirstRunScreen(), open: false),
        () => _closePhone(tester),
        ['g4.welcome.create', 'g4.welcome.restore'],
      );
    });

    testWidgets('Restore: the phrase, the start, the info, Continue; opened by month, then by height; the info sheet', (tester) async {
      Future<void> open({bool start = false, bool height = false, bool info = false}) async {
        await _openPhone(tester, const RestoreScreen(), open: false);
        // Scrolled into view first: the choice opens under the line, above the bottom bar.
        Future<void> tap(Finder f) async {
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          await tester.tap(f);
          await tester.pumpAndSettle();
        }

        if (start) await tap(find.byKey(ScanStart.changeKey));
        if (height) await tap(find.text(englishStrings.restoreStartByHeight));
        if (info) await tap(find.byKey(ScanStart.infoKey));
      }

      await _same(tester, open, () => _closePhone(tester), [
        'g4.restore.phrase', 'g4.restore.start', 'g4.restore.info', 'g4.restore.continue',
      ]);
      await _same(tester, () => open(start: true), () => _closePhone(tester), [
        'g4.restore.by.month', 'g4.restore.by.height', 'g4.restore.month',
      ]);
      await _same(tester, () => open(start: true, height: true), () => _closePhone(tester), ['g4.restore.height']);
      await _same(tester, () => open(info: true), () => _closePhone(tester), ['g4.restore.fromStart']);
      // The roles the drivers look for.
      await open(start: true, height: true);
      final handle = tester.ensureSemantics();
      await tester.pump();
      SemanticsData data(String id) => tester.getSemantics(find.bySemanticsIdentifier(id)).getSemanticsData();
      expect(data('g4.restore.phrase').flagsCollection.isTextField, isTrue);
      expect(data('g4.restore.height').flagsCollection.isTextField, isTrue);
      for (final id in ['g4.restore.start', 'g4.restore.info', 'g4.restore.by.month', 'g4.restore.by.height', 'g4.restore.continue']) {
        expect(data(id).hasAction(SemanticsAction.tap), isTrue, reason: id);
      }
      for (final id in ['g4.restore.start', 'g4.restore.info']) {
        expect(data(id).flagsCollection.isButton, isTrue, reason: id);
      }
      // Scan from the start: a button in the info sheet while a month is the start (by height
      // with nothing typed is the start already, so the sheet holds no button then).
      await _closePhone(tester);
      await open(info: true);
      expect(data('g4.restore.fromStart').hasAction(SemanticsAction.tap), isTrue);
      expect(data('g4.restore.fromStart').flagsCollection.isButton, isTrue);
      handle.dispose();
      await _closePhone(tester);
    });

    testWidgets('Level step: create, restore and the level stops', (tester) async {
      await _same(
        tester,
        () => _openPhone(tester, const LevelStepScreen(), open: false),
        () => _closePhone(tester),
        ['g4.welcome.create', 'g4.welcome.restore'],
      );
    });
  });
}
