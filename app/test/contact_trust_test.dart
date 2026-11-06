// SPDX-License-Identifier: Apache-2.0
// The trust policy on the phone's screens: the contact page's compatibility lines (a line,
// never a badge), the mailbox route hidden while a contact's key answers as another wallet app,
// a mailbox send unanswered for 24 hours and 7 days with Cancel and send to their public Epicbox address (one
// confirm, then the ordinary cancel and an ordinary Epicbox send), and the pruning of what the
// wallet learned about keys on every open.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart' show clockProvider;
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/trust/contact_trust.dart';
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contact_trust_line.dart';
import 'package:epic_wallet/src/ui/mailbox_resend.dart';
import 'package:epic_wallet/src/ui/pairing/send_pairing.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/experimental.dart';

final AppLocalizations _l = englishStrings;
final DateTime _now = DateTime(2026, 11, 1, 12);
final String _anna = 'es${'a' * 50}@epicbox.epiccash.com';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());
int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;
DateTime _ago(Duration d) => _now.subtract(d);

WalletSummary get _summary => WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.from(3),
  total: _epic(10),
  spendable: _epic(7),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: _epic(3),
  validatedWithNode: true,
);

/// A send through Anna's mailbox, waiting for her answer since [sentAt].
TxEntry _mailboxSend(DateTime sentAt) => fakeTx(
  id: 9,
  slateId: 'pay-1',
  kind: TxKind.sent,
  status: TxStatus.awaitingRecipient,
  createdAtUnix: _at(sentAt),
  // 3 EPIC sent, the fee on top.
  amountDebited: _epic(3.007),
  fee: _epic(0.007),
  numInputs: 1,
  transport: 'epicbox',
  cancellable: true,
  pairingId: 'p-anna',
);

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  final session = FakeWalletSession(summary: _summary);
  final store = MemorySecretStore()..values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
  final files = FakeSlateFiles();
  late final service = FakeWalletService(session: session);

  FakePairing get api => session.pairing;

  /// Anna in the address book, with her Epicbox address.
  Contact anna() {
    final c = Contact(id: 'c1', name: 'Anna', epicbox: _anna);
    session.contactsValue.add(c);
    return c;
  }

  /// Anna paired (verified unless [state]), her card naming her payments address.
  PairingRecord pair({PairingState state = PairingState.verified, DateTime? lastSealedIn}) {
    api.clock = () => _now;
    return api.seedPaired(
      id: 'p-anna',
      name: 'Anna',
      state: state,
      contactId: 'c1',
      paymentsAddress: _anna,
      lastSealedIn: lastSealedIn,
    );
  }

  /// What the wallet learned about Anna's key.
  void learned({DateTime? marked, DateTime? unmarked}) {
    service.peerCompats[_anna] = PeerCompat(lastMarkedAt: marked, lastUnmarkedAt: unmarked);
  }

  /// A waiting mailbox send to Anna made at [sentAt], linked to her pairing as LEPIC does.
  TxEntry waiting(DateTime sentAt) {
    final tx = _mailboxSend(sentAt);
    session.transactionsValue.add(tx);
    api.slates['pay-1'] = const PairingSlate(pairingId: 'p-anna', purpose: SlatePurpose.payment);
    return tx;
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    session.owner = service;
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
    walletServiceProvider.overrideWithValue(service),
    secretStoreProvider.overrideWithValue(store),
    invoicesOnProvider.overrideWithValue(true),
    updatePlatformProvider.overrideWithValue(null),
    priceSourceProvider.overrideWithValue(_NoPrice()),
    qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
    slateFilesProvider.overrideWithValue(files),
    clockProvider.overrideWithValue(() => _now),
    pairNetProvider.overrideWithValue(PairNet.online),
    sessionProvider.overrideWith(() => _Open(session)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

String _lineText(WidgetTester tester) => tester.widget<Text>(find.byKey(contactTrustLineKey)).data!;

void main() {
  group('contact page line', () {
    testWidgets('answered by another wallet app: a line under the Pairing block, the badge stays', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair()
        ..learned(marked: _ago(const Duration(days: 40)), unmarked: _ago(const Duration(days: 1)));
      await h.pump(tester, const ContactPage(contactId: 'c1'));
      expect(_lineText(tester), _l.trustLineOtherApp('Anna'));
      expect(find.text(_l.trustVerified), findsWidgets, reason: 'the badge stays');
    });

    testWidgets('not heard for 90 days: the date of the latest sign of life', (tester) async {
      final sealed = _ago(const Duration(days: 95));
      final h = _Harness()
        ..anna()
        ..pair(lastSealedIn: sealed)
        ..learned(marked: _ago(const Duration(days: 100)));
      await h.pump(tester, const ContactPage(contactId: 'c1'));
      expect(_lineText(tester), _l.trustLineNotHeard('Anna', localDayMonth(_l, sealed)));
    });

    testWidgets('a fresh paired contact shows no line; a plain contact answered by another app does', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair()
        ..learned(marked: _ago(const Duration(days: 10)));
      await h.pump(tester, const ContactPage(contactId: 'c1'));
      expect(find.byKey(contactTrustLineKey), findsNothing);

      final g = _Harness()
        ..anna()
        ..learned(unmarked: _ago(const Duration(days: 2)));
      await g.pump(tester, const ContactPage(contactId: 'c1'));
      expect(_lineText(tester), _l.trustLineOtherApp('Anna'));
    });
  });

  group('Send', () {
    Widget line() => Scaffold(
      body: SendPairingLine(address: _anna, epicbox: true, viaMailbox: null, onViaMailbox: (_) {}, onAddress: (_) {}),
    );
    bool on(WidgetTester tester) => tester.widget<SegmentedButton<bool>>(find.byKey(sendRouteKey)).selected.single;

    testWidgets('the selector starts on the public address, with the reason, while the key answers as another wallet app', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair();
      await h.pump(tester, line());
      expect(on(tester), isTrue, reason: 'nothing learned: the pairing is the default');

      final g = _Harness()
        ..anna()
        ..pair()
        ..learned(marked: _ago(const Duration(days: 40)), unmarked: _ago(const Duration(days: 1)));
      await g.pump(tester, line());
      expect(on(tester), isFalse);
      expect(find.text(_l.sendRouteReasonOtherApp('Anna')), findsOneWidget);
    });
  });

  group('an unanswered mailbox send', () {
    testWidgets('under 24 hours: waiting for Anna, no offer', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair();
      final tx = h.waiting(_ago(const Duration(hours: 20)));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text(_l.txStatusWaitingFor('Anna')), findsWidgets);
      expect(find.byKey(mailboxResendCardKey), findsNothing);
    });

    testWidgets('after 24 hours: Not answered yet, Cancel and send to their public Epicbox address first, Keep waiting closes', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair();
      final tx = h.waiting(_ago(const Duration(hours: 30)));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text(_l.mailboxNotAnswered), findsWidgets);
      expect(find.byKey(mailboxResendCardKey), findsOneWidget);
      expect(find.byKey(txDetailsResendKey), findsOneWidget);
      expect(tester.widget(find.byKey(txDetailsResendKey)), isA<FilledButton>(), reason: 'the main action');
      expect(find.text(_l.mailboxNeverPickedUp('Anna')), findsNothing);

      // The confirm, left with Keep waiting: nothing happens.
      await tester.tap(find.byKey(txDetailsResendKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.mailboxResendBody('Anna')), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(TextButton, _l.mailboxKeepWaiting)));
      await tester.pumpAndSettle();
      expect(find.text(_l.mailboxResendBody('Anna')), findsNothing);
      expect(h.session.cancelledTxIds, isEmpty);
      expect(h.session.epicboxSends, isEmpty);
    });

    testWidgets('Cancel and send: the ordinary cancel, then an ordinary Epicbox send of the same amount to Anna', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair();
      final tx = h.waiting(_ago(const Duration(hours: 30)));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      await tester.tap(find.byKey(txDetailsResendKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(mailboxResendConfirmKey));
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [9]);
      expect(h.session.epicboxSends, [(amount: _epic(3), to: _anna)]);
      expect(find.text(_l.mailboxResent), findsOneWidget);
    });

    testWidgets('no Epicbox address for Anna: the facts, no resend', (tester) async {
      // The fake pairs always with a card address, so the policy's answer is checked on its own:
      // paired, no address, no resend; and the card without a resend shows the facts only.
      const noAddress = Relationship(RelationshipKind.verified, hasEpicboxAddress: false);
      final offer = mailboxResendOffer(noAddress, _ago(const Duration(hours: 30)), _now)!;
      expect(offer.resend, isFalse);
      final h = _Harness();
      await h.pump(
        tester,
        Scaffold(body: MailboxResendCard(offer: offer, name: 'Anna', busy: false, onResend: null, onKeepWaiting: () {})),
      );
      expect(find.text(_l.mailboxNotAnswered), findsOneWidget);
      expect(find.byKey(txDetailsResendKey), findsNothing);
      expect(find.byKey(txDetailsKeepWaitingKey), findsNothing);
    });

    testWidgets('after 7 days: Not picked up, never picked this up, Cancel first and the resend second', (tester) async {
      final h = _Harness()
        ..anna()
        ..pair();
      final tx = h.waiting(_ago(const Duration(days: 8)));
      await h.pump(tester, TxDetailsScreen(txKey: tx.key));
      expect(find.text(_l.mailboxNotPickedUp), findsWidgets);
      expect(find.text(_l.mailboxNeverPickedUp('Anna')), findsOneWidget);
      expect(tester.widget(find.byKey(txDetailsResendKey)), isA<OutlinedButton>(), reason: 'second to Cancel');
      expect(find.text(_l.txDetailsCancelPayment), findsOneWidget);
    });
  });

  group('the stage words', () {
    test('follow the policy clock', () {
      final sent = _ago(const Duration(hours: 30));
      expect(mailboxStageWord(_l, sent, _now), _l.mailboxNotAnswered);
      expect(mailboxStageWord(_l, _ago(const Duration(hours: 2)), _now), isNull);
      expect(mailboxStageWord(_l, _ago(const Duration(days: 7)), _now), _l.mailboxNotPickedUp);
      final paired = relationshipOf(inContacts: true, epicboxAddress: _anna, pairing: FakePairing().seedPaired(name: 'Anna'));
      expect(mailboxResendOffer(paired, sent, _now)?.resendPrimary, isTrue);
      expect(mailboxResendOffer(paired, _ago(const Duration(days: 8)), _now)?.resendPrimary, isFalse);
      expect(mailboxResendOffer(paired, _ago(const Duration(hours: 1)), _now), isNull);
    });
  });

  test('opening the wallet drops what was learned about keys silent for 180 days', () async {
    final h = _Harness();
    final container = ProviderContainer(overrides: [walletServiceProvider.overrideWithValue(h.service), secretStoreProvider.overrideWithValue(h.store)]);
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).unlocked(h.session);
    await Future<void>.delayed(Duration.zero);
    expect(h.session.forgetPeersCalls, [peerCompatRetention]);
    expect(peerCompatRetention, const Duration(days: 180));
  });
}
