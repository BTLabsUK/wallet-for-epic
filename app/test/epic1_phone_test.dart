// SPDX-License-Identifier: Apache-2.0
// epic1 payments on the phone, a payment method beside the classic ones: its row in Settings ›
// Payments (applies at once), the epic1 link among Receive's other ways, the link flow on Send
// beside the classic form with the unknown server question, Try next and Sent, the stop that
// says epic1 is off for its links, codes and files, and contacts paid through either.
import 'package:epic_wallet/src/connection_state.dart' show WalletStatusNotifier, walletStatusProvider;
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/settings.dart' show appSettingsProvider;
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_common.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_receive.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_send.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_settings.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_entry.dart' show openScannedInPerson;
import 'package:epic_wallet/src/ui/in_person/in_person_screens.dart' show InPersonFormScreen;
import 'package:epic_wallet/src/ui/receive_other.dart' show epic1LinkWayKey;
import 'package:epic_wallet/src/ui/kit/kit_row.dart' show KitSwitch;
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_route.dart' show openEpic1Text;
import 'package:epic_wallet/src/ui/scan_screen.dart' show FakeQrScanner, qrScannerProvider;
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/status.dart' show EpicboxState, NodeState, WalletStatus;
import 'package:epic_wallet/src/ui/status.dart' as status show NodeStatus;
import 'package:epic_wallet/src/ui/theme/epic1_mark.dart' show Epic1Text;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

const _config = WalletConfig(
  dataDir: '/w',
  chain: Chain.mainnet,
  nodeUrl: 'https://node.example.invalid',
  epicboxDomain: 'relay.example.invalid',
  epicboxPort: 443,
);

final String _classic = 'es${'a' * 50}@relay.example.invalid';
const _link = 'epic:epic1qlink0000000000000000000000000000?amount=250000000';

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => _config;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

final _forty = WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: BigInt.from(4000000000),
  spendable: BigInt.from(4000000000),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

/// A session with 40 EPIC and epic1.
FakeWalletSession _session() => FakeWalletSession(summary: _forty)..epic1Fake = FakeEpic1();

/// The shown status with Epicbox in [epicbox] and the node online.
class _Epicbox extends WalletStatusNotifier {
  _Epicbox(this.epicbox);

  final EpicboxState? epicbox;

  @override
  WalletStatus build() => (node: const status.NodeStatus(NodeState.online), epicbox: epicbox);
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeWalletSession session,
  Widget home, {
  FakeWalletService? service,
  bool epic1 = true,
  List<Override> extra = const [],
}) async {
  final store = sendPinStore()..values['app.network'] = 'mainnet';
  if (!epic1) store.values['app.payment_prefs'] = PaymentPrefs.defaults.copyWith(epic1: false).encode();
  allowPinCheck(session, service);
  tester.view.physicalSize = const Size(1080, 3300);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(service ?? FakeWalletService(session: session)),
        secretStoreProvider.overrideWithValue(store),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        slateFilesProvider.overrideWithValue(FakeSlateFiles()),
        qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
        priceSourceProvider.overrideWithValue(_NoPrice()),
        backedUpProvider.overrideWith((ref) async => true),
        sessionProvider.overrideWith(() => _Open(session)),
        walletConfigProvider.overrideWith(_Config.new),
        ...extra,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  // The app watches its settings from the start; a bare page does not, so load them here.
  await container.read(appSettingsProvider.future);
  return container;
}

/// The secret store [_pump] gave the app: where the payment settings are kept.
String? _storedPayments(ProviderContainer c) => (c.read(secretStoreProvider) as dynamic).values['app.payment_prefs'] as String?;

const _settings = SettingsSectionScreen(section: SettingsSection.transactions);

Finder _key(Key key) => find.byKey(key);

/// A title that names epic1: drawn with the mark, so found by its whole text.
Finder _e1(String text) => find.byWidgetPredicate((w) => w is Epic1Text && w.text == text);

bool _switchOn(WidgetTester tester) =>
    tester.widget<KitSwitch>(find.descendant(of: _key(epic1SwitchKey), matching: find.byType(KitSwitch))).value;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Fifteen frames a tenth of a second apart: for screens with a spinner that never settles.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapFrames(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _frames(tester);
}

void main() {
  group('Settings › Payments', () {
    testWidgets('the epic1 row follows Epicbox, on by default, with Printed links under it', (tester) async {
      await _pump(tester, _session(), _settings);
      expect(_key(epic1SwitchKey), findsOneWidget);
      expect(_switchOn(tester), isTrue);
      expect(_key(epic1PrintedKey), findsOneWidget);
      final epicbox = tester.getTopLeft(_key(const ValueKey('tx-epicbox'))).dy;
      final epic1 = tester.getTopLeft(_key(epic1SwitchKey)).dy;
      final printed = tester.getTopLeft(_key(epic1PrintedKey)).dy;
      expect(epicbox, lessThan(epic1));
      expect(epic1, lessThan(printed));
      // No mode rows, no pending line.
      expect(_e1(_l.deskE1SetSwitch), findsOneWidget);
    });

    testWidgets('turning it off applies at once: Printed links goes, the setting is kept', (tester) async {
      final container = await _pump(tester, _session(), _settings);
      await _tap(tester, _key(epic1SwitchKey));
      expect(_switchOn(tester), isFalse);
      expect(_key(epic1PrintedKey), findsNothing);
      expect(container.read(epic1OnProvider), isFalse);
      expect(_storedPayments(container), contains('noepic1'));
      expect(_key(const ValueKey('tx-epicbox')), findsOneWidget);

      await _tap(tester, _key(epic1SwitchKey));
      expect(_switchOn(tester), isTrue);
      expect(container.read(epic1OnProvider), isTrue);
      expect(_key(epic1PrintedKey), findsOneWidget);
    });

    testWidgets('a wallet that kept it off opens with it off', (tester) async {
      final container = await _pump(tester, _session(), _settings, epic1: false);
      expect(_switchOn(tester), isFalse);
      expect(_key(epic1PrintedKey), findsNothing);
      expect(container.read(epic1OnProvider), isFalse);
    });

    testWidgets('Printed links: each with Retire, which asks first', (tester) async {
      final session = _session();
      await session.epic1Fake.makeLink(kind: Epic1LinkKind.printed, relays: const ['relay.example.invalid']);
      await session.epic1Fake.makeLink(kind: Epic1LinkKind.printed, relays: const ['relay.example.invalid']);
      await _pump(tester, session, _settings);
      expect(find.descendant(of: _key(epic1PrintedKey), matching: find.text(_l.deskE1PhPrintedCount(2, epic1PrintedMax))), findsOneWidget);
      await _tap(tester, _key(epic1PrintedKey));
      expect(_key(const ValueKey('epic1-printed-0')), findsOneWidget);
      expect(_key(const ValueKey('epic1-printed-1')), findsOneWidget);
      await _tap(tester, _key(const ValueKey('epic1-retire-0')));
      await _tap(tester, _key(const ValueKey('epic1-retire-yes')));
      expect(_key(const ValueKey('epic1-printed-0')), findsNothing);
      expect(_key(const ValueKey('epic1-printed-1')), findsOneWidget);
    });
  });

  group('Receive', () {
    const receive = SlotScaffold(body: ReceiveView());

    Future<void> openOther(WidgetTester tester) => _tap(tester, find.text(_l.phoneRecvOther));

    testWidgets('epic1 on: the classic layout stays; the epic1 link is the first of the other ways', (tester) async {
      final session = _session();
      await _pump(tester, session, receive);
      expect(_key(receiveAddressKey), findsOneWidget);
      expect(_key(receiveRequestKey), findsOneWidget);
      expect(_key(epic1LinkCardKey), findsNothing);
      // No link is made before the row is opened.
      expect(session.epic1Fake.calls, isNot(contains('makeLink')));

      await openOther(tester);
      expect(_key(epic1LinkWayKey), findsOneWidget);
      expect(find.text(_l.deskE1LinkTitle), findsOneWidget);
      expect(find.text(_l.deskE1LinkSub), findsOneWidget);
      expect(session.epic1Fake.calls, isNot(contains('makeLink')));
      // First in the sheet.
      expect(tester.getTopLeft(_key(epic1LinkWayKey)).dy, lessThan(tester.getTopLeft(find.text(_l.phoneSettingsWithFile)).dy));
    });

    testWidgets('the epic1 link row opens the link page: QR, Copy link, Ask amount, Request in person; back returns', (tester) async {
      final session = _session();
      await _pump(tester, session, receive);
      await openOther(tester);
      await _tap(tester, _key(epic1LinkWayKey));
      expect(find.byType(Epic1ReceiveView), findsOneWidget);
      expect(_key(epic1LinkCardKey), findsOneWidget);
      expect(_key(epic1QrKey), findsOneWidget);
      expect(_key(epic1CopyLinkKey), findsOneWidget);
      expect(_key(epic1AskAmountKey), findsOneWidget);
      expect(_key(epic1RequestInPersonKey), findsOneWidget);
      expect(session.epic1Fake.calls, contains('makeLink'));

      await _tap(tester, find.byTooltip(MaterialLocalizations.of(tester.element(find.byType(Epic1ReceivePage))).backButtonTooltip));
      expect(find.byType(Epic1ReceiveView), findsNothing);
      expect(_key(receiveAddressKey), findsOneWidget);
    });

    testWidgets('epic1 off: no epic1 row among the other ways', (tester) async {
      final session = _session();
      await _pump(tester, session, receive, epic1: false);
      expect(_key(receiveAddressKey), findsOneWidget);
      await openOther(tester);
      expect(_key(epic1LinkWayKey), findsNothing);
      expect(session.epic1Fake.calls, isNot(contains('makeLink')));
    });

    testWidgets('turned off in Settings, Receive drops the row at once', (tester) async {
      final session = _session();
      await _pump(tester, session, _settings);
      await _tap(tester, _key(epic1SwitchKey));
      Navigator.of(tester.element(find.byType(SettingsSectionScreen))).push(MaterialPageRoute<void>(builder: (_) => receive));
      await tester.pumpAndSettle();
      await openOther(tester);
      expect(_key(epic1LinkWayKey), findsNothing);
    });

    testWidgets('the link page: the listening line follows Epicbox', (tester) async {
      String line(WidgetTester tester) =>
          tester.widget<Text>(find.descendant(of: _key(epic1ListeningKey), matching: find.byType(Text))).data!;
      for (final (state, word) in [
        (EpicboxState.online, _l.phoneRecvListening),
        (EpicboxState.connecting, _l.statusEpicboxConnecting),
        (EpicboxState.offline, _l.statusEpicboxOffline),
        (null, _l.statusEpicboxOffline),
        (EpicboxState.blocked, _l.statusEpicboxBlocked),
      ]) {
        await _pump(tester, _session(), const Epic1ReceivePage(), extra: [walletStatusProvider.overrideWith(() => _Epicbox(state))]);
        expect(line(tester), word, reason: '$state');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('Send', () {
    Widget send() => SlotScaffold(appBar: AppBar(), body: SendView(onDone: () {}));

    test('an epic1 link is recognised on both networks', () {
      expect(looksLikeEpic1Link('epic:epic1qlink0000000000000000000000000000'), isTrue);
      expect(looksLikeEpic1Link('epic:tepic1qlink0000000000000000000000000000?epicbox=a%40b'), isTrue);
      expect(looksLikeEpic1Link('tepic1qlink0000000000000000000000000000'), isTrue);
      expect(looksLikeEpic1Link('zzQGPvjAfqxm9VhHSdsTPFQznkQmdKMTiAMEka5d5eQBUXkWivgC'), isFalse);
    });

    testWidgets('epic1 on: the classic form is the start, and a classic address is taken as it always was', (tester) async {
      await _pump(tester, _session(), send());
      expect(_key(sendRecipientFieldKey), findsOneWidget);
      await tester.enterText(_key(sendRecipientFieldKey), _classic);
      await tester.pumpAndSettle();
      expect(find.byType(Epic1LinkSendScreen), findsNothing);
      expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsNothing);
      expect(_key(epic1FieldSettingsKey), findsNothing);
    });

    testWidgets('epic1 on: a link with an unknown server asks, reviews, waits, tries the next, then Sent; a classic address works after', (tester) async {
      final session = _session();
      session.epic1Fake
        ..linkHosts = const [
          Epic1Host(host: 'first.example.invalid', port: 443, inRelayList: false),
          Epic1Host(host: 'second.example.invalid', port: 443, inRelayList: true),
        ]
        ..failPosts.add('first.example.invalid');
      final container = await _pump(tester, session, send());
      await tester.enterText(_key(sendRecipientFieldKey), _link);
      await _frames(tester);

      expect(find.text(_l.deskE1PhUnknownTitle), findsOneWidget);
      await _tapFrames(tester, _key(epic1UseServerKey));
      expect(find.descendant(of: _key(epic1ReviewServerKey), matching: find.textContaining('first.example.invalid')), findsOneWidget);
      expect(_key(epic1ReviewAmountKey), findsOneWidget);

      await _tapFrames(tester, _key(epic1SendButtonKey));
      await answerPin(tester, settle: false);
      await _frames(tester);
      expect(_key(epic1WaitingKey), findsOneWidget);
      expect(find.text(_l.deskE1PhNotTaken('first.example.invalid')), findsOneWidget);
      expect(_key(epic1CancelUnlockKey), findsOneWidget);

      await _tapFrames(tester, _key(epic1TryNextKey));
      expect(session.epic1Fake.calls, contains('postNext'));
      expect(_key(epic1TryNextKey), findsNothing);
      expect(find.descendant(of: _key(epic1ReviewServerKey), matching: find.textContaining('second.example.invalid')), findsOneWidget);

      // The recipient answered: the payment moved on.
      session.transactionsValue = [
        fakeTx(id: 1, slateId: '00000000-0000-4000-8000-000000000002', kind: TxKind.sent, status: TxStatus.awaitingConfirmation),
      ];
      container.invalidate(homeProvider);
      await _frames(tester);
      expect(_key(epic1SentKey), findsOneWidget);
      await _tapFrames(tester, _key(epic1DoneKey));

      // Back on the classic form, empty; a classic address goes on in the same session.
      expect(_key(sendRecipientFieldKey), findsOneWidget);
      expect(tester.widget<TextField>(_key(sendRecipientFieldKey)).controller!.text, isEmpty);
      await tester.enterText(_key(sendRecipientFieldKey), _classic);
      await tester.pumpAndSettle();
      expect(find.byType(Epic1LinkSendScreen), findsNothing);
    });

    testWidgets('epic1 on: a link on a listed server reviews with no question and pays', (tester) async {
      final session = _session();
      await _pump(tester, session, send());
      await tester.enterText(_key(sendRecipientFieldKey), _link);
      await _frames(tester);
      expect(find.text(_l.deskE1PhUnknownTitle), findsNothing);
      expect(_key(epic1ReviewServerKey), findsOneWidget);

      await _tapFrames(tester, _key(epic1SendButtonKey));
      await answerPin(tester, settle: false);
      await _frames(tester);
      expect(session.epic1Fake.calls, contains('payLink'));
      expect(_key(epic1WaitingKey), findsOneWidget);
    });

    testWidgets('epic1 on: a bare epic1 address gets its line, a mistyped link "not an epic1 link"', (tester) async {
      await _pump(tester, _session(), send());
      await tester.enterText(_key(sendRecipientFieldKey), 'epic:epic1qlink0000000000000000000000000000');
      await tester.pumpAndSettle();
      expect(find.text(_l.epic1AddressAlone), findsOneWidget);
      expect(find.byType(Epic1LinkSendScreen), findsNothing);
    });

    testWidgets('epic1 off: a link stops with the off line and Settings, which opens the Payments row', (tester) async {
      await _pump(tester, _session(), send(), epic1: false);
      await tester.enterText(_key(sendRecipientFieldKey), _link);
      await tester.pumpAndSettle();
      expect(find.byType(Epic1LinkSendScreen), findsNothing);
      expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsOneWidget);
      expect(_key(epic1FieldSettingsKey), findsOneWidget);
      await _tap(tester, _key(epic1FieldSettingsKey));
      expect(_key(epic1SwitchKey), findsOneWidget);
      // Turning it on there applies at once.
      await _tap(tester, _key(epic1SwitchKey));
      expect(_switchOn(tester), isTrue);
    });

    testWidgets('epic1 off: a classic address is paid as ever', (tester) async {
      await _pump(tester, _session(), send(), epic1: false);
      await tester.enterText(_key(sendRecipientFieldKey), _classic);
      await tester.pumpAndSettle();
      expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsNothing);
      expect(_key(epic1FieldSettingsKey), findsNothing);
    });

    testWidgets('epic1 on: No address? offers Pay in person for epic1; off: it does not', (tester) async {
      await _pump(tester, _session(), send());
      await _tap(tester, find.text(_l.sendNoAddress));
      expect(_key(epic1PayInPersonKey), findsOneWidget);
      await _tap(tester, _key(epic1PayInPersonKey));
      expect(find.byType(InPersonFormScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _session(), send(), epic1: false);
      final noAddress = find.text(_l.sendNoAddress);
      if (noAddress.evaluate().isNotEmpty) {
        await _tap(tester, noAddress);
        expect(_key(epic1PayInPersonKey), findsNothing);
      }
    });
  });

  group('Scan', () {
    /// A button that hands [text] to the scan's epic1 check, keeping what it answered.
    Widget scanOf(String text, List<bool> taken) => Scaffold(
      body: Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () async => taken.add(await openEpic1Text(context, ref, text)),
          child: const Text('scan'),
        ),
      ),
    );

    testWidgets('epic1 off: an epic1 link stops with the off line and Settings', (tester) async {
      final taken = <bool>[];
      await _pump(tester, _session(), scanOf(_link, taken), epic1: false);
      await _tap(tester, find.text('scan'));
      // The answer comes when the stop is closed; Settings closes it and opens the row.
      expect(taken, isEmpty);
      expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsOneWidget);
      await _tap(tester, _key(epic1ModeSettingsKey));
      expect(_key(epic1SwitchKey), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(taken, [true]);
    });

    testWidgets('epic1 off: an epic1 file stops the same way', (tester) async {
      final taken = <bool>[];
      await _pump(tester, _session(), scanOf('BEGINEPICTX.abc', taken), epic1: false);
      await _tap(tester, find.text('scan'));
      expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsOneWidget);
      await _tap(tester, find.text(_l.commonClose));
      expect(taken, [true]);
    });

    testWidgets('epic1 off: a classic address is left to the classic route', (tester) async {
      final taken = <bool>[];
      await _pump(tester, _session(), scanOf(_classic, taken), epic1: false);
      await _tap(tester, find.text('scan'));
      expect(taken, [false]);
      expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsNothing);
    });

    testWidgets('epic1 on: an epic1 link opens its pay flow; a classic address is left to the classic route', (tester) async {
      final taken = <bool>[];
      await _pump(tester, _session(), scanOf(_classic, taken));
      await _tap(tester, find.text('scan'));
      expect(taken, [false]);

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, _session(), scanOf(_link, taken));
      await _tapFrames(tester, find.text('scan'));
      expect(find.byType(Epic1LinkSendScreen), findsOneWidget);
      // The answer comes when the pay flow is left.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await _frames(tester);
      expect(taken, [false, true]);
    });

    testWidgets('an animated payment QR is left to the QR Payment reader, epic1 on or off', (tester) async {
      for (final on in [true, false]) {
        final taken = <bool>[];
        await _pump(tester, _session(), scanOf('ur:epic-slate/1-3/lpadaxcfaxhl', taken), epic1: on);
        await _tap(tester, find.text('scan'));
        expect(taken, [false], reason: 'epic1 on: $on');
        expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });

    // The QR Payment reader reads a whole animated in-person code too (an in-person code and a
    // payment share the animated type), and hands its bytes here.
    Widget wholeOf(List<int> bytes) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => openScannedInPerson(context, Uint8List.fromList(bytes)),
          child: const Text('scan'),
        ),
      ),
    );

    final request = [InPersonStage.request.index, ...List.filled(32, 7)];

    testWidgets('epic1 off: a whole animated in-person code stops with the off line', (tester) async {
      final session = _session();
      await _pump(tester, session, wholeOf(request), epic1: false);
      await _tap(tester, find.text('scan'));
      expect(find.text(_l.netBlockMethodOff(_l.deskE1SetSwitch)), findsOneWidget);
      expect(session.epic1Fake.calls, isNot(contains('inPersonRead')));
    });

    testWidgets('epic1: a whole animated in-person request opens its review', (tester) async {
      final session = _session();
      await _pump(tester, session, wholeOf(request));
      await _tapFrames(tester, find.text('scan'));
      expect(session.epic1Fake.calls, contains('inPersonRead'));
      expect(find.text(_l.deskIpPayRequestTitle), findsWidgets);
    });

    testWidgets('epic1: a code for another network says so', (tester) async {
      final session = _session();
      session.epic1Fake.failNext = const WalletError(kind: WalletErrorKind.epic1WrongNetwork, message: 'floonet');
      await _pump(tester, session, wholeOf(request));
      await _tapFrames(tester, find.text('scan'));
      expect(find.text(_l.deskE1ErrCodeWrongNetwork), findsOneWidget);
    });

    testWidgets('epic1: an altered code that is no answer either is refused', (tester) async {
      final session = _session();
      await _pump(tester, session, wholeOf([9, ...List.filled(32, 7)]));
      await _tapFrames(tester, find.text('scan'));
      expect(session.epic1Fake.calls, containsAllInOrder(['inPersonRead', 'inPersonTake']));
      expect(find.text(_l.deskE1ErrNotInPerson), findsOneWidget);
    });
  });
}
