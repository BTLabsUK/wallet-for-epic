// The desktop's Pair page (SPEC 2.1-2.3, desktop): the code with its words, an online invite
// copied with the name they will see, a pasted invite answered, and Pending invites.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingsProvider;
import 'package:epic_wallet/src/desktop/screens/pairing/pair_screens.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart' show PairingState;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _l = englishStrings;
late ProviderContainer _c;
late MockDeskWallet _mock;

FakePairing get _pairing => _mock.pairing;

Future<void> _real(WidgetTester tester, [int ms = 400]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  _mock = MockDeskWallet(delay: Duration.zero);
  _c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_mock)]);
  addTearDown(_c.dispose);
  await tester.runAsync(() => _c.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _c,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: screen)),
    ),
  );
  await _real(tester);
}

Future<void> _seenAs(WidgetTester tester, String name) async {
  final field = find.descendant(of: find.widgetWithText(EField, _l.pairSeenAs), matching: find.byType(EditableText));
  await tester.enterText(field.first, name);
  await tester.pump();
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('the page: the lead, the code panel, Enter link or words and Invite online', (tester) async {
    await _open(tester, const DeskPairScreen());
    expect(find.text(_l.pairLead), findsOneWidget);
    expect(find.text(_l.pairShowMyCode), findsOneWidget);
    expect(find.text(_l.pairEnter), findsOneWidget);
    expect(find.text(_l.pairingInviteOnline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Copy invite makes an invite under the name they will see', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
    final before = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingInvite).length;
    await tester.ensureVisible(find.byKey(deskPairCopyInviteKey));
    await tester.tap(find.byKey(deskPairCopyInviteKey));
    await _real(tester);
    final invites = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingInvite).toList();
    expect(invites.length, before + 1);
  });

  testWidgets('a pasted invite opens the incoming dialog; Pair answers it', (tester) async {
    await _open(tester, const DeskPairScreen());
    await _seenAs(tester, 'the owner');
    final link = _pairing.inviteLinkFrom(name: 'Northwind', asksInvoices: true);
    await tester.enterText(find.descendant(of: find.byKey(deskPairEnterKey), matching: find.byType(EditableText)), link);
    await tester.pump();
    await tester.tap(find.byKey(deskPairGoKey));
    await _real(tester);
    expect(find.text(_l.pairIncomingTitle('Northwind')), findsOneWidget);
    await tester.tap(find.byKey(deskIncomingPairKey));
    await _real(tester);
    final answered = (await tester.runAsync(_pairing.pairings))!.where((r) => r.state == PairingState.pendingReply);
    expect(answered, hasLength(1));
    expect(answered.single.asksInvoices, isFalse, reason: 'Allow invoices is off until the user turns it on');
  });

  testWidgets('Pending invites lists what waits, with Cancel', (tester) async {
    await _open(tester, const DeskPendingScreen());
    await tester.runAsync(() => _pairing.makeInvite(name: 'the owner', expiry: const Duration(hours: 24), label: 'Ola'));
    _c.invalidate(deskPairingsProvider);
    await _real(tester);
    expect(find.text('Ola'), findsOneWidget);
    expect(find.text(_l.pendingCopyLink), findsWidgets);
  });
}
