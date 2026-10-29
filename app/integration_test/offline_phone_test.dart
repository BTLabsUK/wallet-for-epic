// SPDX-License-Identifier: Apache-2.0
// Phone offline check: the real app on an emulator in airplane mode, from its first start.
// Creates a wallet with the PIN, visits the three tabs, every Settings section, Help and
// Contacts, and records per screen: no Flutter exception, no spinner still turning after the
// wait, a body that is not blank, notices sane. Then it asks for the network back (a file the
// host script watches; it turns airplane mode off) and checks the wallet reaches its node and
// Epicbox relay by itself, without a restart. Driven by tool/offline_phone.sh:
//
//   app/tool/offline_phone.sh            # starts its own AVD on port 5560, stops it after
//
// Every check prints one `RC PASS|FAIL | step | evidence` line. Throwaway wallet, PIN 123456;
// the recovery phrase is never shown or printed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart' show openAppSettings;
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/notices.dart' show NoticeCard;
import 'package:epic_wallet/src/ui/settings_sections.dart';
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _pin = '123456';
const _spinnerWait = int.fromEnvironment('OFFLINE_SPINNER_S', defaultValue: 20);

void record(String step, bool pass, [String evidence = '']) =>
    // ignore: avoid_print
    print('RC ${pass ? 'PASS' : 'FAIL'} | $step | ${evidence.replaceAll('\n', ' ⏎ ')}');

final _shotKey = GlobalKey();
late Directory _ext;

Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final ro = _shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (ro == null) return;
  await tester.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = await Directory('${_ext.path}/shots').create(recursive: true);
    await File('${dir.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
  });
}

Future<void> settle(WidgetTester tester, {int ms = 400}) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

List<String> texts() => [
  for (final e in find.byType(RichText).evaluate())
    if ((e.widget as RichText).text.toPlainText().trim() case final t when t.isNotEmpty) t,
];

bool hasText(Pattern p) => texts().any((t) => p is RegExp ? p.hasMatch(t) : t.contains(p as String));

/// What is on screen, the words of a phrase left out.
String screen([int take = 25]) {
  final all = texts();
  final word = RegExp(r'^[a-z]{3,8}$');
  final phrase = all.where(word.hasMatch).length >= 12;
  return all.where((t) => !(phrase && word.hasMatch(t))).take(take).join(' | ');
}

Future<void> pumpUntil(WidgetTester tester, bool Function() done, {Duration timeout = const Duration(seconds: 90), String what = ''}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) throw TestFailure('timeout waiting for $what; on screen: ${screen()}');
    await settle(tester, ms: 250);
  }
}

Future<void> tapText(WidgetTester tester, String t) async {
  final f = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(t));
  expect(f, findsWidgets, reason: 'no "$t": ${screen()}');
  await tester.ensureVisible(f.first);
  await tester.tap(f.first, warnIfMissed: false);
  await settle(tester);
}

Finder fieldF(String label) => find.byWidgetPredicate((w) => w is TextField && (w.decoration?.labelText == label || w.decoration?.hintText == label));

Future<void> typeInto(WidgetTester tester, Finder f, String text) async {
  await pumpUntil(tester, () => f.evaluate().isNotEmpty, what: '$f');
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump();
  await tester.enterText(f.first, text);
  await settle(tester, ms: 300);
}

final _errors = <String>[];
final _visits = <(String, List<String>, int, List<String>, int)>[]; // name, errors, spinners, texts, notices

int _spinners() => find.byWidgetPredicate((w) => w is ProgressIndicator && w.value == null).evaluate().length;

Future<void> look(WidgetTester tester, String name, {int waitS = _spinnerWait}) async {
  final before = _errors.length;
  final end = DateTime.now().add(Duration(seconds: waitS));
  var quiet = 0;
  while (DateTime.now().isBefore(end) && quiet < 3) {
    await settle(tester, ms: 1000);
    quiet = _spinners() == 0 ? quiet + 1 : 0;
  }
  final v = (name, _errors.sublist(before), _spinners(), texts(), find.byType(NoticeCard).evaluate().length);
  _visits.add(v);
  await shot(tester, 'offline-${_visits.length.toString().padLeft(2, '0')}-${name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}');
  // ignore: avoid_print
  print('VISIT $name | errors ${v.$2.length} | spinners ${v.$3} | notices ${v.$5} | ${screen()}');
}

Future<void> push(WidgetTester tester, Widget page) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<void>(builder: (_) => page));
  await settle(tester, ms: 1200);
}

Future<void> toShell(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).popUntil((r) => r.isFirst);
  await settle(tester, ms: 800);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('phone: airplane mode from the first start, then back', (tester) async {
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      _errors.add(d.exceptionAsString().split('\n').first);
      prev?.call(d);
    };
    // The host reads and writes it with `adb shell run-as` (files/rc-offline): the app's own
    // folder, which a debug build lets the shell into.
    _ext = (await tester.runAsync(() async => Directory('${(await getApplicationSupportDirectory()).path}/rc-offline').create(recursive: true)))!;
    final online = await tester.runAsync(() async {
      try {
        (await Socket.connect('1.1.1.1', 443, timeout: const Duration(seconds: 3))).destroy();
        return true;
      } on Object {
        return false;
      }
    });
    record('precondition: no network on the device', online == false, online == true ? 'reached 1.1.1.1:443' : 'no route');

    // As main.dart: the settings file before anything reads a server.
    await tester.runAsync(() async {
      await initWalletBackend();
      await openAppSettings(store: createSecretStore());
    });
    await tester.pumpWidget(ProviderScope(
      retry: (_, _) => null,
      overrides: [
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore(available: false)),
        updatePlatformProvider.overrideWithValue(null),
      ],
      child: RepaintBoundary(key: _shotKey, child: const WalletApp()),
    ));
    await settle(tester, ms: 1500);
    final c = ProviderScope.containerOf(tester.element(find.byType(WalletApp)));
    await pumpUntil(tester, () => hasText('Create a new wallet'), timeout: const Duration(minutes: 2), what: 'Welcome');
    await look(tester, 'Welcome', waitS: 8);

    final t0 = DateTime.now();
    await tapText(tester, 'Create a new wallet');
    await typeInto(tester, fieldF('PIN'), _pin);
    await settle(tester, ms: 600);
    await typeInto(tester, fieldF('Repeat PIN'), _pin);
    var home = true;
    try {
      await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 3), what: 'home');
    } on TestFailure catch (e) {
      home = false;
      record('offline: create wallet reaches Home', false, e.message ?? '');
    }
    if (home) {
      record('offline: create wallet reaches Home', true, '${DateTime.now().difference(t0).inSeconds} s');
      for (var i = 0; i < 6 && find.text('Skip').evaluate().isEmpty; i++) {
        await settle(tester, ms: 500);
      }
      if (find.text('Skip').evaluate().isNotEmpty) await tester.tap(find.text('Skip').first);
      await settle(tester, ms: 800);

      for (final tab in ShellTab.values) {
        c.read(shellTabProvider.notifier).go(tab);
        await settle(tester, ms: 800);
        await look(tester, 'tab ${tab.name}');
      }
      for (final s in SettingsSection.values) {
        await push(tester, SettingsSectionScreen(section: s));
        await look(tester, 'Settings ${s.name}');
        await toShell(tester);
      }
      await push(tester, const HelpScreen());
      await look(tester, 'Help', waitS: 6);
      await toShell(tester);
      await push(tester, const ContactsScreen());
      await look(tester, 'Contacts', waitS: 6);
      await toShell(tester);
      c.read(shellTabProvider.notifier).go(ShellTab.wallet);
      await look(tester, 'Wallet after the visits', waitS: 30);

      // ---- Back online: the host turns airplane mode off when it sees want-up.
      await tester.runAsync(() => File('${_ext.path}/want-up').writeAsString('1'));
      final up = await tester.runAsync(() async {
        for (var i = 0; i < 90; i++) {
          if (File('${_ext.path}/up').existsSync()) return true;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        return false;
      });
      record('back online: the host turned airplane mode off', up == true, '');
      if (up == true) {
        final b0 = DateTime.now();
        bool nodeOk() => c.read(homeProvider).value?.summary.validatedWithNode == true;
        bool boxOk() => c.read(listenerProvider).connected;
        final end = b0.add(const Duration(minutes: 4));
        while (DateTime.now().isBefore(end) && !(nodeOk() && boxOk())) {
          await settle(tester, ms: 2000);
        }
        final secs = DateTime.now().difference(b0).inSeconds;
        record('back online: the node answers without a restart', nodeOk(), 'after $secs s');
        record('back online: Epicbox connects without a restart', boxOk(), 'after $secs s');
        for (final tab in ShellTab.values) {
          c.read(shellTabProvider.notifier).go(tab);
          await settle(tester, ms: 800);
          await look(tester, 'online again: tab ${tab.name}', waitS: 8);
          final stale = texts().where(RegExp(r'offline|unreachable|no connection|can.t reach|not reachable', caseSensitive: false).hasMatch).toList();
          record('back online: tab ${tab.name} shows no offline line', stale.isEmpty, stale.take(3).join(' / '));
        }
      }
    }

    final shell = _visits.length < 3 ? <String>{} : _visits.skip(1).map((v) => v.$4.toSet()).reduce((a, b) => a.intersection(b));
    for (final (name, errors, spin, ts, notices) in _visits) {
      final body = ts.where((t) => !shell.contains(t)).length;
      final problems = [
        if (errors.isNotEmpty) 'exception: ${errors.first}',
        if (spin > 0) '$spin spinner(s) after the wait',
        if (body < 2) 'blank body ($body texts)',
        if (notices > 2) '$notices notices',
      ];
      record('screen $name', problems.isEmpty, problems.isEmpty ? '$body texts, $notices notices' : problems.join('; '));
    }
    record('no Flutter exceptions during the run', _errors.isEmpty, _errors.take(4).join(' / '));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
