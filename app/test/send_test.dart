import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/errors.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/centered_body.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid address for [FakeWalletService.validateEpicboxAddress].
final String _bob = '${'b' * 52}@epicbox.epiccash.com';
final String _carol = '${'c' * 52}@epicbox.epicnet.us';

_GatedSession _funded() => _GatedSession(
  summary: WalletSummary(
    lastConfirmedHeight: BigInt.from(2499990),
    minimumConfirmations: BigInt.from(10),
    total: _epic(50),
    spendable: _epic(40),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: true,
  ),
);

class _FixedPrice implements PriceSource {
  const _FixedPrice(this.value);

  final double? value;

  @override
  Future<double?> price(String currency) async => value;
}

/// Starts with [session] already unlocked.
class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

/// The fake, with calls that can be held open and counted.
class _GatedSession extends FakeWalletSession {
  _GatedSession({required WalletSummary super.summary});

  /// When set, fee estimates and sends wait for it.
  Completer<void>? estimateGate;
  Completer<void>? sendGate;
  int estimateCalls = 0;
  int summaryCalls = 0;

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) async {
    estimateCalls++;
    await estimateGate?.future;
    return super.estimateFee(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
    );
  }

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
  }) async {
    await sendGate?.future;
    return super.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
    );
  }

  /// When set, HTTP sends and finishes return a finished send the network has not taken.
  bool notPosted = false;

  TxEntry _notPosted(BigInt amount) => fakeTx(
    id: 7,
    slateId: 'stuck',
    kind: TxKind.sent,
    status: TxStatus.awaitingConfirmation,
    amountDebited: amount + fee,
    fee: fee,
    numInputs: 1,
    repostable: true,
    statusDetail: 'The node did not answer.',
  );

  @override
  Future<TxEntry> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
  }) async {
    final tx = await super.sendHttp(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      url: url,
    );
    return notPosted ? _notPosted(amount) : tx;
  }

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) async {
    final tx = await super.finalizeAndPost(slateJson: slateJson);
    return notPosted ? _notPosted(_epic(1.5)) : tx;
  }

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) {
    summaryCalls++;
    return super.summary(
      refresh: refresh,
      minimumConfirmations: minimumConfirmations,
    );
  }
}

/// A stand-in for home: it watches the balance and opens Send.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendable = ref.watch(homeProvider).value?.summary.spendable;
    return Scaffold(
      body: Column(
        children: [
          Text('Host ${spendable ?? '-'}'),
          TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const SendScreen()),
            ),
            child: const Text('Open send'),
          ),
        ],
      ),
    );
  }
}

class _Harness {
  _Harness({this.price, bool scanSupported = true})
    : scanner = FakeQrScanner(supported: scanSupported);

  final session = _funded();
  final service = FakeWalletService();
  final files = FakeSlateFiles();
  final FakeQrScanner scanner;
  final double? price;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // A controlled scope, so the price refresh timer ends with the widget tree.
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          slateFilesProvider.overrideWithValue(files),
          qrScannerProvider.overrideWithValue(scanner),
          priceSourceProvider.overrideWithValue(_FixedPrice(price)),
          sessionProvider.overrideWith(() => _OpenSession(session)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void connectListener() => session.listenerEvents.add(
    const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // Screens are lazy lists: scroll until the target is built.
  if (finder.evaluate().isEmpty) {
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
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  // Past the fee estimate's debounce.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Slate files whose trips out of the app last until the test ends them, as a share sheet or
/// file picker stays open while the user is in another app.
class _GatedFiles extends FakeSlateFiles {
  Completer<void>? gate;

  Future<void> _wait() async {
    final g = Completer<void>();
    gate = g;
    await g.future;
  }

  @override
  Future<bool> save({
    required String name,
    required String json,
    required String dialogTitle,
  }) async {
    await _wait();
    return super.save(name: name, json: json, dialogTitle: dialogTitle);
  }

  @override
  Future<bool> share({required String name, required String json}) async {
    await _wait();
    return super.share(name: name, json: json);
  }

  @override
  Future<SlateFile?> pick({required String dialogTitle}) async {
    await _wait();
    return super.pick(dialogTitle: dialogTitle);
  }

  @override
  Future<void> shareText(String text) async {
    await _wait();
    await super.shareText(text);
  }
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

/// The whole app on a funded mainnet wallet with a PIN, auto-lock "Immediately", and a clock
/// the test moves.
class _AppHarness {
  _AppHarness() {
    store.values['wallet.mainnet.sealed'] = 'sealed|$_pin|$_password';
    store.values['app.auto_lock'] = '0';
    service = FakeWalletService(
      existingWallets: {'/fake/wallets/mainnet'},
      session: session,
    );
  }

  static const _pin = '123456';
  static const _password = 'correct horse';

  final store = MemorySecretStore();
  final session = _funded();
  final files = _GatedFiles();
  late final FakeWalletService service;
  DateTime now = DateTime(2026, 9, 30, 12);
  late ProviderContainer container;

  Future<void> pumpUnlocked(WidgetTester tester) async {
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
          slateFilesProvider.overrideWithValue(files),
          priceSourceProvider.overrideWithValue(const _FixedPrice(null)),
          clockProvider.overrideWithValue(() => now),
        ],
        child: const WalletApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    // Home keeps refresh timers; unmounting cancels them.
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.enterText(find.widgetWithText(TextField, 'PIN'), _pin);
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider), isNotNull);
  }

  Future<void> open(WidgetTester tester, Widget screen) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => screen)));
    await tester.pumpAndSettle();
  }

  bool get locked => container.read(sessionProvider) == null;

  /// Leaves the app for [away] and comes back, the way a phone moves through the states.
  Future<void> awayAndBack(WidgetTester tester, Duration away) async {
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    now = now.add(away);
    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
  }

  /// Ends the trip out of the app that is waiting.
  Future<void> finishTrip(WidgetTester tester) async {
    files.gate!.complete();
    await tester.pumpAndSettle();
  }
}

void main() {
  group('amount text', () {
    String n(String text, {String unit = 'epic'}) =>
        normalizeAmountText(text, unit: unit);

    test('decimal comma, spaces, apostrophes and thousands separators', () {
      expect(n('1,5'), '1.5');
      expect(n('0,125'), '0.125');
      expect(n(' 1 234,56 '), '1234.56');
      expect(n('1\u00A0234\u202F567.5'), '1234567.5');
      expect(n('1,234.56'), '1234.56');
      expect(n('1.234,56'), '1234.56');
      expect(n('1,234,567'), '1234567');
      expect(n('1.234.567'), '1234567');
      expect(n("1'234.5"), '1234.5');
      expect(n('0.25'), '0.25');
      expect(n('12.5 EPIC'), '12.5');
      expect(n('10,50 usd', unit: 'usd'), '10.50');
    });

    test('negative and ambiguous amounts are refused in plain words', () {
      expect(
        () => n('-1'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'The amount cannot be negative.',
          ),
        ),
      );
      expect(() => n('\u22122'), throwsFormatException);
      expect(
        () => n('1,234'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Write 1234 or 1.234, so the amount is clear.',
          ),
        ),
      );
      // Thousands separators must group by exactly three.
      const unclear =
          'Write the amount without separators, such as 1234.5, so the amount '
          'is clear.';
      for (final text in [
        '1,234,5',
        '12,34.5',
        '1234,567.5',
        '1.2.3,4',
        '1,234.5,6',
        '1.23.456',
      ]) {
        expect(
          () => n(text),
          throwsA(
            isA<FormatException>().having((e) => e.message, 'message', unclear),
          ),
          reason: text,
        );
      }
      expect(n('1,234,567.89'), '1234567.89');
      expect(n('12,345,678'), '12345678');
      expect(n('1.234.567,5'), '1234567.5');
      // Not ambiguous: no whole part, or not three digits after the comma.
      expect(n('0,234'), '0.234');
      expect(n('1,23'), '1.23');
    });
  });

  group('recent recipients', () {
    final alice = '${'a' * 52}@epicbox.epiccash.com';
    final dave = '${'d' * 52}@epicbox.epiccash.com';
    final eve = '${'e' * 52}@epicbox.epiccash.com';
    const url = 'http://203.0.113.5:3415';
    List<TxEntry> history() => [
      fakeTx(
        kind: TxKind.sentCancelled,
        counterparty: eve,
        timeUnix: 1790000900,
      ),
      fakeTx(kind: TxKind.received, counterparty: dave, timeUnix: 1790000800),
      fakeTx(kind: TxKind.sent, counterparty: alice, timeUnix: 1790000700),
      fakeTx(kind: TxKind.sent, counterparty: _bob, timeUnix: 1790000600),
      fakeTx(kind: TxKind.sent, counterparty: alice, timeUnix: 1790000500),
      fakeTx(kind: TxKind.sent, timeUnix: 1790000450),
      fakeTx(kind: TxKind.sent, counterparty: url, timeUnix: 1790000400),
      fakeTx(kind: TxKind.sent, counterparty: _carol, timeUnix: 1790000300),
    ];

    test('newest distinct sends, at most 3, no cancelled or received', () {
      expect(recentRecipients(history()), [alice, _bob, url]);
      expect(recentRecipients(history().reversed), [alice, _bob, url]);
      expect(recentRecipients(const []), isEmpty);
    });

    testWidgets('chips show names or short addresses and fill the field', (
      tester,
    ) async {
      final h = _Harness();
      h.session.transactionsValue = history();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Bob', address: _bob, note: null),
      );
      await h.pump(tester, const SendScreen());
      final chips = find.byType(ActionChip);
      expect(chips, findsNWidgets(3));
      // The label sits above the chips, and the chips start at the same left edge.
      final label = tester.getRect(find.text('Recent:'));
      final first = tester.getRect(chips.first);
      expect(first.top, greaterThanOrEqualTo(label.bottom));
      final lefts = [
        for (final e in chips.evaluate())
          tester.getRect(find.byWidget(e.widget)).left,
      ];
      expect(lefts.first, closeTo(label.left, 0.5));
      for (final (i, chip) in chips.evaluate().indexed) {
        final r = tester.getRect(find.byWidget(chip.widget));
        expect(r.top, greaterThanOrEqualTo(label.bottom), reason: 'chip $i');
      }
      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
      expect(find.widgetWithText(ActionChip, 'Bob'), findsOneWidget);
      expect(
        find.widgetWithText(ActionChip, 'aaaaaa…aaaaaa@epicbox.epiccash.com'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ActionChip, url), findsOneWidget);

      await _tap(tester, find.widgetWithText(ActionChip, 'Bob'));
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'To'),
      );
      expect(field.controller!.text, _bob);
      expect(find.text('Sending to Bob'), findsOneWidget);
      // Only while the field is empty.
      expect(chips, findsNothing);
      await _enter(tester, 'To', '');
      expect(chips, findsNWidgets(3));
    });

    testWidgets('no chips without past sends', (tester) async {
      final h = _Harness();
      h.session.transactionsValue = [
        fakeTx(kind: TxKind.received, counterparty: dave),
      ];
      await h.pump(tester, const SendScreen());
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('Recent:'), findsNothing);
    });
  });

  group('parseRecipient', () {
    test('reads bare, epicbox:// and http addresses, without whitespace', () {
      final bare = parseRecipient('  $_bob\n');
      expect(bare.kind, RecipientKind.epicbox);
      expect(bare.address, _bob);

      final scheme = parseRecipient('epicbox://$_bob');
      expect(scheme.kind, RecipientKind.epicbox);
      expect(scheme.address, _bob);

      final url = parseRecipient(' https://203.0.113.5:3415 ');
      expect(url.kind, RecipientKind.http);
      expect(url.address, 'https://203.0.113.5:3415');
    });

    test('checkRecipient explains what is wrong', () {
      final service = FakeWalletService();
      final l = englishStrings;
      expect(checkRecipient(l, service, ''), contains('Enter their address'));
      expect(checkRecipient(l, service, 'esBare'), contains('not a valid'));
      expect(
        checkRecipient(l, service, 'http://'),
        contains('full wallet URL'),
      );
      expect(checkRecipient(l, service, _bob), isNull);
      expect(checkRecipient(l, service, 'http://203.0.113.5:3415'), isNull);
    });
  });

  group('send', () {
    testWidgets('epicbox: review, send, result, then save to contacts', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      expect(find.text('Spendable: 40 EPIC'), findsOneWidget);
      // The connection notice is for an entered address only, as a status.
      expect(find.textContaining('Still connecting'), findsNothing);
      await _enter(tester, 'To', _bob);
      expect(find.textContaining('Still connecting'), findsOneWidget);
      expect(find.byType(ErrorText), findsNothing);
      await _enter(tester, 'To', 'http://203.0.113.5:3415');
      expect(find.textContaining('Still connecting'), findsNothing);
      h.connectListener();
      await tester.pumpAndSettle();
      await _enter(tester, 'To', _bob);
      expect(find.textContaining('Still connecting'), findsNothing);

      await _enter(tester, 'To', 'esBare');
      await _enter(tester, 'Amount (EPIC)', '1.5');
      expect(find.text('Fee: 0.008 EPIC. Total: 1.508 EPIC.'), findsOneWidget);
      await _tap(tester, find.text('Review'));
      expect(find.textContaining('not a valid address'), findsOneWidget);
      expect(find.text('Review your payment'), findsNothing);

      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Note (optional)', 'Lunch');
      await _tap(tester, find.text('Review'));
      expect(find.text('Review your payment'), findsOneWidget);
      expect(
        find.text(
          'Goes through epicbox. It completes when the '
          'recipient\'s wallet answers.',
        ),
        findsOneWidget,
      );
      expect(find.text(_bob), findsWidgets);
      expect(find.text('1.5 EPIC'), findsOneWidget);
      expect(find.text('0.008 EPIC'), findsOneWidget);
      expect(find.text('1.508 EPIC'), findsOneWidget);
      expect(find.text('Lunch'), findsWidgets);

      // Edit goes back without sending.
      await _tap(tester, find.text('Edit'));
      expect(h.session.epicboxSends, isEmpty);

      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 1.5 EPIC'));
      expect(h.session.epicboxSends.single.to, _bob);
      expect(h.session.epicboxSends.single.amount, _epic(1.5));
      expect(h.session.notes, {'s:send-1': 'Lunch'});
      expect(find.text('Payment started: 1.5 EPIC'), findsOneWidget);
      // Not "Sent": an epicbox payment has not gone anywhere yet.
      expect(find.text('Sent 1.5 EPIC'), findsNothing);
      // The result is a short screen, centred below the notice slot.
      expect(find.byType(CenteredBody), findsOneWidget);
      expect(find.byType(ScreenBody), findsNothing);
      expect(find.byType(NoticeSlot), findsOneWidget);
      expect(
        find.text(
          'It finishes when the recipient\'s wallet answers, usually within '
          'minutes if their app is open. Keep this app open, or open it again '
          'within a week: epicbox keeps their answer for about that long. '
          'You can find it on the home screen and in History.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'If it is still not completed after 14 days, it cancels by itself '
          'and the amount unlocks. To stop it sooner, open the payment and tap '
          'Cancel payment.',
        ),
        findsOneWidget,
      );

      await _tap(tester, find.text('Save to contacts'));
      expect(find.text('New contact'), findsOneWidget);
      expect(find.text(_bob), findsOneWidget);
      await _enter(tester, 'Name', 'Bob');
      await _tap(tester, find.text('Save contact'));
      final saved = h.session.contactsValue;
      expect(saved.single.name, 'Bob');
      expect(saved.single.address, _bob);
      // Known now, so the offer is gone.
      expect(find.text('Save to contacts'), findsNothing);
    });

    testWidgets('http: completes at once; transport errors in plain words', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'To', 'http://203.0.113.5:3415');
      await _enter(tester, 'Amount (EPIC)', '2');

      h.session.sendError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'the recipient did not answer',
      );
      await _tap(tester, find.text('Review'));
      expect(
        find.text('Goes straight to the recipient\'s wallet.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Send 2 EPIC'));
      expect(
        find.text(
          'Could not reach the recipient. the recipient did not answer',
        ),
        findsOneWidget,
      );

      h.session.sendError = null;
      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 2 EPIC'));
      expect(h.session.httpSends.single.to, 'http://203.0.113.5:3415');
      expect(find.text('Sent 2 EPIC'), findsOneWidget);
    });

    testWidgets('Max fills the largest amount with its fee', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const SendScreen());
      // From fiat entry, Max switches back to EPIC.
      await _tap(tester, find.text('Use USD'));
      await _tap(tester, find.text('Max'));
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Amount (EPIC)'),
      );
      expect(field.controller!.text, '39.992');
      expect(find.text('Fee: 0.008 EPIC. Total: 40 EPIC.'), findsOneWidget);
      await _enter(tester, 'To', _bob);
      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 39.992 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(39.992));
    });

    testWidgets('Max explains when nothing is spendable', (tester) async {
      final h = _Harness();
      h.session.summaryValue = FakeWalletSession.emptySummary;
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Max'));
      expect(find.textContaining('Not enough spendable funds'), findsOneWidget);
    });

    testWidgets('two taps on Review and on Send make one payment', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1');
      final calls = h.session.estimateCalls;

      h.session.estimateGate = Completer<void>();
      final review = find.widgetWithText(FilledButton, 'Review');
      await tester.ensureVisible(review);
      await tester.pumpAndSettle();
      // The second tap lands where the button was; it now shows a spinner.
      final at = tester.getCenter(review);
      await tester.tapAt(at);
      await tester.pump();
      await tester.tapAt(at);
      await tester.pump();
      expect(h.session.estimateCalls, calls + 1);
      h.session.estimateGate!.complete();
      h.session.estimateGate = null;
      await tester.pumpAndSettle();
      expect(find.text('Review your payment'), findsOneWidget);

      final send = find.text('Send 1 EPIC');
      await tester.tap(send);
      await tester.tap(send, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(h.session.epicboxSends, hasLength(1));
      // The Send screen is still there, on its result.
      expect(find.text('Payment started: 1 EPIC'), findsOneWidget);
    });

    testWidgets('Review asks for the fee again; a changed fee is shown', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(find.text('Fee: 0.008 EPIC. Total: 1.008 EPIC.'), findsOneWidget);

      h.session.fee = _epic(0.01);
      await _tap(tester, find.text('Review'));
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('0.01 EPIC')),
        findsOneWidget,
      );

      // The wallet picks its coins again when sending.
      h.session.fee = _epic(0.012);
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(
        find.textContaining(
          'The fee charged was 0.012 EPIC, not the 0.01 EPIC shown before',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an unchanged fee is not mentioned on the result', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(find.textContaining('The fee charged was'), findsNothing);
    });

    testWidgets('after Max, Review asks for the maximum again', (tester) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Max'));
      await _enter(tester, 'To', _bob);
      h.session.summaryValue = WalletSummary(
        lastConfirmedHeight: BigInt.from(2499990),
        minimumConfirmations: BigInt.from(10),
        total: _epic(30),
        spendable: _epic(30),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 29.992 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(29.992));
    });

    testWidgets('fiat entry refuses NaN, Infinity and huge numbers', (
      tester,
    ) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Use USD'));
      for (final text in ['NaN', 'Infinity', '1e400']) {
        await _enter(tester, 'Amount (USD)', text);
        expect(tester.takeException(), isNull);
        expect(find.text('Enter an amount such as 10.50'), findsOneWidget);
      }
    });

    testWidgets('after Max, switching to fiat keeps the exact amount', (
      tester,
    ) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Max'));
      await _tap(tester, find.text('Use USD'));
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Amount (USD)'),
      );
      // 39.992 EPIC at 0.5 is 19.996, shown rounded.
      expect(field.controller!.text, '20.00');
      expect(find.text('≈ 39.992 EPIC'), findsOneWidget);
      await _enter(tester, 'To', _bob);
      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 39.992 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(39.992));
    });

    testWidgets('home refreshes after a send even if Send was closed', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const _Host());
      await _tap(tester, find.text('Open send'));
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Review'));
      h.session.sendGate = Completer<void>();
      await tester.tap(find.text('Send 1 EPIC'));
      // The send is running, so a spinner turns: pump frames instead of settling.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final before = h.session.refreshCalls;

      await tester.pageBack();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Open send'), findsOneWidget);
      h.session.sendGate!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(h.session.epicboxSends, hasLength(1));
      expect(h.session.refreshCalls, before + 1);
    });

    testWidgets('not enough funds shows before review', (tester) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'Amount (EPIC)', '100');
      expect(find.textContaining('Not enough spendable funds'), findsOneWidget);
      final review = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Review'),
      );
      expect(review.onPressed, isNull);
    });

    testWidgets('fiat entry converts at the price and back', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const SendScreen());
      expect(find.text('Spendable: 40 EPIC (≈ 20.00 USD)'), findsOneWidget);
      await _enter(tester, 'Amount (EPIC)', '3');
      expect(find.text('≈ 1.50 USD'), findsOneWidget);

      await _tap(tester, find.text('Use USD'));
      expect(find.widgetWithText(TextField, 'Amount (USD)'), findsOneWidget);
      await _enter(tester, 'Amount (USD)', '10');
      expect(find.text('≈ 20 EPIC'), findsOneWidget);

      await _enter(tester, 'To', _bob);
      await _tap(tester, find.text('Review'));
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('20 EPIC')),
        findsOneWidget,
      );
      expect(find.text('20.008 EPIC (≈ 10.00 USD)'), findsOneWidget);
      await _tap(tester, find.text('Send 20 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(20));
    });

    testWidgets('no price: no unit switch', (tester) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      expect(find.text('Use USD'), findsNothing);
      expect(find.text('Spendable: 40 EPIC'), findsOneWidget);
    });

    testWidgets('scan fills the recipient and a contact shows by name', (
      tester,
    ) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Bob', address: _bob, note: null),
      );
      await h.pump(tester, const SendScreen());
      h.scanner.codes.add(' epicbox://$_bob ');
      await _tap(tester, find.byTooltip('Scan QR code'));
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'To'),
      );
      expect(field.controller!.text, _bob);
      expect(find.text('Sending to Bob'), findsOneWidget);
    });

    testWidgets('scan is hidden where unsupported', (tester) async {
      final h = _Harness(scanSupported: false);
      await h.pump(tester, const SendScreen());
      expect(find.byTooltip('Scan QR code'), findsNothing);
      expect(find.byTooltip('Paste'), findsOneWidget);
    });

    testWidgets('pick a contact as the recipient', (tester) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Carol', address: _carol, note: null),
      );
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Bob', address: _bob, note: null),
      );
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.byTooltip('Choose a contact'));
      expect(find.text('Choose a contact'), findsWidgets);
      await _tap(tester, find.text('Carol'));
      expect(find.text('Sending to Carol'), findsOneWidget);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Review'));
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Carol')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(_carol.replaceFirst('@', '\u200B@')),
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(h.session.epicboxSends.single.to, _carol);
      expect(find.text('Save to contacts'), findsNothing);
    });

    testWidgets('a prefilled recipient from the home scan', (tester) async {
      final h = _Harness();
      await h.pump(tester, SendScreen(recipient: 'epicbox://$_bob'));
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'To'),
      );
      expect(field.controller!.text, _bob);
    });

    testWidgets('by transaction file under "Other ways to send"', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Other ways to send'));
      await _tap(tester, find.text('Send by transaction file'));
      expect(find.textContaining('Sending takes two steps'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Create transaction file'));
      expect(h.session.sentAmounts, [_epic(1.5)]);
      // Nothing leaves the app until the user picks how.
      expect(h.files.saved, isEmpty);
      expect(h.files.shared, isEmpty);
      await _tap(tester, find.text('Save to device'));
      expect(h.files.saved.single.name, 'slate-1.tx');
      expect(h.files.saved.single.json, h.session.sendSlate.json);
      // The confirmation is in the notice slot, not a snack bar.
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text('Saved slate-1.tx'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      await _tap(tester, find.text('Share'));
      expect(h.files.shared.single.name, 'slate-1.tx');
      expect(find.text('Open response file'), findsOneWidget);

      // A response for another transaction is refused before anything is signed.
      h.files.picks.add(
        const SlateFile(name: 'other.tx.response', json: '{"other":1}'),
      );
      h.service.slateInfos['{"other":1}'] = SlateInfo(
        slateId: 'other',
        amount: _epic(9),
        fee: BigInt.one,
        stage: SlateStage.response,
      );
      await _tap(tester, find.text('Open response file'));
      expect(find.textContaining('for a different payment'), findsOneWidget);
      expect(find.text('Finish payment'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      h.files.picks.add(
        SlateFile(
          name: 'slate-1.tx.response',
          json: h.session.responseSlate.json,
        ),
      );
      h.service.slateInfos[h.session.responseSlate.json] = SlateInfo(
        slateId: 'slate-1',
        amount: _epic(1.5),
        fee: h.session.fee,
        stage: SlateStage.response,
      );
      await _tap(tester, find.text('Open response file'));
      expect(
        find.textContaining('answer to your send of 1.5 EPIC'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Finish payment'));
      expect(h.session.finalizedSlates, [h.session.responseSlate.json]);
      expect(
        find.text('Payment of 1.5 EPIC sent to the network.'),
        findsOneWidget,
      );
    });

    testWidgets('where files cannot be shared, only Save to device shows', (
      tester,
    ) async {
      final h = _Harness();
      h.files.canShare = false;
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Other ways to send'));
      await _tap(tester, find.text('Send by transaction file'));
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Create transaction file'));
      expect(find.text('Save to device'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Share'), findsNothing);
    });

    testWidgets('by file: paste the response instead', (tester) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Other ways to send'));
      await _tap(tester, find.text('Send by transaction file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Create transaction file'));
      await _tap(tester, find.text('Copy and paste instead'));
      await _tap(tester, find.text('Finish payment'));
      expect(
        find.text('Paste the response text from the recipient.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(SlateInput),
          matching: find.byType(TextField),
        ),
        h.session.responseSlate.json,
      );
      await _tap(tester, find.text('Finish payment'));
      expect(h.session.finalizedSlates, [h.session.responseSlate.json]);
      expect(find.text('Sent 1.5 EPIC'), findsOneWidget);
      expect(find.textContaining('on its way to the network'), findsOneWidget);
    });
  });

  group('contacts', () {
    testWidgets('add, search, edit and delete', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ContactsScreen());
      expect(find.textContaining('No contacts yet'), findsOneWidget);
      // Nothing to search yet: the empty state sits in the middle, without a search field.
      expect(find.widgetWithText(TextField, 'Search contacts'), findsNothing);
      expect(find.byType(CenteredBody), findsOneWidget);

      await _tap(tester, find.text('Add contact'));
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Enter a name.'), findsOneWidget);
      expect(find.text('Enter their address or a wallet URL.'), findsOneWidget);

      await _enter(tester, 'Name', 'Bob');
      await _enter(tester, 'Address or wallet URL', 'nonsense');
      await _tap(tester, find.text('Save contact'));
      expect(find.textContaining('not a valid address'), findsOneWidget);

      await _enter(tester, 'Address or wallet URL', ' $_bob ');
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Bob'), findsOneWidget);

      await _tap(tester, find.text('Add contact'));
      await _enter(tester, 'Name', 'Carol');
      await _enter(tester, 'Address or wallet URL', _bob);
      expect(
        find.text('This address is already saved as Bob.'),
        findsOneWidget,
      );
      await _enter(tester, 'Address or wallet URL', _carol);
      expect(find.textContaining('already saved'), findsNothing);
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Carol'), findsOneWidget);

      await _enter(tester, 'Search contacts', 'car');
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      await _enter(tester, 'Search contacts', '');

      await _tap(tester, find.text('Bob'));
      expect(find.text('Edit contact'), findsOneWidget);
      await _enter(tester, 'Name', 'Robert');
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Robert'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await _tap(tester, find.text('Robert'));
      await _tap(tester, find.byTooltip('Delete contact'));
      expect(find.text('Delete Robert?'), findsOneWidget);
      await _tap(tester, find.text('Delete'));
      expect(find.text('Robert'), findsNothing);
      expect(h.session.contactsValue.single.name, 'Carol');
    });
  });

  group('auto-lock holds', () {
    testWidgets('sharing the address does not lock; leaving without it does', (
      tester,
    ) async {
      final h = _AppHarness();
      await h.pumpUnlocked(tester);
      await h.open(tester, const ReceiveScreen());

      await _tap(tester, find.text('Share'));
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      expect(h.locked, isFalse);
      await h.finishTrip(tester);
      expect(h.container.read(autoLockHoldProvider), 0);
      expect(h.files.sharedTexts, [h.session.address]);

      // The control: "Immediately" locks an ordinary trip away.
      await h.awayAndBack(tester, const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(h.locked, isTrue);
    });

    testWidgets('a slow send does not lock, and its result stays', (
      tester,
    ) async {
      final h = _AppHarness();
      await h.pumpUnlocked(tester);
      await h.open(tester, const SendScreen());
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Review'));
      h.session.sendGate = Completer<void>();
      await tester.tap(find.text('Send 1 EPIC'));
      await tester.pump();
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      expect(h.locked, isFalse);
      h.session.sendGate!.complete();
      await tester.pumpAndSettle();
      expect(h.locked, isFalse);
      expect(find.text('Payment started: 1 EPIC'), findsOneWidget);
      expect(h.container.read(autoLockHoldProvider), 0);
    });

    testWidgets('picking a transaction file does not lock', (tester) async {
      final h = _AppHarness();
      await h.pumpUnlocked(tester);
      await h.open(tester, const ReceiveScreen());
      await _tap(tester, find.text('Receive a transaction file'));
      await _tap(tester, find.text('Open transaction file'));
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      await h.finishTrip(tester);
      expect(h.locked, isFalse);
      expect(h.container.read(autoLockHoldProvider), 0);
    });

    testWidgets('sharing a send file does not lock', (tester) async {
      final h = _AppHarness();
      await h.pumpUnlocked(tester);
      await h.open(tester, const SendScreen());
      await _tap(tester, find.text('Other ways to send'));
      await _tap(tester, find.text('Send by transaction file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Create transaction file'));
      await _tap(tester, find.text('Save to device'));
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      await h.finishTrip(tester);
      expect(h.locked, isFalse);
      expect(h.files.saved.single.name, 'slate-1.tx');
      expect(h.container.read(autoLockHoldProvider), 0);
    });
  });

  group('finished but not taken by the network', () {
    testWidgets('HTTP: the result says so, and the form is gone', (
      tester,
    ) async {
      final h = _Harness();
      h.session.notPosted = true;
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'To', 'http://203.0.113.5:3415');
      await _enter(tester, 'Amount (EPIC)', '2');
      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 2 EPIC'));
      expect(find.text('Not on the network yet'), findsOneWidget);
      expect(find.text(NotPostedNotice.text(englishStrings)), findsOneWidget);
      expect(find.text('The node did not answer.'), findsOneWidget);
      expect(find.text('Sent 2 EPIC'), findsNothing);
      // Nothing to send a second time with.
      expect(find.text('Review'), findsNothing);
      expect(find.widgetWithText(TextField, 'To'), findsNothing);
      expect(h.session.httpSends, hasLength(1));

      await _tap(tester, find.text('Open the payment'));
      expect(find.byType(TxDetailsScreen), findsOneWidget);
    });

    testWidgets('file, pasted response: the same notice', (tester) async {
      final h = _Harness();
      h.session.notPosted = true;
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Other ways to send'));
      await _tap(tester, find.text('Send by transaction file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Create transaction file'));
      await _tap(tester, find.text('Copy and paste instead'));
      await tester.enterText(
        find.descendant(
          of: find.byType(SlateInput),
          matching: find.byType(TextField),
        ),
        h.session.responseSlate.json,
      );
      await _tap(tester, find.text('Finish payment'));
      expect(find.text(NotPostedNotice.text(englishStrings)), findsOneWidget);
      expect(find.text('Finish payment'), findsNothing);
    });

    testWidgets('file screen: the same notice after Finish payment', (
      tester,
    ) async {
      final h = _Harness();
      h.session.notPosted = true;
      h.service.slateInfos[h.session.responseSlate.json] = SlateInfo(
        slateId: 'slate-1',
        amount: _epic(1.5),
        fee: h.session.fee,
        stage: SlateStage.response,
      );
      await h.pump(
        tester,
        SlateFileScreen(
          file: SlateFile(
            name: 'slate-1.tx.response',
            json: h.session.responseSlate.json,
          ),
        ),
      );
      await _tap(tester, find.text('Finish payment'));
      expect(find.text(NotPostedNotice.text(englishStrings)), findsOneWidget);
      expect(find.textContaining('sent to the network'), findsNothing);
      expect(find.text('Finish payment'), findsNothing);
    });
  });

  group('shared temp files', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('wfe-share-'));
    tearDown(() => tmp.deleteSync(recursive: true));

    for (final status in [
      ShareResultStatus.success,
      ShareResultStatus.dismissed,
    ]) {
      test(
        'a shared file is deleted once the sheet returns (${status.name})',
        () async {
          String? path;
          final ok = await shareBytes(
            name: 'epic-history.csv',
            bytes: Uint8List.fromList(utf8.encode('date,amount')),
            tempDir: tmp,
            share: (params) async {
              path = params.files!.single.path;
              expect(File(path!).existsSync(), isTrue);
              return ShareResult('x', status);
            },
          );
          expect(ok, status == ShareResultStatus.success);
          expect(File(path!).existsSync(), isFalse);
        },
      );
    }

    test('a failing share still deletes the file', () async {
      String? path;
      await expectLater(
        shareBytes(
          name: 'a.tx',
          bytes: Uint8List(1),
          tempDir: tmp,
          share: (params) async {
            path = params.files!.single.path;
            throw StateError('no share sheet');
          },
        ),
        throwsStateError,
      );
      expect(File(path!).existsSync(), isFalse);
    });

    test('clearSharedFiles removes every leftover copy', () async {
      for (final dir in ['shared', 'share_plus', 'slates']) {
        File('${tmp.path}/$dir/left.tx')
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
      }
      File('${tmp.path}/updates/app.apk').createSync(recursive: true);
      await clearSharedFiles(tempDir: tmp);
      for (final dir in ['shared', 'share_plus', 'slates']) {
        expect(Directory('${tmp.path}/$dir').existsSync(), isFalse);
      }
      // Other cache folders are not ours to clear.
      expect(File('${tmp.path}/updates/app.apk').existsSync(), isTrue);
    });
  });

  group('errors', () {
    test('a busy chain says what to do, in plain words', () {
      expect(
        describeError(
          englishStrings,
          const WalletError(
            kind: WalletErrorKind.chainBusy,
            message: 'this process already uses Mainnet for an open wallet',
          ),
        ),
        'The wallet is still busy on the other network. Wait a moment and '
        'try again, or close and reopen the app.',
      );
    });

    group('invalid input', () {
      String say(String message) => describeError(
        englishStrings,
        WalletError(kind: WalletErrorKind.invalidArgument, message: message),
      );

      test('a history-file message is shown alone, as a sentence', () {
        expect(
          say('This is not a history file exported by this app'),
          'This is not a history file exported by this app.',
        );
        expect(
          say('This history file belongs to a different wallet'),
          'This history file belongs to a different wallet.',
        );
        expect(
          say(
            'This history file is from floonet, but this wallet is on mainnet',
          ),
          'This history file is from floonet, but this wallet is on mainnet.',
        );
        expect(
          say('This history file is damaged.'),
          'This history file is damaged.',
        );
      });

      test('any full sentence is shown alone', () {
        expect(
          say('Pick a date after the wallet was made.'),
          'Pick a date after the wallet was made.',
        );
        expect(say('Is this right?\nmore detail'), 'Is this right?');
      });

      test('technical detail keeps the prefix', () {
        expect(
          say('the address has no host'),
          'Invalid input. the address has no host',
        );
        expect(say('No full stop here'), 'Invalid input. No full stop here');
        expect(say(''), 'Invalid input.');
      });
    });

    test('a busy delete does not blame the other network', () {
      final text = describeError(
        englishStrings,
        const WalletError(kind: WalletErrorKind.walletBusy, message: 'busy'),
      );
      expect(
        text,
        'The wallet is still finishing a task. Try again in a moment.',
      );
      expect(text, isNot(contains('network')));
    });

    test('an expired payment uses the core\'s sentence about the funds', () {
      String say(String message) => describeError(
        englishStrings,
        WalletError(kind: WalletErrorKind.paymentExpired, message: message),
      );
      for (final funds in [
        'and the funds are unlocked',
        'and the funds unlock at the next refresh',
      ]) {
        final core =
            'The answer to this payment came too late (block 900, limit 880). '
            'The payment was cancelled: nothing was sent, $funds.';
        expect(say(core), core);
      }
      // Anything else: the fallback, which does not claim the funds are unlocked.
      for (final message in ['', 'expired']) {
        final text = say(message);
        expect(
          text,
          'The answer to this payment came too late, so the payment was '
          'cancelled. Nothing was sent.',
        );
        expect(text, isNot(contains('unlock')));
      }
    });

    test('a bad transaction text does not say "slate" or "JSON"', () {
      final text = describeError(
        englishStrings,
        const WalletError(kind: WalletErrorKind.invalidSlate, message: 'x'),
      );
      expect(text, isNot(contains('slate')));
      expect(text, isNot(contains('JSON')));
      expect(text, contains('transaction text'));
    });
  });

  group('amount field', () {
    testWidgets('reads what people type and paste, and explains the rest', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Amount (EPIC)'),
      );
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );

      await _enter(tester, 'Amount (EPIC)', '1,5');
      expect(find.text('Fee: 0.008 EPIC. Total: 1.508 EPIC.'), findsOneWidget);
      await _enter(tester, 'Amount (EPIC)', ' 12.5 EPIC ');
      expect(find.text('Fee: 0.008 EPIC. Total: 12.508 EPIC.'), findsOneWidget);
      for (final (text, message) in [
        ('-2', 'The amount cannot be negative.'),
        ('0,000000001', 'At most 8 decimal places'),
        (
          '30000000',
          'That is more EPIC than will ever exist. Check the amount.',
        ),
        ('1,234', 'Write 1234 or 1.234, so the amount is clear.'),
        ('abc', 'Enter an amount such as 1.5'),
      ]) {
        await _enter(tester, 'Amount (EPIC)', text);
        expect(find.text(message), findsOneWidget, reason: text);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('fiat entry takes a decimal comma too', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Use USD'));
      await _enter(tester, 'Amount (USD)', '10,50');
      expect(find.text('≈ 21 EPIC'), findsOneWidget);
      await _enter(tester, 'Amount (USD)', '1e5');
      expect(find.text('Enter an amount such as 10.50'), findsOneWidget);
    });

    testWidgets('Next moves To, Amount, Note; Done on the note reviews', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      EditableText editable(String label) => tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextField, label),
          matching: find.byType(EditableText),
        ),
      );

      await tester.tap(find.widgetWithText(TextField, 'To'));
      await tester.enterText(find.widgetWithText(TextField, 'To'), _bob);
      expect(editable('To').textInputAction, TextInputAction.next);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(editable('Amount (EPIC)').focusNode.hasFocus, isTrue);

      await tester.enterText(
        find.widgetWithText(TextField, 'Amount (EPIC)'),
        '1',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(editable('Note (optional)').focusNode.hasFocus, isTrue);
      expect(editable('Note (optional)').textInputAction, TextInputAction.done);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Review your payment'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('field errors are live regions', (tester) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'Amount (EPIC)', '-1');
      await _enter(tester, 'To', 'nonsense');
      await _tap(tester, find.text('Other ways to send'));
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Review'));
      for (final text in [
        'This is not a valid address. It looks like es5x…@epicbox.epiccash.com',
      ]) {
        final live = find.ancestor(
          of: find.text(text),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && (w.properties.liveRegion ?? false),
          ),
        );
        expect(live, findsOneWidget, reason: text);
      }
      handle.dispose();
    });

    for (final (name, screen) in [
      ('send', const SendScreen()),
      ('receive', const ReceiveScreen()),
      ('contacts', const ContactsScreen()),
      ('contact edit', const ContactEditScreen()),
      ('help', const HelpScreen(topic: HelpTopic.fees)),
    ]) {
      testWidgets('$name: labelled tap targets of at least 48 dp', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final h = _Harness();
        await h.session.saveContact(
          contact: Contact(id: '', name: 'Bob', address: _bob, note: null),
        );
        await h.pump(tester, screen);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('the receive QR code has a description', (tester) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      await h.pump(tester, const ReceiveScreen());
      expect(
        tester.getSemantics(find.bySemanticsLabel('QR code of your address')),
        matchesSemantics(label: 'QR code of your address', isImage: true),
      );
      handle.dispose();
    });
  });

  group('help', () {
    testWidgets('every question expands to its answer', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HelpScreen());
      // Tall enough that every closed question is built at once.
      tester.view.physicalSize = const Size(1080, 4800);
      await tester.pumpAndSettle();
      expect(
        find.byType(ExpansionTile),
        findsNWidgets(HelpTopic.values.length),
      );
      // All titles fit on screen while every answer is closed.
      final questions = tester
          .widgetList<ExpansionTile>(find.byType(ExpansionTile))
          .map((t) => (t.title as Text).data!)
          .toList();
      expect(questions, hasLength(HelpTopic.values.length));
      const answer = 'epicbox service holds';
      expect(find.textContaining(answer), findsNothing);
      await _tap(
        tester,
        find.text('Why does my payment say "Waiting for recipient"?'),
      );
      expect(find.textContaining(answer), findsOneWidget);

      // Each question opens to an answer, then closes again.
      for (final q in questions.skip(1)) {
        final title = find.text(q);
        await tester.scrollUntilVisible(
          title,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final tile = find.ancestor(
          of: title,
          matching: find.byType(ExpansionTile),
        );
        await _tap(tester, title);
        expect(
          find.descendant(of: tile, matching: find.byType(Text)),
          findsNWidgets(2),
          reason: q,
        );
        await _tap(tester, title);
      }
      final confirmations = find.text('What are confirmations and why 10?');
      await tester.scrollUntilVisible(
        confirmations,
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await _tap(tester, confirmations);
      expect(
        find.textContaining('After 10 confirmations, about 10 minutes'),
        findsOneWidget,
      );
    });

    for (final (topic, texts) in [
      (
        HelpTopic.waitingForRecipient,
        [
          'holds your payment for about a week',
          'cancels it by itself after 14 days',
        ],
      ),
      (
        HelpTopic.cancelling,
        [
          'cancels itself after 14 days',
          'older versions of this app do not cancel',
        ],
      ),
      (
        HelpTopic.receiving,
        [
          'waits in epicbox for about a week',
          // Other wallets set no time limit, so it is not promised for them.
          'if the sender uses this app, their wallet cancels it by itself',
        ],
      ),
    ]) {
      testWidgets('${topic.name} explains the time limits', (tester) async {
        final h = _Harness();
        await h.pump(tester, HelpScreen(topic: topic));
        for (final text in texts) {
          expect(find.textContaining(text), findsOneWidget, reason: text);
        }
      });
    }

    testWidgets('a topic opens expanded', (tester) async {
      final h = _Harness();
      await h.pump(
        tester,
        const HelpScreen(topic: HelpTopic.historyAfterRestore),
      );
      expect(
        find.textContaining('Payment history, Import history backup'),
        findsOneWidget,
      );
      expect(
        find.textContaining('a copy you kept outside the lost phone'),
        findsOneWidget,
      );
      expect(find.textContaining('epicbox service holds'), findsNothing);
    });

    testWidgets('receive links to help about receiving', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveScreen());
      await _tap(tester, find.byTooltip('Help'));
      expect(find.byType(HelpScreen), findsOneWidget);
      expect(
        find.textContaining('it can only do that while the app is open'),
        findsOneWidget,
      );
    });

    testWidgets('the epicbox send result links to "Waiting for recipient"', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Review'));
      await _tap(tester, find.text('Send 1 EPIC'));
      await _tap(tester, find.widgetWithText(TextButton, 'Help'));
      expect(find.textContaining('epicbox service holds'), findsOneWidget);
    });
  });

  group('receive', () {
    testWidgets('QR, address, copy, share, a connection dot and the file '
        'section, with no explanations', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveScreen());
      expect(find.text(h.session.address), findsOneWidget);
      expect(find.bySemanticsLabel('QR code of your address'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      // The connection state is a dot, named only in its tooltip.
      expect(find.byTooltip('Connecting to epicbox'), findsOneWidget);
      h.connectListener();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Epicbox connected'), findsOneWidget);
      expect(find.byTooltip('Connecting to epicbox'), findsNothing);
      h.session.listenerEvents.add(
        const ListenerEvent(
          kind: ListenerEventKind.disconnected,
          message: 'timeout',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Epicbox offline'), findsOneWidget);
      h.connectListener();
      await tester.pumpAndSettle();
      // Only the address and the button labels: no sentences.
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(CenteredBody),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .toSet();
      expect(texts, {'Copy', 'Share', 'Receive a transaction file'});
      expect(find.textContaining('arrive'), findsNothing);
      expect(find.textContaining('epicbox server'), findsNothing);

      // The content sits in the middle of the space below the notice slot.
      final slot = tester.getRect(find.byType(NoticeSlot));
      final screen = tester.getRect(find.byType(Scaffold));
      final body = tester.getRect(find.byType(CenteredBody));
      expect(
        body.center.dy,
        moreOrLessEquals((slot.bottom + screen.bottom) / 2, epsilon: 1),
      );

      // Copying confirms in the slot, and the content does not move.
      final copied = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copied.add(call.arguments);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _tap(tester, find.text('Copy'));
      expect(copied, [
        {'text': h.session.address},
      ]);
      expect(
        find.descendant(
          of: find.byKey(noticeKey),
          matching: find.text('Address copied'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.getRect(find.byType(CenteredBody)), body);

      await _tap(tester, find.text('Share'));
      expect(h.files.sharedTexts, [h.session.address]);

      expect(find.text('Open transaction file'), findsNothing);
      await _tap(tester, find.text('Receive a transaction file'));
      expect(find.text('Open transaction file'), findsOneWidget);
    });

    testWidgets('by file: open .tx, sign, share .response', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveScreen());
      await _tap(tester, find.text('Receive a transaction file'));

      h.files.picks.add(const SlateFile(name: 'photo.jpg', json: 'nope'));
      await _tap(tester, find.text('Open transaction file'));
      expect(find.text('That file is not a transaction file.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      const incoming = '{"id":"incoming"}';
      h.service.slateInfos[incoming] = SlateInfo(
        slateId: 'incoming',
        amount: _epic(3),
        fee: BigInt.zero,
        stage: SlateStage.send,
      );
      h.files.picks.add(const SlateFile(name: 'from-bob.tx', json: incoming));
      await _tap(tester, find.text('Open transaction file'));
      expect(find.text('Someone is sending you 3 EPIC.'), findsOneWidget);
      await _tap(tester, find.text('Accept payment'));
      expect(h.session.receivedSlates, [incoming]);
      expect(
        find.text('Accepted. Return from-bob.tx.response to the sender.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Save to device'));
      expect(h.files.saved.single.name, 'from-bob.tx.response');
      expect(h.files.saved.single.json, h.session.responseSlate.json);
      await _tap(tester, find.text('Share'));
      expect(h.files.shared.single.name, 'from-bob.tx.response');
    });

    testWidgets('paste slate text as a fallback', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveScreen());
      await _tap(tester, find.text('Receive a transaction file'));
      await _tap(tester, find.text('Paste the transaction text instead'));
      await _tap(tester, find.text('Accept payment'));
      expect(
        find.text('Paste the transaction text you received.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(SlateInput),
          matching: find.byType(TextField),
        ),
        '{"id":"incoming"}',
      );
      await _tap(tester, find.text('Accept payment'));
      expect(h.session.receivedSlates, ['{"id":"incoming"}']);
      expect(find.text(h.session.responseSlate.json), findsOneWidget);
    });
  });
}
