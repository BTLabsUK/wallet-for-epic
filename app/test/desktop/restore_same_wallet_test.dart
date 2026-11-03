// SPDX-License-Identifier: Apache-2.0
// Restoring a phrase that is already in the app opens that wallet instead of making a
// duplicate. "Use N words" looks the phrase up first; restore itself refuses as a backstop.
import 'package:epic_wallet/src/desktop/app/routes.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _v12 = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

/// The lookup misses (as when the list could not be read) and restore itself refuses.
class _Backstop extends MockDeskWallet {
  _Backstop() : super(delay: Duration.zero);

  int restores = 0;

  @override
  Future<WalletEntry?> walletWithPhrase(List<String> words) async => null;

  @override
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase, BigInt? startHeight}) async {
    restores++;
    final same = (await wallets()).firstWhere((w) => w.id == 'legacy-mainnet');
    throw DeskError('This wallet is already here: ${same.name}', sameWallet: same);
  }
}

Future<ProviderContainer> _pump(WidgetTester tester, {MockDeskWallet? api}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api ?? MockDeskWallet(delay: Duration.zero))]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: RestoreScreen())),
    ),
  );
  await tester.pump();
  return container;
}

Future<void> _wait(WidgetTester tester, [int ms = 600]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _paste(WidgetTester tester, String phrase) async {
  await tester.enterText(find.byType(EditableText).first, phrase);
  await _wait(tester);
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('a phrase already here: the dialog names the wallet; Open it lands on Unlock with it selected', (tester) async {
    final container = await _pump(tester);
    final api = container.read(deskApiProvider);
    final before = (await tester.runAsync(api.wallets))!.length;
    await _paste(tester, MockDeskWallet.samePhrase);
    expect(find.text('All 24 words check out.'), findsOneWidget);
    await tester.tap(find.text(_l.commonContinue));
    await _wait(tester);
    expect(find.text(_l.deskOnbSameTitle), findsOneWidget);
    expect(find.text('Main wallet'), findsOneWidget);
    expect(find.text('~/.epic_cash_desktop/wallet'), findsOneWidget);
    expect(find.byKey(const ValueKey('wallet-name-title')), findsNothing, reason: 'no password step for a wallet that exists');
    await tester.tap(find.text(_l.deskOnbSameOpen));
    await _wait(tester);
    final nav = container.read(deskNavProvider);
    expect(nav.route, DeskRoute.unlock);
    expect((nav.arg as UnlockPick).id, 'legacy-mainnet');
    expect((await tester.runAsync(api.wallets))!.length, before, reason: 'nothing was added');
    await _end(tester);
  });

  testWidgets('Cancel keeps the phrase on the grid', (tester) async {
    final container = await _pump(tester);
    await _paste(tester, MockDeskWallet.samePhrase);
    await tester.tap(find.text(_l.commonContinue));
    await _wait(tester);
    expect(find.text(_l.deskOnbSameTitle), findsOneWidget);
    await tester.tap(find.text(_l.commonCancel));
    await _wait(tester);
    expect(find.text('This wallet is already here'), findsNothing);
    expect(find.text('24 of 24 words'), findsOneWidget);
    expect(find.text('All 24 words check out.'), findsOneWidget);
    expect(container.read(deskNavProvider).arg, isNot(isA<UnlockPick>()), reason: 'no wallet was picked');
    await _end(tester);
  });

  testWidgets('a phrase that is not here goes on to the password step', (tester) async {
    await _pump(tester);
    await _paste(tester, _v12);
    await tester.tap(find.text(_l.commonContinue));
    await _wait(tester);
    expect(find.text('This wallet is already here'), findsNothing);
    expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
    await _end(tester);
  });

  testWidgets('restore refused by the wallet shows the dialog too, not a failure', (tester) async {
    final api = _Backstop();
    final container = await _pump(tester, api: api);
    await _paste(tester, _v12);
    await tester.tap(find.text(_l.commonContinue));
    await _wait(tester);
    expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
    await tester.enterText(find.byType(EditableText).at(0), 'password-1234');
    await tester.enterText(find.byType(EditableText).at(1), 'password-1234');
    await tester.pump();
    await tester.tap(find.text(_l.deskOnbRestoreSide).last);
    await _wait(tester);
    expect(api.restores, 1);
    expect(find.text('Wallet not restored'), findsNothing);
    expect(find.text(_l.deskOnbSameTitle), findsOneWidget);
    await tester.tap(find.text('Open it'));
    await _wait(tester);
    final nav = container.read(deskNavProvider);
    expect(nav.route, DeskRoute.unlock);
    expect((nav.arg as UnlockPick).id, 'legacy-mainnet');
    await _end(tester);
  });
}
