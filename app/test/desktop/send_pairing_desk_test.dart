// SPDX-License-Identifier: Apache-2.0
// Send to a contact that has only a pairing, on the desktop (DESIGN 1.3): the picker lists it
// with "Through Zoe's pairing", Send shows the pairing card and the mailbox readout, the review
// names the contact through the pairing and no address, and the send goes through the mailbox.
// A contact that moved relay in the last 30 days gives the date in the readout.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/contact_picker.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings, localDayMonth;
import 'package:epic_wallet/src/models.dart' show PairingState;
import 'package:epic_wallet/src/name_service/payment_refusals.dart';
import 'package:epic_wallet/src/trust/policy.dart' show PeerCompat;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/experimental.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];

  /// A send through a pairing fails (the mailbox did not take it).
  bool failPairing = false;

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    if (failPairing && request.pairingId != null) return Future.value(const SendFailed('No answer through the pairing.'));
    return super.send(request);
  }
}

/// Anna's pairing takes no payments.
class _RefusesAnna implements PaymentRefusals {
  @override
  bool refusesPayments({String? pairingId, String? address}) => pairingId == mockAnnaPairing;

  @override
  String? refusedName({String? pairingId, String? address}) => refusesPayments(pairingId: pairingId, address: address) ? 'Anna' : null;
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
  });

  tearDown(() => container.dispose());

  /// Zoe: a contact with no address, paired and verified.
  Future<void> pump(WidgetTester tester, Widget body) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await wallet.saveContact(Contact(id: 'cz', name: 'Zoe'));
      wallet.pairing.seedPaired(id: 'pz', name: 'Zoe', contactId: 'cz', relay: 'epicbox.epiccash.com');
      await container.read(deskProvider.notifier).refresh();
      await deskExperimentalOn(container);
      await container.read(deskPairingsProvider.future);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: body)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the picker lists a contact with only a pairing, through its pairing', (tester) async {
    await pump(tester, const ContactPickerDialog(query: 'zo'));
    expect(find.text('Zoe'), findsOneWidget);
    expect(find.text(_l.sendRecipientPairing('Zoe')), findsOneWidget);
  });

  testWidgets('Send: the pairing card and readout; Link off; the review names Zoe, no address', (tester) async {
    await pump(tester, const SendScreen(arg: SendArgs(pairingTo: 'pz', amount: '1', epicboxHealth: ServiceHealth.ok)));
    expect(find.byKey(const ValueKey('send-picked-pairing')), findsOneWidget);
    expect(find.text(_l.sendViaMailbox), findsOneWidget);
    expect(find.text(_l.sendViaMailboxHint('epicbox.epiccash.com')), findsOneWidget);
    expect(find.text(_l.deskSendToHint), findsNothing);
    await tester.tap(find.widgetWithText(EButton, _l.deskSendReview));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('send-review-pairing')), findsOneWidget);
    expect(find.text(_l.deskSendCheckChars), findsNothing);
    expect(find.textContaining('@'), findsNothing);
    await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskSendPassword), matching: find.byType(TextField)), 'secret-pass');
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, 'Send 1.0\u00a0EPIC'));
    await tester.pumpAndSettle();
    expect(wallet.sent.single.pairingId, 'pz');
    expect(wallet.sent.single.to, isNull);
  });

  testWidgets('keys changed: the reason and Check the words instead of the readout', (tester) async {
    await pump(tester, const SendScreen(arg: SendArgs(pairingTo: 'pz', amount: '1', epicboxHealth: ServiceHealth.ok)));
    final r = (await tester.runAsync(() => wallet.pairing.pairing('pz')))!;
    wallet.pairing.seed(r.copyWith(state: PairingState.keysChanged));
    container.invalidate(deskPairingsProvider);
    await tester.pumpAndSettle();
    expect(find.text(_l.contactSendKeysChanged), findsOneWidget);
    expect(find.byKey(const ValueKey('send-pairing-check')), findsOneWidget);
    expect(find.text(_l.sendViaMailbox), findsNothing);
  });

  testWidgets('Epicbox off: the readout pauses and the review queues the payment', (tester) async {
    await tester.runAsync(() async {
      final s = (await wallet.settings());
      await wallet.saveSettings(s.copyWith(payments: s.payments.copyWith(epicbox: false)));
    });
    await pump(tester, const SendScreen(arg: SendArgs(pairingTo: 'pz', amount: '1', epicboxHealth: ServiceHealth.off)));
    expect(find.text(_l.contactPausedEpicboxOff), findsOneWidget);
    await tester.tap(find.widgetWithText(EButton, _l.sendQueue));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('send-review-queued')), findsOneWidget);
    await tester.enterText(find.descendant(of: find.widgetWithText(EField, _l.deskSendPassword), matching: find.byType(TextField)), 'secret-pass');
    await tester.pump();
    await tester.tap(find.widgetWithText(EButton, _l.sendQueue).last);
    await tester.pumpAndSettle();
    expect(wallet.sent.single.pairingId, 'pz');
    expect(find.byKey(const ValueKey('send-queued')), findsOneWidget);
  });

  testWidgets('a contact that moved: the readout gives the relay and the date', (tester) async {
    await pump(tester, const SendScreen(arg: SendArgs(pairingTo: 'pz', amount: '1', epicboxHealth: ServiceHealth.ok)));
    final p = (await tester.runAsync(() async {
      await wallet.pairing.askRelayMove('pz', 'box.example.org');
      return (await wallet.pairing.pairings()).firstWhere((p) => p.id == 'pz');
    }))!;
    container.invalidate(deskPairingsProvider);
    await tester.pumpAndSettle();
    expect(find.text(_l.sendViaMailboxMovedHint('box.example.org', localDayMonth(_l, p.movedAt!))), findsOneWidget);
    expect(find.text(_l.sendViaMailboxHint('epicbox.epiccash.com')), findsNothing);
  });

  // A paired contact with an Epicbox address in To: the switch under To starts as the rule says
  // and the send goes through the pairing while it is on.
  group('mailbox first', () {
    final viaSwitch = find.byKey(const ValueKey('send-via-mailbox'));
    final password = find.descendant(of: find.widgetWithText(EField, _l.deskSendPassword), matching: find.byType(TextField));

    /// The mock's contact [id], as the state lists it (Anna 'c1' is paired and verified).
    Future<Contact> contact(WidgetTester tester, String id) async {
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      return container.read(deskProvider).contacts!.firstWhere((c) => c.id == id);
    }

    Future<void> sendOne(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(EButton, _l.deskSendReview));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
      await tester.enterText(password, 'secret-pass');
      await tester.pump();
      await tester.tap(find.widgetWithText(EButton, 'Send 1.0\u00a0EPIC'));
      await tester.pumpAndSettle();
    }

    bool switchOn(WidgetTester tester) => tester.widget<ESwitch>(viaSwitch).value;

    testWidgets('desktop defaults to the pairing for a paired contact with an address', (tester) async {
      final anna = await contact(tester, 'c1');
      await pump(tester, SendScreen(arg: SendArgs(contact: anna, amount: '1', epicboxHealth: ServiceHealth.ok)));
      expect(find.byKey(const ValueKey('send-route-epicbox')), findsOneWidget);
      expect(switchOn(tester), isTrue);
      expect(find.text(_l.sendViaMailbox), findsOneWidget);
      await sendOne(tester);
      expect(wallet.sent.single.pairingId, mockAnnaPairing);
      expect(wallet.sent.single.to, isNull);
    });

    testWidgets('switch off sends by Epicbox', (tester) async {
      final anna = await contact(tester, 'c1');
      await pump(tester, SendScreen(arg: SendArgs(contact: anna, amount: '1', epicboxHealth: ServiceHealth.ok)));
      await tester.tap(viaSwitch);
      await tester.pumpAndSettle();
      expect(switchOn(tester), isFalse);
      expect(find.text(_l.sendViaPublicHint(anna.name)), findsOneWidget);
      await sendOne(tester);
      expect(wallet.sent.single.pairingId, isNull);
      expect(wallet.sent.single.to, anna.address);
    });

    testWidgets('typed address of a paired contact defaults to the pairing too', (tester) async {
      final anna = await contact(tester, 'c1');
      await pump(tester, const SendScreen(arg: SendArgs(amount: '1', epicboxHealth: ServiceHealth.ok)));
      expect(viaSwitch, findsNothing);
      await tester.enterText(find.byType(EditableText).first, anna.address);
      await tester.pumpAndSettle();
      expect(switchOn(tester), isTrue);
      await sendOne(tester);
      expect(wallet.sent.single.pairingId, mockAnnaPairing);
    });

    testWidgets('a reason the rule knows starts the switch off, with its line', (tester) async {
      final anna = await contact(tester, 'c1');
      wallet.peerCompats[anna.address] = PeerCompat(lastMarkedAt: DateTime.now().subtract(const Duration(days: 40)), lastUnmarkedAt: DateTime.now().subtract(const Duration(days: 1)));
      await pump(tester, SendScreen(arg: SendArgs(contact: anna, amount: '1', epicboxHealth: ServiceHealth.ok)));
      expect(switchOn(tester), isFalse);
      expect(find.text(_l.trustLineOtherApp(anna.name)), findsOneWidget);
      await sendOne(tester);
      expect(wallet.sent.single.pairingId, isNull);
      expect(wallet.sent.single.to, anna.address);
    });

    testWidgets('no-payments contact is refused on the pairing route', (tester) async {
      container.dispose();
      container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), paymentRefusalsProvider.overrideWithValue(_RefusesAnna())]);
      final anna = await contact(tester, 'c1');
      await pump(tester, SendScreen(arg: SendArgs(contact: anna, amount: '1', epicboxHealth: ServiceHealth.ok)));
      expect(switchOn(tester), isTrue);
      await tester.tap(find.widgetWithText(EButton, _l.deskSendReview));
      await tester.pumpAndSettle();
      expect(find.text(_l.contactNoPaymentsNamed('Anna')), findsOneWidget);
      expect(find.text(_l.deskSendReviewTitle), findsNothing);
      expect(wallet.sent, isEmpty);
      // The public address is not refused: off, the send goes by Epicbox.
      await tester.tap(viaSwitch);
      await tester.pumpAndSettle();
      expect(find.text(_l.contactNoPaymentsNamed('Anna')), findsNothing);
      await sendOne(tester);
      expect(wallet.sent.single.to, anna.address);
    });

    testWidgets('failed pairing send offers the public Epicbox address', (tester) async {
      wallet.failPairing = true;
      final anna = await contact(tester, 'c1');
      await pump(tester, SendScreen(arg: SendArgs(contact: anna, amount: '1', epicboxHealth: ServiceHealth.ok)));
      await sendOne(tester);
      expect(wallet.sent.single.pairingId, mockAnnaPairing);
      expect(find.text(_l.deskSendFailedTitle), findsOneWidget);
      final fallback = find.byKey(const ValueKey('send-public-fallback'));
      expect(fallback, findsOneWidget);
      expect(find.text(_l.sendPublicFallback), findsOneWidget);
      await tester.tap(fallback);
      await tester.pumpAndSettle();
      expect(find.text(_l.deskSendReviewTitle), findsOneWidget);
      await tester.enterText(password, 'secret-pass');
      await tester.pump();
      await tester.tap(find.widgetWithText(EButton, 'Send 1.0\u00a0EPIC'));
      await tester.pumpAndSettle();
      expect(wallet.sent, hasLength(2));
      expect(wallet.sent.last.pairingId, isNull);
      expect(wallet.sent.last.to, anna.address);
      expect(find.text(_l.deskSendFailedTitle), findsNothing);
      expect(fallback, findsNothing);
    });

    testWidgets('unpaired contact shows no switch', (tester) async {
      final pool = await contact(tester, 'c2');
      await pump(tester, SendScreen(arg: SendArgs(contact: pool, amount: '1', epicboxHealth: ServiceHealth.ok)));
      expect(find.byKey(const ValueKey('send-route-epicbox')), findsOneWidget);
      expect(viaSwitch, findsNothing);
      expect(find.text(_l.sendViaMailbox), findsNothing);
      await sendOne(tester);
      expect(wallet.sent.single.pairingId, isNull);
      expect(wallet.sent.single.to, pool.address);
    });
  });
}
