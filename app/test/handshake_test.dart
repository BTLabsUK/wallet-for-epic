import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/handshake.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _you = HandshakeParty.you;
const _them = HandshakeParty.them;
const _network = HandshakeParty.network;

/// Each step as (actor, from, to).
List<(HandshakeParty, HandshakeParty, HandshakeParty?)> _order(
  HandshakeFlow flow,
) => [for (final s in handshakeSteps(flow)) (s.actor, s.from, s.to)];

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildWalletTheme(protocolDark, Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: const Scaffold(body: HandshakeSheet()),
    ),
  );
  await tester.pump();
  return AppLocalizations.of(tester.element(find.byType(HandshakeSheet)));
}

/// One step and a frame more: a controller completes only once its duration has passed.
Future<void> _nextStep(WidgetTester tester) async {
  await tester.pump(handshakeStepDuration + const Duration(milliseconds: 20));
  await tester.pump();
}

String _caption(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(handshakeCaptionKey)).data!;

void main() {
  group('handshake order', () {
    test('a payment: you start, they sign and return it, you finish and post', () {
      expect(_order(HandshakeFlow.payment), [
        (_you, _you, _them),
        (_them, _them, _you),
        (_you, _you, _network),
        (_network, _network, null),
      ]);
    });

    test('a request: you ask, the payer adds coins and signs, you finish', () {
      expect(_order(HandshakeFlow.request), [
        (_you, _you, _them),
        (_them, _them, _you),
        (_you, _you, _network),
        (_network, _network, null),
      ]);
    });

    test('the wallet that starts is the one that posts, in both flows', () {
      for (final flow in HandshakeFlow.values) {
        final steps = handshakeSteps(flow);
        expect(steps.first.actor, _you, reason: '$flow');
        expect(
          steps.where((s) => s.to == _network).single.from,
          steps.first.actor,
          reason: '$flow',
        );
      }
    });
  });

  group('handshake sheet', () {
    testWidgets('captions advance in order and wrap round', (tester) async {
      final l = await _pump(tester);
      final payment = [
        l.handshakePay1,
        l.handshakePay2,
        l.handshakeFinish,
        l.handshakeConfirm,
      ];
      for (var i = 0; i < 5; i++) {
        final n = i % 4;
        expect(_caption(tester), '${n + 1}. ${payment[n]}');
        await _nextStep(tester);
      }
    });

    testWidgets('the toggle shows the request, from its first step', (
      tester,
    ) async {
      final l = await _pump(tester);
      await _nextStep(tester);
      await tester.tap(find.text(l.handshakeRequest));
      await tester.pump();
      expect(_caption(tester), '1. ${l.handshakeReq1}');
      await _nextStep(tester);
      expect(_caption(tester), '2. ${l.handshakeReq2}');
    });

    testWidgets('pause stops it; the step buttons still move it', (
      tester,
    ) async {
      final l = await _pump(tester);
      await tester.tap(find.byTooltip(l.fileHelpPause));
      await tester.pump();
      await tester.pump(handshakeStepDuration * 3);
      expect(_caption(tester), '1. ${l.handshakePay1}');

      await tester.tap(find.byTooltip(l.handshakeNext));
      await tester.pump();
      expect(_caption(tester), '2. ${l.handshakePay2}');
      await tester.tap(find.byTooltip(l.handshakePrevious));
      await tester.tap(find.byTooltip(l.handshakePrevious));
      await tester.pump();
      expect(_caption(tester), '4. ${l.handshakeConfirm}');

      await tester.tap(find.byTooltip(l.fileHelpPlay));
      await tester.pump();
      await _nextStep(tester);
      expect(_caption(tester), '1. ${l.handshakePay1}');
    });

    testWidgets('reduced motion: nothing plays, step buttons only', (
      tester,
    ) async {
      final l = await _pump(tester, reducedMotion: true);
      expect(find.byTooltip(l.fileHelpPause), findsNothing);
      expect(find.byTooltip(l.fileHelpPlay), findsNothing);
      await tester.pump(handshakeStepDuration * 2);
      expect(_caption(tester), '1. ${l.handshakePay1}');
      await tester.tap(find.byTooltip(l.handshakeNext));
      await tester.pump();
      expect(_caption(tester), '2. ${l.handshakePay2}');
      // Settles: nothing loops.
      await tester.pumpAndSettle();
    });
  });
}
