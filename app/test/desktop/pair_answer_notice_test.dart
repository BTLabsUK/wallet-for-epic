// An answer to this wallet's invite while another screen is open (SPEC 2.10, PAIR-LNX-16): the
// shell's toast says so and its Check the words opens the words check, once per pairing.
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart' show deskPairingsProvider;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/wallet_service.dart' show PairingEvent, PairingEventKind, PairingState;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../support/experimental.dart';

final _l = englishStrings;

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('an answer on another screen: the toast offers Check the words, which opens the check (PAIR-LNX-16)', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = MockDeskWallet(delay: Duration.zero);
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

    api.pairing.seedPaired(id: 'p-ola', name: 'Ola', state: PairingState.paired);
    c.invalidate(deskPairingsProvider);
    api.pairing.emit(const PairingEvent(PairingEventKind.replied, pairingId: 'p-ola', name: 'Ola'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(_l.noticePairingReplied('Ola')), findsOneWidget);
    final check = find.widgetWithText(EButton, _l.noticeCheckWords);
    expect(check, findsOneWidget);

    // The toast has slid in.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(check);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(EDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
