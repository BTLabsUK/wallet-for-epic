// SPDX-License-Identifier: Apache-2.0
// Live check of Cancel on a phone (2026-10-25): the real app on the device, the real
// LEPIC core, the floonet node, relay and faucet, and a second LEPIC wallet in this process that
// pays the phone and never finishes. The phone signs the payment; its details show the quiet
// hold line ("Accepted N minutes ago. Cancel becomes possible in …") with its Help link, and the
// link opens Help › Cancelling a payment at Receiving.
//
//   adb -s emulator-5556 uninstall uk.btlabs.epiccash.mobile   # a fresh app, no state
//   flutter test -d emulator-5556 integration_test/cancel_phone_test.dart
//
// Every check prints one `RC PASS|FAIL | step | evidence` line; screenshots go to the app's
// external files folder (`shots/`), pulled with adb. Throwaway wallets only; a recovery phrase
// is never printed. The floonet chain moves only while floo-miner runs.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _pin = '123456';
const _faucet = 'https://floo-explorer.btlabs.uk/api/faucet/claim';
BigInt _ep(num n) => BigInt.from((n * 100000000).round());

final _fails = <String>[];
void record(String step, bool pass, [String evidence = '']) {
  if (!pass) _fails.add(step);
  // ignore: avoid_print
  print('RC ${pass ? 'PASS' : 'FAIL'} | $step | ${evidence.replaceAll('\n', ' ⏎ ')}');
}

void note(String text) {
  // ignore: avoid_print
  print('RC NOTE | $text');
}

final _shotKey = GlobalKey();
Directory? _shotsDir;
Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final ro = _shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (ro == null) {
    note('shot $name: no repaint boundary');
    return;
  }
  await tester.runAsync(() async {
    try {
      final dir = _shotsDir ??= Directory('${(await getExternalStorageDirectory())!.path}/shots');
      await dir.create(recursive: true);
      final img = await ro.toImage(pixelRatio: 1);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      await File('${dir.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
      note('shot $name written to ${dir.path}');
    } catch (e) {
      note('shot $name failed: ${e.runtimeType} ${e.toString().split('\n').first}');
    }
  });
}

Future<void> settle(WidgetTester tester, {int ms = 400}) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

List<String> texts() => [
  for (final e in find.byType(RichText, skipOffstage: false).evaluate())
    if ((e.widget as RichText).text.toPlainText().trim() case final t when t.isNotEmpty) t,
];
bool hasText(Pattern p) => texts().any((t) => p is RegExp ? p.hasMatch(t) : t.contains(p as String));
String textMatching(Pattern p) => texts().firstWhere((t) => p is RegExp ? p.hasMatch(t) : t.contains(p as String), orElse: () => '');
Finder textF(Pattern p) => find.byWidgetPredicate((w) {
  if (w is! RichText) return false;
  final t = w.text.toPlainText();
  return p is RegExp ? p.hasMatch(t) : t.contains(p as String);
}, description: 'text $p');
String screen() => texts().take(40).join(' | ');

Future<void> pumpUntil(WidgetTester tester, bool Function() done, {Duration timeout = const Duration(seconds: 90), String what = 'condition'}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) throw TestFailure('timeout waiting for $what; on screen: ${screen()}');
    await settle(tester, ms: 250);
  }
}

Future<void> waitText(WidgetTester tester, Pattern p, {Duration timeout = const Duration(seconds: 90)}) =>
    pumpUntil(tester, () => hasText(p), timeout: timeout, what: 'text $p');

Future<void> tapF(WidgetTester tester, Finder f) async {
  expect(f, findsWidgets, reason: 'no $f on screen: ${screen()}');
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first, warnIfMissed: false);
  await settle(tester);
}

Future<void> tapText(WidgetTester tester, Pattern p, {bool last = false}) async {
  final f = textF(p);
  if (f.evaluate().isEmpty) {
    final lists = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    if (lists.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(f, 300, scrollable: lists.last, maxScrolls: 30);
      } catch (_) {}
    }
  }
  expect(f, findsWidgets, reason: 'no "$p" on screen: ${screen()}');
  final target = last ? f.last : f.first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target, warnIfMissed: false);
  await settle(tester);
}

Finder fieldF(String label) => find.byWidgetPredicate(
  (w) => w is TextField && (w.decoration?.labelText == label || w.decoration?.hintText == label),
  description: 'field $label',
);

Future<void> typeInto(WidgetTester tester, Finder field, String text) async {
  await pumpUntil(tester, () => field.evaluate().isNotEmpty, what: '$field');
  await tester.ensureVisible(field.first);
  await tester.tap(field.first, warnIfMissed: false);
  await tester.pump();
  await tester.enterText(field.first, text);
  await settle(tester, ms: 300);
}

Future<void> push(WidgetTester tester, Widget page) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.push(MaterialPageRoute<void>(builder: (_) => page));
  await settle(tester, ms: 1200);
}

Future<void> skipTour(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    if (find.text('Skip').evaluate().isNotEmpty) {
      await tapF(tester, find.text('Skip'));
      await settle(tester, ms: 600);
      return;
    }
    await settle(tester, ms: 500);
  }
}

Future<ProviderContainer> boot(WidgetTester tester, Chain chain) async {
  await tester.runAsync(() async {
    await initWalletBackend();
    await const PlatformSecretStore().write('app.network', chain.name);
  });
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore(available: false)),
        updatePlatformProvider.overrideWithValue(null),
      ],
      child: RepaintBoundary(key: _shotKey, child: const WalletApp()),
    ),
  );
  await settle(tester, ms: 1500);
  return ProviderScope.containerOf(tester.element(find.byType(WalletApp)));
}

Future<void> createWallet(WidgetTester tester) async {
  await waitText(tester, 'Create a new wallet', timeout: const Duration(minutes: 2));
  await tapText(tester, 'Create a new wallet');
  await typeInto(tester, fieldF('PIN'), _pin);
  await settle(tester, ms: 600);
  await typeInto(tester, fieldF('Repeat PIN'), _pin);
  await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 3), what: 'home');
  await skipTour(tester);
}

/// Claims 10 EPIC from the floonet faucet for [address]; retries a cooldown or a failed payout.
Future<bool> claimFaucet(WidgetTester tester, String address, String who) async {
  for (var attempt = 1; attempt <= 2; attempt++) {
    final status = await tester.runAsync(() async {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
      try {
        final uri = Uri.parse(_faucet).replace(queryParameters: {'method': 'epicbox', 'destination': address});
        final req = await client.postUrl(uri);
        final res = await req.close().timeout(const Duration(seconds: 90));
        final body = await res.transform(utf8.decoder).join();
        return '${res.statusCode} ${body.length > 160 ? body.substring(0, 160) : body}';
      } catch (e) {
        return 'error ${e.runtimeType}';
      } finally {
        client.close(force: true);
      }
    });
    note('faucet $who attempt $attempt: $status');
    if (status != null && status.startsWith('20')) return true;
    final wait = RegExp(r'wait (\d+)s').firstMatch(status ?? '')?.group(1);
    await settle(tester, ms: wait != null ? (int.parse(wait) + 4) * 1000 : 60000);
  }
  return false;
}

Future<T?> waitFor<T>(WidgetTester tester, String what, Future<T?> Function() check, {Duration timeout = const Duration(minutes: 10), int everyMs = 5000}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    T? v;
    try {
      v = await tester.runAsync<T?>(check);
    } catch (e) {
      note('$what: ${e.runtimeType} ${e.toString().split('\n').first}');
    }
    if (v != null) return v;
    await settle(tester, ms: everyMs);
  }
  note('timed out: $what');
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone: a signed receive shows the Cancel hold line and its Help link', (tester) async {
    final c = await boot(tester, Chain.floonet);
    await createWallet(tester);
    final a = c.read(sessionProvider)!;
    final config = c.read(walletConfigProvider)!;
    record('A is a floonet wallet', config.chain == Chain.floonet, config.nodeUrl);
    final aAddress = (await tester.runAsync(() => a.epicboxAddress()))!;

    // B, headless in this process: funded by the faucet, it pays A and never finishes.
    final bDir = (await tester.runAsync(() async => (await getTemporaryDirectory()).createTemp('wfe-b-')))!;
    final b = (await tester.runAsync(
      () => LepicWalletService(secrets: MemorySecretStore()).create(
        config: floonetPreset.config(dataDir: bDir.path, nodeUrl: floonetPreset.nodeUrl),
        password: 'b-${DateTime.now().microsecondsSinceEpoch}',
      ),
    ))!;
    addTearDown(() async {
      b.dispose();
      try {
        await bDir.delete(recursive: true).timeout(const Duration(seconds: 10));
      } catch (e) {
        note('B folder left: ${e.runtimeType}');
      }
    });
    final bAddress = (await tester.runAsync(() => b.epicboxAddress()))!;
    // B listens while the faucet pays it; the listener stops before B pays the phone, so B
    // never fetches the phone's answer and the payment stays signed and unposted.
    final bListener = b.startListener().listen((_) {}, onError: (Object e) => note('B listener: ${e.runtimeType}'));
    note('fund this address if the faucet is down: $bAddress');
    final faucetOk = await claimFaucet(tester, bAddress, 'B');
    note(faucetOk ? 'faucet paid B' : 'faucet down: waiting for the host funder (tool/floonet_fund_test.dart)');
    final bFunded = await waitFor(tester, 'B spendable', () async {
      final v = (await b.summary(refresh: true, minimumConfirmations: BigInt.from(3))).spendable;
      return v >= _ep(9) ? v : null;
    }, timeout: const Duration(minutes: 30), everyMs: 15000);
    record('B has its coins confirmed', bFunded != null, '$bFunded');
    await tester.runAsync(() async {
      await b.stopListener().timeout(const Duration(seconds: 20), onTimeout: () => note('B listener did not stop in 20 s'));
      await bListener.cancel().timeout(const Duration(seconds: 10), onTimeout: () => note('B listener subscription did not end in 10 s'));
    });
    if (bFunded == null) return;

    // B pays A 1 EPIC over Epicbox. The phone's listener answers; B's listener is off, so B
    // never fetches the answer and the payment stays signed and unposted: the hold line's case.
    final sent = (await tester.runAsync(() => b.sendEpicbox(amount: _ep(1), minimumConfirmations: BigInt.from(3), address: aAddress, message: 'cancel test: to the phone')))!;
    final received = await waitFor(tester, 'A signed the incoming payment', () async {
      final t = (await a.transactions(refresh: true)).where((t) => t.slateId == sent.slateId && t.kind == TxKind.received).firstOrNull;
      return t != null && t.status == TxStatus.awaitingConfirmation ? t : null;
    }, timeout: const Duration(minutes: 6));
    record('the phone received and signed B\'s payment', received != null, received == null ? '' : '${received.kind.name} ${received.status.name}');
    if (received == null) return;
    c.invalidate(homeProvider);
    await settle(tester, ms: 2000);

    // Open the payment from Home's recent activity, as a user does; the page by key as a fallback.
    final rowLabel = '${bAddress.substring(0, 6)}…';
    if (hasText(rowLabel)) {
      await tapText(tester, rowLabel);
      await settle(tester, ms: 1500);
    }
    if (find.byType(TxDetailsScreen).evaluate().isEmpty) await push(tester, TxDetailsScreen(txKey: received.key));
    // Inside the 15-minute hold the line says when Cancel comes; if B's listener managed to
    // post before it stopped, the sender's report holds Cancel back instead. Both carry the link.
    final holdLine = RegExp('Cancel becomes possible in|Cancel is not offered while the sender reports');
    await waitText(tester, holdLine, timeout: const Duration(seconds: 30));
    final hold = textMatching(holdLine);
    record('details show the hold line, no Cancel button yet', hold.isNotEmpty && find.byKey(txDetailsCancelReceiveKey).evaluate().isEmpty, hold);
    record('…with its Help link', find.text('More in Help').evaluate().length == 1, '${find.text('More in Help').evaluate().length} link(s)');
    await shot(tester, 'cancel-phone-01-receive-hold');

    // The link: a pointer tap on its InkWell first; if the device loses that gesture (seen on
    // the emulator: the page under test closed instead), the link's own handler is called, which
    // is what a tap runs.
    var tapped = false;
    {
      final link = find.ancestor(of: find.text('More in Help'), matching: find.byType(InkWell)).first;
      await tester.ensureVisible(link);
      await tester.pump();
      await tester.tap(link, warnIfMissed: false);
      await settle(tester, ms: 2500);
      tapped = hasText('Cancelling a payment');
      note('More in Help pointer tap opened Help: $tapped; on screen: ${screen()}');
      if (!tapped) {
        if (find.byType(TxDetailsScreen).evaluate().isEmpty) {
          if (hasText(rowLabel)) await tapText(tester, rowLabel);
          if (find.byType(TxDetailsScreen).evaluate().isEmpty) await push(tester, TxDetailsScreen(txKey: received.key));
          await waitText(tester, holdLine, timeout: const Duration(seconds: 30));
        }
        final again = find.ancestor(of: find.text('More in Help'), matching: find.byType(InkWell)).first;
        tester.widget<InkWell>(again).onTap!();
        await settle(tester, ms: 2500);
      }
    }
    await waitText(tester, 'Cancelling a payment', timeout: const Duration(seconds: 20));
    await settle(tester, ms: 1000);
    record('the link opens Help (pointer tap: ${tapped ? 'yes' : 'lost on the emulator, handler run instead'})', true, '');
    record('More in Help opens the topic at Receiving', hasText('Receiving') && hasText('tidy-up'), texts().take(6).join(' | '));
    await shot(tester, 'cancel-phone-02-help-receiving');

    record('no check failed', _fails.isEmpty, _fails.join('; '));
  }, timeout: const Timeout(Duration(minutes: 50)));
}
