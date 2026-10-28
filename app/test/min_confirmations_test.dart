// SPDX-License-Identifier: Apache-2.0
// Settings › Advanced › Confirmations on the phone: the wallet's stored count as a stepper,
// 6 marked Default, 1 and 30 the bounds, Reset back to 6, the quiet note below 6, quick taps
// stored as one, the balance re-split at once, and a refusal reverted with a notice.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/min_confirmations.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/confirmations_row.dart';
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/settings_sections.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: 'https://node');
}

/// The row, with Home's balance watched so a set re-splits it.
class _Page extends ConsumerWidget {
  const _Page();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeProvider);
    return const Scaffold(body: ConfirmationsRow());
  }
}

Future<(ProviderContainer, FakeWalletSession)> _pump(WidgetTester tester, {Widget? home}) async {
  tester.view.physicalSize = const Size(360 * 3, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = FakeWalletSession();
  final store = MemorySecretStore()..values['wallet.mainnet.backedUp'] = '1';
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService(session: session)),
        secretStoreProvider.overrideWithValue(store),
        sessionProvider.overrideWith(() => _Open(session)),
        walletConfigProvider.overrideWith(_Config.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home ?? const _Page(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (ProviderScope.containerOf(tester.element(find.byType(Navigator).first)), session);
}

String _value(WidgetTester tester) => tester.widget<Text>(find.byKey(confirmationsValueKey)).data!;

Future<void> _tap(WidgetTester tester, Key key, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.byKey(key));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(MinimumConfirmationsSetting.debounce);
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, Key key) => tester.widget<IconButton>(find.byKey(key)).onPressed != null;

void main() {
  testWidgets('6 is marked Default, with no Reset and no note', (tester) async {
    await _pump(tester);
    expect(_value(tester), '6');
    expect(find.text(_l.advConfirmationsDefault), findsOneWidget);
    expect(find.byKey(confirmationsResetKey), findsNothing);
    expect(find.byKey(confirmationsNoteKey), findsNothing);
    expect(find.byTooltip(_l.advConfirmationsFewer), findsOneWidget);
    expect(find.byTooltip(_l.advConfirmationsMore), findsOneWidget);
  });

  testWidgets('+ stores 7 in the wallet and re-splits the balance at once', (tester) async {
    final (container, session) = await _pump(tester);
    expect(container.read(homeProvider).value?.summary.minimumConfirmations, BigInt.from(6));
    await _tap(tester, confirmationsPlusKey);
    expect(session.minimumConfirmationsSets, [7]);
    expect(_value(tester), '7');
    expect(container.read(homeProvider).value?.summary.minimumConfirmations, BigInt.from(7));
    expect(container.read(countedConfirmationsProvider), BigInt.from(7));
    expect(find.text(_l.advConfirmationsDefault), findsNothing);
    expect(find.text(_l.advConfirmationsReset(6)), findsOneWidget);
    expect(find.byKey(confirmationsNoteKey), findsNothing, reason: 'the note is for fewer only');
  });

  testWidgets('quick taps are stored as one', (tester) async {
    final (_, session) = await _pump(tester);
    await _tap(tester, confirmationsPlusKey, times: 3);
    expect(session.minimumConfirmationsSets, [9]);
    expect(_value(tester), '9');
  });

  testWidgets('below 6 the quiet note shows; Reset returns to 6', (tester) async {
    final (container, session) = await _pump(tester);
    await _tap(tester, confirmationsMinusKey);
    expect(_value(tester), '5');
    expect(find.text(_l.advConfirmationsLowNote), findsOneWidget);
    await tester.tap(find.byKey(confirmationsResetKey));
    await tester.pump(MinimumConfirmationsSetting.debounce);
    await tester.pumpAndSettle();
    expect(session.minimumConfirmationsSets, [5, 6]);
    expect(_value(tester), '6');
    expect(find.byKey(confirmationsNoteKey), findsNothing);
    expect(container.read(countedConfirmationsProvider), BigInt.from(6));
  });

  testWidgets('1 and 30 are the bounds', (tester) async {
    final (_, session) = await _pump(tester);
    await _tap(tester, confirmationsMinusKey, times: 5);
    expect(_value(tester), '1');
    expect(_enabled(tester, confirmationsMinusKey), isFalse);
    expect(_enabled(tester, confirmationsPlusKey), isTrue);
    await _tap(tester, confirmationsPlusKey, times: 29);
    expect(_value(tester), '30');
    expect(_enabled(tester, confirmationsPlusKey), isFalse);
    expect(session.minimumConfirmationsSets, [1, 30]);
    final notifier = ProviderScope.containerOf(tester.element(find.byType(ConfirmationsRow)))
        .read(minimumConfirmationsSettingProvider.notifier);
    expect(() => notifier.set(31), throwsRangeError);
    expect(() => notifier.set(0), throwsRangeError);
  });

  testWidgets('a refused change reverts and shows the error notice', (tester) async {
    final (container, session) = await _pump(tester);
    const refused = WalletError(kind: WalletErrorKind.walletBusy, message: 'busy');
    session.setMinimumConfirmationsError = refused;
    await _tap(tester, confirmationsPlusKey);
    expect(_value(tester), '6');
    expect(container.read(noticeProvider)?.level, NoticeLevel.error);
    expect(container.read(homeProvider).value?.summary.minimumConfirmations, BigInt.from(6));
  });

  testWidgets('Settings › Advanced has the row under Balance, at 360 dp', (tester) async {
    await _pump(tester, home: const SettingsSectionScreen(section: SettingsSection.advanced));
    await tester.scrollUntilVisible(find.byKey(confirmationsRowKey), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text(_l.advBalanceHeader), findsOneWidget);
    expect(find.text(_l.advConfirmations), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
