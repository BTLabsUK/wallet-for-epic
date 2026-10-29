// SPDX-License-Identifier: Apache-2.0
// Desktop offline check: the real desktop wallet (real LEPIC) started with NO network at all,
// inside a network namespace that tool/offline_check.sh makes (loopback only). Creates a
// wallet, visits every screen and the flows that need no network, and records per screen:
// no Flutter exception, no spinner still turning after the wait, a body that is not blank,
// a sane number of notices. Then, when the runner offers it (OFFLINE_NET_DIR), it asks for
// the network back (the runner plugs a cable into the namespace) and checks the app recovers
// by itself, without a restart.
//
//   app/tool/offline_check.sh            # offline, then the network comes back
//   OFFLINE_MODE=drop app/tool/offline_check.sh   # packets dropped instead of refused
//
// Throwaway empty wallet only; never prints the phrase or the password.
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/routes.dart' show DeskRoute, deskNavProvider;
import 'package:epic_wallet/src/desktop/data/files.dart' show DeskFiles, deskFilesProvider, deskOpenFolderProvider, deskOpenUrlProvider;
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show ServiceHealth;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Seconds a screen gets before a spinner still turning counts as endless.
const spinnerWait = int.fromEnvironment('OFFLINE_SPINNER_S', defaultValue: 20);

final home = Platform.environment['RC_HOME'] ?? Directory.systemTemp.path;

/// The runner's control folder: the test writes `want-up`, the runner answers `up`.
final netDir = Platform.environment['OFFLINE_NET_DIR'];

String _p(String name) => '$home${Platform.pathSeparator}$name';

/// The Save and Open dialogs, answered in [home].
class _Files implements DeskHistoryFiles {
  String? next;
  String? lastSaved;
  @override
  Future<String?> save({required String name, required Uint8List bytes, required String title}) async {
    await File(_p(name)).writeAsBytes(bytes, flush: true);
    return lastSaved = _p(name);
  }

  @override
  Future<({String name, Uint8List bytes})?> pick({required String title, List<String> extensions = const ['wfeh'], int? maxBytes}) async {
    final p = next;
    next = null;
    return p == null ? null : (name: p.split('/').last, bytes: await File(p).readAsBytes());
  }
}

class _Slates implements DeskFiles {
  String? next;
  @override
  Future<String?> pickSlate({required String title}) async {
    final p = next;
    next = null;
    return p;
  }
}

final _files = _Files();
final _slates = _Slates();
final _opened = <String>[];

/// What one visit saw.
class Visit {
  Visit(this.name, this.errors, this.spinners, this.texts, this.notices, this.toasts, this.animating);
  final String name;
  final List<String> errors;
  final int spinners;
  final List<String> texts;
  final int notices;
  final int toasts;
  final bool animating;
}

final visits = <Visit>[];

int _spinners() => find
    .byWidgetPredicate((w) => w is ProgressIndicator && w.value == null)
    .evaluate()
    .length;

int _count(String type) => find.byWidgetPredicate((w) => w.runtimeType.toString() == type).evaluate().length;

/// Pumps [spinnerWait] seconds of real time, then records what the screen shows.
Future<Visit> look(WidgetTester tester, String name, {int waitS = spinnerWait}) async {
  final before = flutterErrors.length;
  final end = DateTime.now().add(Duration(seconds: waitS));
  // No spinner for three seconds in a row ends the wait early.
  var quiet = 0;
  while (DateTime.now().isBefore(end) && quiet < 3) {
    await settle(tester, ms: 1000);
    quiet = _spinners() == 0 ? quiet + 1 : 0;
  }
  await tester.pump(const Duration(milliseconds: 50));
  final v = Visit(
    name,
    flutterErrors.sublist(before),
    _spinners(),
    texts(),
    _count('ENotice') + _count('EpicboxDownNotice') + _count('HttpReachNotice'),
    find.byType(SnackBar).evaluate().length,
    tester.binding.hasScheduledFrame,
  );
  visits.add(v);
  await shot(tester, 'offline-${visits.length.toString().padLeft(2, '0')}-${name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}');
  // ignore: avoid_print
  print('VISIT $name | errors ${v.errors.length} | spinners ${v.spinners} | notices ${v.notices} | toasts ${v.toasts} | '
      'texts ${v.texts.length} | ${shownTexts(25)}');
  return v;
}

Future<void> go(WidgetTester tester, DeskRoute r, [Object? arg]) async {
  if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
  final nav = containerOf(tester).read(deskNavProvider.notifier);
  nav.go(DeskRoute.overview);
  await settle(tester, ms: 300);
  nav.go(r, arg);
  await settle(tester, ms: 1000);
}

/// Taps the whole label [label] if it is on screen; false when it is not.
Future<bool> tapIf(WidgetTester tester, String label, {bool last = true}) async {
  final f = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().trim() == label);
  if (f.evaluate().isEmpty) return false;
  final target = last ? f.last : f.first;
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(target, warnIfMissed: false);
  await settle(tester, ms: 800);
  return true;
}

Future<void> closeAll(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await key(tester, LogicalKeyboardKey.escape);
  }
  ScaffoldMessenger.maybeOf(tester.element(find.byType(Navigator).first))?.clearSnackBars();
  await settle(tester);
}

ServiceHealth? nodeHealth(WidgetTester tester) => containerOf(tester).read(deskProvider).status?.nodeHealth;
ServiceHealth? boxHealth(WidgetTester tester) => containerOf(tester).read(deskProvider).status?.epicboxHealth;

const shellRoutes = [
  DeskRoute.overview,
  DeskRoute.activity,
  DeskRoute.send,
  DeskRoute.receive,
  DeskRoute.importTx,
  DeskRoute.finalize,
  DeskRoute.invoices,
  DeskRoute.outputs,
  DeskRoute.contacts,
  DeskRoute.settingsNode,
  DeskRoute.settingsReceiving,
  DeskRoute.settingsPrivacy,
  DeskRoute.settingsInvoices,
  DeskRoute.settingsAppearance,
  DeskRoute.settingsAccount,
  DeskRoute.settingsDevices,
  DeskRoute.settingsWallets,
  DeskRoute.settingsPhrase,
  DeskRoute.settingsRescan,
  DeskRoute.settingsAdvanced,
  DeskRoute.settingsAbout,
  DeskRoute.settingsHelp,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: no network at all, then back', (tester) async {
    captureErrors();
    final online = await tester.runAsync(() async {
      try {
        final s = await Socket.connect('1.1.1.1', 443, timeout: const Duration(seconds: 3));
        s.destroy();
        return true;
      } on Object {
        return false;
      }
    });
    record('precondition: no network in this process', online == false, online == true ? 'reached 1.1.1.1:443' : 'no route');

    final password = randomPassword();
    final t0 = DateTime.now();
    await boot(tester, extra: [
      deskHistoryFilesProvider.overrideWithValue(_files),
      deskFilesProvider.overrideWithValue(_slates),
      deskOpenUrlProvider.overrideWithValue((u) async => (_opened..add(u)).isNotEmpty),
      deskOpenFolderProvider.overrideWithValue((d) async => true),
    ]);
    await look(tester, 'Welcome', waitS: 8);
    record('offline: Welcome opens', hasText('Create a new wallet'), '${DateTime.now().difference(t0).inSeconds} s');

    // ---- Create a wallet with no network.
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    final c0 = DateTime.now();
    await tapText(tester, 'Create wallet', last: true);
    var created = true;
    try {
      await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    } on TestFailure catch (e) {
      created = false;
      record('offline: create wallet reaches the phrase', false, e.message ?? '');
    }
    if (created) {
      record('offline: create wallet reaches the phrase', true, '${DateTime.now().difference(c0).inSeconds} s');
      await tapText(tester, 'Reveal phrase');
      await tapText(tester, RegExp('[Ww]ritten down'));
      await tapText(tester, 'Continue', last: true);
      await waitText(tester, 'Skip setup', timeout: const Duration(seconds: 60));
      await look(tester, 'Setup (first run)', waitS: 12);
      await tapText(tester, 'Skip setup');
      final u0 = DateTime.now();
      await waitText(tester, RegExp('Unlock wallet|Available to spend|Skip tour'), timeout: const Duration(seconds: 120));
      if (hasText('Unlock wallet')) {
        await typeIn(tester, 0, password);
        await tapText(tester, 'Unlock', last: true);
      }
      var opened = true;
      try {
        await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
      } on TestFailure catch (e) {
        opened = false;
        record('offline: the wallet opens to Overview', false, e.message ?? '');
      }
      if (opened) {
        record('offline: the wallet opens to Overview', true, '${DateTime.now().difference(u0).inSeconds} s');
        await settle(tester, ms: 2000);
        if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
        await offlineScreens(tester, password);
        await backOnline(tester);
      }
    }
    record('no Flutter exceptions during the run', flutterErrors.isEmpty, flutterErrors.take(4).join(' / '));
    summary();
  }, timeout: const Timeout(Duration(minutes: 40)));
}

Future<void> offlineScreens(WidgetTester tester, String password) async {
  // ---- Every screen.
  for (final r in shellRoutes) {
    await go(tester, r);
    await look(tester, r.name);
  }
  record('offline: node shows as down, not checking', nodeHealth(tester) == ServiceHealth.down, '${nodeHealth(tester)}');
  record('offline: Epicbox shows as down, not checking', boxHealth(tester) == ServiceHealth.down, '${boxHealth(tester)}');

  // ---- Lock and unlock offline.
  await key(tester, LogicalKeyboardKey.keyL, ctrl: true);
  var locked = true;
  try {
    await waitText(tester, 'Unlock wallet', timeout: const Duration(seconds: 30));
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, 'Available to spend', timeout: const Duration(seconds: 120));
  } on TestFailure catch (e) {
    locked = false;
    record('offline: lock and unlock', false, e.message ?? '');
  }
  if (locked) record('offline: lock and unlock', true, '');

  // ---- Contacts: add one.
  await go(tester, DeskRoute.contacts);
  if (await tapIf(tester, 'Add contact')) {
    await settle(tester, ms: 800);
    final fields = find.byType(EditableText).evaluate().length;
    if (fields >= 2) {
      await typeIn(tester, 0, 'Offline friend');
      await typeIn(tester, 1, 'esZ1yz8pUH9iMdc7sk5Q2HQxpcFhCvwHJcgo9SyCYTrjEiyqHs9S@epicbox.epiccash.com');
      await settle(tester, ms: 600);
      await tapIf(tester, 'Save') || await tapIf(tester, 'Add contact');
    }
    final v = await look(tester, 'Contacts: add', waitS: 6);
    record('offline: add a contact', v.errors.isEmpty && hasText('Offline friend'), shownTexts(10));
    await closeAll(tester);
  } else {
    record('offline: add a contact', false, 'no Add contact: ${shownTexts(12)}');
  }

  // ---- Wallet data (.wfeh) export and import.
  await go(tester, DeskRoute.settingsAccount);
  if (await tapIf(tester, 'Export…')) {
    await settle(tester, ms: 1200);
    await tapIf(tester, 'Save as…');
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (!hasText('Done') && DateTime.now().isBefore(end)) {
      await settle(tester, ms: 500);
    }
    final v = await look(tester, 'Export wallet data', waitS: 4);
    record('offline: export wallet data (.wfeh)', _files.lastSaved != null && File(_files.lastSaved!).existsSync() && v.errors.isEmpty,
        _files.lastSaved ?? 'nothing saved: ${shownTexts(12)}');
    await tapIf(tester, 'Done');
    await closeAll(tester);
  } else {
    record('offline: export wallet data (.wfeh)', false, 'no Export…: ${shownTexts(12)}');
  }
  if (_files.lastSaved != null) {
    await go(tester, DeskRoute.settingsAccount);
    if (await tapIf(tester, 'Import…')) {
      await settle(tester, ms: 1000);
      _files.next = _files.lastSaved;
      await tapIf(tester, 'Choose file…');
      final end = DateTime.now().add(const Duration(seconds: 90));
      while (!hasText(RegExp(r'^(Imported|Nothing new|Not imported)')) && DateTime.now().isBefore(end)) {
        if (await tapIf(tester, 'Use the file’s') || await tapIf(tester, 'Use them here')) continue;
        await settle(tester, ms: 600);
      }
      final v = await look(tester, 'Import wallet data', waitS: 4);
      record('offline: import wallet data (.wfeh)', hasText(RegExp(r'^(Imported|Nothing new)')) && v.errors.isEmpty, shownTexts(12));
      await tapIf(tester, 'Done') || await tapIf(tester, 'Cancel');
      await closeAll(tester);
    }
  }

  // ---- Send: an amount to an address, up to the review; the File method.
  await go(tester, DeskRoute.send);
  await typeIn(tester, 0, 'esZ1yz8pUH9iMdc7sk5Q2HQxpcFhCvwHJcgo9SyCYTrjEiyqHs9S@epicbox.epiccash.com');
  await typeIn(tester, 1, '0.5');
  await settle(tester, ms: 800);
  await tapIf(tester, 'Review');
  await look(tester, 'Send: review (empty wallet)', waitS: 8);
  await tapIf(tester, 'File', last: false);
  await look(tester, 'Send: File method', waitS: 8);
  await closeAll(tester);

  // ---- Receive: a payment file that is not one, and a file that is not there.
  final junk = _p('not-a-slate.tx');
  await tester.runAsync(() => File(junk).writeAsString('{"version_info":{"version":4},"id":"0"}'));
  await go(tester, DeskRoute.importTx);
  _slates.next = junk;
  final pick = find.byWidgetPredicate((w) => w is RichText && RegExp(r'^(Choose file…|Choose a file|Open file|Choose a transaction file)$').hasMatch(w.text.toPlainText().trim()));
  if (pick.evaluate().isNotEmpty) {
    await tester.tap(pick.last, warnIfMissed: false);
    await settle(tester, ms: 1500);
  }
  final r1 = await look(tester, 'Receive: read a bad payment file', waitS: 15);
  record('offline: a bad payment file is refused in words', r1.errors.isEmpty && r1.spinners == 0 && hasText(RegExp('Not a transaction|not readable|could not', caseSensitive: false)), shownTexts(12));

  // ---- Request (invoice) needs the node's tip: it must say so, not hang.
  await go(tester, DeskRoute.invoiceIssue);
  await look(tester, 'Invoices: request form', waitS: 6);

  // ---- Report a problem: Send fails in words; Save to file works.
  await go(tester, DeskRoute.settingsHelp);
  if (await tapIf(tester, 'Report a problem')) {
    await settle(tester, ms: 800);
    final f = find.byType(EditableText);
    if (f.evaluate().isNotEmpty) {
      await tester.enterText(f.first, 'Offline check: no network.');
      await settle(tester);
    }
    await tapIf(tester, 'Send');
    final v = await look(tester, 'Report a problem: Send offline', waitS: 30);
    record('offline: report Send ends in words, no spinner', v.spinners == 0 && v.errors.isEmpty, shownTexts(12));
    await closeAll(tester);
  }

  // ---- Updates: the About page's check.
  await go(tester, DeskRoute.settingsAbout);
  if (await tapIf(tester, 'Check for updates') || await tapIf(tester, 'Check now')) {
    final v = await look(tester, 'About: update check offline', waitS: 30);
    record('offline: update check ends in words, no spinner', v.spinners == 0 && v.errors.isEmpty, shownTexts(12));
  }

  // ---- Once more after a few minutes offline: nothing piles up.
  await go(tester, DeskRoute.overview);
  await look(tester, 'Overview after the visits', waitS: 30);
}

Future<void> backOnline(WidgetTester tester) async {
  if (netDir == null) {
    record('back online: not run (no OFFLINE_NET_DIR)', true, '');
    return;
  }
  await tester.runAsync(() => File('$netDir/want-up').writeAsString('1'));
  final up = await tester.runAsync(() async {
    for (var i = 0; i < 60; i++) {
      if (File('$netDir/up').existsSync()) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  });
  record('back online: the runner plugged the network in', up == true, '');
  if (up != true) return;
  final t0 = DateTime.now();
  await go(tester, DeskRoute.overview);
  // Recovery by itself: no restart, no tap.
  final end = t0.add(const Duration(minutes: 4));
  while (DateTime.now().isBefore(end) && !(nodeHealth(tester) == ServiceHealth.ok && boxHealth(tester) == ServiceHealth.ok)) {
    await settle(tester, ms: 2000);
  }
  final secs = DateTime.now().difference(t0).inSeconds;
  record('back online: node ok without a restart', nodeHealth(tester) == ServiceHealth.ok, '${nodeHealth(tester)} after $secs s');
  record('back online: Epicbox ok without a restart', boxHealth(tester) == ServiceHealth.ok, '${boxHealth(tester)} after $secs s');
  for (final r in [DeskRoute.overview, DeskRoute.receive, DeskRoute.send, DeskRoute.settingsNode, DeskRoute.settingsPrivacy, DeskRoute.settingsAbout]) {
    await go(tester, r);
    final v = await look(tester, 'online again: ${r.name}', waitS: 10);
    final stale = v.texts.where((t) => RegExp(r'offline|unreachable|no connection|can.t reach|not reachable', caseSensitive: false).hasMatch(t)).toList();
    record('back online: ${r.name} shows no offline notice', stale.isEmpty && v.errors.isEmpty, stale.take(3).join(' / '));
  }
}

/// One PASS/FAIL per screen, judged after all visits: the texts every screen shows (sidebar,
/// title bar) do not count toward the body.
void summary() {
  final shell = visits.length < 3
      ? <String>{}
      : visits.skip(2).map((v) => v.texts.toSet()).reduce((a, b) => a.intersection(b));
  for (final v in visits) {
    final body = v.texts.where((t) => !shell.contains(t)).length;
    final problems = [
      if (v.errors.isNotEmpty) 'exception: ${v.errors.first}',
      if (v.spinners > 0) '${v.spinners} spinner(s) after the wait',
      if (body < 2) 'blank body ($body texts)',
      if (v.notices > 3) '${v.notices} notices',
      if (v.toasts > 1) '${v.toasts} toasts',
    ];
    record('screen ${v.name}', problems.isEmpty, problems.isEmpty ? '$body texts, ${v.notices} notices, ${v.toasts} toasts' : problems.join('; '));
  }
  // ignore: avoid_print
  print('OPENED ${_opened.join(' ')}');
}
