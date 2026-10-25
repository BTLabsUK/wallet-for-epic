// The phone's way in for `epic:` payment codes (docs/feedback/designs/epic-uri/ui.md §1–§8):
// Home's scan, the Send field's paste, and links from other apps, through the scan router to
// Send prefilled (banner, amount marker, unverified payee block, origin on the review) or to
// a sheet that says why not. Nothing is ever sent without the review and the PIN.

import 'dart:async';

import 'package:epic_wallet/src/demo.dart' show demoModeProvider;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/scan/incoming_link.dart';
import 'package:epic_wallet/src/scan/scan_router.dart' show maxUriAddressLength;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/method_art.dart';
import 'package:epic_wallet/src/ui/payment_code_ui.dart';
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/ui/qr_scan_screen.dart';
import 'package:epic_wallet/src/ui/scan_result_sheet.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/send_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/send_pin.dart';

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';

/// A valid Epicbox address (E of the spec's §2.5).
const _e = '$_key@epicbox.epiccash.com';

/// Another valid Epicbox address.
final String _other = 'es${'x' * 50}@epicbox.epiccash.com';

/// An Epicbox address of the other network, as [_OtherChainService] tells it.
const _floonet =
    'fsWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.epiccash.com';

/// A Direct HTTP address.
const _d = 'http://1.2.3.4:3415';

const _lunch = 'epic:$_e?amount=1.5&message=Lunch%20with%20Anna&label=Anna';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final DateTime _now = DateTime(2026, 9, 30, 12);

WalletSummary _summary() => WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.from(3),
  total: _epic(12.5),
  spendable: _epic(12.5),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

/// [_floonet] is valid on the other network only.
class _OtherChainService extends FakeWalletService {
  _OtherChainService({super.session});

  @override
  bool validateEpicboxAddress({required String address}) =>
      address != _floonet && super.validateEpicboxAddress(address: address);

  @override
  bool epicboxAddressOtherChain({required String address}) =>
      address == _floonet;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoPush implements PushPlatform {
  @override
  Future<bool> start() async => true;

  @override
  Future<bool> configured() async => true;

  @override
  Future<String?> token() async => 'token';

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

class _NoUpdates extends UpdateNotifier {
  @override
  Future<void> install() async {}
}

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  _Config(this.config);

  final WalletConfig config;

  @override
  WalletConfig? build() => config;
}

class _Harness {
  _Harness({bool otherChain = false}) {
    store.values['wallet.mainnet.backedUp'] = '1';
    store.values['app.history_reminder_first_seen.mainnet'] =
        '${_now.millisecondsSinceEpoch ~/ 1000}';
    store.values['app.payment_prefs'] = PaymentPrefs.phoneDefaults
        .copyWith(linkHttp: true, linkTor: true)
        .encode();
    service = otherChain
        ? _OtherChainService(session: session)
        : FakeWalletService(session: session);
    allowPinCheck(session, service);
  }

  final session = FakeWalletSession(summary: _summary(), transactions: []);
  final store = sendPinStore();
  final scanner = FakeQrScanner(supported: true);
  final camera = FakeQrCamera();
  late final FakeWalletService service;

  /// Shows home once true; before, a stand-in for the lock screen.
  final unlocked = ValueNotifier<bool>(true);
  late ProviderContainer container;

  /// Texts written to the clipboard, and the text it gives back.
  final List<String> copied = [];
  String? clipboard;

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1080, 7200),
    Locale? locale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        if (call.method == 'Clipboard.getData') return {'text': clipboard};
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          updateProvider.overrideWith(_NoUpdates.new),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(scanner),
          qrCameraFactoryProvider.overrideWithValue(() => camera),
          pushPlatformProvider.overrideWithValue(_NoPush()),
          historyFilesProvider.overrideWithValue(
            FakeHistoryFiles()..canShare = false,
          ),
          clockProvider.overrideWithValue(() => _now),
          demoModeProvider.overrideWithValue(false),
          phonePaymentsProvider.overrideWithValue(true),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          walletConfigProvider.overrideWith(
            () => _Config(
              mainnetPreset.config(
                dataDir: '/fake/wallets/mainnet',
                nodeUrl: 'https://node',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            // Reduced motion: pulses and spinners would never settle.
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: ValueListenableBuilder<bool>(
            valueListenable: unlocked,
            builder: (_, open, _) => open
                ? const HomeScreen()
                : const Scaffold(body: Text('locked')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
  }

  /// Home's scan button, with [text] as what the camera reads.
  Future<void> scan(WidgetTester tester, String text) async {
    scanner.codes.add(text);
    await _tap(tester, find.byTooltip('Scan a QR code to send'));
  }
}

/// Scrolls to [finder] when it is out of sight, then taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (!tester.any(finder.hitTestable())) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _field(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;

ShellTab _tab(WidgetTester tester) =>
    ShellTab.values[tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .selectedIndex];

TransferMethod _method(WidgetTester tester) => tester
    .widget<SegmentedButton<TransferMethod>>(find.byKey(sendMethodsKey))
    .selected
    .single;

Finder _inBanner(String text) => find.descendant(
  of: find.byKey(sendRequestBannerKey),
  matching: find.text(text),
);

Finder _inPayee(String text) =>
    find.descendant(of: find.byKey(payeeClaimsKey), matching: find.text(text));

/// The folded note tile's subtitle.
Finder _noteTile(String note) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(note));

/// Whether Send is on the amount step (its amount field is built).
bool _onAmount() => find.byKey(sendAmountFieldKey).evaluate().isNotEmpty;

Future<void> _continue(WidgetTester tester) =>
    _tap(tester, find.widgetWithText(FilledButton, 'Continue'));

Future<void> _back(WidgetTester tester) =>
    _tap(tester, find.byTooltip('Back').first);

/// The review's origin pill says [text].
Finder _origin(String text) => find.descendant(
  of: find.byKey(sendOriginPillKey),
  matching: find.text(text),
);

void main() {
  group('Home scan of a payment code', () {
    testWidgets('fills Send and stops at the amount step, nothing sent', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _lunch);

      expect(_tab(tester), ShellTab.send);
      expect(find.byType(SendView), findsOneWidget);
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), '1.5');
      expect(_inBanner('Payment request'), findsOneWidget);
      expect(_inBanner('Check the amount, then continue.'), findsOneWidget);
      expect(find.text('Requested by the code'), findsOneWidget);
      // The note travels in the payment: its tile is folded and shows it.
      expect(_noteTile('Lunch with Anna'), findsOneWidget);
      expect(_inPayee('Anna'), findsOneWidget);
      expect(_inPayee('Lunch with Anna'), findsOneWidget);
      expect(
        _inPayee('Name given by the payee (not verified)'),
        findsOneWidget,
      );
      expect(h.session.epicboxSends, isEmpty);
      expect(h.session.sentAmounts, isEmpty);
    });

    testWidgets('the review shows where it came from; the send asks the PIN', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await _continue(tester);

      expect(_origin('From a QR code'), findsOneWidget);
      expect(tester.widget<AddressEnds>(find.byType(AddressEnds)).address, _e);
      expect(_inPayee('Anna'), findsOneWidget);
      expect(_inPayee('Lunch with Anna'), findsOneWidget);

      await _tap(tester, find.textContaining('Send 1.5'));
      expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
      expect(h.session.epicboxSends, isEmpty);
      await answerPin(tester);
      expect(h.session.epicboxSends.single.amount, _epic(1.5));
      expect(h.session.epicboxSends.single.to, _e);
      expect(h.session.sentMessages.last, 'Lunch with Anna');
    });

    testWidgets('the amount is written in the user\'s number format', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, locale: const Locale('pl'));
      h.scanner.codes.add(_lunch);
      await _tap(tester, find.byIcon(Icons.qr_code_scanner).first);
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), '1,5');
    });
  });

  group('what the code got wrong', () {
    for (final amount in ['0', '1,5']) {
      testWidgets('amount=$amount is dropped and said so', (tester) async {
        final h = _Harness();
        await h.pump(tester);
        await h.scan(tester, 'epic:$_e?amount=$amount&label=Anna');
        expect(_onAmount(), isTrue);
        expect(
          _inBanner('The amount in this code is not valid and was ignored.'),
          findsOneWidget,
        );
        expect(_field(tester, sendAmountFieldKey), isEmpty);
      });
    }

    testWidgets('a too large amount is dropped and said so', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, 'epic:$_e?amount=21000000001');
      expect(
        _inBanner('The amount in this code is too large and was ignored.'),
        findsOneWidget,
      );
      expect(_field(tester, sendAmountFieldKey), isEmpty);
    });

    testWidgets('a note past the signed limit shows whole, only in the block', (
      tester,
    ) async {
      // 100 Thai letters: 300 bytes, past the 256 a payment signs, but under 264 characters.
      final note = 'ก' * 100;
      final h = _Harness();
      await h.pump(tester);
      await h.scan(
        tester,
        'epic:$_e?amount=1&message=${Uri.encodeComponent(note)}',
      );
      expect(_onAmount(), isTrue);
      expect(find.text('Add a note'), findsOneWidget);
      expect(_noteTile(note), findsNothing);
      expect(_inPayee(note), findsOneWidget);
      await _tap(tester, find.text('Add a note'));
      expect(_field(tester, sendNoteFieldKey), isEmpty);
    });
  });

  group('editing what the code filled in', () {
    testWidgets('× closes only the banner', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await _tap(tester, find.byKey(sendRequestDismissKey));
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      expect(_field(tester, sendAmountFieldKey), '1.5');
      expect(find.text('Requested by the code'), findsOneWidget);
      expect(find.byKey(payeeClaimsKey), findsOneWidget);
      expect(_noteTile('Lunch with Anna'), findsOneWidget);
    });

    testWidgets('a changed amount says what the code asked for', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await tester.enterText(find.byKey(sendAmountFieldKey), '2');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Requested by the code'), findsNothing);
      expect(find.textContaining('The code asked for 1.5'), findsOneWidget);
    });

    testWidgets('another address clears the untouched amount, note and block', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await _back(tester);
      expect(find.byKey(payeeClaimsKey), findsOneWidget);
      await tester.enterText(find.byKey(sendRecipientFieldKey), _other);
      await tester.pumpAndSettle();
      expect(find.byKey(payeeClaimsKey), findsNothing);
      await _continue(tester);
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), isEmpty);
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      expect(find.text('Add a note'), findsOneWidget);
    });

    testWidgets('an edited amount stays when the address changes', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await tester.enterText(find.byKey(sendAmountFieldKey), '2');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await _back(tester);
      await tester.enterText(find.byKey(sendRecipientFieldKey), _other);
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(_field(tester, sendAmountFieldKey), '2');
    });
  });

  group('the code\'s name and saved contacts', () {
    testWidgets('a contact of that name at the address hides the name line', (
      tester,
    ) async {
      final h = _Harness();
      h.session.contactsValue.add(
        const Contact(id: 'c1', name: 'anna', address: _e),
      );
      await h.pump(tester);
      await h.scan(tester, 'epic:$_e?amount=1&message=Hi&label=%20ANNA%20');
      await _back(tester);
      // The contact's own name on the card; the code's name line hidden, its note kept.
      expect(
        find.descendant(
          of: find.byType(RecipientCard),
          matching: find.text('anna'),
        ),
        findsOneWidget,
      );
      expect(_inPayee('Name given by the payee (not verified)'), findsNothing);
      expect(_inPayee('Hi'), findsOneWidget);
      expect(_field(tester, sendRecipientFieldKey), _e);
    });

    testWidgets('a contact of that name elsewhere is not picked', (
      tester,
    ) async {
      final h = _Harness();
      h.session.contactsValue.add(
        Contact(id: 'c1', name: 'Anna', address: _other),
      );
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await _back(tester);
      expect(_field(tester, sendRecipientFieldKey), _e);
      expect(
        find.descendant(
          of: find.byType(RecipientCard),
          matching: find.text('New recipient'),
        ),
        findsOneWidget,
      );
      expect(_inPayee('Anna'), findsOneWidget);
    });

    testWidgets('a contact under another name keeps its name on the card', (
      tester,
    ) async {
      final h = _Harness();
      h.session.contactsValue.add(
        const Contact(id: 'c1', name: 'Bob', address: _e),
      );
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await _back(tester);
      expect(
        find.descendant(
          of: find.byType(RecipientCard),
          matching: find.text('Bob'),
        ),
        findsOneWidget,
      );
      expect(_inPayee('Anna'), findsOneWidget);
    });
  });

  group('Home scan of other codes', () {
    testWidgets('a bare address fills the recipient, origin on the review', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _e);
      expect(_tab(tester), ShellTab.send);
      expect(_onAmount(), isFalse);
      expect(_field(tester, sendRecipientFieldKey), _e);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      await _continue(tester);
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      await tester.enterText(find.byKey(sendAmountFieldKey), '1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(_origin('From a QR code'), findsOneWidget);
    });

    testWidgets('a Link address selects Link Payment', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _d);
      expect(_field(tester, sendRecipientFieldKey), _d);
      expect(_method(tester), TransferMethod.direct);
    });

    testWidgets('a QR Payment part opens the payment reader with it', (
      tester,
    ) async {
      const part = 'UR:EPIC-SLATE/1-3/LPADCFAXHD';
      final h = _Harness();
      await h.pump(tester);
      h.scanner.codes.add(part);
      await tester.tap(find.byTooltip('Scan a QR code to send'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      final reader = tester.widget<QrScanScreen>(find.byType(QrScanScreen));
      expect(reader.kind, QrScanKind.payment);
      expect(reader.first, part);
    });

    testWidgets('unknown text: a cut preview, Copy copies it all', (
      tester,
    ) async {
      final text = 'https://example.com/pay?${'a' * 120}';
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, text);
      expect(find.byKey(scanResultSheetKey), findsOneWidget);
      expect(find.text('Not an Epic code'), findsOneWidget);
      expect(
        find.text('${String.fromCharCodes(text.runes.take(80))}…'),
        findsOneWidget,
      );
      expect(find.text('Scan again'), findsOneWidget);
      await _tap(tester, find.byKey(scanResultCopyKey));
      expect(h.copied, [text]);
      expect(find.byKey(scanResultSheetKey), findsNothing);
      expect(_tab(tester), ShellTab.wallet);
    });

    testWidgets('Scan again opens the scanner again', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.scanner.codes.addAll(['hello there', _e]);
      await _tap(tester, find.byTooltip('Scan a QR code to send'));
      expect(find.byKey(scanResultSheetKey), findsOneWidget);
      await _tap(tester, find.byKey(scanResultPrimaryKey));
      expect(h.scanner.codes, isEmpty);
      expect(_tab(tester), ShellTab.send);
      expect(_field(tester, sendRecipientFieldKey), _e);
    });

    testWidgets('an address of the other network gets its sheet', (
      tester,
    ) async {
      final h = _Harness(otherChain: true);
      await h.pump(tester);
      await h.scan(tester, 'epic:$_floonet?amount=1');
      expect(find.text('Other network'), findsOneWidget);
      expect(find.text(_floonet), findsOneWidget);
      expect(_tab(tester), ShellTab.wallet);
    });

    testWidgets('a transaction file\'s text opens in the File flow', (
      tester,
    ) async {
      const json = '{"ver":"4:3","id":"x"}';
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, json);
      expect(find.text('Transaction file'), findsOneWidget);
      expect(
        find.text('This is the text of a transaction file, not an address.'),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Open'));
      expect(find.byType(SlateFileScreen), findsOneWidget);
    });

    testWidgets('a pairing link says pairing is not here yet', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, 'epiccash://pair/1/abc');
      expect(find.text('Pairing link'), findsOneWidget);
      expect(
        find.text('Pairing is not available in this version.'),
        findsOneWidget,
      );
    });
  });

  group('a Send tab kept alive', () {
    testWidgets('an address scanned after Send was opened keeps its origin', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text('Send').last);
      await _tap(tester, find.text('Wallet').last);
      await h.scan(tester, _e);
      expect(_tab(tester), ShellTab.send);
      expect(_field(tester, sendRecipientFieldKey), _e);
      await _continue(tester);
      await tester.enterText(find.byKey(sendAmountFieldKey), '1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(_origin('From a QR code'), findsOneWidget);
    });

    testWidgets('a second code without an amount drops the first one\'s', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, 'epic:$_e?amount=5&message=Table%204');
      expect(_field(tester, sendAmountFieldKey), '5');
      await _tap(tester, find.text('Wallet').last);
      await h.scan(tester, 'epic:$_e?label=Bob');
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), isEmpty);
      expect(_noteTile('Table 4'), findsNothing);
      expect(_inPayee('Bob'), findsOneWidget);
    });
  });

  group('Send field paste', () {
    Future<void> paste(WidgetTester tester, _Harness h, String text) async {
      await _tap(
        tester,
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Send'),
        ),
      );
      h.clipboard = text;
      await _tap(tester, find.widgetWithText(TextButton, 'Paste'));
    }

    testWidgets('a payment code fills the form, origin Pasted', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await paste(tester, h, _lunch);
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), '1.5');
      expect(_inBanner('Payment request'), findsOneWidget);
      expect(_inPayee('Lunch with Anna'), findsOneWidget);
      await _continue(tester);
      expect(_origin('Pasted'), findsOneWidget);
      expect(h.session.epicboxSends, isEmpty);
    });

    testWidgets('a code with a bad address stays in the field, said so', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await paste(tester, h, 'epic:notanaddress');
      expect(_field(tester, sendRecipientFieldKey), 'epic:notanaddress');
      expect(
        find.text('The address in this code is not valid.'),
        findsOneWidget,
      );
      expect(find.byKey(scanResultSheetKey), findsNothing);
    });

    testWidgets('half an address keeps today\'s check', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      final half = _key.substring(0, 20);
      await paste(tester, h, half);
      expect(_field(tester, sendRecipientFieldKey), half);
      expect(find.byKey(scanResultSheetKey), findsNothing);
      expect(find.text('The address in this code is not valid.'), findsNothing);
      expect(find.byKey(sendRequestBannerKey), findsNothing);
    });
  });

  group('payment links', () {
    testWidgets('over home: Send prefilled, origin link', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.container.read(incomingLinkProvider.notifier).deliver(_lunch);
      await tester.pumpAndSettle();
      expect(_tab(tester), ShellTab.send);
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), '1.5');
      expect(_inBanner('Payment request'), findsOneWidget);
      await _continue(tester);
      expect(_origin('From a link'), findsOneWidget);
    });

    testWidgets('under another screen: a notice, Open fills Send', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      unawaited(
        Navigator.of(tester.element(find.byType(HomeScreen))).push(
          MaterialPageRoute<void>(
            builder: (_) => const SlotScaffold(body: Text('another screen')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      h.container.read(incomingLinkProvider.notifier).deliver(_lunch);
      await tester.pumpAndSettle();
      // Nothing closed.
      expect(find.text('another screen'), findsOneWidget);
      expect(find.text('Payment link received'), findsOneWidget);
      await _tap(
        tester,
        find.descendant(of: find.byKey(noticeKey), matching: find.text('Open')),
      );
      expect(find.text('another screen'), findsNothing);
      expect(_tab(tester), ShellTab.send);
      expect(_field(tester, sendAmountFieldKey), '1.5');
    });

    testWidgets('while busy: dropped, said so', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.container.read(linkBusyProvider.notifier).set(true);
      h.container.read(incomingLinkProvider.notifier).deliver(_lunch);
      await tester.pumpAndSettle();
      expect(find.text('Finish the current payment first.'), findsOneWidget);
      expect(_tab(tester), ShellTab.wallet);
      expect(h.container.read(incomingLinkProvider), isNull);
      expect(h.container.read(sendRecipientProvider), isNull);
    });

    testWidgets('before unlock: opened once home shows', (tester) async {
      final h = _Harness()..unlocked.value = false;
      await h.pump(tester);
      expect(find.text('locked'), findsOneWidget);
      h.container.read(incomingLinkProvider.notifier).deliver(_lunch);
      await tester.pumpAndSettle();
      expect(find.text('locked'), findsOneWidget);
      h.unlocked.value = true;
      await tester.pumpAndSettle();
      expect(_tab(tester), ShellTab.send);
      expect(_field(tester, sendAmountFieldKey), '1.5');
      expect(h.container.read(incomingLinkProvider), isNull);
    });
  });

  testWidgets(
    'a 255-character Direct code and a 264-character note fit 360 dp',
    (tester) async {
      const base = '$_d/';
      final url = '$base${'p' * (maxUriAddressLength - base.length)}';
      expect(url.length, maxUriAddressLength);
      final note = 'n' * 264;
      final h = _Harness();
      await h.pump(tester, size: const Size(1080, 2400));
      await h.scan(tester, 'epic:$url?amount=1&message=$note');
      expect(tester.takeException(), isNull);
      expect(_onAmount(), isTrue);
      expect(_inPayee(note), findsOneWidget);
      await _continue(tester);
      expect(tester.takeException(), isNull);
      expect(_origin('From a QR code'), findsOneWidget);
      final host = find.text('1.2.3.4:3415');
      await tester.ensureVisible(host);
      await tester.pumpAndSettle();
      expect(host.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
