// SPDX-License-Identifier: Apache-2.0
// The notices of a run on the desktop: one toast for several, which outlives a change of screen
// (a route change clears the others) and opens the place that lists them.
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/message_checks.dart';
import 'package:epic_wallet/src/wallet_service.dart' show PairingEvent, PairingEventKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../support/experimental.dart';

final _l = englishStrings;

PairingEvent _invoice(String slate) => PairingEvent(PairingEventKind.invoiceFromContact, name: 'Ola', slateId: slate, amount: BigInt.from(100000000));

Future<(ProviderContainer, MockDeskWallet, MessageChecks)> _shell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final checks = MessageChecks(showAfter: const Duration(seconds: 5), digestGrace: Duration.zero);
  addTearDown(checks.dispose);
  final api = MockDeskWallet(delay: Duration.zero)..messageChecks = checks;
  final c = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
  addTearDown(c.dispose);
  await tester.runAsync(() async {
    await c.read(deskProvider.notifier).refresh();
    await deskExperimentalOn(c);
  });
  c.read(deskNavProvider.notifier).reset(DeskRoute.settingsAbout);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Consumer(builder: (_, ref, _) => DeskShell(at: ref.watch(deskNavProvider))),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  return (c, api, checks);
}

/// Lets the events reach the shell and the batch flush, and the toast slide.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('several notices of a run are one toast that survives a change of screen', (tester) async {
    final (c, api, checks) = await _shell(tester);
    const digest = '3 updates: 2 invoices, 1 withdrawal';
    checks.notices.begin();
    api.pairing.emit(_invoice('a'));
    api.pairing.emit(_invoice('b'));
    api.pairing.emit(PairingEvent(PairingEventKind.withdrawalFromContact, name: 'Ola', slateId: 'c', amount: BigInt.from(100000000)));
    await _settle(tester);
    expect(find.byType(SnackBar), findsNothing, reason: 'held until the run ends');

    checks.notices.end();
    await _settle(tester);
    expect(find.text(digest), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);

    c.read(deskNavProvider.notifier).go(DeskRoute.overview);
    await _settle(tester);
    expect(find.text(digest), findsOneWidget);

    await tester.tap(find.widgetWithText(EButton, _l.noticeView));
    await _settle(tester);
    expect(c.read(deskNavProvider).route, DeskRoute.invoices);
    expect(find.text(digest), findsNothing);
  });

  testWidgets('one notice of a run is today\'s toast', (tester) async {
    final (_, api, checks) = await _shell(tester);
    checks.notices.begin();
    api.pairing.emit(_invoice('a'));
    await _settle(tester);
    expect(find.byType(SnackBar), findsNothing);
    checks.notices.end();
    await _settle(tester);
    expect(find.textContaining('Ola requests'), findsOneWidget);
    expect(find.textContaining('updates'), findsNothing);
  });
}
