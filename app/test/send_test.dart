import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/errors.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/centered_body.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'support/send_pin.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid address for [FakeWalletService.validateEpicboxAddress].
final String _bob = '${'b' * 52}@epicbox.epiccash.com';
final String _carol = '${'c' * 52}@epicbox.epicnet.us';

_GatedSession _funded() => _GatedSession(
  summary: WalletSummary(
    lastConfirmedHeight: BigInt.from(2499990),
    minimumConfirmations: BigInt.from(3),
    total: _epic(50),
    spendable: _epic(40),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: true,
  ),
);

/// A wallet holding 10 EPIC, still confirming or [confirmed] and spendable.
WalletSummary _tenEpic({required bool confirmed}) => WalletSummary(
  lastConfirmedHeight: BigInt.from(2499990),
  minimumConfirmations: BigInt.from(3),
  total: _epic(10),
  spendable: confirmed ? _epic(10) : BigInt.zero,
  awaitingConfirmation: confirmed ? BigInt.zero : _epic(10),
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
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

/// The open wallet is on mainnet, as after the launch screen.
class _MainnetConfig extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: mainnetPreset.nodeUrl,
  );
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
    SendOptions? options,
  }) async {
    estimateCalls++;
    await estimateGate?.future;
    return super.estimateFee(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      options: options,
    );
  }

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) async {
    await sendGate?.future;
    return super.sendEpicbox(
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      address: address,
      message: message,
      options: options,
    );
  }

  /// When set, finishes return a finished send the network has not taken.
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

/// The Send tab alone, as the shell shows it. Done closes the route it is in, if any, as the
/// shell goes back to Wallet.
Widget _sendTab() => Builder(
  builder: (context) => SlotScaffold(
    appBar: AppBar(),
    body: SendView(onDone: () => Navigator.maybePop(context)),
  ),
);

/// The Receive tab alone, as the shell shows it.
Widget _receiveTab() => const SlotScaffold(body: ReceiveView());

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
            onPressed: () => Navigator.of(
              context,
            ).push<void>(MaterialPageRoute<void>(builder: (_) => _sendTab())),
            child: const Text('Open send'),
          ),
        ],
      ),
    );
  }
}

class _Harness {
  _Harness({this.price, bool scanSupported = true, this.advanced = false, this.direct = false})
    : scanner = FakeQrScanner(supported: scanSupported);

  /// Advanced options, as `MaterialApp.builder` in the app would provide it.
  final bool advanced;

  /// Settings › Transactions › Link on.
  final bool direct;

  final session = _funded();
  late final service = FakeWalletService()
    ..slateInfos[session.responseSlate.json] = SlateInfo(
      slateId: session.sendSlate.slateId,
      amount: _epic(1.5),
      fee: session.fee,
      stage: SlateStage.response,
    );
  final files = FakeSlateFiles();
  final FakeQrScanner scanner;
  final double? price;

  /// [settle] false stops after the first frame, for a screen with a spinner.
  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    allowPinCheck(session, service);
    // A controlled scope, so the price refresh timer ends with the widget tree.
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(
            sendPinStore()
              ..values['app.payment_prefs'] = PaymentPrefs(linkHttp: direct, linkTor: direct).encode(),
          ),
          slateFilesProvider.overrideWithValue(files),
          qrScannerProvider.overrideWithValue(scanner),
          priceSourceProvider.overrideWithValue(_FixedPrice(price)),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          walletConfigProvider.overrideWith(_MainnetConfig.new),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              AdvancedOptions(prefs: advanced ? AdvancedPrefs.all : AdvancedPrefs.none, child: child!),
          home: screen,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
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
  await answerPin(tester);
}

/// The contact form's first address field, whose label follows the kind typed into it.
Future<void> _enterAddress(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(contactAddressFieldKey(0)), text);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  // Screens are lazy lists: scroll until the field is built.
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  // Past the fee estimate's debounce.
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// The address field on the first step.
const String _address = 'To';

Finder get _continue => find.widgetWithText(FilledButton, 'Continue');

/// The first step for [to], then Continue to the amount.
Future<void> _toAmount(WidgetTester tester, [String? to]) async {
  await _enter(tester, _address, to ?? _bob);
  await _tap(tester, _continue);
}

/// Unfolds the note on the amount step and writes [text] in it.
Future<void> _note(WidgetTester tester, String text) async {
  if (find.widgetWithText(TextField, 'Note').evaluate().isEmpty) {
    await _tap(tester, find.text('Add a note'));
  }
  await _enter(tester, 'Note', text);
}

/// The recipient and the amount, then Continue to the review.
Future<void> _toReview(
  WidgetTester tester, {
  String? to,
  String amount = '1',
  String? note,
}) async {
  await _toAmount(tester, to);
  await _enter(tester, 'Amount (EPIC)', amount);
  if (note != null) await _note(tester, note);
  await _tap(tester, _continue);
}

/// The payment file route, from the first step.
Future<void> _toFile(WidgetTester tester) => _tap(tester, find.text('Direct · File'));

String _fieldText(WidgetTester tester, String label) => tester
    .widget<TextField>(find.widgetWithText(TextField, label))
    .controller!
    .text;

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

  @override
  Future<void> shareImage({
    required String name,
    required Uint8List png,
    required String text,
  }) async {
    await _wait();
    await super.shareImage(name: name, png: png, text: text);
  }
}

/// Pumps until [done], letting real time pass between frames: the share card renders through
/// the engine, which fake time does not move.
Future<void> _untilRendered(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(done(), isTrue, reason: 'the share card did not render');
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

/// The whole app on a funded mainnet wallet with a PIN, auto-lock after a minute (the
/// shortest), and a clock the test moves.
class _AppHarness {
  _AppHarness({bool advanced = false}) {
    store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    store.values['app.auto_lock'] = '1';
    if (advanced) store.values['app.advanced'] = 'true';
    service = FakeWalletService(
      existingWallets: {'/fake/wallets/mainnet'},
      session: session,
    );
  }

  static const _pin = '123456';

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
          updatePlatformProvider.overrideWithValue(null),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
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

    testWidgets(
      'recent rows show names or short addresses and fill the field',
      (tester) async {
        final h = _Harness();
        h.session.transactionsValue = history();
        await h.session.saveContact(
          contact: Contact(id: '', name: 'Bob', address: _bob, note: null),
        );
        await h.pump(tester, _sendTab());
        // A tall phone: the rows sit under the method strip, past a test font's fold.
        tester.view.physicalSize = const Size(1080, 3600);
        await tester.pumpAndSettle();
        expect(find.text('Recent'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
        // A name keeps its address beside it.
        expect(find.text('bbbbbb…bbbbbb@epicbox.epiccash.com'), findsOneWidget);
        expect(find.text('aaaaaa…aaaaaa@epicbox.epiccash.com'), findsOneWidget);
        expect(find.text(url), findsOneWidget);
        final handle = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();

        // One tap: the recipient and on to the amount.
        await _tap(tester, find.text('Bob'));
        expect(find.text('2 of 3'), findsOneWidget);
        expect(find.text('To Bob'), findsOneWidget);
        await _tap(tester, find.byTooltip('Back'));
        expect(_fieldText(tester, _address), _bob);
        // The card names him; no offer to save him again.
        expect(find.text('New recipient'), findsNothing);
        expect(find.text('Save as contact'), findsNothing);
        // Only while the field is empty.
        expect(find.text('Recent'), findsNothing);
        await _enter(tester, _address, '');
        expect(find.text('Recent'), findsOneWidget);
      },
    );

    testWidgets('no recent list without past sends', (tester) async {
      final h = _Harness();
      h.session.transactionsValue = [
        fakeTx(kind: TxKind.received, counterparty: dave),
      ];
      await h.pump(tester, _sendTab());
      expect(find.text('Recent'), findsNothing);
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
      expect(
        checkRecipient(l, service, ''),
        contains('Enter their address'),
      );
      expect(checkRecipient(l, service, 'esBare'), contains('Not a valid'));
      expect(
        checkRecipient(l, service, 'http://'),
        contains('full wallet URL'),
      );
      expect(checkRecipient(l, service, _bob), isNull);
      expect(checkRecipient(l, service, 'http://203.0.113.5:3415'), isNull);
    });
  });

  group('send', () {
    testWidgets(
      'address: three steps, send, the tracker, then save the contact',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, _sendTab());
        expect(find.text('Payment method'), findsOneWidget);
        expect(find.text('1 of 3'), findsOneWidget);
        // Continue waits for an address.
        expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
        await _enter(tester, _address, 'esBare');
        await _tap(tester, _continue);
        expect(find.text('This address looks incomplete.'), findsOneWidget);
        expect(find.text('2 of 3'), findsNothing);

        await _enter(tester, _address, _bob);
        expect(find.text('New recipient'), findsOneWidget);
        expect(find.text('Save as contact'), findsOneWidget);
        await _tap(tester, _continue);
        expect(find.text('Amount'), findsOneWidget);
        expect(find.text('2 of 3'), findsOneWidget);
        expect(find.text('Available 40 EPIC'), findsOneWidget);
        await _enter(tester, 'Amount (EPIC)', '1.5');
        // The fee is a quiet figure, not a sentence about what Bob gets.
        expect(find.text('Network fee 0.008 EPIC'), findsOneWidget);
        expect(find.textContaining('gets exactly'), findsNothing);
        await _note(tester, 'Lunch');
        await _tap(tester, _continue);
        expect(find.text('Review'), findsOneWidget);
        expect(find.text('3 of 3'), findsOneWidget);
        expect(find.text('1.5 EPIC'), findsOneWidget);
        expect(find.text('0.008 EPIC'), findsOneWidget);
        expect(find.text('1.508 EPIC'), findsOneWidget);

        // Edit goes back without sending.
        await _tap(tester, find.text('Edit'));
        expect(h.session.epicboxSends, isEmpty);
        expect(find.text('2 of 3'), findsOneWidget);
        expect(_fieldText(tester, 'Note'), 'Lunch');

        await _tap(tester, _continue);
        await _tap(tester, find.text('Send 1.5 EPIC'));
        expect(h.session.epicboxSends.single.to, _bob);
        expect(h.session.epicboxSends.single.amount, _epic(1.5));
        expect(h.session.notes, {'s:send-1': 'Lunch'});
        expect(h.session.sentMessages, ['Lunch']);
        // The tracker, not "Sent": the payment waits for their wallet.
        expect(find.text('Sent'), findsOneWidget);
        expect(find.text('Waiting for their wallet'), findsOneWidget);
        expect(find.text('Sent to the network'), findsOneWidget);
        expect(find.text('Confirmed'), findsOneWidget);
        expect(
          find.text(
            'Their wallet finishes it when it opens. '
            '1.508 EPIC stays on hold until then.',
          ),
          findsOneWidget,
        );
        // The cancel rule waits behind a small expandable.
        expect(find.textContaining('cancels by itself'), findsNothing);
        await _tap(tester, find.text('What if it never finishes?'));
        expect(
          find.textContaining('If it is still not completed after 14 days'),
          findsOneWidget,
        );

        await _tap(tester, find.text('Save as contact'));
        expect(find.text('New contact'), findsOneWidget);
        expect(find.text(_bob), findsOneWidget);
        await _enter(tester, 'Name', 'Bob');
        await _tap(tester, find.text('Save contact'));
        final saved = h.session.contactsValue;
        expect(saved.single.name, 'Bob');
        expect(saved.single.address, _bob);
        // Known now: the offer is gone and the steps name him.
        expect(find.text('Save as contact'), findsNothing);
        expect(find.text('Sent to Bob'), findsOneWidget);
        expect(find.text('Waiting for Bob’s wallet'), findsOneWidget);
      },
    );

    testWidgets('an incomplete wallet URL is refused in plain words', (
      tester,
    ) async {
      final h = _Harness(direct: true);
      await h.pump(tester, _sendTab());
      await _enter(tester, _address, 'https://');
      await _tap(tester, _continue);
      expect(
        find.text('Enter the full wallet URL, such as http://host:3415'),
        findsOneWidget,
      );
      expect(find.text('2 of 3'), findsNothing);

      // A whole one goes on, over HTTP.
      await _enter(tester, _address, 'http://203.0.113.5:3415');
      expect(find.byType(LiveFieldError), findsNothing);
      await _tap(tester, _continue);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(h.session.epicboxSends, isEmpty);
      expect(h.session.sentAmounts, isEmpty);
    });

    testWidgets('a paste is checked at once, typing when the field is left', (
      tester,
    ) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async =>
            call.method == 'Clipboard.getData' ? {'text': clipboard} : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final h = _Harness();
      await h.pump(tester, _sendTab());

      clipboard = 'https://';
      await _tap(tester, find.text('Paste'));
      expect(
        find.text('Enter the full wallet URL, such as http://host:3415'),
        findsOneWidget,
      );
      clipboard = 'b' * 30;
      await _tap(tester, find.text('Paste'));
      expect(find.text('This address looks incomplete.'), findsOneWidget);
      clipboard = 'not an address!';
      await _tap(tester, find.text('Paste'));
      expect(find.text('This is not an Epicbox address.'), findsOneWidget);
      clipboard = ' $_bob ';
      await _tap(tester, find.text('Paste'));
      expect(find.byType(LiveFieldError), findsNothing);
      expect(find.text('New recipient'), findsOneWidget);

      // Typed: no message while typing, one when the field is left.
      await tester.tap(find.widgetWithText(TextField, _address));
      await tester.enterText(find.widgetWithText(TextField, _address), 'esB');
      await tester.pumpAndSettle();
      expect(find.byType(LiveFieldError), findsNothing);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('This address looks incomplete.'), findsOneWidget);
    });

    testWidgets(
      'a send the relay refuses is never sent again from the review',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, _sendTab());
        await _toReview(tester, amount: '2');
        h.session.sendError = const WalletError(
          kind: WalletErrorKind.transportFailed,
          message: 'the relay did not answer',
        );
        await _tap(tester, find.text('Send 2 EPIC'));
        expect(
          find.textContaining("didn't take it."),
          findsOneWidget,
        );
        expect(find.text('Send anyway'), findsNothing);
        expect(find.text('Send 2 EPIC'), findsNothing);
        expect(find.text('Edit'), findsNothing);
        // The payment waits with its coins on hold until it is cancelled.
        expect(h.session.summaryValue.locked, _epic(2) + h.session.fee);

        h.session.sendError = null;
        await _tap(tester, find.text('Leave it for now'));
        expect(h.session.epicboxSends, hasLength(1));
        expect(h.session.cancelledTxIds, isEmpty);
      },
    );

    testWidgets('other send errors in plain words, under the review', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toReview(tester, amount: '2');
      h.session.sendError = const WalletError(
        kind: WalletErrorKind.walletBusy,
        message: 'busy',
      );
      await _tap(tester, find.text('Send 2 EPIC'));
      expect(find.byType(ErrorText), findsOneWidget);
      expect(find.text('Pay with a file instead'), findsNothing);
      h.session.sendError = null;
      await _tap(tester, find.text('Send 2 EPIC'));
      expect(h.session.epicboxSends, hasLength(1));
    });

    testWidgets('the note stops at LEPIC\'s limit in bytes', (tester) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      // Folded until asked for.
      expect(find.widgetWithText(TextField, 'Note'), findsNothing);
      await _tap(tester, find.text('Add a note'));
      const label = 'Note';
      expect(find.text('They see it too.'), findsOneWidget);
      expect(find.text('0/256'), findsOneWidget);
      await _enter(tester, label, 'Zażółć');
      // Four of the six letters take two bytes.
      expect(find.text('10/256'), findsOneWidget);
      // A paste past the limit keeps the whole characters that fit.
      await _enter(tester, label, 'é' * 200);
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, label),
      );
      expect(field.controller!.text, 'é' * 128);
      expect(find.text('256/256'), findsOneWidget);
      await _enter(tester, label, '${'a' * 255}€');
      expect(field.controller!.text, 'a' * 255, reason: '€ takes three bytes');
    });

    group('the byte limit cuts only what is inserted', () {
      const limit = Utf8LengthLimiter(10);
      TextEditingValue at(String text, int start, [int? end]) =>
          TextEditingValue(
            text: text,
            selection: TextSelection(
              baseOffset: start,
              extentOffset: end ?? start,
            ),
          );

      test('typing in the middle of a full field changes nothing', () {
        final out = limit.formatEditUpdate(
          at('abcdefghij', 2),
          at('abXcdefghij', 3),
        );
        expect(out.text, 'abcdefghij');
        expect(out.selection, const TextSelection.collapsed(offset: 2));
      });

      test('a paste in the middle keeps the text after it', () {
        final out = limit.formatEditUpdate(
          at('abcdefgh', 4),
          at('abcdéXYZefgh', 8),
        );
        // é takes two bytes, so only it fits beside the eight letters.
        expect(out.text, 'abcdéefgh');
        expect(out.selection, const TextSelection.collapsed(offset: 5));
      });

      test('a paste over a selection replaces it, cut to fit', () {
        final out = limit.formatEditUpdate(
          at('abcdefghij', 2, 5),
          at('ab12345fghij', 7),
        );
        expect(out.text, 'ab123fghij');
        expect(out.selection, const TextSelection.collapsed(offset: 5));
      });

      test('an edit that is no insertion falls back to the first bytes', () {
        final out = limit.formatEditUpdate(
          const TextEditingValue(text: 'abc'),
          const TextEditingValue(text: 'zzzzzzzzzzzz'),
        );
        expect(out.text, 'zzzzzzzzzz');
      });
    });

    testWidgets('Max fills the largest amount with its fee', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      // From fiat entry, Max switches back to EPIC.
      await _tap(tester, find.text('Use USD'));
      await _tap(tester, find.text('Max'));
      expect(_fieldText(tester, 'Amount (EPIC)'), '39.992');
      expect(find.text('Network fee 0.008 EPIC'), findsOneWidget);
      await _tap(tester, _continue);
      await _tap(tester, find.text('Send 39.992 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(39.992));
    });

    testWidgets('Max explains when nothing is spendable, and what is on hold', (
      tester,
    ) async {
      final h = _Harness();
      h.session.summaryValue = _tenEpic(confirmed: false);
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      expect(find.text('Available 0 EPIC'), findsOneWidget);
      expect(find.text('+10 EPIC coming in'), findsOneWidget);
      await _tap(tester, find.text('Max'));
      expect(find.textContaining('Not enough spendable funds'), findsOneWidget);
    });

    testWidgets('two taps on Continue and on Send make one payment', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      await _enter(tester, 'Amount (EPIC)', '1');
      final calls = h.session.estimateCalls;

      h.session.estimateGate = Completer<void>();
      await tester.ensureVisible(_continue);
      await tester.pumpAndSettle();
      // The second tap lands where the button was; it now shows a spinner.
      final at = tester.getCenter(_continue);
      await tester.tapAt(at);
      await tester.pump();
      await tester.tapAt(at);
      await tester.pump();
      expect(h.session.estimateCalls, calls + 1);
      h.session.estimateGate!.complete();
      h.session.estimateGate = null;
      await tester.pumpAndSettle();
      expect(find.text('3 of 3'), findsOneWidget);

      final send = find.text('Send 1 EPIC');
      await tester.tap(send);
      await tester.tap(send, warnIfMissed: false);
      await tester.pumpAndSettle();
      // One PIN dialog for the two taps.
      expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
      await answerPin(tester);
      expect(h.session.epicboxSends, hasLength(1));
      // The Send tab is still there, on its tracker.
      expect(find.text('Waiting for their wallet'), findsOneWidget);
    });

    testWidgets('Continue asks for the fee again; a changed fee is shown', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      await _enter(tester, 'Amount (EPIC)', '1');
      expect(find.text('Network fee 0.008 EPIC'), findsOneWidget);

      h.session.fee = _epic(0.01);
      await _tap(tester, _continue);
      expect(find.text('0.01 EPIC'), findsOneWidget);
      expect(find.text('1.01 EPIC'), findsOneWidget);

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

    testWidgets('an unchanged fee is not mentioned on the tracker', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toReview(tester);
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(find.textContaining('The fee charged was'), findsNothing);
    });

    testWidgets('after Max, a balance change asks for the maximum again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      await _tap(tester, find.text('Max'));
      expect(_fieldText(tester, 'Amount (EPIC)'), '39.992');
      final fees = h.session.estimateCalls;
      h.session.summaryValue = WalletSummary(
        lastConfirmedHeight: BigInt.from(2499990),
        minimumConfirmations: BigInt.from(3),
        total: _epic(30),
        spendable: _epic(30),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      await ProviderScope.containerOf(tester.element(find.byType(SendView)))
          .read(homeProvider.notifier)
          .reload();
      await tester.pumpAndSettle();
      // The maximum of the new balance, not a fee for the old maximum.
      expect(_fieldText(tester, 'Amount (EPIC)'), '29.992');
      expect(h.session.estimateCalls, fees);
      expect(find.textContaining('Not enough spendable funds'), findsNothing);
    });

    testWidgets('after Max, Continue asks for the maximum again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      await _tap(tester, find.text('Max'));
      h.session.summaryValue = WalletSummary(
        lastConfirmedHeight: BigInt.from(2499990),
        minimumConfirmations: BigInt.from(3),
        total: _epic(30),
        spendable: _epic(30),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      );
      await _tap(tester, _continue);
      await _tap(tester, find.text('Send 29.992 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(29.992));
    });

    testWidgets('fiat entry refuses NaN, Infinity and huge numbers', (
      tester,
    ) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
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
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      await _tap(tester, find.text('Max'));
      await _tap(tester, find.text('Use USD'));
      // 39.992 EPIC at 0.5 is 19.996, shown rounded.
      expect(_fieldText(tester, 'Amount (USD)'), '20.00');
      expect(find.text('≈ 39.992 EPIC'), findsOneWidget);
      await _tap(tester, _continue);
      await _tap(tester, find.text('Send 39.992 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(39.992));
    });

    testWidgets('home refreshes after a send even if Send was closed', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const _Host());
      await _tap(tester, find.text('Open send'));
      await _toReview(tester);
      h.session.sendGate = Completer<void>();
      await tester.tap(find.text('Send 1 EPIC'));
      await tester.pumpAndSettle();
      await answerPin(tester, settle: false);
      // The send is running, so a spinner turns: pump frames instead of settling.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final before = h.session.refreshCalls;

      // Closes the route; the step header has its own Back.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
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

    testWidgets('not enough funds shows in place, before Continue', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      await _enter(tester, 'Amount (EPIC)', '100');
      expect(find.textContaining('Not enough spendable funds'), findsOneWidget);
      expect(tester.widget<FilledButton>(_continue).onPressed, isNull);
    });

    // F-06: "Spendable: 10 EPIC" beside "Not enough spendable funds", because the estimate
    // failed while the balance was 0 and was never asked again.
    testWidgets(
      'a balance that arrives clears the funds error and estimates again',
      (tester) async {
        final h = _Harness();
        h.session.summaryValue = _tenEpic(confirmed: false);
        await h.pump(tester, _sendTab());
        await _toAmount(tester);
        await _enter(tester, 'Amount (EPIC)', '2.5');
        expect(
          find.textContaining('Not enough spendable funds'),
          findsOneWidget,
        );
        final calls = h.session.estimateCalls;

        // The coins confirm: the balance becomes spendable.
        h.session.summaryValue = _tenEpic(confirmed: true);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(SendView)),
        );
        await container.read(homeProvider.notifier).reload();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Available 10 EPIC'), findsOneWidget);
        expect(find.textContaining('Not enough spendable funds'), findsNothing);
        expect(h.session.estimateCalls, greaterThan(calls));
        expect(find.text('Network fee 0.008 EPIC'), findsOneWidget);
        expect(tester.widget<FilledButton>(_continue).onPressed, isNotNull);
      },
    );

    testWidgets('fiat entry converts at the price and back', (tester) async {
      final h = _Harness(price: 0.5);
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      expect(find.text('Available 40 EPIC'), findsOneWidget);
      await _enter(tester, 'Amount (EPIC)', '3');
      expect(find.text('≈ 1.50 USD'), findsOneWidget);

      await _tap(tester, find.text('Use USD'));
      expect(find.widgetWithText(TextField, 'Amount (USD)'), findsOneWidget);
      await _enter(tester, 'Amount (USD)', '10');
      expect(find.text('≈ 20 EPIC'), findsOneWidget);

      await _tap(tester, _continue);
      expect(find.text('20 EPIC'), findsOneWidget);
      expect(find.text('20.008 EPIC (≈ 10.00 USD)'), findsOneWidget);
      await _tap(tester, find.text('Send 20 EPIC'));
      expect(h.session.epicboxSends.single.amount, _epic(20));
    });

    testWidgets('no price: no unit switch', (tester) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      expect(find.text('Use USD'), findsNothing);
      expect(find.text('Max'), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('Use USD and Max fit at 320 dp, text x$scale', (
        tester,
      ) async {
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final h = _Harness(price: 0.5);
        await h.pump(tester, _sendTab());
        tester.view.physicalSize = const Size(960, 2340);
        await tester.pumpAndSettle();
        await _toAmount(tester);
        expect(tester.takeException(), isNull);
        final row = tester.getRect(find.byKey(amountSuffixKey));
        expect(row.left, greaterThanOrEqualTo(0));
        expect(row.right, lessThanOrEqualTo(320));
        for (final label in ['Use USD', 'Max']) {
          final button = find.ancestor(
            of: find.text(label),
            matching: find.byType(OutlinedButton),
          );
          final rect = tester.getRect(button);
          expect(rect.right, lessThanOrEqualTo(320), reason: label);
          expect(rect.height, greaterThanOrEqualTo(48), reason: label);
        }
        // Both still work.
        await _tap(tester, find.text('Use USD'));
        expect(find.widgetWithText(TextField, 'Amount (USD)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('scan fills the recipient and a contact shows by name', (
      tester,
    ) async {
      final h = _Harness();
      await h.session.saveContact(
        contact: Contact(id: '', name: 'Bob', address: _bob, note: null),
      );
      await h.pump(tester, _sendTab());
      h.scanner.codes.add(' epicbox://$_bob ');
      await _tap(tester, find.byTooltip('Scan QR code'));
      expect(_fieldText(tester, _address), _bob);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('New recipient'), findsNothing);
    });

    testWidgets('scan is hidden where unsupported', (tester) async {
      final h = _Harness(scanSupported: false);
      await h.pump(tester, _sendTab());
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
      await h.pump(tester, _sendTab());
      await _tap(tester, find.byTooltip('Choose a contact'));
      expect(find.text('Choose a contact'), findsWidgets);
      await _tap(tester, find.text('Carol'));
      expect(find.text('Carol'), findsOneWidget);
      await _tap(tester, _continue);
      expect(find.text('To Carol'), findsOneWidget);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, _continue);
      expect(find.text('Carol'), findsOneWidget);
      // The whole address, its relay on its own line.
      expect(
        find.text('${'c' * 52}\n@epicbox.epicnet.us', findRichText: true),
        findsOneWidget,
      );
      await _tap(tester, find.text('Send 1 EPIC'));
      expect(h.session.epicboxSends.single.to, _carol);
      expect(find.text('Sent to Carol'), findsOneWidget);
      expect(find.text('Save as contact'), findsNothing);
    });

    testWidgets('a recipient handed over fills the open form', (tester) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toAmount(tester, _carol);
      // From a later step it goes back to the recipient, keeping the amount.
      await _enter(tester, 'Amount (EPIC)', '2');
      ProviderScope.containerOf(tester.element(find.byType(SendView)))
          .read(sendRecipientProvider.notifier)
          .hand('epicbox://$_bob');
      await tester.pumpAndSettle();
      expect(find.text('1 of 3'), findsOneWidget);
      expect(_fieldText(tester, _address), _bob);
      await _tap(tester, _continue);
      expect(_fieldText(tester, 'Amount (EPIC)'), '2');
    });

    // android-15: making a payment file locks the coins it pays, so it asks the PIN as an
    // Epicbox send does; a dismissed prompt makes nothing.
    testWidgets('a payment file is made only after the PIN', (tester) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toFile(tester);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      final make = find.text('Make payment file');
      await tester.ensureVisible(make);
      await tester.tap(make);
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter the PIN to make a payment file'), findsOneWidget);
      await tester.tap(find.text(englishStrings.commonCancel));
      await tester.pumpAndSettle();
      expect(h.session.sentAmounts, isEmpty);
      await tester.tap(make);
      await tester.pumpAndSettle();
      await answerPin(tester);
      expect(h.session.sentAmounts, [_epic(1.5)]);
    });

    testWidgets('by payment file, from the first step with Advanced off', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toFile(tester);
      expect(find.text('Pay with a file'), findsOneWidget);
      expect(find.widgetWithText(TextField, _address), findsNothing);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make payment file'));
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
      expect(find.text('Open their reply'), findsOneWidget);

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
      await _tap(tester, find.text('Open their reply'));
      expect(find.textContaining('for a different payment'), findsOneWidget);
      expect(find.text('Finish payment'), findsNothing);
      // The error notice goes first, so the screen is back in its own place.
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(noticeProvider.notifier)
          .clear();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Waiting for their reply'), findsOneWidget);

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
      await _tap(tester, find.text('Open their reply'));
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
      // Back on Send, the tracker has moved on.
      await _tap(tester, find.widgetWithText(FilledButton, 'Done'));
      expect(find.text('Waiting for their reply'), findsNothing);
      expect(find.text('Their wallet signed'), findsOneWidget);
      expect(find.text('Open their reply'), findsNothing);
    });

    testWidgets('where files cannot be shared, only Save to device shows', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      h.files.canShare = false;
      await h.pump(tester, _sendTab());
      await _toFile(tester);
      await _enter(tester, 'Amount (EPIC)', '1');
      await _tap(tester, find.text('Make payment file'));
      expect(find.text('Save to device'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Share'), findsNothing);
    });

    testWidgets('by file: a pasted reply to another payment is refused', (
      tester,
    ) async {
      final h = _Harness();
      h.service.slateInfos['{"other":1}'] = SlateInfo(
        slateId: 'other',
        amount: _epic(9),
        fee: BigInt.one,
        stage: SlateStage.response,
      );
      await h.pump(tester, _sendTab());
      await _toFile(tester);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make payment file'));
      await _tap(tester, find.text('Copy and paste instead'));
      for (final (text, message) in [
        ('{"other":1}', 'for a different payment'),
        ('not a reply', 'not a transaction file'),
      ]) {
        await tester.enterText(
          find.descendant(
            of: find.byType(SlateInput),
            matching: find.byType(TextField),
          ),
          text,
        );
        await _tap(tester, find.text('Finish payment'));
        expect(find.textContaining(message), findsOneWidget, reason: text);
        expect(h.session.finalizedSlates, isEmpty, reason: text);
      }
      expect(find.text('Waiting for their reply'), findsOneWidget);
    });

    testWidgets('by file: paste the response instead', (tester) async {
      final h = _Harness(advanced: true);
      await h.pump(tester, _sendTab());
      await _toFile(tester);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make payment file'));
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
      expect(find.text('Their wallet signed'), findsOneWidget);
      expect(find.text('Sent to the network'), findsOneWidget);
      expect(find.text('Waiting for their reply'), findsNothing);
    });
  });

  group('contacts', () {
    testWidgets('add, search, edit and delete', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ContactsScreen());
      expect(find.textContaining('No contacts yet'), findsOneWidget);
      // Nothing to search yet: the empty state sits in the middle, without a search field.
      expect(find.widgetWithText(TextField, 'Name or address'), findsNothing);
      expect(find.byType(CenteredBody), findsOneWidget);

      await _tap(tester, find.text('Add contact'));
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Enter a name.'), findsOneWidget);
      expect(find.text('Enter their address.'), findsOneWidget);

      await _enter(tester, 'Name', 'Bob');
      await _enterAddress(tester, 'nonsense');
      await _tap(tester, find.text('Save contact'));
      expect(find.textContaining('Use an Epicbox address'), findsOneWidget);

      await _enterAddress(tester, ' $_bob ');
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Bob'), findsOneWidget);

      // With contacts, Add is the app bar's icon.
      await _tap(tester, find.byTooltip('Add contact'));
      await _enter(tester, 'Name', 'Carol');
      await _enterAddress(tester, _bob);
      expect(
        find.text('This address is already saved as Bob.'),
        findsOneWidget,
      );
      await _enterAddress(tester, _carol);
      expect(find.textContaining('already saved'), findsNothing);
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Carol'), findsOneWidget);

      await _enter(tester, 'Name or address', 'car');
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);
      await _enter(tester, 'Name or address', '');

      // A tap opens the contact's page; Edit opens the form.
      await _tap(tester, find.text('Bob'));
      await _tap(tester, find.byKey(contactPageEditKey));
      expect(find.text('Edit contact'), findsOneWidget);
      await _enter(tester, 'Name', 'Robert');
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Robert'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await _tap(tester, find.text('Robert'));
      await _tap(tester, find.byKey(contactPageMoreKey));
      await _tap(tester, find.byKey(contactPageDeleteKey));
      expect(find.text('Delete Robert?'), findsOneWidget);
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
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
      await h.open(tester, _receiveTab());

      await tester.tap(find.byTooltip('Share'));
      await _untilRendered(tester, () => h.files.gate != null);
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      expect(h.locked, isFalse);
      await h.finishTrip(tester);
      expect(h.container.read(autoLockHoldProvider), 0);
      expect(h.files.sharedImages.single.text, h.session.address);

      // The control: a minute locks an ordinary trip away.
      await h.awayAndBack(tester, const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(h.locked, isTrue);
    });

    testWidgets('a slow send does not lock, and its tracker stays', (
      tester,
    ) async {
      final h = _AppHarness();
      await h.pumpUnlocked(tester);
      await h.open(tester, _sendTab());
      await _toReview(tester);
      h.session.sendGate = Completer<void>();
      await tester.tap(find.text('Send 1 EPIC'));
      await tester.pumpAndSettle();
      await answerPin(tester, settle: false);
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      expect(h.locked, isFalse);
      h.session.sendGate!.complete();
      await tester.pumpAndSettle();
      expect(h.locked, isFalse);
      expect(find.text('Waiting for their wallet'), findsOneWidget);
      expect(h.container.read(autoLockHoldProvider), 0);
    });

    testWidgets('picking a transaction file does not lock', (tester) async {
      final h = _AppHarness(advanced: true);
      await h.pumpUnlocked(tester);
      await h.open(tester, _receiveTab());
      // The tab's label may break at its " · "; its tooltip keeps the whole name.
      await _tap(tester, find.descendant(of: find.byKey(receiveTabsKey), matching: find.byTooltip('Direct · File')));
      await _tap(tester, find.text('Open file'));
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      await h.finishTrip(tester);
      expect(h.locked, isFalse);
      expect(h.container.read(autoLockHoldProvider), 0);
    });

    testWidgets('sharing a send file does not lock', (tester) async {
      final h = _AppHarness(advanced: true);
      await h.pumpUnlocked(tester);
      await h.open(tester, _sendTab());
      await _toFile(tester);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make payment file'));
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
    testWidgets('file, pasted response: the same notice', (tester) async {
      final h = _Harness(advanced: true);
      h.session.notPosted = true;
      await h.pump(tester, _sendTab());
      await _toFile(tester);
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Make payment file'));
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

    test('a failed Tor send is not "Invalid input"', () {
      String say(WalletErrorKind kind, String message) => describeError(
        englishStrings,
        WalletError(kind: kind, message: message),
      );
      for (final message in [
        'tor did not connect in time',
        'tor is not available',
        '',
      ]) {
        expect(
          say(WalletErrorKind.torNotRunning, message),
          'Tor is not connected.',
        );
      }
      expect(
        say(WalletErrorKind.onionUnreachable, 'not reached'),
        'Their wallet was not reached over Tor.',
      );
      // A bad address still carries the core's sentence about it.
      expect(
        say(WalletErrorKind.onionAddressInvalid, 'the address has no host'),
        'Invalid input. the address has no host',
      );
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
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Amount (EPIC)'),
      );
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );

      await _enter(tester, 'Amount (EPIC)', '1,5');
      expect(find.text('Network fee 0.008 EPIC'), findsOneWidget);
      await _enter(tester, 'Amount (EPIC)', ' 12.5 EPIC ');
      expect(find.byType(LiveFieldError), findsNothing);
      await _tap(tester, _continue);
      expect(find.text('12.508 EPIC'), findsOneWidget);
      await _tap(tester, find.text('Edit'));
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
      await h.pump(tester, _sendTab());
      await _toAmount(tester);
      await _tap(tester, find.text('Use USD'));
      await _enter(tester, 'Amount (USD)', '10,50');
      expect(find.text('≈ 21 EPIC'), findsOneWidget);
      await _enter(tester, 'Amount (USD)', '1e5');
      expect(find.text('Enter an amount such as 10.50'), findsOneWidget);
    });

    testWidgets(
      'Next goes on from the address and the amount; Done on the note',
      (tester) async {
        final h = _Harness();
        await h.pump(tester, _sendTab());
        EditableText editable(String label) => tester.widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextField, label),
            matching: find.byType(EditableText),
          ),
        );

        await tester.tap(find.widgetWithText(TextField, _address));
        await tester.enterText(find.widgetWithText(TextField, _address), _bob);
        expect(editable(_address).textInputAction, TextInputAction.next);
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(editable('Amount (EPIC)').focusNode.hasFocus, isTrue);

        await tester.enterText(
          find.widgetWithText(TextField, 'Amount (EPIC)'),
          '1',
        );
        await tester.pump(const Duration(milliseconds: 500));
        // With the note folded, Next on the amount goes to the review.
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(find.text('3 of 3'), findsOneWidget);

        await _tap(tester, find.text('Edit'));
        await _tap(tester, find.text('Add a note'));
        expect(editable('Note').focusNode.hasFocus, isTrue);
        await tester.tap(find.widgetWithText(TextField, 'Amount (EPIC)'));
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();
        expect(editable('Note').focusNode.hasFocus, isTrue);
        expect(editable('Note').textInputAction, TextInputAction.done);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('3 of 3'), findsOneWidget);
      },
    );
  });

  group('accessibility', () {
    testWidgets('field errors are live regions', (tester) async {
      final handle = tester.ensureSemantics();
      final h = _Harness(advanced: true);
      await h.pump(tester, _sendTab());
      bool live(String text) => find
          .ancestor(
            of: find.text(text),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && (w.properties.liveRegion ?? false),
            ),
          )
          .evaluate()
          .isNotEmpty;
      await _enter(tester, _address, 'not an address!');
      await _tap(tester, _continue);
      expect(live('This is not an Epicbox address.'), isTrue);
      await _enter(tester, _address, _bob);
      await _tap(tester, _continue);
      await _enter(tester, 'Amount (EPIC)', '-1');
      expect(live('The amount cannot be negative.'), isTrue);
      handle.dispose();
    });

    for (final (name, screen) in [
      ('send', _sendTab()),
      ('receive', _receiveTab()),
      ('contacts', const ContactsScreen()),
      ('contact edit', const ContactEditScreen()),
      ('help', const HelpScreen(topic: HelpId.fees)),
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
      await h.pump(tester, _receiveTab());
      expect(
        tester.getSemantics(find.bySemanticsLabel('QR code of your address')),
        matchesSemantics(label: 'QR code of your address', isImage: true),
      );
      handle.dispose();
    });
  });

  group('help', () {
    testWidgets('receive links to help about receiving', (tester) async {
      final h = _Harness();
      await h.pump(tester, _receiveTab());
      await _tap(tester, find.text('How receiving works'));
      expect(find.byType(HelpTopicScreen), findsOneWidget);
      expect(find.text('Receive your first EPIC'), findsOneWidget);
    });

    testWidgets('the tracker links to "Send to someone"', (tester) async {
      final h = _Harness();
      await h.pump(tester, _sendTab());
      await _toReview(tester);
      await _tap(tester, find.text('Send 1 EPIC'));
      await _tap(tester, find.text('What if it never finishes?'));
      await _tap(tester, find.widgetWithText(TextButton, 'Help'));
      expect(find.byType(HelpTopicScreen), findsOneWidget);
      expect(find.text('Send to someone'), findsOneWidget);
    });
  });

  group('receive', () {
    testWidgets('a file shows the sender\'s message before it is accepted', (
      tester,
    ) async {
      final h = _Harness();
      const incoming = '{"id":"incoming"}';
      h.service.slateInfos[incoming] = SlateInfo(
        slateId: 'incoming',
        amount: _epic(3),
        fee: BigInt.zero,
        stage: SlateStage.send,
        messages: const [SlateMessage(role: SlateRole.sender, text: 'hi Bob')],
      );
      await h.pump(
        tester,
        const SlateFileScreen(
          file: SlateFile(name: 'from-alice.tx', json: incoming),
        ),
      );
      expect(find.text('Message from the sender'), findsOneWidget);
      expect(find.text('hi Bob'), findsOneWidget);
      expect(h.session.receivedSlates, isEmpty);
    });

    testWidgets('an answer shows the recipient\'s message, not ours', (
      tester,
    ) async {
      final h = _Harness();
      h.service.slateInfos[h.session.responseSlate.json] = SlateInfo(
        slateId: 'slate-2',
        amount: _epic(3),
        fee: _epic(0.008),
        stage: SlateStage.response,
        messages: const [
          SlateMessage(role: SlateRole.sender, text: 'ours'),
          SlateMessage(role: SlateRole.receiver, text: 'got it'),
        ],
      );
      await h.pump(
        tester,
        SlateFileScreen(
          file: SlateFile(
            name: 'pay.tx.response',
            json: h.session.responseSlate.json,
          ),
        ),
      );
      expect(find.text('Message from the recipient'), findsOneWidget);
      expect(find.text('got it'), findsOneWidget);
      expect(find.text('ours'), findsNothing);
    });

    testWidgets('a file without a message shows none', (tester) async {
      final h = _Harness();
      const incoming = '{"id":"incoming"}';
      h.service.slateInfos[incoming] = SlateInfo(
        slateId: 'incoming',
        amount: _epic(3),
        fee: BigInt.zero,
        stage: SlateStage.send,
      );
      await h.pump(
        tester,
        const SlateFileScreen(
          file: SlateFile(name: 'from-alice.tx', json: incoming),
        ),
      );
      expect(find.text('Someone is sending you 3 EPIC.'), findsOneWidget);
      expect(find.text('Message from the sender'), findsNothing);
    });

    testWidgets('a file accepted before says so and hands out the same answer', (
      tester,
    ) async {
      final h = _Harness();
      const incoming = '{"id":"incoming"}';
      h.service.slateInfos[incoming] = SlateInfo(
        slateId: 'incoming',
        amount: _epic(3),
        fee: BigInt.zero,
        stage: SlateStage.send,
      );
      // Accepted once already, as through the listener or an earlier open.
      await h.session.receiveSlate(slateJson: incoming);
      // Home's data stays watched, so a refresh would reload the transactions.
      await h.pump(
        tester,
        Consumer(
          builder: (context, ref, _) {
            ref.watch(homeProvider);
            return const SlateFileScreen(
              file: SlateFile(name: 'from-bob.tx', json: incoming),
            );
          },
        ),
      );
      final loads = h.session.transactionsCalls;
      await _tap(tester, find.text('Accept payment'));
      expect(h.session.receivedSlates, [incoming, incoming]);
      expect(h.session.transactionsCalls, loads);
      expect(
        find.text(
          'Already accepted. Return incoming.response to the sender again.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('not a second payment'), findsOneWidget);
      expect(find.textContaining('Accepted. Return'), findsNothing);
      await _tap(tester, find.text('Save to device'));
      expect(h.files.saved.single.name, 'incoming.response');
      expect(h.files.saved.single.json, h.session.responseSlate.json);
    });

    testWidgets('the file screen waits for the core; a request while Invoices is off says they are experimental', (
      tester,
    ) async {
      final h = _Harness();
      const invoice = '{"id":"invoice"}';
      h.service.slateInfos[invoice] = SlateInfo(
        slateId: 'invoice',
        amount: _epic(4),
        fee: BigInt.zero,
        stage: SlateStage.request,
      );
      final gate = h.service.inspectGate = Completer<void>();
      await h.pump(
        tester,
        const SlateFileScreen(
          file: SlateFile(name: 'bill.tx', json: invoice),
        ),
        settle: false,
      );
      expect(find.bySemanticsLabel('Reading the file'), findsOneWidget);
      expect(find.text('Accept payment'), findsNothing);
      expect(find.byType(ErrorText), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Reading the file'), findsNothing);
      expect(
        find.text('Invoices are experimental'),
        findsOneWidget,
      );
      expect(find.text('Accept payment'), findsNothing);
      expect(find.text('Finish payment'), findsNothing);
      expect(h.session.receivedSlates, isEmpty);
      expect(h.session.finalizedSlates, isEmpty);
    });
  });

  group('advanced options', () {
    testWidgets('send offers the file by default, Link with its switch in Settings › Transactions', (
      tester,
    ) async {
      final off = _Harness();
      await off.pump(tester, _sendTab());
      expect(find.text('Direct · File'), findsOneWidget);
      expect(find.text('Link'), findsNothing);
      expect(find.text('Other ways to send'), findsNothing);

      // A fresh tree, so the screen's state starts over.
      await tester.pumpWidget(const SizedBox());
      final on = _Harness(direct: true);
      await on.pump(tester, _sendTab());
      expect(find.text('Direct · File'), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);
      await _enter(tester, _address, 'http://203.0.113.5:3415');
      await _tap(tester, _continue);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(on.session.epicboxSends, isEmpty);
    });

    testWidgets('Smallest / All for one payment shows only with Send options', (
      tester,
    ) async {
      final off = _Harness();
      await off.pump(tester, _sendTab());
      await _toAmount(tester, null);
      expect(find.byKey(sendStrategyKey), findsNothing);

      await tester.pumpWidget(const SizedBox());
      final on = _Harness(advanced: true);
      await on.pump(tester, _sendTab());
      await _toAmount(tester, null);
      expect(find.byKey(sendStrategyKey), findsOneWidget);
      expect(find.text('Strategy for this send'), findsOneWidget);
      final picker = tester.widget<SegmentedButton<SelectionStrategy>>(
        find.byKey(sendStrategyKey),
      );
      expect(picker.selected, {SelectionStrategy.smallest});

      await _enter(tester, 'Amount (EPIC)', '1');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        on.session.estimateOptions.last?.strategy,
        isNot(SelectionStrategy.all),
      );
      await _tap(
        tester,
        find.descendant(
          of: find.byKey(sendStrategyKey),
          matching: find.text('All'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(on.session.estimateOptions.last?.strategy, SelectionStrategy.all);
      expect(
        tester
            .widget<SegmentedButton<SelectionStrategy>>(
              find.byKey(sendStrategyKey),
            )
            .selected,
        {SelectionStrategy.all},
      );
      // For this payment only: Settings keeps its default.
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(sendStrategyKey)),
      );
      expect(
        container.read(appSettingsProvider).value?.sendStrategy,
        isNot(SelectionStrategy.all),
      );
    });
  });
}
