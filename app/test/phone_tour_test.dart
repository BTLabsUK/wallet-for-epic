// SPDX-License-Identifier: Apache-2.0
// The phone's first-unlock tour: it opens once after the first unlock (never over a screen that
// is not idle), Skip ends it and marks it seen, Back and Next open the right screens, Help can
// show it again, every step lights something that exists with Advanced off and switches
// nothing on, and the card fits at 360×800 and 412×915 dp without covering what it lights.
import 'dart:async';

import 'package:epic_wallet/l10n/app_localizations_en.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/onion_notice.dart' show onionNoticeKey, onionNoticeSeen;
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/scan/incoming_link.dart' show incomingLinkProvider;
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart' show goHome;
import 'package:epic_wallet/src/ui/devices/linked_devices_screen.dart';
import 'package:epic_wallet/src/ui/help_screen.dart';
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/invoices_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_sections.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tour/phone_tour.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

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

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

/// A wallet that does not take invoices (the LEPIC adapter before it is wired).
class _NoInvoicesSession extends FakeWalletSession {
  _NoInvoicesSession({super.summary});

  @override
  bool get supportsInvoices => false;
}

/// What a harness gives back: the store, the container, the session.
class _Rig {
  _Rig(this.store, this.container);

  final MemorySecretStore store;
  final ProviderContainer container;
}

/// Home, as after the first unlock, at [size] dp. [auto] turns the tour's own start on (the other
/// suites keep it off); [seen] is the saved flag.
Future<_Rig> _pump(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  bool auto = true,
  bool seen = false,
  bool invoices = true,
  bool funded = true,
  bool insets = false,
  double textScale = 1,
  bool still = false,
  AdvancedPrefs advanced = AdvancedPrefs.none,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  if (insets) {
    tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 48 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 24 * 3, bottom: 48 * 3);
  }
  addTearDown(tester.view.reset);
  final session = invoices ? FakeWalletSession(summary: _funds) : _NoInvoicesSession(summary: _funds);
  if (!funded) session.summaryValue = FakeWalletSession.emptySummary;
  final config = mainnetPreset.config(dataDir: '/fake/wallets', nodeUrl: 'https://node');
  final store = MemorySecretStore()
    ..values['wallet.${config.chain.name}.backedUp'] = '1';
  store.values['app.advanced_prefs'] = advanced.encode();
  store.values[onionNoticeKey(config.chain.name, null)] = onionNoticeSeen;
  if (seen) store.values[AppSettingsNotifier.phoneTourSeenKey] = 'true';
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        phoneTourAutoProvider.overrideWithValue(auto),
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        walletServiceProvider.overrideWithValue(FakeWalletService(session: session)),
        secretStoreProvider.overrideWithValue(store),
        biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
        updatePlatformProvider.overrideWithValue(null),
        priceSourceProvider.overrideWithValue(_NoPrice()),
        qrScannerProvider.overrideWithValue(FakeQrScanner()),
        slateFilesProvider.overrideWithValue(FakeSlateFiles()),
        historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
        sessionProvider.overrideWith(() => _OpenSession(session)),
        walletConfigProvider.overrideWith(() => _Config(config)),
      ],
      child: MaterialApp(
        theme: buildWalletTheme(protocolLight, Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AdvancedOptions(
          prefs: advanced,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: still,
            ),
            child: child!,
          ),
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
  await tester.pumpAndSettle();
  return _Rig(store, container);
}

/// Home idle for the start delay, then the tour's first step settled.
Future<void> _startAuto(WidgetTester tester) async {
  await tester.pump(phoneTourStartDelay + const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Finder _inTour(Finder f) => find.descendant(of: find.byType(PhoneTourOverlay), matching: f);

Finder get _card => find.byKey(phoneTourCardKey);

Finder get _overlay => find.byType(PhoneTourOverlay);

Finder _button(String label) => find.descendant(of: _card, matching: find.text(label));

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(_button(label));
  await tester.pumpAndSettle();
}

/// The ring around the lit area, or null with nothing lit.
Rect? _ring(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(_inTour(find.byType(CustomPaint)).first);
  return (paint.painter! as dynamic).hole as Rect?;
}

String _counter(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(of: _card, matching: find.byType(Text)))
    .first
    .data!;

bool _lit(String id) => phoneTourContext(id) != null;

final WalletSummary _funds = WalletSummary(
  lastConfirmedHeight: BigInt.from(2500000),
  minimumConfirmations: BigInt.from(3),
  total: BigInt.from(1250000000),
  spendable: BigInt.from(1250000000),
  awaitingConfirmation: BigInt.zero,
  awaitingFinalization: BigInt.zero,
  immature: BigInt.zero,
  locked: BigInt.zero,
  validatedWithNode: true,
);

final AppLocalizations _en = AppLocalizationsEn();

void main() {
  tearDown(() => debugPhoneTourSteps = null);

  group('steps', () {
    test('nine with invoices and linked devices; no Contacts step; each optional step drops out on its own', () {
      final all = phoneTourSteps(invoices: true);
      final none = phoneTourSteps(invoices: false);
      expect(all.map((s) => s.titleOf(_en)), [
        'Wallet',
        'Send',
        'Receive',
        'Activity',
        'Invoices',
        'Linked devices',
        'Network & privacy',
        'Advanced',
        'Help',
      ]);
      expect(none.length, 8);
      expect(none.any((s) => s.place == TourPlace.invoices), isFalse);
      final noDevices = phoneTourSteps(invoices: true, devices: false);
      expect(noDevices.length, 8);
      expect(noDevices.any((s) => s.place == TourPlace.devices), isFalse);
    });

    test('epic1 mode: Send and Receive speak of links and in person, not Epicbox or files', () {
      final steps = phoneTourSteps(invoices: true, epic1: true);
      expect(steps.length, phoneTourSteps(invoices: true).length);
      final send = steps.firstWhere((s) => s.place == TourPlace.send);
      final receive = steps.firstWhere((s) => s.place == TourPlace.receive);
      expect(send.textOf(_en), _en.deskE1TourPhSendText);
      expect(receive.textOf(_en), _en.deskE1TourPhReceiveText);
      for (final s in [send, receive]) {
        expect(s.textOf(_en), contains('epic1 link'));
        expect(s.textOf(_en), isNot(contains('Epicbox')));
        expect(s.textOf(_en).length, lessThan(175));
      }
    });

    test('copy: short, no "we", the Advanced step says it switches nothing on by asking to switch on what you need', () {
      for (final s in phoneTourSteps(invoices: true)) {
        final text = s.textOf(_en);
        expect(text.length, lessThan(175), reason: s.titleOf(_en));
        expect(text, isNot(matches(RegExp(r'\b[Ww]e\b'))), reason: s.titleOf(_en));
      }
    });
  });

  group('start', () {
    testWidgets('opens once after the first unlock, on Wallet, saved as seen', (tester) async {
      final rig = await _pump(tester);
      expect(_overlay, findsNothing, reason: 'not before Home has been idle');
      await _startAuto(tester);
      expect(_overlay, findsOneWidget);
      expect(_counter(tester), '1 of 9');
      expect(_inTour(find.text('Wallet')), findsOneWidget);
      expect(rig.store.values[AppSettingsNotifier.phoneTourSeenKey], 'true');
      expect(rig.container.read(appSettingsProvider).value?.phoneTourSeen, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not open when it was seen', (tester) async {
      await _pump(tester, seen: true);
      await _startAuto(tester);
      expect(_overlay, findsNothing);
    });

    testWidgets('is off in the other suites by default (the flag is the test harness switch)', (tester) async {
      await _pump(tester, auto: false);
      await _startAuto(tester);
      expect(_overlay, findsNothing);
    });

    testWidgets('a payment link opened at the first unlock wins: Send stays, the tour waits for Wallet', (tester) async {
      final rig = await _pump(tester);
      rig.container.read(incomingLinkProvider.notifier).deliver('epic:${'b' * 52}@epicbox.epiccash.com?amount=0.4');
      await tester.pumpAndSettle();
      expect(rig.container.read(shellTabProvider), ShellTab.send);
      await _startAuto(tester);
      expect(_overlay, findsNothing);
      expect(rig.container.read(shellTabProvider), ShellTab.send);
      // Back on Wallet, Home is idle again: the tour opens.
      rig.container.read(shellTabProvider.notifier).go(ShellTab.wallet);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(_overlay, findsOneWidget);
    });

    testWidgets('does not open over a dialog; opens once it is closed', (tester) async {
      await _pump(tester);
      unawaited(
        showDialog<void>(
          context: tester.element(find.byType(HomeScreen)),
          builder: (_) => const AlertDialog(title: Text('Backup reminder')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(phoneTourStartDelay + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
      Navigator.of(tester.element(find.text('Backup reminder'))).pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(_overlay, findsOneWidget);
    });

    testWidgets('Skip ends it, marks it seen and lands on Wallet; it does not come back', (tester) async {
      final rig = await _pump(tester);
      await _startAuto(tester);
      await _tap(tester, _l.tourPhoneNext);
      await _tap(tester, _l.tourPhoneSkip);
      expect(_overlay, findsNothing);
      expect(rig.container.read(shellTabProvider), ShellTab.wallet);
      expect(rig.store.values[AppSettingsNotifier.phoneTourSeenKey], 'true');
      // Another unlock: a new Home, the saved flag says seen.
      goHome(tester.element(find.byType(HomeScreen)));
      await tester.pumpAndSettle();
      await _startAuto(tester);
      expect(_overlay, findsNothing);
    });
  });

  group('steps open the right screens', () {
    testWidgets('Next walks all nine, Back walks back, Done lands on Wallet', (tester) async {
      final rig = await _pump(tester);
      await _startAuto(tester);
      final steps = phoneTourSteps(invoices: true);

      void expectStep(int i) {
        expect(_counter(tester), '${i + 1} of ${steps.length}');
        expect(_inTour(find.text(steps[i].titleOf(_en))), findsOneWidget);
        // Every target the step names is there with Advanced off (the Tor switch may be absent
        // when this phone offers no Tor), and the ring is on something.
        final found = steps[i].targets.where(_lit).toList();
        expect(found, isNotEmpty, reason: 'step ${i + 1}');
        expect(_ring(tester), isNotNull, reason: 'step ${i + 1} lights something');
        final screen = switch (steps[i].place) {
          TourPlace.activity => find.byType(HistoryScreen),
          TourPlace.devices => find.byType(LinkedDevicesScreen),
          TourPlace.invoices => find.byType(InvoicesScreen),
          TourPlace.privacy || TourPlace.advanced => find.byType(SettingsSectionScreen),
          TourPlace.help => find.byType(HelpScreen),
          _ => null,
        };
        if (screen == null) {
          expect(find.byType(HistoryScreen), findsNothing);
          expect(find.byType(SettingsSectionScreen), findsNothing);
        } else {
          expect(screen, findsOneWidget);
        }
        expect(tester.takeException(), isNull, reason: 'step ${i + 1}');
      }

      expectStep(0);
      expect(rig.container.read(shellTabProvider), ShellTab.wallet);
      expect(_button('Back'), findsNothing, reason: 'nothing before the first step');
      await _tap(tester, _l.tourPhoneNext);
      expectStep(1);
      expect(rig.container.read(shellTabProvider), ShellTab.send);
      await _tap(tester, _l.tourPhoneNext);
      expectStep(2);
      expect(rig.container.read(shellTabProvider), ShellTab.receive);
      for (var i = 3; i < steps.length; i++) {
        await _tap(tester, _l.tourPhoneNext);
        expectStep(i);
      }
      expect(find.text('Done'), findsWidgets);
      // Back to the middle and forward again.
      await _tap(tester, 'Back');
      expectStep(steps.length - 2);
      await _tap(tester, 'Back');
      expectStep(steps.length - 3);
      await _tap(tester, 'Next');
      await _tap(tester, 'Next');
      expectStep(steps.length - 1);
      await tester.tap(find.descendant(of: _card, matching: find.text('Done')));
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
      expect(find.byType(HelpScreen), findsNothing);
      expect(rig.container.read(shellTabProvider), ShellTab.wallet);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Back from a screen step closes that screen and returns to the tab', (tester) async {
      final rig = await _pump(tester);
      await _startAuto(tester);
      for (var i = 0; i < 3; i++) {
        await _tap(tester, _l.tourPhoneNext);
      }
      expect(find.byType(HistoryScreen), findsOneWidget);
      await _tap(tester, _l.tourPhoneBack);
      expect(find.byType(HistoryScreen), findsNothing);
      expect(rig.container.read(shellTabProvider), ShellTab.receive);
      expect(_counter(tester), '3 of 9');
    });

    testWidgets('system Back moves the tour one step back, and ends it on the first step', (tester) async {
      await _pump(tester);
      await _startAuto(tester);
      for (var i = 0; i < 4; i++) {
        await _tap(tester, _l.tourPhoneNext);
      }
      expect(find.byType(InvoicesScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_counter(tester), '4 of 9');
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(InvoicesScreen), findsNothing);
      for (var i = 0; i < 3; i++) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      expect(_counter(tester), '1 of 9');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('the Invoices step is there only when the wallet takes invoices', (tester) async {
      await _pump(tester, invoices: false);
      await _startAuto(tester);
      expect(_counter(tester), '1 of 8');
      for (var i = 0; i < 7; i++) {
        await _tap(tester, _l.tourPhoneNext);
        expect(find.byType(InvoicesScreen), findsNothing);
      }
      expect(_counter(tester), '8 of 8');
      expect(_inTour(find.text('Help')), findsOneWidget);
    });

    testWidgets('the Advanced step lights the page and switches nothing on', (tester) async {
      final rig = await _pump(tester);
      await _startAuto(tester);
      for (var i = 0; i < 7; i++) {
        await _tap(tester, _l.tourPhoneNext);
      }
      expect(_inTour(find.text('Advanced')), findsOneWidget);
      expect(find.byType(SettingsSectionScreen), findsOneWidget);
      expect(_lit('tour-advanced-top'), isTrue);
      expect(_lit('tour-advanced-modes'), isFalse, reason: 'the modes are on Network & privacy');
      await _tap(tester, 'Next');
      await _tap(tester, 'Done');
      expect(rig.container.read(appSettingsProvider).value?.advanced, AdvancedPrefs.none);
      expect(rig.store.values['app.advanced_prefs'], AdvancedPrefs.none.encode(), reason: 'as stored before the tour');
      expect(rig.store.values.keys.where((k) => k == 'app.advanced'), isEmpty);
    });

    testWidgets('a pushed screen is under the card: Next works on it', (tester) async {
      await _pump(tester);
      await _startAuto(tester);
      for (var i = 0; i < 3; i++) {
        await _tap(tester, _l.tourPhoneNext);
      }
      expect(find.byType(HistoryScreen), findsOneWidget);
      // The scrim takes taps: the Activity screen's own controls do not react under it.
      await tester.tapAt(const Offset(200, 120));
      await tester.pumpAndSettle();
      expect(_counter(tester), '4 of 9');
    });

    testWidgets('locking while it is open ends it with Home', (tester) async {
      final rig = await _pump(tester);
      await _startAuto(tester);
      final context = tester.element(find.byType(HomeScreen));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('PIN'))),
        (_) => false,
      );
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
      expect(rig.container.read(phoneTourProvider).open, isFalse);
      expect(find.text('PIN'), findsOneWidget);
    });
  });

  group('Show the tour again', () {
    testWidgets('Help starts it from the first step, also when it was seen', (tester) async {
      final rig = await _pump(tester, seen: true);
      await _startAuto(tester);
      expect(_overlay, findsNothing);
      unawaited(openHelp(tester.element(find.byType(HomeScreen))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(helpShowTourKey), 300, scrollable: find.descendant(of: find.descendant(of: find.byType(HelpScreen), matching: find.byType(ListView)), matching: find.byType(Scrollable)).first);
      // The last row of a long page: wholly on screen before the tap.
      await tester.ensureVisible(find.byKey(helpShowTourKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(helpShowTourKey));
      await tester.pumpAndSettle();
      expect(_overlay, findsOneWidget);
      expect(_counter(tester), '1 of 9');
      expect(find.byType(HelpScreen), findsNothing, reason: 'the tour starts on Home');
      expect(rig.container.read(shellTabProvider), ShellTab.wallet);
    });
  });

  group('a new wallet without coins', () {
    testWidgets('the Send step lights what the tab shows: that there is nothing to send yet', (tester) async {
      await _pump(tester, funded: false);
      await _startAuto(tester);
      await _tap(tester, _l.tourPhoneNext);
      expect(_lit('tour-send-empty'), isTrue);
      expect(_lit('tour-send-methods'), isFalse);
      expect(_ring(tester), isNotNull);
    });
  });

  group('layout', () {
    for (final (size, insets) in [
      (const Size(360, 800), false),
      (const Size(412, 915), false),
      (const Size(360, 800), true),
      (const Size(412, 915), true),
    ]) {
      testWidgets('every step fits at ${size.width.toInt()}×${size.height.toInt()}${insets ? ' with bars' : ''}; the card never covers the lit area and stays at the bottom', (tester) async {
        await _pump(tester, size: size, insets: insets);
        await _startAuto(tester);
        final steps = phoneTourSteps(invoices: true);
        final screen = Offset.zero & size;
        final safe = Rect.fromLTRB(0, insets ? 24 : 0, size.width, size.height - (insets ? 48 : 0));
        double? bottom;
        for (var i = 0; i < steps.length; i++) {
          final card = tester.getRect(_card);
          // One place on every step: the card does not jump to the top for a tall lit area.
          bottom ??= card.bottom;
          expect(card.bottom, bottom, reason: 'step ${i + 1} card $card');
          expect(safe.contains(card.topLeft) && safe.contains(card.bottomRight), isTrue, reason: 'step ${i + 1} card $card in $safe');
          expect(screen.contains(card.bottomRight), isTrue);
          final ring = _ring(tester);
          expect(ring, isNotNull, reason: 'step ${i + 1}');
          expect(ring!.overlaps(card), isFalse, reason: 'step ${i + 1}: card $card over ring $ring');
          expect(ring.width, greaterThan(20), reason: 'step ${i + 1}');
          expect(ring.height, greaterThan(20), reason: 'step ${i + 1}');
          expect(tester.takeException(), isNull, reason: 'step ${i + 1}');
          if (i < steps.length - 1) await _tap(tester, _l.tourPhoneNext);
        }
      });
    }

    testWidgets('long text at 360 dp and large text wraps and scrolls inside the card', (tester) async {
      const long =
          'Überweisungen an eine Adresse, die Sie eingefügt oder gescannt haben, oder an einen '
          'gespeicherten Kontakt; vor jeder Zahlung kommt eine Prüfung, und die Datei-Methode '
          'erzeugt eine Transaktionsdatei, die Sie selbst weitergeben. Das ist ein sehr langer '
          'Text für einen Schritt der Tour, damit der Umbruch geprüft wird. Mehr Text. Mehr Text. '
          'Mehr Text. Mehr Text. Mehr Text. Mehr Text.';
      debugPhoneTourSteps = [
        PhoneTourStep(place: TourPlace.wallet, targets: const ['tour-balance'], titleOf: (_) => 'Überweisungen und Zahlungen mit einem langen Titel', textOf: (_) => long),
        PhoneTourStep(place: TourPlace.send, targets: const ['tour-send-methods', 'tour-send-recipient'], titleOf: (_) => 'Senden', textOf: (_) => long),
      ];
      await _pump(tester, size: const Size(360, 800), textScale: 1.6, insets: true);
      await _startAuto(tester);
      for (var i = 0; i < 2; i++) {
        final card = tester.getRect(_card);
        expect(card.left, greaterThanOrEqualTo(0));
        expect(card.right, lessThanOrEqualTo(360));
        expect(card.top, greaterThanOrEqualTo(24));
        expect(card.bottom, lessThanOrEqualTo(800 - 48));
        expect(card.height, lessThanOrEqualTo(800 * 0.5 + 1));
        expect(tester.takeException(), isNull);
        // The buttons stay reachable under the long text.
        expect(_button(_l.tourPhoneSkip), findsOneWidget);
        expect(find.descendant(of: _card, matching: find.text(i == 1 ? 'Done' : _l.tourPhoneNext)), findsOneWidget);
        if (i == 0) await _tap(tester, _l.tourPhoneNext);
      }
    });

    testWidgets('reduced motion: the card is there at once, no fade to wait for', (tester) async {
      await _pump(tester, still: true);
      await tester.pump(phoneTourStartDelay + const Duration(milliseconds: 100));
      // A few frames to place it, none to fade it in.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final fade = tester.widget<FadeTransition>(find.ancestor(of: _card, matching: find.byType(FadeTransition)).first);
      expect(fade.opacity.value, 1.0);
    });

    testWidgets('the card is announced as a route of its own and the counter, title and text are read', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _startAuto(tester);
      expect(find.bySemanticsLabel(_l.tourPhoneSemantics), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Next$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Skip tour$')), findsOneWidget);
      handle.dispose();
    });
  });
}
