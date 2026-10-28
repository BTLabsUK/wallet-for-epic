// SPDX-License-Identifier: Apache-2.0
// Pairing between two real desktop apps (RFC 0002): this file runs in two app instances at
// once, each with its own HOME, keyring and wallet, which meet through files in RC_SYNC.
// RC_ROLE is A or B. Driven by tool/two_apps_check.sh, which builds the app once with this
// file as its entry and starts both under xvfb. Real LEPIC, the node in RC_NODE and the relay
// in RC_RELAY; no funds move. Never prints a phrase or a password.
//
//   (a) A's online invite link pasted into B: the same four words, both verified.
//   (d) B allows A's invoices, A asks B for a payment, B sees it named and verified and
//       declines it, A sees it declined.
//   (b)+(e) B removes the pairing and tells A (RFC 7.6): A marks it Removed by B. A's
//       pairing words typed into B pair them again.
//   (c) Both remove what they hold; face to face by pasting each other's card link.
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show AdvancedFeature;
import 'package:epic_wallet/src/app_log_io.dart' show startLogging;
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/invoices.dart' show PaymentRequestDraft, RequestState;
import 'package:epic_wallet/src/desktop/data/models.dart' show Contact, ServiceHealth;
import 'package:epic_wallet/src/desktop/data/pairing_state.dart'
    show deskOwnCardProvider, deskPairingApiProvider, deskSeenAsProvider;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider, deskProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show EDialog;
import 'package:epic_wallet/src/ui/pairing/pairing_parts.dart' show WordTiles;
import 'package:epic_wallet/src/wallet_service.dart' hide Contact;
import 'package:flutter/material.dart' show Scrollable, SelectableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

final String role = Platform.environment['RC_ROLE'] ?? 'A';
final String other = role == 'A' ? 'B' : 'A';
final String syncDir = Platform.environment['RC_SYNC'] ?? 'build/rc_sync';
final String nodeUrl = Platform.environment['RC_NODE'] ?? 'https://node.btlabs.uk';
final String relayHost = Platform.environment['RC_RELAY'] ?? 'epicbox.stackwallet.com';

const _names = {'A': 'Anna Desk', 'B': 'Ben Desk'};
String get myName => _names[role]!;
String get theirName => _names[other]!;

void rc(String step, bool pass, [String evidence = '']) => record('[$role] $step', pass, evidence);

/// Hands [value] to the other app under [key].
Future<void> put(WidgetTester tester, String key, String value) async {
  await tester.runAsync(() async {
    final tmp = File('$syncDir/$role-$key.tmp');
    await tmp.writeAsString(value);
    await tmp.rename('$syncDir/$role-$key');
  });
}

/// What the other app handed over under [key], waiting for it.
Future<String> take(WidgetTester tester, String key, {Duration timeout = const Duration(minutes: 6)}) async {
  final f = File('$syncDir/$other-$key');
  final end = DateTime.now().add(timeout);
  while (!(await tester.runAsync(f.exists))!) {
    if (DateTime.now().isAfter(end)) throw TestFailure('[$role] timed out waiting for $other-$key');
    await settle(tester, ms: 1000);
  }
  return (await tester.runAsync(f.readAsString))!;
}

/// Both apps reach [name] before either goes on.
Future<void> meet(WidgetTester tester, String name) async {
  await put(tester, 'at-$name', '1');
  await take(tester, 'at-$name');
}

Finder get dialogWords => find.descendant(of: find.byType(EDialog), matching: find.byType(WordTiles));

List<String> shownWords(WidgetTester tester) =>
    dialogWords.evaluate().isEmpty ? const [] : [for (final w in tester.widget<WordTiles>(dialogWords.first).words) w?.name ?? '?'];

Future<List<PairingRecord>> pairings(WidgetTester tester) async =>
    (await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).pairings()))!;

/// The pairing with the other app once verified, waiting for it; never one in [old].
Future<PairingRecord?> verifiedWithOther(WidgetTester tester, {Set<String> old = const {}}) async {
  final end = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(end)) {
    final r = (await pairings(tester))
        .where((p) => p.name == theirName && p.state == PairingState.verified && !old.contains(p.id))
        .firstOrNull;
    if (r != null) return r;
    await settle(tester, ms: 1000);
  }
  return null;
}

Future<PairingRecord?> wordsCheck(WidgetTester tester, String step) async {
  await pumpUntil(tester, () => dialogWords.evaluate().isNotEmpty, timeout: const Duration(minutes: 5), what: 'the words check');
  await settle(tester, ms: 800);
  final mine = shownWords(tester);
  await shot(tester, '$role-$step-words');
  await put(tester, '$step-words', mine.join(' '));
  final theirs = await take(tester, '$step-words');
  rc('$step: both apps show the same four words', mine.length == 4 && mine.join(' ') == theirs, '${mine.length} words, same: ${mine.join(' ') == theirs}');
  // The pairings held before this one: the check waits for the new one.
  final before = {for (final p in await pairings(tester)) if (p.state == PairingState.verified) p.id};
  await tester.tap(find.byKey(deskCheckMatchKey));
  await settle(tester, ms: 1500);
  final r = await verifiedWithOther(tester, old: before);
  rc('$step: verified', r != null, (await pairings(tester)).map((p) => '${p.name}:${p.state.name}').join(', '));
  await shot(tester, '$role-$step-verified');
  return r;
}

/// Pastes [text] under Enter link or words and presses Pair.
Future<void> enter(WidgetTester tester, String text) async {
  containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.pair);
  await settle(tester, ms: 1500);
  // Under the open way's panel: scrolled to first.
  await tester.ensureVisible(find.byKey(deskPairEnterKey));
  await settle(tester);
  await tester.enterText(find.byKey(deskPairEnterKey), text);
  await settle(tester);
  // Enter in the field, as a person may: the open way's panel can still grow above it while
  // its invite is made, which moves the Pair button under a tap.
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester, ms: 1500);
}

/// Answers the incoming invite dialog with Pair.
Future<void> answerIncoming(WidgetTester tester, String step) async {
  try {
    await pumpUntil(tester, () => find.byKey(deskIncomingPairKey).evaluate().isNotEmpty, timeout: const Duration(seconds: 90), what: 'Pair with $theirName?');
  } on TestFailure {
    await shot(tester, '$role-$step-no-incoming');
    rc('$step: the invite opens as Pair with $theirName?', false, texts().where((t) => t.length > 12).take(12).join(' | '));
    rethrow;
  }
  rc('$step: the invite opens as Pair with $theirName?', hasText('Pair with $theirName?'), texts().where((t) => t.contains(theirName)).take(1).join());
  await shot(tester, '$role-$step-incoming');
  await tester.tap(find.byKey(deskIncomingPairKey));
  await settle(tester, ms: 1500);
  await shot(tester, '$role-$step-waiting');
}

Future<void> removeAll(WidgetTester tester) async {
  final api = containerOf(tester).read(deskPairingApiProvider);
  for (final p in await pairings(tester)) {
    await tester.runAsync(() => p.state.isPaired ? api.removePairing(p.id) : api.cancelInvite(p.id));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('two apps pair: $role', (tester) async {
    captureErrors();
    final password = randomPassword();
    final events = <PairingEvent>[];
    await tester.runAsync(() => Directory(syncDir).create(recursive: true));
    await boot(tester);
    // The app's own log, under its data folder, for a step that goes wrong.
    await tester.runAsync(startLogging);

    // A fresh wallet on the given node and relay.
    await tapText(tester, 'Create a new wallet');
    await typeIn(tester, 0, password);
    await typeIn(tester, 1, password);
    await settle(tester);
    await tapText(tester, 'Create wallet', last: true);
    await waitText(tester, 'Recovery phrase', timeout: const Duration(minutes: 3));
    // A throwaway wallet: the phrase is shown but never read or kept.
    await tapText(tester, 'Reveal phrase');
    await tapText(tester, RegExp('[Ww]ritten down'));
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
    final desk = containerOf(tester).read(deskProvider.notifier);
    await tester.runAsync(() => desk.useNode(nodeUrl));
    await tester.runAsync(() => desk.useEpicbox(relayHost));
    // Pairing and Invoices are experimental switches, off by default: this check needs both.
    final settings = containerOf(tester).read(deskProvider).settings;
    await tester.runAsync(() => desk.saveSettings(settings.copyWith(advanced: settings.advanced.withExperimental(AdvancedFeature.invoices, true))));
    await settle(tester, ms: 5000);
    // The title bar shows icons (their words are tooltips): read the wallet's own status.
    final st = await tester.runAsync(() async {
      for (var i = 0; i < 60; i++) {
        final s = containerOf(tester).read(deskProvider).status;
        if (s != null && s.epicboxHealth == ServiceHealth.ok) return s;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      return containerOf(tester).read(deskProvider).status;
    });
    rc('the wallet uses ${Uri.parse(nodeUrl).host} and $relayHost',
        st != null && st.node.url.contains(Uri.parse(nodeUrl).host) && st.epicbox.domain.contains(relayHost) && st.epicboxHealth == ServiceHealth.ok,
        '${st?.node.url} ${st?.epicbox.domain} ${st?.epicboxHealth.name}');
    containerOf(tester).read(deskSeenAsProvider.notifier).set(myName);
    final sub = containerOf(tester).read(deskPairingApiProvider).events().listen(events.add);
    addTearDown(sub.cancel);
    await meet(tester, 'ready');

    // (a) An online invite link.
    containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.pair, DeskPairWay.message);
    await settle(tester, ms: 2000);
    if (role == 'A') {
      await tester.tap(find.byKey(deskPairCopyInviteKey));
      await settle(tester, ms: 2000);
      final invite = (await pairings(tester)).where((p) => p.way == PairingWay.link && p.inviteLink != null).firstOrNull;
      rc('a: Copy invite made an invite link', invite?.inviteLink?.startsWith('epiccash://pair/1/') ?? false, invite?.homeRelay ?? '');
      await shot(tester, 'A-a-invite');
      await put(tester, 'a-link', invite?.inviteLink ?? '');
    } else {
      await enter(tester, await take(tester, 'a-link'));
      await answerIncoming(tester, 'a');
    }
    await wordsCheck(tester, 'a');
    await meet(tester, 'a-done');

    // (d) Allow invoices, a request from A to B, declined by B.
    final withOther = (await verifiedWithOther(tester))!;
    String? bookId;
    if (role == 'A') {
      // A keeps B in its address book: the record a later key check starts from.
      final api = containerOf(tester).read(deskApiProvider);
      bookId = await tester.runAsync(() => api.saveContact(Contact(id: '', name: theirName)));
      await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).attach(withOther.id, bookId));
      rc('a: A saved B as a contact with the pairing', (await pairings(tester)).any((p) => p.id == withOther.id && p.contactId == bookId), '');
    }
    if (role == 'B') {
      await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).setAllowInvoices(withOther.id, true));
      rc('d: B allows invoices from A', (await pairings(tester)).any((p) => p.id == withOther.id && p.allowInvoices), '');
      await meet(tester, 'd-allowed');
      containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.invoices);
      final end = DateTime.now().add(const Duration(minutes: 4));
      while (DateTime.now().isBefore(end) && !hasText('Review')) {
        await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).collect(trigger: PairingCollectTrigger.pull));
        await settle(tester, ms: 4000);
      }
      final book = await tester.runAsync(() => containerOf(tester).read(deskApiProvider).invoices());
      final row = book?.waiting.firstOrNull;
      rc('d: B sees the request named Anna Desk, verified', row?.label == theirName && hasText('Verified'), '${book?.waiting.length} waiting, label ${row?.label}, ${row?.amount}');
      await shot(tester, 'B-d-to-pay');
      if (row != null) {
        // The "<name> is verified" offer to save the contact can land late; it is not this step.
        if (hasText('Not now')) {
          await tapText(tester, 'Not now');
          await settle(tester, ms: 800);
        }
        await tapText(tester, 'Review');
        await settle(tester, ms: 1500);
        await shot(tester, 'B-d-review');
        rc("d: B's Review shows A's message", hasText('RC order'), '');
        await tapText(tester, 'Decline');
        await settle(tester, ms: 800);
        await tapText(tester, 'Decline', last: true);
        await settle(tester, ms: 3000);
      }
      final after = await tester.runAsync(() => containerOf(tester).read(deskApiProvider).invoices());
      rc('d: B declined it', after?.waiting.isEmpty ?? false, '${after?.waiting.length} waiting');
      await put(tester, 'd-declined', '1');
    } else {
      await take(tester, 'at-d-allowed');
      await put(tester, 'at-d-allowed', '1');
      final req = await tester.runAsync(() => containerOf(tester).read(deskApiProvider).requestPayment(PaymentRequestDraft(pairingId: withOther.id, amount: 12345678, message: 'RC order')));
      rc('d: A asked B for 0.12345678 EPIC', req != null, '${req?.state.name}');
      await take(tester, 'd-declined');
      containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.invoices);
      await settle(tester, ms: 1000);
      if (hasText('Issue')) await tapText(tester, 'Issue');
      RequestState? state;
      final end = DateTime.now().add(const Duration(minutes: 4));
      while (DateTime.now().isBefore(end) && state != RequestState.declined) {
        await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).collect(trigger: PairingCollectTrigger.pull));
        await settle(tester, ms: 4000);
        state = (await tester.runAsync(() => containerOf(tester).read(deskApiProvider).invoices()))?.request(req!.slateId)?.state;
      }
      rc('d: A sees the request declined', state == RequestState.declined, '${state?.name}');
      await shot(tester, 'A-d-declined');
    }
    await meet(tester, 'd-done');

    // (b) + (e): B removes the pairing, A keeps it; A's words pair again, keys back on A.
    if (role == 'B') {
      await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).removePairing(withOther.id));
      rc('e: B removed the pairing', !(await pairings(tester)).any((p) => p.id == withOther.id), '');
      await put(tester, 'e-removed', '1');
      final words = await take(tester, 'b-words-code');
      rc('b: A handed over five pairing words', words.split(' ').length == 5, '${words.split(' ').length} words');
      if (words.split(' ').length == 5) {
        await enter(tester, words);
        await answerIncoming(tester, 'b');
        await wordsCheck(tester, 'b');
      }
      // B answers A's key check by collecting.
      final f = File('$syncDir/A-e-checked');
      final end = DateTime.now().add(const Duration(minutes: 5));
      while (DateTime.now().isBefore(end) && !(await tester.runAsync(f.exists))!) {
        await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).collect(trigger: PairingCollectTrigger.pull));
        await settle(tester, ms: 4000);
      }
    } else {
      await take(tester, 'e-removed');
      // B said it removed the pairing: A marks it Removed by B and keeps the record.
      final heardBy = DateTime.now().add(const Duration(minutes: 2));
      while (DateTime.now().isBefore(heardBy) && !events.any((e) => e.kind == PairingEventKind.unpaired)) {
        await tester.runAsync(() => containerOf(tester).read(deskPairingApiProvider).collect(trigger: PairingCollectTrigger.pull));
        await settle(tester, ms: 3000);
      }
      final marked = (await pairings(tester)).where((p) => p.name == theirName && p.removedByPeer).isNotEmpty;
      rc('e: A hears that B removed the pairing (Removed by)', events.any((e) => e.kind == PairingEventKind.unpaired) && marked, 'events ${events.map((e) => e.kind.name).toSet().join(',')}');
      containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.contacts);
      await settle(tester, ms: 1000);
      containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.pair, DeskPairWay.words);
      // Words go to the three meeting relays first: they take a few seconds to show.
      PairingRecord? code;
      final wordsBy = DateTime.now().add(const Duration(seconds: 60));
      while (DateTime.now().isBefore(wordsBy)) {
        await settle(tester, ms: 2000);
        code = (await pairings(tester)).where((p) => p.way == PairingWay.words && p.inviteWords.isNotEmpty).firstOrNull;
        if (code != null) break;
      }
      await shot(tester, 'A-b-code');
      rc('b: A shows five pairing words on $relayHost', code?.inviteWords.length == 5, code == null ? texts().where((t) => t.contains('relay') || t.contains('Epicbox')).take(2).join(' / ') : '');
      await put(tester, 'b-words-code', [for (final w in code?.inviteWords ?? const <SasWord>[]) w.name].join(' '));
      final fresh = code == null ? null : await wordsCheck(tester, 'b');
      rc('e: A and B pair again by words', fresh != null && fresh.state.isPaired, '${fresh?.state.name}');
      await put(tester, 'e-checked', '1');
      await shot(tester, 'A-e-paired-again');
    }
    await meet(tester, 'b-done');

    // (c) Face to face by card links.
    await removeAll(tester);
    await meet(tester, 'c-clean');
    if (role == 'A') {
      containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.pair, DeskPairWay.inPerson);
      await settle(tester, ms: 2000);
      // Under the fold since the name field sits above both panels.
      // Centred: at the bottom edge a toast can cover it.
      await Scrollable.ensureVisible(tester.element(find.byKey(deskPairCopyCardKey)), alignment: 0.5);
      await settle(tester, ms: 500);
      await tester.tap(find.byKey(deskPairCopyCardKey));
      // Making a card is a native call: give it its time.
      await pumpUntil(tester, () => containerOf(tester).read(deskOwnCardProvider) != null, timeout: const Duration(seconds: 60), what: 'A\'s card');
      final card = containerOf(tester).read(deskOwnCardProvider);
      rc('c: A made its card link', card?.link.startsWith('epiccash://contact/1/') ?? false, '');
      await shot(tester, 'A-c-card');
      await put(tester, 'c-card', card?.link ?? '');
      await enter(tester, await take(tester, 'c-card'));
    } else {
      // A fresh Pair page, as a user opens it again.
      containerOf(tester).read(deskNavProvider.notifier).go(DeskRoute.contacts);
      await settle(tester, ms: 1000);
      await enter(tester, await take(tester, 'c-card'));
      try {
        await pumpUntil(tester, () => find.byKey(deskCardBackLinkKey).evaluate().isNotEmpty, what: 'B\'s card to hand back');
      } on TestFailure {
        await shot(tester, 'B-c-no-card-back');
        rc('c: B read A\'s card and shows its own to hand back', false, texts().where((t) => t.length > 10).skip(10).take(14).join(' | '));
        rethrow;
      }
      final link = tester.widget<SelectableText>(find.byKey(deskCardBackLinkKey)).data ?? '';
      rc('c: B read A\'s card and shows its own to hand back', link.startsWith('epiccash://contact/1/'), '');
      await shot(tester, 'B-c-card-back');
      await put(tester, 'c-card', link);
      await tester.tap(find.byKey(deskCardBackCheckKey));
      await settle(tester, ms: 1000);
    }
    await wordsCheck(tester, 'c');
    await meet(tester, 'c-done');
    rc('no Flutter errors', flutterErrors.isEmpty, flutterErrors.take(3).join(' / '));
    // ignore: avoid_print
    print('RC DONE $role');
  });
}
