// SPDX-License-Identifier: Apache-2.0
// Several wallets on the desktop: Unlock's Wallet select and the Remove wallet dialog's two
// modes, on the mock with its calls recorded.
import 'dart:async';

import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/unlock_screen.dart';
import 'package:epic_wallet/src/desktop/screens/settings/dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart' show demoOtherWallet;
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder extends MockDeskWallet {
  _Recorder() : super(delay: const Duration(milliseconds: 10));

  final List<String> calls = [];

  @override
  Future<void> selectWallet(String id) {
    calls.add('select $id');
    return super.selectWallet(id);
  }

  @override
  Future<bool> unlock(String password, {bool remember = false}) {
    calls.add('unlock');
    return super.unlock(password, remember: remember);
  }

  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) {
    calls.add('remove $id ${mode.name}');
    return super.removeWallet(id, mode, password: password);
  }
}

/// Fails every removal, as when the disk refuses; the adapter locks the open wallet anyway.
class _FailingRemove extends _Recorder {
  bool locked = false;

  @override
  Future<void> lock() {
    locked = true;
    return super.lock();
  }

  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) async {
    await super.removeWallet(id, mode, password: password);
    throw const DeskError('Disk refused');
  }
}

Future<void> _pump(WidgetTester tester, _Recorder api, Widget child) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
  ));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _wait(WidgetTester tester, [int ms = 2000]) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('unlock opens the wallet picked in the Wallet select', (tester) async {
    final api = _Recorder();
    await _pump(tester, api, const UnlockScreen());
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Main wallet'), findsOneWidget);
    await tester.tap(find.text('Main wallet'));
    await tester.pump(const Duration(milliseconds: 500));
    // Each option names its whole folder on hover; the list cuts it.
    // The mock's Savings lives in the app's own folder, under its id.
    expect(
      find.byWidgetPredicate((w) => w is Tooltip && w.message == '~/.epic_cash_desktop/wallets/${demoOtherWallet.id}'),
      findsOneWidget,
    );
    // ... and copies it from its own button, which does not pick the wallet.
    expect(find.byTooltip('Copy path: Savings'), findsOneWidget);
    await tester.tap(find.text('Savings').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.calls, ['select ${demoOtherWallet.id}']);
    await tester.enterText(find.byType(EditableText).first, 'wrong');
    await tester.tap(find.text('Unlock'));
    await _wait(tester);
    expect(api.calls, ['select ${demoOtherWallet.id}', 'select ${demoOtherWallet.id}', 'unlock']);
    await _end(tester);
  });

  testWidgets('remove dialog for a wallet that is not open offers only Remove from list', (tester) async {
    final api = _Recorder();
    await _pump(tester, api, Builder(builder: (c) => TextButton(onPressed: () => showRemoveWalletDialog(c, demoOtherWallet), child: const Text('open'))));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Remove from list'), findsWidgets);
    expect(find.text('Delete wallet'), findsNothing);
    await tester.tap(find.widgetWithText(EButton, 'Remove from list'));
    await _wait(tester);
    expect(api.calls, ['remove ${demoOtherWallet.id} list']);
    expect(find.text('Savings removed from the list'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('remove dialog for a wallet that is not open: the delete line and "Unlock this wallet"', (tester) async {
    final api = _FailingRemove();
    await _pump(tester, api, Builder(builder: (c) => TextButton(onPressed: () => showRemoveWalletDialog(c, demoOtherWallet), child: const Text('open'))));
    final container = ProviderScope.containerOf(tester.element(find.text('open')));
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.pump();
    expect(container.read(deskProvider).account, isNotNull, reason: 'a wallet is open');
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('To delete its files as well, unlock this wallet and use Delete wallet under Settings\u00a0›\u00a0This wallet.'), findsOneWidget);
    await tester.tap(find.text('Unlock this wallet'));
    await _wait(tester);
    expect(api.locked, isTrue, reason: 'the open wallet is locked first');
    expect(api.calls, contains('select ${demoOtherWallet.id}'));
    expect(find.byType(RemoveWalletDialog), findsNothing);
    final nav = container.read(deskNavProvider);
    expect(nav.route, DeskRoute.unlock);
    final pick = nav.arg;
    expect(pick, isA<UnlockPick>());
    expect((pick! as UnlockPick).id, demoOtherWallet.id);
    expect((pick as UnlockPick).then, DeskRoute.settingsAccount);
    await _end(tester);
  });

  testWidgets('remove dialog for the open wallet: delete needs the typed name, the password and the tick', (tester) async {
    final api = _Recorder();
    const open = WalletEntry(id: 'legacy-mainnet', name: 'Main wallet', folder: '~/x', network: 'mainnet');
    await _pump(tester, api, Builder(builder: (c) => TextButton(onPressed: () => showRemoveWalletDialog(c, open), child: const Text('open'))));
    final container = ProviderScope.containerOf(tester.element(find.text('open')));
    unawaited(container.read(deskProvider.notifier).refresh());
    await _wait(tester, 4000);
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Delete wallet'), findsOneWidget);
    expect(find.text('Unlock this wallet'), findsNothing, reason: 'the open wallet can be deleted here');
    await tester.tap(find.text('Delete wallet'));
    await tester.pump(const Duration(milliseconds: 300));
    final button = find.widgetWithText(EButton, 'Delete wallet');
    expect(tester.widget<EButton>(button).onPressed, isNull);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Main wallet');
    await tester.tap(find.text('The recovery phrase is written down'));
    await tester.pump();
    expect(tester.widget<EButton>(button).onPressed, isNull, reason: 'the password is still missing');
    await tester.enterText(fields.at(1), 'test-pass-1234');
    await tester.pump();
    expect(tester.widget<EButton>(button).onPressed, isNotNull);
    await _end(tester);
  });

  test('a failed removal of the open wallet still leaves the app locked', () async {
    final api = _FailingRemove();
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(api)]);
    addTearDown(container.dispose);
    final desk = container.read(deskProvider.notifier);
    await desk.refresh();
    expect(container.read(deskProvider).account?.id, 'legacy-mainnet');
    await expectLater(desk.removeWallet('legacy-mainnet', WalletRemoval.delete, password: 'x'), throwsA(isA<DeskError>()));
    expect(api.locked, isTrue);
    expect(container.read(deskProvider).account, isNull);
  });
}
