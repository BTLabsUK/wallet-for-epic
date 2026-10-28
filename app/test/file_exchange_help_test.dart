// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/file_exchange_help.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

List<String> _captions(FileExchangeRole role) => switch (role) {
  FileExchangeRole.sender => [
    _l.fileHelpSendStep1,
    _l.fileHelpSendStep2,
    _l.fileHelpSendStep3,
    _l.fileHelpSendStep4,
  ],
  FileExchangeRole.receiver => [
    _l.fileHelpReceiveStep1,
    _l.fileHelpReceiveStep2,
    _l.fileHelpReceiveStep3,
    _l.fileHelpReceiveStep4,
  ],
};

/// A button that opens the help, as Send and Receive will.
Future<void> _open(
  WidgetTester tester,
  FileExchangeRole role, {
  bool reducedMotion = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildWalletTheme(
        brightness == Brightness.dark ? protocolDark : protocolLight,
        brightness,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showFileExchangeHelp(context, role: role),
              child: const Text('help'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('help'));
  // The sheet's entrance; the loop itself never settles.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String _caption(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(fileHelpCaptionKey)).data!;

/// Moves the loop forward by [steps] whole steps.
Future<void> _advance(WidgetTester tester, [int steps = 1]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(fileHelpStepDuration);
  }
}

void main() {
  for (final role in FileExchangeRole.values) {
    group(role.name, () {
      testWidgets('steps through all four captions and loops', (tester) async {
        await _open(tester, role);
        expect(find.text(_l.fileHelpTitle), findsOneWidget);
        expect(find.text(_l.fileHelpYou), findsOneWidget);
        expect(find.text(_l.fileHelpFriend), findsOneWidget);
        final captions = _captions(role);
        for (var i = 0; i < 4; i++) {
          expect(_caption(tester), captions[i], reason: 'step ${i + 1}');
          expect(find.bySemanticsLabel(_l.fileHelpStepOf(i + 1, 4)), findsOne);
          await _advance(tester);
        }
        expect(_caption(tester), captions[0], reason: 'loops back');
      });

      testWidgets('a tap pauses and a second tap plays on', (tester) async {
        await _open(tester, role);
        final captions = _captions(role);
        await _advance(tester);
        expect(_caption(tester), captions[1]);

        await tester.tap(find.byKey(fileHelpAnimationKey));
        await tester.pump();
        expect(find.bySemanticsLabel(_l.fileHelpPlay), findsOneWidget);
        await _advance(tester, 3);
        expect(_caption(tester), captions[1], reason: 'paused');

        await tester.tap(find.byKey(fileHelpAnimationKey));
        await tester.pump();
        expect(find.bySemanticsLabel(_l.fileHelpPause), findsOneWidget);
        await _advance(tester);
        expect(
          _caption(tester),
          captions[2],
          reason: 'plays from where it was',
        );
      });

      testWidgets('reduced motion shows the four steps as a still list', (
        tester,
      ) async {
        await _open(tester, role, reducedMotion: true);
        for (final caption in _captions(role)) {
          expect(find.text(caption), findsOneWidget);
        }
        expect(find.byKey(fileHelpAnimationKey), findsNothing);
        expect(find.byType(FileExchangePainter), findsNothing);
        // Nothing animates, so the sheet settles.
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(RegExp('^${_l.fileHelpStepOf(3, 4)}')),
          findsOneWidget,
        );
      });

      testWidgets('semantics: a labelled button, steps and a heading', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _open(tester, role);
        expect(
          tester.getSemantics(find.byKey(fileHelpAnimationKey)),
          matchesSemantics(
            label: _l.fileHelpPause,
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(find.semantics.byLabel(_l.fileHelpStepOf(1, 4)), findsOne);
        expect(
          find.semantics.byPredicate(
            (n) => n.label == _l.fileHelpTitle && n.flagsCollection.isHeader,
          ),
          findsOne,
        );
        // Only the visible caption is read out.
        expect(find.semantics.byLabel(_captions(role)[0]), findsOne);
        expect(find.semantics.byLabel(_captions(role)[1]), findsNothing);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });

      for (final brightness in Brightness.values) {
        testWidgets('text scale 2 fits, ${brightness.name}', (tester) async {
          await _open(tester, role, textScale: 2, brightness: brightness);
          for (var i = 0; i < 4; i++) {
            await _advance(tester);
          }
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text(_l.commonClose));
          await tester.pump();
          await tester.tap(find.text(_l.commonClose));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(FileExchangeHelp), findsNothing);
        });
      }

      testWidgets('text scale 2 fits the still list', (tester) async {
        await _open(tester, role, textScale: 2, reducedMotion: true);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }
}
