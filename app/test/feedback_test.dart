import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/app_log.dart';
import 'package:epic_wallet/src/feedback.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/feedback_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _pin = '123456';
const _password = 'correct horse';
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
    ..values['wallet.mainnet.sealed'] = 'sealed|$_pin|$_password';
  final session = FakeWalletSession();
  late final service = FakeWalletService(
    existingWallets: {'/fake/wallets/mainnet'},
    session: session,
  );
  final outlet = FakeFeedbackOutlet();
  final log = MemoryLogSink();
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
          vaultCryptoProvider.overrideWithValue(FakeVaultCrypto()),
          updatePlatformProvider.overrideWithValue(null),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          pushPlatformProvider.overrideWithValue(null),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 1, 9, 5)),
          feedbackOutletProvider.overrideWithValue(outlet),
          feedbackLogProvider.overrideWithValue(log),
          feedbackUrlProvider.overrideWithValue(url),
          feedbackPlatformProvider.overrideWithValue('android 14'),
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

  /// Settings, then Send feedback.
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
    await tap(tester, find.text('Send feedback'));
    expect(find.text('Attach diagnostic logs'), findsOneWidget);
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
  group('report', () {
    test('states the facts, redacts the message and attaches the log', () {
      final report = buildFeedbackReport(
        message: 'Restore failed with $_phrase and PIN 123456, paid $_address',
        email: ' me@example.com ',
        details: _details,
        log: 'INFO dart.unlock: PIN 654321\nWARN x: sent to $_address\n',
        at: DateTime.utc(2026, 10, 1, 8, 5),
      );
      expect(report, contains('Written: 2026-10-01T08:05:00.000Z'));
      expect(
        report,
        contains(
          'Restore failed with [words] and PIN [redacted], paid esWn9r…@epicbox.epiccash.com',
        ),
      );
      expect(report, contains('Reply to: me@example.com'));
      expect(report, contains('Version: 1.1.2 (12)'));
      expect(report, contains('Platform: android 14'));
      expect(report, contains('Network: Mainnet'));
      expect(report, contains('Node: node.btlabs.uk'));
      expect(report, contains('Epicbox server: epicbox.epiccash.com'));
      expect(report, contains('Sync: Up to date at height 3600000'));
      expect(report, contains('INFO dart.unlock: PIN [redacted]'));
      for (final secret in ['abandon', '123456', '654321', 'esWn9r2zQj5']) {
        expect(report, isNot(contains(secret)), reason: secret);
      }
    });

    test('says when no log is attached and no email was given', () {
      final report = buildFeedbackReport(
        message: 'Nice app',
        details: _details,
        at: DateTime.utc(2026, 10, 1),
      );
      expect(report, contains('Reply to: not given'));
      expect(report, contains('Diagnostic log: not attached'));
    });

    test('caps the log at 256 KB, keeping the newest whole lines', () {
      final log = StringBuffer();
      for (var i = 0; log.length < 400 * 1024; i++) {
        log.writeln('line ${i.toString().padLeft(6, '0')} ${'lorem ' * 9}');
      }
      final text = log.toString();
      final report = buildFeedbackReport(
        message: 'm',
        details: _details,
        log: text,
        at: DateTime.utc(2026),
      );
      final tail = report.substring(report.indexOf('-\nline ') + 2);
      expect(tail.length, lessThanOrEqualTo(feedbackLogBytes));
      expect(tail.startsWith('line '), isTrue);
      expect(text.endsWith(tail), isTrue);
      expect(keepLastBytes('é' * 10, 5), hasLength(lessThanOrEqualTo(3)));
    });

    test('takes https feedback URLs, and http only to this machine', () {
      expect(parseFeedbackUrl('https://feedback.example.com/in'), isNotNull);
      expect(parseFeedbackUrl('http://127.0.0.1:8765/'), isNotNull);
      expect(parseFeedbackUrl('http://10.0.2.2:8765/'), isNotNull);
      expect(parseFeedbackUrl('http://feedback.example.com/in'), isNull);
      expect(parseFeedbackUrl(''), isNull);
      expect(parseFeedbackUrl('ftp://x'), isNull);
    });

    test('posts the report as UTF-8 text and reports a refusal', () {
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

      await enter(tester, 'Your message', 'My phrase $_phrase does not work');
      await tap(tester, find.text('Preview what is sent'));
      final preview = previewText(tester);
      expect(preview, contains('[words] does not work'));
      expect(preview, contains('Network: Mainnet'));
      expect(preview, contains('Node: node.btlabs.uk'));
      expect(preview, contains('Epicbox server: epicbox.epiccash.com'));
      expect(preview, contains('Platform: android 14'));
      expect(preview, contains('dart.unlock: PIN [redacted] accepted'));
      expect(preview, contains('to esWn9r…@epicbox.epiccash.com'));
      for (final secret in ['abandon', '123456', 'esWn9r2zQj5']) {
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
      expect(find.text('Attach diagnostic logs'), findsNothing);
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

        await enter(tester, 'Your message', 'The balance looks wrong');
        await enter(tester, 'Email for a reply (optional)', 'nope');
        await tap(tester, find.text('Share or save'));
        expect(
          find.text('This does not look like an email address.'),
          findsOneWidget,
        );

        await enter(tester, 'Email for a reply (optional)', 'me@example.com');
        await tap(tester, find.text('Attach diagnostic logs'));
        await tap(tester, find.text('Share or save'));
        await tap(tester, find.text('Save to device'));
        final saved = h.outlet.saved.single.report;
        expect(saved, contains('Reply to: me@example.com'));
        expect(saved, contains('Diagnostic log: not attached'));
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
      await enter(tester, 'Your message', 'Please add dark mode');

      h.outlet.postError = FeedbackSendError(
        (l) => l.feedbackServerAnswered(503),
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Send'));
      expect(find.text('The feedback server answered 503.'), findsOneWidget);

      h.outlet.postError = null;
      await tap(tester, find.widgetWithText(FilledButton, 'Send'));
      final post = h.outlet.posted.single;
      expect(post.url.host, 'feedback.example.com');
      expect(post.report, contains('Please add dark mode'));
      expect(post.report, contains('Sync: '));
      expect(find.text('Thank you. Your feedback was sent.'), findsOneWidget);
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
      await tap(tester, find.widgetWithText(OutlinedButton, 'Send feedback'));
      expect(find.byType(FeedbackScreen), findsOneWidget);
    });
  });
}

class _RealHttp extends HttpOverrides {}

Future<void> _postsToLoopback() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  final received = <({String? type, int length, String body})>[];
  var status = HttpStatus.noContent;
  server.listen((request) async {
    received.add((
      type: request.headers.contentType?.mimeType,
      length: request.headers.contentLength,
      body: await utf8.decodeStream(request),
    ));
    request.response.statusCode = status;
    await request.response.close();
  });
  final url = Uri.parse('http://127.0.0.1:${server.port}/');
  const outlet = PlatformFeedbackOutlet();
  await outlet.post(url, 'Café report\n');
  expect(received.single.type, 'text/plain');
  // Declared, not chunked: tool/feedback_receiver.py and other simple receivers need it.
  expect(received.single.length, utf8.encode('Café report\n').length);
  expect(received.single.body, 'Café report\n');

  status = HttpStatus.serviceUnavailable;
  await expectLater(
    outlet.post(url, 'again'),
    throwsA(
      isA<FeedbackSendError>().having(
        (e) => e.message,
        'message',
        'The feedback server answered 503.',
      ),
    ),
  );
}
