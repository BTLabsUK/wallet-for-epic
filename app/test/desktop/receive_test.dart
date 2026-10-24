// Receive (spec 4): no QR code on open in any state, the Epicbox reveal keeps the hero's size,
// the compact reveal opens and closes in the same time, panels grow with their switch, and
// the page carries none of the banned words.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/receive_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

const _args = [
  ReceiveArgs(),
  ReceiveArgs(epicbox: RxEpicbox.off),
  ReceiveArgs(http: RxHttp.on, tor: RxTor.on),
  ReceiveArgs(http: RxHttp.starting, tor: RxTor.connecting),
  ReceiveArgs(epicbox: RxEpicbox.down, http: RxHttp.failed, tor: RxTor.failed),
];

Future<ProviderContainer> _pump(WidgetTester tester, ReceiveArgs args, {double width = 1440, double height = 900, bool reduce = false}) async {
  tester.view.physicalSize = Size(width - 224, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))]);
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
  await tester.runAsync(() => advancedOn(container));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: MediaQuery(
          data: MediaQueryData(size: Size(width - 224, 900), disableAnimations: reduce),
          child: Scaffold(body: ReceiveScreen(arg: args)),
        ),
      ),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }
  return container;
}

const _images = ['rx-qr-image-epicbox', 'rx-qr-image-http', 'rx-qr-image-tor'];

void main() {
  for (final width in [1200.0, 1340.0, 1440.0, 1600.0]) {
    testWidgets('no QR code on open in any state at $width px, nothing overflows', (tester) async {
      for (final a in _args) {
        await _pump(tester, a, width: width);
        for (final k in _images) {
          expect(find.byKey(ValueKey(k)), findsNothing, reason: '$k with $a');
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Show QR reveals the Epicbox code without moving anything; Hide QR covers it', (tester) async {
    await _pump(tester, const ReceiveArgs());
    final panel = find.byKey(const ValueKey('rx-panel-epicbox'));
    final before = tester.getRect(panel);
    final show = find.byKey(const ValueKey('rx-qr-epicbox'));
    final boxBefore = tester.getRect(show);
    await tester.tap(find.text('Show QR'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rx-qr-image-epicbox')), findsOneWidget);
    expect(tester.getRect(panel), before);
    expect(tester.getRect(show).center, boxBefore.center);
    await tester.tap(find.text('Hide QR'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rx-qr-image-epicbox')), findsNothing);
    expect(find.text('QR code of the Epicbox address'), findsOneWidget);
    expect(tester.getRect(panel), before);
  });

  testWidgets('the HTTP reveal opens and closes in the same number of frames', (tester) async {
    await _pump(tester, const ReceiveArgs(http: RxHttp.on));
    final panel = find.byKey(const ValueKey('rx-panel-http'));
    Future<int> frames() async {
      var n = 0;
      var last = tester.getSize(panel).height;
      var still = 0;
      while (still < 2 && n < 60) {
        await tester.pump(const Duration(milliseconds: 16));
        n++;
        final h = tester.getSize(panel).height;
        still = h == last ? still + 1 : 0;
        last = h;
      }
      return n - 2;
    }

    final closed = tester.getSize(panel).height;
    await tester.tap(find.byKey(const ValueKey('rx-qr-http')));
    final open = await frames();
    expect(tester.getSize(panel).height, greaterThan(closed + 150));
    await tester.tap(find.byKey(const ValueKey('rx-qr-http')));
    final close = await frames();
    expect(tester.getSize(panel).height, closed);
    expect((open - close).abs(), lessThanOrEqualTo(1));
    expect(open, inInclusiveRange(13, 17));
  });

  testWidgets('with reduced motion the reveal swaps in one frame', (tester) async {
    await _pump(tester, const ReceiveArgs(http: RxHttp.on), reduce: true);
    await tester.tap(find.byKey(const ValueKey('rx-qr-http')));
    await tester.pump();
    expect(find.byKey(const ValueKey('rx-qr-image-http')), findsOneWidget);
  });

  testWidgets('the HTTP panel grows with its switch and shrinks back to its state line', (tester) async {
    await _pump(tester, const ReceiveArgs());
    final panel = find.byKey(const ValueKey('rx-panel-http'));
    final small = tester.getSize(panel).height;
    expect(find.descendant(of: panel, matching: find.textContaining('Off', findRichText: true)), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('rx-switch-http')));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
    }
    expect(tester.getSize(panel).height, greaterThan(small + 60));
    expect(find.byKey(const ValueKey('rx-qr-http')), findsOneWidget);
  });

  testWidgets('two columns from 1340 px start level; one column below', (tester) async {
    await _pump(tester, const ReceiveArgs(http: RxHttp.on, tor: RxTor.on), width: 1440);
    final hero = tester.getRect(find.byKey(const ValueKey('rx-panel-epicbox')));
    final head = tester.getRect(find.text('Other ways to receive'));
    expect(head.left, greaterThan(hero.right));
    expect((head.top - hero.top).abs(), lessThan(10));
    await _pump(tester, const ReceiveArgs(http: RxHttp.on, tor: RxTor.on), width: 1200);
    final hero2 = tester.getRect(find.byKey(const ValueKey('rx-panel-epicbox')));
    expect(tester.getRect(find.text('Other ways to receive')).top, greaterThan(hero2.bottom));
  });

  testWidgets("a header icon scrolls to its method's panel", (tester) async {
    // With Tor on, Link is the one panel beside Epicbox: a short window puts it below the fold.
    await _pump(tester, const ReceiveArgs(http: RxHttp.on, tor: RxTor.on), width: 1200, height: 600);
    final panel = find.byKey(const ValueKey('rx-panel-tor'));
    final view = tester.getRect(find.byType(Scrollable).first);
    final before = tester.getRect(panel).top;
    expect(view.contains(tester.getRect(panel).bottomLeft), isFalse, reason: 'below the fold in one column');
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Link Payment · Tor: ')));
    await tester.pumpAndSettle();
    expect(tester.getRect(panel).top, lessThan(before));
    expect(view.contains(tester.getRect(panel).topLeft), isTrue);
  });

  testWidgets('the header says each method in words for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const ReceiveArgs(http: RxHttp.on));
    expect(find.bySemanticsLabel(RegExp(r'^Epicbox on, Link Payment · HTTP on')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no banned words on the page', (tester) async {
    for (final a in _args) {
      await _pump(tester, a);
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        final s = (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase();
        expect(s.contains('listener') || s.contains('relay') || s.contains('epic address'), isFalse, reason: s);
      }
    }
  });
}
