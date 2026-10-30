// SPDX-License-Identifier: Apache-2.0
// Phone network-mode proof: the real app on an emulator WITH its network, started with
// settings.toml naming Kill switch. The host script (tool/offline_phone.sh with
// OFFLINE_KILL_PROOF=1) counts every packet the app's uid sends (iptables owner match, DNS
// included: Android's resolver sends on the asking app's uid); that count is the proof. This
// test makes the app do what reaches out: start in the mode, create a wallet with the PIN, visit
// the three tabs, call the app's own requests the way their screens do, and sit on Home while
// its timers run.
//
// Throwaway wallet, PIN 123456; the recovery phrase is never shown or printed.
@Tags(['release-check'])
library;

import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show hostSettings;
import 'package:epic_wallet/src/settings_file/settings_platform_io.dart' show settingsFolder;
import 'package:epic_wallet/src/settings_file/settings_providers.dart' show openAppSettings;
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _pin = '123456';
const _idle = int.fromEnvironment('NET_IDLE_S', defaultValue: 90);

void record(String step, bool pass, [String evidence = '']) =>
    // ignore: avoid_print
    print('RC ${pass ? 'PASS' : 'FAIL'} | $step | ${evidence.replaceAll('\n', ' ⏎ ')}');

Future<void> settle(WidgetTester tester, {int ms = 400}) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

List<String> texts() => [
  for (final e in find.byType(RichText).evaluate())
    if ((e.widget as RichText).text.toPlainText().trim() case final t when t.isNotEmpty) t,
];

Future<void> pumpUntil(WidgetTester tester, bool Function() done, {Duration timeout = const Duration(seconds: 90), String what = ''}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) throw TestFailure('timeout waiting for $what');
    await settle(tester, ms: 250);
  }
}

Future<void> tapText(WidgetTester tester, String t) async {
  final f = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(t));
  expect(f, findsWidgets, reason: 'no "$t"');
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('phone: Kill switch from the first start, network on', (tester) async {
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d.exceptionAsString().split('\n').first);
      prev?.call(d);
    };
    // The saved mode, before the settings file is opened (main.dart's order).
    await tester.runAsync(() async {
      final f = File('${(await settingsFolder()).path}/settings.toml');
      await f.parent.create(recursive: true);
      await f.writeAsString('[network]\nmode = "kill_switch"\n');
      await initWalletBackend();
      await openAppSettings(store: createSecretStore());
    });
    record('the app starts in the saved mode', NetGate.killSwitch, 'gate ${NetGate.mode.name}');
    await tester.pumpWidget(ProviderScope(
      retry: (_, _) => null,
      overrides: [updatePlatformProvider.overrideWithValue(null)],
      child: const WalletApp(),
    ));
    await settle(tester, ms: 1500);
    final c = ProviderScope.containerOf(tester.element(find.byType(WalletApp)));
    await pumpUntil(tester, () => texts().any((t) => t.contains('Create a new wallet')), timeout: const Duration(minutes: 2), what: 'Welcome');
    await tapText(tester, 'Create a new wallet');
    await typeInto(tester, fieldF('PIN'), _pin);
    await settle(tester, ms: 600);
    await typeInto(tester, fieldF('Repeat PIN'), _pin);
    await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 3), what: 'home');
    record('the wallet opens to Home', true);
    for (var i = 0; i < 6 && find.text('Skip').evaluate().isEmpty; i++) {
      await settle(tester, ms: 500);
    }
    if (find.text('Skip').evaluate().isNotEmpty) await tester.tap(find.text('Skip').first);
    await settle(tester, ms: 800);
    for (final tab in ShellTab.values) {
      c.read(shellTabProvider.notifier).go(tab);
      await settle(tester, ms: 1500);
    }

    // The app's own requests, as their screens make them: each refused.
    final cfg = hostSettings.config;
    for (final e in {
      'status directory': cfg.statusDirectory,
      'price': cfg.statusPrice,
      'reach/IP': cfg.statusIp,
      'update downloads': cfg.updateDownloads,
      'problem report': cfg.supportReport,
    }.entries) {
      if (e.value == null) continue;
      final r = await tester.runAsync(() async {
        try {
          final reply = await httpGet(Uri.parse(e.value!), timeout: const Duration(seconds: 15));
          return 'answered ${reply.status}';
        } on Object catch (x) {
          return 'refused ${x.runtimeType}';
        }
      });
      record('${e.key}: $r', r != null && !r.startsWith('answered'));
    }

    final end = DateTime.now().add(const Duration(seconds: _idle));
    while (DateTime.now().isBefore(end)) {
      await settle(tester, ms: 2000);
    }
    record('still Kill switch at the end', NetGate.killSwitch, NetGate.mode.name);
    record('no uncaught errors', errors.isEmpty, errors.take(3).join(' | '));
  });
}
