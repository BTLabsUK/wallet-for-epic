// Live check of the warning before the first import, on the real desktop wallet in a fresh
// HOME: Welcome › Import wallets shows it; Cancel leaves no wallet and no flag; Continue needs
// the acknowledgement, opens the wizard and saves the flag with the app's settings; a second
// start goes straight to the wizard. Run as tool/release_check.sh desktop <this file>.
import 'dart:io';

import 'package:epic_wallet/main_desktop.dart' show deskOverrides;
import 'package:epic_wallet/src/desktop/app/desk_app.dart' show DeskApp;
import 'package:epic_wallet/src/desktop/data/desk_store.dart' show deskStoreProvider;
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show EButton, ECheckbox;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

const _title = 'Before you import';
const _ack = 'I have a backup of every wallet';

/// The flag as the app's settings store holds it (the keyring on Linux, as every setting).
Future<bool> _flagSaved(WidgetTester tester) async =>
    (await tester.runAsync(() async => (await containerOf(tester).read(deskStoreProvider)!.settings()).importWarningSeen))!;

/// A wallet exists once LEPIC wrote a wallet.seed; the empty folders come with the first start.
bool _walletsOnDisk() => _seeds().isNotEmpty;

List<String> _seeds() {
  final home = Platform.environment['HOME']!;
  final dir = Directory('$home/.epic_cash_desktop');
  if (!dir.existsSync()) return const [];
  return [for (final f in dir.listSync(recursive: true).whereType<File>()) if (f.uri.pathSegments.last == 'wallet.seed') f.path.substring(home.length)];
}

/// The app started again on the same HOME (the backend stays, it cannot init twice).
Future<void> reboot(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await settle(tester);
  final overrides = await tester.runAsync(deskOverrides);
  await tester.pumpWidget(ProviderScope(retry: (_, _) => null, overrides: overrides!, child: RepaintBoundary(key: shotKey, child: const DeskApp())));
  await settle(tester, ms: 1500);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: the warning before the first import', (tester) async {
    captureErrors();
    await boot(tester);
    record('first start shows Welcome with Import wallets', hasText('Import wallets'), texts().take(6).join(' | '));

    await tapText(tester, 'Import wallets');
    await settle(tester, ms: 800);
    await shot(tester, 'iw-01-warning');
    record('Import wallets shows the warning first', hasText(_title) && hasText(_ack), texts().where((t) => t.length > 20).take(4).join(' | '));
    final cont = find.widgetWithText(EButton, 'Continue');
    record('Continue is disabled before the acknowledgement', cont.evaluate().isNotEmpty && tester.widget<EButton>(cont).onPressed == null);

    await tapText(tester, 'Cancel', last: true);
    await settle(tester, ms: 800);
    await shot(tester, 'iw-02-after-cancel');
    final flagAfterCancel = await _flagSaved(tester);
    record('Cancel: back on Welcome, no wallet, no flag saved', !hasText(_title) && hasText('Import wallets') && !_walletsOnDisk() && !flagAfterCancel, 'seeds: ${_seeds()}, flag: $flagAfterCancel');

    await tapText(tester, 'Import wallets');
    await settle(tester, ms: 800);
    record('the second try asks again', hasText(_title));
    await tester.tap(find.byType(ECheckbox));
    await settle(tester, ms: 400);
    await shot(tester, 'iw-03-acknowledged');
    record('the tick enables Continue', tester.widget<EButton>(cont).onPressed != null);
    await tapText(tester, 'Continue', last: true);
    await waitText(tester, RegExp(r'Finding wallets|No wallets found|wallets? found'), timeout: const Duration(seconds: 60));
    await settle(tester, ms: 1500);
    await shot(tester, 'iw-04-wizard');
    record('Continue opens the wizard and saves the flag', !hasText(_title) && await _flagSaved(tester), texts().take(3).join(' | '));

    // Back to Welcome; the same run asks no more.
    await tapText(tester, 'Cancel', last: true);
    await waitText(tester, 'Import wallets');
    await tapText(tester, 'Import wallets');
    await settle(tester, ms: 800);
    record('the same run: straight to the wizard', !hasText(_title) && hasText(RegExp(r'Finding wallets|No wallets found|wallets? found')));
    await tapText(tester, 'Cancel', last: true);
    await waitText(tester, 'Import wallets');

    // A second start: the app booted again on the same HOME.
    await reboot(tester);
    await tapText(tester, 'Import wallets');
    await settle(tester, ms: 800);
    await shot(tester, 'iw-05-second-start');
    record('a second start: no warning, the wizard opens', !hasText(_title) && hasText(RegExp(r'Finding wallets|No wallets found|wallets? found')), texts().take(4).join(' | '));
    record('no wallet was ever created', !_walletsOnDisk(), 'seeds: ${_seeds()}');
  });
}
