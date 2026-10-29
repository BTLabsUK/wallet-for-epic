// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/feedback.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/support_clean.dart';
import 'package:epic_wallet/src/support_report.dart';
import 'package:epic_wallet/src/ui/feedback_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _pin = '123456';
const _phrase =
    'abandon ability able about above absent absorb abstract absurd abuse '
    'access accident';
const _address =
    'esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9@epicbox.epiccash.com';

const _details = FeedbackDetails(
  appVersion: '1.1.2 (12)',
  platform: 'android 14',
  network: 'Mainnet',
  node: 'node.btlabs.uk',
  relay: 'epicbox.epiccash.com',
  sync: 'Up to date at height 3600000, epicbox connected',
);

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  final store = MemorySecretStore()
    ..values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
  final session = FakeWalletSession();
  late final service = FakeWalletService(
    existingWallets: {'/fake/wallets/mainnet'},
    session: session,
  );
  final outlet = FakeFeedbackOutlet();
  MemoryLogSink log = MemoryLogSink();
  Uri? url;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          walletDirProvider.overrideWithValue(
            (chain) async => '/fake/wallets/${chain.name}',
          ),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(
            MemoryBiometricStore(available: false),
          ),
          updatePlatformProvider.overrideWithValue(null),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 1, 9, 5)),
          feedbackOutletProvider.overrideWithValue(outlet),
          feedbackLogProvider.overrideWithValue(log),
          feedbackUrlProvider.overrideWithValue(url),
          feedbackPlatformProvider.overrideWithValue('android 14'),
          feedbackCleanContextProvider.overrideWithValue(const CleanContext()),
        ],
        child: const WalletApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.enterText(find.widgetWithText(TextField, 'PIN'), _pin);
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider), isNotNull);
  }

  /// Settings, then Help & feedback, then Send feedback.
  Future<void> openFeedback(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(settingsHelpKey));
    await tap(tester, find.byKey(helpFeedbackKey));
    expect(find.text('Attach logs'), findsOneWidget);
  }
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // Lazy lists build only what is on screen.
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextField, label), text);
  await tester.pumpAndSettle();
}

/// The text of the preview screen, line by line as it shows them.
String previewText(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(ListView), matching: find.byType(Text)),
    )
    .map((t) => t.data)
    .join('\n');

void main() {
  previewLargeLog();
  group('report', () {
    test('states the facts, redacts the message and attaches the log', () {
      final report = buildFeedbackReport(
        message: 'Restore failed with $_phrase and PIN 123456, paid $_address',
        email: ' me@example.com ',
        details: _details,
        log: 'INFO dart.unlock: PIN 654321\nWARN x: sent to $_address\n',
        at: DateTime.utc(2026, 10, 1, 8, 5),
      ).text;
      expect(report, contains('Created: 2026-10-01T08:05:00.000Z'));
      expect(
        report,
        contains(
          'Restore failed with [recovery phrase removed] and PIN [redacted], paid <address-1>@epicbox.epiccash.com',
        ),
      );
      expect(report, contains('Contact: me@example.com'));
      expect(report, contains('version: 1.1.2 (12)'));
      expect(report, contains('ui: phone'));
      expect(report, contains('platform: android 14'));
      expect(report, isNot(contains('network:')), reason: 'mainnet is never named');
      expect(report, contains('node: node.btlabs.uk'));
      expect(report, contains('epicbox: epicbox.epiccash.com'));
      expect(report, contains('sync: Up to date at height 3600000'));
      expect(report, contains('== app/wfe.log =='));
      expect(report, contains('INFO dart.unlock: PIN [redacted]'));
      expect(report, contains('WARN x: sent to <address-1>@epicbox.epiccash.com'));
      for (final secret in ['abandon', '123456', '654321', 'esWn9r']) {
        expect(report, isNot(contains(secret)), reason: secret);
      }
    });

    test('names a private node by a stand-in, the same in the facts and the log', () {
      final report = buildFeedbackReport(
        message: 'Sync stuck',
        details: const FeedbackDetails(
          appVersion: '0.1.0',
          platform: 'android 14',
          network: 'Mainnet',
          node: '10.0.1.24',
          relay: 'epicbox.epiccash.com',
          sync: 'Syncing',
        ),
        log: 'WARN node: http://10.0.1.24:3413 timed out\n',
        at: DateTime.utc(2026),
      );
      expect(report.app['node'], '<ip-1>');
      expect(report.files.single.text, contains('http://<ip-1>:3413 timed out'));
    });

    test('says when no log is attached and no email was given', () {
      final report = buildFeedbackReport(
        message: 'Nice app',
        details: _details,
        at: DateTime.utc(2026, 10, 1),
      ).text;
      expect(report, contains('Contact: none'));
      expect(report, contains('Logs: none attached'));
    });

    test('caps the log at 256 KB, keeping the newest whole lines', () {
      final log = StringBuffer();
      for (var i = 0; log.length < 400 * 1024; i++) {
        log.writeln('line ${i.toString().padLeft(6, '0')} ${'lorem ' * 9}');
      }
      final text = log.toString();
      final file = buildFeedbackReport(
        message: 'm',
        details: _details,
        log: text,
        at: DateTime.utc(2026),
      ).files.single;
      expect(file.cut, isTrue);
      final tail = file.text.substring(file.text.indexOf('\n') + 1);
      expect(tail.length, lessThanOrEqualTo(feedbackLogBytes));
      expect(tail.startsWith('line '), isTrue);
      expect(text.endsWith(tail), isTrue);
    });

    test('sends to the support intake unless the build says otherwise', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(feedbackUrlProvider),
        Uri.parse('https://support.btlabs.uk/v1/report'),
      );
    });

    test('takes https feedback URLs, and http only to this machine', () {
      expect(parseFeedbackUrl('https://feedback.example.com/in'), isNotNull);
      expect(parseFeedbackUrl('http://127.0.0.1:8765/'), isNotNull);
      expect(parseFeedbackUrl('http://10.0.2.2:8765/'), isNotNull);
      expect(parseFeedbackUrl('http://feedback.example.com/in'), isNull);
      expect(parseFeedbackUrl(''), isNull);
      expect(parseFeedbackUrl('ftp://x'), isNull);
    });

    test('seals and posts the report as the GUI does, and reports a refusal', () {
      // flutter_test answers every HttpClient with 400; this test needs a real one.
      return HttpOverrides.runWithHttpOverrides(_postsToLoopback, _RealHttp());
    });

    test('checks emails loosely and names files by the minute', () {
      expect(isValidFeedbackEmail('a@b.co'), isTrue);
      expect(isValidFeedbackEmail('not an email'), isFalse);
      expect(
        feedbackFileName(DateTime(2026, 10, 1, 9, 5)),
        'epic-wallet-feedback-20261001-0905.txt',
      );
    });
  });

  group('feedback screen', () {
    testWidgets('previews exactly what is shared, with the log redacted', (
      tester,
    ) async {
      final h = _Harness();
      h.log.write(LogLevel.info, 'unlock', 'PIN 123456 accepted');
      h.log.write(LogLevel.warn, 'send', 'to $_address');
      await h.pump(tester);
      await h.openFeedback(tester);
      // Without a feedback server there is no Send, only share or save.
      expect(find.widgetWithText(FilledButton, 'Send'), findsNothing);

      await enter(tester, 'What happened', 'My phrase $_phrase does not work');
      await tap(tester, find.text('What is sent'));
      final preview = previewText(tester);
      expect(preview, contains('[recovery phrase removed] does not work'));
      expect(preview, isNot(contains('network:')));
      expect(preview, contains('node: node.btlabs.uk'));
      expect(preview, contains('epicbox: epicbox.epiccash.com'));
      expect(preview, contains('platform: android 14'));
      expect(preview, contains('dart.unlock: PIN [redacted] accepted'));
      expect(preview, contains('to <address-1>@epicbox.epiccash.com'));
      for (final secret in ['abandon', '123456', 'esWn9r']) {
        expect(preview, isNot(contains(secret)), reason: secret);
      }
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tap(tester, find.text('Share or save'));
      await tap(tester, find.text('Share'));
      expect(h.outlet.shared, hasLength(1));
      final shared = h.outlet.shared.single;
      expect(shared.name, 'epic-wallet-feedback-20261001-0905.txt');
      // The shared file is the previewed text, line for line.
      expect(shared.report.trimRight(), preview.trimRight());
      expect(find.text('Thank you for your feedback.'), findsOneWidget);
      expect(find.text('Attach logs'), findsNothing);
    });

    testWidgets(
      'asks for a message, checks the email, and can leave logs out',
      (tester) async {
        final h = _Harness();
        h.log.write(LogLevel.info, 'app', 'start');
        await h.pump(tester);
        await h.openFeedback(tester);
        await tap(tester, find.text('Share or save'));
        expect(
          find.text('Write a few words about what happened.'),
          findsOneWidget,
        );
        expect(h.outlet.shared, isEmpty);

        await enter(tester, 'What happened', 'The balance looks wrong');
        await enter(tester, 'Contact (optional)', 'nope');
        await tap(tester, find.text('Share or save'));
        expect(
          find.text('This does not look like an email address.'),
          findsOneWidget,
        );

        await enter(tester, 'Contact (optional)', 'me@example.com');
        await tap(tester, find.text('Attach logs'));
        await tap(tester, find.text('Share or save'));
        await tap(tester, find.text('Save to device'));
        final saved = h.outlet.saved.single.report;
        expect(saved, contains('Contact: me@example.com'));
        expect(saved, contains('Logs: none attached'));
        expect(saved, isNot(contains('dart.app: start')));
        expect(
          find.text('Saved epic-wallet-feedback-20261001-0905.txt'),
          findsOneWidget,
        );
      },
    );

    testWidgets('sends to the feedback server when the build names one', (
      tester,
    ) async {
      final h = _Harness()..url = Uri.parse('https://feedback.example.com/in');
      await h.pump(tester);
      await h.openFeedback(tester);
      await enter(tester, 'What happened', 'Please add dark mode');

      h.outlet.postError = FeedbackSendError(
        (l) => l.feedbackServerAnswered(503),
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Send'));
      expect(find.text('The feedback server answered 503.'), findsOneWidget);

      h.outlet.postError = null;
      await tap(tester, find.widgetWithText(FilledButton, 'Send'));
      final post = h.outlet.posted.single;
      expect(post.url.host, 'feedback.example.com');
      expect(post.report.description, 'Please add dark mode');
      expect(post.report.app['sync'], isNotEmpty);
      expect(find.text('Thank you. Your feedback was sent.'), findsOneWidget);
    });

    testWidgets('Offline: Send waits with the reason, sharing the report does not', (
      tester,
    ) async {
      final h = _Harness()..url = Uri.parse('https://feedback.example.com/in');
      h.store.values['app.advanced_prefs'] = '|offline';
      await h.pump(tester);
      await h.openFeedback(tester);
      await enter(tester, 'What happened', 'Please add dark mode');
      expect(find.text('Offline is on in Advanced.'), findsOneWidget);
      final send = find.widgetWithText(FilledButton, 'Send');
      await tester.ensureVisible(send);
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      // Saving or sharing the report needs no network.
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Share or save'),
            )
            .onPressed,
        isNotNull,
      );
      expect(h.outlet.posted, isEmpty);
    });

    testWidgets('help links to it', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(OutlinedButton, 'Report a problem'));
      expect(find.byType(FeedbackScreen), findsOneWidget);
    });
  });
}

class _RealHttp extends HttpOverrides {}

Future<void> _postsToLoopback() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  final received = <({String? type, String body})>[];
  var status = HttpStatus.ok;
  server.listen((request) async {
    received.add((
      type: request.headers.contentType?.mimeType,
      body: await utf8.decodeStream(request),
    ));
    request.response.statusCode = status;
    request.response.write('{"ok":true,"id":"ab12cd34"}');
    await request.response.close();
  });
  final url = Uri.parse('http://127.0.0.1:${server.port}/v1/report');
  const outlet = PlatformFeedbackOutlet();
  final report = buildFeedbackReport(
    message: 'Café report',
    details: _details,
    at: DateTime.utc(2026),
  );
  expect(await outlet.post(url, report), 'ab12cd34');
  expect(received.single.type, 'application/json');
  final body = jsonDecode(received.single.body) as Map<String, dynamic>;
  // The intake takes exactly these keys.
  expect(body.keys.toList()..sort(), ['app', 'bundle', 'v']);
  expect(body['v'], 2);
  expect(body['app'], 'wfe-1.1.2');
  final bundle = base64.decode(body['bundle'] as String);
  expect(ascii.decode(bundle.sublist(0, 8)), 'EPICSUP1');
  expect(
    bundle.sublist(8, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    supportKeyId,
  );
  // Sealed: the message is not readable on the wire.
  expect(received.single.body, isNot(contains('Caf')));

  status = HttpStatus.serviceUnavailable;
  await expectLater(
    outlet.post(url, report),
    throwsA(
      isA<FeedbackSendError>().having(
        (e) => e.message,
        'message',
        'The feedback server answered 503.',
      ),
    ),
  );
}

// The preview must open with the whole 256 KB log, at once, and show its first and last
// lines; it never silently fails (the web had no dart:io Platform, and a throw inside the
// report build left nothing on screen).
void previewLargeLog() {
  group('feedback preview, large log', () {
    testWidgets('opens with a 256 KB log and shows its last line', (tester) async {
      final h = _Harness();
      h.log = MemoryLogSink(capacity: 100000);
      var bytes = 0;
      var i = 0;
      while (bytes < 300 * 1024) {
        final body = 'line $i tip height ${2500000 + i} from node.btlabs.uk, '
            'send to $_address, slate ${'ab' * 32} posted, balance spendable=${i * 7}';
        h.log.write(LogLevel.values[i % 3], 'dart.t${i % 5}', body);
        bytes += body.length + 40;
        i++;
      }
      await h.pump(tester);
      await h.openFeedback(tester);
      await enter(tester, 'What happened', 'The preview with a big log');
      // No wall-clock bound: under a loaded machine it says nothing about the screen.
      await tap(tester, find.text('What is sent'));
      expect(find.byKey(feedbackPreviewListKey), findsOneWidget, reason: 'the preview opened');
      expect(find.textContaining('The preview with a big log'), findsOneWidget);
      expect(find.textContaining('== app/wfe.log =='), findsOneWidget);
      final list = tester.widget<ListView>(find.byKey(feedbackPreviewListKey));
      final count = list.childrenDelegate.estimatedChildCount!;
      expect(count, greaterThan(500), reason: 'one row per line of the 256 KB tail');
      // The end of the log is reachable and is the newest line.
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: find.byKey(feedbackPreviewListKey), matching: find.byType(Scrollable)),
      );
      // The extent is an estimate until the rows are built, so the jump repeats until it
      // lands on the end (as a reader's scrolling does).
      for (var j = 0; j < 100; j++) {
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        if (scroll.position.pixels >= scroll.position.maxScrollExtent - 0.5) break;
      }
      expect(find.textContaining('line ${i - 1} tip height'), findsOneWidget);
      expect(find.textContaining('<address-1>@epicbox.epiccash.com'), findsWidgets);
      expect(find.textContaining('esWn9r'), findsNothing);
    });

    testWidgets('a report that cannot be built shows the error under the button', (tester) async {
      final h = _Harness();
      h.log = _ThrowingLog();
      await h.pump(tester);
      await h.openFeedback(tester);
      await enter(tester, 'What happened', 'hello');
      await tap(tester, find.text('What is sent'));
      // The log tail failure is caught and written into the report, so the preview opens.
      expect(find.byKey(feedbackPreviewListKey), findsOneWidget);
      expect(find.textContaining('The log could not be read'), findsOneWidget);
    });
  });
}

class _ThrowingLog extends MemoryLogSink {
  @override
  Future<String> tail(int maxBytes) async => throw StateError('no log here');
}
