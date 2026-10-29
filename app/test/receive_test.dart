// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/demo.dart' show devNetworksProvider;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/file_exchange_help.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/ui/status_icons.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// A full-length address, as long as a real one.
/// The address on the Receive card: a rich text whose server sits on its own line.
final Finder _addressText = find.byWidgetPredicate(
  (w) => w is SelectableText && w.textSpan?.toPlainText().replaceAll('\n', '') == _address,
);

const String _address =
    'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@epicbox.epiccash.com';

/// Starts with [session] already unlocked.
class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

/// A device that shares nothing, not even text.
class _NoShareFiles extends FakeSlateFiles {
  _NoShareFiles() {
    canShare = false;
  }

  @override
  bool get canShareText => false;
}

class _Harness {
  _Harness({this.advanced = false, FakeSlateFiles? files})
    : files = files ?? FakeSlateFiles() {
    session.address = _address;
  }

  final bool advanced;
  final session = FakeWalletSession();
  final service = FakeWalletService();
  final FakeSlateFiles files;
  late ProviderContainer container;

  /// What the app put on the clipboard.
  final copied = <String>[];

  /// What a paste reads; null is an empty clipboard.
  String? clipboard;

  Future<void> pump(
    WidgetTester tester, {
    Widget screen = const SlotScaffold(body: ReceiveView()),
    double textScale = 1,
    Chain chain = Chain.mainnet,
  }) async {
    // Taller than a phone: the test font draws every glyph a full em wide, so the method
    // strip takes about twice its real height. receive_fit_test checks real phones.
    tester.view.physicalSize = const Size(1080, 3300);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        if (call.method == 'Clipboard.getData') {
          return clipboard == null ? null : {'text': clipboard};
        }
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
          devNetworksProvider.overrideWithValue(true),
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          slateFilesProvider.overrideWithValue(files),
          sessionProvider.overrideWith(() => _OpenSession(session)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: AdvancedOptions(prefs: advanced ? AdvancedPrefs.all : AdvancedPrefs.none, child: child!),
          ),
          home: screen,
        ),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container
        .read(walletConfigProvider.notifier)
        .select(
          WalletConfig(
            dataDir: '/fake',
            chain: chain,
            nodeUrl: 'https://node.example',
            epicboxDomain: 'epicbox.epiccash.com',
            epicboxPort: 443,
          ),
        );
    await tester.pumpAndSettle();
  }

  /// Shows the Payment file tab.
  Future<void> byFile(WidgetTester tester) =>
      _tap(tester, find.descendant(of: find.byKey(receiveTabsKey), matching: find.byTooltip('Direct · File')));

  Future<void> listener(WidgetTester tester, ListenerEventKind kind) async {
    session.listenerEvents.add(ListenerEvent(kind: kind, message: 'x'));
    await tester.pumpAndSettle();
    // A drop shows once it lasts (walletStatusProvider).
    await tester.pump(statusSettle);
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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

/// Width and height from a PNG's header.
(int, int) _pngSize(Uint8List png) {
  expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final data = ByteData.sublistView(png);
  return (data.getUint32(16), data.getUint32(20));
}

// The QR checks read the code PrettyQrView draws.
// ignore_for_file: invalid_use_of_protected_member

void main() {
  group('tabs', () {
    testWidgets('three tabs with Send\'s look; Epicbox address by default', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final tabs = tester.widget<SegmentedButton<ReceiveTab>>(
        find.byKey(receiveTabsKey),
      );
      expect(tabs.selected, {ReceiveTab.epicbox});
      expect(tabs.showSelectedIcon, isFalse);
      expect(tabs.expandedInsets, EdgeInsets.zero);
      expect(
        [
          for (final s in tabs.segments)
            // The whole name: a long one wraps in two lines on the tab (PH-1).
            (s.value, s.tooltip),
        ],
        // Link stays whatever Settings says.
        [(ReceiveTab.epicbox, 'Epicbox'), (ReceiveTab.direct, 'Link'), (ReceiveTab.file, 'Direct · File')],
      );
      // The icon above the label, on every tab.
      expect(
        [
          for (final s in tabs.segments)
            tester.widget<Icon>(find.descendant(of: find.byWidget(s.label!), matching: find.byType(Icon))).icon,
        ],
        [EpicGlyphs.epicbox, EpicGlyphs.link, Icons.description_outlined],
      );
      // Full width: as wide as the address card under it.
      expect(
        tester.getSize(find.byKey(receiveTabsKey)).width,
        tester.getSize(find.byKey(receiveAddressKey)).width,
      );
      // Epicbox address: the card, the epicbox line, the code, the help. No request button:
      // Invoices are off by default (Settings › Advanced › Experimental).
      for (final key in [receiveAddressKey, receiveEpicboxKey]) {
        expect(find.byKey(key), findsOneWidget);
      }
      expect(find.byKey(receiveRequestKey), findsNothing);
      expect(find.byType(MarkedQr), findsOneWidget);
      expect(find.text('Receive by transaction file'), findsNothing);
      expect(find.text('How receiving works'), findsOneWidget);
      // The code is covered on open (the QR rule); Show QR uncovers it in the same box, a
      // tap on the code covers it again.
      final box = tester.getRect(find.byType(MarkedQr));
      expect(find.byKey(receiveShowQrKey), findsOneWidget);
      await tester.tap(find.text('Show QR'));
      await tester.pumpAndSettle();
      expect(find.byKey(receiveShowQrKey), findsNothing);
      expect(tester.getRect(find.byType(MarkedQr)), box);
      await tester.tap(find.byType(MarkedQr));
      await tester.pumpAndSettle();
      expect(find.byKey(receiveShowQrKey), findsOneWidget);
      // Payment file: the file card and the help, nothing else.
      await h.byFile(tester);
      expect(find.text('Receive by transaction file'), findsOneWidget);
      expect(find.text('How receiving works'), findsOneWidget);
      for (final key in [
        receiveAddressKey,
        receiveEpicboxKey,
        receiveRequestKey,
      ]) {
        expect(find.byKey(key), findsNothing);
      }
      expect(find.byType(MarkedQr), findsNothing);
      // The help ends both tabs.
      expect(
        tester.getRect(find.text('How receiving works')).top,
        greaterThan(tester.getRect(find.text('Open file')).bottom),
      );
      await _tap(tester, find.text('Epicbox'));
      expect(find.byKey(receiveAddressKey), findsOneWidget);
    });

    testWidgets('the choice outlives the view while the app runs', (
      tester,
    ) async {
      final shown = ValueNotifier(true);
      addTearDown(shown.dispose);
      final h = _Harness();
      await h.pump(
        tester,
        screen: SlotScaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (_, on, _) =>
                on ? const ReceiveView() : const SizedBox.shrink(),
          ),
        ),
      );
      await h.byFile(tester);
      // The view goes and is built again, as after a lock and unlock.
      shown.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(ReceiveView), findsNothing);
      shown.value = true;
      await tester.pumpAndSettle();
      expect(find.text('Receive by transaction file'), findsOneWidget);
      expect(find.byKey(receiveAddressKey), findsNothing);
    });

    testWidgets('the code keeps its size where there is room', (tester) async {
      await _Harness().pump(tester);
      expect(
        tester.getSize(find.byType(MarkedQr)),
        const Size.square(receiveQrMaxSize),
      );
    });
  });

  group('address', () {
    testWidgets('the full address comes first, the QR code below it', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      // Advanced options is off, and the address is still whole.
      expect(_addressText, findsOneWidget);
      final card = tester.getRect(find.byKey(receiveAddressKey));
      final qr = tester.getRect(find.byType(MarkedQr));
      expect(card.bottom, lessThan(qr.top));
      expect(
        find.descendant(
          of: find.byKey(receiveAddressKey),
          matching: find.byIcon(Icons.copy),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a tap anywhere on the card copies the whole address', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      // On the caption, on the copy icon, and on the address text itself. The docked notice
      // moves the content down, so it goes before the next tap.
      for (final target in [
        find.text('Epicbox address'),
        find.byIcon(Icons.copy),
        _addressText,
      ]) {
        await _tap(tester, target);
        expect(find.text('Address copied'), findsOneWidget);
        h.container.read(noticeProvider.notifier).clear();
        await tester.pumpAndSettle();
      }
      expect(h.copied, [_address, _address, _address]);
    });

    testWidgets('the card takes the full width, copy above share inside it', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final card = tester.getRect(
        find.ancestor(
          of: find.byKey(receiveAddressKey),
          matching: find.byType(Card),
        ),
      );
      final qr = tester.getRect(find.byType(MarkedQr));
      final view = tester.getRect(find.byType(ReceiveView));
      // Nothing beside the card: it spans the view, less the view's own padding.
      expect(card.width, greaterThan(view.width - 40));
      final copy = tester.getRect(find.byIcon(Icons.copy));
      final share = tester.getRect(find.byKey(receiveShareKey));
      expect(card.contains(copy.center), isTrue);
      expect(
        card.contains(share.topLeft) && card.contains(share.bottomRight),
        isTrue,
      );
      expect(share.top, greaterThanOrEqualTo(copy.bottom));
      expect(share.center.dx, closeTo(copy.center.dx, 1));
      expect(share.size, const Size(48, 48));
      expect(card.bottom, lessThan(qr.top));
      // Share shares; it does not copy.
      await tester.tap(find.byKey(receiveShareKey));
      await _untilRendered(tester, () => h.files.sharedImages.isNotEmpty);
      expect(h.copied, isEmpty);
    });

    testWidgets('where nothing can be shared, only the copy icon shows', (
      tester,
    ) async {
      final h = _Harness(files: _NoShareFiles());
      await h.pump(tester);
      expect(find.byKey(receiveShareKey), findsNothing);
      expect(find.byTooltip('Share'), findsNothing);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      await _tap(tester, _addressText);
      expect(h.copied, [_address]);
    });

    testWidgets('the card reads as a button with the address', (tester) async {
      final handle = tester.ensureSemantics();
      final h = _Harness();
      await h.pump(tester);
      expect(
        tester.getSemantics(find.byKey(receiveAddressKey)),
        matchesSemantics(
          label: 'Epicbox address',
          value: _address,
          isButton: true,
          hasTapAction: true,
          onTapHint: 'Copy',
        ),
      );
      handle.dispose();
    });
  });

  group('share', () {
    testWidgets('shares the card as one PNG with the address as its text', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await tester.tap(find.byTooltip('Share'));
      await _untilRendered(tester, () => h.files.sharedImages.isNotEmpty);
      final shared = h.files.sharedImages.single;
      expect(shared.text, _address);
      expect(shared.name, shareCardFileName);
      expect(_pngSize(shared.png), (1080, 1800));
      expect(h.files.sharedTexts, isEmpty);
      expect(h.container.read(autoLockHoldProvider), 0);
    });

    testWidgets('where only text can be shared, the address goes alone', (
      tester,
    ) async {
      final h = _Harness()..files.canShare = false;
      await h.pump(tester);
      await _tap(tester, find.byTooltip('Share'));
      expect(h.files.sharedTexts, [_address]);
      expect(h.files.sharedImages, isEmpty);
    });

    Future<void> pumpCard(WidgetTester tester, {String? network}) async {
      tester.view.physicalSize = shareCardSize * shareCardPixelRatio;
      tester.view.devicePixelRatio = shareCardPixelRatio;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildWalletTheme(protocolLight, Brightness.light),
          home: Center(
            child: SizedBox.fromSize(
              size: shareCardSize,
              child: ShareCard(
                address: _address,
                headline: 'Pay me in Epic Cash',
                network: network,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('the card fits its size and holds the whole address', (
      tester,
    ) async {
      await pumpCard(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ShareCard)), shareCardSize);
      expect(find.text(_address), findsOneWidget);
      expect(find.text('Pay me in Epic Cash'), findsOneWidget);
      expect(find.byType(EpicMark), findsNWidgets(2));
      expect(tester.widget<MarkedQr>(find.byType(MarkedQr)).data, _address);
      expect(find.text('Floonet'), findsNothing);

      await pumpCard(tester, network: 'Floonet');
      expect(tester.takeException(), isNull);
      expect(find.text('Floonet'), findsOneWidget);
    });

    testWidgets('the card names the network off mainnet only', (tester) async {
      final h = _Harness();
      await h.pump(tester, chain: Chain.floonet);
      final context = tester.element(find.byType(ReceiveView));
      Uint8List? floonet, mainnet;
      await tester.runAsync(() async {
        floonet = await renderShareCard(
          context,
          address: _address,
          chain: Chain.floonet,
        );
        mainnet = await renderShareCard(
          context,
          address: _address,
          chain: Chain.mainnet,
        );
      });
      expect(_pngSize(floonet!), (1080, 1800));
      expect(_pngSize(mainnet!), (1080, 1800));
      // The network pill is the only difference.
      expect(floonet, isNot(equals(mainnet)));
    });
  });

  group('QR code', () {
    testWidgets('holds the full address at level H with the mark', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final marked = tester.widget<MarkedQr>(find.byType(MarkedQr));
      expect(marked.data, _address);
      final view = tester.widget<PrettyQrView>(find.byType(PrettyQrView));
      expect(view.qrImage.errorCorrectLevel, QrErrorCorrectLevel.H);
      final expected = QrImage(
        QrCode.fromData(
          data: _address,
          errorCorrectLevel: QrErrorCorrectLevel.H,
        ),
      );
      expect(view.qrImage.moduleCount, expected.moduleCount);
      for (var x = 0; x < expected.moduleCount; x++) {
        for (var y = 0; y < expected.moduleCount; y++) {
          expect(view.qrImage.isDark(y, x), expected.isDark(y, x));
        }
      }
      // The mark sits in the middle, on a tile at most a fifth of the code's width.
      final code = tester.getRect(find.byType(MarkedQr));
      final mark = find.descendant(
        of: find.byType(MarkedQr),
        matching: find.byType(EpicMark),
      );
      expect(mark, findsOneWidget);
      expect(tester.getCenter(mark), code.center);
      final tile = tester.getRect(
        find.ancestor(of: mark, matching: find.byType(Container)).first,
      );
      expect(tile.width, lessThanOrEqualTo(code.width / 5));
      expect(tile.height, lessThanOrEqualTo(code.width / 5));
    });
  });

  group('epicbox', () {
    testWidgets('each state is one line; offline says what it means', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text('Epicbox connecting'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);

      await h.listener(tester, ListenerEventKind.connected);
      expect(find.text('Connected · epicbox.epiccash.com'), findsOneWidget);
      expect(find.byIcon(EpicGlyphs.epicbox), findsWidgets);
      expect(find.text('Retry'), findsNothing);

      await h.listener(tester, ListenerEventKind.disconnected);
      expect(find.text('Not connected · epicbox.epiccash.com'), findsOneWidget);
      expect(find.textContaining('wait on the Epicbox server'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await h.listener(tester, ListenerEventKind.connected);
      expect(find.text('Connected · epicbox.epiccash.com'), findsOneWidget);
      expect(find.textContaining('wait on the Epicbox server'), findsNothing);

      // A stopped listener receives nothing either.
      await h.listener(tester, ListenerEventKind.stopped);
      expect(find.text('Not connected · epicbox.epiccash.com'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Retry stops the listener, waits for it, and starts it again', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(h.session.listenerStarts, 1);
      await h.listener(tester, ListenerEventKind.disconnected);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      // The shown status follows a turn later.
      await tester.pump();
      expect(h.session.listenerStops, 1);
      expect(find.text('Epicbox connecting'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      // The core starts a new listener only once the old one has stopped.
      expect(h.session.listenerStarts, 1);
      await h.listener(tester, ListenerEventKind.stopped);
      expect(h.session.listenerStarts, 2);
      // The old listener's last word did not make it look stopped.
      expect(find.text('Epicbox connecting'), findsOneWidget);

      await h.listener(tester, ListenerEventKind.connected);
      expect(find.text('Connected · epicbox.epiccash.com'), findsOneWidget);
    });

    testWidgets(
      'Retry starts anyway if the old listener never says it stopped',
      (tester) async {
        final h = _Harness();
        await h.pump(tester);
        await h.listener(tester, ListenerEventKind.disconnected);
        await tester.tap(find.text('Retry'));
        await tester.pump(listenerStopWait - const Duration(milliseconds: 100));
        expect(h.session.listenerStarts, 1);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(h.session.listenerStarts, 2);
      },
    );

    testWidgets('a stream that ends without a word counts as stopped', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      expect(find.text('Epicbox connecting'), findsOneWidget);
      // LEPIC's stream when a listener runs already: it closes with no event.
      await h.session.listenerEvents.close();
      await tester.pumpAndSettle();
      expect(h.container.read(listenerProvider).stopped, isTrue);
      expect(find.text('Not connected · epicbox.epiccash.com'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('an error stays offline when its stream then ends', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      h.session.listenerEvents.addError(StateError('relay gone'));
      await h.session.listenerEvents.close();
      await tester.pumpAndSettle();
      await tester.pump(statusSettle);
      final state = h.container.read(listenerProvider);
      expect(state.lost, isTrue);
      expect(state.stopped, isFalse);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('the relay readout is for Advanced options only', (
      tester,
    ) async {
      await _Harness().pump(tester);
      expect(find.text('Server: epicbox.epiccash.com:443'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _Harness(advanced: true).pump(tester);
      expect(find.text('Server: epicbox.epiccash.com:443'), findsOneWidget);
    });

    // Report gwuouzfy: a network filter refuses every handshake with epicbox.epiccash.com.
    const refused = 'could not connect to the relay: received fatal alert: CloseNotify';

    testWidgets('blocked by the network: says so and switches to another relay in one tap', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      for (var i = 0; i < 2; i++) {
        h.session.listenerEvents.add(
          const ListenerEvent(
            kind: ListenerEventKind.disconnected,
            message: refused,
            reason: refused,
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(find.text('Epicbox blocked'), findsOneWidget);
      expect(
        find.text(
          'This network blocks epicbox.epiccash.com. A network filter may be the cause. '
          'Try another Epicbox server or a private DNS.',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing, reason: 'a restart changes nothing here');
      expect(find.textContaining('wait on the Epicbox server'), findsNothing);
      expect(find.text('Your Epicbox address will change. Share the new one.'), findsOneWidget);

      await _tap(tester, find.text('Switch to epicbox.stackwallet.com'));
      expect(h.session.serverSwitches.single.epicboxDomain, 'epicbox.stackwallet.com');
      expect(
        h.session.serverSwitches.single.nodeUrl,
        h.container.read(networkChoiceProvider).value!.nodeUrl,
        reason: 'the node stays',
      );
      // The listener moves to the new relay: the old one is stopped first.
      await tester.pump(listenerStopWait);
      await tester.pumpAndSettle();
    });

    testWidgets('one refused handshake, or an ordinary outage, is not blocked', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      for (final reason in [
        refused,
        'could not connect to the relay: Connection refused (os error 111)',
      ]) {
        h.session.listenerEvents.add(
          ListenerEvent(kind: ListenerEventKind.disconnected, message: reason, reason: reason),
        );
      }
      await tester.pumpAndSettle();
      await tester.pump(statusSettle);
      await tester.pumpAndSettle();
      expect(find.text('Not connected · epicbox.epiccash.com'), findsOneWidget);
      expect(find.text('Epicbox blocked'), findsNothing);
      expect(find.textContaining('Switch to'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('by file', () {
    testWidgets('a card for everyone with Open file, Paste and its help', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.byFile(tester);
      expect(find.text('Receive by transaction file'), findsOneWidget);
      expect(find.text('Open file'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      // The sheet loops its animation, so it never settles.
      await tester.tap(find.byTooltip('How a transaction file works'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final help = tester.widget<FileExchangeHelp>(
        find.byType(FileExchangeHelp),
      );
      expect(help.role, FileExchangeRole.receiver);
    });

    testWidgets('open a file, accept it, save and share the reply', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.byFile(tester);
      h.files.picks.add(const SlateFile(name: 'photo.jpg', json: 'nope'));
      await _tap(tester, find.text('Open file'));
      expect(find.text('That file is not a transaction file.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      const incoming = '{"id":"incoming"}';
      h.service.slateInfos[incoming] = SlateInfo(
        slateId: 'incoming',
        amount: BigInt.from(300000000),
        fee: BigInt.zero,
        stage: SlateStage.send,
      );
      h.files.picks.add(const SlateFile(name: 'from-bob.tx', json: incoming));
      await _tap(tester, find.text('Open file'));
      expect(find.text('from-bob.tx'), findsOneWidget);
      await _tap(tester, find.text('Accept payment'));
      expect(h.session.receivedSlates, [incoming]);
      await _tap(tester, find.text('Save to device'));
      expect(h.files.saved.single.name, 'from-bob.tx.response');
      await _tap(tester, find.text('Share'));
      expect(h.files.shared.single.name, 'from-bob.tx.response');
      expect(find.text('Copy reply'), findsNothing);
    });

    testWidgets('paste: an empty clipboard and text that is no payment', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.byFile(tester);
      await _tap(tester, find.text('Paste'));
      expect(
        find.text('Copy the payment text first, then tap Paste.'),
        findsOneWidget,
      );
      h.clipboard = 'hello';
      await _tap(tester, find.text('Paste'));
      expect(find.text('That file is not a transaction file.'), findsOneWidget);
      expect(find.byType(SlateFileScreen), findsNothing);
    });

    testWidgets('paste opens the text like a file, and the reply copies', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.byFile(tester);
      const incoming = '{"id":"incoming"}';
      h.service.slateInfos[incoming] = SlateInfo(
        slateId: 'incoming',
        amount: BigInt.from(300000000),
        fee: BigInt.zero,
        stage: SlateStage.send,
      );
      h.clipboard = '  $incoming\n';
      await _tap(tester, find.text('Paste'));
      expect(find.text('Pasted payment'), findsOneWidget);
      expect(find.text('Someone is sending you 3.00000000 EPIC.'), findsOneWidget);
      await _tap(tester, find.text('Accept payment'));
      expect(h.session.receivedSlates, [incoming]);
      expect(
        find.text('Accepted. Return incoming.response to the sender.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Copy reply'));
      expect(h.copied, [h.session.responseSlate.json]);
      await _tap(tester, find.text('Save to device'));
      expect(h.files.saved.single.name, 'incoming.response');
      expect(h.files.saved.single.json, h.session.responseSlate.json);
    });
  });

  group('layout', () {
    for (final state in [
      ListenerEventKind.connected,
      ListenerEventKind.disconnected,
    ]) {
      testWidgets('text scale 2 fits, ${state.name}', (tester) async {
        final h = _Harness(advanced: true);
        await h.pump(tester, textScale: 2);
        await h.listener(tester, state);
        expect(tester.takeException(), isNull);
        await h.byFile(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('Open file'), findsOneWidget);
      });

      testWidgets('tap targets and contrast, ${state.name}', (tester) async {
        final handle = tester.ensureSemantics();
        final h = _Harness();
        await h.pump(tester);
        await h.listener(tester, state);
        for (final tab in ['Epicbox', 'Direct · File']) {
          await _tap(tester, find.descendant(of: find.byKey(receiveTabsKey), matching: find.byTooltip(tab)));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        handle.dispose();
      });
    }
  });
}
