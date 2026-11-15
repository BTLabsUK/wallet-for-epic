// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/ui/motion_switches.dart';
import 'package:epic_wallet/src/ui/phone_motion.dart';
import 'package:epic_wallet/src/ui/phone_sheet.dart';
import 'package:epic_wallet/src/ui/phone_tab_pager.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme(TargetPlatform platform) => buildWalletTheme(
  protocolLight,
  Brightness.light,
).copyWith(platform: platform);

/// Pushes a screen over a home screen and returns the route's transition duration.
Future<Duration> _pushedDuration(
  WidgetTester tester,
  TargetPlatform platform, {
  bool modal = false,
}) async {
  late BuildContext home;
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme(platform),
      home: Builder(
        builder: (context) {
          home = context;
          return const Scaffold(body: Text('home'));
        },
      ),
    ),
  );
  final route = modal
      ? PhoneModalRoute<void>(
          builder: (_) => const Scaffold(body: Text('next')),
        )
      : MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('next')),
        );
  Navigator.of(home).push(route);
  await tester.pump();
  return route.transitionDuration;
}

void main() {
  tearDown(() {
    phoneTabsSlide = false;
  });

  group('pushed screens use the shared transitions', () {
    test('the theme carries them for Android and iOS, within 300 ms', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        final builder = _theme(platform)
            .pageTransitionsTheme
            .builders[platform];
        expect(builder, isA<PhoneTransitionsBuilder>(), reason: '$platform');
        expect(
          builder!.transitionDuration,
          lessThanOrEqualTo(const Duration(milliseconds: 300)),
        );
        expect(
          builder.reverseTransitionDuration,
          lessThanOrEqualTo(const Duration(milliseconds: 300)),
        );
      }
      expect(
        (_theme(TargetPlatform.android)
                    .pageTransitionsTheme
                    .builders[TargetPlatform.android]!
                as PhoneTransitionsBuilder)
            .inner,
        isA<PredictiveBackPageTransitionsBuilder>(),
      );
      expect(
        (_theme(TargetPlatform.iOS)
                    .pageTransitionsTheme
                    .builders[TargetPlatform.iOS]!
                as PhoneTransitionsBuilder)
            .inner,
        isA<CupertinoPageTransitionsBuilder>(),
      );
    });

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets(
        'a MaterialPageRoute on $platform moves for the shared 300 ms, then settles',
        (tester) async {
          expect(await _pushedDuration(tester, platform), PhoneMotion.push);
          await tester.pump(const Duration(milliseconds: 150));
          expect(find.text('next'), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 160));
          await tester.pumpAndSettle();
          expect(find.text('next'), findsOneWidget);
          expect(
            find.text('home'),
            findsNothing,
            reason: 'the covered screen is dropped once the push settled',
          );
        },
      );

      testWidgets(
        'reduced motion: the pushed route has no duration on $platform',
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          expect(await _pushedDuration(tester, platform), Duration.zero);
          await tester.pump();
          expect(find.text('next'), findsOneWidget);
          expect(find.text('home'), findsNothing);
        },
      );
    }

    testWidgets(
      'a modal (Send, Receive) rises from the bottom, and is still with reduced motion',
      (tester) async {
        expect(
          await _pushedDuration(tester, TargetPlatform.android, modal: true),
          PhoneMotion.push,
        );
        await tester.pump(const Duration(milliseconds: 100));
        final at = tester.getTopLeft(find.text('next')).dy;
        expect(at, greaterThan(0), reason: 'part-way up');
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byType(Scaffold).last).dy, 0);
        expect(
          find.text('home', skipOffstage: false),
          findsOneWidget,
          reason: 'the shell stays under it',
        );
      },
    );

    testWidgets('a modal has no duration with reduced motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      expect(
        await _pushedDuration(tester, TargetPlatform.android, modal: true),
        Duration.zero,
      );
      await tester.pump();
      expect(tester.getTopLeft(find.byType(Scaffold).last).dy, 0);
    });
  });

  group('sheets', () {
    Future<void> open(WidgetTester tester, {required bool still}) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: still);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(TargetPlatform.android),
          home: Builder(
            builder: (c) {
              ctx = c;
              return const Scaffold();
            },
          ),
        ),
      );
      showPhoneSheet<void>(
        context: ctx,
        builder: (_) => const SizedBox(height: 120, child: Text('sheet')),
      );
    }

    testWidgets('rise within 300 ms', (tester) async {
      await open(tester, still: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        tester.getTopLeft(find.text('sheet')).dy,
        lessThan(screen),
        reason: 'on its way up',
      );
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 210));
      expect(tester.hasRunningAnimations, isFalse, reason: 'settled by 310 ms');
    });

    testWidgets('with reduced motion they are there at once', (tester) async {
      await open(tester, still: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('sheet'), findsOneWidget);
    });
  });

  group('the shell tabs', () {
    Widget host({required ValueNotifier<int> tab, bool still = false}) =>
        MaterialApp(
          theme: _theme(TargetPlatform.android),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: still),
            child: ValueListenableBuilder<int>(
              valueListenable: tab,
              builder: (_, selected, _) => PhoneTabs(
                selected: selected,
                onSelect: (i) => tab.value = i,
                flat: (screen) => screen,
                children: [
                  for (final n in ['one', 'two', 'three', 'four'])
                    Center(child: Text(n)),
                ],
              ),
            ),
          ),
        );

    testWidgets(
      'a tap slides: both screens are on view part-way, only the new one after',
      (tester) async {
        phoneTabsSlide = true;
        final tab = ValueNotifier(0);
        await tester.pumpWidget(host(tab: tab));
        expect(find.text('one'), findsOneWidget);
        tab.value = 1;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('one'), findsOneWidget);
        expect(find.text('two'), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text('one'), findsNothing);
        expect(find.text('two'), findsOneWidget);
      },
    );

    testWidgets('a far tab passes no screen in between', (tester) async {
      phoneTabsSlide = true;
      final tab = ValueNotifier(0);
      await tester.pumpWidget(host(tab: tab));
      tab.value = 3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('two'), findsNothing);
      expect(find.text('three'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('four'), findsOneWidget);
      expect(find.text('one'), findsNothing);
    });

    testWidgets(
      'a swipe follows the finger, and the bar is told when it passes the middle',
      (tester) async {
        phoneTabsSlide = true;
        final tab = ValueNotifier(1);
        await tester.pumpWidget(host(tab: tab));
        await tester.drag(find.text('two'), const Offset(-500, 0));
        await tester.pump();
        expect(
          tab.value,
          2,
          reason: 'the bar moved on before the finger lifted',
        );
        await tester.pumpAndSettle();
        expect(find.text('three'), findsOneWidget);
        expect(find.text('two'), findsNothing);
        // Back, with a flick.
        await tester.fling(find.text('three'), const Offset(300, 0), 1200);
        await tester.pumpAndSettle();
        expect(tab.value, 1);
        expect(find.text('two'), findsOneWidget);
      },
    );

    testWidgets('no overswipe past the last tab', (tester) async {
      phoneTabsSlide = true;
      final tab = ValueNotifier(3);
      await tester.pumpWidget(host(tab: tab));
      await tester.fling(find.text('four'), const Offset(-300, 0), 1200);
      await tester.pumpAndSettle();
      expect(tab.value, 3);
      expect(find.text('four'), findsOneWidget);
    });

    testWidgets(
      'reduced motion: the tab is there at once, a flick still moves on',
      (tester) async {
        phoneTabsSlide = true;
        final tab = ValueNotifier(0);
        await tester.pumpWidget(host(tab: tab, still: true));
        tab.value = 1;
        await tester.pump();
        expect(find.text('one'), findsNothing);
        expect(find.text('two'), findsOneWidget);
      },
    );
  });
}
