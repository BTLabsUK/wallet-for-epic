// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/last_session_offer.dart';
import 'package:epic_wallet/src/desktop/screens/settings/report_problem.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/feedback.dart';
import 'package:epic_wallet/src/last_session.dart';
import 'package:epic_wallet/src/log.dart';
import 'package:epic_wallet/src/support_clean.dart';
import 'package:epic_wallet/src/support_report.dart';
import 'package:epic_wallet/src/ui/feedback_screen.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _phrase = 'abandon ability able about above absent absorb abstract absurd abuse access accident';
const _address = 'esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9';

class _Harness {
  FakeFeedbackOutlet outlet = FakeFeedbackOutlet();
  MemoryLogSink log = MemoryLogSink();

  /// LEPIC's log ring; null is none, as in a test run, and the log's tail goes instead.
  List<LogRingFile>? ring;
  LastSessionSource? lastSession;
  late ProviderContainer container;

  /// The support intake; null is a build without one.
  Uri? url = Uri.parse('https://support.example.com/v1/report');

  Future<void> pump(WidgetTester tester, {Widget? home, double width = 1280, double height = 900}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(overrides: [
      feedbackOutletProvider.overrideWithValue(outlet),
      feedbackLogProvider.overrideWithValue(log),
      feedbackRingProvider.overrideWithValue(() async => ring),
      lastSessionProvider.overrideWithValue(lastSession),
      feedbackUrlProvider.overrideWithValue(url),
      feedbackPlatformProvider.overrideWithValue('linux test'),
      feedbackCleanContextProvider.overrideWithValue(const CleanContext()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildDeskTheme(Brightness.dark),
        home: Scaffold(body: home ?? Builder(builder: (c) => TextButton(onPressed: () => showReportProblemDialog(c), child: const Text('open')))),
      ),
    ));
    if (home == null) {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }
  }
}

Future<void> describe(WidgetTester tester, String text) async {
  await tester.enterText(find.descendant(of: find.byType(ReportProblemDialog), matching: find.byType(TextField)).first, text);
  await tester.pump();
}

Future<void> send(WidgetTester tester) async {
  await tester.ensureVisible(find.widgetWithText(EButton, 'Send'));
  await tester.tap(find.widgetWithText(EButton, 'Send'));
  await settle(tester);
}

/// Past the preview's pause, then the report built on its isolate.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
  await tester.pumpAndSettle();
}

/// The text the preview shows, all of it (the list builds only the rows on screen).
String previewText(WidgetTester tester) => tester.widget<ReportPreview>(find.byType(ReportPreview)).text!;

class _KeptSession implements LastSessionSource {
  _KeptSession(this.kept);

  final LastSessionLog kept;
  int offers = 0;

  @override
  bool get due => offers == 0;

  @override
  void offered() => offers++;

  @override
  Future<LastSessionLog?> read() async => kept;

  @override
  void clean() {}
}

void main() {
  testWidgets('a crashed last session: the toast once, its Send opens the report with that log', (tester) async {
    final kept = _KeptSession(const LastSessionLog(end: LastSessionEnd.closed, cause: 'not closed', version: '26.10.26', log: 'INFO dart.send: to $_address\n'));
    final h = _Harness()
      ..lastSession = kept
      ..log = (MemoryLogSink()..write(LogLevel.info, 'app', 'this session only'));
    await h.pump(
      tester,
      home: Consumer(builder: (c, ref, _) => TextButton(onPressed: () => offerDeskLastSessionReport(c, ref), child: const Text('offer'))),
    );
    await tester.tap(find.text('offer'));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskLastSessionClosed), findsOneWidget);
    expect(kept.offers, 1);
    // Asked again (the next unlock): nothing more.
    await tester.tap(find.text('offer'));
    await tester.pumpAndSettle();
    expect(kept.offers, 1);
    await tester.tap(find.descendant(of: find.byType(SnackBar), matching: find.text('Send')));
    await settle(tester);
    expect(find.byType(ReportProblemDialog), findsOneWidget);
    expect(find.text(_l.deskLastSessionReportClosed), findsOneWidget);
    expect(find.textContaining(_l.deskLastSessionAttached), findsOneWidget);
    await send(tester);
    final report = h.outlet.posted.single.report;
    expect(report.description, 'The app closed unexpectedly.');
    expect(report.app['last session'], 'not closed');
    final log = report.files.single;
    expect(log.name, 'app/last-session/wfe.log');
    expect(log.text, contains('dart.send: to '));
    expect(log.text, isNot(contains(_address)));
    expect(log.text, isNot(contains('this session only')));
  });

  testWidgets('Help opens Report a problem', (tester) async {
    final h = _Harness();
    await h.pump(tester, home: const SettingsHelpScreen());
    final button = find.widgetWithText(EButton, _l.deskSetHelpReportButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(ReportProblemDialog), findsOneWidget);
  });

  testWidgets('asks for a description, and the busy state ends when sending fails', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await send(tester);
    expect(find.text(_l.deskSetReportDescribe), findsOneWidget);
    expect(h.outlet.posted, isEmpty);

    await describe(tester, 'The balance looks wrong');
    h.outlet.postError = FeedbackSendError((l) => l.feedbackServerUnreachable);
    await send(tester);
    expect(find.text(_l.deskSetReportNotSentTitle), findsOneWidget);
    expect(find.text(_l.feedbackServerUnreachable), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Send')).busy, isFalse);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.commonCancel)).onPressed, isNotNull);

    h.outlet.postError = null;
    await send(tester);
    expect(find.text(_l.deskSetReportSent), findsOneWidget);
    expect(find.text('The report arrived. Its reference is ab12cd34.'), findsOneWidget);
    expect(h.outlet.posted.single.report.description, 'The balance looks wrong');
    expect(h.outlet.posted.single.report.app['ui'], 'desktop');
  });

  testWidgets('the preview is the cleaned report, exactly as it is sent', (tester) async {
    final h = _Harness();
    h.log.record(LogLevel.info, 'dart.restore', 'words $_phrase');
    h.log.record(LogLevel.warn, 'dart.send', 'to $_address@box.epic.invalid via 203.0.113.7:3413');
    await h.pump(tester);
    await describe(tester, 'Sending to $_address fails');
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    final preview = previewText(tester);
    // The rows on screen are the text's first lines.
    expect(find.text(preview.split('\n').first), findsOneWidget);
    expect(preview, contains('Sending to <address-1> fails'));
    expect(preview, isNot(contains('Contact:')));
    expect(preview, contains('== app/wfe.log =='));
    expect(preview, contains('[recovery phrase removed]'));
    expect(preview, contains('to <address-1>@box.epic.invalid via <ip-1>:3413'));
    for (final secret in ['abandon', 'esWn9r', '203.0.113.7']) {
      expect(preview, isNot(contains(secret)), reason: secret);
    }

    // Without logs, the preview says so.
    await tester.tap(find.text(_l.deskSetReportAttach));
    await settle(tester);
    expect(previewText(tester), contains('Logs: none attached'));
    await tester.tap(find.text(_l.deskSetReportAttach));
    await settle(tester);

    await send(tester);
    expect(h.outlet.posted.single.report.text.trimRight(), preview.trimRight());
  });

  testWidgets('Include full details is off by default; ticked, the report keeps the addresses', (tester) async {
    final h = _Harness();
    h.log.record(LogLevel.warn, 'dart.send', 'to $_address@box.epic.invalid via 203.0.113.7:3413');
    await h.pump(tester);
    expect(find.text(_l.deskSetReportFullDetails), findsOneWidget);
    // No small print under the tick: what it changes sits behind the info icon beside it.
    expect(find.byKey(const ValueKey('report-full-details-info')), findsOneWidget);
    expect(find.textContaining('Seeds, keys and passwords never'), findsNothing);
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    expect(previewText(tester), isNot(contains(_address)));
    expect(find.textContaining('· Full details'), findsNothing);

    await tester.tap(find.text(_l.deskSetReportFullDetails));
    await settle(tester);
    expect(find.textContaining('Seeds, keys and passwords never'), findsNothing, reason: 'ticked adds no text either');
    expect(find.textContaining('· Full details'), findsOneWidget);
    final preview = previewText(tester);
    expect(preview, contains('log details: full'));
    expect(preview, contains('to $_address@box.epic.invalid'));
    expect(preview, isNot(contains('203.0.113.7')));

    // Attach logs off takes the tick with it.
    await tester.tap(find.text(_l.deskSetReportAttach));
    await settle(tester);
    expect(find.text(_l.deskSetReportFullDetails), findsNothing);
    expect(find.byKey(const ValueKey('report-full-details-info')), findsNothing);
  });

  testWidgets('sends the log ring as it is, oldest file first', (tester) async {
    const older = '2026-10-01T08:00:00.000Z INFO dart: unlock tag=unlock\n';
    const newer = '2026-10-01T08:05:00.000Z WARN lepic_wallet::send: slate posted relay=box.epic.invalid\n';
    final h = _Harness()..ring = [(name: 'lepic.1.log', text: older), (name: 'lepic.0.log', text: newer)];
    h.log.record(LogLevel.warn, 'dart.send', 'to $_address@box.epic.invalid');
    await h.pump(tester);
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    expect(find.text('Report text\u00A0· lepic.0.log (all, 1 KB)\u00A0· lepic.1.log (all, 1 KB)'), findsOneWidget);
    var preview = previewText(tester);
    expect(preview, contains('== app/lepic.1.log ==\n$older\n== app/lepic.0.log ==\n$newer'));
    expect(preview, isNot(contains('app/wfe.log')));

    await describe(tester, 'Sync stuck');
    await send(tester);
    final files = h.outlet.posted.single.report.files;
    expect([for (final f in files) f.name], ['app/lepic.1.log', 'app/lepic.0.log']);
    expect([for (final f in files) f.text], [older, newer]);
  });

  testWidgets('Include full details sends the log rather than the ring', (tester) async {
    final h = _Harness()..ring = [(name: 'lepic.0.log', text: '2026-10-01T08:00:00.000Z INFO dart: unlock tag=unlock\n')];
    h.log.record(LogLevel.warn, 'dart.send', 'to $_address@box.epic.invalid');
    await h.pump(tester);
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await tester.tap(find.text(_l.deskSetReportFullDetails));
    await settle(tester);
    expect(find.textContaining('lepic.0.log'), findsNothing);
    final preview = previewText(tester);
    expect(preview, contains('== app/wfe.log =='));
    expect(preview, contains('log details: full'));
    expect(preview, contains('to $_address@box.epic.invalid'));
    expect(preview, isNot(contains('lepic.0.log')));
  });

  testWidgets('What is sent names each log file and how much of it goes', (tester) async {
    final h = _Harness();
    h.log = _FilesLog([const LogFileInfo('wfe.log', 100 * 1024), const LogFileInfo('wfe.log.1', 1024 * 1024)]);
    await h.pump(tester);
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    expect(find.text('Report text\u00A0· wfe.log (all, 100 KB)\u00A0· wfe.log.1 (last 156 KB of 1.0 MB)'), findsOneWidget);
    expect(previewText(tester), contains('log level: normal'));
  });

  testWidgets('Save to file writes the same cleaned report as the preview', (tester) async {
    final h = _Harness();
    h.log.record(LogLevel.info, 'dart.restore', 'words $_phrase');
    await h.pump(tester);
    await describe(tester, 'Sending to $_address fails');
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    final preview = previewText(tester);
    await tester.ensureVisible(find.widgetWithText(EButton, _l.deskSetReportSaveToFile));
    await tester.tap(find.widgetWithText(EButton, _l.deskSetReportSaveToFile));
    await settle(tester);
    final saved = h.outlet.saved.single;
    expect(saved.name, startsWith('epic-wallet-feedback-'));
    expect(saved.report.trimRight(), preview.trimRight());
    expect(saved.report, isNot(contains('abandon')));
    expect(find.text(_l.deskSetReportSaved), findsOneWidget);
    expect(h.outlet.posted, isEmpty);
  });

  testWidgets('Esc closes the dialog with the focus on What is sent', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    Focus.of(tester.element(find.text(_l.deskSetReportSentWhat))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ReportProblemDialog), findsNothing);
  });

  testWidgets('Esc closes the dialog after the focus was lost (the system Save dialog took it)', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ReportProblemDialog), findsNothing);
  });

  testWidgets('opened in full, the dialog fits an 800 px window; Esc closes it', (tester) async {
    await tester.runAsync(_loadFonts);
    final h = _Harness();
    await h.pump(tester, height: 800);
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    final scroll = find.descendant(of: find.byType(EDialog), matching: find.byType(Scrollable)).first;
    expect(tester.state<ScrollableState>(scroll).position.maxScrollExtent, 0);
    expect(tester.getTopLeft(find.text(_l.deskSetReportTitle)).dy, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ReportProblemDialog), findsNothing);
  });

  // The smallest desktop window (window_placement.dart's deskWindowMinSize) at a large text
  // size, as a Mac tester had it: Send in view and taken, the body scrolling behind it.
  testWidgets('at the smallest window and a 1.2 text scale, Send is in view and sends', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = _Harness();
    await h.pump(tester, width: 800, height: 700);
    await tester.tap(find.text(_l.deskSetReportSentWhat));
    await settle(tester);
    await describe(tester, 'The balance looks wrong');
    final view = Offset.zero & const Size(800, 700);
    final sendButton = find.widgetWithText(EButton, 'Send');
    expect(view.contains(tester.getRect(sendButton).topLeft) && view.contains(tester.getRect(sendButton).bottomRight), isTrue);
    expect(tester.widget<EButton>(sendButton).onPressed, isNotNull);
    await tester.tap(sendButton);
    await settle(tester);
    expect(find.text(_l.deskSetReportSent), findsOneWidget);
  });

  testWidgets('when it cannot send, Send still shows and the reason stands beside it', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = _Harness()..url = null;
    await h.pump(tester, width: 800, height: 700);
    final sendButton = find.widgetWithText(EButton, 'Send');
    expect(sendButton, findsOneWidget);
    expect(tester.widget<EButton>(sendButton).onPressed, isNull);
    final reason = find.text(_l.deskSetReportOff);
    expect(reason, findsOneWidget);
    // Pinned with the buttons, not at the foot of the scrolling body.
    final body = find.descendant(of: find.byType(EDialog), matching: find.byType(SingleChildScrollView)).last;
    expect(find.descendant(of: body, matching: reason), findsNothing);
    final view = Offset.zero & const Size(800, 700);
    expect(view.contains(tester.getRect(reason).topLeft) && view.contains(tester.getRect(reason).bottomRight), isTrue);
  });

  testWidgets('a send that never answers ends in Not sent', (tester) async {
    final h = _Harness()..outlet = _SilentOutlet();
    await h.pump(tester);
    await describe(tester, 'The balance looks wrong');
    // Not settled: the spinner would run the clock past the deadline.
    await tester.tap(find.widgetWithText(EButton, 'Send'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await tester.pump();
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Send')).busy, isTrue);
    await tester.pump(feedbackSendDeadline + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(_l.deskSetReportNotSentTitle), findsOneWidget);
    expect(find.text(_l.feedbackServerNoAnswer), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Send')).busy, isFalse);
  });
}

/// An outlet whose post never answers.
class _SilentOutlet extends FakeFeedbackOutlet {
  @override
  Future<String> post(Uri url, SupportReport report) => Completer<String>().future;
}

/// A memory log that reports files, as the file log does.
class _FilesLog extends MemoryLogSink {
  _FilesLog(this.list);

  final List<LogFileInfo> list;

  @override
  Future<List<LogFileInfo>> files() async => list;
}

/// The app's fonts, so text wraps as it does in the app (the test font is wider).
Future<void> _loadFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  for (final (family, file) in [('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'), ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf')]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
}
