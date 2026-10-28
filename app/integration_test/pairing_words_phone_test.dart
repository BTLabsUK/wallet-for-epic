// Live check of pairing by words on a phone (report utc3fhjj, 2026-10-26): the real app on the
// device with the real LEPIC core and real mainnet relays. The phone's own relay is one outside
// the words meeting list (epicbox.iniaku.my.id, as a tester had), which LEPIC 26.10.16 refused
// words for outright ("Can't reach the relay").
//
//   WFE_WORDS_MODE=filter: run the emulator with `-dns-server 194.168.4.100` (Virgin Media's DNS,
//     whose filter answers epicbox.epiccash.com with a host that refuses TLS). The phone offers
//     words, a second LEPIC wallet in this process (relay stackwallet) types them, answers, and
//     both sides reach the same four words.
//   WFE_WORDS_MODE=dead: run the emulator with a DNS server that answers nothing
//     (`-dns-server 192.0.2.1`): no meeting relay is reached and Pairing words says so.
//
//   WFE_WORDS_JOINER=desk: the phone copies its words and waits; the desktop app pastes them
//     (integration_test/release_check/pairing_words_paste_test.dart, WFE_WORDS_FILE).
//
//   flutter test -d <emulator> integration_test/pairing_words_phone_test.dart --dart-define=WFE_WORDS_MODE=filter
//
// Every check prints one `RC PASS|FAIL | step | evidence` line. Throwaway wallets only; no funds
// move and no recovery phrase is printed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/l10n/app_localizations_en.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/pairing/pair_screen.dart' show PairingWordsScreen;
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _mode = String.fromEnvironment('WFE_WORDS_MODE', defaultValue: 'filter');
// `desk`: the desktop app is the other side and pastes what the phone copied.
const _joiner = String.fromEnvironment('WFE_WORDS_JOINER', defaultValue: 'here');
const _node = 'https://node.btlabs.uk';
const _ownRelay = EpicboxRelay(host: 'epicbox.iniaku.my.id');
final _l = AppLocalizationsEn();

const _pin = '123456';

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
  if (f.evaluate().isEmpty) {
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
      ],
      child: RepaintBoundary(key: _shotKey, child: const WalletApp()),
    ),
  );
  await settle(tester, ms: 1500);
  return ProviderScope.containerOf(tester.element(find.byType(WalletApp)));
}

Future<void> createWallet(WidgetTester tester) async {
  await waitText(tester, 'Create a new wallet', timeout: const Duration(minutes: 2));
  await tapText(tester, 'Create a new wallet');
  await typeInto(tester, fieldF('PIN'), _pin);
  await settle(tester, ms: 600);
  await typeInto(tester, fieldF('Repeat PIN'), _pin);
  await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 3), what: 'home');
  await skipTour(tester);
}


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone: pairing words on a relay outside the meeting list ($_mode)', (tester) async {
    final c = await boot(tester, Chain.mainnet);
    await createWallet(tester);
    await tester.runAsync(() => c.read(appSettingsProvider.notifier).setAdvanced(AdvancedPrefs(features: {AdvancedFeature.pairing})));
    // The relay a tester had, switched live as Settings does (server_switch.dart).
    final opened = c.read(walletConfigProvider)!;
    final moved = WalletConfig(
      dataDir: opened.dataDir,
      chain: opened.chain,
      nodeUrl: _node,
      epicboxDomain: _ownRelay.host,
      epicboxPort: _ownRelay.port,
      walletId: opened.walletId,
    );
    await tester.runAsync(() async {
      await c.read(sessionProvider)!.setServers(config: moved);
      await c.read(networkChoiceProvider.notifier).save(mainnetPreset, _node, relay: _ownRelay);
    });
    c.read(walletConfigProvider.notifier).select(moved);
    await settle(tester, ms: 3000);
    final config = c.read(walletConfigProvider)!;
    record('the phone wallet is on ${config.epicboxDomain}', config.epicboxDomain == _ownRelay.host, '${config.chain.name} ${config.nodeUrl}');
    final lookup = await tester.runAsync(
      () => InternetAddress.lookup('epicbox.epiccash.com').then((a) => a.map((e) => e.address).join(',')).catchError((Object e) => 'lookup failed'),
    );
    note('epicbox.epiccash.com from here: $lookup');

    await push(tester, const PairingWordsScreen());
    await pumpUntil(
      tester,
      () => find.byType(WordTiles).evaluate().isNotEmpty || hasText(_l.pairNoRelay) || hasText(_l.pairRelaysBlocked) || hasText(_l.pairRelayUnreachableTitle),
      timeout: const Duration(minutes: 2),
      what: 'words or a notice',
    );
    await settle(tester, ms: 800);
    await shot(tester, 'words-$_mode');
    if (_mode == 'dead') {
      record('no relay reached: the words screen says so', hasText(_l.pairNoRelay) || hasText(_l.pairRelaysBlocked), screen());
      record('not the old "Can\'t reach the relay"', !hasText(_l.pairRelayUnreachableTitle), '');
      return;
    }
    final all = await tester.runAsync(() => c.read(pairingApiProvider).pairings());
    final invite = (all ?? const <PairingRecord>[]).where((p) => p.inviteWords.isNotEmpty).firstOrNull;
    record('the phone offered five words', invite?.inviteWords.length == 5, screen());
    if (invite == null) return;

    // Copy puts the names alone on the clipboard, as the other side pastes them.
    // What the button hands the system clipboard, taken off the platform call on its way (this
    // Android does not let the test read the clipboard back); other platform calls go through.
    var copied = '';
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = ((call.arguments as Map?)?['text'] as String?) ?? '';
      return null;
    });
    final copy = find.ancestor(of: textF(_l.pairWordsCopy), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    await tapF(tester, copy);
    await settle(tester, ms: 1000);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    note('after Copy: ${hasText(_l.pairCopied) ? 'Copied notice shown' : 'no Copied notice'}');
    final names = invite.inviteWords.map((w) => w.name).join(' ');
    record('Copy puts only the words on the clipboard', copied == names, copied);
    note('COPIED|$copied|');

    if (_joiner == 'desk') {
      // The desktop app pastes [copied] and answers (pairing_words_paste_test.dart).
      PairingRecord? mine;
      final until = DateTime.now().add(const Duration(minutes: 8));
      while (DateTime.now().isBefore(until)) {
        await tester.runAsync(() => c.read(pairingApiProvider).collect());
        mine = await tester.runAsync<PairingRecord?>(() => c.read(pairingApiProvider).pairing(invite.id));
        if (mine?.state == PairingState.paired) break;
        await settle(tester, ms: 3000);
      }
      await shot(tester, 'words-desk-paired');
      record('the desktop\'s answer reached the phone', mine?.state == PairingState.paired, '${mine?.state.name}');
      note('PHONE SAS|${[for (final w in mine?.sas ?? const <SasWord>[]) w.name].join(' ')}|');
      return;
    }

    // The other side, in this process: its own relay is stackwallet; it looks on the meeting list.
    final tmp = await tester.runAsync(getTemporaryDirectory);
    final otherDir = Directory('${tmp!.path}/words-other-${DateTime.now().millisecondsSinceEpoch}')..createSync();
    final other = (await tester.runAsync(
      () => LepicWalletService(secrets: MemorySecretStore()).create(
        config: mainnetPreset.config(dataDir: otherDir.path, nodeUrl: _node, relay: const EpicboxRelay(host: 'epicbox.stackwallet.com')),
        password: 'words-other-$_pin',
      ),
    ))!;
    addTearDown(other.dispose);
    final words = invite.inviteWords.map((w) => w.name).toList();
    final preview = await tester.runAsync(() => other.pairing.openWords(words));
    record('the other wallet found the invite by its words', preview != null, '${preview?.name} home ${preview?.homeRelay}');
    if (preview == null) return;
    final answered = await tester.runAsync(() => other.pairing.acceptInvite(token: preview.token, name: 'RC Other'));
    record('its answer went to the phone\'s own relay', answered != null && !answered.relayDown, '${answered?.state.name} relayDown ${answered?.relayDown}');

    PairingRecord? mine;
    PairingRecord? theirs;
    final until = DateTime.now().add(const Duration(minutes: 3));
    while (DateTime.now().isBefore(until)) {
      await tester.runAsync(() => c.read(pairingApiProvider).collect());
      await tester.runAsync(() => other.pairing.collect(trigger: PairingCollectTrigger.pull));
      mine = await tester.runAsync<PairingRecord?>(() => c.read(pairingApiProvider).pairing(invite.id));
      theirs = await tester.runAsync<PairingRecord?>(() => other.pairing.pairing(answered!.id));
      if (mine?.state == PairingState.paired && theirs?.state == PairingState.paired) break;
      await settle(tester, ms: 3000);
    }
    await shot(tester, 'words-$_mode-paired');
    record('both sides paired', mine?.state == PairingState.paired && theirs?.state == PairingState.paired, '${mine?.state.name} / ${theirs?.state.name}');
    final a = [for (final w in mine?.sas ?? const <SasWord>[]) w.name].join(' ');
    final b = [for (final w in theirs?.sas ?? const <SasWord>[]) w.name].join(' ');
    record('both show the same four words', a.isNotEmpty && a == b, a.isEmpty ? 'none' : 'same: ${a == b}');
  });
}
