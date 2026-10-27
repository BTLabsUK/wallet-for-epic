// The desktop side of the Pairing UX live check (26.10.18) with a phone
// (integration_test/pairing_message_phone_test.dart; tool/pairing_message_check.sh drives both):
// the phone's invite taken from the clipboard offer, the reply copied, the finish link offered
// in the wait; then this desktop invites, takes the phone's reply from the offer and copies the
// finish link; then in person, the phone's code link taken from the offer on the In person
// panel. The real app, LEPIC, node and relays; no funds move.
//
// Messages go through $RC_CHAT: the phone's arrive as <name> (p-invite, p-finish, p-reply,
// p-card), this desktop's go out as <name> (d-reply, d-sas1, d-invite, d-finish, d-sas2,
// d-card, d-sas3). Each one that arrives is put on the clipboard and the window "comes back",
// as when the user copied it in a chat.
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskSeenAsProvider;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

final _chat = Platform.environment['RC_CHAT'] ?? '';

Future<String> receive(WidgetTester tester, String name, {Duration timeout = const Duration(minutes: 8)}) async {
  final file = File('$_chat/$name');
  final end = DateTime.now().add(timeout);
  while (!file.existsSync()) {
    if (DateTime.now().isAfter(end)) throw TestFailure('nothing came as $name');
    await settle(tester, ms: 1000);
  }
  return file.readAsStringSync();
}

void send(String name, String text) => File('$_chat/$name').writeAsStringSync(text);

/// [text] copied in the chat, then the window back in front.
Future<void> copiedInChat(WidgetTester tester, String text) async {
  await tester.runAsync(() => Clipboard.setData(ClipboardData(text: text)));
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  await settle(tester, ms: 300);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await settle(tester, ms: 1500);
}

Future<String> clipboard(WidgetTester tester) async => (await tester.runAsync(() => Clipboard.getData(Clipboard.kTextPlain)))?.text ?? '';

Future<bool> until(WidgetTester tester, Finder f, {Duration timeout = const Duration(seconds: 60)}) async {
  final end = DateTime.now().add(timeout);
  while (f.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) return false;
    await settle(tester, ms: 500);
  }
  return true;
}

Future<void> tapKey(WidgetTester tester, Key key) async {
  await until(tester, find.byKey(key), timeout: const Duration(seconds: 30));
  expect(find.byKey(key), findsWidgets, reason: 'no $key on screen');
  await tester.ensureVisible(find.byKey(key).first);
  await tester.pump();
  await tester.tap(find.byKey(key).first, warnIfMissed: false);
  await settle(tester, ms: 800);
}

Future<List<String>> words(WidgetTester tester) async {
  await until(tester, find.byType(WordTiles), timeout: const Duration(minutes: 3));
  final tiles = find.byType(WordTiles);
  if (tiles.evaluate().isEmpty) return const [];
  return [for (final w in tester.widget<WordTiles>(tiles.first).words) w?.name ?? '?'];
}

/// Closes the words check (Skip for now) and what follows it.
Future<void> closeCheck(WidgetTester tester) async {
  await tapKey(tester, deskCheckSkipKey);
  for (var i = 0; i < 3; i++) {
    if (find.byKey(deskSavedNotNowKey).evaluate().isNotEmpty) await tapKey(tester, deskSavedNotNowKey);
    await settle(tester, ms: 600);
  }
}

String safe(String t) => t.replaceAll(RegExp(r'epiccash://\S+'), '<link>');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('desktop: pairing by message both ways and in person, with a phone', (tester) async {
    captureErrors();
    final password = randomPassword();
    await boot(tester);
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    // A throwaway wallet: the phrase is shown but never read or kept.
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, 'Written down');
    await tapText(tester, 'Continue', last: true);
    for (var i = 0; i < 4 && !hasText('Unlock wallet'); i++) {
      await waitText(tester, RegExp(r'^(Continue|Save settings)$'));
      await settle(tester, ms: 1000);
      await tapText(tester, hasText('Save settings') ? 'Save settings' : 'Continue', last: true);
      await settle(tester, ms: 3000);
    }
    await waitText(tester, 'Unlock wallet');
    await typeIn(tester, 0, password);
    await tapText(tester, 'Unlock', last: true);
    await waitText(tester, RegExp('Overview|Balance'), timeout: const Duration(seconds: 120));
    await settle(tester, ms: 3000);
    if (hasText('Skip tour')) await tapText(tester, 'Skip tour');
    final c = containerOf(tester);
    final settings = c.read(deskProvider).settings;
    await tester.runAsync(() => c.read(deskProvider.notifier).saveSettings(settings.copyWith(advanced: settings.advanced.withExperimental(AdvancedFeature.pairing, true))));
    c.read(deskSeenAsProvider.notifier).set('RC Desk');
    await settle(tester, ms: 3000);

    // 1. The phone invites: offered from the clipboard, answered, the reply copied.
    await copiedInChat(tester, await receive(tester, 'p-invite'));
    final offered = await until(tester, find.byType(DeskPairingClipDialog));
    record('1 the phone\'s invite on the clipboard is offered', offered && hasText('RC Phone'), safe(texts().take(12).join(' | ')));
    await shot(tester, 'msg-01-offer');
    await tapKey(tester, deskClipUseKey);
    await tapKey(tester, deskIncomingPairKey);
    record('1 Pair opens the reply to copy', await until(tester, find.byKey(deskReplyCopyKey)), safe(texts().take(12).join(' | ')));
    await shot(tester, 'msg-02-reply');
    await tapKey(tester, deskReplyCopyKey);
    final reply = await clipboard(tester);
    record('1 the reply copied as one message', reply.startsWith('My reply to your Epic Cash pairing: epiccash://pair-reply/'), reply.split(':').first);
    send('d-reply', reply);
    await copiedInChat(tester, await receive(tester, 'p-finish'));
    final found = await until(tester, find.byKey(deskWaitFoundKey), timeout: const Duration(seconds: 30));
    record('1 the finish link is offered in the wait', found, safe(texts().take(12).join(' | ')));
    await shot(tester, 'msg-03-finish-found');
    if (found) await tapKey(tester, deskWaitUseKey);
    final w1 = await words(tester);
    record('1 the desktop shows four words', w1.length == 4, w1.join(' '));
    send('d-sas1', w1.join(' '));
    await closeCheck(tester);

    // 2. This desktop invites; the phone's reply comes back through the offer.
    c.read(deskNavProvider.notifier).go(DeskRoute.pair);
    await settle(tester, ms: 1500);
    await tapKey(tester, deskPairMessageKey);
    await tapKey(tester, deskPairCopyInviteKey);
    final invite = await clipboard(tester);
    record('2 the invite copied as one message', invite.startsWith('Pair with me in Epic Cash: epiccash://pair/'), invite.split(':').first);
    await shot(tester, 'msg-04-invite-wait');
    send('d-invite', invite);
    await copiedInChat(tester, await receive(tester, 'p-reply'));
    final offered2 = await until(tester, find.byType(DeskPairingClipDialog));
    record('2 the phone\'s reply is offered', offered2, safe(texts().take(12).join(' | ')));
    if (offered2) await tapKey(tester, deskClipUseKey);
    record('2 Use it opens the finish link', await until(tester, find.byKey(deskFinishCopyKey)), safe(texts().take(12).join(' | ')));
    await shot(tester, 'msg-05-finish');
    await tapKey(tester, deskFinishCopyKey);
    final finish = await clipboard(tester);
    record('2 the finish link copied as one message', finish.startsWith('Finish our Epic Cash pairing: epiccash://pair-confirm/'), finish.split(':').first);
    send('d-finish', finish);
    await tapKey(tester, deskConfirmBackCheckKey);
    final w2 = await words(tester);
    record('2 the desktop shows four words', w2.length == 4, w2.join(' '));
    send('d-sas2', w2.join(' '));
    await closeCheck(tester);

    // 3. In person: this desktop's code link out, the phone's code link offered on the panel.
    c.read(deskNavProvider.notifier).go(DeskRoute.contacts);
    await settle(tester, ms: 800);
    c.read(deskNavProvider.notifier).go(DeskRoute.pair, DeskPairWay.inPerson);
    await settle(tester, ms: 2500);
    await tapKey(tester, deskPairCopyCardKey);
    final card = await clipboard(tester);
    record('3 the desktop\'s code copies as a link', card.startsWith('epiccash://contact/'), card.isEmpty ? 'nothing' : 'a contact link');
    send('d-card', card);
    await copiedInChat(tester, await receive(tester, 'p-card'));
    final offered3 = await until(tester, find.byType(DeskPairingClipDialog));
    record('3 the phone\'s code link is offered on the In person panel', offered3 && hasText('A pairing code is on the clipboard'), safe(texts().take(12).join(' | ')));
    if (offered3) await tapKey(tester, deskClipUseKey);
    final w3 = await words(tester);
    record('3 in person: the desktop shows four words', w3.length == 4, w3.join(' '));
    await shot(tester, 'msg-06-in-person-words');
    send('d-sas3', w3.join(' '));
    record('no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
    // ignore: avoid_print
    print('RC DONE desk');
  });
}
