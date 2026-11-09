// SPDX-License-Identifier: Apache-2.0
// epic1 payments on the phone (ui-spec P1-P4, D3, D7): the Experimental switch with its
// confirm and "Applies at next unlock", the epic1 section in epic1 mode, the link card on
// Receive, the link flow on Send with the unknown server question, Try next and Sent, the
// mode lines for the other mode's codes, "Classic only" contacts, and the setting kept per
// wallet across lock and unlock.
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_common.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_receive.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_send.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_settings.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_route.dart' show openEpic1Text;
import 'package:epic_wallet/src/ui/scan_screen.dart' show FakeQrScanner, qrScannerProvider;
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

Future<ProviderContainer> _pump(WidgetTester tester, FakeWalletSession session, Widget home, {FakeWalletService? service}) async {
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

bool _switchOn(WidgetTester tester) =>
    tester.widget<Switch>(find.descendant(of: _key(epic1SwitchKey), matching: find.byType(Switch))).value;

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
      expect(find.text(_l.deskE1PhConfirmTitle), findsOneWidget);
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
      expect(find.text(_l.deskE1PhSection), findsOneWidget);
      expect(_key(epic1EpicboxKey), findsOneWidget);
      expect(find.descendant(of: _key(epic1EpicboxKey), matching: find.textContaining('relay.example.invalid')), findsOneWidget);
      expect(_key(epic1PrintedKey), findsOneWidget);
      expect(find.text(_l.deskE1PhReceiving), findsOneWidget);
      expect(_switchOn(tester), isTrue);

      // Turning off asks nothing; it applies at the next unlock.
      await _tap(tester, _key(epic1SwitchKey));
      expect(find.text(_l.deskE1PhConfirmTitle), findsNothing);
      expect(session.epic1Fake.storedOn, isFalse);
      expect(_key(epic1AppliesKey), findsOneWidget);
      expect(_key(epic1EpicboxKey), findsOneWidget);
    });

    testWidgets('Printed codes: each with Retire, which asks first', (tester) async {
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

    testWidgets('epic1: the link card, its QR covered until tapped', (tester) async {
      final session = _session(on: true);
      await _pump(tester, session, receive);
      expect(_key(epic1LinkCardKey), findsOneWidget);
      expect(_key(epic1QrCoverKey), findsOneWidget);
      expect(_key(epic1QrKey), findsNothing);
      expect(_key(epic1CopyLinkKey), findsOneWidget);
      expect(_key(epic1RequestInPersonKey), findsOneWidget);
      expect(session.epic1Fake.calls, contains('makeLink'));
      await _tap(tester, _key(epic1QrCoverKey));
      expect(_key(epic1QrKey), findsOneWidget);
    });

    testWidgets('classic: no link card', (tester) async {
      await _pump(tester, _session(), receive);
      expect(_key(epic1LinkCardKey), findsNothing);
      expect(find.byType(Epic1ReceiveView), findsNothing);
    });
  });

  group('Send', () {
    Widget send() => SlotScaffold(appBar: AppBar(), body: SendView(onDone: () {}));

    testWidgets('epic1: a classic address says so, with Settings', (tester) async {
      await _pump(tester, _session(on: true), send());
      expect(_key(epic1SendFieldKey), findsOneWidget);
      expect(_key(sendRecipientFieldKey), findsNothing);
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
      expect(tester.widget<ButtonStyleButton>(_key(contactPageSendKey)).onPressed, isNull);
    });
  });
}
