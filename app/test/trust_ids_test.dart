// SPDX-License-Identifier: Apache-2.0
// The test drivers' control ids (lib/src/trust_ids.dart, tools/rellib/drivers/trust_ids.json):
// the two lists are one set, and on the screens that carry them each id is one node with the
// role, the tap action and the label the drivers look for.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show CheckedState, Tristate;

import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/widgets/fields.dart' show EInput;
import 'package:epic_wallet/src/desktop/app/shots.dart' show DeskShot;
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/shots.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';
import 'package:epic_wallet/src/trust_ids.dart';
import 'package:epic_wallet/src/ui/scan_start.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _registry = (jsonDecode(File('../tools/rellib/drivers/trust_ids.json').readAsStringSync()) as Map)['controls'] as List;
final _arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

Map<String, dynamic> _control(String id) => _registry.cast<Map<String, dynamic>>().firstWhere((c) => c['id'] == id);

/// The English ARB text of [key] up to its first placeholder.
String _english(String key) {
  final text = _arb[key] as String;
  final at = text.indexOf('{');
  return at < 0 ? text : text.substring(0, at);
}

void main() {
  test('the registry and TrustIds are one set', () {
    final ids = [for (final c in _registry.cast<Map<String, dynamic>>()) c['id'] as String];
    expect(ids.toSet(), hasLength(ids.length), reason: 'an id twice in trust_ids.json');
    expect(TrustIds.all.toSet(), ids.toSet());
    expect(TrustIds.all.toSet(), hasLength(TrustIds.all.length));
    expect(TrustIds.shellNav('overview'), 'g4.nav.overview');
    expect(TrustIds.settingsSection('settingsNode'), 'g4.settings.section.node');
    expect(TrustIds.settingsSection('security'), 'g4.settings.section.security');
    expect(TrustIds.settingsSection('privacyNetwork'), 'g4.settings.section.privacyNetwork');
    expect(TrustIds.levelStop(2), 'g4.level.stop.2');
    for (final c in _registry.cast<Map<String, dynamic>>()) {
      for (final key in (c['keys'] as List).cast<String>()) {
        expect(_arb.containsKey(key), isTrue, reason: '${c['id']}: no ARB key $key');
      }
      expect(c['id'], matches(RegExp(r'^g4\.[a-z]+(\.[A-Za-z0-9_]+)+$')));
    }
  });

  final shots = <String, DeskShot>{
    for (final s in [...onboardingShots, ...settingsShots, ...transferShots, ...walletShots]) s.id: s,
  };

  /// What is wrong with [id] on the screen, or null: one node, with its role, a tap for what
  /// presses, its label.
  String? check(WidgetTester tester, String id) {
    final found = find.bySemanticsIdentifier(id);
    final n = found.evaluate().length;
    if (n != 1) return '$id: $n nodes';
    final control = _control(id);
    final data = tester.getSemantics(found).getSemanticsData();
    final flags = data.flagsCollection;
    final problems = <String>[];
    final role = control['role'];
    final enabled = flags.isEnabled != Tristate.isFalse;
    if (const ['button', 'tab', 'menu_item', 'link'].contains(role) && enabled && !data.hasAction(SemanticsAction.tap)) problems.add('no tap action');
    if (role == 'button' && !flags.isButton) problems.add('not a button');
    if (role == 'text_field' && !flags.isTextField) problems.add('not a text field');
    if (role == 'checkbox' && flags.isChecked == CheckedState.none) problems.add('no checked state');
    if (role == 'toggle' && flags.isChecked == CheckedState.none && flags.isToggled == Tristate.none) problems.add('no switch state');
    final keys = (control['keys'] as List).cast<String>();
    if (keys.isNotEmpty) {
      final label = data.label.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      final first = data.label.split('\n').first.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      final fits = [
        for (final k in keys) _english(k).replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase(),
      ].any(
        (text) => switch (control['match']) {
          'contains' => label.contains(text),
          'starts' => label.startsWith(text),
          _ => first.startsWith(text) || label.startsWith(text),
        },
      );
      if (!fits) problems.add('label "${data.label}" is none of $keys');
    }
    return problems.isEmpty ? null : '$id: ${problems.join(', ')}';
  }

  Future<ProviderContainer> open(WidgetTester tester, DeskShot shot) async {
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

  /// The app gone, and the seconds its timers run out in.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  }

  // Screen (a shot of the catalogue) -> the ids on it.
  final screens = <String, List<String>>{
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
    '10-overview': [
      'g4.nav.overview', 'g4.nav.activity', 'g4.nav.send', 'g4.nav.receive', 'g4.nav.settings',
      'g4.overview.refresh', 'g4.overview.available',
    ],
    '13-send': ['g4.send.to', 'g4.send.amount', 'g4.send.max', 'g4.send.review'],
    '16-send-review': ['g4.send.password', 'g4.send.confirm'],
    '16c-send-done': ['g4.send.another'],
    '17-receive': ['g4.receive.address'],
    '22-settings-node': [
      'g4.server.node', 'g4.settings.section.node', 'g4.settings.section.receiving', 'g4.settings.section.appearance',
      'g4.settings.section.account', 'g4.settings.section.advanced', 'g4.settings.section.about',
    ],
    '22c-node-typed': ['g4.server.search', 'g4.server.node.add'],
    '23-settings-receiving': ['g4.server.epicbox', 'g4.confirmations.fewer', 'g4.confirmations.more'],
    '24-settings-appearance': ['g4.appearance.theme.system', 'g4.appearance.theme.dark', 'g4.appearance.theme.light'],
    '25-settings-account': ['g4.wallet.label'],
    '43-advanced': ['g4.advanced.technical', 'g4.level.stop.1', 'g4.level.stop.2', 'g4.level.stop.3'],
    '23b-epicbox-combobox-open': ['g4.server.epicbox', 'g4.server.search'],
    '23j-epicbox-picked': ['g4.server.epicbox.switch'],
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key}: ${entry.value.length} ids', (tester) async {
      final handle = tester.ensureSemantics();
      final shot = shots[entry.key];
      expect(shot, isNotNull, reason: 'no shot ${entry.key}');
      await open(tester, shot!);
      final problems = [for (final id in entry.value) check(tester, id)].nonNulls.toList();
      expect(problems, isEmpty);
      await close(tester);
      handle.dispose();
    });
  }

  testWidgets('the Epicbox list: a typed address offers Add', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, shots['23b-epicbox-combobox-open']!);
    await tester.enterText(find.descendant(of: find.byKey(const ValueKey('server-list-field')), matching: find.byType(EditableText)), 'epicbox.example.org');
    await tester.pump(const Duration(milliseconds: 300));
    expect(check(tester, 'g4.server.epicbox.add'), isNull);
    await close(tester);
    handle.dispose();
  });

  testWidgets('the wallet name: Save appears with an edit', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, shots['25-settings-account']!);
    await tester.enterText(find.descendant(of: find.byWidgetPredicate((w) => w is EInput && w.semanticsId == TrustIds.walletLabelField), matching: find.byType(EditableText)), 'Renamed wallet');
    await tester.pump(const Duration(milliseconds: 200));
    expect(check(tester, 'g4.wallet.label.save'), isNull);
    await close(tester);
    handle.dispose();
  });

  testWidgets('Restore\u2019s start opened: by month, by height, the month, the height; the info: from the start', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, shots['03c-restore-password']!);
    // The fold's first frame is at elapsed 0: one frame to start, one to open.
    Future<void> tap(Finder f) async {
      await tester.tap(f);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tap(find.byKey(ScanStart.changeKey));
    expect([for (final id in ['g4.restore.by.month', 'g4.restore.by.height', 'g4.restore.month']) check(tester, id)].nonNulls, isEmpty);
    await tap(find.bySemanticsIdentifier('g4.restore.by.height'));
    expect(check(tester, 'g4.restore.height'), isNull);
    // The info holds Scan from the start while a month is the start (by height with nothing
    // typed is the start already).
    await tap(find.bySemanticsIdentifier('g4.restore.by.month'));
    await tap(find.byKey(ScanStart.infoKey));
    expect(check(tester, 'g4.restore.fromStart'), isNull);
    await close(tester);
    handle.dispose();
  });

  test('every id of the registry is used in lib', () {
    final source = [
      for (final f in Directory('lib/src').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && !f.path.endsWith('trust_ids.dart')) f.readAsStringSync(),
    ].join('\n');
    final decl = File('lib/src/trust_ids.dart').readAsStringSync();
    final unused = <String>[];
    for (final m in RegExp(r"static const (\w+) = '([^']+)'").allMatches(decl)) {
      final name = m.group(1)!;
      if (!source.contains('TrustIds.$name') && RegExp('\\b$name\\b').allMatches(decl).length < 2) {
        unused.add(m.group(2)!);
      }
    }
    expect(unused, isEmpty);
  });

  testWidgets('the tour: Skip', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await open(tester, shots['10-overview']!);
    container.read(deskTourProvider.notifier).open();
    await tester.pump(const Duration(milliseconds: 600));
    expect(check(tester, 'g4.tour.skip'), isNull);
    await close(tester);
    handle.dispose();
  });
}
