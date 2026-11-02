// SPDX-License-Identifier: Apache-2.0
// Receive: no QR code on open in any state, the Epicbox reveal keeps the hero's size,
// the compact reveal opens and closes in the same time, panels grow with their switch, and
// the page carries none of the banned words.
import 'package:epic_wallet/src/tor_build.dart';
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

/// Internet on: the QR code is the internet address's (this computer's 127.0.0.1 has none).
Future<void> _internet(WidgetTester tester, ProviderContainer container) async {
  final n = container.read(deskProvider.notifier);
  await tester.runAsync(() => n.saveSettings(container.read(deskProvider).settings.copyWith(publicMode: true)));
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }
}

// The Epicbox code shows from the start (item 17); the others open on demand.
const _images = ['rx-qr-image-http', 'rx-qr-image-tor'];

void main() {
  for (final width in [1200.0, 1340.0, 1440.0, 1600.0]) {
    testWidgets('only the Epicbox QR code on open in any state at $width px, nothing overflows', (tester) async {
      for (final a in _args) {
        await _pump(tester, a, width: width);
        for (final k in _images) {
          expect(find.byKey(ValueKey(k)), findsNothing, reason: '$k with $a');
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('the Epicbox code shows on open: no blur, no Show QR or Hide QR', (tester) async {
    await _pump(tester, const ReceiveArgs());
    expect(find.byKey(const ValueKey('rx-qr-image-epicbox')), findsOneWidget);
    expect(find.byKey(const ValueKey('rx-qr-epicbox')), findsNothing);
    expect(find.text('Show QR'), findsNothing);
    expect(find.text('Hide QR'), findsNothing);
    expect(find.text('QR code of the Epicbox address'), findsOneWidget);
  });

  testWidgets('the HTTP reveal opens and closes in the same number of frames', (tester) async {
    await _internet(tester, await _pump(tester, const ReceiveArgs(http: RxHttp.on)));
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
    await _internet(tester, await _pump(tester, const ReceiveArgs(http: RxHttp.on), reduce: true));
    await tester.tap(find.byKey(const ValueKey('rx-qr-http')));
    await tester.pump();
    expect(find.byKey(const ValueKey('rx-qr-image-http')), findsOneWidget);
  });

  testWidgets('the HTTP panel stays with Link · HTTP off, one line with its switch; on, grown with the address switches instead', (tester) async {
    final container = await _pump(tester, const ReceiveArgs());
    final panel = find.byKey(const ValueKey('rx-panel-http'));
    final own = find.byKey(const ValueKey('rx-switch-http'));
    expect(panel, findsOneWidget, reason: 'Link · HTTP off: the card stays, so it is turned on here');
    expect(own, findsOneWidget);
    expect(container.read(deskProvider).settings.payments.linkHttp, isFalse);
    await tester.tap(own);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
    }
    expect(container.read(deskProvider).settings.payments.linkHttp, isTrue);
    expect(panel, findsOneWidget);
    expect(own, findsNothing, reason: "on, the switches are the addresses'");
    expect(find.byKey(const ValueKey('http-local-switch')), findsOneWidget);
    expect(find.byKey(const ValueKey('rx-qr-http')), findsNothing, reason: 'no QR code for 127.0.0.1');
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
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Link · Tor: ')));
    await tester.pumpAndSettle();
    expect(tester.getRect(panel).top, lessThan(before));
    expect(view.contains(tester.getRect(panel).topLeft), isTrue);
  }, skip: !torBuilt);

  testWidgets('the header says each method in words for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const ReceiveArgs(http: RxHttp.on));
    expect(find.bySemanticsLabel(RegExp(r'^Epicbox connected, Link · HTTP receiving')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Tor not connected: the banner is the one message (D-04)', (tester) async {
    await _pump(tester, const ReceiveArgs(http: RxHttp.on, tor: RxTor.failed));
    expect(find.byKey(const ValueKey('rx-tor-notice')), findsOneWidget);
    // The banner offers Retry; the Tor line keeps only its state, with no second Retry.
    expect(find.descendant(of: find.byKey(const ValueKey('rx-panel-tor')), matching: find.text('Retry')), findsNothing);
    final line = tester.widget<EStateLine>(find.byKey(const ValueKey('rx-state-tor')).first);
    expect(line.line.detail, isNull);
    expect(line.line.state, EState.risk);
    // The chip keeps its words in the neutral look, never a second red signal.
    final chip = tester.widget<EBadge>(find.byKey(const ValueKey('tor-chip')));
    expect(chip.tone, BadgeTone.neutral);
  }, skip: !torBuilt);

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
