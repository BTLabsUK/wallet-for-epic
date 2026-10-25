// Wave 1 of the 0.1.0 feedback: the small desktop fixes that are not covered by their own
// files (F11, F17, F20, F21, F30, F31/B04, D06, M18, B11, O2's dialog, O7).
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_topics.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_http.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_receiving.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  int torOn = 0;

  @override
  Future<void> setTor(bool on) async {
    if (on) torOn++;
    return super.setTor(on);
  }
}

/// The local node just started: answering, at height 0 (O2).
class _NodeAtZero extends _Wallet {
  @override
  Future<ServiceStatus> status() async {
    final s = await super.status();
    return ServiceStatus(
      node: s.node,
      nodeHealth: ServiceHealth.slow,
      nodeHeight: 0,
      epicbox: s.epicbox,
      epicboxHealth: s.epicboxHealth,
      httpListener: s.httpListener,
      tor: s.tor,
      torCanSend: s.torCanSend,
      lastUpdate: s.lastUpdate,
    );
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, Widget child, {MockDeskWallet? api, bool refresh = true}) async {
  tester.view.physicalSize = const Size(1280, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api ?? _Wallet())]);
  addTearDown(container.dispose);
  if (refresh) await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.runAsync(() => advancedOn(container));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  return container;
}

Finder _input(String label) => find.descendant(of: find.widgetWithText(EField, label), matching: find.byType(EditableText));

void main() {
  group('amounts always carry decimals (D06)', () {
    test('four decimals at least, eight at most, thousands grouped', () {
      expect(formatEpic(0), '0.0000');
      expect(formatEpic(150000000), '1.5000');
      expect(formatEpic(123456789), '1.23456789');
      expect(formatEpic(1234500000000), '12,345.0000');
      expect(formatEpic(-50000000), '-0.5000');
      expect(formatEpic(100000000, minDecimals: 0), '1');
    });
  });

  group('wording', () {
    test('no Tor text states a duration (F21)', () {
      final tor = helpTopicsFor(3).where((t) => t.title == 'Tor');
      for (final t in tor) {
        expect('${t.short} ${t.bodyText}'.toLowerCase(), isNot(contains('minute')));
        expect(t.short, contains('Slower'));
        expect(t.short, contains('no ports to open'));
        expect(t.bodyText, contains('blocked or not allowed in some countries'));
      }
    });

    test('a payment found by a scan says so; an older entry makes no time claim (F17)', () {
      final t = Tx(
        id: 1,
        slateId: '',
        direction: TxDirection.received,
        state: TxState.confirmed,
        method: TxMethod.epicbox,
        amount: 1,
        fee: 0,
        created: DateTime(2026),
        foundByScan: true,
      );
      expect(whoOf(englishStrings, t), 'Found by scan');
      expect(whoTip(englishStrings, t), 'Found on the chain by a scan. The sender is not recorded.');
      expect(whoTip(englishStrings, t), isNot(contains('scan found')));
    });
  });

  testWidgets('Report a problem is the first block of Help (F20)', (tester) async {
    await _pump(tester, const SettingsHelpScreen());
    final report = tester.getTopLeft(find.text('Report a problem').first);
    final search = tester.getTopLeft(find.text('Search help').first);
    expect(report.dy, lessThan(search.dy));
  });

  testWidgets('the Internet guide says "the wallet answers" and offers Tor (F30)', (tester) async {
    InternetGuideChoice? choice;
    await _pump(
      tester,
      Builder(
        builder: (c) => EButton(
          label: 'guide',
          onPressed: () async => choice = await showEDialog<InternetGuideChoice>(c, builder: (_) => const InternetGuide(port: 3415, isPublic: false)),
        ),
      ),
      refresh: false,
    );
    await tester.tap(find.text('guide'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('The wallet answers on 0.0.0.0, port 3415'), findsOneWidget);
    expect(find.textContaining('Advanced'), findsNothing);
    expect(find.text('Tor works from anywhere with nothing to forward.'), findsOneWidget);
    await tester.tap(find.text('Turn on Tor'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(choice, InternetGuideChoice.tor);
    expect(find.byType(InternetGuide), findsNothing);
  });

  testWidgets('the Transactions page turns Tor on from the guide (F30)', (tester) async {
    final api = _Wallet();
    final container = await _pump(tester, const SettingsReceivingScreen(), api: api);
    // Link · HTTP on (its one switch since the methods split) shows the HTTP group with its
    // reach choice.
    await tester.runAsync(() async {
      final n = container.read(deskProvider.notifier);
      await n.saveSettings(container.read(deskProvider).settings.copyWith(payments: const PaymentPrefs(linkHttp: true)));
    });
    await tester.pump(const Duration(milliseconds: 600));
    await tester.ensureVisible(find.text('From the internet'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('From the internet'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(InternetGuide), findsOneWidget);
    await tester.tap(find.text('Turn on Tor'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(api.torOn, 1);
    expect(container.read(deskProvider).settings.tor, isTrue);
    expect(container.read(deskProvider).settings.publicMode, isFalse, reason: 'the HTTP mode is unchanged');
    expect(container.read(settingsPrefsProvider).jump?.section, SettingsJump.tor, reason: 'lands on the Tor switch (Privacy)');
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a contact form has no format hint and one error naming every accepted form (F31)', (tester) async {
    await _pump(tester, const ContactsScreen(arg: ContactsArgs(adding: true)));
    expect(find.textContaining('starts with “es”'), findsNothing);
    expect(find.textContaining('e.g. @epicbox'), findsNothing);
    for (final bad in ['http://', 'esShort', 'nonsense.onion', 'hello world']) {
      await tester.enterText(_input('Name'), 'Ann');
      await tester.enterText(_input('Address'), bad);
      await tester.pump();
      await tester.tap(find.text('Save contact'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Not a valid address. Use an Epicbox address (es5x…@epicbox.epiccash.com), a Link address (https://…) or an onion address (….onion).'), findsOneWidget, reason: '"$bad"');
    }
  });

  testWidgets('an empty contact list beside the form never says "No contacts match" (B04)', (tester) async {
    await _pump(tester, const ContactsScreen(arg: ContactsArgs(adding: true)));
    expect(find.text('No contacts match'), findsNothing);
    expect(find.text('Clear search'), findsNothing);
  });

  testWidgets('sending to the wallet\'s own Epicbox address is refused at review; "Balance after" (M18, F11)', (tester) async {
    final api = _Wallet();
    final own = await api.epicboxAddress();
    await _pump(tester, SendScreen(arg: SendArgs(recipient: own, amount: '1')), api: api);
    expect(find.text('Balance after'), findsOneWidget);
    expect(find.text('Left to spend'), findsNothing);
    await tester.tap(find.text('Review send'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text("This is the wallet's own address."), findsOneWidget);
    expect(find.text('Send 1.0000 EPIC'), findsNothing, reason: 'no review dialog');
  });

  // The own-address check: the key exactly, the server this one, missing or with :443 (M18).
  const ownKey = 'esWnT8kBf3yXqPZ2r9cLhVd7JmK4uA6gYsN1pQeRtC5vD8xHwF2b';
  for (final (to, refused) in [
    (ownKey, true),
    ('$ownKey@epicbox.epiccash.com:443', true),
    ('$ownKey@EPICBOX.epiccash.com', true),
    ('${ownKey.toLowerCase()}@epicbox.epiccash.com', false),
    ('$ownKey@epicbox.stackwallet.com', false),
  ]) {
    testWidgets('"$to" is ${refused ? '' : 'not '}the wallet\'s own address (M18)', (tester) async {
      final api = _Wallet();
      expect((await api.epicboxAddress()).split('@').first, ownKey);
      await _pump(tester, SendScreen(arg: SendArgs(recipient: to, amount: '1')), api: api);
      await tester.tap(find.text('Review send'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text("This is the wallet's own address."), refused ? findsOneWidget : findsNothing);
      // The review dialog that opens for another address starts a timer of its own.
      await tester.pumpAndSettle();
    });
  }

  testWidgets('no send while the local node is at height 0 (O2)', (tester) async {
    await _pump(tester, const SendScreen(arg: SendArgs(recipient: 'abc.onion', amount: '1')), api: _NodeAtZero());
    expect(find.text('Node not synced'), findsOneWidget);
    expect(find.text('Waiting for the node to sync.'), findsOneWidget);
  });

  testWidgets('an empty contact address says "Add an address."', (tester) async {
    await _pump(tester, const ContactsScreen(arg: ContactsArgs(adding: true)));
    await tester.enterText(_input('Name'), 'Ann');
    await tester.tap(find.text('Save contact'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Add an address.'), findsOneWidget);
  });

  testWidgets('the local node asks before it starts (O2)', (tester) async {
    bool? answer;
    await _pump(
      tester,
      Builder(builder: (c) => EButton(label: 'node', onPressed: () async => answer = await confirmLocalNode(c))),
      refresh: false,
    );
    await tester.tap(find.text('node'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Start the local node?'), findsOneWidget);
    expect(find.textContaining('disk space'), findsOneWidget);
    expect(find.textContaining('firewall'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(answer, isFalse);
    await tester.tap(find.text('node'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Start local node'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(answer, isTrue);
  });

  testWidgets('a toast closes when the screen changes (B11)', (tester) async {
    final container = await _pump(
      tester,
      Builder(builder: (c) => EButton(label: 'toast', onPressed: () => showEToast(c, 'Saved', tone: ETone.ok))),
      refresh: false,
    );
    await tester.tap(find.text('toast'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Saved'), findsOneWidget);
    container.read(deskNavProvider.notifier).go(DeskRoute.send);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('a toast shows its tone: tick only for done, alert for warn, error for risk', (tester) async {
    for (final (tone, icon) in [(ETone.ok, EIcons.okCircle), (ETone.warn, EIcons.alert), (ETone.risk, EIcons.error)]) {
      await _pump(tester, Builder(builder: (c) => EButton(label: 'toast', onPressed: () => showEToast(c, 'T', tone: tone))), refresh: false);
      await tester.tap(find.text('toast'));
      await tester.pump(const Duration(milliseconds: 300));
      final toast = find.byType(SnackBar);
      expect(find.descendant(of: toast, matching: find.byIcon(icon)), findsOneWidget, reason: '$tone');
      if (tone != ETone.ok) expect(find.descendant(of: toast, matching: find.byIcon(EIcons.okCircle)), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    }
  });

  testWidgets('a copy refused once is tried again (O7)', (tester) async {
    var calls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        calls++;
        if (calls == 1) throw PlatformException(code: 'Clipboard busy');
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await _pump(tester, const ECopyButton(text: 'x', label: 'Copy id', withLabel: true), refresh: false);
    await tester.tap(find.text('Copy id'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, 2);
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
