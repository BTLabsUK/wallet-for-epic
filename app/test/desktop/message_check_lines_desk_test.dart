// The desktop status popover's lines for the wallet's message checks (Epicbox popover):
// "Checking messages" after notices.check_show_after_ms, "Checked at", a failed check, and
// the lines for messages read, pairings failed, held, refused, kept and more waiting. Each
// shows for a report that has it and is absent otherwise.
import 'dart:async';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/routes.dart' show DeskRoute, deskStartProvider;
import 'package:epic_wallet/src/desktop/data/state.dart' show deskApiProvider, deskProvider;
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/message_checks.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart' show appConfig;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _delay = appConfig.checkShowAfter;

final _lines = {
  'Messages read: 3': const CheckOutcome(messages: 3),
  'Pairings failed: 1': const CheckOutcome(failed: 1),
  'Messages held: 2': const CheckOutcome(held: 2),
  'Messages refused: 3': const CheckOutcome(rejected: 1, dropped: 2),
  '1 message could not be read': const CheckOutcome(unreadable: 1),
  'More messages wait for the next check': const CheckOutcome(capped: 1),
};

const _popover = ValueKey('status-pop-epicbox');

Future<MessageChecks> _openPopover(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      deskStartProvider.overrideWithValue(DeskRoute.overview),
      deskLevelProvider.overrideWithValue(WalletLevel.everything),
      deskLevelUiProvider.overrideWithValue(DeskLevelFeatures.of(WalletLevel.everything, prefs: const AdvancedPrefs(), wallets: 1)),
    ],
  );
  addTearDown(container.dispose);
  final checks = MessageChecks(showAfter: _delay, digestGrace: Duration.zero);
  addTearDown(checks.dispose);
  mockBehind(container.read(deskApiProvider))!.messageChecks = checks;
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.byKey(const ValueKey('bar-status-epicbox')));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byKey(_popover), findsOneWidget);
  return checks;
}

Finder _inPopover(String text) => find.descendant(of: find.byKey(_popover), matching: find.textContaining(text));

Future<void> _end(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 10));
}

void main() {
  testWidgets('no check yet: the popover says nothing about checks', (tester) async {
    await _openPopover(tester);
    for (final t in ['Checking messages', 'Checked at', 'Messages', 'could not be read', 'More messages']) {
      expect(_inPopover(t), findsNothing, reason: t);
    }
    await _end(tester);
  });

  testWidgets('"Checking messages" shows only after notices.check_show_after_ms, then "Checked at" replaces it', (tester) async {
    final checks = await _openPopover(tester);
    final done = Completer<int>();
    final run = checks.run(CheckSource.collect, () => done.future, outcomeOf: (_) => const CheckOutcome());
    await tester.pump(_delay - const Duration(milliseconds: 100));
    expect(_inPopover('Checking messages'), findsNothing, reason: 'a quick check never shows');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_inPopover('Checking messages'), findsOneWidget);
    expect(_inPopover('Checked at'), findsNothing);
    done.complete(1);
    await run;
    await tester.pump();
    expect(_inPopover('Checking messages'), findsNothing);
    expect(_inPopover('Checked at'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('a failed check says so', (tester) async {
    final checks = await _openPopover(tester);
    await expectLater(checks.run<int>(CheckSource.collect, () async => throw StateError('x'), outcomeOf: (_) => const CheckOutcome()), throwsStateError);
    await tester.pump();
    expect(_inPopover('The last message check failed'), findsOneWidget);
    expect(_inPopover('Checked at'), findsNothing);
    await _end(tester);
  });

  for (final MapEntry(key: line, value: outcome) in _lines.entries) {
    testWidgets('"$line" shows for a report that has it and no other outcome line does', (tester) async {
      final checks = await _openPopover(tester);
      await checks.run(CheckSource.collect, () async => 1, outcomeOf: (_) => outcome);
      await tester.pump();
      expect(_inPopover('Checked at'), findsOneWidget);
      expect(_inPopover(line), findsOneWidget);
      for (final other in _lines.keys.where((k) => k != line)) {
        expect(_inPopover(other), findsNothing, reason: other);
      }
      await _end(tester);
    });
  }

  testWidgets('buffered and received counts add no line', (tester) async {
    final checks = await _openPopover(tester);
    await checks.run(CheckSource.drain, () async => 1, outcomeOf: (_) => const CheckOutcome(received: 4, buffered: 2));
    await tester.pump();
    expect(_inPopover('Checked at'), findsOneWidget);
    for (final other in _lines.keys) {
      expect(_inPopover(other), findsNothing, reason: other);
    }
    await _end(tester);
  });
}
