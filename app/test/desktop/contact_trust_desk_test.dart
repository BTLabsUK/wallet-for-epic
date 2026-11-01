// SPDX-License-Identifier: Apache-2.0
// The trust policy on the desktop: the contact details' compatibility line (a line, never a
// badge), and a mailbox send unanswered for 24 hours and 7 days with Cancel and send by Epicbox
// (one confirm, then the ordinary cancel and an ordinary Epicbox send to the contact's address).

import 'package:epic_wallet/src/cancel_final.dart' show CancelResult;
import 'package:epic_wallet/src/desktop/data/clock.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contact_trust_line.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/contacts_screen.dart' show ContactsArgs, ContactsScreen;
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings, localDayMonth;
import 'package:epic_wallet/src/trust/policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/experimental.dart';

final _l = englishStrings;
final DateTime _now = DateTime(2026, 11, 1, 12);
DateTime _ago(Duration d) => _now.subtract(d);

/// The mock, recording cancels and sends.
class _Desk extends MockDeskWallet {
  _Desk() : super(delay: Duration.zero);

  final List<int> cancelled = [];
  final List<SendRequest> sent = [];

  @override
  Future<CancelResult> cancelTx(int id, {bool spendBack = true}) async {
    cancelled.add(id);
    return super.cancelTx(id, spendBack: spendBack);
  }

  @override
  Future<SendResult> send(SendRequest r) {
    sent.add(r);
    return super.send(r);
  }
}

late ProviderContainer _c;
late _Desk _mock;

/// A send through Anna's mailbox, waiting for her answer since [created].
Tx _mailboxSend(DateTime created) => Tx(
  id: 77,
  slateId: 'f0e1d2c3-b4a5-4697-8879-9f3a7c21a0b1',
  direction: TxDirection.sent,
  state: TxState.waitingRecipient,
  method: TxMethod.epicbox,
  amount: 250000000,
  fee: 7000000,
  created: created,
  cancellable: true,
  pairingId: mockAnnaPairing,
);

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<Contact> _open(WidgetTester tester, Widget Function(Contact anna) screen, {PeerCompat? learned}) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  _mock = _Desk();
  final anna = (await _mock.contacts()).firstWhere((c) => c.id == 'c1');
  if (learned != null) _mock.peerCompats[anna.epicbox!] = learned;
  _c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_mock), deskClockProvider.overrideWithValue(() => _now)]);
  addTearDown(_c.dispose);
  await tester.runAsync(() async {
    await _c.read(deskProvider.notifier).refresh();
    await deskExperimentalOn(_c);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen(anna))),
    ),
  );
  await _real(tester);
  return anna;
}

Widget _contacts(Contact anna) => ContactsScreen(arg: ContactsArgs(selectedId: anna.id));

Widget _detail(Tx tx) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: TxDetail(tx: tx));

/// Unmounts the screen and lets Riverpod's auto-dispose timer run before the test ends.
Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUpAll(initializeDateFormatting);

  group('the contact line', () {
    testWidgets('answered by another wallet app: a line, the badge stays', (tester) async {
      final anna = await _open(
        tester,
        _contacts,
        learned: PeerCompat(lastMarkedAt: _ago(const Duration(days: 40)), lastUnmarkedAt: _ago(const Duration(days: 1))),
      );
      expect(tester.widget<Text>(find.byKey(deskContactTrustLineKey)).data, _l.trustLineOtherApp(anna.name));
      expect(find.text(_l.trustVerified), findsWidgets);
      await _end(tester);
    });

    testWidgets('not heard for 90 days: the date of the last marked message', (tester) async {
      final marked = _ago(const Duration(days: 100));
      final anna = await _open(tester, _contacts, learned: PeerCompat(lastMarkedAt: marked));
      expect(tester.widget<Text>(find.byKey(deskContactTrustLineKey)).data, _l.trustLineNotHeard(anna.name, localDayMonth(_l, marked)));
      await _end(tester);
    });

    testWidgets('nothing learned, or a fresh key: no line', (tester) async {
      await _open(tester, _contacts, learned: PeerCompat(lastMarkedAt: _ago(const Duration(days: 5))));
      expect(find.byKey(deskContactTrustLineKey), findsNothing);
      await _end(tester);
    });
  });

  group('an unanswered mailbox send', () {
    testWidgets('under 24 hours: waiting for Anna, no offer', (tester) async {
      final anna = await _open(tester, (_) => _detail(_mailboxSend(_ago(const Duration(hours: 20)))));
      expect(find.text(_l.deskTxStatusWaitingFor(anna.name)), findsOneWidget);
      expect(find.byKey(deskTxResendKey), findsNothing);
      await _end(tester);
    });

    testWidgets('after 24 hours: Not answered yet, Cancel and send by Epicbox first; the confirm, then cancel and send', (tester) async {
      final anna = await _open(tester, (_) => _detail(_mailboxSend(_ago(const Duration(hours: 30)))));
      expect(find.text(_l.mailboxNotAnswered), findsOneWidget);
      expect(find.byKey(const ValueKey('tx-mailbox-gone')), findsNothing);
      final button = tester.widget<EButton>(find.byKey(deskTxResendKey));
      expect(button.kind, EBtnKind.primary, reason: 'the main action');

      await tester.tap(find.byKey(deskTxResendKey));
      await _real(tester);
      expect(find.text(_l.mailboxResendBody(anna.name)), findsOneWidget);
      await tester.tap(find.widgetWithText(EButton, _l.mailboxKeepWaiting));
      await _real(tester);
      expect(find.text(_l.mailboxResendBody(anna.name)), findsNothing);
      expect(_mock.cancelled, isEmpty);
      expect(_mock.sent, isEmpty);

      await tester.tap(find.byKey(deskTxResendKey));
      await _real(tester);
      await tester.tap(find.byKey(deskMailboxResendConfirmKey));
      await _real(tester, 800);
      expect(_mock.cancelled, [77]);
      final r = _mock.sent.single;
      expect(r.method, TxMethod.epicbox);
      expect(r.amount, 250000000);
      expect(r.to, anna.epicbox);
      expect(r.pairingId, isNull, reason: 'an ordinary payment, no mailbox');
      expect(find.text(_l.mailboxResent), findsOneWidget);
      await _end(tester);
    });

    testWidgets('after 7 days: Not picked up, never picked this up, Cancel first and the resend second', (tester) async {
      final anna = await _open(tester, (_) => _detail(_mailboxSend(_ago(const Duration(days: 8)))));
      expect(find.text(_l.mailboxNotPickedUp), findsOneWidget);
      expect(find.text(_l.mailboxNeverPickedUp(anna.name)), findsOneWidget);
      expect(tester.widget<EButton>(find.byKey(deskTxResendKey)).kind, isNot(EBtnKind.primary));
      expect(find.widgetWithText(EButton, _l.deskTxCancelOutgoingAction), findsOneWidget);
      await _end(tester);
    });
  });
}
