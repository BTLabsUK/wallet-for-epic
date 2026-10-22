// Desktop release check, part 1: first run, create, lock, sync, receive, settings, hidden features.
// Real LEPIC, real node and Epicbox relay (see tool/release_check.sh). Never prints the phrase or
// the password. The phrase is written to RC_PHRASE_FILE (a throwaway dir) for restore_test.dart.
import 'dart:io';

import 'package:epic_wallet/src/desktop/widgets/kit.dart' show ESeedGrid;
import 'package:epic_wallet/src/desktop/data/features.dart';
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: first run to settings', (tester) async {
    captureErrors();
    final password = randomPassword();
    await boot(tester);
    await shot(tester, '01-welcome');
    record('first start shows Welcome', hasText('Create a new wallet') && hasText('Restore from a phrase'), texts().take(6).join(' | '));

    // Create.
    await tapText(tester, 'Create a new wallet');
    await shot(tester, '02-create-account');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    await tapText(tester, 'Reveal phrase');
    final words = tester.widget<ESeedGrid>(find.byType(ESeedGrid)).words;
    record('recovery phrase has 24 words', words.length == 24, '${words.length} words');
    // Throwaway empty wallet only: the phrase goes to a mode-600 file in the scratch dir for
    // restore_test.dart, which deletes it. Never do this for a wallet that will hold funds.
    final phraseFile = Platform.environment['RC_PHRASE_FILE'];
    if (phraseFile != null) {
      File(phraseFile).writeAsStringSync(words.join(' '));
      Process.runSync('chmod', ['600', phraseFile]);
    }
    await tapText(tester, 'Written down');
    await tapText(tester, 'Continue', last: true);
    await waitText(tester, 'Unlock wallet');
    record('Continue on the phrase lands on Unlock', true, texts().take(5).join(' | '));

    // Unlock: wrong password first.
    await typeIn(tester, 0, '${password}x');
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, RegExp('password', caseSensitive: false), timeout: const Duration(seconds: 120));
    record('wrong password shows an error', hasText('Wrong password'), texts().firstWhere((t) => t.contains('assword.'), orElse: () => '-'));
    await shot(tester, '04-unlock-wrong-password');
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
    await settle(tester, ms: 3000);
    record('first Overview offers the tour', hasText('Skip tour'), texts().where((t) => t.contains('of 8')).join());
    await tapText(tester, 'Skip tour');
    await settle(tester, ms: 1000);
    dump('overview');
    await shot(tester, '05-overview');
    final deskAddr = await tester.runAsync(() => containerOf(tester).read(deskApiProvider).epicboxAddress());
    final addrFile = Platform.environment['RC_ADDR_FILE'];
    if (addrFile != null) File(addrFile).writeAsStringSync(deskAddr!);

    // ---- Overview, sync, receive address, Epicbox.
    dump('overview');
    final heightRe = RegExp(r'Height (\d[\d,]*)');
    final h = heightRe.firstMatch(texts().join(' '));
    record('sync: node online with a height', hasText('Online') && h != null, 'node ${hasText('node.btlabs.uk') ? 'btlabs' : '?'} ${h?.group(0)}');
    record('Epicbox status online', texts().join(' | ').contains('Epicbox | Online | $relay'), 'sidebar: ${texts().where((t) => t.startsWith('Receiving') || t == 'On').join(' ')}');
    record('overview shows 0 balance on a fresh wallet', hasText('Available to spend') && hasText('0'), '');

    await tapText(tester, 'Receive');
    await settle(tester, ms: 1500);
    record('Receive shows Epic address, listening', hasText('Epic address') && hasText('Listening via'), texts().where((t) => t.startsWith('Listening')).join());
    record('Epicbox address is <id>@<relay>', RegExp(r'^[^@\s]{20,}@[a-z0-9.\-]+$').hasMatch(deskAddr!), deskAddr.replaceAll(RegExp(r'^[^@]+'), '<id>'));
    await shot(tester, '06-receive');

    // ---- Send on an empty wallet, up to the review step.
    await tapText(tester, 'Send');
    await settle(tester, ms: 800);
    await typeIn(tester, 0, deskAddr);
    await typeIn(tester, 1, '0.5');
    await settle(tester, ms: 1000);
    await shot(tester, '07-send-filled');
    dump('send filled');
    await tapText(tester, 'Review send');
    await settle(tester, ms: 2500);
    dump('send review');
    await shot(tester, '08-send-review-empty-wallet');
    record('Send review on an empty wallet', hasText(RegExp('More than the available|enough|insufficient', caseSensitive: false)), texts().where((t) => RegExp('enough|insufficient|exceed|balance', caseSensitive: false).hasMatch(t)).join(' / '));
    await tapText(tester, 'File');
    await settle(tester, ms: 800);
    dump('send file tab');
    await shot(tester, '09-send-file-tab');

    // ---- Hidden features.
    for (final page in ['Overview', 'Activity', 'Send', 'Receive', 'Contacts', 'Settings']) {
      await tapText(tester, page);
      await settle(tester, ms: 600);
      final bad = texts().where((t) => _hidden(const []).hasMatch(t)).toList();
      record('hidden features absent on $page', bad.isEmpty, bad.join(' / '));
    }
    for (final sub in ['Node', 'Receiving', 'Appearance', 'Rescan', 'About']) {
      await tapText(tester, 'Settings');
      await tapText(tester, sub);
      await settle(tester, ms: 700);
      final bad = texts().where((t) => _hidden(const ['This computer', 'we ']).hasMatch(t)).toList();
      record('hidden features absent in Settings > $sub', bad.isEmpty, bad.join(' / '));
    }
    await tapText(tester, 'Help');
    await settle(tester, ms: 700);
    final helpBad = texts().where((t) => RegExp(r'\bTor\b|built-in|Telegram|\bbot\b|HTTP', caseSensitive: false).hasMatch(t)).toList();
    record('Help topics mention only built features', helpBad.isEmpty, helpBad.map((t) => t.length > 90 ? t.substring(0, 90) : t).join(' / '));

    // ---- Theme.
    var themeShot = 0;
    await tapText(tester, 'Appearance');
    await settle(tester, ms: 500);
    for (final t in ['Dark', 'Light', 'Dark']) {
      await tapText(tester, t, last: true);
      await settle(tester, ms: 600);
      await shot(tester, '10-theme-${t.toLowerCase()}-${++themeShot}');
    }
    record('theme dark/light/dark switches without errors', flutterErrors.isEmpty, flutterErrors.take(2).join(' / '));

    // ---- Interface scale.
    for (final pct in ['90', '125', '150', '100']) {
      await tapText(tester, RegExp(r'^\d+%$'));
      await settle(tester, ms: 500);
      final opt = textF('$pct%');
      if (opt.evaluate().isEmpty) {
        record('scale $pct%', false, 'no option: ${texts().where((t) => t.contains('%')).join(',')}');
        await key(tester, LogicalKeyboardKey.escape);
        continue;
      }
      await tester.tap(opt.last, warnIfMissed: false);
      await settle(tester, ms: 1200);
      await shot(tester, '11-scale-$pct');
      record('scale $pct%: applies, no overflow', hasText('$pct%') && flutterErrors.isEmpty, flutterErrors.take(2).join(' / '));
    }

    // ---- Node change and back.
    await tapText(tester, 'Settings');
    await tapText(tester, 'Node');
    await settle(tester, ms: 800);
    await typeIn(tester, 0, Uri.parse(node2).host);
    await settle(tester, ms: 1500);
    await tapText(tester, RegExp('^${RegExp.escape(Uri.parse(node2).host)}'), last: true);
    await settle(tester, ms: 6000);
    dump('node after change');
    await shot(tester, '12-node-changed');
    await tapText(tester, 'Overview');
    await settle(tester, ms: 1500);
    record('Overview status shows the changed node', hasText(Uri.parse(node2).host), texts().where((t) => t.contains('node.')).join(' / '));
    await tapText(tester, 'Settings');
    await tapText(tester, 'Node');
    await settle(tester, ms: 800);
    await typeIn(tester, 0, Uri.parse(node).host);
    await settle(tester, ms: 1500);
    await tapText(tester, RegExp('^${RegExp.escape(Uri.parse(node).host)}'), last: true);
    await settle(tester, ms: 6000);
    await tapText(tester, 'Overview');
    await settle(tester, ms: 1500);
    record('Overview status shows the node switched back', hasText(Uri.parse(node).host), texts().where((t) => t.contains('node.')).join(' / '));
    await tapText(tester, 'Settings');
    await tapText(tester, 'Node');
    await shot(tester, '13-node-back');

    // ---- Lock and unlock.
    await key(tester, LogicalKeyboardKey.keyL, ctrl: true);
    await waitText(tester, 'Unlock wallet', timeout: const Duration(seconds: 30));
    record('Ctrl+L locks the wallet', true, '');
    await shot(tester, '14-locked');
    await typeIn(tester, 0, '${password}x');
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, 'Wrong password', timeout: const Duration(seconds: 120));
    record('locked: wrong password rejected', true, '');
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, 'Available to spend', timeout: const Duration(seconds: 120));
    record('locked: right password unlocks to Overview', true, '');

    record('no Flutter exceptions during the run', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
  }, timeout: const Timeout(Duration(minutes: 25)));
}

/// Words that must not show while their feature is off, plus copy that must never show.
RegExp _hidden(List<String> extra) {
  final terms = [
    if (!DeskFeatures.tor) ...[r'\bTor\b', 'onion'],
    if (!DeskFeatures.httpDirect) ...['HTTP', 'Direct'],
    if (!DeskFeatures.importWizard) 'Import',
    if (!DeskFeatures.multiWallet) ...['Switch wallet', 'Add a wallet', 'All wallets'],
    if (!DeskFeatures.builtInNode) ...['Built-in', ...extra.where((e) => e == 'This computer')],
    if (!DeskFeatures.coins) ...['Outputs', 'Coins'],
    if (!DeskFeatures.dandelion) 'Dandelion',
    if (!DeskFeatures.changePassword) 'Change password',
    if (!DeskFeatures.paymentProofs) 'Export proof',
    'Telegram', r'\bbot\b',
    ...extra.where((e) => e != 'This computer'),
  ];
  return RegExp(terms.join('|'), caseSensitive: false);
}
