// SPDX-License-Identifier: Apache-2.0
// epic1 payments on the phone (ui-spec P1-P4, D3, D7): the Experimental switch with its
// confirm and "Applies at next unlock", the epic1 section in epic1 mode, the link card on
// Receive, the link flow on Send with the unknown server question, Try next and Sent, the
// mode lines for the other mode's codes, "Classic only" contacts, and the setting kept per
// wallet across lock and unlock.
import 'package:epic_wallet/src/connection_state.dart' show WalletStatusNotifier, walletStatusProvider;
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/epic1_hosts.dart' show acceptedRelaysIn;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/settings_file/host_settings.dart' show HostSettings, hostSettings;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_common.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_receive.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_send.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_settings.dart';
import 'package:epic_wallet/src/ui/in_person/in_person_entry.dart' show openScannedInPerson;
import 'package:epic_wallet/src/ui/kit/kit_row.dart' show KitSwitch;
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_route.dart' show openEpic1Text;
import 'package:epic_wallet/src/ui/scan_screen.dart' show FakeQrScanner, qrScannerProvider;
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/ui/status.dart' show EpicboxState, NodeState, WalletStatus;
import 'package:epic_wallet/src/ui/status.dart' as status show NodeStatus;
import 'package:epic_wallet/src/ui/theme/epic1_mark.dart' show Epic1Text;
import 'package:epic_wallet/src/ui/tour/tour_target.dart' show PhoneTourTarget;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
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

/// A session with 40 EPIC, in epic1 mode when [on].
FakeWalletSession _session({bool on = false}) => FakeWalletSession(summary: _forty)..epic1Fake = FakeEpic1(on: on);

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
  List<Override> extra = const [],
}) async {
  allowPinCheck(session, service);
  tester.view.physicalSize = const Size(1080, 3300);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(service ?? FakeWalletService(session: session)),
        secretStoreProvider.overrideWithValue(sendPinStore()..values['app.network'] = 'mainnet'),
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
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

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

/// The [PhoneTourTarget] [id] around [inner].
Finder _tourTarget(String id, Finder inner) =>
    find.ancestor(of: inner, matching: find.byWidgetPredicate((w) => w is PhoneTourTarget && w.id == id));

void main() {
  // "Use server" writes the settings ([acceptedRelaysIn]): each test starts from the same ones.
  late HostSettings saved;
  setUp(() => saved = hostSettings);
  tearDown(() => hostSettings = saved);

  group('Settings › Transactions', () {
    testWidgets('classic: the methods, then Experimental; turning on asks, then Applies at next unlock', (tester) async {
      final session = _session();
      await _pump(tester, session, _settings);
      expect(_key(const ValueKey('tx-epicbox')), findsOneWidget);
      expect(find.text(_l.deskE1PhExperimental), findsOneWidget);
      expect(_switchOn(tester), isFalse);
      expect(_key(epic1EpicboxKey), findsNothing);
      expect(_key(epic1AppliesKey), findsNothing);

      // Cancel on the confirm keeps it off.
      await _tap(tester, _key(epic1SwitchKey));
      expect(_e1(_l.deskE1PhConfirmTitle), findsOneWidget);
      await _tap(tester, find.text(_l.commonCancel));
      expect(_switchOn(tester), isFalse);
      expect(session.epic1Fake.storedOn, isFalse);

      await _tap(tester, _key(epic1SwitchKey));
      await _tap(tester, _key(epic1TurnOnKey));
      expect(_switchOn(tester), isTrue);
      expect(session.epic1Fake.storedOn, isTrue);
      expect(session.epic1Fake.inUse, isFalse);
      expect(_key(epic1AppliesKey), findsOneWidget);
      expect(_key(epic1LockNowKey), findsOneWidget);
      // This unlock stays classic.
      expect(_key(const ValueKey('tx-epicbox')), findsOneWidget);
      expect(_key(epic1EpicboxKey), findsNothing);

      // Back to what is in use: the line goes.
      await _tap(tester, _key(epic1SwitchKey));
      expect(_switchOn(tester), isFalse);
      expect(_key(epic1AppliesKey), findsNothing);
    });

    testWidgets('epic1: the epic1 section, Receiving and Experimental in place of the methods', (tester) async {
      final session = _session(on: true);
      await _pump(tester, session, _settings);
      expect(_key(const ValueKey('tx-epicbox')), findsNothing);
      expect(_e1(_l.deskE1PhSection), findsOneWidget);
      expect(_key(epic1EpicboxKey), findsOneWidget);
      expect(find.descendant(of: _key(epic1EpicboxKey), matching: find.textContaining('relay.example.invalid')), findsOneWidget);
      expect(_key(epic1PrintedKey), findsOneWidget);
      expect(find.text(_l.deskE1PhReceiving), findsOneWidget);
      expect(_switchOn(tester), isTrue);

      // Turning off asks nothing; it applies at the next unlock.
      await _tap(tester, _key(epic1SwitchKey));
      expect(_e1(_l.deskE1PhConfirmTitle), findsNothing);
      expect(session.epic1Fake.storedOn, isFalse);
      expect(_key(epic1AppliesKey), findsOneWidget);
      expect(_key(epic1EpicboxKey), findsOneWidget);
    });

    testWidgets('Printed links: each with Retire, which asks first', (tester) async {
      final session = _session(on: true);
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

    testWidgets('the setting is kept per wallet across lock and unlock', (tester) async {
      final service = FakeWalletService(existingWallets: {_config.dataDir});
      var session = await service.open(config: _config, password: service.password) as FakeWalletSession;
      expect(session.paymentMode, PaymentMode.classic);
      await _pump(tester, session, _settings, service: service);
      await _tap(tester, _key(epic1SwitchKey));
      await _tap(tester, _key(epic1TurnOnKey));
      expect(_key(epic1AppliesKey), findsOneWidget);

      // Next unlock: epic1 mode, no pending line.
      session = await service.open(config: _config, password: service.password) as FakeWalletSession;
      expect(session.paymentMode, PaymentMode.epic1);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, session, _settings, service: service);
      expect(_key(epic1EpicboxKey), findsOneWidget);
      expect(_key(epic1AppliesKey), findsNothing);
      await _tap(tester, _key(epic1SwitchKey));
      expect(_key(epic1AppliesKey), findsOneWidget);

      // And off again at the unlock after.
      session = await service.open(config: _config, password: service.password) as FakeWalletSession;
      expect(session.paymentMode, PaymentMode.classic);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, session, _settings, service: service);
      expect(_key(const ValueKey('tx-epicbox')), findsOneWidget);
      expect(_key(epic1EpicboxKey), findsNothing);
      expect(_switchOn(tester), isFalse);
    });
  });

  group('Receive', () {
    const receive = SlotScaffold(body: ReceiveView());

    testWidgets('epic1: the link card with its QR, Copy link and Share', (tester) async {
      final session = _session(on: true);
      await _pump(tester, session, receive);
      expect(_key(epic1LinkCardKey), findsOneWidget);
      expect(_key(epic1QrKey), findsOneWidget);
      expect(_key(epic1CopyLinkKey), findsOneWidget);
      expect(_key(epic1AskAmountKey), findsOneWidget);
      expect(_key(epic1RequestInPersonKey), findsOneWidget);
      // The tour's Receive step lights the link card.
      expect(_tourTarget('tour-receive-address', _key(epic1LinkCardKey)), findsOneWidget);
      expect(session.epic1Fake.calls, contains('makeLink'));
    });

    testWidgets('epic1: the listening line follows Epicbox', (tester) async {
      String line(WidgetTester tester) =>
          tester.widget<Text>(find.descendant(of: _key(epic1ListeningKey), matching: find.byType(Text))).data!;
      for (final (state, word) in [
        (EpicboxState.online, _l.phoneRecvListening),
        (EpicboxState.connecting, _l.statusEpicboxConnecting),
        (EpicboxState.offline, _l.statusEpicboxOffline),
        (null, _l.statusEpicboxOffline),
        (EpicboxState.blocked, _l.statusEpicboxBlocked),
      ]) {
        await _pump(tester, _session(on: true), receive, extra: [walletStatusProvider.overrideWith(() => _Epicbox(state))]);
        expect(line(tester), word, reason: '$state');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('epic1 turned off in Settings: Receive shows the Epicbox address at once', (tester) async {
      final session = _session(on: true);
      final container = await _pump(tester, session, _settings);
      await _tap(tester, _key(epic1SwitchKey));
      expect(session.epic1Fake.storedOn, isFalse);
      expect(session.epic1Fake.inUse, isTrue);
      expect(container.read(receiveModeProvider), PaymentMode.classic);

      Navigator.of(tester.element(find.byType(SettingsSectionScreen))).push(MaterialPageRoute<void>(builder: (_) => receive));
      await tester.pumpAndSettle();
      expect(find.byType(Epic1ReceiveView), findsNothing);
      expect(_key(epic1LinkCardKey), findsNothing);
      expect(_key(receiveAddressKey), findsOneWidget);
      expect(_key(receiveRequestKey), findsOneWidget);
    });

    testWidgets('epic1 turned on in a classic unlock: Receive waits for the next unlock', (tester) async {
      final session = _session();
      final container = await _pump(tester, session, _settings);
      await _tap(tester, _key(epic1SwitchKey));
      await _tap(tester, _key(epic1TurnOnKey));
      expect(session.epic1Fake.storedOn, isTrue);
      expect(container.read(receiveModeProvider), PaymentMode.classic);
    });

    testWidgets('classic: no link card', (tester) async {
      await _pump(tester, _session(), receive);
      expect(_key(epic1LinkCardKey), findsNothing);
      expect(find.byType(Epic1ReceiveView), findsNothing);
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

    testWidgets('epic1: a classic address says so, with Settings', (tester) async {
      await _pump(tester, _session(on: true), send());
      expect(_key(epic1SendFieldKey), findsOneWidget);
      expect(_key(sendRecipientFieldKey), findsNothing);
      // The tour's Send step lights the link field.
      expect(_tourTarget('tour-send-recipient', _key(epic1SendFieldKey)), findsOneWidget);
      await tester.enterText(_key(epic1SendFieldKey), _classic);
      await _tap(tester, _key(epic1SendContinueKey));
      expect(find.text(_l.deskE1ModeClassicAddress), findsOneWidget);
      expect(_key(epic1FieldSettingsKey), findsOneWidget);
    });

    testWidgets('epic1: a link with an unknown server asks, reviews, waits, tries the next, then Sent', (tester) async {
      final session = _session(on: true);
      session.epic1Fake
        ..linkHosts = const [
          Epic1Host(host: 'first.example.invalid', port: 443, inRelayList: false),
          Epic1Host(host: 'second.example.invalid', port: 443, inRelayList: true),
        ]
        ..failPosts.add('first.example.invalid');
      final container = await _pump(tester, session, send());
      await tester.enterText(_key(epic1SendFieldKey), _link);
      await _tapFrames(tester, _key(epic1SendContinueKey));

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
      expect(_key(epic1SendFieldKey), findsOneWidget);
    });

    testWidgets('epic1: a link through a listed server the wallet is not on reviews with no question', (tester) async {
      // LEPIC knows only the relay in use; the link names another of the Epicbox list, port written.
      final listed = hostSettings.epicboxServers.last;
      final session = _session(on: true);
      session.epic1Fake.linkHosts = [Epic1Host(host: listed.host.toUpperCase(), port: listed.port)];
      await _pump(tester, session, send());
      await tester.enterText(_key(epic1SendFieldKey), _link);
      await _tapFrames(tester, _key(epic1SendContinueKey));
      expect(find.text(_l.deskE1PhUnknownTitle), findsNothing);
      expect(_key(epic1ReviewServerKey), findsOneWidget);
    });

    testWidgets('epic1: "Use server" is kept, the next link through that server asks nothing', (tester) async {
      const hosts = [Epic1Host(host: 'relay.example.invalid', port: 443)];
      final session = _session(on: true);
      session.epic1Fake.linkHosts = hosts;
      await _pump(tester, session, send());
      await tester.enterText(_key(epic1SendFieldKey), _link);
      await _tapFrames(tester, _key(epic1SendContinueKey));
      expect(find.text(_l.deskE1PhUnknownTitle), findsOneWidget);
      await _tapFrames(tester, _key(epic1UseServerKey));
      expect(acceptedRelaysIn(hostSettings).map((r) => r.label), ['relay.example.invalid']);

      final next = _session(on: true);
      next.epic1Fake.linkHosts = hosts;
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, next, send());
      await tester.enterText(_key(epic1SendFieldKey), _link);
      await _tapFrames(tester, _key(epic1SendContinueKey));
      expect(find.text(_l.deskE1PhUnknownTitle), findsNothing);
      expect(_key(epic1ReviewServerKey), findsOneWidget);
    });

    testWidgets('epic1: a link on a listed server reviews with no question and pays', (tester) async {
      final session = _session(on: true);
      await _pump(tester, session, send());
      await tester.enterText(_key(epic1SendFieldKey), _link);
      await _tapFrames(tester, _key(epic1SendContinueKey));
      expect(find.text(_l.deskE1PhUnknownTitle), findsNothing);
      expect(_key(epic1ReviewServerKey), findsOneWidget);

      await _tapFrames(tester, _key(epic1SendButtonKey));
      await answerPin(tester, settle: false);
      await _frames(tester);
      expect(session.epic1Fake.calls, contains('payLink'));
      expect(_key(epic1WaitingKey), findsOneWidget);
    });

    testWidgets('classic: an epic1 link says so, with Settings', (tester) async {
      await _pump(tester, _session(), send());
      expect(_key(epic1SendFieldKey), findsNothing);
      await tester.enterText(_key(sendRecipientFieldKey), _link);
      await tester.pumpAndSettle();
      expect(find.text(_l.deskE1ModeEpic1Link), findsOneWidget);
      expect(_key(epic1FieldSettingsKey), findsOneWidget);
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

    testWidgets('classic: an in-person code says so, with Settings', (tester) async {
      final taken = <bool>[];
      await _pump(tester, _session(), scanOf('ur:epic1/${'A' * 24}', taken));
      await _tap(tester, find.text('scan'));
      expect(find.text(_l.deskE1ModeEpic1Link), findsOneWidget);
    });

    testWidgets('classic: an animated payment QR is left to the QR Payment reader', (tester) async {
      final taken = <bool>[];
      await _pump(tester, _session(), scanOf('ur:epic-slate/1-3/lpadaxcfaxhl', taken));
      await _tap(tester, find.text('scan'));
      expect(taken, [false]);
      expect(find.text(_l.deskE1ModeEpic1Link), findsNothing);
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

    testWidgets('classic: a whole animated in-person code says so, with Settings', (tester) async {
      final session = _session();
      await _pump(tester, session, wholeOf(request));
      await _tap(tester, find.text('scan'));
      expect(find.text(_l.deskE1ModeEpic1Code), findsOneWidget);
      expect(session.epic1Fake.calls, isNot(contains('inPersonRead')));
    });

    testWidgets('epic1: a whole animated in-person request opens its review', (tester) async {
      final session = _session(on: true);
      await _pump(tester, session, wholeOf(request));
      await _tapFrames(tester, find.text('scan'));
      expect(session.epic1Fake.calls, contains('inPersonRead'));
      expect(find.text(_l.deskIpPayRequestTitle), findsWidgets);
    });

    testWidgets('epic1: a code for another network says so', (tester) async {
      final session = _session(on: true);
      session.epic1Fake.failNext = const WalletError(kind: WalletErrorKind.epic1WrongNetwork, message: 'floonet');
      await _pump(tester, session, wholeOf(request));
      await _tapFrames(tester, find.text('scan'));
      expect(find.text(_l.deskE1ErrCodeWrongNetwork), findsOneWidget);
    });

    testWidgets('epic1: an altered code that is no answer either is refused', (tester) async {
      final session = _session(on: true);
      await _pump(tester, session, wholeOf([9, ...List.filled(32, 7)]));
      await _tapFrames(tester, find.text('scan'));
      expect(session.epic1Fake.calls, containsAllInOrder(['inPersonRead', 'inPersonTake']));
      expect(find.text(_l.deskE1ErrNotInPerson), findsOneWidget);
    });
  });

  group('Contacts', () {
    Future<FakeWalletSession> withAlice({required bool on}) async {
      final session = _session(on: on);
      await session.saveContact(contact: Contact(id: '', name: 'Alice', address: _classic));
      return session;
    }

    testWidgets('epic1: the picker shows a contact without an epic1 pairing as Classic only', (tester) async {
      final session = await withAlice(on: true);
      await _pump(tester, session, const ContactsScreen(pick: true, forPayment: true));
      expect(_key(classicOnlyKey), findsOneWidget);
      expect(find.text(_l.deskE1ClassicOnly), findsOneWidget);
      // The row does not pick.
      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactsScreen), findsOneWidget);
    });

    testWidgets('classic: no Classic only line', (tester) async {
      final session = await withAlice(on: false);
      await _pump(tester, session, const ContactsScreen(pick: true, forPayment: true));
      expect(_key(classicOnlyKey), findsNothing);
    });

    testWidgets('epic1: the contact page says Classic only and Send is off', (tester) async {
      final session = await withAlice(on: true);
      final alice = (await session.contacts()).single;
      await _pump(tester, session, ContactPage(contactId: alice.id));
      expect(_key(classicOnlyKey), findsOneWidget);
      expect(tester.widget<KitButton>(_key(contactPageSendKey)).onPressed, isNull);
    });
  });
}
