// SPDX-License-Identifier: Apache-2.0
// Desktop release check: a user never sees a network's name. Creates a wallet on the real LEPIC
// core, walks every page, Settings section and Help topic, exports Wallet data, and lists the
// data folder; any "mainnet", "floonet" or "floo" on screen, in a saved file's name or content
// (plain text only) or in a folder name is a FAIL. Throwaway empty wallet; never prints the
// phrase or the password.
//
//   RC_OUT=$TMPDIR/rc app/tool/release_check.sh desktop integration_test/release_check/mainnet_words_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/desktop/app/routes.dart' show DeskRoute, deskNavProvider;
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_pairing.dart' show HelpAt;
import 'package:epic_wallet/src/help/help_content.dart' show HelpId;
import 'package:flutter/material.dart' show RichText;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

final _words = RegExp('mainnet|floonet|floo', caseSensitive: false);

/// Saves land in RC_HOME/saved under the name the app offers.
class _Files implements DeskHistoryFiles {
  final saved = <String>[];
  String get dir => '${Platform.environment['RC_HOME'] ?? Platform.environment['HOME']}/saved';

  @override
  Future<String?> save({required String name, required Uint8List bytes, required String title}) async {
    await Directory(dir).create(recursive: true);
    final p = '$dir/$name';
    await File(p).writeAsBytes(bytes, flush: true);
    saved.add(p);
    return p;
  }

  @override
  Future<({String name, Uint8List bytes})?> pick({required String title, List<String> extensions = const ['wfeh'], int? maxBytes}) async => null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: no network name anywhere a user sees', (tester) async {
    captureErrors();
    final files = _Files();
    final password = randomPassword();
    final seen = <String>{};
    final hits = <String>[];
    // The run's own HOME is a scratch path that may hold anything; the app shows it as is.
    final runHome = Platform.environment['RC_HOME'] ?? Platform.environment['HOME']!;
    void look(String where) {
      for (final t in texts().map((t) => t.replaceAll(runHome, '~'))) {
        seen.add(t);
        if (_words.hasMatch(t)) hits.add('$where: ${t.length > 120 ? t.substring(0, 120) : t}');
      }
    }

    await boot(tester, extra: [deskHistoryFilesProvider.overrideWithValue(files)]);
    look('welcome');

    // Create, the way desktop_test.dart does.
    await tapText(tester, 'Create a new wallet');
    look('create');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, RegExp('[Ww]ritten down'));
    await tapText(tester, 'Continue', last: true);
    await waitText(tester, 'Skip setup', timeout: const Duration(seconds: 60));
    look('setup');
    await tapText(tester, 'Skip setup');
    await waitText(tester, RegExp('Unlock wallet|Available to spend|Skip tour'), timeout: const Duration(seconds: 120));
    if (hasText('Unlock wallet')) {
      look('unlock');
      await typeIn(tester, 0, password);
      await tapText(tester, 'Unlock', last: true);
    }
    await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
    await settle(tester, ms: 3000);
    if (hasText('Skip tour')) {
      look('tour');
      await tapText(tester, 'Skip tour');
    }
    record('wallet created', hasText('Available to spend'), '');

    final nav = containerOf(tester).read(deskNavProvider.notifier);
    Future<void> go(DeskRoute r, [Object? arg]) async {
      nav.go(DeskRoute.overview);
      await settle(tester, ms: 300);
      nav.go(r, arg);
      await settle(tester, ms: 1500);
      look(r.name);
    }

    // Every page that opens without an argument (the phrase page asks for the password).
    for (final r in const [
      DeskRoute.overview, DeskRoute.activity, DeskRoute.send, DeskRoute.receive, DeskRoute.contacts,
      DeskRoute.outputs, DeskRoute.invoices, DeskRoute.settingsNode, DeskRoute.settingsReceiving,
      DeskRoute.settingsPrivacy, DeskRoute.settingsInvoices, DeskRoute.settingsAppearance,
      DeskRoute.settingsAccount, DeskRoute.settingsDevices, DeskRoute.settingsWallets,
      DeskRoute.settingsRescan, DeskRoute.settingsAdvanced, DeskRoute.settingsAbout, DeskRoute.settingsHelp,
    ]) {
      await go(r);
    }
    // Every Help topic, opened.
    for (final id in const [
      HelpId.receive, HelpId.send, HelpId.file, HelpId.qr, HelpId.addresses, HelpId.handshake,
      HelpId.confirmations, HelpId.privacy, HelpId.locked, HelpId.strategy, HelpId.split, HelpId.fees,
      HelpId.phrase, HelpId.backup, HelpId.node, HelpId.epicbox, HelpId.tor, HelpId.advanced,
      HelpId.modes, HelpId.methods, HelpId.trouble, HelpId.pairing, HelpId.pairingWords,
      HelpId.pairingWays, HelpId.checkWords, HelpId.invoices, HelpId.pairingRestore, HelpId.cleanup,
      HelpId.importWarning, HelpId.cancel, HelpId.otherWallet, HelpId.linkedDevices, HelpId.lostDevice,
      HelpId.heldCoins,
    ]) {
      await go(DeskRoute.settingsHelp, HelpAt.topic(id));
    }
    await shot(tester, 'mw-help');

    // Settings › This wallet › Backup › Export…
    await go(DeskRoute.settingsAccount);
    final export = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().trim() == 'Export…');
    if (export.evaluate().isNotEmpty) {
      await tester.ensureVisible(export.first);
      await tester.tap(export.first, warnIfMissed: false);
      await settle(tester, ms: 1500);
      look('export dialog');
      await shot(tester, 'mw-export');
      await tapText(tester, 'Save as…', last: true);
      await waitText(tester, 'Done', timeout: const Duration(seconds: 60));
      look('export done');
      await tapText(tester, 'Done', last: true);
    }
    final wfeh = files.saved.where((p) => p.endsWith('.wfeh')).toList();
    record('Wallet data exported', wfeh.isNotEmpty, wfeh.map((p) => p.split('/').last).join(', '));

    // Contacts › Export contacts (a plain-text file the user receives).
    await go(DeskRoute.contacts);
    if (hasText('Export contacts')) {
      await tapText(tester, 'Export contacts');
      await settle(tester, ms: 800);
      look('contacts export dialog');
      final more = find.byWidgetPredicate((w) => w is RichText && RegExp(r'^(Export|Save|Save as…)$').hasMatch(w.text.toPlainText().trim()));
      if (more.evaluate().isNotEmpty) {
        await tester.tap(more.last, warnIfMissed: false);
        await settle(tester, ms: 1500);
      }
    }

    for (final p in files.saved) {
      final name = p.split('/').last;
      record('saved file name has no network: $name', !_words.hasMatch(name), name);
      if (!p.endsWith('.wfeh')) {
        final text = await tester.runAsync(() => File(p).readAsString()) ?? '';
        record('saved file content has no network: $name', !_words.hasMatch(text), '${text.length} chars');
      }
    }

    // The data folder and everything in it.
    final home = runHome;
    final paths = await tester.runAsync(() async => [
          await for (final e in Directory('$home/.epic_cash_desktop').list(recursive: true, followLinks: false)) e.path,
        ]) ??
        const <String>[];
    final badPaths = paths.where((p) => _words.hasMatch(p.substring(home.length))).toList();
    // ignore: avoid_print
    print('FOLDERS ${paths.where((p) => !p.contains('/lepic/')).map((p) => p.substring(home.length)).take(40).join(' ')}');
    record('data folder: ${paths.length} paths, none named for a network', paths.isNotEmpty && badPaths.isEmpty, badPaths.take(5).join(' / '));

    record('screens: ${seen.length} texts seen, none names a network', hits.isEmpty, hits.take(10).join(' / '));
    record('no Flutter exceptions during the run', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  }, timeout: const Timeout(Duration(minutes: 25)));
}
