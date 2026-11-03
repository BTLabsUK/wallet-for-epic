// SPDX-License-Identifier: Apache-2.0
// Send to a contact that has only a pairing, on the desktop (DESIGN 1.3): the picker lists it
// with "Through Zoe's pairing", Send shows the pairing card and the mailbox readout, the review
// names the contact through the pairing and no address, and the send goes through the mailbox.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/contact_picker.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/send_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/models.dart' show PairingState;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/experimental.dart';

final _l = englishStrings;

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<SendRequest> sent = [];

  @override
  Future<SendResult> send(SendRequest request) {
    sent.add(request);
    return super.send(request);
  }
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
    expect(find.text(_l.sendViaMailbox('Zoe')), findsOneWidget);
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
    expect(find.text(_l.sendViaMailbox('Zoe')), findsNothing);
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
}
