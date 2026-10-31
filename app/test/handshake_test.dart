// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/handshake.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _you = HandshakeParty.you;
const _relay = HandshakeParty.relay;
const _them = HandshakeParty.them;
const _network = HandshakeParty.network;

/// Each step as (actor, from, to).
List<(HandshakeParty, HandshakeParty, HandshakeParty?)> _order(
  HandshakeFlow flow,
) => [for (final s in handshakeSteps(flow)) (s.actor, s.from, s.to)];

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  HandshakeFlow flow = HandshakeFlow.payment,
  bool reducedMotion = false,
  double textScale = 1,
  Size size = const Size(1080, 2340),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildWalletTheme(protocolDark, Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        // The Invoice chip shows only with the Invoices switch on.
        child: AdvancedOptions(prefs: AdvancedPrefs.all, child: child!),
      ),
      home: Scaffold(body: HandshakeSheet(flow: flow)),
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
    test('a payment: you start, it goes through the relay to them, they sign, '
        'it comes back through the relay, you finish and post', () {
      expect(_order(HandshakeFlow.payment), [
        (_you, _you, _relay),
        (_them, _relay, _them),
        (_them, _them, _relay),
        (_relay, _relay, _you),
        (_you, _you, _network),
        (_network, _network, null),
      ]);
    });

    test(
      'a request: you ask through the relay, the payer adds coins and signs, '
      'it comes back through the relay, you (the issuer) finish and post',
      () {
        expect(_order(HandshakeFlow.request), [
          (_you, _you, _relay),
          (_them, _relay, _them),
          (_them, _them, _relay),
          (_relay, _relay, _you),
          (_you, _you, _network),
          (_network, _network, null),
        ]);
      },
    );

    test('a payment file: the same route, the file passed by hand, you open '
        'the reply', () {
      expect(_order(HandshakeFlow.file), [
        (_you, _you, _relay),
        (_them, _relay, _them),
        (_them, _them, _relay),
        (_you, _relay, _you),
        (_you, _you, _network),
        (_network, _network, null),
      ]);
    });

    test('the relay flows never talk directly, and the one that starts posts', () {
      for (final flow in [
        HandshakeFlow.payment,
        HandshakeFlow.request,
        HandshakeFlow.file,
      ]) {
        final steps = handshakeSteps(flow);
        expect(steps.first.actor, _you, reason: '$flow');
        for (final s in steps) {
          expect({s.from, s.to}, isNot(equals({_you, _them})), reason: '$flow');
        }
        expect(
          steps.where((s) => s.to == _network).single.from,
          steps.first.actor,
          reason: '$flow',
        );
      }
    });

    test('a Link payment goes straight to them, answers on the same '
        'connection, and has no relay', () {
      expect(_order(HandshakeFlow.direct), [
        (_you, _you, _them),
        (_them, _them, _you),
        (_you, _you, _network),
        (_network, _network, null),
      ]);
    });

    test('a QR payment is phone to phone, five steps, no relay', () {
      expect(_order(HandshakeFlow.qr), [
        (_you, _you, _them),
        (_them, _you, _them),
        (_them, _them, _you),
        (_you, _them, _you),
        (_you, _you, _network),
      ]);
      // Receiving: they show, you scan, you reply, they scan and post.
      expect(_order(HandshakeFlow.qrReceive), [
        (_them, _them, _you),
        (_you, _them, _you),
        (_you, _you, _them),
        (_them, _you, _them),
        (_them, _them, _network),
      ]);
    });

    test('only the relay flows name the server; the others never do', () {
      final l = lookupAppLocalizations(const Locale('en'));
      for (final flow in [
        HandshakeFlow.direct,
        HandshakeFlow.qr,
        HandshakeFlow.qrReceive,
      ]) {
        for (final s in handshakeSteps(flow)) {
          expect(s.caption(l).toLowerCase(), isNot(contains('server')));
          expect(s.caption(l).toLowerCase(), isNot(contains('slate')));
          expect({s.from, s.to}, isNot(contains(_relay)));
        }
      }
    });

    test('relay captions name the server; file captions do not', () {
      final l = lookupAppLocalizations(const Locale('en'));
      for (final flow in [HandshakeFlow.payment, HandshakeFlow.request]) {
        for (final s in handshakeSteps(flow).take(4)) {
          expect(s.caption(l), contains('server'), reason: '$flow');
        }
      }
      for (final s in handshakeSteps(HandshakeFlow.file)) {
        expect(s.caption(l), isNot(contains('server')));
      }
    });
  });

  group('handshake sheet', () {
    testWidgets('captions advance in order and wrap round', (tester) async {
      final l = await _pump(tester);
      final payment = [
        l.handshakePay1,
        l.handshakePay2,
        l.handshakeBack,
        l.handshakeRelayBack,
        l.handshakeFinish,
        l.handshakeConfirm,
      ];
      for (var i = 0; i < 7; i++) {
        final n = i % 6;
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
      final request = [
        l.handshakeReq1,
        l.handshakeReq2,
        l.handshakeBack,
        l.handshakeRelayBack,
        l.handshakeFinish,
        l.handshakeConfirm,
      ];
      for (final (i, caption) in request.indexed) {
        expect(_caption(tester), '${i + 1}. $caption');
        await _nextStep(tester);
      }
      expect(_caption(tester), '1. ${l.handshakeReq1}');
    });

    testWidgets('the file route labels the middle node File', (tester) async {
      final l = await _pump(tester);
      expect(find.text(l.handshakeRelay), findsOneWidget);
      await tester.tap(find.text(l.methodShortFile));
      await tester.pump();
      expect(_caption(tester), '1. ${l.handshakeFile1}');
      expect(find.text(l.handshakeRelay), findsNothing);
      // The segment names the method, the node the file.
      expect(find.text(l.methodShortFile), findsOneWidget);
      expect(find.text(l.handshakeFile), findsOneWidget);
    });

    testWidgets('each method opens its own explanation', (tester) async {
      final expected = {
        HandshakeFlow.payment: (lc) => lc.handshakePay1,
        HandshakeFlow.direct: (lc) => lc.handshakeLink1,
        HandshakeFlow.qr: (lc) => lc.handshakeQr1,
        HandshakeFlow.qrReceive: (lc) => lc.handshakeQrR1,
        HandshakeFlow.file: (lc) => lc.handshakeFile1,
      };
      for (final MapEntry(key: flow, value: first) in expected.entries) {
        await tester.pumpWidget(const SizedBox());
        final l = await _pump(tester, flow: flow);
        expect(_caption(tester), '1. ${first(l)}', reason: '$flow');
        // The tab of the method is the lit one.
        final tabs = tester.widget<SegmentedButton<HandshakeFlow>>(
          find.byType(SegmentedButton<HandshakeFlow>),
        );
        expect(tabs.selected, {flow});
      }
    });

    testWidgets('QR Payment: the five QR steps, a phone-to-phone diagram, '
        'no relay text', (tester) async {
      final l = await _pump(tester, flow: HandshakeFlow.qr);
      final qr = [
        l.handshakeQr1,
        l.handshakeQr2,
        l.handshakeQr3,
        l.handshakeQr4,
        l.handshakeQr5,
      ];
      for (final (i, caption) in qr.indexed) {
        expect(_caption(tester), '${i + 1}. $caption');
        expect(find.textContaining('relay'), findsNothing);
        expect(find.text(l.handshakeRelay), findsNothing);
        await _nextStep(tester);
      }
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
      expect(_caption(tester), '6. ${l.handshakeConfirm}');

      await tester.tap(find.byTooltip(l.fileHelpPlay));
      await tester.pump();
      await _nextStep(tester);
      expect(_caption(tester), '1. ${l.handshakePay1}');
    });

    testWidgets('a step press while it plays pauses there', (tester) async {
      final l = await _pump(tester);
      await tester.tap(find.byTooltip(l.handshakeNext));
      await tester.pump();
      expect(_caption(tester), '2. ${l.handshakePay2}');
      expect(find.byTooltip(l.fileHelpPlay), findsOneWidget);
      await tester.pump(handshakeStepDuration * 3);
      expect(_caption(tester), '2. ${l.handshakePay2}');
    });

    testWidgets('fits a 360 dp phone at text scale 2', (tester) async {
      final l = await _pump(tester, textScale: 2, size: const Size(1080, 2400));
      expect(tester.takeException(), isNull);
      for (final flow in [l.handshakeRequest, l.methodShortFile]) {
        await tester.tap(find.text(flow).first);
        await tester.pump();
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byTooltip(l.handshakeNext));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      }
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
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
