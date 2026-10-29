// SPDX-License-Identifier: Apache-2.0
// Linked devices as a tester had them (26.10.20): the desktop holds two wallets, "Desktop" (its
// own phrase) and "P7" (the phone's phrase), P7 open; the desktop shows the device link, the phone
// (integration_test/device_link_two_wallets_phone_test.dart on an emulator) pastes it, and while the
// desktop waits the wallet reopens as in the field (an Epicbox change, before and after its own
// match). Both lists must show the other device, also after a switch to "Desktop" and back; a
// send on each side holds the coins on the other; unlink from each side.
//
//   RC_PHRASE_FILE  P7's phrase (a throwaway floonet wallet, mode 600)
//   RC_SYNC         the sync folder: this test writes p7-addr, to.txt, link.txt, desk-* and reads
//                   phone-*; the host copies them to and from the phone with adb and funds p7-addr
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
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';
import '../live_hosts.dart';

final String syncDir = Platform.environment['RC_SYNC'] ?? 'build/rc_sync';
const homeRelay = liveFlooRelay;
const otherRelay = liveRelay;
/// RC_REOPEN: unset, the wallet reopens while the link is under way; `after`, only once the
/// link is made (with the 5 s reads running); `both`, both.
final String reopenMode = Platform.environment['RC_REOPEN'] ?? 'during';
final bool reopenDuringLink = reopenMode != 'after';
final bool reopenAfterLink = reopenMode == 'after' || reopenMode == 'both';

int epic(num n) => (n * 100000000).round();
String fmt(int nano) => (nano / 100000000).toStringAsFixed(4);

DeskWalletApi apiOf(WidgetTester tester) => containerOf(tester).read(deskApiProvider);
DeskController deskOf(WidgetTester tester) => containerOf(tester).read(deskProvider.notifier);
DeviceService? serviceOf(WidgetTester tester) => containerOf(tester).read(deskDeviceServiceProvider);
Future<T> io<T>(WidgetTester tester, Future<T> Function() f) async => (await tester.runAsync(f)) as T;

void note(String text) {
  // ignore: avoid_print
  print('RC NOTE | $text');
}

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

String bookOf(DeviceService? s) =>
    s == null ? 'no service' : s.book.devices.map((d) => '"${d.name}" ${d.deviceId.substring(0, 8)} ${d.pairings.keys.length} server(s)').join(', ');

/// After an unlock (Setup skipped, the tour skipped): the overview.
Future<void> landed(WidgetTester tester, String password) async {
  await waitText(tester, RegExp('Skip setup|Unlock wallet|Available to spend|Skip tour'), timeout: const Duration(minutes: 4));
  if (hasText('Skip setup')) {
    await tapText(tester, 'Skip setup');
    await waitText(tester, RegExp('Unlock wallet|Available to spend|Skip tour'), timeout: const Duration(seconds: 120));
  }
  if (hasText('Unlock wallet')) {
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
  }
  await waitText(tester, RegExp('Available to spend|Skip tour'), timeout: const Duration(minutes: 3));
  await settle(tester, ms: 2000);
  if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
}

/// The wallet switch as Unlock does it: lock, the other wallet chosen, its password, the lists.
Future<void> switchTo(WidgetTester tester, String id, String password) async {
  final desk = deskOf(tester);
  await io(tester, desk.lock);
  await settle(tester, ms: 800);
  final api = apiOf(tester);
  await io(tester, () => api.selectWallet(id));
  final ok = await io(tester, () => api.unlock(password));
  if (!ok) throw TestFailure('the password did not open $id');
  await io(tester, desk.refresh);
  await io(tester, () => desk.startLive(listen: true));
  containerOf(tester).read(deskNavProvider.notifier).reset(DeskRoute.overview);
  await settle(tester, ms: 3000);
}

/// One device link from the desktop's side, up to the pictures; returns the code's service.
Future<DeviceService> showLink(WidgetTester tester, String file, String shotPrefix) async {
  await go(tester, DeskRoute.settingsDevices);
  await tester.ensureVisible(find.byKey(devices.devicesLinkKey));
  await tester.tap(find.byKey(devices.devicesLinkKey));
  await settle(tester, ms: 2500);
  final service = serviceOf(tester)!;
  await pumpUntil(tester, () => service.link?.code != null || service.link?.phase == LinkPhase.failed, timeout: const Duration(seconds: 60), what: 'the code');
  final code = service.link?.code ?? '';
  record('desktop: shows a device link on ${service.link?.servers.join(' + ')} ($file)', code.startsWith('epiccash://device-link/1/') && find.byKey(deskLinkCodeKey).evaluate().isNotEmpty, '${code.length} chars');
  await settle(tester, ms: 800);
  await shot(tester, '$shotPrefix-link-code');
  await put(tester, file, code);
  await pumpUntil(tester, () => service.link?.phase == LinkPhase.checking || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 20), what: 'the pictures');
  await settle(tester, ms: 800);
  await shot(tester, '$shotPrefix-link-pictures');
  return service;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop (two wallets): two wallets, link with a reopen, lists, switch, sends, unlink', (tester) async {
    captureErrors();
    final phrase = File(Platform.environment['RC_PHRASE_FILE']!).readAsStringSync().trim();
    final password = randomPassword();
    await tester.runAsync(() => Directory(syncDir).create(recursive: true));
    await boot(tester, size: const Size(1400, 950));

    // ---- 1. "Desktop": a new wallet on floonet.
    await settle(tester, ms: 6000);
    await io(tester, () => apiOf(tester).useNetwork('floonet'));
    containerOf(tester).read(onbFlowProvider.notifier).setNetwork('floonet');
    await settle(tester, ms: 800);
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, RegExp('[Ww]ritten down'));
    await tapText(tester, 'Continue', last: true);
    await landed(tester, password);
    final desktopId = containerOf(tester).read(deskProvider).account!.id!;
    await io(tester, () => deskOf(tester).renameWallet(desktopId, 'Desktop'));
    // Its address is the payee that never answers: "Desktop" stays closed while the sends run.
    final to = await io(tester, () => apiOf(tester).epicboxAddress());
    record('desktop: wallet "Desktop" created on floonet', apiOf(tester).network == 'floonet' && to.isNotEmpty, '${apiOf(tester).network} ${to.substring(to.indexOf('@'))}');
    await put(tester, 'to.txt', to);
    await shot(tester, 's01-desktop-wallet');

    // "P7": added, restored from the phone's phrase, then open.
    await io(tester, deskOf(tester).lock);
    await settle(tester, ms: 800);
    containerOf(tester).read(onbFlowProvider.notifier).setNetwork('floonet');
    containerOf(tester).read(deskNavProvider.notifier).reset(DeskRoute.welcome, 'add');
    await settle(tester, ms: 1500);
    await tapText(tester, 'Restore from phrase');
    await typeIn(tester, 0, phrase);
    await settle(tester, ms: 1500);
    await tapText(tester, 'Continue', last: true);
    await settle(tester);
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Restore wallet', last: true);
    await landed(tester, password);
    final end = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(end)) {
      await settle(tester, ms: 1500);
      if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
      if (hasText('Bring back history and settings?')) {
        await tapText(tester, 'Not now', last: true);
        break;
      }
    }
    final p7Id = containerOf(tester).read(deskProvider).account!.id!;
    await io(tester, () => deskOf(tester).renameWallet(p7Id, 'P7'));
    // The funder pays over BT Labs' relay: P7 starts there.
    if (!(await io(tester, () => apiOf(tester).epicboxAddress())).endsWith('@$homeRelay')) {
      await io(tester, () => deskOf(tester).useEpicbox(homeRelay));
      await io(tester, deskOf(tester).refresh);
    }
    final p7Addr = await io(tester, () => apiOf(tester).epicboxAddress());
    final wallets = await io(tester, () => deskOf(tester).loadWallets());
    record('desktop: two wallets, P7 restored and open', wallets.length == 2 && containerOf(tester).read(deskProvider).account?.id == p7Id && p7Id != desktopId,
        '${wallets.map((w) => w.name).join(' + ')}; open ${containerOf(tester).read(deskProvider).account?.name}');
    await put(tester, 'p7-addr', p7Addr);
    await shot(tester, 's02-p7-open');

    // ---- 2. The link, with the wallet reopening while the desktop waits.
    await pumpUntil(tester, () => serviceOf(tester)?.loaded ?? false, what: 'the devices service');
    final service = await showLink(tester, 'link.txt', 's03');
    final mine = service.link!.sas.map((w) => w.name).join(' ');
    final theirs = await take(tester, 'phone-sas.txt');
    record('desktop and phone show the same four pictures', mine == theirs && service.link!.sas.length == 4, mine);
    if (reopenDuringLink) {
      // A reopen before the desktop's match: an Epicbox change, as Settings › Epicbox does.
      final rev0 = apiOf(tester).sessionRevision;
      await io(tester, () => deskOf(tester).useEpicbox(otherRelay));
      await io(tester, deskOf(tester).refresh);
      await settle(tester, ms: 2000);
      final rev1 = apiOf(tester).sessionRevision;
      record('desktop: the wallet reopened before its match (Epicbox → $otherRelay)', rev1 > rev0 && (await io(tester, () => apiOf(tester).epicboxAddress())).endsWith('@$otherRelay'),
          'session $rev0 → $rev1');
      record('desktop: the same devices service after the reopen', identical(serviceOf(tester), service), '');
      record('desktop: the link still waits on the pictures after the reopen', service.link?.phase == LinkPhase.checking,
          'phase ${service.link?.phase.name} ${service.link?.failure?.name ?? ''}; supported ${service.supported}');
      await shot(tester, 's04-after-reopen-1');
      if (service.link?.phase != LinkPhase.checking) throw TestFailure('the reopen ended the link: ${service.link?.phase.name} ${service.link?.failure?.name}');
      await tester.tap(find.byKey(deskLinkMatchKey));
      await settle(tester, ms: 1500);
      // A second reopen after the desktop's match, before the phone's: back to BT Labs' relay.
      await io(tester, () => deskOf(tester).useEpicbox(homeRelay));
      await io(tester, deskOf(tester).refresh);
      await settle(tester, ms: 2000);
      final rev2 = apiOf(tester).sessionRevision;
      record('desktop: the wallet reopened after its match (Epicbox → $homeRelay)', rev2 > rev1, 'session $rev1 → $rev2; phase ${service.link?.phase.name}');
      record('desktop: still the same devices service', identical(serviceOf(tester), service), '');
    } else {
      await tester.tap(find.byKey(deskLinkMatchKey));
      await settle(tester, ms: 1500);
    }
    await put(tester, 'desk-reopened', '1');
    await shot(tester, 's05-matched-waiting');
    await pumpUntil(tester, () => service.link?.phase == LinkPhase.done || service.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 5), what: 'the link');
    record('desktop: linked the phone', service.link?.phase == LinkPhase.done, bookOf(service));
    await settle(tester, ms: 800);
    await shot(tester, 's06-link-done');
    if (find.byKey(deskLinkDoneKey).evaluate().isNotEmpty) await tester.tap(find.byKey(deskLinkDoneKey));
    await settle(tester, ms: 800);
    final phoneName = await take(tester, 'phone-linked');

    // ---- 3. Both lists.
    await pumpUntil(tester, () => service.book.devices.isNotEmpty && service.book.devices.first.pairings.length == service.book.servers.length,
        timeout: const Duration(minutes: 2), what: 'every server');
    await go(tester, DeskRoute.settingsDevices);
    await settle(tester, ms: 1500);
    final phone = service.book.devices.first;
    final rowKey = ValueKey('dev-${phone.deviceId}');
    record('desktop: Linked devices lists the phone', find.byKey(rowKey).evaluate().isNotEmpty && hasText(phone.name) && service.book.devices.length == 1,
        '${bookOf(service)}; phone calls itself "$phoneName"');
    record('desktop: the list is read from the service that finished the link', identical(serviceOf(tester), service) && identical(containerOf(tester).read(deskDeviceBookProvider), service.book), '');
    await shot(tester, 's07-desk-list-linked');
    final phoneSees = await take(tester, 'phone-list');
    record('the phone lists the desktop', phoneSees.isNotEmpty, phoneSees);

    // The wallet reopens with the phone linked (an Epicbox change each way, a few times, with
    // the 5 s reads running): the phone stays listed.
    if (reopenAfterLink) {
      for (var i = 0; i < 4; i++) {
        final relay = i.isEven ? otherRelay : homeRelay;
        final rev = apiOf(tester).sessionRevision;
        await io(tester, () => deskOf(tester).useEpicbox(relay));
        await io(tester, deskOf(tester).refresh);
        await settle(tester, ms: 8000);
        final now = serviceOf(tester);
        record('desktop: still lists the phone after reopen ${i + 1} (→ $relay)',
            identical(now, service) && service.book.device(phone.deviceId) != null && service.book.removedBy == null && find.byKey(rowKey).evaluate().isNotEmpty,
            'session $rev → ${apiOf(tester).sessionRevision}; ${bookOf(service)}; removedBy ${service.book.removedBy}');
        await shot(tester, 's07b-after-linked-reopen-${i + 1}');
      }
    }

    // ---- 4. The other wallet and back.
    await switchTo(tester, desktopId, password);
    await go(tester, DeskRoute.settingsDevices);
    await pumpUntil(tester, () => serviceOf(tester)?.loaded ?? false, what: 'the Desktop wallet\'s devices');
    record('desktop: wallet "Desktop" lists no devices', containerOf(tester).read(deskProvider).account?.id == desktopId && serviceOf(tester)!.book.devices.isEmpty && find.byKey(const ValueKey('dev-none')).evaluate().isNotEmpty,
        bookOf(serviceOf(tester)));
    record('desktop: the old service was let go on the switch', !identical(serviceOf(tester), service), '');
    await shot(tester, 's08-desktop-wallet-list');
    await switchTo(tester, p7Id, password);
    await go(tester, DeskRoute.settingsDevices);
    await pumpUntil(tester, () => serviceOf(tester)?.loaded ?? false, what: 'P7\'s devices');
    await settle(tester, ms: 3000);
    final back = serviceOf(tester)!;
    record('desktop: P7 still lists the phone after the switch', back.book.devices.any((d) => d.deviceId == phone.deviceId) && find.byKey(rowKey).evaluate().isNotEmpty, bookOf(back));
    await shot(tester, 's09-p7-list-after-switch');
    await put(tester, 'desk-switched', '1');

    // ---- 5. A send on each side. Coins need the funder's payment and 6 blocks.
    final api = apiOf(tester);
    var bal = await io(tester, api.balance);
    for (var i = 0; i < 180 && bal.spendable < epic(2); i++) {
      try {
        await tester.runAsync(api.syncNow);
      } on Object {
        // The next round asks again.
      }
      await settle(tester, ms: 10000);
      bal = await io(tester, api.balance);
    }
    final funded = bal.spendable >= epic(2);
    record('desktop: P7 has spendable coins', funded, fmt(bal.spendable));
    if (funded) {
      final sent = await io(tester, () => deskOf(tester).send(SendRequest(method: TxMethod.epicbox, amount: epic(1), to: to, message: 'two wallets link live')));
      final tx = sent is SendDone ? sent.tx : null;
      record('desktop: sent 1 EPIC over Epicbox', tx != null, sent.runtimeType.toString());
      if (tx != null) {
        await settle(tester, ms: 6000);
        await put(tester, 'desk-sent', '1');
        final held = await take(tester, 'phone-held');
        record('the phone holds the desktop\'s payment', held.isNotEmpty, held);
        await go(tester, DeskRoute.activity, tx.id);
        await tester.ensureVisible(find.widgetWithText(EButton, 'Cancel payment').first);
        await settle(tester, ms: 600);
        await tester.tap(find.widgetWithText(EButton, 'Cancel payment').first);
        await settle(tester, ms: 1200);
        await tapText(tester, 'Cancel payment', last: true);
        await waitText(tester, RegExp(r'^Cancelled\.?$'), timeout: const Duration(seconds: 60));
        await settle(tester, ms: 6000);
        final after = (await io(tester, api.transactions)).where((t) => t.id == tx.id).firstOrNull;
        record('desktop: the send is cancelled', after?.state == TxState.cancelled, '${after?.state.name}');
        // The other devices hear of the cancel from this device's book: its send ends there.
        final told = DateTime.now();
        await pumpUntil(tester, () => serviceOf(tester)?.book.announced[tx.slateId] == AnnouncedState.ended,
            timeout: const Duration(seconds: 90), what: 'the cancel announced').catchError((Object _) {});
        final announced = serviceOf(tester)?.book.announced[tx.slateId];
        record('desktop: told its devices the send ended', announced == AnnouncedState.ended,
            '${announced?.name} after ${DateTime.now().difference(told).inSeconds} s; outbox ${serviceOf(tester)?.book.outbox.length}');
        await put(tester, 'desk-cancelled', '1');
        final released = await take(tester, 'phone-released');
        record('the phone freed the coins', released == '1', released);
      }
      // The phone sends: the desktop holds.
      final phoneSent = await take(tester, 'phone-sent', timeout: const Duration(minutes: 15));
      if (phoneSent != 'skip') {
        final dev = serviceOf(tester)!;
        final sentAt = DateTime.now();
        try {
          await pumpUntil(tester, () => dev.book.holds.any((h) => h.slateId == phoneSent && h.state.holds), timeout: const Duration(minutes: 5), what: 'the hold');
        } on TestFailure {
          // Recorded below.
        }
        final hold = dev.book.holds.where((h) => h.slateId == phoneSent).firstOrNull;
        final outs = await io(tester, api.outputs);
        final heldHere = outs.where((o) => o.heldBy != null).length;
        record('desktop: holds the phone\'s payment', hold != null && hold.state.holds && heldHere > 0,
            '${hold?.amount} ${hold?.commitments.length} coin(s), $heldHere output(s) held, after ${DateTime.now().difference(sentAt).inSeconds} s');
        await go(tester, DeskRoute.settingsDevices);
        await shot(tester, 's10-desk-holds-phone-send');
        await put(tester, 'desk-held', '1');
        await take(tester, 'phone-cancelled');
        final cancelledAt = DateTime.now();
        try {
          await pumpUntil(tester, () => !dev.book.holds.any((h) => h.slateId == phoneSent && h.state.holds), timeout: const Duration(minutes: 10), what: 'the release');
        } on TestFailure {
          // Recorded below.
        }
        final freed = dev.book.holds.where((h) => h.slateId == phoneSent).firstOrNull;
        final outs2 = await io(tester, api.outputs);
        record('desktop: the phone\'s cancel freed the coins', freed?.state == HoldState.released && outs2.every((o) => o.heldBy == null),
            '${freed?.state.name} ${freed?.ending?.name} after ${DateTime.now().difference(cancelledAt).inSeconds} s');
        await put(tester, 'desk-released', '1');
      }
    } else {
      await put(tester, 'desk-sent', 'skip');
    }

    // ---- 6. Unlink from the desktop; link again; unlink from the phone.
    await go(tester, DeskRoute.settingsDevices);
    var dev = serviceOf(tester)!;
    final removeKey = ValueKey('dev-remove-${phone.deviceId}');
    await tester.ensureVisible(find.byKey(removeKey));
    await tester.tap(find.byKey(removeKey));
    await settle(tester, ms: 1000);
    await tester.tap(find.byKey(devices.devicesRemoveConfirmKey));
    await settle(tester, ms: 3000);
    await pumpUntil(tester, () => dev.book.devices.isEmpty, what: 'the removal');
    record('desktop: removed the phone', dev.book.devices.isEmpty && find.byKey(const ValueKey('dev-none')).evaluate().isNotEmpty, bookOf(dev));
    await shot(tester, 's11-desk-removed-phone');
    await put(tester, 'desk-removed', '1');
    final phoneAfter = await take(tester, 'phone-saw-removed');
    record('the phone dropped the desktop and says who removed it', phoneAfter.startsWith('ok'), phoneAfter);

    dev = await showLink(tester, 'link2.txt', 's12');
    final mine2 = dev.link!.sas.map((w) => w.name).join(' ');
    final theirs2 = await take(tester, 'phone-sas2.txt');
    record('second link: the same four pictures', mine2 == theirs2, mine2);
    await tester.tap(find.byKey(deskLinkMatchKey));
    await settle(tester, ms: 1000);
    await pumpUntil(tester, () => dev.link?.phase == LinkPhase.done || dev.link?.phase == LinkPhase.failed, timeout: const Duration(minutes: 5), what: 'the second link');
    record('desktop: linked the phone again', dev.link?.phase == LinkPhase.done, bookOf(dev));
    if (find.byKey(deskLinkDoneKey).evaluate().isNotEmpty) await tester.tap(find.byKey(deskLinkDoneKey));
    await settle(tester, ms: 800);
    await take(tester, 'phone-linked2');
    await go(tester, DeskRoute.settingsDevices);
    await shot(tester, 's13-desk-relinked');
    await put(tester, 'desk-relinked', '1');
    await take(tester, 'phone-removed');
    await pumpUntil(tester, () => dev.book.devices.isEmpty, timeout: const Duration(minutes: 3), what: 'the phone\'s removal');
    await go(tester, DeskRoute.settingsDevices);
    await settle(tester, ms: 1000);
    record('desktop: the phone\'s removal dropped it here', dev.book.devices.isEmpty && dev.book.removedBy != null && find.byKey(devices.devicesRemovedByKey).evaluate().isNotEmpty,
        'removed by ${dev.book.removedBy}');
    await shot(tester, 's14-desk-removed-by-phone');
    await put(tester, 'desk-done', '1');
    record('desktop: no Flutter exceptions', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
    note('desktop finished');
    // ignore: avoid_print
    print('RC DONE desktop');
  }, timeout: const Timeout(Duration(minutes: 110)));
}
