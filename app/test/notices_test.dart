// SPDX-License-Identifier: Apache-2.0
// The notice standard (`app/README.md` "Notifications"): levels and their timing, the queue,
// dismissal, the dock under the app bar, semantics and large text.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _second = Key('second');

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => SlotScaffold(
    appBar: AppBar(title: const Text('Home')),
    body: Align(
      alignment: Alignment.topCenter,
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SlotScaffold(
              key: _second,
              appBar: AppBar(title: const Text('Second')),
              body: const SizedBox.expand(),
            ),
          ),
        ),
        child: const Text('Open'),
      ),
    ),
  );
}

/// A plain screen with its dock, on a phone.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double textScale = 1,
  bool accessible = false,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: theme,
        theme: buildWalletTheme(protocolLight, Brightness.light),
        darkTheme: buildWalletTheme(protocolDark, Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            accessibleNavigation: accessible,
          ),
          child: child!,
        ),
        home: const _Home(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(_Home)));
}

extension on ProviderContainer {
  NoticeNotifier get notices => read(noticeProvider.notifier);

  /// The visible notice.
  Notice? get shown => read(noticeProvider);
}

/// The visible notice's text, or null.
String? _visible(ProviderContainer c) => c.shown?.text;

Finder get _card => find.byKey(noticeKey);

void main() {
  test('each level has its time, longer with an action or a screen reader', () {
    expect(noticeDuration(NoticeLevel.success), const Duration(seconds: 3));
    expect(noticeDuration(NoticeLevel.info), const Duration(seconds: 4));
    expect(noticeDuration(NoticeLevel.warning), const Duration(seconds: 6));
    expect(noticeDuration(NoticeLevel.error), const Duration(seconds: 8));
    expect(
      noticeDuration(NoticeLevel.success, action: true),
      const Duration(seconds: 7),
    );
    expect(
      noticeDuration(NoticeLevel.error, action: true, accessible: true),
      const Duration(seconds: 24),
    );
  });

  for (final level in NoticeLevel.values) {
    testWidgets('a ${level.name} notice leaves after its time', (tester) async {
      final c = await _pump(tester);
      final time = noticeDuration(level);
      c.notices.show('Hello', level: level);
      await tester.pump(time - const Duration(milliseconds: 100));
      expect(_visible(c), 'Hello');
      expect(_card, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_visible(c), isNull);
      await tester.pumpAndSettle();
      expect(_card, findsNothing);
    });
  }

  testWidgets('an action adds 4 seconds; persistent stays', (tester) async {
    final c = await _pump(tester);
    c.notices.show(
      'With action',
      level: NoticeLevel.success,
      action: NoticeAction('View', () {}),
    );
    await tester.pump(const Duration(milliseconds: 6900));
    expect(_visible(c), 'With action');
    await tester.pump(const Duration(milliseconds: 100));
    expect(_visible(c), isNull);

    c.notices.show('Stays', level: NoticeLevel.info, persistent: true);
    await tester.pump(const Duration(minutes: 5));
    expect(_visible(c), 'Stays');
  });

  testWidgets('a screen reader doubles the time', (tester) async {
    final c = await _pump(tester, accessible: true);
    c.notices.show('Slow', level: NoticeLevel.success);
    await tester.pump(const Duration(milliseconds: 5900));
    expect(_visible(c), 'Slow');
    await tester.pump(const Duration(milliseconds: 100));
    expect(_visible(c), isNull);
  });

  testWidgets('hover and a press pause the timer', (tester) async {
    final c = await _pump(tester);
    c.notices.show('Held', level: NoticeLevel.success);
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(_card));
    await tester.pump(const Duration(seconds: 20));
    expect(_visible(c), 'Held');
    // A click inside the card keeps it held while the mouse stays on it.
    await mouse.down(tester.getCenter(_card));
    await mouse.up();
    await tester.pump(const Duration(seconds: 20));
    expect(_visible(c), 'Held');
    await mouse.moveTo(const Offset(5, 900));
    await tester.pump(const Duration(seconds: 3));
    expect(_visible(c), isNull);

    c.notices.show('Pressed', level: NoticeLevel.success);
    await tester.pumpAndSettle();
    final finger = await tester.startGesture(tester.getCenter(_card));
    await tester.pump(const Duration(seconds: 20));
    expect(_visible(c), 'Pressed');
    await finger.up();
    await tester.pump(const Duration(seconds: 3));
    expect(_visible(c), isNull);
  });

  testWidgets('a new notice replaces one of the same or a lower level', (
    tester,
  ) async {
    final c = await _pump(tester);
    c.notices.show('Saved', level: NoticeLevel.success);
    c.notices.show('Note', level: NoticeLevel.info);
    expect(_visible(c), 'Note');
    c.notices.show('Careful', level: NoticeLevel.warning);
    expect(_visible(c), 'Careful');
    c.notices.show('Broken', level: NoticeLevel.error);
    expect(_visible(c), 'Broken');
    expect(c.notices.queued, isEmpty);
    await tester.pumpAndSettle();
    expect(find.text('Broken'), findsOneWidget);
    expect(find.text('Careful'), findsNothing);
  });

  testWidgets('a lower level queues behind a higher one, three at most', (
    tester,
  ) async {
    final c = await _pump(tester);
    c.notices.show('Broken', level: NoticeLevel.error);
    c.notices.show('One', level: NoticeLevel.success);
    c.notices.show('Two', level: NoticeLevel.warning);
    c.notices.show('Three', level: NoticeLevel.info);
    c.notices.show('Four', level: NoticeLevel.success);
    expect(_visible(c), 'Broken');
    // The oldest waiting one was dropped.
    expect(c.notices.queued.map((n) => n.text), ['Two', 'Three', 'Four']);
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsNothing);

    // The next one shows when the visible one leaves, on its own or closed.
    await tester.pump(noticeDuration(NoticeLevel.error));
    expect(_visible(c), 'Two');
    c.notices.dismiss();
    expect(_visible(c), 'Three');
    expect(c.notices.queued.map((n) => n.text), ['Four']);
  });

  testWidgets('a replaced persistent notice comes back', (tester) async {
    final c = await _pump(tester);
    c.notices.show('Update ready', level: NoticeLevel.info, persistent: true);
    c.notices.show('Copied', level: NoticeLevel.success);
    expect(_visible(c), 'Copied');
    await tester.pump(noticeDuration(NoticeLevel.success));
    expect(_visible(c), 'Update ready');
  });

  testWidgets('the same text again restarts the timer instead of stacking', (
    tester,
  ) async {
    final c = await _pump(tester);
    c.notices.show('Copied', level: NoticeLevel.success);
    final id = c.shown!.id;
    await tester.pump(const Duration(seconds: 2));
    c.notices.show('Copied', level: NoticeLevel.success);
    expect(c.shown!.id, id, reason: 'the card stays, no new one');
    expect(c.notices.queued, isEmpty);
    await tester.pump(const Duration(milliseconds: 2900));
    expect(_visible(c), 'Copied');
    await tester.pump(const Duration(milliseconds: 100));
    expect(_visible(c), isNull);

    // Also while it waits behind a higher level.
    c.notices.show('Broken', level: NoticeLevel.error);
    c.notices.show('Copied', level: NoticeLevel.success);
    c.notices.show('Copied', level: NoticeLevel.success);
    expect(c.notices.queued.map((n) => n.text), ['Copied']);
  });

  testWidgets('a tag updates its notice in place', (tester) async {
    final c = await _pump(tester);
    c.notices.show(
      'Downloading 10%',
      level: NoticeLevel.info,
      persistent: true,
      progress: 0.1,
      tag: 'update',
    );
    final id = c.shown!.id;
    c.notices.show(
      'Downloading 50%',
      level: NoticeLevel.info,
      persistent: true,
      progress: 0.5,
      tag: 'update',
    );
    expect(c.shown!.id, id);
    expect(c.shown!.progress, 0.5);
    c.notices.dismissTag('update');
    expect(_visible(c), isNull);
  });

  testWidgets('a swipe up or sideways dismisses; a nudge does not', (
    tester,
  ) async {
    final c = await _pump(tester);
    c.notices.show('Swipe me', level: NoticeLevel.info);
    await tester.pumpAndSettle();
    await tester.drag(_card, const Offset(0, -8));
    await tester.pumpAndSettle();
    expect(_visible(c), 'Swipe me');

    await tester.drag(_card, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(_visible(c), isNull);
    expect(_card, findsNothing);

    for (final dx in [250.0, -250.0]) {
      c.notices.show('Sideways $dx', level: NoticeLevel.info);
      await tester.pumpAndSettle();
      await tester.drag(_card, Offset(dx, 0));
      await tester.pumpAndSettle();
      expect(_visible(c), isNull, reason: 'dx $dx');
    }
  });

  testWidgets(
    'warnings, errors, persistent notices and actions can be closed',
    (tester) async {
      final c = await _pump(tester);
      Finder close() =>
          find.descendant(of: _card, matching: find.byTooltip('Close'));
      for (final (level, closable) in [
        (NoticeLevel.info, false),
        (NoticeLevel.success, false),
        (NoticeLevel.warning, true),
        (NoticeLevel.error, true),
      ]) {
        c.notices.show('A ${level.name}', level: level);
        await tester.pumpAndSettle();
        expect(close(), closable ? findsOneWidget : findsNothing);
      }
      // The error is still up; an info notice would wait behind it.
      c.notices.clear();
      c.notices.show('Persistent', level: NoticeLevel.info, persistent: true);
      await tester.pumpAndSettle();
      await tester.tap(close());
      await tester.pumpAndSettle();
      expect(_visible(c), isNull);

      var pressed = 0;
      c.notices.show(
        'Paid',
        level: NoticeLevel.success,
        action: NoticeAction('View', () => pressed++),
      );
      await tester.pumpAndSettle();
      expect(close(), findsOneWidget);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(_visible(c), isNull, reason: 'the action closes it too');
    },
  );

  testWidgets('the dock is closed without a notice and opens to the card', (
    tester,
  ) async {
    final c = await _pump(tester);
    final dock = find.byType(NoticeDock);
    final appBar = tester.getRect(find.byType(AppBar));
    final open = find.text('Open');
    final idleTop = tester.getTopLeft(open).dy;
    expect(tester.getSize(dock).height, 0);
    expect(_card, findsNothing);

    c.notices.show('PIN changed', level: NoticeLevel.success);
    // Half way it is opening, and the content moves with it.
    await tester.pump();
    await tester.pump(noticeDockDuration ~/ 2);
    final half = tester.getSize(dock).height;
    await tester.pumpAndSettle();
    final card = tester.getRect(_card);
    final height = tester.getSize(dock).height;
    expect(half, inExclusiveRange(0, height));
    expect(height, card.height + NoticeDock.padding.vertical);
    // Under the app bar, never over it, and the content moved down by the dock.
    expect(card.top, appBar.bottom + progressSlotHeight + 12);
    expect(card.overlaps(appBar), isFalse);
    expect(tester.getTopLeft(open).dy, idleTop + height);
    expect(card.overlaps(tester.getRect(open)), isFalse);

    // It closes again with the last notice.
    await tester.pump(noticeDuration(NoticeLevel.success));
    await tester.pumpAndSettle();
    expect(_card, findsNothing);
    expect(tester.getSize(dock).height, 0);
    expect(tester.getTopLeft(open).dy, idleTop);
  });

  testWidgets('android-02: a scrolling list stays under the finger while the dock opens and closes', (
    tester,
  ) async {
    final c = await _pump(tester);
    final taps = <int>[];
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => SlotScaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
              for (var i = 0; i < 30; i++)
                ListTile(key: ValueKey('row$i'), title: Text('Row $i'), onTap: () => taps.add(i)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('row5'));
    final before = tester.getCenter(row);
    await tester.tap(row);
    c.notices.show('Notifications off', level: NoticeLevel.info);
    await tester.pump();
    await tester.pump(noticeDockDuration ~/ 2);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(NoticeDock).last).height, greaterThan(0));
    // The same row under the same spot: a second tap there toggles it again.
    expect(tester.getCenter(row).dy, moreOrLessEquals(before.dy, epsilon: 1));
    await tester.tapAt(before);
    expect(taps, [5, 5]);
    // The card still covers nothing.
    expect(tester.getRect(_card).overlaps(tester.getRect(row)), isFalse);
    // Closing does not move it either.
    await tester.pump(noticeDuration(NoticeLevel.info));
    await tester.pumpAndSettle();
    expect(tester.getCenter(row).dy, moreOrLessEquals(before.dy, epsilon: 1));
  });

  testWidgets('android-18: a persistent notice pushes the content down and covers nothing', (
    tester,
  ) async {
    final c = await _pump(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => SlotScaffold(
          appBar: AppBar(title: const Text('Outputs')),
          body: ListView(
            children: [
              for (var i = 0; i < 30; i++)
                ListTile(key: ValueKey('row$i'), title: Text('Row $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('row0'));
    final before = tester.getTopLeft(first).dy;
    c.notices.show(
      'Downloading version 26.10.9… 58%',
      level: NoticeLevel.info,
      persistent: true,
      progress: 0.58,
      progressLabel: 'Download',
      tag: 'update',
    );
    await tester.pumpAndSettle();
    final dock = tester.getSize(find.byType(NoticeDock).last).height;
    expect(dock, greaterThan(0));
    // The first row moved down by the dock, so it sits whole under the card.
    expect(tester.getTopLeft(first).dy, moreOrLessEquals(before + dock, epsilon: 1));
    expect(tester.getRect(_card).overlaps(tester.getRect(first)), isFalse);
    // Progress updates keep it there.
    c.notices.show(
      'Downloading version 26.10.9… 70%',
      level: NoticeLevel.info,
      persistent: true,
      progress: 0.7,
      progressLabel: 'Download',
      tag: 'update',
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dy, moreOrLessEquals(before + dock, epsilon: 1));
    // Closing it gives the space back.
    c.notices.dismissTag('update');
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dy, moreOrLessEquals(before, epsilon: 1));
  });

  testWidgets('a notice survives a pop, docked on the screen below', (
    tester,
  ) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    c.notices.show('PIN changed', level: NoticeLevel.success);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(_second), matching: _card),
      findsOneWidget,
    );
    Navigator.of(tester.element(find.byKey(_second))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_second), findsNothing);
    expect(find.text('PIN changed'), findsOneWidget);
    final appBar = tester.getRect(find.byType(AppBar));
    final card = tester.getRect(_card);
    expect(card.top, greaterThanOrEqualTo(appBar.bottom));
    // The screen below still takes touches.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(_second), findsOneWidget);
  });

  testWidgets('a screen opened while a notice shows starts with it docked', (
    tester,
  ) async {
    final c = await _pump(tester);
    c.notices.show('Saved', level: NoticeLevel.success, persistent: true);
    await tester.pumpAndSettle();
    final open = tester.getSize(find.byType(NoticeDock)).height;
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byKey(_second),
              matching: find.byType(NoticeDock),
            ),
          )
          .height,
      open,
    );
  });

  testWidgets('the card takes the content width, 600 dp at most', (
    tester,
  ) async {
    final c = await _pump(tester);
    c.notices.show('Phone', level: NoticeLevel.info);
    await tester.pumpAndSettle();
    expect(tester.getSize(_card).width, 1080 / 2.625 - 32);
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 1;
    c.notices.show('Wide screen', level: NoticeLevel.info);
    await tester.pumpAndSettle();
    expect(tester.getSize(_card).width, 600 - 32);
  });

  testWidgets('a screen reader hears the level and the whole text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final c = await _pump(tester);
    const long =
        'Could not reach the node. The payment is unchanged, and the app '
        'tries again by itself in a minute. Nothing is lost while it waits, '
        'and you can keep using the wallet.';
    c.notices.show(long, level: NoticeLevel.error);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Error: $long'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Error: $long')),
      isSemantics(isLiveRegion: true),
    );
    // Two lines on screen.
    final text = tester.widget<Text>(
      find.descendant(of: _card, matching: find.text(long)),
    );
    expect(text.maxLines, 2);
    handle.dispose();
  });

  for (final theme in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('every level fits at text scale 2 (${theme.name})', (
      tester,
    ) async {
      final c = await _pump(tester, textScale: 2, theme: theme);
      for (final level in NoticeLevel.values) {
        c.notices.show(
          'Version 1.4.0 could not be installed. Please try again later.',
          level: level,
          action: NoticeAction('Try again', () {}),
          progress: level == NoticeLevel.info ? 0.4 : null,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: level.name);
        final card = tester.getRect(_card);
        expect(card.left, greaterThanOrEqualTo(0));
        expect(card.right, lessThanOrEqualTo(1080 / 2.625));
        expect(card.overlaps(tester.getRect(find.byType(AppBar))), isFalse);
        expect(find.text('Try again'), findsOneWidget);
      }
    });
  }

  testWidgets('reduced motion turns the entrance into a cut', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final c = await _pump(tester);
    c.notices.show('Now', level: NoticeLevel.info);
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: _card, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('the progress slot reserves 2 dp, at any text scale', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: SlotScaffold(
              appBar: AppBar(title: const Text('Screen')),
              idle: const SlotProgress(label: 'Loading'),
              body: const Text('Body'),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ProgressSlot)).height, 2);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    }
  });
}
