// Linked devices between the desktop app and the phone app (integration_test/device_link_phone_test.dart
// on an emulator), the same floonet wallet restored on both, real LEPIC, node and relays. The
// desktop shows the device link, the phone pastes it, both check the pictures; then the desktop
// sends to a wallet that never answers (RC_TO), the phone holds the coins, the desktop cancels
// and the phone frees them. The apps meet through files in RC_SYNC, which the host copies to and
// from the phone with adb.
//
//   RC_PHRASE_FILE  the wallet's phrase (a throwaway floonet wallet, mode 600)
//   RC_TO           the floonet Epicbox address the desktop pays (never answers)
//   RC_SYNC         the sync folder: this test writes link.txt, desk-sent, desk-cancelled and reads
//                   phone-sas.txt, phone-linked, phone-held, phone-released
//
// Run like the release checks (tool/release_check.sh pattern: xvfb, dbus, a throwaway keyring).
// Never prints the phrase or the password.
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/api.dart';
import 'package:epic_wallet/src/desktop/data/devices_state.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/devices/link_flow.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart' show onbFlowProvider;
import 'package:epic_wallet/src/desktop/screens/settings/settings_devices.dart' as devices;
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show EButton;
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

final String syncDir = Platform.environment['RC_SYNC'] ?? 'build/rc_sync';

int epic(num n) => (n * 100000000).round();
String fmt(int nano) => (nano / 100000000).toStringAsFixed(4);

DeskWalletApi apiOf(WidgetTester tester) => containerOf(tester).read(deskApiProvider);
Future<T> io<T>(WidgetTester tester, Future<T> Function() f) async => (await tester.runAsync(f)) as T;

Future<void> put(WidgetTester tester, String key, String value) => tester.runAsync(() async {
  final tmp = File('$syncDir/$key.tmp');
  await tmp.writeAsString(value);
  await tmp.rename('$syncDir/$key');
}).then((_) {});

Future<String> take(WidgetTester tester, String key, {Duration timeout = const Duration(minutes: 20)}) async {
  final f = File('$syncDir/$key');
  final end = DateTime.now().add(timeout);
  while (!(await tester.runAsync(f.exists))!) {
    if (DateTime.now().isAfter(end)) throw TestFailure('no $key from the phone');
    await settle(tester, ms: 1000);
  }
  return (await tester.runAsync(f.readAsString))!.trim();
}

Future<void> go(WidgetTester tester, DeskRoute r, [Object? arg]) async {
  if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
  final nav = containerOf(tester).read(deskNavProvider.notifier);
  nav.go(DeskRoute.overview);
  await settle(tester, ms: 300);
  nav.go(r, arg);
  await settle(tester, ms: 1500);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop: link to the phone, send, cancel', (tester) async {
    captureErrors();
    final phrase = File(Platform.environment['RC_PHRASE_FILE']!).readAsStringSync().trim();
    final to = Platform.environment['RC_TO']!;
    final password = randomPassword();
    await tester.runAsync(() => Directory(syncDir).create(recursive: true));
    await boot(tester, size: const Size(1400, 950));

    // Welcome on floonet, then the wallet restored from its phrase.
    await settle(tester, ms: 6000);
    await io(tester, () => apiOf(tester).useNetwork('floonet'));
    containerOf(tester).read(onbFlowProvider.notifier).setNetwork('floonet');
    await settle(tester, ms: 800);
    await tapText(tester, 'Restore from phrase');
    await typeIn(tester, 0, phrase);
    await settle(tester, ms: 1500);
    await tapText(tester, 'Continue', last: true);
    await settle(tester);
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Restore wallet', last: true);
    await waitText(tester, RegExp('Skip setup|Unlock wallet|Available to spend'), timeout: const Duration(minutes: 4));
    if (hasText('Skip setup')) {
      await tapText(tester, 'Skip setup');
      await waitText(tester, RegExp('Unlock wallet|Available to spend|Skip tour'), timeout: const Duration(seconds: 120));
    }
    if (hasText('Unlock wallet')) {
      await typeIn(tester, 0, password);
      await tapText(tester, 'Unlock', last: true);
    }
    await waitText(tester, 'Available to spend', timeout: const Duration(minutes: 3));
    // The end of the restore asks about wallet data, with the quiet offer to link a device.
    var offered = false;
    final end = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(end)) {
      await settle(tester, ms: 1500);
      if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
      if (hasText('Bring back history and settings?')) {
        offered = hasText('Using this wallet on another device too?');
        await shot(tester, 'd01a-restore-end-link-offer');
        await tapText(tester, 'Not now', last: true);
        break;
      }
    }
    record('desktop: the end of the restore offers to link a device', offered, '');
    final api = apiOf(tester);
    var bal = await io(tester, api.balance);
    for (var i = 0; i < 60 && bal.spendable < epic(2); i++) {
      await tester.runAsync(api.syncNow);
      await settle(tester, ms: 5000);
      bal = await io(tester, api.balance);
    }
    record('desktop: restored on floonet with coins', api.network == 'floonet' && bal.spendable >= epic(2), '${api.network} spendable ${fmt(bal.spendable)}');
    await shot(tester, 'd01-overview');

    // Settings › Linked devices › Link a device: the code, for the phone.
    await go(tester, DeskRoute.settingsDevices);
    await shot(tester, 'd02-linked-devices');
    await tester.ensureVisible(find.byKey(devices.devicesLinkKey));
    await tester.tap(find.byKey(devices.devicesLinkKey));
    await settle(tester, ms: 2500);
    final service = containerOf(tester).read(deskDeviceServiceProvider)!;
    await pumpUntil(tester, () => service.link?.code != null || service.link?.phase == LinkPhase.failed, timeout: const Duration(seconds: 60), what: 'the code');
    final code = service.link?.code ?? '';
    record('desktop: shows a device link on ${service.link?.servers.join(' + ')}', code.startsWith('epiccash://device-link/1/') && find.byKey(deskLinkCodeKey).evaluate().isNotEmpty, '${code.length} chars');
    await settle(tester, ms: 800);
    await shot(tester, 'd03-link-code');
    await put(tester, 'link.txt', code);

    // The phone answers: both show the same pictures, both match.
    await pumpUntil(tester, () => service.link?.phase == LinkPhase.checking || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 20), what: 'the pictures');
    final mine = service.link!.sas.map((w) => w.name).join(' ');
    await settle(tester, ms: 800);
    await shot(tester, 'd04-link-pictures');
    final theirs = await take(tester, 'phone-sas.txt');
    record('desktop and phone show the same four pictures', mine == theirs && service.link!.sas.length == 4, mine);
    await tester.tap(find.byKey(deskLinkMatchKey));
    await settle(tester, ms: 1000);
    await shot(tester, 'd05-link-matched-waiting');
    await pumpUntil(tester, () => service.link?.phase == LinkPhase.done || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 5), what: 'the link');
    record('desktop: linked the phone', service.link?.phase == LinkPhase.done, service.book.devices.map((d) => '${d.name} ${d.pairings.keys.join('+')}').join(', '));
    await settle(tester, ms: 800);
    await shot(tester, 'd06-link-done');
    if (find.byKey(deskLinkDoneKey).evaluate().isNotEmpty) await tester.tap(find.byKey(deskLinkDoneKey));
    await settle(tester, ms: 800);
    await take(tester, 'phone-linked');
    await pumpUntil(tester, () => service.book.devices.isNotEmpty && service.book.devices.first.pairings.length == service.book.servers.length, timeout: const Duration(minutes: 2), what: 'every server');
    await go(tester, DeskRoute.settingsDevices);
    await shot(tester, 'd07-linked-devices-one');

    // A send to a wallet that never answers: the phone holds its coins. Coins need 10 blocks.
    for (var i = 0; i < 90 && bal.spendable < epic(2); i++) {
      await tester.runAsync(api.syncNow);
      await settle(tester, ms: 10000);
      bal = await io(tester, api.balance);
    }
    record('desktop: spendable before the send', bal.spendable >= epic(2), fmt(bal.spendable));
    final sent = await io(tester, () => api.send(SendRequest(method: TxMethod.epicbox, amount: epic(1), to: to, message: 'device link live')));
    final tx = sent is SendDone ? sent.tx : null;
    record('desktop: sent 1 EPIC over Epicbox', tx != null, sent.runtimeType.toString());
    if (tx == null) return;
    await settle(tester, ms: 6000);
    await put(tester, 'desk-sent', '1');
    await go(tester, DeskRoute.activity, tx.id);
    await shot(tester, 'd08-send-waiting');
    final held = await take(tester, 'phone-held');
    record('the phone holds the desktop\'s payment', held.isNotEmpty, held);

    // Cancel, as a person does: the phone frees the coins.
    await go(tester, DeskRoute.activity, tx.id);
    await tester.ensureVisible(find.widgetWithText(EButton, 'Cancel payment').first);
    await settle(tester, ms: 600);
    await tester.tap(find.widgetWithText(EButton, 'Cancel payment').first);
    await settle(tester, ms: 1200);
    await shot(tester, 'd09-cancel-dialog');
    await tapText(tester, 'Cancel payment', last: true);
    await waitText(tester, RegExp(r'^Cancelled\.?$'), timeout: const Duration(seconds: 60));
    await settle(tester, ms: 6000);
    final after = (await io(tester, api.transactions)).where((t) => t.id == tx.id).firstOrNull;
    record('desktop: the send is cancelled', after?.state == TxState.cancelled, '${after?.state.name}');
    await shot(tester, 'd10-cancelled');
    await put(tester, 'desk-cancelled', '1');
    await take(tester, 'phone-released');
    record('the phone freed the coins', true, '');
    record('desktop: no Flutter exceptions', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
    // ignore: avoid_print
    print('RC DONE desktop');
  }, timeout: const Timeout(Duration(minutes: 50)));
}
