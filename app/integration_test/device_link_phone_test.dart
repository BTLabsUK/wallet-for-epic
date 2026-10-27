// Live check of linked devices on a phone: the real app on an emulator with the real LEPIC core
// on floonet, against the desktop app (integration_test/release_check/device_link_desk_test.dart)
// holding the same wallet. They meet through files in the app's external files folder
// (`<external>/dl/`), which the host copies to and from the desktop's sync folder with adb:
//
//   phrase.txt     the wallet's phrase (a throwaway floonet wallet), deleted once read
//   link.txt       the device link the desktop shows
//   desk-sent / desk-cancelled    the desktop sent a payment / cancelled it
//
// The phone writes phone-ready, phone-sas.txt, phone-linked, phone-held and phone-released.
// Screenshots go to `<external>/shots/`. Every check prints one `RC PASS|FAIL | step | evidence`
// line; nothing prints the phrase.
//
//   flutter test -d emulator-5556 integration_test/device_link_phone_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:epic_wallet/src/devices/phone_devices.dart';
import 'package:epic_wallet/src/models.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/devices/link_device_screen.dart';
import 'package:epic_wallet/src/ui/devices/linked_devices_screen.dart';
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

final _fails = <String>[];
void record(String step, bool pass, [String evidence = '']) {
  if (!pass) _fails.add(step);
  // ignore: avoid_print
  print('RC ${pass ? 'PASS' : 'FAIL'} | $step | ${evidence.replaceAll('\n', ' ⏎ ')}');
}

final _shotKey = GlobalKey();
late Directory _base;

Future<void> shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 300));
  final ro = _shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (ro == null) return;
  await tester.runAsync(() async {
    final dir = Directory('${_base.path}/shots');
    await dir.create(recursive: true);
    final img = await ro.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    await File('${dir.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
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

Future<void> popAll(WidgetTester tester) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.popUntil((r) => r.isFirst);
  await settle(tester, ms: 800);
}

/// Waits for the host to drop [name] into the folder; returns its text.
Future<String> take(WidgetTester tester, String name, {Duration timeout = const Duration(minutes: 20)}) async {
  final f = File('${_base.path}/dl/$name');
  final end = DateTime.now().add(timeout);
  while (!(await tester.runAsync(f.exists))!) {
    if (DateTime.now().isAfter(end)) throw TestFailure('no $name from the host');
    await settle(tester, ms: 1000);
  }
  return (await tester.runAsync(f.readAsString))!.trim();
}

Future<void> put(WidgetTester tester, String name, String value) => tester.runAsync(() async {
  final tmp = File('${_base.path}/dl/$name.tmp');
  await tmp.writeAsString(value);
  await tmp.rename('${_base.path}/dl/$name');
}).then((_) {});

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone: link to the desktop, hold and release its payment', (tester) async {
    _base = (await tester.runAsync(() async => (await getExternalStorageDirectory())!))!;
    await tester.runAsync(() => Directory('${_base.path}/dl').create(recursive: true));
    await tester.runAsync(() async {
      await initWalletBackend();
      await const PlatformSecretStore().write('app.network', Chain.floonet.name);
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
    final c = ProviderScope.containerOf(tester.element(find.byType(WalletApp)));
    await put(tester, 'phone-ready', '1');

    // The same wallet as the desktop: restored from its phrase.
    final phrase = await take(tester, 'phrase.txt');
    await tester.runAsync(() => File('${_base.path}/dl/phrase.txt').delete());
    await waitText(tester, 'Restore from a phrase', timeout: const Duration(minutes: 2));
    await tapText(tester, 'Restore from a phrase');
    await typeInto(tester, fieldF('Recovery phrase'), phrase);
    await tapText(tester, 'Continue', last: true);
    await typeInto(tester, fieldF('PIN'), _pin);
    await settle(tester, ms: 600);
    await typeInto(tester, fieldF('Repeat PIN'), _pin);
    await pumpUntil(tester, () => hasText('Not now') || find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 6), what: 'the restore to end');
    if (hasText('Not now')) await tapText(tester, 'Not now');
    await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 3), what: 'home');
    for (var i = 0; i < 6 && find.text('Skip').evaluate().isEmpty; i++) {
      await settle(tester, ms: 500);
    }
    if (find.text('Skip').evaluate().isNotEmpty) await tapF(tester, find.text('Skip'));
    await settle(tester, ms: 3000);
    final config = c.read(walletConfigProvider)!;
    record('the phone wallet is restored on floonet', config.chain == Chain.floonet, '${config.nodeUrl} ${config.epicboxDomain}');
    await shot(tester, 'p01-home');

    // Linked devices: the page, then Link a device with the desktop's code pasted.
    await pumpUntil(tester, () => c.read(deviceServiceProvider)?.loaded ?? false, what: 'the devices service');
    await push(tester, const LinkedDevicesScreen());
    await shot(tester, 'p02-linked-devices');
    await tapF(tester, find.byKey(devicesLinkKey));
    await settle(tester, ms: 1000);
    await shot(tester, 'p03-link-a-device');
    final code = await take(tester, 'link.txt');
    record('the desktop\'s link arrived', code.startsWith('epiccash://device-link/1/'), '${code.length} chars');
    await typeInto(tester, find.byKey(linkPasteFieldKey), code);
    await shot(tester, 'p04-link-pasted');
    await tapF(tester, find.byKey(linkPasteKey));
    await settle(tester, ms: 1500);
    await shot(tester, 'p05-link-waiting');
    final service = c.read(deviceServiceProvider)!;
    await pumpUntil(tester, () => service.link?.phase == LinkPhase.checking || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 3), what: 'the pictures');
    final sas = service.link!.sas.map((w) => w.name).join(' ');
    record('the phone shows the four pictures', service.link!.phase == LinkPhase.checking && service.link!.sas.length == 4, sas);
    await shot(tester, 'p06-link-pictures');
    await put(tester, 'phone-sas.txt', sas);
    await tapF(tester, find.byKey(linkMatchKey));
    await settle(tester, ms: 1000);
    await shot(tester, 'p07-link-matched-waiting');
    await pumpUntil(tester, () => service.link?.phase == LinkPhase.done || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 5), what: 'the link');
    record('the phone linked the desktop', service.link?.phase == LinkPhase.done, '${service.book.devices.map((d) => '${d.name} ${d.pairings.keys.join('+')}')}');
    await shot(tester, 'p08-link-done');
    await put(tester, 'phone-linked', '1');
    await popAll(tester);
    await push(tester, const LinkedDevicesScreen());
    await pumpUntil(tester, () => service.book.devices.isNotEmpty && service.book.devices.first.pairings.length == service.book.servers.length, timeout: const Duration(minutes: 2), what: 'every server');
    await settle(tester, ms: 1000);
    await shot(tester, 'p09-linked-devices-one');

    // The desktop sends: its coins are held here.
    await take(tester, 'desk-sent');
    await pumpUntil(tester, () => service.book.holds.any((h) => h.state.holds), timeout: const Duration(minutes: 3), what: 'the hold');
    final hold = service.book.holds.lastWhere((h) => h.state.holds);
    record('the desktop\'s payment holds its coins here', c.read(sessionProvider)!.heldOutputs.containsAll(hold.commitments), '${hold.slateId} ${hold.amount}');
    await settle(tester, ms: 1500);
    await shot(tester, 'p10-held-on-devices-page');
    await popAll(tester);
    c.read(shellTabProvider.notifier).go(ShellTab.wallet);
    await settle(tester, ms: 2500);
    record('the activity shows the desktop\'s payment', hasText(RegExp('Desktop')), texts().where((t) => t.contains('Desktop')).take(2).join(' / '));
    await shot(tester, 'p11-held-in-activity');
    c.read(shellTabProvider.notifier).go(ShellTab.send);
    await settle(tester, ms: 2500);
    await shot(tester, 'p12-held-on-send');
    await put(tester, 'phone-held', hold.slateId);

    // The desktop cancels: the coins are free again, the row says so.
    await take(tester, 'desk-cancelled');
    await pumpUntil(tester, () => !service.book.holds.any((h) => h.slateId == hold.slateId && h.state.holds), timeout: const Duration(minutes: 3), what: 'the release');
    final after = service.book.holds.firstWhere((h) => h.slateId == hold.slateId);
    record('the desktop\'s cancel released the coins here', after.state == HoldState.released && c.read(sessionProvider)!.heldOutputs.isEmpty, '${after.state.name} ${after.ending?.name}');
    c.read(shellTabProvider.notifier).go(ShellTab.wallet);
    await settle(tester, ms: 2500);
    await shot(tester, 'p13-released-in-activity');
    await push(tester, const LinkedDevicesScreen());
    await shot(tester, 'p14-released-devices-page');
    await put(tester, 'phone-released', '1');
    record('phone: no failed check', _fails.isEmpty, _fails.join(', '));
    // The test's end uninstalls the app and its folder: the host takes the shots first.
    await take(tester, 'host-done', timeout: const Duration(minutes: 3));
    // ignore: avoid_print
    print('RC DONE phone');
  }, timeout: const Timeout(Duration(minutes: 50)));
}
