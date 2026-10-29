// SPDX-License-Identifier: Apache-2.0
// Text selection on the desktop (selectable.dart): the page's and a dialog's text select with
// the mouse (drag, double-click a word) and copy with Ctrl+C; a scrolling pane (a payment's
// details) selects within itself; a dialog with a selection still
// closes with Esc; button labels, the sidebar and the recovery phrase never join a selection;
// hidden amounts copy as dots. The phone's Help topic selects with a long press.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_pairing.dart' show HelpAt;
import 'package:epic_wallet/src/desktop/screens/settings/settings_phrase.dart' show PhraseDemo;
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/help/help_content.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String? _clip;

void _fakeClipboard(WidgetTester tester) {
  _clip = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    switch (call.method) {
      case 'Clipboard.setData':
        _clip = (call.arguments as Map)['text'] as String?;
        return null;
      case 'Clipboard.getData':
        return _clip == null ? null : {'text': _clip};
      case 'Clipboard.hasStrings':
        return {'value': _clip?.isNotEmpty ?? false};
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

/// The desktop app on the mock wallet, at [route].
Future<ProviderContainer> _pumpApp(WidgetTester tester, DeskRoute route, {Object? arg, bool hideAmounts = false}) async {
  _fakeClipboard(tester);
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  if (hideAmounts) {
    final s = container.read(deskProvider).settings;
    await tester.runAsync(() => container.read(deskProvider.notifier).saveSettings(s.copyWith(hideAmounts: true)));
  }
  container.read(deskNavProvider.notifier).reset(route, arg);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(seconds: 1));
  return container;
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

/// Drags the mouse from the start of [finder]'s text to [dx] further right (and [dy] down).
Future<void> _drag(WidgetTester tester, Finder finder, {required double dx, double dy = 0}) async {
  final from = tester.getTopLeft(finder) + const Offset(2, 8);
  final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
  await tester.pump();
  await g.moveTo(from + Offset(dx / 2, dy / 2));
  await tester.pump();
  await g.moveTo(from + Offset(dx, dy));
  await tester.pump();
  await g.up();
  await tester.pump();
}

Future<void> _doubleClick(WidgetTester tester, Offset at) async {
  final g = await tester.startGesture(at, kind: PointerDeviceKind.mouse);
  await g.up();
  await tester.pump(const Duration(milliseconds: 50));
  final g2 = await tester.startGesture(at, kind: PointerDeviceKind.mouse);
  await g2.up();
  await tester.pump();
}

Finder _textContaining(String s) => find.byWidgetPredicate((w) => w is Text && (w.textSpan?.toPlainText() ?? w.data ?? '').contains(s));

void main() {
  testWidgets('Help: a drag selects the topic text and Ctrl+C copies it; a double-click takes a word', (tester) async {
    await _pumpApp(tester, DeskRoute.settingsHelp, arg: const HelpAt('maintenance'));
    final para = _textContaining('takes a wallet off the list');
    expect(para, findsOneWidget);
    await tester.ensureVisible(para);
    await tester.pump();
    await _drag(tester, para, dx: 260);
    expect(_clip, isNull);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, isNotNull);
    expect(_clip, startsWith('Remove from'));
    expect(_clip!.length, greaterThan(8));
    // The page keeps its focus inside the route: Tab still moves on from the region.
    final title = find.text('Clean up old wallet folders');
    await tester.ensureVisible(title);
    await tester.pump();
    await _doubleClick(tester, tester.getTopLeft(title) + const Offset(6, 8));
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip!.trim(), 'Clean');
  });

  testWidgets('Help: Select all copies the page, never the Read more toggle nor the sidebar', (tester) async {
    await _pumpApp(tester, DeskRoute.settingsHelp, arg: const HelpAt('maintenance'));
    final para = _textContaining('takes a wallet off the list');
    await tester.ensureVisible(para);
    await tester.pump();
    await _drag(tester, para, dx: 40);
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, contains('Clean up old wallet folders'));
    expect(_clip, contains('WALLET.txt'));
    expect(_clip, isNot(contains('Show less')));
    expect(_clip, isNot(contains('Read more')));
    expect(_clip, isNot(contains('Overview')));
  });

  testWidgets('payment details: the pane is a selection of its own (drag, word, Select all), apart from the list', (tester) async {
    await _pumpApp(tester, DeskRoute.activity, arg: 36);
    final line = _textContaining('Confirmed, ');
    expect(line, findsOneWidget);
    await _drag(tester, line, dx: 220);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, startsWith('Confirmed, 1,4'));
    await _doubleClick(tester, tester.getTopLeft(line) + const Offset(6, 8));
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, 'Confirmed');
    // Select all takes the details pane, not the activity list beside it.
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, contains('Confirmed, 1,440 confirmations.'));
    expect(_clip, contains('Mining pool payouts'));
    expect(_clip, isNot(contains('Kowalska')));
    final date = _textContaining('20 Oct 2026');
    await _drag(tester, date, dx: 100);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, startsWith('20 Oct'));
  });

  testWidgets('a dialog: its text selects and copies, and Esc still closes it', (tester) async {
    await _pumpApp(tester, DeskRoute.settingsHelp);
    final ctx = deskNavigatorKey.currentContext!;
    showEDialog<void>(
      ctx,
      builder: (_) => EDialog(
        title: 'Node not reachable',
        description: 'The node at node.example.org:3413 did not answer. Check the address and try again.',
        actions: [EButton(label: 'Close', onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final desc = _textContaining('did not answer');
    expect(desc, findsOneWidget);
    await _drag(tester, desc, dx: 200);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, startsWith('The node at'));
    expect(_clip!.length, greaterThan(8));
    // The button's label is no part of a selection.
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, contains('Node not reachable'));
    expect(_clip, isNot(contains('Close')));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(EDialog), findsNothing);
  });

  testWidgets('the recovery phrase never joins a selection', (tester) async {
    await _pumpApp(tester, DeskRoute.settingsPhrase, arg: PhraseDemo.shown);
    expect(find.text('orbit'), findsOneWidget);
    final intro = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('recovery phrase'));
    expect(intro, findsWidgets);
    await _drag(tester, intro.first, dx: 60);
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, isNotNull);
    expect(_clip, isNot(contains('orbit')));
    expect(_clip, isNot(contains('harbor')));
  });

  testWidgets('hidden amounts copy as dots, never the figure', (tester) async {
    await _pumpApp(tester, DeskRoute.overview, hideAmounts: true);
    expect(_textContaining('••••••'), findsWidgets);
    final dots = _textContaining('••••••').first;
    await _drag(tester, dots, dx: 30);
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(_clip, contains('••••••'));
    expect(_clip, isNot(contains('1,284.73')));
    expect(_clip, isNot(contains('1284.73')));
  });

  testWidgets('phone Help: a topic selects with a long press and offers Copy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final topics = helpTopics(3, platform: HelpPlatform.phone);
    final topic = topics.firstWhere((t) => t.id == HelpId.cancel);
    final section = helpSections.firstWhere((s) => s.id == topic.section);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [countedConfirmationsProvider.overrideWithValue(BigInt.from(3)), phoneTorProvider.overrideWith(_Tor.new)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HelpTopicScreen(topic: topic, section: section),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(HelpTopicScreen), matching: find.byType(SelectionArea)), findsOneWidget);
    final para = find.byType(HelpBlockView).first;
    await tester.longPressAt(tester.getTopLeft(para) + const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
  });
}

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(phase: PhoneTorPhase.off, onion: 'abc.onion');
}
