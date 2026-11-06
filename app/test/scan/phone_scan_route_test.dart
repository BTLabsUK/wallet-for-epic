// SPDX-License-Identifier: Apache-2.0
// The phone's way in for `epic:` payment codes:
// Home's scan, the Send field's paste, and links from other apps, through the scan router to
// Send prefilled (banner, amount marker, unverified payee block, origin on the review) or to
// a sheet that says why not. Nothing is ever sent without the review and the PIN.

import 'dart:async';

import 'package:epic_wallet/src/invite_links.dart'
    show InviteKind, InviteLink, clearInviteHandlers, inviteInboxProvider, inviteShareText, registerInviteHandler;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/scan/incoming_link.dart';
import 'package:epic_wallet/src/scan/scan_router.dart' show maxUriAddressLength;
import 'package:epic_wallet/src/scan/scan_text.dart' show directHostBesideOf;
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_services.dart';
import '../support/send_pin.dart';

final _l = englishStrings;

const _key = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK';

/// A valid Epicbox address (the one the epic: URI examples use).
const _e = '$_key@box.epic.invalid';

/// Another valid Epicbox address.
final String _other = 'es${'x' * 50}@box.epic.invalid';

/// An Epicbox address of the other network, as [_OtherChainService] tells it.
const _floonet =
    'fsWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@box.epic.invalid';

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
  _Harness({bool otherChain = false, bool pairing = true}) {
    store.values['wallet.mainnet.backedUp'] = '1';
    // Pairing and Invoices (Settings › Advanced › Experimental) are off by default.
    if (pairing) store.values['app.advanced_prefs'] = 'invoices,pairing|standard';
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
          torBundleFinderProvider.overrideWithValue(
            () async => const TorBundle(binary: '/data/app/lib/arm64/libtor.so'),
          ),
          networkChangesProvider.overrideWithValue(const Stream<bool>.empty()),
          phoneTorTimingProvider.overrideWithValue(
            PhoneTorTiming(
              backoff: [Duration(hours: 1)],
              sendWait: Duration(hours: 1),
            ),
          ),
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          updateProvider.overrideWith(_NoUpdates.new),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(scanner),
          qrCameraFactoryProvider.overrideWithValue(() => camera),
          historyFilesProvider.overrideWithValue(
            FakeHistoryFiles()..canShare = false,
          ),
          clockProvider.overrideWithValue(() => _now),
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
    await _tap(tester, find.byTooltip(_l.scanQrTooltip));
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

Finder _inBanner(String text) => find.descendant(
  of: find.byKey(sendRequestBannerKey),
  matching: find.text(text),
);

/// The folded note tile's subtitle.
Finder _noteTile(String note) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(note));

/// Whether Send is on the amount step (its amount field is built).
bool _onAmount() => find.byKey(sendAmountFieldKey).evaluate().isNotEmpty;

Future<void> _continue(WidgetTester tester) =>
    _tap(tester, find.widgetWithText(FilledButton, _l.commonContinue));

Future<void> _back(WidgetTester tester) =>
    _tap(tester, find.byTooltip(_l.scanQrBack).first);

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
      // A normal send: no Invoice card, no "Message from the recipient" card, no name line.
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      expect(find.text(_l.sendRequestTitle), findsNothing);
      expect(find.text('Invoice'), findsNothing);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      expect(find.text(_l.payeeNoteLabel), findsNothing);
      expect(find.text('Anna'), findsNothing);
      expect(find.text(_l.sendAmountFromCode), findsOneWidget);
      // The note travels in the payment: its tile is folded and shows it.
      expect(_noteTile('Lunch with Anna'), findsOneWidget);
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

      expect(_origin(_l.sendOriginQr), findsOneWidget);
      expect(tester.widget<AddressEnds>(find.byType(AddressEnds)).address, _e);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      expect(find.text('Invoice'), findsNothing);

      await _tap(tester, find.textContaining('Send 1.5'));
      expect(find.widgetWithText(TextField, _l.pinLabel), findsOneWidget);
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
      expect(find.text(_l.sendAddNote), findsOneWidget);
      expect(_noteTile(note), findsNothing);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      await _tap(tester, find.text(_l.sendAddNote));
      expect(_field(tester, sendNoteFieldKey), isEmpty);
    });
  });

  group('editing what the code filled in', () {
    testWidgets('× closes only the dropped-parts notice', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, 'epic:$_e?amount=1.5&message=Lunch%20with%20Anna&min=zero');
      expect(find.byKey(sendRequestBannerKey), findsOneWidget);
      await _tap(tester, find.byKey(sendRequestDismissKey));
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      expect(_field(tester, sendAmountFieldKey), '1.5');
      expect(find.text(_l.sendAmountFromCode), findsOneWidget);
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
      expect(find.text(_l.sendAmountFromCode), findsNothing);
      expect(find.textContaining('The code asked for 1.5'), findsOneWidget);
    });

    testWidgets('another address clears the untouched amount, note and block', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _lunch);
      await _back(tester);
      await tester.enterText(find.byKey(sendRecipientFieldKey), _other);
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), isEmpty);
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      expect(find.text(_l.sendAddNote), findsOneWidget);
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
    testWidgets('the name is shown nowhere; a saved contact keeps its own name', (
      tester,
    ) async {
      final h = _Harness();
      h.session.contactsValue.add(
        Contact(id: 'c1', name: 'Bob', address: _e),
      );
      await h.pump(tester);
      await h.scan(tester, _lunch);
      expect(find.text('To Bob'), findsOneWidget);
      expect(find.text('Anna'), findsNothing);
      await _back(tester);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      expect(find.text('Anna'), findsNothing);
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
      // Not a saved contact at this address: it can be saved.
      expect(find.text(_l.sendSaveContact), findsOneWidget);
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
      expect(_origin(_l.sendOriginQr), findsOneWidget);
    });

    testWidgets('a Link address selects Link', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _d);
      expect(_field(tester, sendRecipientFieldKey), _d);
      // The method line names the way the address picks.
      expect(find.text(_l.methodDirectHttp), findsOneWidget);
    });

    testWidgets('a QR Payment part opens the payment reader with it', (
      tester,
    ) async {
      const part = 'UR:EPIC-SLATE/1-3/LPADCFAXHD';
      final h = _Harness();
      await h.pump(tester);
      h.scanner.codes.add(part);
      await tester.tap(find.byTooltip(_l.scanQrTooltip));
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
      expect(find.text(_l.scanNotEpicTitle), findsOneWidget);
      expect(
        find.text('${String.fromCharCodes(text.runes.take(80))}…'),
        findsOneWidget,
      );
      expect(find.text(_l.qrScanAgain), findsOneWidget);
      await _tap(tester, find.byKey(scanResultCopyKey));
      expect(h.copied, [text]);
      expect(find.byKey(scanResultSheetKey), findsNothing);
      expect(_tab(tester), ShellTab.wallet);
    });

    testWidgets('Scan again opens the scanner again', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.scanner.codes.addAll(['hello there', _e]);
      await _tap(tester, find.byTooltip(_l.scanQrTooltip));
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
      expect(find.text(_l.scanWrongNetworkTitle), findsOneWidget);
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
      expect(find.text(_l.slateFileTitle), findsOneWidget);
      expect(
        find.text(_l.scanSlateTextBody),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(FilledButton, _l.commonOpen));
      expect(find.byType(SlateFileScreen), findsOneWidget);
    });

    testWidgets('a pairing link on a core without pairing says it is not here yet', (tester) async {
      final h = _Harness();
      h.session.pairing.enabled = false;
      await h.pump(tester);
      await h.scan(tester, 'epiccash://pair/1/abc');
      expect(find.text(_l.scanPairingTitle), findsOneWidget);
      expect(
        find.text(_l.scanPairingUnavailable),
        findsOneWidget,
      );
    });

    testWidgets('a pairing invite opens the incoming invite', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, h.session.pairing.inviteLinkFrom(name: 'Anna'));
      expect(find.text(_l.pairIncomingTitle('Anna')), findsOneWidget);
      expect(find.text(_l.scanPairingUnavailable), findsNothing);
    });
  });

  group('a pairing invite at Just send and receive', () {
    /// The invite as the inviter's QR and Share carry it: the invite page's https link.
    String pageLink(_Harness h) => inviteShareText(
      InviteLink(InviteKind.pair, h.session.pairing.inviteLinkFrom(name: 'Anna')),
      invitePage: 'https://epiccash.btlabs.uk',
    );

    _Harness levelOne() =>
        _Harness()..store.values[levelKey] = const LevelChosen(WalletLevel.justSendReceive).encode();

    testWidgets('a link handed to the app: the notice, See request opens the invite', (tester) async {
      final h = levelOne();
      await h.pump(tester);
      h.container.read(inviteInboxProvider).deliver(pageLink(h));
      await tester.pumpAndSettle();
      expect(find.text(_l.lvShellPairNotice('Anna')), findsOneWidget);
      expect(find.text(_l.pairIncomingTitle('Anna')), findsNothing);
      await _tap(tester, find.text(_l.lvShellSeeRequest));
      expect(find.text(_l.pairIncomingTitle('Anna')), findsOneWidget);
    });

    testWidgets('Home\'s scan of the inviter\'s QR opens the invite, no notice first', (tester) async {
      final h = levelOne();
      await h.pump(tester);
      await h.scan(tester, pageLink(h));
      expect(find.text(_l.pairIncomingTitle('Anna')), findsOneWidget);
      expect(find.text(_l.lvShellPairNotice('Anna')), findsNothing);
    });

    testWidgets('Send › Scan of the inviter\'s QR opens the invite', (tester) async {
      final h = levelOne();
      await h.pump(tester);
      await _tap(tester, find.descendant(of: find.byType(NavigationBar), matching: find.text(_l.homeSendButton)));
      h.scanner.codes.add(pageLink(h));
      await _tap(tester, find.text(_l.sendScanButton));
      expect(find.text(_l.pairIncomingTitle('Anna')), findsOneWidget);
      expect(find.text(_l.scanNotEpicTitle), findsNothing);
    });
  });

  group('a Send tab kept alive', () {
    testWidgets('an address scanned after Send was opened keeps its origin', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text(_l.homeSendButton).last);
      await _tap(tester, find.text(_l.shellWalletTab).last);
      await h.scan(tester, _e);
      expect(_tab(tester), ShellTab.send);
      expect(_field(tester, sendRecipientFieldKey), _e);
      await _continue(tester);
      await tester.enterText(find.byKey(sendAmountFieldKey), '1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(_origin(_l.sendOriginQr), findsOneWidget);
    });

    testWidgets('a second code without an amount drops the first one\'s', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, 'epic:$_e?amount=5&message=Table%204');
      expect(_field(tester, sendAmountFieldKey), '5');
      await _tap(tester, find.text(_l.shellWalletTab).last);
      await h.scan(tester, 'epic:$_e?label=Bob');
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), isEmpty);
      expect(_noteTile('Table 4'), findsNothing);
      expect(find.text('Bob'), findsNothing);
    });
  });

  group('a deposit code', () {
    const note = '4827193065148';
    const deposit = 'epic:$_e?message=$note&require=message&min=0.1&label=Example%20Exchange%20deposit';
    const link = 'epiccash:$_e?message=$note&require=message&min=0.1&label=Example%20Exchange%20deposit';

    Future<void> clearNote(WidgetTester tester) async {
      await _tap(tester, _noteTile(note));
      await tester.enterText(find.byKey(sendNoteFieldKey), '');
      await tester.pumpAndSettle();
    }

    testWidgets('the note is filled and can change; the amount stays for the user', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, deposit);

      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), isEmpty);
      expect(_noteTile(note), findsOneWidget);
      expect(find.text(_l.sendNoteRequiredHelper), findsOneWidget);
      expect(find.byKey(sendNoteMissingKey), findsNothing);
      expect(find.textContaining('Minimum'), findsOneWidget);
      await _tap(tester, _noteTile(note));
      expect(_field(tester, sendNoteFieldKey), note);
      expect(h.session.epicboxSends, isEmpty);
    });

    testWidgets('a code that asks for a note and carries none opens Message', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, 'epic:$_e?require=message');
      expect(find.text(_l.sendAddNote), findsNothing);
      expect(find.byKey(sendNoteFieldKey), findsOneWidget);
      expect(find.byKey(sendNoteMissingKey), findsOneWidget);
    });

    testWidgets('a cleared note warns on both steps and the send still goes, without it', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, deposit);
      await clearNote(tester);
      expect(find.byKey(sendNoteMissingKey), findsOneWidget);
      expect(find.text(_l.sendNoteMissingCode), findsOneWidget);

      await tester.enterText(find.byKey(sendAmountFieldKey), '1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(find.byKey(sendReviewNoteMissingKey), findsOneWidget);
      await _tap(tester, find.textContaining('Send 1'));
      await answerPin(tester);
      expect(h.session.epicboxSends.single.to, _e);
      expect(h.session.sentMessages.last, anyOf(isNull, isEmpty));
    });

    testWidgets('a code without its note opens Send and warns', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, 'epic:$_e?require=message');
      expect(_tab(tester), ShellTab.send);
      expect(find.text(_l.sendNoteMissingCode), findsOneWidget);
    });

    testWidgets('under the minimum it warns on both steps, and the note goes with the send', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, deposit);

      await tester.enterText(find.byKey(sendAmountFieldKey), '0.05');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(sendBelowMinimumKey), findsOneWidget);
      await _continue(tester);
      expect(find.byKey(sendReviewBelowMinimumKey), findsOneWidget);
      await _tap(tester, find.textContaining('Send 0.05'));
      await answerPin(tester);
      expect(h.session.epicboxSends.single.to, _e);
      expect(h.session.sentMessages.last, note);
    });

    testWidgets('at the minimum nothing warns', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, deposit);
      await tester.enterText(find.byKey(sendAmountFieldKey), '0.1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(sendBelowMinimumKey), findsNothing);
      await _continue(tester);
      expect(find.byKey(sendReviewBelowMinimumKey), findsNothing);
      expect(find.byKey(sendReviewNoteMissingKey), findsNothing);
    });

    testWidgets('another address takes the note and the minimum away with the code', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, deposit);
      await _back(tester);
      await tester.enterText(find.byKey(sendRecipientFieldKey), _other);
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(_noteTile(note), findsNothing);
      expect(find.byKey(sendNoteMissingKey), findsNothing);
      expect(find.textContaining('Minimum'), findsNothing);
      expect(find.text(_l.sendAddNote), findsOneWidget);
    });

    testWidgets('a link fills the same', (tester) async {
      final linked = _Harness();
      await linked.pump(tester);
      linked.container.read(incomingLinkProvider.notifier).deliver(link);
      await tester.pumpAndSettle();
      expect(_tab(tester), ShellTab.send);
      expect(_noteTile(note), findsOneWidget);
      expect(find.textContaining('Minimum'), findsOneWidget);
      await tester.enterText(find.byKey(sendAmountFieldKey), '1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(_origin(_l.sendOriginLink), findsOneWidget);
    });

    testWidgets('pasted over the address field', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.descendant(of: find.byType(NavigationBar), matching: find.text(_l.homeSendButton)));
      await tester.enterText(find.byKey(sendRecipientFieldKey), deposit);
      await tester.pumpAndSettle();
      expect(_noteTile(note), findsOneWidget);
      expect(find.textContaining('Minimum'), findsOneWidget);
    });
  });

  group('an address on an exchange relay', () {
    const exchange = '$_key@epicbox.exchange.invalid';

    setUp(useSampleServices);

    testWidgets('a bare scan warns on both steps; a message clears it; the send still goes', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, exchange);
      await _continue(tester);
      expect(find.text(_l.serviceHintExchangeCheckNote), findsOneWidget);

      await tester.enterText(find.byKey(sendAmountFieldKey), '1');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await _continue(tester);
      expect(find.byKey(sendReviewNoteMissingKey), findsOneWidget);
      await _tap(tester, find.textContaining('Send 1'));
      await answerPin(tester);
      expect(h.session.epicboxSends.single.to, exchange);
    });

    testWidgets('Message is open, not folded behind Add a message, and stays open while typed in', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, exchange);
      await _continue(tester);
      expect(find.text(_l.sendAddNote), findsNothing);
      expect(find.byKey(sendNoteFieldKey), findsOneWidget);
      await tester.enterText(find.byKey(sendNoteFieldKey), '1');
      await tester.pumpAndSettle();
      expect(find.byKey(sendNoteFieldKey), findsOneWidget);
    });

    testWidgets('another relay says nothing', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.scan(tester, _e);
      await _continue(tester);
      expect(find.byKey(sendNoteMissingKey), findsNothing);
      expect(find.text(_l.sendAddNote), findsOneWidget);
    });
  });

  group('Send field paste', () {
    Future<void> paste(WidgetTester tester, _Harness h, String text) async {
      await _tap(
        tester,
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(_l.homeSendButton),
        ),
      );
      h.clipboard = text;
      await _tap(tester, find.widgetWithText(TextButton, _l.commonPaste));
    }

    testWidgets('a payment code fills the form, origin Pasted', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await paste(tester, h, _lunch);
      expect(_onAmount(), isTrue);
      expect(_field(tester, sendAmountFieldKey), '1.5');
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      await _continue(tester);
      expect(_origin(_l.sendOriginPasted), findsOneWidget);
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
        find.text(_l.scanBadAddress),
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
      expect(find.text(_l.scanBadAddress), findsNothing);
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
      expect(find.byKey(sendRequestBannerKey), findsNothing);
      await _continue(tester);
      expect(_origin(_l.sendOriginLink), findsOneWidget);
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
      expect(find.text(_l.linkWaitingNotice), findsOneWidget);
      await _tap(
        tester,
        find.descendant(of: find.byKey(noticeKey), matching: find.text(_l.commonOpen)),
      );
      expect(find.text('another screen'), findsNothing);
      expect(_tab(tester), ShellTab.send);
      expect(_field(tester, sendAmountFieldKey), '1.5');
    });

    testWidgets('under another screen, a pairing invite goes to the pairing handler, not Payment link', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      unawaited(
        Navigator.of(tester.element(find.byType(HomeScreen))).push(
          MaterialPageRoute<void>(builder: (_) => const SlotScaffold(body: Text('another screen'))),
        ),
      );
      await tester.pumpAndSettle();
      final opened = <String>[];
      registerInviteHandler(InviteKind.pair, (_, link) async => opened.add(link.invite));
      addTearDown(clearInviteHandlers);
      h.container.read(incomingLinkProvider.notifier).deliver('epiccash://pair/1/AAAA');
      await tester.pumpAndSettle();
      expect(opened, ['epiccash://pair/1/AAAA']);
      expect(find.text(_l.linkWaitingNotice), findsNothing);
      expect(h.container.read(incomingLinkProvider), isNull);
    });

    testWidgets('a pairing invite with no pairing handler: a short notice', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      // Pairing registers its handler with Home; none for this case.
      clearInviteHandlers();
      h.container.read(incomingLinkProvider.notifier).deliver('epiccash://pair/1/AAAA');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Pairing is off or not available in this wallet.'), findsOneWidget);
      expect(find.text(_l.linkWaitingNotice), findsNothing);
    });

    testWidgets('while busy: dropped, said so', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      h.container.read(linkBusyProvider.notifier).set(true);
      h.container.read(incomingLinkProvider.notifier).deliver(_lunch);
      await tester.pumpAndSettle();
      expect(find.text(_l.linkFinishCurrentFirst), findsOneWidget);
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

  testWidgets('a Tor code shows the onion address once on the review', (
    tester,
  ) async {
    const name = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid';
    const onion = '$name.onion';
    expect(name.length, 56);
    final h = _Harness();
    await h.pump(tester);
    await h.scan(tester, 'epic:$onion?amount=1');
    // Tor starts with the send: nothing to turn on first.
    expect(find.byKey(sendTurnOnTorKey), findsNothing);
    h.session.torStatusValue = TorStatus(
      kind: TorStatusKind.ready,
      onion: h.session.onion,
    );
    h.session.torEvents.add(
      TorEvent(kind: TorEventKind.ready, onion: h.session.onion),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();
    await _continue(tester);
    expect(_origin(_l.sendOriginQr), findsOneWidget);
    expect(find.text('Host'), findsNothing);
    final onCard = find.descendant(
      of: find.byType(RecipientCard),
      matching: find.textContaining('.onion', findRichText: true),
    );
    expect(onCard, findsOneWidget);
    expect(find.textContaining('.onion', findRichText: true), findsOneWidget);
  });

  testWidgets('a Link code with a path keeps the host line on the review', (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await h.scan(tester, 'epic:$_d/pay?amount=1');
    await _continue(tester);
    expect(find.text(_l.sendFactHost), findsOneWidget);
    expect(find.text('1.2.3.4:3415'), findsOneWidget);
    // The reach check's slow-answer timer runs out.
    await tester.pump(const Duration(seconds: 2));
  });

  test('scheme and host alone are already the host', () {
    expect(directHostBesideOf(_d), isNull);
    expect(directHostBesideOf('$_d/'), isNull);
    expect(directHostBesideOf('$_d/pay'), '1.2.3.4:3415');
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
      // The 264-character note takes the room above the field: it is built once scrolled to.
      await tester.dragUntilVisible(
        find.byKey(sendAmountFieldKey),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      expect(_onAmount(), isTrue);
      expect(find.byKey(payeeClaimsKey), findsNothing);
      await _continue(tester);
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(
        find.byKey(sendOriginPillKey),
        find.byType(Scrollable).first,
        const Offset(0, 200),
      );
      expect(_origin(_l.sendOriginQr), findsOneWidget);
      final host = find.text('1.2.3.4:3415');
      // The list is lazy: the host row is built once scrolled to.
      await tester.dragUntilVisible(
        host,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(host.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The reach check's "Checking…" timer (send_screen _askReach) runs out before the end.
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
