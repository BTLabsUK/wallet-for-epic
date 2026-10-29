// SPDX-License-Identifier: Apache-2.0
// Desktop release check, history backup (.wfeh v2) round trip on floonet: the real desktop
// wallet with real LEPIC, the floonet node and relay, the floonet faucet. Two phases, each in
// its own fresh HOME:
//
//   HB_PHASE=build   RC_OUT=$TMPDIR/rc app/tool/release_check.sh desktop integration_test/release_check/history_backup_test.dart
//   HB_PHASE=restore RC_OUT=$TMPDIR/rc app/tool/release_check.sh desktop integration_test/release_check/history_backup_test.dart
//
// (floo-miner must run so blocks come; the build phase waits for two faucet payments to confirm.)
//
//   HB_PHASE=build    wallet A is made on floonet and funded from the faucet; a second LEPIC
//                     wallet B in this process pairs with it, takes a payment, asks for one
//                     (A pays) and is asked twice (one request withdrawn, one declined); A
//                     asks once more by file; contacts B never names, a star, labels and
//                     settings away from their defaults, a new wallet name. Settings › Backup
//                     exports the file, then A is deleted in the app. B's own backup and a
//                     version 1 file of A (sealed by a twin of A made from its phrase) are
//                     left beside F1.
//   HB_PHASE=restore  a new computer: A restored from its phrase, F1 imported (one summary,
//                     no settings question), everything checked; a changed setting asks once;
//                     B's file is refused; restored rows edited in the UI travel in F2 and
//                     come back on the same payments; the version 1 file still imports.
//
// HB_DIR (default $RC_OUT/hb) holds what the phases share: A's phrase and password (mode 600, never printed), the
// files and hb-expect.json. Throwaway floonet wallets only. Never prints a phrase or password.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/desktop/app/routes.dart' show DeskRoute, InvoicesTab, deskNavProvider;
import 'package:epic_wallet/src/desktop/data/api.dart' show DeskWalletApi;
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingApiProvider;
import 'package:epic_wallet/src/desktop/data/server_lists.dart' show ServerKind, deskServerListProvider;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider, deskProvider;
import 'package:epic_wallet/src/desktop/screens/onboarding/onboarding_parts.dart' show onbFlowProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart' show DeleteWalletDialog;
import 'package:epic_wallet/src/desktop/screens/wallet/tx_details_dialog.dart' show TxDetailsDialog;
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show EButton, ESeedGrid, ESegmented;
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart' show floonetPreset;
import 'package:epic_wallet/src/payment_method.dart' show MethodKind;
import 'package:epic_wallet/src/secret_store_api.dart' show MemorySecretStore;
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter/gestures.dart' show HitTestResult;
import 'package:flutter/material.dart' show EditableText, RichText, Scrollable, Size, TextField, TextInputAction, ValueKey, WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lepic/lepic.dart' as lepic;

import 'support.dart';

const flooNode = 'https://floo-node.btlabs.uk';
const flooRelay = 'epicbox.btlabs.uk';
const faucet = 'https://floo-explorer.btlabs.uk/api/faucet/claim';

final phase = Platform.environment['HB_PHASE'] ?? 'build';
/// `$RC_OUT/hb` under release_check.sh (beside shots/desktop), so both phases find it.
final hbDir = Platform.environment['HB_DIR'] ?? (Platform.environment['RC_SHOTS'] == null ? 'build/hb' : '${File(Platform.environment['RC_SHOTS']!).parent.parent.path}/hb');
String hbPath(String name) => '$hbDir/$name';

// What the build phase makes and the restore phase looks for.
const walletName = 'RC History A';
const seenAs = 'RC Desk';
const bName = 'RC Shop';
const carol = 'RC Carol';
const dave = 'RC Dave';
const daveHttp = 'http://198.51.100.7:3415';
const sendMessage = 'RC rent';
const orderMessage = 'RC order';
const withdrawnMessage = 'RC ask withdrawn';
const declinedMessage = 'RC ask declined';
const fileMessage = 'RC file ask';
const faucetLabel = 'RC faucet one';
const sendLabel = 'RC rent label';
const addedNode = 'https://rc-node.example.net';
const addedRelay = 'rc-relay.example.net';
const editLabels = ['RC restored label one', 'RC restored label two'];
const editNotes = ['RC restored note one', 'RC restored note two'];
const editVia = ['file', 'tor'];

int epic(num n) => (n * nanoPerEpic).round();

/// HB_NO_FUNDS=1: the faucet is down. Everything that needs coins (faucet in, the send to B,
/// the paid invoice, restored rows) is skipped and said so; B's invoice is declined instead.
final noFunds = Platform.environment['HB_NO_FUNDS'] == '1';

void skip(String step, String why) =>
    // ignore: avoid_print
    print('RC SKIP | $step | $why');

void log(String s) =>
    // ignore: avoid_print
    print('HB ${DateTime.now().toIso8601String().substring(11, 19)} $s');

/// The system file dialogs, answered from [hbDir]: a save writes there under [saveAs] (or the
/// name the app offers), a pick reads [next].
class HbFiles implements DeskHistoryFiles {
  String? saveAs;
  String? next;
  String? lastSaved;

  @override
  Future<String?> save({required String name, required Uint8List bytes, required String title}) async {
    final p = hbPath(saveAs ?? name);
    saveAs = null;
    await File(p).writeAsBytes(bytes, flush: true);
    return lastSaved = p;
  }

  @override
  Future<({String name, Uint8List bytes})?> pick({required String title, List<String> extensions = const ['wfeh'], int? maxBytes}) async {
    final p = next;
    next = null;
    if (p == null) return null;
    return (name: p.split('/').last, bytes: await File(p).readAsBytes());
  }
}

final files = HbFiles();

class _Store implements lepic.SecretStore {
  final _m = <String, String>{};
  @override
  Future<String?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, String value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
}

/// A headless copy of wallet A made from its phrase in [dir]: the same seed seals and opens
/// the same history files, so it reads what an export holds and seals a version 1 file.
Future<lepic.EpicWallet> twinOf(String phrase, String dir) => lepic.EpicWallet.create(
  runtime: lepic.LepicRuntime(logLevel: lepic.LogLevel.warn),
  config: lepic.WalletConfig(dataDir: dir, chain: lepic.Chain.floonet, nodeUrl: flooNode, epicboxDomain: flooRelay, epicboxPort: 443),
  store: lepic.lepicSecretStore(_Store()),
  mnemonic: phrase,
  password: randomPassword(),
);

Future<Map<String, dynamic>> openFile(lepic.EpicWallet twin, String path) async =>
    jsonDecode(utf8.decode(await twin.openAppData(file: await File(path).readAsBytes()))) as Map<String, dynamic>;

/// [v2] as 26.10.x wrote it: version 1, no invoices, wallet name or settings, no per-record
/// flow, pairing or slate messages.
Map<String, dynamic> asVersion1(Map<String, dynamic> v2) {
  final m = Map<String, dynamic>.of(v2)
    ..['version'] = 1
    ..['app_version'] = '26.10.16'
    ..remove('issued_invoices')
    ..remove('paid_invoices')
    ..remove('wallet')
    ..remove('settings');
  m['txs'] = [
    for (final t in (v2['txs'] as List).cast<Map<String, dynamic>>())
      Map<String, dynamic>.of(t)
        ..remove('flow')
        ..remove('pairing_id')
        ..remove('slate_messages'),
  ];
  return m;
}

void writeSecret(String path, Map<String, Object?> m) {
  final f = File(path)..writeAsStringSync('');
  Process.runSync('chmod', ['600', f.path]);
  f.writeAsStringSync(jsonEncode(m));
}

// ---- Driving the app.

/// True while a step wants the restored wallet's import offer left open.
bool keepOffer = false;

/// The restored wallet's import offer or the tour, when either opened late, out of the way.
Future<void> clearPopups(WidgetTester tester) async {
  if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
  if (!keepOffer && find.byKey(const ValueKey('history-import-offer')).evaluate().isNotEmpty) {
    await shot(tester, 'hb-$phase-offer');
    await tapText(tester, 'Not now', last: true);
  }
}

Future<void> go(WidgetTester tester, DeskRoute r, [Object? arg]) async {
  await clearPopups(tester);
  final nav = containerOf(tester).read(deskNavProvider.notifier);
  // Going to the same route with another arg keeps the old state: Overview first.
  nav.go(DeskRoute.overview);
  await settle(tester, ms: 300);
  nav.go(r, arg);
  await settle(tester, ms: 1500);
}

/// Taps a Settings row button after scrolling it to the middle: at the top edge the page
/// header covers it and the tap lands on the header.
Future<void> tapRowButton(WidgetTester tester, String label, {String? opens}) async {
  // On screen only and the whole label: pages kept offstage hold other buttons with it.
  final f = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().trim() == label, description: 'button $label');
  expect(f, findsWidgets, reason: 'no "$label" on screen: ${shownTexts()}');
  log('tap $label: ${f.evaluate().length} on screen');
  final done = Scrollable.ensureVisible(f.evaluate().first, alignment: 0.5);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await done;
  final at = tester.getCenter(f.first);
  await tester.tapAt(at);
  await settle(tester, ms: 1500);
  if (opens == null || hasText(opens)) return;
  // The tap was lost: say what sits on top there, then press the button's own handler.
  final hits = HitTestResult();
  WidgetsBinding.instance.hitTestInView(hits, at, tester.view.viewId);
  log('tap $label at $at missed; on top: ${hits.path.take(6).map((e) => e.target.runtimeType).join(' > ')}');
  await shot(tester, 'hb-missed-${label.replaceAll(RegExp(r'[^A-Za-z]'), '')}');
  final button = find.ancestor(of: f.first, matching: find.byType(EButton));
  tester.widget<EButton>(button.first).onPressed?.call();
  await settle(tester, ms: 1500);
}

DeskWalletApi apiOf(WidgetTester tester) => containerOf(tester).read(deskApiProvider);

Future<T> io<T>(WidgetTester tester, Future<T> Function() f) async => (await tester.runAsync(f)) as T;

/// Welcome on floonet: the adapter and Welcome's flow move to the test network.
Future<void> useFloonet(WidgetTester tester) async {
  // The app settles its Epicbox server once at start; a network change while that runs saves
  // mainnet's relay as floonet's (the _settleRelay race), so let it finish first.
  await settle(tester, ms: 6000);
  await io(tester, () => apiOf(tester).useNetwork('floonet'));
  containerOf(tester).read(onbFlowProvider.notifier).setNetwork('floonet');
  await settle(tester, ms: 800);
  record('$phase: Welcome makes and restores floonet wallets', apiOf(tester).network == 'floonet', apiOf(tester).network);
}

/// Setup's steps with their defaults until Unlock, then Unlock with [password], then the tour
/// skipped. [offer]: what to do with a restored wallet's "import a history backup?" question.
Future<void> unlockToOverview(WidgetTester tester, String password, {String offer = 'not-now'}) async {
  for (var i = 0; i < 8 && !hasText('Unlock wallet'); i++) {
    if (hasText(RegExp(r'^(Continue|Save settings)$'))) {
      await settle(tester, ms: 1000);
      await tapText(tester, hasText('Save settings') ? 'Save settings' : 'Continue', last: true);
    }
    await settle(tester, ms: 3000);
  }
  await waitText(tester, 'Unlock wallet', timeout: const Duration(minutes: 4));
  await typeIn(tester, 0, password);
  await tapText(tester, 'Unlock', last: true);
  await waitText(tester, RegExp('Available to spend|Overview'), timeout: const Duration(minutes: 3));
  final end = DateTime.now().add(const Duration(seconds: 40));
  while (DateTime.now().isBefore(end)) {
    await settle(tester, ms: 1500);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
    if (hasText('Skip setup')) await tapText(tester, 'Skip setup', last: true);
    if (find.byKey(const ValueKey('history-import-offer')).evaluate().isNotEmpty) {
      await shot(tester, 'hb-$phase-offer');
      if (offer == 'leave') return;
      await tapText(tester, offer == 'import' ? RegExp(r'^Import') : 'Not now', last: true);
      return;
    }
  }
}

Future<void> createA(WidgetTester tester, String password) async {
  await tapText(tester, 'Create a new wallet');
  await typeIn(tester, 0, password);
  await typeIn(tester, 1, password);
  await settle(tester);
  await tapText(tester, 'Create wallet', last: true);
  await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
  await tapText(tester, 'Reveal phrase');
  final words = tester.widget<ESeedGrid>(find.byType(ESeedGrid)).words;
  writeSecret(hbPath('a-secret.json'), {'phrase': words.join(' '), 'password': password});
  record('build: A made, phrase kept (mode 600)', words.length == 24, '${words.length} words');
  await tapText(tester, RegExp('[Ww]ritten down'));
  await tapText(tester, 'Continue', last: true);
  await unlockToOverview(tester, password);
}

/// Welcome › Restore from a phrase, with [phrase]; then Unlock. The scan is waited for by the
/// caller.
Future<void> restoreA(WidgetTester tester, String phrase, String password, {String offer = 'not-now', String tag = ''}) async {
  await waitText(tester, 'Restore from phrase', timeout: const Duration(seconds: 90));
  await tapText(tester, 'Restore from phrase');
  await typeIn(tester, 0, phrase);
  await settle(tester, ms: 1500);
  record('restore$tag: 24 words accepted', hasText('All 24 words check out.'), '');
  await tapText(tester, 'Continue', last: true);
  await settle(tester);
  // Wallet name (optional) comes first; the name is left for the import to bring back.
  final first = hasText('Wallet name (optional)') ? 1 : 0;
  await typeIn(tester, first, password);
  await typeIn(tester, first + 1, password);
  await settle(tester);
  await tapText(tester, 'Restore wallet', last: true);
  await unlockToOverview(tester, password, offer: offer);
}

/// The balance the first restore's scan found; later restores must find the same.
int? scannedTotal;

/// Waits until the restore scan is done: rows listed and the balance unchanged for 30 s (the
/// same as the first restore's, after that). [atExport] is only reported: payments still
/// confirming at export move coins between locked and change.
Future<List<Tx>> waitScan(WidgetTester tester, int atExport, {String tag = ''}) async {
  final api = apiOf(tester);
  final end = DateTime.now().add(const Duration(minutes: 8));
  var txs = <Tx>[];
  var total = -1, last = -2, same = 0;
  while (DateTime.now().isBefore(end)) {
    await clearPopups(tester);
    final b = await io(tester, api.balance);
    total = b.spendable + b.awaitingConfirmation + b.locked + b.immature;
    txs = await io(tester, api.transactions);
    same = total == last ? same + 1 : 0;
    last = total;
    final want = scannedTotal;
    if (txs.isNotEmpty && total > 0 && (want == null ? same >= 6 : total == want)) break;
    await settle(tester, ms: 5000);
  }
  final want = scannedTotal ??= total;
  record('restore$tag: the scan found the wallet\'s coins', total == want && total > 0 && txs.isNotEmpty, '${formatEpic(total)} (first restore ${formatEpic(want)}, at export ${formatEpic(atExport)}), ${txs.length} rows');
  await settle(tester, ms: 3000);
  return io(tester, api.transactions);
}

/// Settings › This wallet › Delete…, with the password and the tick; Welcome after.
Future<void> deleteA(WidgetTester tester, String password, {String tag = ''}) async {
  await go(tester, DeskRoute.settingsAccount);
  await tapRowButton(tester, 'Delete…', opens: 'Delete this wallet?');
  await waitText(tester, 'Delete this wallet?');
  final field = find.descendant(of: find.byType(DeleteWalletDialog), matching: find.byType(EditableText));
  await tester.enterText(field.first, password);
  await settle(tester);
  await tapText(tester, 'The recovery phrase is written down');
  await tapText(tester, 'Delete wallet', last: true);
  await waitText(tester, 'Restore from phrase', timeout: const Duration(minutes: 2));
  record('delete$tag: A deleted in the app, Welcome opens', hasText('Restore from phrase'), '');
}

/// Settings › This wallet › Backup › Export…, saved as [name] in [hbDir].
Future<String?> exportUi(WidgetTester tester, String name, {String shotName = ''}) async {
  await go(tester, DeskRoute.settingsAccount);
  await tapRowButton(tester, 'Export…', opens: 'Save as…');
  await waitText(tester, 'Save as…');
  await settle(tester, ms: 1500);
  if (shotName.isNotEmpty) await shot(tester, shotName);
  final shown = texts().join(' ');
  files.saveAs = name;
  await tapText(tester, 'Save as…', last: true);
  await waitText(tester, 'Done', timeout: const Duration(seconds: 60));
  await tapText(tester, 'Done', last: true);
  return shown;
}

class ImportRun {
  ImportRun(this.summary, this.settingsAsked, this.pairingAsked, this.refused, this.screen);
  final String summary;
  final int settingsAsked;
  final bool pairingAsked;
  final String? refused;
  final String screen;
}

/// Settings › This wallet › Backup › Import…, the file [path] picked. Answers the settings
/// question with [settings] ("Use the backup's" or "Keep mine") and takes pairings over.
Future<ImportRun> importUi(WidgetTester tester, String path, {String shotName = '', String settings = 'Use the file’s', bool fromOffer = false}) async {
  if (!fromOffer) {
    await go(tester, DeskRoute.settingsAccount);
    await tapRowButton(tester, 'Import…', opens: 'Choose file…');
  }
  await waitText(tester, 'Choose file…');
  files.next = path;
  await tapText(tester, 'Choose file…', last: true);
  var asked = 0;
  var pairing = false;
  String? refused;
  final end = DateTime.now().add(const Duration(minutes: 3));
  var quiet = 0;
  while (DateTime.now().isBefore(end)) {
    await settle(tester, ms: 800);
    if (hasText('Use the settings from this file?')) {
      asked++;
      await shot(tester, '$shotName-settings-question');
      dump('settings question');
      await tapText(tester, settings, last: true);
      quiet = 0;
      continue;
    }
    if (hasText('Use your contacts on this device?')) {
      pairing = true;
      await tapText(tester, 'Use them here', last: true);
      quiet = 0;
      continue;
    }
    if (hasText('Not imported') || hasText(RegExp('another wallet|other wallet|newer version|not a history', caseSensitive: false))) {
      refused = texts().where((t) => t.length > 12).join(' | ');
      break;
    }
    if (hasText(RegExp(r'^(Imported|Nothing new)$')) && ++quiet >= 3) break;
  }
  await settle(tester, ms: 800);
  final screen = texts().join(' | ');
  // The summary line only (the dialog's description also says "changes nothing").
  final summary = texts().where((t) => t.startsWith('Imported:') || t == 'Nothing new').join(' ');
  if (shotName.isNotEmpty) await shot(tester, shotName);
  if (hasText('Done')) {
    await tapText(tester, 'Done', last: true);
  } else if (hasText('Cancel')) {
    await tapText(tester, 'Cancel', last: true);
  }
  await settle(tester, ms: 1500);
  return ImportRun(summary, asked, pairing, refused, screen);
}

Future<String> claimFaucet(String address) async {
  final c = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final rq = await c.postUrl(Uri.parse('$faucet?method=epicbox&destination=${Uri.encodeComponent(address)}'));
    final rs = await rq.close().timeout(const Duration(seconds: 90));
    final body = await rs.transform(utf8.decoder).join();
    return '${rs.statusCode} ${body.length > 160 ? body.substring(0, 160) : body}';
  } on Object catch (e) {
    return 'error ${e.runtimeType}';
  } finally {
    c.close(force: true);
  }
}

Future<int> tip() async {
  final c = HttpClient();
  try {
    final rq = await c.postUrl(Uri.parse('$flooNode/v2/foreign'));
    rq.headers.contentType = ContentType.json;
    rq.write('{"jsonrpc":"2.0","method":"get_tip","params":[],"id":1}');
    final body = await (await rq.close()).transform(utf8.decoder).join();
    return ((jsonDecode(body) as Map)['result']['Ok']['height'] as num).toInt();
  } on Object {
    return -1;
  } finally {
    c.close(force: true);
  }
}

Map<String, Object?> txJson(Tx t) => {
  'key': t.key,
  'slate': t.slateId,
  'dir': t.direction.name,
  'amount': t.amount,
  'height': t.height,
  'label': t.labelText,
  'note': t.note,
  'flow': t.flow.name,
  'restored': t.restored,
  'counterparty': t.counterparty,
  'transport': t.transport,
};

// ---- Phase 1: build A's history and export it.

Future<void> buildPhase(WidgetTester tester) async {
  await tester.runAsync(() => Directory(hbDir).create(recursive: true));
  final password = randomPassword();
  await boot(tester, size: const Size(1400, 950), extra: [deskHistoryFilesProvider.overrideWithValue(files)]);
  await useFloonet(tester);
  await createA(tester, password);
  final api = apiOf(tester);
  final desk = containerOf(tester).read(deskProvider.notifier);
  final aAddr = await io(tester, api.epicboxAddress);
  record('build: A listens on the floonet relay', aAddr.endsWith('@$flooRelay'), aAddr.replaceAll(RegExp(r'^[^@]+'), '<id>'));
  // A faucet payout to an address nobody answers on poisons the faucet for everyone.
  if (!aAddr.endsWith('@$flooRelay')) return;

  // The experimental switches, and auto-lock 60 min so the long waits never lock the wallet.
  var s = containerOf(tester).read(deskProvider).settings;
  await io(
    tester,
    () => desk.saveSettings(
      s.copyWith(
        autoLockMinutes: 60,
        advanced: s.advanced.withExperimental(AdvancedFeature.invoices, true).withFeature(AdvancedFeature.outputs, true).withFeature(AdvancedFeature.technicalDetails, true),
      ),
    ),
  );
  await settle(tester, ms: 1000);

  // Wallet B (the shop) and C (only its address), headless, on floonet.
  final bDir = await io(tester, () => Directory(hbPath('b-wallet')).create(recursive: true));
  final cDir = await io(tester, () => Directory(hbPath('c-wallet')).create(recursive: true));
  final bService = LepicWalletService(secrets: MemorySecretStore());
  final b = await io(tester, () => bService.create(config: floonetPreset.config(dataDir: bDir.path, nodeUrl: flooNode), password: randomPassword()));
  final c = await io(tester, () => LepicWalletService(secrets: MemorySecretStore()).create(config: floonetPreset.config(dataDir: cDir.path, nodeUrl: flooNode), password: randomPassword()));
  final bAddr = await io(tester, b.epicboxAddress);
  final cAddr = await io(tester, c.epicboxAddress);
  c.dispose();
  final bEvents = <String>[];
  final bListen = b.startListener().listen((e) => bEvents.add(e.kind.name), onError: (Object e) => bEvents.add('error ${e.runtimeType}'));
  // Ending B's listener can hang LEPIC's stream; the run must still end.
  addTearDown(() async {
    await bListen.cancel().timeout(const Duration(seconds: 10), onTimeout: () => log('B listener did not stop in 10 s'));
    b.dispose();
  });

  // Pairing: B invites, A answers in Contacts › Pair under the name others see.
  final invite = await io(tester, () => b.pairing.makeInvite(name: bName, expiry: const Duration(hours: 2)));
  await go(tester, DeskRoute.pair);
  await tester.enterText(find.byKey(deskPairEnterKey), invite.inviteLink!);
  await settle(tester);
  await tester.tap(find.byKey(deskPairGoKey));
  await waitText(tester, bName, timeout: const Duration(seconds: 60));
  await settle(tester, ms: 800);
  await tester.tap(find.byKey(deskIncomingPairKey));
  await settle(tester);
  if (hasText('Enter the name they will see')) {
    await tester.enterText(find.byType(EditableText).last, seenAs);
    await settle(tester);
    await tester.tap(find.byKey(deskIncomingPairKey));
  }
  await settle(tester, ms: 1500);
  core.PairingRecord? theirs;
  var until = DateTime.now().add(const Duration(minutes: 3));
  while (DateTime.now().isBefore(until)) {
    await tester.runAsync(() => b.pairing.collect(trigger: core.PairingCollectTrigger.pull));
    theirs = await tester.runAsync<core.PairingRecord?>(() => b.pairing.pairing(invite.id));
    if (theirs?.state == core.PairingState.paired && find.byType(WordTiles).evaluate().isNotEmpty) break;
    await settle(tester, ms: 3000);
  }
  if (find.byType(WordTiles).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(deskCheckMatchKey));
    await settle(tester, ms: 1500);
  }
  await io(tester, () => b.pairing.checkWords(invite.id, core.PairingCheck.match));
  await io(tester, () => b.pairing.setAllowInvoices(invite.id, true));
  final pairApi = containerOf(tester).read(deskPairingApiProvider);
  var mine = await io(tester, pairApi.pairings);
  final paired = mine.where((p) => p.name == bName && p.state == core.PairingState.verified).firstOrNull;
  record('build: A paired with B (verified)', paired != null, mine.map((p) => '${p.name}:${p.state.name}').join(', '));
  if (paired == null) return;
  await io(tester, () => pairApi.setAllowInvoices(paired.id, true));

  // Funds: two faucet claims (two outputs, so two payments can go at once), then confirmed.
  var spendable = 0;
  Tx? sendRow;
  // The faucet is shared with the phone tester: claims wait for $HB_DIR/faucet-go when
  // HB_FAUCET_GATE=1 (the runner creates it when the faucet is ours).
  if (!noFunds && Platform.environment['HB_FAUCET_GATE'] == '1') {
    log('waiting for faucet-go');
    final gateEnd = DateTime.now().add(const Duration(minutes: 30));
    while (!File(hbPath('faucet-go')).existsSync() && DateTime.now().isBefore(gateEnd)) {
      await settle(tester, ms: 5000);
    }
  }
  for (var n = 0; n < 2 && !noFunds; n++) {
    var done = false;
    for (var attempt = 0; attempt < 8 && !done; attempt++) {
      final r = await io(tester, () => claimFaucet(aAddr));
      log('faucet claim ${n + 1}: $r');
      done = RegExp(r'^20[0-9] ').hasMatch(r);
      // A 429 names its wait; an early retry only pushes the cooldown out.
      final wait = int.tryParse(RegExp(r'wait (\d+)').firstMatch(r)?.group(1) ?? '');
      if (!done) await settle(tester, ms: wait != null ? (wait + 3) * 1000 : (r.contains('429') ? 45000 : 60000));
    }
    record('build: faucet claim ${n + 1} accepted', done, '');
    if (n == 0) await settle(tester, ms: 41000);
  }
  final fundEnd = DateTime.now().add(Duration(minutes: noFunds ? 0 : 40));
  var lastLog = DateTime(2000);
  while (DateTime.now().isBefore(fundEnd)) {
    await tester.runAsync(api.syncNow);
    spendable = (await io(tester, api.balance)).spendable;
    if (spendable >= epic(19)) break;
    if (DateTime.now().difference(lastLog).inSeconds > 60) {
      lastLog = DateTime.now();
      log('waiting for funds: spendable ${formatEpic(spendable)}, tip ${await io(tester, tip)}');
    }
    await settle(tester, ms: 15000);
  }
  final funded = spendable >= epic(19);
  if (noFunds) {
    skip('build: A funded from the faucet', 'HB_NO_FUNDS: the floonet faucet answers 503 finalize_tx TransactionDoesntExist');
  } else {
    record('build: A funded and confirmed (two faucet payments)', funded, formatEpic(spendable));
    await shot(tester, 'hb-build-01-funded');
    if (spendable < epic(2)) return;
  }

  // A pays B by Epicbox; B's listener answers.
  if (funded) {
    final sent = await io(tester, () => api.send(SendRequest(method: TxMethod.epicbox, amount: epic(1.5), to: bAddr, message: sendMessage)));
    final sentTx = sent is SendDone ? sent.tx : null;
    until = DateTime.now().add(const Duration(minutes: 4));
    while (DateTime.now().isBefore(until)) {
      sendRow = (await io(tester, api.transactions)).where((t) => t.slateId == sentTx?.slateId).firstOrNull;
      if (sendRow != null && sendRow.state != TxState.waitingRecipient) break;
      await settle(tester, ms: 4000);
    }
    record('build: the Epicbox payment to B went out', sendRow != null && sendRow.state != TxState.waitingRecipient, '${sendRow?.state.name}; B saw ${bEvents.join(',')}');
  } else {
    skip('build: the Epicbox payment to B', 'no funds');
  }

  // B asks A for a payment; A pays it (an invoice paid).
  final asked = await io(tester, () => b.pairing.requestPayment(id: invite.id, amount: BigInt.from(epic(2)), message: orderMessage));
  IncomingInvoice? toPay;
  until = DateTime.now().add(const Duration(minutes: 4));
  while (DateTime.now().isBefore(until) && toPay == null) {
    await tester.runAsync(() => b.pairing.collect(trigger: core.PairingCollectTrigger.pull));
    await tester.runAsync(() => pairApi.collect(trigger: core.PairingCollectTrigger.pull));
    toPay = (await io(tester, api.invoices)).waiting.where((i) => i.slateId == asked.slateId).firstOrNull;
    await settle(tester, ms: 4000);
  }
  record('build: B\'s invoice waits under Invoices › Pay', toPay != null, '${toPay?.label} ${toPay?.message}');
  if (toPay != null && !funded) {
    // No coins to pay with: A declines it, so the file still carries an invoice that ended here.
    await go(tester, DeskRoute.invoices, InvoicesTab.pay);
    await shot(tester, 'hb-build-02-to-pay');
    await io(tester, () => api.declineInvoice(toPay!.slateId));
    final after = (await io(tester, api.invoices)).toPay.where((i) => i.slateId == toPay!.slateId).firstOrNull;
    record('build: A declined B\'s invoice (no funds to pay it)', after?.state == PayState.declined, '${after?.state.name}');
    skip('build: A pays B\'s invoice', 'no funds');
  }
  if (toPay != null && funded) {
    await go(tester, DeskRoute.invoices, InvoicesTab.pay);
    await shot(tester, 'hb-build-02-to-pay');
    await io(tester, () => api.payInvoice(toPay!.slateId, amount: toPay.amount, password: password));
    IncomingInvoice? after;
    until = DateTime.now().add(const Duration(minutes: 4));
    while (DateTime.now().isBefore(until)) {
      await tester.runAsync(() => b.pairing.collect(trigger: core.PairingCollectTrigger.pull));
      await tester.runAsync(b.drainPayments);
      await tester.runAsync(() => pairApi.collect(trigger: core.PairingCollectTrigger.pull));
      after = (await io(tester, api.checkInvoices)).toPay.where((i) => i.slateId == toPay!.slateId).firstOrNull;
      if (after != null && (after.state == PayState.posted || after.state == PayState.confirming || after.state == PayState.completed)) break;
      await settle(tester, ms: 5000);
    }
    // Delivered: B has the reply; its posted notice may come later than this wait.
    record('build: A paid B\'s invoice', after != null && {PayState.delivered, PayState.posted, PayState.confirming, PayState.completed}.contains(after.state), '${after?.state.name}');
  }

  // A asks B twice: one request withdrawn here, one B declines; and once by file.
  final r1 = await io(tester, () => api.requestPayment(PaymentRequestDraft(pairingId: paired.id, amount: epic(0.5), message: withdrawnMessage)));
  final r2 = await io(tester, () => api.requestPayment(PaymentRequestDraft(pairingId: paired.id, amount: epic(0.25), message: declinedMessage)));
  await settle(tester, ms: 3000);
  await io(tester, () => api.withdrawRequest(r1.slateId));
  var declined = false;
  until = DateTime.now().add(const Duration(minutes: 4));
  while (DateTime.now().isBefore(until) && !declined) {
    await tester.runAsync(() => b.pairing.collect(trigger: core.PairingCollectTrigger.pull));
    await tester.runAsync(b.drainInvoices);
    final pend = await io(tester, b.pendingInvoices);
    if (pend.any((p) => p.slateId == r2.slateId)) await io(tester, () => b.declineInvoice(slateId: r2.slateId));
    await tester.runAsync(() => pairApi.collect(trigger: core.PairingCollectTrigger.pull));
    final sentNow = (await io(tester, api.checkInvoices)).sent;
    declined = sentNow.any((r) => r.slateId == r2.slateId && r.state == RequestState.declined);
    await settle(tester, ms: 4000);
  }
  final book = await io(tester, api.invoices);
  record('build: request to B withdrawn', book.sent.any((r) => r.slateId == r1.slateId && r.state == RequestState.withdrawn), book.sent.map((r) => '${r.message}:${r.state.name}').join(', '));
  record('build: request to B declined by B', declined, '');
  final byFile = await io(tester, () => api.requestFile(amount: epic(0.3), message: fileMessage));
  record('build: request by file made', byFile.slateId.isNotEmpty, '');
  await go(tester, DeskRoute.invoices, InvoicesTab.issue);
  await shot(tester, 'hb-build-03-requests');

  // Contacts B never names, one starred.
  await io(tester, () => api.saveContact(Contact(id: '', name: carol, epicbox: cAddr, favourite: true)));
  await io(tester, () => api.saveContact(Contact(id: '', name: dave, http: daveHttp)));

  // Labels on two payments.
  await io(tester, desk.refresh);
  var txs = await io(tester, api.transactions);
  final faucetRow = txs.where((t) => t.direction == TxDirection.received && t.flow == TxFlow.payment).lastOrNull ?? txs.firstOrNull;
  if (faucetRow != null) await io(tester, () => api.setTxLabel(faucetRow.key, faucetLabel));
  final secondRow = sendRow ?? txs.where((t) => t.key != faucetRow?.key).firstOrNull;
  if (secondRow != null) await io(tester, () => api.setTxLabel(secondRow.key, sendLabel));
  record('build: labels on two payments', faucetRow != null && secondRow != null, '${txs.length} rows');

  // Settings away from their defaults; a node and a relay added to the lists; a new name.
  s = containerOf(tester).read(deskProvider).settings;
  await io(
    tester,
    () => desk.saveSettings(
      s.copyWith(
        theme: ThemeChoice.light,
        payments: s.payments.copyWith(directQr: true, defaultMethod: MethodKind.directFile),
        advanced: s.advanced.withFeature(AdvancedFeature.serverDetails, true),
      ),
    ),
  );
  await io(tester, () => api.saveOutputPrefs(const OutputPrefs(strategy: SelectionStrategy.all, smartOutputs: false)));
  await go(tester, DeskRoute.settingsNode);
  await io(tester, () => containerOf(tester).read(deskServerListProvider(ServerKind.node).notifier).add(addedNode));
  await go(tester, DeskRoute.settingsReceiving);
  await io(tester, () => containerOf(tester).read(deskServerListProvider(ServerKind.relay).notifier).add(addedRelay));
  final account = containerOf(tester).read(deskProvider).account!;
  await io(tester, () => desk.renameWallet(account.id!, walletName));
  await settle(tester, ms: 1500);

  // What the restore phase must find again.
  await io(tester, desk.refresh);
  txs = await io(tester, api.transactions);
  final contacts = await io(tester, api.contacts);
  mine = await io(tester, pairApi.pairings);
  final invoices = await io(tester, api.invoices);
  final settingsNow = containerOf(tester).read(deskProvider).settings;
  final out = await io(tester, api.outputPrefs);
  final bal = await io(tester, api.balance);
  final expect = {
    'walletName': containerOf(tester).read(deskProvider).account?.name,
    'total': bal.spendable + bal.awaitingConfirmation + bal.locked + bal.immature,
    'txs': [for (final t in txs) txJson(t)],
    'contacts': [for (final c in contacts) {'name': c.name, 'address': c.epicbox ?? c.http ?? c.tor, 'favourite': c.favourite}],
    'pairings': [for (final p in mine) {'name': p.name, 'state': p.state.name, 'allowInvoices': p.allowInvoices}],
    'sent': [for (final r in invoices.sent) {'slate': r.slateId, 'state': r.state.name, 'message': r.message, 'amount': r.amount, 'byFile': r.byFile}],
    'toPay': [for (final i in invoices.toPay) {'slate': i.slateId, 'state': i.state.name, 'message': i.message, 'label': i.label, 'amount': i.amount}],
    'settings': {
      'theme': settingsNow.theme.name,
      'autoLock': settingsNow.autoLockMinutes,
      'directQr': settingsNow.payments.directQr,
      'defaultMethod': settingsNow.payments.defaultMethod.name,
      'features': [for (final f in settingsNow.advanced.features) f.name]..sort(),
      'seenAs': settingsNow.pairingSeenAs,
      'strategy': out.strategy.name,
      'smartOutputs': out.smartOutputs,
    },
    'nodeList': containerOf(tester).read(deskServerListProvider(ServerKind.node))?.entries,
    'relayList': containerOf(tester).read(deskServerListProvider(ServerKind.relay))?.entries,
    'bAddr': bAddr,
    'cAddr': cAddr,
  };
  await tester.runAsync(() => File(hbPath('hb-expect.json')).writeAsString(const JsonEncoder.withIndent(' ').convert(expect)));
  log('expect: ${txs.length} payments, ${contacts.length} contacts, ${mine.length} pairings, ${invoices.sent.length} requests, ${invoices.toPay.length} invoices, settings ${jsonEncode(expect['settings'])}');
  record('build: pairing seen-as name kept as a setting', settingsNow.pairingSeenAs == seenAs, settingsNow.pairingSeenAs);

  // Activity with the labels, then the export.
  await go(tester, DeskRoute.activity);
  await shot(tester, 'hb-build-04-activity');
  final shown = await exportUi(tester, 'F1.wfeh', shotName: 'hb-03-export-dialog');
  final words = shown ?? '';
  record('export: says it holds history, contacts, invoices and settings', RegExp('history.*contacts.*invoices.*settings').hasMatch(words), '');
  record('export: says the recovery phrase is not in it', words.contains('The recovery phrase'), '');
  record('export: says it cannot restore alone, phrase first', words.contains('cannot restore the wallet on its own') && words.contains('restore from the recovery phrase first, then import this file'), '');
  record('export: F1 written', File(hbPath('F1.wfeh')).existsSync(), '${File(hbPath('F1.wfeh')).lengthSync()} bytes');

  // What F1 holds, read by a twin of A; a version 1 file sealed by it; B's own backup.
  final secret = jsonDecode(File(hbPath('a-secret.json')).readAsStringSync()) as Map;
  final twinDir = await io(tester, () => Directory(hbPath('twin-a')).create(recursive: true));
  final twin = await io(tester, () => twinOf(secret['phrase'] as String, twinDir.path));
  final f1 = await io(tester, () => openFile(twin, hbPath('F1.wfeh')));
  final f1Contacts = (f1['contacts'] as List).cast<Map>();
  record('version 2', f1['version'] == 2, '${f1['version']}');
  record('the whole shared address book', f1Contacts.length >= contacts.length && [carol, dave].every((n) => f1Contacts.any((c) => c['name'] == n)), '${f1Contacts.length} contacts in file, ${contacts.length} in the app: ${f1Contacts.map((c) => c['name']).join(', ')}');
  record('the star', jsonEncode(f1['favourites'] ?? []).length > 2, 'favourites ${jsonEncode(f1['favourites'])}');
  record('issued and paid invoices', (f1['issued_invoices'] as Map? ?? {}).length >= 3 && (f1['paid_invoices'] as Map? ?? {}).isNotEmpty, 'issued ${(f1['issued_invoices'] as Map? ?? {}).length}, paid ${(f1['paid_invoices'] as Map? ?? {}).length}');
  record('the pairing', f1['pairings'] != null, '');
  record('the wallet name', jsonEncode(f1['wallet']).contains(walletName), jsonEncode(f1['wallet']));
  final fs = f1['settings'];
  record('the settings', fs is Map && jsonEncode(fs).contains('light'), fs is Map ? 'keys ${(fs['values'] ?? fs).keys.join(',')}': '$fs');
  record('no phrase, password or keys', !jsonEncode(f1).contains(secret['phrase'] as String) && !jsonEncode(f1).contains(password), '');
  final v1 = await io(tester, () => twin.sealAppData(payload: utf8.encode(jsonEncode(asVersion1(f1)))));
  await tester.runAsync(() => File(hbPath('V1.wfeh')).writeAsBytes(v1, flush: true));
  twin.dispose();
  final bFile = await io(tester, () => b.exportHistory());
  await tester.runAsync(() => File(hbPath('B.wfeh')).writeAsBytes(bFile, flush: true));
  record('build: version 1 file of A and B\'s backup written', File(hbPath('V1.wfeh')).existsSync() && File(hbPath('B.wfeh')).existsSync(), '');

  // A deleted in the app.
  await deleteA(tester, password, tag: ' (build)');
  await shot(tester, 'hb-build-05-deleted');
  record('build: no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
}

// ---- Phase 2: a new computer.

Future<void> restorePhase(WidgetTester tester) async {
  final secret = jsonDecode(File(hbPath('a-secret.json')).readAsStringSync()) as Map;
  final phrase = secret['phrase'] as String;
  final password = secret['password'] as String;
  final want = jsonDecode(File(hbPath('hb-expect.json')).readAsStringSync()) as Map<String, dynamic>;
  final total = want['total'] as int;
  await boot(tester, size: const Size(1400, 950), extra: [deskHistoryFilesProvider.overrideWithValue(files)]);
  await useFloonet(tester);

  // Step 4–5: restore from the phrase, then F1.
  await restoreA(tester, phrase, password, tag: ' 1');
  final api = apiOf(tester);
  final desk = containerOf(tester).read(deskProvider.notifier);
  await waitScan(tester, total, tag: ' 1');
  final before = containerOf(tester).read(deskProvider).settings;
  record('restore 1: settings at their defaults', before.theme == const DeskSettings().theme && before.autoLockMinutes == const DeskSettings().autoLockMinutes, 'theme ${before.theme.name}, auto-lock ${before.autoLockMinutes}');
  final r1 = await importUi(tester, hbPath('F1.wfeh'), shotName: 'hb-05-import-summary');
  log('import F1: ${r1.screen}');
  record('import F1: one summary', r1.summary.startsWith('Imported:'), r1.summary);
  record('import F1: payments, contacts, pairings, invoices and settings named', RegExp(r'payment').hasMatch(r1.summary) && r1.summary.contains('contact') && r1.summary.contains('pairing') && r1.summary.contains('invoice') && r1.summary.contains('settings'), r1.summary);
  record('import F1: no settings question after a restore', r1.settingsAsked == 0, '${r1.settingsAsked} asked');
  record('import F1: pairing question (use on this device)', r1.pairingAsked, '');
  await io(tester, desk.refresh);
  await checkAll(tester, want, 'F1');

  // Step 7: a setting changed here and different in the file asks once.
  final s = containerOf(tester).read(deskProvider).settings;
  await io(tester, () => desk.saveSettings(s.copyWith(theme: ThemeChoice.system)));
  await settle(tester, ms: 800);
  final r2 = await importUi(tester, hbPath('F1.wfeh'), shotName: 'hb-07-import-again');
  final themeAfter = containerOf(tester).read(deskProvider).settings.theme;
  record('settings conflict: "Use the settings from this file?" asked once', r2.settingsAsked == 1, '${r2.settingsAsked} asked; ${r2.summary}');
  record('settings conflict: Use the backup\'s takes the file\'s theme', themeAfter.name == want['settings']['theme'], themeAfter.name);

  // Step 9: another wallet's file is refused; nothing changes.
  final txsBefore = (await io(tester, api.transactions)).length;
  final contactsBefore = (await io(tester, api.contacts)).length;
  final r3 = await importUi(tester, hbPath('B.wfeh'), shotName: 'hb-09-other-wallet-refused');
  record('other wallet\'s file refused with a message', r3.refused != null, r3.refused ?? r3.screen);
  record('other wallet\'s file changes nothing', (await io(tester, api.transactions)).length == txsBefore && (await io(tester, api.contacts)).length == contactsBefore, '');

  // Step 6: restored rows edited in the UI travel in F2 and land on the same payments.
  await deleteA(tester, password, tag: ' 2');
  await restoreA(tester, phrase, password, tag: ' 2');
  final rows = await waitScan(tester, total, tag: ' 2');
  final restored = rows.where((t) => t.restored).toList();
  record('restore 2: payments found on chain (restored)', restored.length >= 2, '${restored.length} of ${rows.length}: ${restored.map((t) => t.key.substring(0, 10)).join(', ')}');
  final edited = restored.take(2).toList();
  final cAddr = want['cAddr'] as String;
  // The wallet has two restored rows: an export with only the first edited shows the
  // untouched second one left out of the file.
  bool inFileOf(List<Map<String, dynamic>> recs, Tx t) => recs.any((r) => (r['output_commits'] as List? ?? const []).any((c) => t.key == 'c:$c'));
  Future<List<Map<String, dynamic>>> recordsOf(String name, String twinName) async {
    final dir = await io(tester, () => Directory(hbPath(twinName)).create(recursive: true));
    final twin = await io(tester, () => twinOf(phrase, dir.path));
    final m = await io(tester, () => openFile(twin, hbPath(name)));
    twin.dispose();
    return (m['txs'] as List).cast<Map<String, dynamic>>();
  }
  if (edited.length == 2) {
    await editRestored(tester, edited[0], label: editLabels[0], note: editNotes[0], via: editVia[0], from: cAddr);
    await exportUi(tester, 'F2-one-edited.wfeh');
    final one = await recordsOf('F2-one-edited.wfeh', 'twin-a1');
    record('F2 (one edited): the edited restored row kept', inFileOf(one, edited[0]), '${one.length} records');
    record('F2 (one edited): the untouched restored row left out', !inFileOf(one, edited[1]), '${edited[1].key.substring(0, 10)}… in file: ${inFileOf(one, edited[1])}');
    await editRestored(tester, edited[1], label: editLabels[1], note: editNotes[1], via: editVia[1]);
  } else {
    for (final (i, t) in edited.indexed) {
      await editRestored(tester, t, label: editLabels[i], note: editNotes[i], via: editVia[i], from: i == 0 ? cAddr : null);
    }
  }
  await io(tester, desk.refresh);
  final afterEdit = await io(tester, api.transactions);
  for (final (i, t) in edited.indexed) {
    final now = afterEdit.where((x) => x.key == t.key).firstOrNull;
    record('edit ${i + 1}: label, method, note${i == 0 ? ', sender' : ''} saved on ${t.key.substring(0, 10)}…', now?.labelText == editLabels[i] && now?.note == editNotes[i] && now?.transport == editVia[i] && (i != 0 || now?.counterparty == cAddr), now == null ? 'row gone' : jsonEncode(txJson(now)));
  }
  await go(tester, DeskRoute.activity);
  await shot(tester, 'hb-06-restored-edited');
  await exportUi(tester, 'F2.wfeh');
  final recs = await recordsOf('F2.wfeh', 'twin-a2');
  bool inFile(Tx t) => inFileOf(recs, t);
  final untouched = restored.skip(2).toList();
  record('edited restored rows kept', edited.every(inFile), '${recs.length} records; ${edited.map((t) => inFile(t)).join(',')}');
  record('untouched restored rows left out', untouched.every((t) => !inFile(t)), '${untouched.where(inFile).length} of ${untouched.length} untouched in the file');
  await deleteA(tester, password, tag: ' 3');
  await restoreA(tester, phrase, password, tag: ' 3');
  final rows3 = await waitScan(tester, total, tag: ' 3');
  record('restore 3: the same payments again (same commitments)', edited.every((t) => rows3.any((x) => x.key == t.key && x.amount == t.amount && x.height == t.height)), rows3.where((t) => t.restored).map((t) => t.key.substring(0, 10)).join(', '));
  final r4 = await importUi(tester, hbPath('F2.wfeh'), shotName: 'hb-06-import-f2');
  record('import F2: summary', r4.summary.startsWith('Imported:'), r4.summary);
  await io(tester, desk.refresh);
  final back = await io(tester, api.transactions);
  for (final (i, t) in edited.indexed) {
    final now = back.where((x) => x.key == t.key).firstOrNull;
    record('F2 back: edits on the same payment ${t.key.substring(0, 10)}… (amount ${formatEpic(t.amount)}, height ${t.height})', now?.labelText == editLabels[i] && now?.note == editNotes[i] && now?.transport == editVia[i] && (i != 0 || now?.counterparty == cAddr), now == null ? 'row gone' : jsonEncode(txJson(now)));
  }
  await go(tester, DeskRoute.activity);
  await shot(tester, 'hb-06-f2-back');

  // Step 8: a version 1 file of A still imports (here through the restored wallet's offer).
  await deleteA(tester, password, tag: ' 4');
  keepOffer = true;
  await restoreA(tester, phrase, password, offer: 'leave', tag: ' 4');
  await waitScan(tester, total, tag: ' 4');
  keepOffer = false;
  final offered = find.byKey(const ValueKey('history-import-offer')).evaluate().isNotEmpty;
  record('restore 4: Overview offers to import a history backup', offered, '');
  if (offered) {
    await tapText(tester, RegExp(r'^Import'), last: true);
  } else {
    await go(tester, DeskRoute.settingsAccount);
    await tapRowButton(tester, 'Import…', opens: 'Choose file…');
  }
  final r5 = await importUi(tester, hbPath('V1.wfeh'), shotName: 'hb-08-import-v1', fromOffer: true);
  record('version 1 file imports', r5.summary.startsWith('Imported:') && r5.refused == null, r5.summary);
  await io(tester, desk.refresh);
  final v1Txs = await io(tester, api.transactions);
  final v1Contacts = await io(tester, api.contacts);
  record('version 1: labels back', v1Txs.any((t) => t.labelText == faucetLabel || t.labelText == sendLabel), v1Txs.map((t) => t.labelText).nonNulls.join(', '));
  record('version 1: contacts back', [carol, dave].every((n) => v1Contacts.any((c) => c.name == n)), v1Contacts.map((c) => c.name).join(', '));
  record('restore: no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
}

/// Activity › the row › Add details (method, sender, note) and Add label, as a user does.
Future<void> editRestored(WidgetTester tester, Tx t, {required String label, required String note, required String via, String? from}) async {
  await go(tester, DeskRoute.activity, t.id);
  await tapText(tester, 'Add details', last: true);
  await waitText(tester, 'Method');
  tester.widget<ESegmented<String>>(find.descendant(of: find.byType(TxDetailsDialog), matching: find.byType(ESegmented<String>))).onChanged(via);
  await settle(tester);
  final fields = find.descendant(of: find.byType(TxDetailsDialog), matching: find.byType(EditableText));
  if (from != null) await tester.enterText(fields.at(0), from);
  await tester.enterText(fields.at(1), note);
  await settle(tester);
  await shot(tester, 'hb-06-details-${t.id}');
  await tapText(tester, 'Save', last: true);
  await settle(tester, ms: 1500);
  await tapText(tester, RegExp(r'^(Add label|Edit label)$'), last: true);
  await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Add label').last, label);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester, ms: 1500);
}

/// Everything the build phase left in hb-expect.json, as the restored wallet shows it.
Future<void> checkAll(WidgetTester tester, Map<String, dynamic> want, String tag) async {
  final api = apiOf(tester);
  final txs = await io(tester, api.transactions);
  final wantTxs = (want['txs'] as List).cast<Map<String, dynamic>>();
  for (final w in wantTxs.where((w) => w['label'] != null)) {
    final got = txs.where((t) => t.amount == w['amount'] && t.labelText == w['label']).firstOrNull;
    record('$tag: label "${w['label']}" back', got != null, got == null ? txs.map((t) => '${formatEpic(t.amount)}:${t.labelText}').join(', ') : got.key.substring(0, 10));
  }
  final withMessage = txs.where((t) => t.amount == epic(1.5) && t.direction == TxDirection.sent).firstOrNull;
  record('$tag: the payment to B with its counterparty', withMessage?.counterparty != null, '${withMessage?.counterparty?.replaceAll(RegExp(r'^[^@]+'), '<id>')} ${withMessage?.contactName}');
  final invoiceRow = txs.where((t) => t.isInvoice && t.direction == TxDirection.sent).firstOrNull;
  record('$tag: the paid invoice is in history as an invoice', invoiceRow != null, '${invoiceRow?.state.name} ${formatEpic(invoiceRow?.amount ?? 0)}');
  record('$tag: every payment of the file is listed', txs.length >= wantTxs.length, '${txs.length} rows, ${wantTxs.length} at export');

  final contacts = await io(tester, api.contacts);
  final wantContacts = (want['contacts'] as List).cast<Map<String, dynamic>>();
  record('$tag: every contact back', wantContacts.every((w) => contacts.any((c) => c.name == w['name'])), contacts.map((c) => c.name).join(', '));
  record('$tag: the star back', contacts.any((c) => c.name == carol && c.favourite), contacts.where((c) => c.favourite).map((c) => c.name).join(', '));

  final pairings = await io(tester, containerOf(tester).read(deskPairingApiProvider).pairings);
  final p = pairings.where((p) => p.name == bName).firstOrNull;
  record('$tag: the pairing back', p != null, pairings.map((p) => '${p.name}:${p.state.name}').join(', '));
  record('$tag: the pairing allows invoices', p?.allowInvoices ?? false, '');

  final book = await io(tester, api.invoices);
  final wantSent = (want['sent'] as List).cast<Map<String, dynamic>>();
  for (final w in wantSent) {
    final got = book.sent.where((r) => r.slateId == w['slate']).firstOrNull;
    if (w['state'] == RequestState.waiting.name) {
      // Open at export: the restored wallet cannot finish it, so it is history only, an
      // Activity row from the backup, never a request to act on.
      final row = txs.where((t) => t.slateId == w['slate']).firstOrNull;
      record('$tag: open request "${w['message']}" not listed under Requests', got == null, '${got?.state.name}');
      record('$tag: open request "${w['message']}" is an Activity row with its amount and message', row != null && row.amount == w['amount'] && (row.message ?? '').contains(w['message'] as String), row == null ? 'no row' : '${row.state.name}, fromBackup ${row.fromBackup}, ${formatEpic(row.amount)}, message ${row.message}');
      // Never paid: it reads as an amount asked, not as money that arrived.
      record('$tag: open request "${w['message']}" not shown as paid', row != null && row.state == TxState.waitingRecipient, '${row?.state.name}');
      continue;
    }
    record('$tag: request "${w['message']}" back (${w['state']})', got != null && got.message == w['message'], '${got?.state.name} ${got?.message}');
  }
  final wantPay = (want['toPay'] as List).cast<Map<String, dynamic>>();
  for (final w in wantPay) {
    final got = book.toPay.where((i) => i.slateId == w['slate']).firstOrNull;
    record('$tag: invoice "${w['message']}" back (${w['state']})', got != null && got.message == w['message'], '${got?.state.name} ${got?.message}');
  }
  await go(tester, DeskRoute.invoices, InvoicesTab.issue);
  await shot(tester, 'hb-05-requests');
  record('$tag: Invoices › Requests lists the ended requests', hasText(withdrawnMessage) && hasText(declinedMessage), texts().where((t) => t.startsWith('RC')).join(' | '));
  // To pay lists only invoices waiting; a paid one opens by its slate id (as from Activity).
  final paidSlate = wantPay.where((w) => w['message'] == orderMessage).firstOrNull?['slate'] as String?;
  await go(tester, DeskRoute.invoices, paidSlate ?? InvoicesTab.pay);
  await settle(tester, ms: 1500);
  await shot(tester, 'hb-05-paid-invoice');
  record('$tag: Invoices shows the paid invoice opened from history', hasText(orderMessage), texts().where((t) => t.contains('RC')).take(6).join(' | '));
  await go(tester, DeskRoute.contacts);
  await shot(tester, 'hb-05-contacts');
  await go(tester, DeskRoute.activity);
  await shot(tester, 'hb-05-activity');
  record('$tag: Activity shows the labels', hasText(faucetLabel) || hasText(sendLabel), '');

  final ws = want['settings'] as Map<String, dynamic>;
  final s = containerOf(tester).read(deskProvider).settings;
  final out = await io(tester, api.outputPrefs);
  void same(String what, Object? got, Object? exp) => record('$tag: setting $what back', jsonEncode(got) == jsonEncode(exp), 'now ${jsonEncode(got)}, file ${jsonEncode(exp)}');
  same('theme', s.theme.name, ws['theme']);
  same('auto-lock', s.autoLockMinutes, ws['autoLock']);
  same('QR method on', s.payments.directQr, ws['directQr']);
  same('default method', s.payments.defaultMethod.name, ws['defaultMethod']);
  same('Advanced switches', [for (final f in s.advanced.features) f.name]..sort(), ws['features']);
  same('Pairing seen-as name', s.pairingSeenAs, ws['seenAs']);
  same('send strategy', out.strategy.name, ws['strategy']);
  same('smart outputs', out.smartOutputs, ws['smartOutputs']);
  await go(tester, DeskRoute.settingsNode);
  final nodes = containerOf(tester).read(deskServerListProvider(ServerKind.node))?.entries ?? const [];
  record('$tag: the added node is in the list', nodes.contains(addedNode), nodes.join(', '));
  await go(tester, DeskRoute.settingsReceiving);
  final relays = containerOf(tester).read(deskServerListProvider(ServerKind.relay))?.entries ?? const [];
  record('$tag: the added relay is in the list', relays.contains(addedRelay), relays.join(', '));
  final name = containerOf(tester).read(deskProvider).account?.name;
  record('$tag: the wallet name back', name == want['walletName'], '$name');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: history backup, build A and export', (tester) async {
    captureErrors();
    await buildPhase(tester);
  }, skip: phase != 'build', timeout: const Timeout(Duration(minutes: 90)));
  testWidgets('desktop: history backup, restore A and import', (tester) async {
    captureErrors();
    await restorePhase(tester);
  }, skip: phase != 'restore', timeout: const Timeout(Duration(minutes: 90)));
}
