// Live check of the Pairing UX (26.10.18) on a phone, with the desktop app as the other side
// (integration_test/release_check/pairing_message_desk_test.dart) and tool/pairing_message_check.sh
// carrying the messages between them, as a chat would:
//
//   1. this phone invites by message, the desktop joins; the reply comes back through the
//      clipboard offer, the finish link goes out, both show the same four words;
//   2. the desktop invites; Not now on the offer, then not offered again; pasted under Got words
//      or a link?, Pair, the reply goes out, the finish link comes back through the offer;
//   3. in person: this phone's code link goes to the desktop, the desktop's code is "scanned"
//      (the camera is a fake fed the desktop's link; the rest is real).
//
// The real app with the real LEPIC core, Epicbox off on this phone, so every step goes by
// message. What this phone shares is written to files/rc-chat/out/<name>; what it gets, the
// driver copies in another app of the device (so Android sees another app's clip and shows its
// toast) and switches back, then writes files/rc-chat/in/<name>. Nothing is printed but
// pass/fail lines without links: the driver also reads logcat for link text.
//
//   flutter test -d <emulator> integration_test/pairing_message_phone_test.dart
import 'dart:io';

import 'package:epic_wallet/l10n/app_localizations_en.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/pairing_clip_probe.dart';
import 'package:epic_wallet/src/pairing_clipboard.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/pairing/pair_check.dart' show CheckWordsScreen;
import 'package:epic_wallet/src/ui/pairing/pair_incoming.dart';
import 'package:epic_wallet/src/ui/pairing/pair_screen.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_clip_offer.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

final _l = AppLocalizationsEn();
const _pin = '123456';

void record(String step, bool pass, [String evidence = '']) {
  // ignore: avoid_print
  print('RC ${pass ? 'PASS' : 'FAIL'} | $step | ${evidence.replaceAll('\n', ' ⏎ ')}');
}

/// The phone's real clipboard, counting the reads of the clip's text (each shows Android's
/// "pasted from your clipboard" toast for another app's clip).
class _Counting implements ClipboardProbe {
  int reads = 0;
  final _real = const PlatformClipboardProbe();

  @override
  bool get silent => _real.silent;

  @override
  Future<ClipStamp?> stamp() => _real.stamp();

  @override
  Future<String?> read() {
    reads++;
    return _real.read();
  }
}

late Directory _chat;

Future<void> settle(WidgetTester tester, {int ms = 400}) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

List<String> texts() => [
  for (final e in find.byType(RichText, skipOffstage: false).evaluate())
    if ((e.widget as RichText).text.toPlainText().trim() case final t when t.isNotEmpty) t,
];
bool hasText(String p) => texts().any((t) => t.contains(p));
String screen() => texts().take(30).join(' | ').replaceAll(RegExp(r'epiccash://\S+'), '<link>');

Future<bool> pumpUntil(WidgetTester tester, bool Function() done, {Duration timeout = const Duration(seconds: 90)}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) return false;
    await settle(tester, ms: 250);
  }
  return true;
}

Future<void> tapF(WidgetTester tester, Finder f) async {
  await pumpUntil(tester, () => f.evaluate().isNotEmpty, timeout: const Duration(seconds: 30));
  expect(f, findsWidgets, reason: 'no $f on screen: ${screen()}');
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first, warnIfMissed: false);
  await settle(tester);
}

Future<void> send(WidgetTester tester, String name, String text) =>
    tester.runAsync(() => File('${_chat.path}/out/$name').writeAsString(text)).then((_) {});

/// Waits for the driver's file in/[name] (a message, or that it put one on the clipboard and
/// switched back); its text.
Future<String> receive(WidgetTester tester, String name, {Duration timeout = const Duration(minutes: 8)}) async {
  final file = File('${_chat.path}/in/$name');
  final end = DateTime.now().add(timeout);
  while (!(await tester.runAsync(file.exists))!) {
    if (DateTime.now().isAfter(end)) throw TestFailure('nothing came as $name');
    await settle(tester, ms: 1000);
  }
  return (await tester.runAsync(file.readAsString))!;
}

Future<List<String>> words(WidgetTester tester) async {
  await pumpUntil(tester, () => find.byType(WordTiles).evaluate().isNotEmpty, timeout: const Duration(minutes: 3));
  final tiles = find.byType(WordTiles);
  if (tiles.evaluate().isEmpty) return const [];
  return [for (final w in tester.widget<WordTiles>(tiles.first).words) w?.name ?? '?'];
}

void home(WidgetTester tester) => tester.state<NavigatorState>(find.byType(Navigator).first).popUntil((r) => r.isFirst);

Future<void> push(WidgetTester tester, Widget page) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<void>(builder: (_) => page));
  await settle(tester, ms: 1200);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone: pairing by message both ways and in person, with the desktop', (tester) async {
    final files = FakeSlateFiles();
    final camera = FakeQrCamera();
    final probe = _Counting();
    await tester.runAsync(() async {
      await initWalletBackend();
      await const PlatformSecretStore().write('app.network', Chain.mainnet.name);
      _chat = Directory('${(await getApplicationSupportDirectory()).path}/rc-chat');
      await Directory('${_chat.path}/out').create(recursive: true);
      await Directory('${_chat.path}/in').create(recursive: true);
    });
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore(available: false)),
          updatePlatformProvider.overrideWithValue(null),
          // The share sheet is another app's: what would go to it is taken here.
          slateFilesProvider.overrideWithValue(files),
          pairingClipProbeProvider.overrideWithValue(probe),
          qrCameraFactoryProvider.overrideWithValue(() => camera),
        ],
        child: const WalletApp(),
      ),
    );
    await settle(tester, ms: 1500);
    final c = ProviderScope.containerOf(tester.element(find.byType(WalletApp)));

    // A fresh wallet, Pairing on, Epicbox off: every step goes by message.
    await pumpUntil(tester, () => hasText('Create a new wallet'), timeout: const Duration(minutes: 2));
    await tapF(tester, find.text('Create a new wallet'));
    for (final label in ['PIN', 'Repeat PIN']) {
      final field = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == label);
      await pumpUntil(tester, () => field.evaluate().isNotEmpty);
      await tester.tap(field.first, warnIfMissed: false);
      await tester.enterText(field.first, _pin);
      await settle(tester, ms: 600);
    }
    await pumpUntil(tester, () => find.byKey(balanceFigureKey).evaluate().isNotEmpty, timeout: const Duration(minutes: 3));
    for (var i = 0; i < 6 && find.text('Skip').evaluate().isEmpty; i++) {
      await settle(tester, ms: 500);
    }
    if (find.text('Skip').evaluate().isNotEmpty) await tapF(tester, find.text('Skip'));
    await tester.runAsync(() async {
      final settings = c.read(appSettingsProvider.notifier);
      await settings.setAdvanced(AdvancedPrefs(features: {AdvancedFeature.pairing}));
      final now = c.read(appSettingsProvider).value!;
      await settings.setPayments(now.payments.copyWith(epicbox: false));
      // Loaded first: a set before the stored name is read would be overwritten by it.
      await c.read(pairingSeenAsProvider.future);
      await c.read(pairingSeenAsProvider.notifier).set('RC Phone');
    });
    await settle(tester, ms: 1500);
    record('the phone pairs, Epicbox off', c.read(pairingSupportedProvider) && c.read(pairNetProvider) == PairNet.epicboxOff, '${c.read(pairNetProvider)}');

    // 1. This phone invites by message.
    await push(tester, const PairScreen());
    await tapF(tester, find.byKey(pairMessageKey));
    await tapF(tester, find.byKey(pairShareKey));
    await pumpUntil(tester, () => files.sharedTexts.isNotEmpty, timeout: const Duration(seconds: 30));
    final invite = files.sharedTexts.lastOrNull ?? '';
    record('1 invite shared as one message', invite.startsWith('Pair with me in Epic Cash: epiccash://pair/'), invite.split(':').first);
    await send(tester, 'p-invite', invite);
    await receive(tester, 'clip-d-reply');
    final offered = await pumpUntil(tester, () => find.byType(PairingClipSheet).evaluate().isNotEmpty, timeout: const Duration(seconds: 30));
    record('1 the reply on the clipboard is offered when the app comes back', offered, offered ? _l.pairClipReply : screen());
    // Each new clip is read once (an older clip on the device was read once when Pair opened).
    final readsAfterReply = probe.reads;
    record('1 the clip was read', readsAfterReply >= 1, 'reads $readsAfterReply');
    if (!offered) return;
    await tapF(tester, find.byKey(pairClipUseKey));
    final finishShown = await pumpUntil(tester, () => find.byType(PairFinishScreen).evaluate().isNotEmpty, timeout: const Duration(seconds: 60));
    record('1 Use it opens the finish link to send', finishShown, screen());
    await tapF(tester, find.byKey(finishShareKey));
    final finish = files.sharedTexts.last;
    record('1 the finish link shared as one message', finish.startsWith('Finish our Epic Cash pairing: epiccash://pair-confirm/'), finish.split(':').first);
    await send(tester, 'p-finish', finish);
    await tapF(tester, find.byKey(finishCheckKey));
    final w1 = await words(tester);
    record('1 the phone shows four words', w1.length == 4, w1.join(' '));
    await send(tester, 'p-sas1', w1.join(' '));
    home(tester);
    await settle(tester, ms: 1500);

    // The same clip on the next return: not read again, so no second toast.
    await send(tester, 'p-away1', 'switch away and back');
    await receive(tester, 'back1');
    await settle(tester, ms: 5000);
    record('the unchanged clip is not read again on return', probe.reads == readsAfterReply && find.byType(PairingClipSheet).evaluate().isEmpty, 'reads ${probe.reads}');

    // 2. The desktop invites: offered, Not now, not offered again, then pasted by hand.
    await receive(tester, 'clip-d-invite');
    final offered2 = await pumpUntil(tester, () => find.byType(PairingClipSheet).evaluate().isNotEmpty, timeout: const Duration(seconds: 30));
    record('2 the desktop\'s invite on the clipboard is offered, with its name', offered2 && hasText(_l.pairClipInvite('RC Desk')), screen());
    if (offered2) await tapF(tester, find.byKey(pairClipNotNowKey));
    final readsAfterNotNow = probe.reads;
    await send(tester, 'p-away2', 'switch away and back');
    await receive(tester, 'back2');
    await settle(tester, ms: 5000);
    record('2 after Not now it is not offered again', find.byType(PairingClipSheet).evaluate().isEmpty && probe.reads == readsAfterNotNow, 'reads ${probe.reads}');
    await push(tester, const EnterLinkScreen());
    await tapF(tester, find.byTooltip(_l.pairPaste));
    await tapF(tester, find.byKey(pairEnterGoKey));
    final incoming = await pumpUntil(tester, () => find.byType(IncomingInviteSheet).evaluate().isNotEmpty, timeout: const Duration(seconds: 60));
    record('2 the pasted message opens "Pair with RC Desk?"', incoming && hasText(_l.pairIncomingTitle('RC Desk')), screen());
    await tapF(tester, find.byKey(incomingPairKey));
    final replyShown = await pumpUntil(tester, () => find.byType(PairReplyScreen).evaluate().isNotEmpty, timeout: const Duration(seconds: 60));
    record('2 Pair opens the reply to send', replyShown, screen());
    await tapF(tester, find.byKey(replyShareKey));
    final reply = files.sharedTexts.last;
    record('2 the reply shared as one message', reply.startsWith('My reply to your Epic Cash pairing: epiccash://pair-reply/'), reply.split(':').first);
    await send(tester, 'p-reply', reply);
    record('2 then the wait for the finish link', find.byKey(waitingPasteFinishKey).evaluate().isNotEmpty, screen());
    await receive(tester, 'clip-d-finish');
    final offered3 = await pumpUntil(tester, () => find.byType(PairingClipSheet).evaluate().isNotEmpty, timeout: const Duration(seconds: 30));
    record('2 the finish link is offered over the wait', offered3, screen());
    if (offered3) await tapF(tester, find.byKey(pairClipUseKey));
    final w2 = await words(tester);
    record('2 the phone shows four words', w2.length == 4, w2.join(' '));
    record('2 the wait made way for the words', find.byType(CheckWordsScreen).evaluate().isNotEmpty && find.byType(PairingWaitingScreen).evaluate().isEmpty, screen());
    await send(tester, 'p-sas2', w2.join(' '));
    home(tester);
    await settle(tester, ms: 1500);

    // 3. In person: this phone's code link to the desktop, the desktop's code "scanned".
    await push(tester, const InPersonScreen());
    await pumpUntil(tester, () => find.byKey(pairCopyCardKey).evaluate().isNotEmpty, timeout: const Duration(seconds: 60));
    var card = '';
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') card = ((call.arguments as Map?)?['text'] as String?) ?? '';
      return null;
    });
    await tapF(tester, find.byKey(pairCopyCardKey));
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    record('3 the phone\'s code copies as a link', card.startsWith('epiccash://contact/'), card.isEmpty ? 'nothing' : 'a contact link');
    await send(tester, 'p-card', card);
    final deskCard = await receive(tester, 'd-card');
    await tapF(tester, find.text(_l.pairScanTheirs));
    await settle(tester, ms: 800);
    camera.emit(deskCard.trim());
    final w3 = await words(tester);
    record('3 in person: the phone shows four words', w3.length == 4, w3.join(' '));
    await send(tester, 'p-sas3', w3.join(' '));
    await send(tester, 'p-done', 'done');
    // ignore: avoid_print
    print('RC DONE phone');
  });
}
