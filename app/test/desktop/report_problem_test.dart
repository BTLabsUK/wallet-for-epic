// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/desktop/screens/settings/report_problem.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_help.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/feedback.dart';
import 'package:epic_wallet/src/log.dart';
import 'package:epic_wallet/src/support_clean.dart';
import 'package:epic_wallet/src/ui/feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _phrase = 'abandon ability able about above absent absorb abstract absurd abuse access accident';
const _address = 'esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9';

class _Harness {
  final outlet = FakeFeedbackOutlet();
  MemoryLogSink log = MemoryLogSink();

  /// LEPIC's log ring; null is none, as in a test run, and the log's tail goes instead.
  List<LogRingFile>? ring;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, {Widget? home, double height = 900}) async {
    tester.view.physicalSize = Size(1280, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(overrides: [
      feedbackOutletProvider.overrideWithValue(outlet),
      feedbackLogProvider.overrideWithValue(log),
      feedbackRingProvider.overrideWithValue(() async => ring),
      feedbackUrlProvider.overrideWithValue(Uri.parse('https://support.example.com/v1/report')),
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

void main() {
  testWidgets('Help opens Report a problem', (tester) async {
    final h = _Harness();
    await h.pump(tester, home: const SettingsHelpScreen());
    final button = find.widgetWithText(EButton, 'Report a problem');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(ReportProblemDialog), findsOneWidget);
  });

  testWidgets('asks for a description, and the busy state ends when sending fails', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await send(tester);
    expect(find.text('Describe what happened.'), findsOneWidget);
    expect(h.outlet.posted, isEmpty);

    await describe(tester, 'The balance looks wrong');
    h.outlet.postError = FeedbackSendError((l) => l.feedbackServerUnreachable);
    await send(tester);
    expect(find.text('Not sent'), findsOneWidget);
    expect(find.text('Could not reach the feedback server.'), findsOneWidget);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Send')).busy, isFalse);
    expect(tester.widget<EButton>(find.widgetWithText(EButton, 'Cancel')).onPressed, isNotNull);

    h.outlet.postError = null;
    await send(tester);
    expect(find.text('Report sent'), findsOneWidget);
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
    await tester.enterText(find.descendant(of: find.byType(ReportProblemDialog), matching: find.byType(TextField)).at(1), 'me@example.com');
    await tester.pump();
    await tester.tap(find.text('What is sent'));
    await settle(tester);
    final preview = previewText(tester);
    // The rows on screen are the text's first lines.
    expect(find.text(preview.split('\n').first), findsOneWidget);
    expect(preview, contains('Sending to <address-1> fails'));
    expect(preview, contains('Contact: me@example.com'));
    expect(preview, contains('== app/wfe.log =='));
    expect(preview, contains('[recovery phrase removed]'));
    expect(preview, contains('to <address-1>@box.epic.invalid via <ip-1>:3413'));
    for (final secret in ['abandon', 'esWn9r', '203.0.113.7']) {
      expect(preview, isNot(contains(secret)), reason: secret);
    }

    // Without logs, the preview says so.
    await tester.tap(find.text('Attach logs (recommended)'));
    await settle(tester);
    expect(previewText(tester), contains('Logs: none attached'));
    await tester.tap(find.text('Attach logs (recommended)'));
    await settle(tester);

    await send(tester);
    expect(h.outlet.posted.single.report.text.trimRight(), preview.trimRight());
  });

  testWidgets('Include full details is off by default; ticked, the report keeps the addresses', (tester) async {
    final h = _Harness();
    h.log.record(LogLevel.warn, 'dart.send', 'to $_address@box.epic.invalid via 203.0.113.7:3413');
    await h.pump(tester);
    expect(find.text('Include full details'), findsOneWidget);
    // No small print under the tick: what it changes sits behind the info icon beside it.
    expect(find.byKey(const ValueKey('report-full-details-info')), findsOneWidget);
    expect(find.textContaining('Seeds, keys and passwords never'), findsNothing);
    await tester.tap(find.text('What is sent'));
    await settle(tester);
    expect(previewText(tester), isNot(contains(_address)));
    expect(find.textContaining('· Full details'), findsNothing);

    await tester.tap(find.text('Include full details'));
    await settle(tester);
    expect(find.textContaining('Seeds, keys and passwords never'), findsNothing, reason: 'ticked adds no text either');
    expect(find.textContaining('· Full details'), findsOneWidget);
    final preview = previewText(tester);
    expect(preview, contains('log details: full'));
    expect(preview, contains('to $_address@box.epic.invalid'));
    expect(preview, isNot(contains('203.0.113.7')));

    // Attach logs off takes the tick with it.
    await tester.tap(find.text('Attach logs (recommended)'));
    await settle(tester);
    expect(find.text('Include full details'), findsNothing);
    expect(find.byKey(const ValueKey('report-full-details-info')), findsNothing);
  });

  testWidgets('sends the log ring as it is, oldest file first', (tester) async {
    const older = '2026-10-01T08:00:00.000Z INFO dart: unlock tag=unlock\n';
    const newer = '2026-10-01T08:05:00.000Z WARN lepic_wallet::send: slate posted relay=box.epic.invalid\n';
    final h = _Harness()..ring = [(name: 'lepic.1.log', text: older), (name: 'lepic.0.log', text: newer)];
    h.log.record(LogLevel.warn, 'dart.send', 'to $_address@box.epic.invalid');
    await h.pump(tester);
    await tester.tap(find.text('What is sent'));
    await settle(tester);
    expect(find.text('Report text · lepic.0.log (all, 1 KB) · lepic.1.log (all, 1 KB)'), findsOneWidget);
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
    await tester.tap(find.text('What is sent'));
    await tester.tap(find.text('Include full details'));
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
    await tester.tap(find.text('What is sent'));
    await settle(tester);
    expect(find.text('Report text · wfe.log (all, 100 KB) · wfe.log.1 (last 156 KB of 1.0 MB)'), findsOneWidget);
    expect(previewText(tester), contains('log level: normal'));
  });

  testWidgets('Save to file writes the same cleaned report as the preview', (tester) async {
    final h = _Harness();
    h.log.record(LogLevel.info, 'dart.restore', 'words $_phrase');
    await h.pump(tester);
    await describe(tester, 'Sending to $_address fails');
    await tester.tap(find.text('What is sent'));
    await settle(tester);
    final preview = previewText(tester);
    await tester.ensureVisible(find.widgetWithText(EButton, 'Save to file'));
    await tester.tap(find.widgetWithText(EButton, 'Save to file'));
    await settle(tester);
    final saved = h.outlet.saved.single;
    expect(saved.name, startsWith('epic-wallet-feedback-'));
    expect(saved.report.trimRight(), preview.trimRight());
    expect(saved.report, isNot(contains('abandon')));
    expect(find.text('Saved. Cleaned of secrets, not encrypted.'), findsOneWidget);
    expect(h.outlet.posted, isEmpty);
  });

  testWidgets('Esc closes the dialog with the focus on What is sent', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.text('What is sent'));
    await settle(tester);
    Focus.of(tester.element(find.text('What is sent'))).requestFocus();
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
    await tester.tap(find.text('What is sent'));
    await settle(tester);
    final scroll = find.descendant(of: find.byType(EDialog), matching: find.byType(Scrollable)).first;
    expect(tester.state<ScrollableState>(scroll).position.maxScrollExtent, 0);
    expect(tester.getTopLeft(find.text('Report a problem')).dy, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ReportProblemDialog), findsNothing);
  });
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
