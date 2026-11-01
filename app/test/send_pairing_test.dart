// SPDX-License-Identifier: Apache-2.0
// Send to a contact that has only a pairing (DESIGN 1.2): the contact page's Send by the
// pairing's state, Send with the pairing as recipient (its card, the mailbox readout, no
// address), the queue while Epicbox is off, and "Waiting for Anna" on the payment's row.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/pairing/send_pairing.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/experimental.dart';
import 'support/send_pin.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final _tip = NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');

class _NodeService extends FakeWalletService {
  _NodeService({super.session});

  @override
  Future<NodeTip> nodeAnswer(WalletConfig config) async => _tip;
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Mainnet extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: mainnetPreset.nodeUrl);
}

final WalletSummary _forty = WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: _epic(50),
  spendable: _epic(40),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

class _Harness {
  _Harness({bool pairing = true}) {
    allowPinCheck(session);
    session.contactsValue.add(Contact(id: 'c1', name: 'Anna'));
    // Pairing is an experimental switch (Settings › Advanced), off by default.
    if (pairing) store.values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
  }

  final session = FakeWalletSession(summary: _forty);
  late final service = _NodeService(session: session);
  final store = sendPinStore();

  ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  Future<void> pump(WidgetTester tester, Widget home, {PairNet? net}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          sessionProvider.overrideWith(() => _Open(session)),
          walletConfigProvider.overrideWith(_Mainnet.new),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          if (net != null) pairNetProvider.overrideWithValue(net),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AdvancedOptions(prefs: AdvancedPrefs.none, child: child!),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Send with the pairing [id] handed over, as the contact page's Send does.
  Future<void> openSend(WidgetTester tester, String id, {PairNet? net}) async {
    await pump(tester, SlotScaffold(appBar: AppBar(), body: SendView(onDone: () {})), net: net);
    container(tester).read(sendRecipientProvider.notifier).handPairing(id);
    await tester.pumpAndSettle();
  }
}

Future<void> _reach(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first,
    );
  }
  await tester.ensureVisible(finder);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reach(tester, finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await answerPin(tester);
}

/// From the recipient step with a pairing: Continue, 1.5000\u00a0EPIC, Continue to the review.
Future<void> _toReview(WidgetTester tester) async {
  await _tap(tester, find.widgetWithText(FilledButton, _l.commonContinue));
  final amount = find.widgetWithText(TextField, 'Amount (EPIC)');
  await _reach(tester, amount);
  await tester.enterText(amount, '1.5');
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await _tap(tester, find.widgetWithText(FilledButton, _l.commonContinue));
}

bool _enabled(WidgetTester tester, Finder button) => tester.widget<ButtonStyleButton>(button).onPressed != null;

void main() {
  group('contact page of a contact with only a pairing', () {
    for (final (name, state, caps, net, on, reason) in [
      ('verified', PairingState.verified, const PairingCaps(), null, true, null),
      ('paired, not verified', PairingState.paired, const PairingCaps(), null, true, null),
      ('Epicbox off', PairingState.verified, const PairingCaps(), PairNet.epicboxOff, true, null),
      ('Offline', PairingState.verified, const PairingCaps(), PairNet.offline, true, null),
      ('keys changed', PairingState.keysChanged, const PairingCaps(), null, false, _l.contactSendKeysChanged),
      ('wallet does not open sealed messages', PairingState.verified, const PairingCaps(opensSealed: false), null, false, _l.contactSendNoSealed('Anna')),
    ]) {
      testWidgets('$name: Send ${on ? 'on' : 'off'}', (tester) async {
        final h = _Harness();
        h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1', state: state, caps: caps);
        await h.pump(tester, const ContactPage(contactId: 'c1'), net: net);
        expect(_enabled(tester, find.byKey(contactPageSendKey)), on);
        expect(find.byKey(contactPageViaPairingKey), findsOneWidget);
        expect(find.text(_l.contactNoAddressPaired), findsOneWidget);
        expect(find.text(_l.contactNoAddresses), findsNothing);
        if (reason == null) {
          expect(find.byKey(contactPageSendReasonKey), findsNothing);
        } else {
          expect(tester.widget<Text>(find.byKey(contactPageSendReasonKey)).data, reason);
        }
      });
    }

    testWidgets('Pairing switched off: a paired contact with no address keeps Send off, no pairing row', (tester) async {
      final h = _Harness(pairing: false);
      h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1');
      await h.pump(tester, const ContactPage(contactId: 'c1'));
      expect(_enabled(tester, find.byKey(contactPageSendKey)), isFalse);
      expect(find.byKey(contactPageViaPairingKey), findsNothing);
      expect(find.text(_l.contactNoAddresses), findsOneWidget);
    });

    testWidgets('not paired and no address: Send off, "No addresses saved."', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ContactPage(contactId: 'c1'));
      expect(_enabled(tester, find.byKey(contactPageSendKey)), isFalse);
      expect(find.text(_l.contactNoAddresses), findsOneWidget);
      expect(find.byKey(contactPageViaPairingKey), findsNothing);
    });
  });

  group('Send to a pairing', () {
    testWidgets('the card and the mailbox readout take the To field; no address shows', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1', relay: 'epicbox.epiccash.com');
      await h.openSend(tester, 'p1');
      expect(find.byKey(sendPairingCardKey), findsOneWidget);
      expect(find.byKey(sendRecipientFieldKey), findsNothing);
      expect(find.text(_l.sendRecipientPairing('Anna')), findsOneWidget);
      expect(find.text(_l.sendViaMailbox('Anna')), findsOneWidget);
      expect(find.text(_l.sendViaMailboxHint('epicbox.epiccash.com')), findsOneWidget);
      // No address, and no Link segment.
      expect(find.textContaining('@'), findsNothing);
      expect(find.text(MethodIcons.familyName(_l, MethodFamily.link)), findsNothing);
      expect(_enabled(tester, find.widgetWithText(FilledButton, _l.commonContinue)), isTrue);
      // The review names the contact through the pairing; Send goes through the mailbox.
      await _toReview(tester);
      expect(find.text(_l.sendRecipientPairing('Anna')), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
      expect(find.byKey(sendQueuedCardKey), findsNothing);
      await _tap(tester, find.widgetWithText(FilledButton, 'Send 1.50000000\u00a0EPIC'));
      expect(h.session.pairing.calls, contains('sendViaMailbox'));
      expect(h.session.epicboxSends.single.amount, _epic(1.5));
      expect(find.text(_l.txStepSentMailbox('Anna')), findsOneWidget);
    });

    testWidgets('× goes back to the empty To field', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1');
      await h.openSend(tester, 'p1');
      await tester.tap(find.byKey(sendPairingClearKey));
      await tester.pumpAndSettle();
      expect(find.byKey(sendPairingCardKey), findsNothing);
      expect(find.byKey(sendRecipientFieldKey), findsOneWidget);
    });

    testWidgets('Epicbox off: paused readout, the queue card, Queue payment, then Payment queued', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1');
      await h.openSend(tester, 'p1', net: PairNet.epicboxOff);
      expect(find.text(_l.contactPausedEpicboxOff), findsOneWidget);
      await _toReview(tester);
      await _reach(tester, find.byKey(sendQueuedCardKey));
      expect(find.byKey(sendQueuedCardKey), findsOneWidget);
      expect(find.text(_l.sendQueuedEpicboxOff), findsOneWidget);
      final queue = find.widgetWithText(FilledButton, _l.sendQueue);
      expect(_enabled(tester, queue), isTrue);
      await _tap(tester, queue);
      expect(h.session.pairing.calls, contains('sendViaMailbox'));
      expect(find.byKey(sendQueuedHeadlineKey), findsOneWidget);
      expect(find.text(_l.sendQueuedBody('Anna')), findsOneWidget);
      // The send is still the step under way: it waits in the outbox.
      expect(find.text(_l.txStepSentMailbox('Anna')), findsOneWidget);
      expect(find.text(_l.contactPausedEpicboxOff), findsOneWidget);
      expect(find.text(_l.sendTrackWaitingFor('Anna')), findsNothing);
    });

    testWidgets('keys changed meanwhile: the warn notice with Check the words, Continue off', (tester) async {
      final h = _Harness();
      final r = h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1');
      await h.openSend(tester, 'p1');
      // As LEPIC: the same pairing, its keys changed (a collect found them).
      h.session.pairing.seed(r.copyWith(state: PairingState.keysChanged));
      h.container(tester).invalidate(pairingsProvider);
      await tester.pumpAndSettle();
      expect(find.text(_l.contactKeysChangedTitle('Anna')), findsOneWidget);
      expect(find.byKey(sendPairingCheckKey), findsOneWidget);
      expect(_enabled(tester, find.widgetWithText(FilledButton, _l.commonContinue)), isFalse);
    });
  });

  group('the payment\'s row', () {
    TxEntry waiting(String slateId) => fakeTx(
      id: 7,
      slateId: slateId,
      kind: TxKind.sent,
      status: TxStatus.awaitingRecipient,
      amountDebited: _epic(1.5),
      fee: BigInt.from(700000),
      transport: 'file',
    );

    Widget line(TxEntry tx) => Material(child: TxStatusLine(tx: tx, tip: BigInt.from(2500000), date: 'Today'));

    testWidgets('a pairing\'s payment reads "Waiting for Anna"', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1');
      h.session.pairing.slates['s-anna'] = const PairingSlate(pairingId: 'p1', purpose: SlatePurpose.payment);
      await h.pump(tester, line(waiting('s-anna')));
      expect(find.textContaining(_l.txStatusWaitingFor('Anna'), findRichText: true), findsOneWidget);
      expect(find.textContaining(_l.txStatusWaitingRecipient, findRichText: true), findsNothing);
    });

    testWidgets('any other reads "Waiting for recipient"', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(id: 'p1', name: 'Anna', contactId: 'c1');
      await h.pump(tester, line(waiting('s-other')));
      expect(find.textContaining(_l.txStatusWaitingRecipient, findRichText: true), findsOneWidget);
    });
  });
}
