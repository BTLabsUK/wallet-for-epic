// SPDX-License-Identifier: Apache-2.0
// Live round trip of the history backup (.wfeh v2) on a phone: the real app on the device, the
// real LEPIC core, the floonet node and relay, the floonet faucet and a second LEPIC wallet in
// this process. Nothing is mocked but the system file dialogs (the file stays in memory).
//
//   adb -s emulator-5556 uninstall uk.btlabs.btwallet   # a fresh app, no state
//   flutter test -d emulator-5556 integration_test/history_backup_phone_test.dart \
//     [--dart-define-from-file=<v1.json>]
//
// The floonet chain moves only while floo-miner runs. <v1.json> (mode 600, never committed)
// names a version 1 file made by a released app: WFE_V1_FILE (base64), WFE_V1_PHRASE (the
// throwaway mainnet wallet it came from) and WFE_V1_START (a height to scan from); without it
// that test is skipped. Every check prints one `RC PASS|FAIL | step | evidence` line;
// screenshots go to the app's external files folder (`shots/`), pulled with adb. Throwaway
// wallets only; a recovery phrase is never printed.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/pairing_providers.dart' show pairingSeenAsProvider;
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/server_list_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/invoices_screen.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_sections.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart' show settingsGroupKey;
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lepic/lepic.dart' as lepic;
// Not exported by package:lepic/lepic.dart.
import 'package:lepic/src/rust/api/policy.dart' show HostPolicy;
import 'package:path_provider/path_provider.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'live_hosts.dart';

const _pin = '123456';
const _faucet = liveFaucet;
const _v1File = String.fromEnvironment('WFE_V1_FILE');
const _v1Phrase = String.fromEnvironment('WFE_V1_PHRASE');
const _v1Start = String.fromEnvironment('WFE_V1_START');

final _epic = BigInt.from(100000000);
BigInt _ep(num n) => BigInt.from((n * 100000000).round());

// ---- Results and screenshots.

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
  if (ro == null) return;
  await tester.runAsync(() async {
    final dir = _shotsDir ??= Directory('${(await getExternalStorageDirectory())!.path}/shots');
    await dir.create(recursive: true);
    final img = await ro.toImage(pixelRatio: 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    await File('${dir.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
  });
}

// ---- Finding and driving the screens.

/// Lets real time pass (native calls, network) while pumping frames.
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

/// One line of what is on screen; never called while a phrase shows.
String screen() => texts().take(40).join(' | ');

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 90),
  String what = 'condition',
}) async {
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
    // A lazy list builds what is below the fold only once scrolled there.
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

/// The text field labelled [label] (or with that hint).
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

/// Back to the shell, with nothing pushed over it.
Future<void> toShell(WidgetTester tester) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.popUntil((r) => r.isFirst);
  await settle(tester, ms: 800);
}

Future<void> push(WidgetTester tester, Widget page) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  // Not awaited: the route stays until popped.
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

/// The one-time "Before you import" warning, where this build has it.
Future<void> passImportWarning(WidgetTester tester) async {
  if (!hasText('Before you import')) return;
  await tapText(tester, 'I have a backup of every wallet');
  final go = find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton));
  if (go.evaluate().isNotEmpty) await tapF(tester, go.last);
  await settle(tester, ms: 600);
}

// ---- The app.

/// The system file dialogs, replaced: a save or share keeps the bytes, a pick hands out [next].
class _MemoryHistoryFiles implements HistoryFiles {
  final List<({String name, Uint8List bytes})> saved = [];
  Uint8List? next;

  @override
  bool get canShare => true;

  @override
  Future<bool> save({required String name, required Uint8List bytes, required String dialogTitle}) async {
    saved.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<bool> share({required String name, required Uint8List bytes}) async {
    saved.add((name: name, bytes: bytes));
    return true;
  }

  @override
  Future<Uint8List?> pick({required String dialogTitle}) async => next;
}

final _files = _MemoryHistoryFiles();

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
        historyFilesProvider.overrideWithValue(_files),
      ],
      child: RepaintBoundary(key: _shotKey, child: const WalletApp()),
    ),
  );
  await settle(tester, ms: 1500);
  return ProviderScope.containerOf(tester.element(find.byType(WalletApp)));
}

WalletSession sessionOf(ProviderContainer c) => c.read(sessionProvider)!;

Future<void> enterPinTwice(WidgetTester tester) async {
  await typeInto(tester, fieldF('PIN'), _pin);
  await settle(tester, ms: 600);
  await typeInto(tester, fieldF('Repeat PIN'), _pin);
}

/// Welcome › Create a new wallet, the PIN twice, Home.
Future<void> createWallet(WidgetTester tester) async {
  await waitText(tester, 'Create a new wallet', timeout: const Duration(minutes: 2));
  await tapText(tester, 'Create a new wallet');
  await enterPinTwice(tester);
  await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 3), what: 'home');
  await skipTour(tester);
}

/// Welcome › Restore from a phrase: the phrase, an optional start height, the PIN twice, the
/// scan. Ends on the restore's history backup offer.
Future<void> restoreWallet(WidgetTester tester, String phrase, {String? startHeight}) async {
  // Welcome: Settings › Wallet has a "Restore from a phrase" row too.
  await waitText(tester, 'Create a new wallet', timeout: const Duration(minutes: 2));
  // A tap during the page transition is lost: tap until the phrase field shows.
  for (var i = 0; i < 6 && fieldF('Recovery phrase').evaluate().isEmpty; i++) {
    await settle(tester, ms: 1000);
    if (hasText('Restore from phrase')) await tapText(tester, 'Restore from phrase');
    await settle(tester, ms: 1500);
  }
  await typeInto(tester, fieldF('Recovery phrase'), phrase);
  if (startHeight != null) {
    await tapText(tester, 'Start from a month or height');
    if (hasText('Block height')) await tapText(tester, 'Block height');
    await typeInto(tester, fieldF('Start height (optional)'), startHeight);
  }
  await tapText(tester, 'Continue', last: true);
  await enterPinTwice(tester);
  await waitText(tester, 'Import wallet data', timeout: const Duration(minutes: 15));
}

/// Home › Settings › Wallet.
Future<void> openWalletSettings(WidgetTester tester) async {
  await toShell(tester);
  await tapF(tester, find.byTooltip('Settings'));
  await settle(tester, ms: 800);
  await tapF(tester, find.byKey(settingsGroupKey(SettingsSection.wallet)));
  await settle(tester, ms: 800);
}

/// Settings › Wallet › Delete this wallet: the checkbox, "delete", the PIN. Ends on Welcome.
Future<void> deleteWalletUi(WidgetTester tester) async {
  await openWalletSettings(tester);
  await tapText(tester, 'Delete wallet');
  await tapText(tester, 'I have written down my recovery phrase');
  await typeInto(tester, find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'delete');
  await tapF(tester, find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(OutlinedButton, 'Delete wallet')));
  await typeInto(tester, fieldF('PIN'), _pin);
  await waitText(tester, 'Create a new wallet', timeout: const Duration(minutes: 2));
}

/// Settings › Wallet › Export wallet data › Save to device: the file, and the sheet's text.
Future<(Uint8List, String)> exportUi(WidgetTester tester, String shotName) async {
  await openWalletSettings(tester);
  final before = _files.saved.length;
  await tapText(tester, 'Export wallet data');
  await waitText(tester, 'Save to device');
  final sheet = texts().join(' ');
  await shot(tester, shotName);
  await tapText(tester, 'Save to device');
  await pumpUntil(tester, () => _files.saved.length > before, what: 'the saved file');
  await settle(tester, ms: 800);
  return (_files.saved.last.bytes, sheet);
}

/// What an import ended with: the summary's text, and whether the settings question came.
typedef ImportSeen = ({String summary, bool settingsAsked, bool pairingAsked, String error});

/// Answers what an import asks, in order: the settings question ([useBackupSettings]), the
/// summary, the pairings question (Use them here).
Future<ImportSeen> answerImport(WidgetTester tester, String prefix, {bool useBackupSettings = true}) async {
  var summary = '';
  var settingsAsked = false;
  var pairingAsked = false;
  var error = '';
  final end = DateTime.now().add(const Duration(minutes: 3));
  while (DateTime.now().isBefore(end)) {
    await settle(tester, ms: 400);
    await passImportWarning(tester);
    if (hasText('Use the settings from this file?')) {
      settingsAsked = true;
      await shot(tester, '$prefix-settings-question');
      note('$prefix settings question: ${textMatching(RegExp('differ'))}');
      await tapText(tester, useBackupSettings ? 'Use the file’s' : 'Keep mine');
      continue;
    }
    if (hasText('Wallet data imported')) {
      summary = textMatching(RegExp(r'^(Imported:|The file held nothing new)'));
      await shot(tester, '$prefix-summary');
      await tapF(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('OK')));
      continue;
    }
    if (hasText('Use your contacts on this device?')) {
      pairingAsked = true;
      await shot(tester, '$prefix-pairing-question');
      await tapText(tester, 'Use them here');
      continue;
    }
    if (hasText('Could not import the wallet data')) {
      error = textMatching('Could not import the wallet data');
      break;
    }
    // Done once nothing asks any more and the summary was seen.
    if (summary.isNotEmpty && find.byType(AlertDialog).evaluate().isEmpty) {
      await settle(tester, ms: 1500);
      if (find.byType(AlertDialog).evaluate().isEmpty) break;
    }
  }
  return (summary: summary, settingsAsked: settingsAsked, pairingAsked: pairingAsked, error: error);
}

// ---- The other wallet, the faucet, the chain.

class _MemoryLepicStore implements lepic.SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Opens a history file with the wallet of [phrase], as only that wallet can: the payload.
Future<HistoryPayload> decodeFile(WidgetTester tester, String phrase, Uint8List file, Chain chain) async {
  final payload = await tester.runAsync(() async {
    final dir = await (await getTemporaryDirectory()).createTemp('wfe-decode-');
    final preset = networkPresets.firstWhere((p) => p.chain == chain);
    final w = await lepic.EpicWallet.create(
      runtime: lepic.LepicRuntime(logLevel: lepic.LogLevel.warn),
      config: lepic.WalletConfig(policy: const HostPolicy(), torWanted: false, hostFeatures: 0, 
        dataDir: dir.path,
        chain: chain == Chain.mainnet ? lepic.Chain.mainnet : lepic.Chain.floonet,
        nodeUrl: 'http://127.0.0.1:9',
        epicboxDomain: preset.epicboxDomain,
        epicboxPort: preset.epicboxPort,
        onionRoutes: const [], tuning: LepicWalletService.netTuningOf(appConfig), offline: false,
      ),
      store: lepic.lepicSecretStore(_MemoryLepicStore()),
      mnemonic: phrase,
      password: 'decode-only-${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      return HistoryPayload.decode(await w.openAppData(file: file));
    } finally {
      w.dispose();
      await dir.delete(recursive: true);
    }
  });
  return payload!;
}

/// Claims 10 EPIC from the floonet faucet for [address]; retries a cooldown or a failed payout.
Future<bool> claimFaucet(WidgetTester tester, String address, String who) async {
  for (var attempt = 1; attempt <= 16; attempt++) {
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
    // A cooldown says how long; asking earlier only pushes it out.
    final wait = RegExp(r'wait (\d+)s').firstMatch(status ?? '')?.group(1);
    await settle(tester, ms: wait != null ? (int.parse(wait) + 4) * 1000 : 60000);
  }
  return false;
}

/// Polls [check] until it gives a value, pumping frames between tries.
Future<T?> waitFor<T>(
  WidgetTester tester,
  String what,
  Future<T?> Function() check, {
  Duration timeout = const Duration(minutes: 10),
  int everyMs = 5000,
}) async {
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

Future<BigInt> spendable(WidgetTester tester, WalletSession s) async =>
    (await tester.runAsync(() => s.summary(refresh: true, minimumConfirmations: liveMinConfirmations)))!.spendable;

Future<List<TxEntry>> txs(WidgetTester tester, WalletSession s, {bool refresh = false}) async =>
    (await tester.runAsync(() => s.transactions(refresh: refresh)))!;

String _row(TxEntry t) =>
    '${t.key.length > 14 ? t.key.substring(0, 14) : t.key} ${t.kind.name}/${t.status.name}/${t.source.name} '
    '+${t.amountCredited} -${t.amountDebited} h${t.blockHeight} label=${t.label} note=${t.note} from=${t.counterparty} via=${t.transport}';

/// The output commitments of [t], the key a scan finds it by.
Set<String> commitsOf(TxEntry t) => {...t.outputCommits};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    // flutter test uninstalls the app when it ends: the host pulls the shots meanwhile.
    await Future<void>.delayed(const Duration(seconds: 20));
    // ignore: avoid_print
    print('RC SUMMARY | ${_fails.isEmpty ? 'all passed' : 'failed: ${_fails.join('; ')}'}');
  });

  // Step 8 (older format): a version 1 file the released 26.10.16 app wrote for a throwaway
  // mainnet wallet (2 contacts, one starred) imports into this build once that phrase is
  // restored: the contacts and the star come back.
  testWidgets('phone: a version 1 file from 26.10.16 imports after a restore', (tester) async {
    final c = await boot(tester, Chain.mainnet);
    await restoreWallet(tester, _v1Phrase, startHeight: _v1Start.isEmpty ? null : _v1Start);
    await shot(tester, 'v1-01-import-offer');
    final s = sessionOf(c);
    record('v1: the restored wallet is on mainnet', c.read(walletConfigProvider)?.chain == Chain.mainnet);
    final v1 = await decodeFile(tester, _v1Phrase, base64Decode(_v1File), Chain.mainnet);
    // 26.10.16 wrote stars into the wallet's archive only, never into the file.
    final v1Stars = v1.favourites.isNotEmpty;
    record('v1: the file is a version 1 payload from 26.10.16', v1.version == 1,
        'v${v1.version}, app ${v1.appVersion}, ${v1.contacts.length} contacts, ${v1.favourites.length} stars, ${v1.txs.length} records');
    _files.next = base64Decode(_v1File);
    await tapText(tester, 'Import wallet data');
    final seen = await answerImport(tester, 'v1-02');
    record('v1: one summary, no error', seen.summary.isNotEmpty && seen.error.isEmpty, '${seen.summary} ${seen.error}');
    record('v1: the summary names 2 contacts${v1Stars ? ' and 1 starred contact' : ''}', seen.summary.contains('2 contacts') && (!v1Stars || seen.summary.contains('1 starred contact')), seen.summary);
    record('v1: no settings question (a v1 file has no settings)', !seen.settingsAsked);
    final contacts = (await tester.runAsync(() => s.contacts()))!;
    final stars = (await tester.runAsync(() => s.favouriteContacts()))!.toSet();
    final alice = contacts.where((x) => x.name == 'Old Alice').firstOrNull;
    final bruno = contacts.where((x) => x.name == 'Old Bruno').firstOrNull;
    record('v1: both contacts are back with their addresses', alice?.http == 'https://alice.example.org' && bruno?.http == 'https://bruno.example.net', contacts.map((x) => '${x.name}=${x.address}').join(', '));
    if (v1Stars) {
      record('v1: Old Bruno is starred, Old Alice is not', bruno != null && stars.contains(bruno.id) && (alice == null || !stars.contains(alice.id)), 'stars ${stars.length}');
    } else {
      note('v1: the 26.10.16 file carries no stars (that app kept them out of the file), so none can come back; stars here ${stars.length}');
    }
    await toShell(tester);
    await push(tester, const ContactsScreen());
    await shot(tester, 'v1-03-contacts');
    record('v1: Contacts shows both', hasText('Old Alice') && hasText(RegExp('Old Bruno')), screen());
    await toShell(tester);
    c.read(sessionProvider.notifier).lock();
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester, ms: 1000);
  }, skip: _v1File.isEmpty || _v1Phrase.isEmpty, timeout: const Timeout(Duration(minutes: 30)));

  testWidgets('phone: the history backup brings a restored wallet back', (tester) async {
    final c = await boot(tester, Chain.floonet);

    // ---- 1. Wallet A, fresh, on floonet; its phrase stays in this process only.
    await createWallet(tester);
    var a = sessionOf(c);
    final config = c.read(walletConfigProvider)!;
    record('A is a floonet wallet', config.chain == Chain.floonet, config.nodeUrl);
    final phrase = (await tester.runAsync(() => c.read(vaultProvider).mnemonic(a, config, _pin)))!;
    record('A has a 24-word phrase', phrase.split(' ').length == 24);
    final aAddress = (await tester.runAsync(() => a.epicboxAddress()))!;

    // Wallet B, headless in this process, on the same chain and relay; it listens.
    final bDir = (await tester.runAsync(() async => (await getTemporaryDirectory()).createTemp('wfe-b-')))!;
    final b = (await tester.runAsync(
      () => LepicWalletService(secrets: MemorySecretStore()).create(
        config: floonetPreset.config(dataDir: bDir.path, nodeUrl: floonetPreset.nodeUrl),
        password: 'b-${DateTime.now().microsecondsSinceEpoch}',
      ),
    ))!;
    final bListener = b.startListener().listen((_) {}, onError: (Object e) => note('B listener: ${e.runtimeType}'));
    addTearDown(() async {
      // Never wait long on the other wallet's listener or folder: the checks are done.
      await bListener.cancel().timeout(const Duration(seconds: 10), onTimeout: () => note('B listener did not stop in 10 s'));
      b.dispose();
      try {
        await bDir.delete(recursive: true).timeout(const Duration(seconds: 10));
      } catch (e) {
        note('B folder left: ${e.runtimeType}');
      }
    });
    final bAddress = (await tester.runAsync(() => b.epicboxAddress()))!;

    // ---- Funding: two faucet payments for A (two coins, so two payments go out without
    // waiting on change), one for B.
    final tip0 = (await tester.runAsync(() => a.nodeTipFor(config: config)))!;
    note('floonet tip at start ${tip0.height}');
    record('faucet paid A (1)', await claimFaucet(tester, aAddress, 'A1'));
    record('faucet paid B', await claimFaucet(tester, bAddress, 'B'));
    record('faucet paid A (2)', await claimFaucet(tester, aAddress, 'A2'));
    final funded = await waitFor(tester, 'A spendable 20 EPIC', () async {
      final v = (await a.summary(refresh: true, minimumConfirmations: liveMinConfirmations)).spendable;
      return v >= _ep(20) ? v : null;
    }, timeout: const Duration(minutes: 30), everyMs: 15000);
    record('A has 20 EPIC spendable after 3 confirmations', funded != null, '$funded');
    final bFunded = await waitFor(tester, 'B spendable', () async {
      final v = (await b.summary(refresh: true, minimumConfirmations: liveMinConfirmations)).spendable;
      return v >= _ep(10) ? v : null;
    }, timeout: const Duration(minutes: 10), everyMs: 15000);
    record('B has 10 EPIC spendable', bFunded != null, '$bFunded');

    // ---- 2. History: the Experimental switches, a contact for B, the pairing, payments.
    // Read again at each use: the providers rebuild when the wallet changes.
    AppSettingsNotifier settings() => c.read(appSettingsProvider.notifier);
    ContactsNotifier contactsN() => c.read(contactsProvider.notifier);
    await tester.runAsync(() async {
      await settings().setExperimental(AdvancedFeature.pairing, true);
      await settings().setExperimental(AdvancedFeature.invoices, true);
    });
    await settle(tester, ms: 800);
    final ben = (await tester.runAsync(() => contactsN().save(Contact(id: '', name: 'Ben Shop', address: bAddress))))!;
    final carol = (await tester.runAsync(() => contactsN().save(Contact(id: '', name: 'Carol Link', address: 'https://carol.example.org'))))!;
    final dave = (await tester.runAsync(() => contactsN().save(Contact(id: '', name: 'Dave Link', address: 'https://dave.example.net:3415'))))!;
    await tester.runAsync(() => c.read(favouriteContactsProvider.notifier).set(carol.id, true));
    record('3 contacts saved, Carol starred', ben.id.isNotEmpty && carol.id.isNotEmpty && dave.id.isNotEmpty);

    // Pairing: B invites, A answers (as "Phone A", invoices allowed, attached to Ben Shop).
    final invite = (await tester.runAsync(() => b.pairing.standingCode(name: 'Shop B')))!;
    final preview = (await tester.runAsync(() => a.pairing.openInvite(invite.inviteLink!)))!;
    final answer = (await tester.runAsync(() => a.pairing.acceptInvite(token: preview.token, name: 'Phone A', allowInvoices: true, contactId: ben.id)))!;
    final paired = await waitFor(tester, 'pairing answered', () async {
      await b.pairing.collect(trigger: PairingCollectTrigger.pull);
      await a.pairing.collect(trigger: PairingCollectTrigger.pull);
      final mine = await a.pairing.pairing(answer.id);
      final theirs = await b.pairing.pairing(invite.id);
      return mine != null && theirs != null && mine.state == PairingState.paired && theirs.state == PairingState.paired ? mine : null;
    }, timeout: const Duration(minutes: 4), everyMs: 3000);
    record('A and B paired over the relay', paired != null);
    final aCheck = await tester.runAsync(() => a.pairing.checkWords(answer.id, PairingCheck.match));
    final bCheck = await tester.runAsync(() => b.pairing.checkWords(invite.id, PairingCheck.match));
    record('both sides verified', aCheck?.state == PairingState.verified && bCheck?.state == PairingState.verified, '${aCheck?.state.name} ${bCheck?.state.name}');
    await tester.runAsync(() => a.pairing.setAllowInvoices(answer.id, true));
    await tester.runAsync(() => b.pairing.setAllowInvoices(invite.id, true));

    // A pays B 1 EPIC over Epicbox, with a message.
    final sent = (await tester.runAsync(() => a.sendEpicbox(amount: _epic, minimumConfirmations: liveMinConfirmations, address: bAddress, message: 'phone test: to B')))!;
    final sentDone = await waitFor(tester, 'the send to B finalized', () async {
      final t = (await a.transactions(refresh: true)).where((t) => t.slateId == sent.slateId).firstOrNull;
      return t != null && t.status != TxStatus.awaitingRecipient ? t : null;
    }, timeout: const Duration(minutes: 5));
    record('A paid B over Epicbox', sentDone != null, sentDone == null ? '' : _row(sentDone));

    // B asks A for 0.5 EPIC through the pairing; A pays it (an invoice paid).
    final asked = (await tester.runAsync(() => b.pairing.requestPayment(id: invite.id, amount: _ep(0.5), message: 'Phone test order')))!;
    final waiting = await waitFor(tester, 'B\'s invoice parked at A', () async {
      await a.collectInvoices();
      return (await a.pendingInvoices()).where((i) => i.slateId == asked.slateId).firstOrNull;
    }, timeout: const Duration(minutes: 4), everyMs: 4000);
    record('B\'s request waits at A', waiting != null);
    final paidInv = waiting == null ? null : await tester.runAsync(() => a.payInvoice(slateId: asked.slateId, amount: _ep(0.5)));
    record('A paid B\'s invoice', paidInv != null, '${paidInv?.status.name}');
    final bPaid = await waitFor(tester, 'B finalized the invoice', () async {
      await b.pairing.collect(trigger: PairingCollectTrigger.pull);
      await b.collectInvoices();
      await b.drainPayments();
      final i = await b.issuedInvoice(slateId: asked.slateId);
      return i?.state == IssuedInvoiceState.paid ? i : null;
    }, timeout: const Duration(minutes: 4), everyMs: 4000);
    record('B saw its invoice paid', bPaid != null);

    // A asks B for 0.3 EPIC and withdraws it (an ended request).
    final lunch = (await tester.runAsync(() => a.pairing.requestPayment(id: answer.id, amount: _ep(0.3), message: 'Phone lunch')))!;
    final withdrawn = await tester.runAsync(() => a.withdrawInvoice(slateId: lunch.slateId));
    record('A\'s request to B withdrawn', withdrawn?.state == IssuedInvoiceState.withdrawn, '${withdrawn?.state.name}');

    // A asks for 0.2 EPIC by file; B pays the file; A finishes and posts it.
    String? fileSlate;
    if (a.supportsRequestFiles) {
      final req = (await tester.runAsync(() => a.pairing.requestFile(amount: _ep(0.2), message: 'File order')))!;
      final paidFile = await tester.runAsync(() => b.payRequestFile(slateJson: req.json, amount: _ep(0.2)));
      final posted = paidFile == null ? null : await tester.runAsync(() => a.finalizeAndPost(slateJson: paidFile.json));
      fileSlate = req.slateId;
      record('a request by file paid by B and posted by A', posted != null, posted == null ? '' : _row(posted));
    } else {
      note('this core has no request files');
    }

    // A note and a label, on two payments.
    var list = await txs(tester, a, refresh: true);
    final faucetRow = list.firstWhere((t) => t.kind == TxKind.received && t.amountCredited == _ep(10));
    await tester.runAsync(() => a.setTxNote(key: sent.key, note: 'phone note: B coffee'));
    await tester.runAsync(() => a.setTxLabel(key: faucetRow.key, label: 'Faucet one'));

    // Settings away from the defaults.
    await tester.runAsync(() async {
      await settings().setThemeMode(ThemeMode.dark);
      await settings().setFeature(AdvancedFeature.technicalDetails, true);
      final now = (await c.read(appSettingsProvider.future)).payments;
      await settings().setPayments(now.copyWith(linkHttp: false));
      await settings().setAutoLockMinutes(30);
      await settings().setSendStrategy(SelectionStrategy.all);
      await c.read(serverListProvider((ServerKind.node, Chain.floonet)).notifier).add('https://floonet-node.example.org');
      await c.read(pairingSeenAsProvider.notifier).set('Phone A seen');
    });
    final before = (await tester.runAsync(() => c.read(appSettingsProvider.future)))!;
    note('settings set: theme ${before.themeMode.name}, autoLock ${before.autoLockMinutes}, strategy ${before.sendStrategy.name}, '
        'features ${before.advanced.features.map((f) => f.name).join('+')}, linkHttp ${before.payments.linkHttp}');

    // Everything on chain before the deletes: a restore finds only confirmed outputs.
    final settled = await waitFor(tester, 'every payment confirmed', () async {
      final l = await a.transactions(refresh: true);
      final open = l.where((t) => t.status != TxStatus.cancelled && !t.confirmed).toList();
      return open.isEmpty ? l : null;
    }, timeout: const Duration(minutes: 30), everyMs: 20000);
    list = settled ?? await txs(tester, a, refresh: true);
    record('every payment of A confirmed', settled != null, list.map(_row).join(' ;; '));
    final unspent = (await tester.runAsync(() => a.outputs()))!.where((o) => o.status.name == 'unspent').toList();
    note('A unspent outputs: ${unspent.length}');

    // ---- 3. Export through Settings › Wallet › Export wallet data.
    final (f1, sheet) = await exportUi(tester, 'a-01-export-sheet');
    record('the export sheet says what the file holds', sheet.contains('payment history, contacts, invoices and settings'), sheet);
    record('…not the phrase, cannot restore alone', sheet.contains('enter the recovery phrase first'));
    record('…phrase first, then this file', sheet.contains('enter the recovery phrase first, then import this file'));
    final p1 = await decodeFile(tester, phrase, f1, Chain.floonet);
    final book = (await tester.runAsync(() => c.read(contactsProvider.future)))!;
    record('F1 is version 2', p1.version == 2, 'v${p1.version}, ${f1.length} bytes');
    record('F1 carries the whole shared address book', book.every((x) => p1.contacts.any((r) => r.name == x.name)),
        'book ${book.map((x) => x.name).join(', ')}; file ${p1.contacts.map((r) => r.name).join(', ')}');
    record('F1 carries the star', p1.favourites.contains(carol.id), '${p1.favourites.length} stars');
    record('F1 carries every payment', list.every((t) => p1.txs.any((r) => r.slateId == t.slateId)), '${p1.txs.length} records, ${list.length} rows');
    record('F1 carries issued and paid invoices', p1.issuedInvoices.containsKey(lunch.slateId) && p1.paidInvoices.containsKey(asked.slateId),
        'issued ${p1.issuedInvoices.length}, paid ${p1.paidInvoices.length}');
    record('F1 carries the pairing', p1.pairings != null);
    record('F1 carries settings', p1.settings != null && p1.settings!['theme'] == 'dark', jsonEncode(p1.settings));
    final f1Text = utf8.decode(f1, allowMalformed: true);
    record('F1 holds no phrase word run in clear', !f1Text.contains(phrase.split(' ').take(3).join(' ')));

    // ---- 4. Delete A in the app; restore from the phrase.
    await deleteWalletUi(tester);
    await shot(tester, 'a-02-deleted');
    await restoreWallet(tester, phrase);
    a = sessionOf(c);
    await shot(tester, 'a-03-import-offer');
    final afterRestore = (await tester.runAsync(() => c.read(appSettingsProvider.future)))!;
    note('settings after delete + restore: theme ${afterRestore.themeMode.name}, autoLock ${afterRestore.autoLockMinutes}, '
        'strategy ${afterRestore.sendStrategy.name}, seen-as ${await tester.runAsync(() => c.read(pairingSeenAsProvider.future))}');
    // A new phone has the defaults: set them, and take Carol and Dave out of the shared book,
    // so the import is what brings them back.
    await tester.runAsync(() async {
      await settings().setThemeMode(ThemeMode.system);
      await settings().setAdvanced(AdvancedPrefs.none);
      await settings().setPayments(c.read(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults);
      await settings().setAutoLockMinutes(autoLockDefault);
      await settings().setSendStrategy(SelectionStrategy.smallest);
      await c.read(pairingSeenAsProvider.notifier).set('');
      await contactsN().delete(carol.id);
      await contactsN().delete(dave.id);
    });
    final restoredRows = await txs(tester, a);
    record('the restore found A\'s coins on chain', restoredRows.isNotEmpty && restoredRows.every((t) => t.source == TxSource.restored), restoredRows.map(_row).join(' ;; '));

    // ---- 5. Import F1 from the restore's offer.
    _files.next = f1;
    await tapText(tester, 'Import wallet data');
    final s5 = await answerImport(tester, 'a-04');
    record('one summary after the import', s5.summary.startsWith('Imported:') && s5.error.isEmpty, '${s5.summary} ${s5.error}');
    record('the summary names payments, notes, contacts, pairings, invoices and settings',
        ['payment', 'note', 'contact', 'pairing', 'invoice', 'settings'].every(s5.summary.contains), s5.summary);
    record('no settings question after a fresh restore', !s5.settingsAsked);
    note('pairing question shown: ${s5.pairingAsked}');
    await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 2), what: 'home after import');
    await skipTour(tester);
    var paidNotice = false;
    for (var i = 0; i < 10 && !paidNotice; i++) {
      await settle(tester, ms: 1000);
      paidNotice = hasText('An invoice you sent was paid');
    }
    record('no "request was paid" notice for a request the backup brought back', !paidNotice);
    a = sessionOf(c);
    list = await txs(tester, a);
    final sentBack = list.where((t) => t.slateId == sent.slateId).firstOrNull;
    final faucetBack = list.where((t) => commitsOf(t).intersection(commitsOf(faucetRow)).isNotEmpty || t.slateId == faucetRow.slateId).firstOrNull;
    record('the note is back', sentBack?.note == 'phone note: B coffee', sentBack == null ? 'no row' : _row(sentBack));
    record('the label is back', faucetBack?.label == 'Faucet one', faucetBack == null ? 'no row' : _row(faucetBack));
    record('the send keeps its recipient and method', sentBack?.counterparty == bAddress && sentBack?.transport == 'epicbox', sentBack == null ? '' : _row(sentBack));
    final coreContacts = (await tester.runAsync(() => a.contacts()))!;
    record('the core\'s address book has every contact again', ['Ben Shop', 'Carol Link', 'Dave Link'].every((n) => coreContacts.any((x) => x.name == n)),
        coreContacts.map((x) => x.name).join(', '));
    final contactsBack = (await tester.runAsync(() => c.read(contactsProvider.future)))!;
    final starsBack = (await tester.runAsync(() => a.favouriteContacts()))!.toSet();
    final carolBack = coreContacts.where((x) => x.name == 'Carol Link').firstOrNull;
    record('Contacts (the app\'s list) shows every contact after the import', ['Ben Shop', 'Carol Link', 'Dave Link'].every((n) => contactsBack.any((x) => x.name == n)), contactsBack.map((x) => x.name).join(', '));
    record('Carol is starred again', carolBack != null && starsBack.contains(carolBack.id), '${starsBack.length} stars');
    final pairingsBack = (await tester.runAsync(() => a.pairing.pairings()))!;
    final shopB = pairingsBack.where((p) => p.name == 'Shop B').firstOrNull;
    record('the pairing is back, verified, invoices allowed', shopB != null && shopB.state == PairingState.verified && shopB.allowInvoices,
        pairingsBack.map((p) => '${p.name}:${p.state.name}:inv=${p.allowInvoices}:contact=${p.contactId}').join(', '));
    record('the pairing names Ben Shop', shopB?.contactId == ben.id, '${shopB?.contactId}');
    final issuedBack = (await tester.runAsync(() => a.issuedInvoices()))!;
    final lunchBack = issuedBack.where((i) => i.slateId == lunch.slateId).firstOrNull;
    record('the withdrawn request is back, ended, with its message', lunchBack?.state == IssuedInvoiceState.withdrawn && lunchBack?.message == 'Phone lunch',
        issuedBack.map((i) => '${i.message}:${i.state.name}').join(', '));
    if (fileSlate != null) {
      final fileBack = issuedBack.where((i) => i.slateId == fileSlate).firstOrNull;
      record('the request by file is back, paid', fileBack?.state == IssuedInvoiceState.paid, '${fileBack?.state.name} ${fileBack?.message}');
    }
    final paidBack = await tester.runAsync(() => a.paidInvoice(slateId: asked.slateId));
    record('the paid invoice is back', paidBack != null && paidBack.message == 'Phone test order', '${paidBack?.status.name} ${paidBack?.message}');
    final sNow = (await tester.runAsync(() => c.read(appSettingsProvider.future)))!;
    final nodes = (await tester.runAsync(() => c.read(serverListProvider((ServerKind.node, Chain.floonet)).future)))!;
    final seenAs = await tester.runAsync(() => c.read(pairingSeenAsProvider.future));
    record('settings are back: theme dark', sNow.themeMode == ThemeMode.dark, sNow.themeMode.name);
    record('…Technical details on', sNow.advanced.has(AdvancedFeature.technicalDetails));
    record('…Link HTTP off', !sNow.payments.linkHttp);
    record('…auto-lock 30 min', sNow.autoLockMinutes == 30, '${sNow.autoLockMinutes}');
    record('…send strategy All', sNow.sendStrategy == SelectionStrategy.all, sNow.sendStrategy.name);
    record('…the added node is listed', nodes.entries.any((e) => e.contains('floonet-node.example.org')), nodes.entries.join(', '));
    record('…Pairing and Invoices on', sNow.advanced.pairingOn && sNow.advanced.invoicesOn);
    record('…"seen as" name', seenAs == 'Phone A seen', '$seenAs');

    // The screens.
    await toShell(tester);
    await shot(tester, 'a-05-home');
    await push(tester, const InvoicesScreen(segment: InvoicesSegment.sent));
    await settle(tester, ms: 1500);
    await shot(tester, 'a-06-invoices-sent');
    record('…nor in Invoices', !hasText('An invoice you sent was paid'));
    final sentList = texts().join(' | ');
    record('Invoices › Sent lists the withdrawn request and the paid request by file',
        hasText('Withdrawn') && hasText(RegExp(r'^0[.,]2 EPIC')) && hasText(RegExp(r'^0[.,]3 EPIC')), sentList.substring(0, sentList.length.clamp(0, 400)));
    await tapText(tester, 'Withdrawn');
    await settle(tester, ms: 1200);
    await shot(tester, 'a-06b-withdrawn-request');
    // The message is selectable text (an EditableText), which texts() does not read.
    final message = find.byWidgetPredicate((w) => w is EditableText && w.controller.text.contains('Phone lunch'));
    record('the withdrawn request shows its message', hasText('Phone lunch') || message.evaluate().isNotEmpty);
    await push(tester, const InvoicesScreen(segment: InvoicesSegment.toPay));
    await settle(tester, ms: 1500);
    await shot(tester, 'a-07-invoices-to-pay');
    note('Invoices › To pay: ${screen()}');
    await toShell(tester);
    await push(tester, TxDetailsScreen(txKey: sentBack?.key ?? sent.key));
    await shot(tester, 'a-08-send-details');
    record('the send\'s details show the note', hasText('phone note: B coffee'), screen());
    final paidRow = list.where((t) => t.slateId == asked.slateId).firstOrNull;
    if (paidRow != null) {
      await toShell(tester);
      await push(tester, TxDetailsScreen(txKey: paidRow.key));
      await shot(tester, 'a-09-paid-invoice-details');
      record('the paid invoice reads as an invoice in history', hasText(RegExp('Phone test order|[Ii]nvoice')), screen());
    }
    await toShell(tester);
    await push(tester, const ContactsScreen());
    await shot(tester, 'a-10-contacts');
    record('Contacts shows everyone, a star', hasText('Carol Link') && hasText('Dave Link') && hasText('Ben Shop') && find.byIcon(Icons.star_rounded).evaluate().isNotEmpty, screen());
    await toShell(tester);

    // ---- 6. the restored-row test: restore without the import, edit two found rows in
    // the UI, export F2, restore again, import F2: the edits are on the same payments.
    await deleteWalletUi(tester);
    await restoreWallet(tester, phrase);
    await tapText(tester, 'Not now');
    await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 2), what: 'home');
    await skipTour(tester);
    a = sessionOf(c);
    final found = (await txs(tester, a)).where((t) => t.source == TxSource.restored).toList()
      ..sort((x, y) => x.key.compareTo(y.key));
    record('the payments show as found on chain', found.length >= 2, found.map(_row).join(' ;; '));
    final edits = <String, ({String label, String from, String method, String note})>{};
    if (found.length >= 2) {
      edits[found[0].key] = (label: 'Found one', from: bAddress, method: 'Epicbox', note: 'restored note one');
      edits[found[1].key] = (label: 'Found two', from: 'https://shop.example.org', method: 'Direct · File Transfer', note: 'restored note two');
    }
    var n = 0;
    for (final e in edits.entries) {
      n++;
      await toShell(tester);
      // The payment's page (a tap on a Home row's title edits its label in place).
      await push(tester, TxDetailsScreen(txKey: e.key));
      await waitText(tester, 'Add details');
      // Sender, method and note in the sheet.
      await tapText(tester, 'Add details');
      await typeInto(tester, fieldF('From'), e.value.from);
      await tapF(tester, find.widgetWithText(ChoiceChip, e.value.method));
      await typeInto(tester, fieldF('Note'), e.value.note);
      await shot(tester, 'r-0$n-edit-sheet');
      await tapF(tester, find.widgetWithText(FilledButton, 'Save'));
      await settle(tester, ms: 1500);
      // The label in place; leaving the field saves it, as a tap elsewhere does.
      await tapText(tester, 'Add label');
      final labelField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Add label');
      await typeInto(tester, labelField, e.value.label);
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester, ms: 1500);
      note('restored row $n: the page is still open after the label: ${hasText('Edit details')}');
      await shot(tester, 'r-0$n-edited');
    }
    final editedRows = {for (final t in await txs(tester, a)) t.key: t};
    for (final e in edits.entries) {
      final t = editedRows[e.key];
      record('restored row ${e.key.substring(0, 12)} took the edits', t?.label == e.value.label && t?.counterparty == e.value.from && t?.note == e.value.note && t?.transport != null,
          t == null ? 'gone' : _row(t));
    }
    final (f2, _) = await exportUi(tester, 'r-03-export-sheet');
    final p2 = await decodeFile(tester, phrase, f2, Chain.floonet);
    final inFile = {for (final r in p2.txs) ...r.outputCommits};
    final editedKept = edits.keys.every((k) => commitsOf(editedRows[k]!).every(inFile.contains));
    final untouched = found.where((t) => !edits.containsKey(t.key)).toList();
    final untouchedOut = untouched.every((t) => commitsOf(t).every((x) => !inFile.contains(x)));
    record('F2 keeps the edited restored rows', editedKept, '${p2.txs.length} records: ${p2.txs.map((r) => '${r.label}/${r.transport}/${r.outputCommits.length}c').join(', ')}');
    record('F2 leaves the untouched restored rows out', untouchedOut, '${untouched.length} untouched');
    final f2Theme = p2.settings?['theme'];
    note('F2 settings theme: $f2Theme');

    await deleteWalletUi(tester);
    await restoreWallet(tester, phrase);
    await tapText(tester, 'Not now');
    await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 2), what: 'home');
    await skipTour(tester);
    a = sessionOf(c);

    // ---- 7. A setting the file also has, changed here first: the question comes once.
    final conflictTheme = f2Theme == 'light' ? ThemeMode.dark : ThemeMode.light;
    await tester.runAsync(() => settings().setThemeMode(conflictTheme));
    await openWalletSettings(tester);
    _files.next = f2;
    await tapText(tester, 'Import wallet data');
    final s7 = await answerImport(tester, 'r-04', useBackupSettings: true);
    record('the settings question comes for a changed setting', s7.settingsAsked, s7.summary);
    final themeAfter = (await tester.runAsync(() => c.read(appSettingsProvider.future)))!.themeMode.name;
    record('"Use the backup\'s" takes the file\'s theme', themeAfter == f2Theme, 'file $f2Theme, here ${conflictTheme.name}, now $themeAfter');
    final reRows = {for (final t in await txs(tester, a)) t.key: t};
    for (final e in edits.entries) {
      final t = reRows[e.key];
      record('the edits are back on the same payment ${e.key.substring(0, 12)}',
          t != null && t.label == e.value.label && t.counterparty == e.value.from && t.note == e.value.note && t.amountCredited == editedRows[e.key]!.amountCredited && t.blockHeight == editedRows[e.key]!.blockHeight,
          t == null ? 'gone; keys ${reRows.keys.map((k) => k.substring(0, 12)).join(', ')}' : _row(t));
    }
    await toShell(tester);
    if (edits.isNotEmpty) {
      await push(tester, TxDetailsScreen(txKey: edits.keys.first));
      await shot(tester, 'r-05-edits-back');
      await toShell(tester);
    }

    // ---- 9. A file of another wallet (B's) is refused; nothing changes.
    final fb = (await tester.runAsync(() => b.exportHistory()))!;
    final rowsBefore = (await txs(tester, a)).map(_row).toList();
    final bookBefore = (await tester.runAsync(() => c.read(contactsProvider.future)))!.length;
    await openWalletSettings(tester);
    _files.next = fb;
    await tapText(tester, 'Import wallet data');
    final s9 = await answerImport(tester, 'o-01');
    await shot(tester, 'o-01-refused');
    record('another wallet\'s file is refused with a clear message', s9.error.contains('different wallet'), s9.error);
    record('…the app\'s sentence: only the wallet of the same phrase opens it', s9.error.contains('Only the wallet restored from the same recovery phrase can open it'), s9.error);
    final rowsAfter = (await txs(tester, a)).map(_row).toList();
    final bookAfter = (await tester.runAsync(() => c.read(contactsProvider.future)))!.length;
    record('nothing changed in A', rowsAfter.join() == rowsBefore.join() && bookAfter == bookBefore, '$bookBefore → $bookAfter contacts');

    note('checks done, closing');
    await toShell(tester);
    c.read(sessionProvider.notifier).lock();
    await tester.pumpWidget(const SizedBox.shrink());
    note('wallet A locked');
    expect(_fails, isEmpty, reason: 'failed checks: ${_fails.join('; ')}');
  }, timeout: const Timeout(Duration(minutes: 150)));
}
