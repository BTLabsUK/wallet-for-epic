// Help › How linked devices work: the sync picture animates through its four steps, stands
// still with its steps numbered under reduced motion, pauses on a tap and fits a 360 dp phone
// and a 1280 px desktop; the status panel shows the empty state with Link a device, and a linked
// device with its last notice beside two servers of which one does not answer.
import 'package:epic_wallet/src/desktop/theme/theme.dart' show buildDeskTheme;
import 'package:epic_wallet/src/devices/device_model.dart';
import 'package:epic_wallet/src/devices/device_providers.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/devices/sync_help.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

Future<void> _pump(WidgetTester tester, Widget child, {double width = 360, bool reducedMotion = false, bool desk = false}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: desk ? buildDeskTheme(Brightness.dark) : buildWalletTheme(protocolDark, Brightness.dark),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion), child: child!),
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

String _caption(WidgetTester tester) => tester.widget<Text>(find.byKey(syncHelpCaptionKey)).data!;

const _s1 = 'epicbox.epiccash.com', _s2 = 'epicbox.stackwallet.com';

DeviceView _linked(DateTime now, {bool paused = false}) => DeviceView(
  book: DeviceBook(
    deviceId: 'a' * 32,
    deviceName: 'Phone',
    servers: const [_s1, _s2],
    paused: paused,
    devices: [
      LinkedDevice(
        deviceId: 'd' * 32,
        name: 'Desktop',
        pairings: const {_s1: 'p1', _s2: 'p2'},
        linkedAt: now.subtract(const Duration(days: 3)),
        lastSeen: now.subtract(const Duration(minutes: 2)),
      ),
    ],
  ),
  link: null,
  supported: true,
  loaded: true,
);

SyncServerState _oneDown(String server) => server == _s1 ? SyncServerState.answering : SyncServerState.notAnswering;

void main() {
  group('the picture', () {
    testWidgets('animates: the caption follows the steps, with the servers the link uses', (tester) async {
      await _pump(tester, const SyncDiagram(thisIsPhone: true));
      expect(find.byKey(syncHelpStillKey), findsNothing);
      expect(_caption(tester), _l.syncHelpStep1);
      await tester.pump(syncHelpStepDuration);
      expect(_caption(tester), _l.syncHelpStep2(2));
      expect(_caption(tester), contains('both servers'));
      await tester.pump(syncHelpStepDuration);
      expect(_caption(tester), _l.syncHelpStep3);
      await tester.pump(syncHelpStepDuration);
      expect(_caption(tester), _l.syncHelpStep4);
      // It loops.
      await tester.pump(syncHelpStepDuration);
      expect(_caption(tester), _l.syncHelpStep1);
      expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'the loop runs');
      await _pump(tester, const SyncDiagram(thisIsPhone: true, servers: 1));
      await tester.pump(syncHelpStepDuration);
      expect(_caption(tester), contains('over the server.'));
    });

    testWidgets('a tap pauses the loop and names what the tap does', (tester) async {
      await _pump(tester, const SyncDiagram(thisIsPhone: true));
      expect(find.bySemanticsLabel(RegExp(_l.fileHelpPause)), findsOneWidget);
      await tester.tap(find.byKey(syncHelpAnimationKey));
      await tester.pump();
      final before = _caption(tester);
      await tester.pump(syncHelpStepDuration * 2);
      expect(_caption(tester), before);
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.bySemanticsLabel(RegExp(_l.fileHelpPlay)), findsOneWidget);
    });

    testWidgets('reduced motion: one still picture, the four steps as a numbered list, nothing runs', (tester) async {
      await _pump(tester, const SyncDiagram(thisIsPhone: false), reducedMotion: true);
      expect(find.byKey(syncHelpStillKey), findsOneWidget);
      expect(find.byKey(syncHelpCaptionKey), findsNothing);
      expect(find.byKey(syncHelpAnimationKey), findsNothing);
      for (final step in [_l.syncHelpStep1, _l.syncHelpStep2(2), _l.syncHelpStep3, _l.syncHelpStep4]) {
        expect(find.text(step), findsOneWidget);
      }
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(_l.syncHelpDiagram)), findsOneWidget);
      await tester.pump(syncHelpStepDuration);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('fits a 360 dp phone and a 1280 px desktop, moving and still', (tester) async {
      for (final (width, desk) in [(360.0, false), (1280.0, true)]) {
        for (final still in [false, true]) {
          await _pump(tester, SyncDiagram(thisIsPhone: !desk), width: width, desk: desk, reducedMotion: still);
          await tester.pump(syncHelpStepDuration ~/ 2);
          expect(tester.takeException(), isNull, reason: 'width $width still $still');
          final picture = tester.getSize(find.byType(CustomPaint).first);
          expect(picture.width, lessThanOrEqualTo(width - 40), reason: 'width $width');
          expect(picture.width, greaterThan(200), reason: 'width $width');
        }
      }
    });
  });

  group('the status panel', () {
    testWidgets('nothing linked: the empty line and Link a device', (tester) async {
      await _pump(
        tester,
        SyncStatusPanel(
          view: null,
          now: DateTime(2026, 10, 27, 12),
          serverState: (_) => SyncServerState.unknown,
          thisIsPhone: true,
          linkAction: TextButton(onPressed: () {}, child: Text(_l.devicesLink)),
        ),
      );
      expect(find.text(_l.syncHelpStatus), findsOneWidget);
      expect(find.text(_l.devicesEmpty), findsOneWidget);
      expect(find.descendant(of: find.byKey(syncHelpLinkKey), matching: find.text(_l.devicesLink)), findsOneWidget);
      expect(find.text(_l.syncHelpAnswering), findsNothing);
    });

    testWidgets('a linked device with its last notice, two servers of which one does not answer', (tester) async {
      final now = DateTime(2026, 10, 27, 12);
      await _pump(tester, SyncStatusPanel(view: _linked(now), now: now, serverState: _oneDown, thisIsPhone: true, linkAction: const SizedBox()));
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text(_l.devicesThisDevice), findsOneWidget);
      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text(_l.devicesSeenMinutes(2)), findsOneWidget);
      expect(find.text(_s1), findsOneWidget);
      expect(find.text(_s2), findsOneWidget);
      expect(find.text(_l.syncHelpAnswering), findsOneWidget);
      expect(find.text(_l.syncHelpNotAnswering), findsOneWidget);
      expect(find.text(_l.devicesEmpty), findsNothing);
      expect(find.byKey(syncHelpLinkKey), findsNothing);
      expect(find.text(_l.syncHelpPaused), findsNothing);
      // Paused, the panel says so; on the desktop theme the same panel fits a wide window.
      await _pump(tester, SyncStatusPanel(view: _linked(now, paused: true), now: now, serverState: _oneDown, thisIsPhone: false), width: 1280, desk: true);
      expect(find.text(_l.syncHelpPaused), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
