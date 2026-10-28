// SPDX-License-Identifier: Apache-2.0
// Linked devices as a tester had them (26.10.20), the phone's half: the real app on an emulator
// with the real LEPIC core on floonet, against the desktop app
// (integration_test/release_check/device_link_two_wallets_desk_test.dart) holding two wallets, the open one
// ("P7") restored from this phone's phrase. The desktop shows the device link and reopens its
// wallet while it waits; the phone matches only after that reopen. Then both lists, the desktop's
// switch to its other wallet and back, a send on each side (held on the other, then freed), and
// an unlink from each side. They meet through files in the app's external files folder
// (`<external>/dl/`), which the host copies to and from the desktop's sync folder with adb:
//
//   from the desktop: phrase.txt (deleted once read), to.txt, link.txt, link2.txt, desk-*
//   from the phone:   phone-*
//
// Screenshots go to `<external>/shots/`. Every check prints one `RC PASS|FAIL | step | evidence`
// line; nothing prints the phrase.
//
//   flutter test -d emulator-5556 --dart-define=WFE_DEV_NETWORKS=true integration_test/device_link_two_wallets_phone_test.dart
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

String bookOf(DeviceService s) => s.book.devices.map((d) => '"${d.name}" ${d.deviceId.substring(0, 8)} ${d.pairings.length} server(s)').join(', ');

/// Linked devices › Link a device with [file]'s code pasted, up to the pictures (sent back as
/// [sasFile]); the phone matches once [waitFor] (if any) arrived.
Future<void> linkFrom(WidgetTester tester, ProviderContainer c, String file, String sasFile, String shotPrefix, {String? waitFor}) async {
  await popAll(tester);
  await push(tester, const LinkedDevicesScreen());
  await tapF(tester, find.byKey(devicesLinkKey));
  await settle(tester, ms: 1000);
  final code = await take(tester, file, timeout: const Duration(minutes: 40));
  record('the desktop\'s link arrived ($file)', code.startsWith('epiccash://device-link/1/'), '${code.length} chars');
  await typeInto(tester, find.byKey(linkPasteFieldKey), code);
  await tapF(tester, find.byKey(linkPasteKey));
  await settle(tester, ms: 1500);
  final service = c.read(deviceServiceProvider)!;
  await pumpUntil(tester, () => service.link?.phase == LinkPhase.checking || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 3), what: 'the pictures');
  final sas = service.link!.sas.map((w) => w.name).join(' ');
  record('the phone shows the four pictures ($file)', service.link!.phase == LinkPhase.checking && service.link!.sas.length == 4, sas);
  await shot(tester, '$shotPrefix-link-pictures');
  await put(tester, sasFile, sas);
  if (waitFor != null) await take(tester, waitFor, timeout: const Duration(minutes: 5));
  await tapF(tester, find.byKey(linkMatchKey));
  await settle(tester, ms: 1000);
  await pumpUntil(tester, () => service.link?.phase == LinkPhase.done || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 5), what: 'the link');
  record('the phone linked the desktop ($file)', service.link?.phase == LinkPhase.done, bookOf(service));
  await shot(tester, '$shotPrefix-link-done');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone (two wallets): link with the desktop reopening, lists, sends, unlink', (tester) async {
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

    // ---- 1. The desktop's P7: restored from its phrase.
    final phrase = await take(tester, 'phrase.txt');
    await tester.runAsync(() => File('${_base.path}/dl/phrase.txt').delete());
    await waitText(tester, 'Restore from phrase', timeout: const Duration(minutes: 2));
    await tapText(tester, 'Restore from phrase');
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
    await shot(tester, 'q01-home');

    // ---- 2. The link; the phone matches after the desktop reopened its wallet.
    await pumpUntil(tester, () => c.read(deviceServiceProvider)?.loaded ?? false, what: 'the devices service');
    await linkFrom(tester, c, 'link.txt', 'phone-sas.txt', 'q02', waitFor: 'desk-reopened');
    final service = c.read(deviceServiceProvider)!;
    await put(tester, 'phone-linked', service.book.deviceName);

    // ---- 3. The phone's list.
    await popAll(tester);
    await push(tester, const LinkedDevicesScreen());
    await pumpUntil(tester, () => service.book.devices.isNotEmpty && service.book.devices.first.pairings.length == service.book.servers.length, timeout: const Duration(minutes: 2), what: 'every server');
    await settle(tester, ms: 1000);
    final desk = service.book.devices.first;
    final listed = find.byKey(deviceRowKey(desk.deviceId)).evaluate().isNotEmpty && hasText(desk.name);
    record('phone: Linked devices lists the desktop', listed && service.book.devices.length == 1, bookOf(service));
    await shot(tester, 'q03-phone-list-linked');
    await put(tester, 'phone-list', listed ? '"${desk.name}" ${desk.deviceId.substring(0, 8)}' : '');

    // ---- 4. The desktop switched to its other wallet and back: the phone still lists it.
    await take(tester, 'desk-switched', timeout: const Duration(minutes: 15));
    await settle(tester, ms: 6000);
    record('phone: still lists the desktop after its wallet switch', service.book.devices.any((d) => d.deviceId == desk.deviceId) && service.book.removedBy == null, bookOf(service));

    // ---- 5. The desktop sends: its coins are held here; it cancels: they are free.
    final deskSent = await take(tester, 'desk-sent', timeout: const Duration(minutes: 40));
    if (deskSent == 'skip') {
      record('sends skipped: the desktop had no spendable coins', false, '');
    } else {
      final heardAt = DateTime.now();
      await pumpUntil(tester, () => service.book.holds.any((h) => h.state.holds), timeout: const Duration(minutes: 5), what: 'the hold');
      final hold = service.book.holds.lastWhere((h) => h.state.holds);
      record('phone: the desktop\'s payment holds its coins here', c.read(sessionProvider)!.heldOutputs.containsAll(hold.commitments), '${hold.slateId} ${hold.amount} after ${DateTime.now().difference(heardAt).inSeconds} s');
      await popAll(tester);
      await push(tester, const LinkedDevicesScreen());
      await shot(tester, 'q04-phone-holds-desk-send');
      await put(tester, 'phone-held', hold.slateId);
      await take(tester, 'desk-cancelled');
      final told = DateTime.now();
      try {
        await pumpUntil(tester, () => !service.book.holds.any((h) => h.slateId == hold.slateId && h.state.holds), timeout: const Duration(minutes: 10), what: 'the release');
      } on TestFailure {
        // Recorded below; the unlink steps still run.
      }
      final after = service.book.holds.firstWhere((h) => h.slateId == hold.slateId);
      final freed = after.state == HoldState.released && c.read(sessionProvider)!.heldOutputs.isEmpty;
      record('phone: the desktop\'s cancel released the coins here', freed,
          '${after.state.name} ${after.ending?.name} after ${DateTime.now().difference(told).inSeconds} s; ${bookOf(service)}');
      await shot(tester, 'q04b-phone-after-desk-cancel');
      await put(tester, 'phone-released', freed ? '1' : 'no');

      // The phone sends to the same payee (it never answers), as Send does.
      final to = await take(tester, 'to.txt');
      final session = c.read(sessionProvider)!;
      final minConf = c.read(minimumConfirmationsProvider);
      final need = BigInt.from(110000000);
      var spendable = BigInt.zero;
      for (var i = 0; i < 40 && spendable < need; i++) {
        spendable = (await tester.runAsync(() => session.summary(refresh: true, minimumConfirmations: minConf)))!.spendable;
        if (spendable < need) await settle(tester, ms: 10000);
      }
      record('phone: spendable before its send', spendable >= need, '$spendable');
      TxEntry? tx;
      try {
        tx = await tester.runAsync(() async {
          await service.beforeSend();
          final t = await session.sendEpicbox(amount: BigInt.from(100000000), minimumConfirmations: minConf, address: to, message: 'two wallets link live (phone)');
          await service.announceNow();
          return t;
        });
      } on Object catch (e) {
        record('phone: sent 1 EPIC over Epicbox', false, e.runtimeType.toString());
      }
      final sent = tx;
      if (sent == null || sent.slateId == null || sent.id == null) {
        await put(tester, 'phone-sent', 'skip');
      } else {
        record('phone: sent 1 EPIC over Epicbox', true, sent.slateId!);
        await shot(tester, 'q05-phone-sent');
        await put(tester, 'phone-sent', sent.slateId!);
        await take(tester, 'desk-held');
        await tester.runAsync(() async {
          await session.cancelTransaction(txId: sent.id!);
          await service.announceNow();
        });
        final rows = (await tester.runAsync(() => session.transactions(refresh: false)))!;
        final row = rows.where((r) => r.slateId == sent.slateId).firstOrNull;
        record('phone: its send is cancelled', row?.kind == TxKind.sentCancelled || row?.status == TxStatus.cancelled, '${row?.kind.name} ${row?.status.name}');
        await put(tester, 'phone-cancelled', '1');
        await take(tester, 'desk-released');
      }
    }

    // ---- 6. The desktop removes the phone: the list drops it, with the notice.
    await take(tester, 'desk-removed', timeout: const Duration(minutes: 20));
    await pumpUntil(tester, () => service.book.devices.isEmpty && service.book.removedBy != null, timeout: const Duration(minutes: 3), what: 'the removal');
    await popAll(tester);
    await push(tester, const LinkedDevicesScreen());
    await settle(tester, ms: 1000);
    final notice = hasText('removed this device from the link');
    record('phone: the desktop\'s removal dropped it, with the notice', service.book.devices.isEmpty && notice, 'removed by ${service.book.removedBy}');
    await shot(tester, 'q06-phone-removed-by-desk');
    await put(tester, 'phone-saw-removed', service.book.devices.isEmpty && notice ? 'ok removed by ${service.book.removedBy}' : 'no: ${bookOf(service)}');

    // Linked again; then the phone removes the desktop.
    await linkFrom(tester, c, 'link2.txt', 'phone-sas2.txt', 'q07');
    await put(tester, 'phone-linked2', '1');
    await take(tester, 'desk-relinked');
    await popAll(tester);
    await push(tester, const LinkedDevicesScreen());
    await pumpUntil(tester, () => service.book.devices.isNotEmpty, what: 'the desktop again');
    await settle(tester, ms: 1000);
    final desk2 = service.book.devices.first;
    await shot(tester, 'q08-phone-relinked');
    await tapF(tester, find.byKey(deviceRowKey(desk2.deviceId)));
    await settle(tester, ms: 1000);
    await tapText(tester, RegExp(r'^Remove$'));
    await settle(tester, ms: 800);
    await tapText(tester, RegExp(r'^Remove$'), last: true);
    await pumpUntil(tester, () => service.book.devices.isEmpty, what: 'the removal');
    await settle(tester, ms: 1500);
    record('phone: removed the desktop', service.book.devices.isEmpty, bookOf(service));
    await shot(tester, 'q09-phone-removed-desk');
    await put(tester, 'phone-removed', '1');
    await take(tester, 'desk-done', timeout: const Duration(minutes: 10));
    record('phone: no failed check', _fails.isEmpty, _fails.join(', '));
    // The test's end uninstalls the app and its folder: the host takes the shots first.
    await put(tester, 'phone-done', '1');
    await take(tester, 'host-done', timeout: const Duration(minutes: 3));
    // ignore: avoid_print
    print('RC DONE phone');
  }, timeout: const Timeout(Duration(minutes: 110)));
}
