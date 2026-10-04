// The notice standard (`app/README.md` "Notifications"): levels and their timing, the queue,
// dismissal, the host above the navigator, semantics and large text.

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              key: _second,
              appBar: AppBar(title: const Text('Second')),
            ),
          ),
        ),
        child: const Text('Open'),
      ),
    ),
  );
}

/// The app's host over a plain screen, on a phone.
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
          child: NoticeHost(child: child!),
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

  testWidgets('a notice floats over the app bar and survives a pop', (
    tester,
  ) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final appBar = tester.getRect(find.byType(AppBar).last);
    c.notices.show('PIN changed', level: NoticeLevel.success);
    Navigator.of(tester.element(find.byKey(_second))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_second), findsNothing);
    expect(find.text('PIN changed'), findsOneWidget);
    final card = tester.getRect(_card);
    // At the top, inside the safe area, over the app bar.
    expect(card.top, lessThan(appBar.bottom));
    expect(card.overlaps(appBar), isTrue);
    // Touches outside the card still reach the screen.
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(_second), findsOneWidget);
  });

  testWidgets('the card is at most 600 dp wide', (tester) async {
    final c = await _pump(tester);
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 1;
    c.notices.show('Wide screen', level: NoticeLevel.info);
    await tester.pumpAndSettle();
    expect(tester.getSize(_card).width, 600);
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
        MaterialApp(
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
      );
      expect(tester.getSize(find.byType(ProgressSlot)).height, 2);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    }
  });
}
