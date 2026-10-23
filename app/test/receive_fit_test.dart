// Receive's Epicbox tab on a phone, with the real fonts: the fonts decide how many lines the
// address and the buttons take, and the test font draws every glyph a full em wide. This file
// loads them for itself, so the other tests keep the test font.
import 'dart:io';

import 'package:epic_wallet/src/demo.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/demo_screens.dart' show testCoinsKey;
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/ui/theme/protocol.dart' show CornerTicksPainter;
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A full-length address, as long as a real one.
const String _address =
    'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@epicbox.epiccash.com';

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

/// Roboto, the bundled Montserrat and JetBrains Mono, and the icons, as the tour loads them.
Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  for (final (family, file) in [
    ('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'),
    ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('MaterialIcons', '$dir/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
}

/// Opens the shell on Receive at [size] dp, in demo mode or not, with invoices on.
Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required bool demo,
  bool insets = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  if (insets) {
    // A phone's status bar and gesture bar, in physical pixels.
    tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 48 * 3);
    tester.view.viewPadding = const FakeViewPadding(
      top: 24 * 3,
      bottom: 48 * 3,
    );
  }
  addTearDown(tester.view.reset);
  final session = FakeWalletSession()..address = _address;
  expect(session.supportsInvoices, isTrue);
  final config = (demo ? floonetPreset : mainnetPreset).config(
    dataDir: '/fake/wallets',
    nodeUrl: 'https://node',
  );
  final store = MemorySecretStore()
    ..values['wallet.${config.chain.name}.backedUp'] = '1';
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        demoModeProvider.overrideWithValue(demo),
        demoApiProvider.overrideWithValue(
          FakeDemoApi(
            status: DemoActive(DateTime.now().add(const Duration(hours: 5))),
          ),
        ),
        walletServiceProvider.overrideWithValue(
          FakeWalletService(session: session),
        ),
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Receive'),
    ),
  );
  await tester.pumpAndSettle();
}

/// Receive's own scroll view.
ScrollPosition _receiveScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ReceiveView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// The QR code's side.
double _qrSide(WidgetTester tester) =>
    tester.getSize(find.byType(MarkedQr)).width;

void main() {
  setUpAll(_loadFonts);

  // A phone with its status bar (24 dp) and gesture bar (48 dp), wallet with invoices; and
  // the web demo, which runs in a browser window without them.
  for (final (size, demo, insets) in [
    (const Size(412, 915), false, false),
    (const Size(360, 780), false, false),
    (const Size(412, 915), false, true),
    (const Size(360, 780), false, true),
    (const Size(412, 915), true, false),
    (const Size(360, 780), true, false),
  ]) {
    final name =
        '${size.width.toInt()} x ${size.height.toInt()} dp'
        '${demo ? ', demo' : ', invoices'}'
        '${insets ? ', status and gesture bars' : ''}';
    // The method strip and the caption under the address (spec 7.2) take the room a 780 dp
    // phone had to spare with the Request or test coins buttons: there it scrolls a little,
    // the code at its least size.
    final fits = size.height >= 900;
    testWidgets(
      fits
          ? 'the Epicbox tab fits without scrolling at $name'
          : 'the Epicbox tab scrolls a little at $name',
      (tester) async {
        await _pump(tester, size: size, demo: demo, insets: insets);
        expect(tester.takeException(), isNull);
        // Everything the tab holds is there.
        expect(find.byKey(receiveAddressKey), findsOneWidget);
        expect(find.byKey(receiveEpicboxKey), findsOneWidget);
        expect(find.byType(MarkedQr), findsOneWidget);
        expect(find.byKey(receiveRequestKey), findsOneWidget);
        expect(find.byKey(testCoinsKey), demo ? findsOneWidget : findsNothing);
        final help = find.text('How receiving works');
        expect(help, findsOneWidget);
        final scroll = _receiveScroll(tester).maxScrollExtent;
        if (fits) {
          // No scroll, and the last of it ends above the tab bar.
          expect(scroll, 0);
        } else {
          expect(scroll, lessThanOrEqualTo(160), reason: name);
          expect(_qrSide(tester), receiveQrMinSize);
          await tester.drag(find.byType(ReceiveView), const Offset(0, -400));
          await tester.pumpAndSettle();
        }
        final bar = tester.getRect(find.byType(NavigationBar));
        final helpButton = tester.getRect(
          find.ancestor(of: help, matching: find.byType(TextButton)),
        );
        expect(helpButton.bottom, lessThanOrEqualTo(bar.top));
        // The code and its frame stay in their slot: under the epicbox line, above the
        // buttons. A code drawn past the room it was given would cover them.
        final code = tester.getRect(
          find.ancestor(
            of: find.byType(MarkedQr),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint && w.foregroundPainter is CornerTicksPainter,
            ),
          ),
        );
        expect(
          code.top,
          greaterThanOrEqualTo(
            tester.getRect(find.byKey(receiveEpicboxKey)).bottom,
          ),
        );
        for (final below in [receiveRequestKey, if (demo) testCoinsKey]) {
          expect(
            code.bottom,
            lessThanOrEqualTo(tester.getRect(find.byKey(below)).top),
            reason: '$below',
          );
        }
        final side = _qrSide(tester);
        // The frame holds the whole code: its ticks' 12 dp and the white 16 dp on each side.
        expect(code.height, closeTo(side + 56, 0.5));
        expect(code.width, closeTo(side + 56, 0.5));
        expect(
          code.deflate(28).contains(tester.getCenter(find.byType(MarkedQr))),
          isTrue,
        );
        expect(
          tester.getRect(find.byType(MarkedQr)).top,
          closeTo(code.top + 28, 0.5),
        );
        expect(
          side,
          inInclusiveRange(receiveQrMinSize, receiveQrMaxSize),
          reason: name,
        );
        // ignore: avoid_print
        print(
          '$name: QR $side dp, ${bar.top - helpButton.bottom} dp to spare, '
          '$scroll dp scrolled',
        );
      },
    );
  }

  testWidgets('with no room for the least code, the page scrolls', (
    tester,
  ) async {
    await _pump(tester, size: const Size(360, 780), demo: true, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(_qrSide(tester), receiveQrMinSize);
    expect(_receiveScroll(tester).maxScrollExtent, greaterThan(0));
    // Scrolled to its end, the help shows above the tab bar.
    await tester.fling(find.byType(ReceiveView), const Offset(0, -2000), 3000);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('How receiving works')).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top),
    );
    expect(tester.takeException(), isNull);
  });
}
