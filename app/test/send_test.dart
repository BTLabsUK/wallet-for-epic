import 'dart:async';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/contacts.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/vault.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid address for [FakeWalletService.validateEpicboxAddress].
final String _bob = '${'b' * 52}@epicbox.epiccash.com';
final String _carol = '${'c' * 52}@epicbox.epicnet.us';

FakeWalletSession _funded() => FakeWalletSession(
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
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  void connectListener() => session.listenerEvents.add(
    const ListenerEvent(kind: ListenerEventKind.connected, message: 'a'),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
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
  Future<bool> export({required String name, required String json}) async {
    await _wait();
    return super.export(name: name, json: json);
  }

  @override
  Future<SlateFile?> pick() async {
    await _wait();
    return super.pick();
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
      expect(checkRecipient(service, ''), contains('Enter an epicbox'));
      expect(checkRecipient(service, 'esBare'), contains('not a valid'));
      expect(checkRecipient(service, 'http://'), contains('full wallet URL'));
      expect(checkRecipient(service, _bob), isNull);
      expect(checkRecipient(service, 'http://203.0.113.5:3415'), isNull);
    });
  });

  group('send', () {
    testWidgets('epicbox: review, send, result, then save to contacts', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      expect(find.text('Spendable: 40 EPIC'), findsOneWidget);
      expect(find.textContaining('Not connected to the relay'), findsOneWidget);
      h.connectListener();
      await tester.pumpAndSettle();
      expect(find.textContaining('Not connected to the relay'), findsNothing);

      await _enter(tester, 'To', 'esBare');
      await _enter(tester, 'Amount (EPIC)', '1.5');
      expect(find.text('Fee: 0.008 EPIC. Total: 1.508 EPIC.'), findsOneWidget);
      await _tap(tester, find.text('Review'));
      expect(
        find.textContaining('not a valid epicbox address'),
        findsOneWidget,
      );
      expect(find.text('Review your payment'), findsNothing);

      await _enter(tester, 'To', _bob);
      await _enter(tester, 'Note (optional)', 'Lunch');
      await _tap(tester, find.text('Review'));
      expect(find.text('Review your payment'), findsOneWidget);
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
      expect(find.text('Sent.'), findsOneWidget);
      expect(
        find.text(
          'The payment completes when the recipient\'s wallet is online; '
          'keep this app open or reopen it later to finish.',
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
        find.text('Sent straight to the recipient\'s wallet.'),
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
      expect(
        find.text('Sent 2 EPIC. The payment is complete.'),
        findsOneWidget,
      );
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
      expect(find.text('20 EPIC (≈ 10.00 USD)'), findsOneWidget);
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
        find.descendant(of: sheet, matching: find.text(_carol)),
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
      expect(h.files.exported.single.name, 'slate-1.tx');
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
      expect(
        find.textContaining('for a different transaction'),
        findsOneWidget,
      );
      expect(find.text('Finalize and post'), findsNothing);
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
      await _tap(tester, find.text('Finalize and post'));
      expect(h.session.finalizedSlates, [h.session.responseSlate.json]);
      expect(find.text('Transaction of 1.5 EPIC posted.'), findsOneWidget);
    });

    testWidgets('by file: paste the response instead', (tester) async {
      final h = _Harness();
      await h.pump(tester, const SendScreen());
      await _tap(tester, find.text('Other ways to send'));
      await _tap(tester, find.text('Send by transaction file'));
      await _enter(tester, 'Amount (EPIC)', '1.5');
      await _tap(tester, find.text('Create transaction file'));
      await _tap(tester, find.text('Copy and paste instead'));
      await _tap(tester, find.text('Finalize and post'));
      expect(
        find.text('Paste the response slate from the recipient.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(SlateInput),
          matching: find.byType(TextField),
        ),
        h.session.responseSlate.json,
      );
      await _tap(tester, find.text('Finalize and post'));
      expect(h.session.finalizedSlates, [h.session.responseSlate.json]);
      expect(find.textContaining('The payment is complete.'), findsOneWidget);
    });
  });

  group('contacts', () {
    testWidgets('add, search, edit and delete', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ContactsScreen());
      expect(find.textContaining('No contacts yet'), findsOneWidget);

      await _tap(tester, find.text('Add contact'));
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Enter a name.'), findsOneWidget);
      expect(
        find.text('Enter an epicbox address or wallet URL.'),
        findsOneWidget,
      );

      await _enter(tester, 'Name', 'Bob');
      await _enter(tester, 'Epicbox address or wallet URL', 'nonsense');
      await _tap(tester, find.text('Save contact'));
      expect(
        find.textContaining('not a valid epicbox address'),
        findsOneWidget,
      );

      await _enter(tester, 'Epicbox address or wallet URL', ' $_bob ');
      await _tap(tester, find.text('Save contact'));
      expect(find.text('Bob'), findsOneWidget);

      await _tap(tester, find.text('Add contact'));
      await _enter(tester, 'Name', 'Carol');
      await _enter(tester, 'Epicbox address or wallet URL', _bob);
      expect(
        find.text('This address is already saved as Bob.'),
        findsOneWidget,
      );
      await _enter(tester, 'Epicbox address or wallet URL', _carol);
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
      expect(h.container.read(autoLockHoldProvider), 1);
      await h.awayAndBack(tester, const Duration(minutes: 10));
      await h.finishTrip(tester);
      expect(h.locked, isFalse);
      expect(h.files.exported.single.name, 'slate-1.tx');
      expect(h.container.read(autoLockHoldProvider), 0);
    });
  });

  group('help', () {
    testWidgets('every question expands to its answer', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HelpScreen());
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
      const answer = 'Epicbox is a mailbox service';
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
      expect(find.textContaining('after 10 confirmations'), findsOneWidget);
    });

    testWidgets('a topic opens expanded', (tester) async {
      final h = _Harness();
      await h.pump(
        tester,
        const HelpScreen(topic: HelpTopic.historyAfterRestore),
      );
      expect(find.textContaining('import it in Settings'), findsOneWidget);
      expect(find.textContaining('Epicbox is a mailbox service'), findsNothing);
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
      expect(
        find.textContaining('Epicbox is a mailbox service'),
        findsOneWidget,
      );
    });
  });

  group('receive', () {
    testWidgets('QR, copy, share, listening state and the file section', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveScreen());
      expect(find.text(h.session.address), findsOneWidget);
      expect(
        find.bySemanticsLabel('QR code of your epicbox address'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Keep the app open to receive. Payments sent while it is closed '
          'arrive the next time you unlock.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Connecting to the epicbox relay'),
        findsOneWidget,
      );
      h.connectListener();
      await tester.pumpAndSettle();
      expect(
        find.text('Listening for payments on the relay epicbox.epiccash.com.'),
        findsOneWidget,
      );

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
      await _tap(tester, find.text('Sign and share response'));
      expect(h.session.receivedSlates, [incoming]);
      expect(h.files.exported.single.name, 'from-bob.tx.response');
      expect(h.files.exported.single.json, h.session.responseSlate.json);
      expect(
        find.text('Signed. Return from-bob.tx.response to the sender.'),
        findsOneWidget,
      );
    });

    testWidgets('paste slate text as a fallback', (tester) async {
      final h = _Harness();
      await h.pump(tester, const ReceiveScreen());
      await _tap(tester, find.text('Receive a transaction file'));
      await _tap(tester, find.text('Paste slate text instead'));
      await _tap(tester, find.text('Sign slate'));
      expect(find.text('Paste the slate you received.'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(SlateInput),
          matching: find.byType(TextField),
        ),
        '{"id":"incoming"}',
      );
      await _tap(tester, find.text('Sign slate'));
      expect(h.session.receivedSlates, ['{"id":"incoming"}']);
      expect(find.text(h.session.responseSlate.json), findsOneWidget);
    });
  });
}
