// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/connection_state.dart';
import 'package:epic_wallet/src/dev_networks.dart' show devNetworksProvider;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/phrase_clipboard.dart' show clearCopiedPhrase;
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/file_exchange_help.dart';
import 'package:epic_wallet/src/ui/receive_screen.dart';
import 'package:epic_wallet/src/ui/slate_file_screen.dart';
import 'package:epic_wallet/src/ui/kit/kit_button.dart';
import 'package:epic_wallet/src/ui/kit/kit_tokens.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/brand.dart';
import 'package:epic_wallet/src/ui/theme/logo_qr.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'support/real_time.dart';

final _l = englishStrings;

/// A full-length address, as long as a real one.
/// The address on the Receive card: a rich text whose server sits on its own line.
/// The key part of the address; its server is a line of its own under it (UP-033).
final Finder _addressText = find.byWidgetPredicate(
  (w) =>
      w is SelectableText &&
      w.textSpan?.toPlainText().replaceAll('\n', '') == _address.substring(0, _address.indexOf('@')),
);

const String _address =
    'esVeVUhWwJT4HcFNwCw8wxqauG3SoQ3aKABLyaXWq6HUZ83es6TA@box.epic.invalid';

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
            epicboxDomain: 'box.epic.invalid',
            epicboxPort: 443,
          ),
        );
    await tester.pumpAndSettle();
  }

  /// Opens "Other ways to receive" and then With a file.
  Future<void> byFile(WidgetTester tester) async {
    await _tap(tester, find.text(_l.phoneRecvOther));
    await _tap(tester, find.text(_l.phoneSettingsWithFile));
  }

  Future<void> listener(WidgetTester tester, ListenerEventKind kind) async {
    session.listenerEvents.add(ListenerEvent(kind: kind, message: 'x'));
    await tester.pumpAndSettle();
    // A drop shows once it lasts (walletStatusProvider).
    await tester.pump(statusSettle);
    await tester.pumpAndSettle();
  }
}

/// Waits for the toast to leave: it floats over the top of the screen and takes the touches there.
Future<void> _toastGone(WidgetTester tester) async {
  await tester.pump(noticeDuration(NoticeLevel.success));
  await tester.pumpAndSettle();
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
  await pumpUntil(tester, done);
  expect(done(), isTrue, reason: 'the share card did not render');
}

/// Width and height from a PNG's header.
(int, int) _pngSize(Uint8List png) {
  expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final data = ByteData.sublistView(png);
  return (data.getUint32(16), data.getUint32(20));
}

void main() {
  group('screen', () {
    testWidgets('one screen: the code, the address, the epicbox line, Ask and Other ways', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      for (final key in [receiveAddressKey, receiveEpicboxKey, receiveRequestKey, receiveShareKey]) {
        expect(find.byKey(key), findsOneWidget);
      }
      expect(find.byType(LogoQr), findsOneWidget);
      expect(find.byType(SegmentedButton<ReceiveTab>), findsNothing);
      expect(find.text(_l.phoneRecvAsk), findsOneWidget);
      expect(find.text(_l.phoneRecvOther), findsOneWidget);
      expect(find.text(_l.receiveFileTitle), findsNothing);
      // Top to bottom: the code, the address, the epicbox line, the two rows.
      final tops = [
        for (final f in [find.byType(LogoQr), find.byKey(receiveAddressKey), find.byKey(receiveEpicboxKey), find.byKey(receiveRequestKey)])
          tester.getRect(f).top,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(tester.getRect(find.byKey(receiveRequestKey)).top, lessThan(tester.getRect(find.text(_l.phoneRecvOther)).top));
    });

    testWidgets('Other ways lists With a file, which opens its page and its help', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await _tap(tester, find.text(_l.phoneRecvOther));
      expect(find.text(_l.phoneSettingsWithFile), findsOneWidget);
      await _tap(tester, find.text(_l.phoneSettingsWithFile));
      expect(find.text(_l.receiveFileTitle), findsOneWidget);
      expect(find.byKey(receiveAddressKey), findsNothing);
      expect(find.byType(LogoQr), findsNothing);
      await tester.tap(find.byTooltip(_l.sendHelp));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.widget<FileExchangeHelp>(find.byType(FileExchangeHelp)).role, FileExchangeRole.receiver);
    });

    testWidgets('the code keeps its size where there is room', (tester) async {
      await _Harness().pump(tester);
      expect(tester.getSize(find.byType(LogoQr)), const Size.square(Kit.qr - 24));
    });
  });

  group('address', () {
    testWidgets('an empty Epicbox list: no address, a short reason and the way to add a server', (tester) async {
      final before = hostSettings;
      hostSettings = before.withValues(const {'epicbox.servers': <String>[]});
      addTearDown(() => hostSettings = before);
      final h = _Harness();
      await h.pump(tester);
      expect(find.byKey(const ValueKey('receive-no-epicbox')), findsOneWidget);
      expect(find.textContaining(_l.deskSlNoEpicboxTitle), findsOneWidget);
      expect(find.byKey(receiveAddressKey), findsNothing);
      expect(find.byType(LogoQr), findsNothing);
      expect(find.byType(ErrorText), findsNothing, reason: 'no raw core error');
    });

    testWidgets('the QR code comes first, the full address below it', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      // Advanced options is off, and the address is still whole.
      expect(_addressText, findsOneWidget);
      final card = tester.getRect(find.byKey(receiveAddressKey));
      final qr = tester.getRect(find.byType(LogoQr));
      expect(qr.bottom, lessThan(card.top));
    });

    testWidgets('a tap on the address, or on Copy, copies the whole address', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      // The notice floats over the top and leaves with the next tap.
      for (final target in [_addressText, find.text(_l.commonCopy)]) {
        await _tap(tester, target);
        expect(find.text(_l.receiveAddressCopied), findsOneWidget);
        h.container.read(noticeProvider.notifier).clear();
        await tester.pumpAndSettle();
      }
      expect(h.copied, [_address, _address]);
    });

    testWidgets('Copy and Share sit side by side under the address, as wide as the view allows', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final address = tester.getRect(find.byKey(receiveAddressKey));
      final copy = tester.getRect(find.widgetWithText(KitButton, _l.commonCopy));
      final share = tester.getRect(find.byKey(receiveShareKey));
      expect(copy.top, greaterThanOrEqualTo(address.bottom));
      expect(share.top, closeTo(copy.top, 1));
      expect(share.left, greaterThan(copy.right));
      expect(share.height, greaterThanOrEqualTo(Kit.hitTarget));
      expect(copy.width, closeTo(share.width, 1));
      // Share shares; it does not copy.
      await tester.tap(find.byKey(receiveShareKey));
      await _untilRendered(tester, () => h.files.sharedImages.isNotEmpty);
      expect(h.copied, isEmpty);
    });

    testWidgets('where nothing can be shared, only Copy shows', (
      tester,
    ) async {
      final h = _Harness(files: _NoShareFiles());
      await h.pump(tester);
      expect(find.byKey(receiveShareKey), findsNothing);
      expect(find.text(_l.commonShare), findsNothing);
      expect(find.text(_l.commonCopy), findsOneWidget);
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
      await tester.tap(find.byKey(receiveShareKey));
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
      await _tap(tester, find.byKey(receiveShareKey));
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
      // The key, the server whole on its own line (never "epiccash. / com").
      expect(find.text(_address.split('@').first), findsOneWidget);
      expect(find.text('@${_address.split('@').last}'), findsOneWidget);
      expect(find.text('Pay me in Epic Cash'), findsOneWidget);
      // The card's head; the code paints its own BT Wallet mark.
      expect(find.byType(EpicMark), findsOneWidget);
      expect(tester.widget<LogoQr>(find.byType(LogoQr)).data, _address);
      expect(tester.widget<LogoQr>(find.byType(LogoQr)).logo, QrLogo.bt);
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
    testWidgets('holds the full address at level H with the BT Wallet mark', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      final qr = tester.widget<LogoQr>(find.byType(LogoQr));
      expect(qr.data, _address);
      expect(qr.logo, QrLogo.bt);
      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(of: find.byType(LogoQr), matching: find.byType(CustomPaint)),
          )
          .map((w) => w.painter)
          .whereType<LogoQrPainter>()
          .single;
      expect(painter.image.errorCorrectLevel, QrErrorCorrectLevel.H);
      final expected = QrImage(
        QrCode.fromData(
          data: _address,
          errorCorrectLevel: QrErrorCorrectLevel.H,
        ),
      );
      expect(painter.image.moduleCount, expected.moduleCount);
      for (var x = 0; x < expected.moduleCount; x++) {
        for (var y = 0; y < expected.moduleCount; y++) {
          expect(painter.image.isDark(y, x), expected.isDark(y, x));
        }
      }
      // The clear patch under the mark stays well inside what level H restores.
      final n = expected.moduleCount;
      final patch = LogoQr.patchModules(n);
      expect(patch * patch, lessThan(n * n * 0.1));
    });
  });

  group('epicbox', () {
    testWidgets('each state is one line; offline says what it means', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      expect(find.text(_l.statusEpicboxConnecting), findsOneWidget);
      expect(find.text(_l.commonRetry), findsNothing);

      await h.listener(tester, ListenerEventKind.connected);
      expect(find.text('Connected · box.epic.invalid'), findsOneWidget);
      expect(find.text(_l.commonRetry), findsNothing);

      await h.listener(tester, ListenerEventKind.disconnected);
      expect(find.text('Not connected · box.epic.invalid'), findsOneWidget);
      expect(find.textContaining('wait on the Epicbox server'), findsOneWidget);
      expect(find.text(_l.commonRetry), findsOneWidget);

      await h.listener(tester, ListenerEventKind.connected);
      expect(find.text('Connected · box.epic.invalid'), findsOneWidget);
      expect(find.textContaining('wait on the Epicbox server'), findsNothing);

      // A stopped listener receives nothing either.
      await h.listener(tester, ListenerEventKind.stopped);
      expect(find.text('Not connected · box.epic.invalid'), findsOneWidget);
      expect(find.text(_l.commonRetry), findsOneWidget);
    });

    testWidgets('Retry stops the listener, waits for it, and starts it again', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      expect(h.session.listenerStarts, 1);
      await h.listener(tester, ListenerEventKind.disconnected);

      await tester.tap(find.text(_l.commonRetry));
      await tester.pump();
      // The shown status follows a turn later.
      await tester.pump();
      expect(h.session.listenerStops, 1);
      expect(find.text(_l.statusEpicboxConnecting), findsOneWidget);
      expect(find.text(_l.commonRetry), findsNothing);
      // The core starts a new listener only once the old one has stopped.
      expect(h.session.listenerStarts, 1);
      await h.listener(tester, ListenerEventKind.stopped);
      expect(h.session.listenerStarts, 2);
      // The old listener's last word did not make it look stopped.
      expect(find.text(_l.statusEpicboxConnecting), findsOneWidget);

      await h.listener(tester, ListenerEventKind.connected);
      expect(find.text('Connected · box.epic.invalid'), findsOneWidget);
    });

    testWidgets(
      'Retry starts anyway if the old listener never says it stopped',
      (tester) async {
        final h = _Harness(advanced: true);
        await h.pump(tester);
        await h.listener(tester, ListenerEventKind.disconnected);
        await tester.tap(find.text(_l.commonRetry));
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
      final h = _Harness(advanced: true);
      await h.pump(tester);
      expect(find.text(_l.statusEpicboxConnecting), findsOneWidget);
      // LEPIC's stream when a listener runs already: it closes with no event.
      await h.session.listenerEvents.close();
      await tester.pumpAndSettle();
      expect(h.container.read(listenerProvider).stopped, isTrue);
      expect(find.text('Not connected · box.epic.invalid'), findsOneWidget);
      expect(find.text(_l.commonRetry), findsOneWidget);
    });

    testWidgets('an error stays offline when its stream then ends', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
      await h.pump(tester);
      h.session.listenerEvents.addError(StateError('relay gone'));
      await h.session.listenerEvents.close();
      await tester.pumpAndSettle();
      await tester.pump(statusSettle);
      final state = h.container.read(listenerProvider);
      expect(state.lost, isTrue);
      expect(state.stopped, isFalse);
      expect(find.text(_l.commonRetry), findsOneWidget);
    });

    testWidgets('without Advanced the line says Listening and names no server', (tester) async {
      final h = _Harness();
      await h.pump(tester);
      await h.listener(tester, ListenerEventKind.connected);
      expect(find.text(_l.phoneRecvListening), findsOneWidget);
      expect(find.text('Connected · box.epic.invalid'), findsNothing);
      expect(find.text('Not connected · box.epic.invalid'), findsNothing);
      await h.listener(tester, ListenerEventKind.disconnected);
      expect(find.text(_l.statusEpicboxOffline), findsOneWidget);
      expect(find.text(_l.commonRetry), findsOneWidget);
    });

    testWidgets('the relay readout is for Advanced options only', (
      tester,
    ) async {
      await _Harness().pump(tester);
      expect(find.text('Server: box.epic.invalid:443'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _Harness(advanced: true).pump(tester);
      expect(find.text('Server: box.epic.invalid:443'), findsOneWidget);
    });

    // Report gwuouzfy: a network filter refuses every handshake with box.epic.invalid.
    const refused = 'could not connect to the relay: received fatal alert: CloseNotify';

    testWidgets('blocked by the network: says so and switches to another relay in one tap', (
      tester,
    ) async {
      final h = _Harness(advanced: true);
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
      expect(find.text(_l.statusEpicboxBlocked), findsOneWidget);
      expect(
        find.text(
          'This network blocks box.epic.invalid. A network filter may be the cause. '
          'Try another Epicbox server or a private DNS.',
        ),
        findsOneWidget,
      );
      expect(find.text(_l.commonRetry), findsNothing, reason: 'a restart changes nothing here');
      expect(find.textContaining('wait on the Epicbox server'), findsNothing);
      expect(find.text('Switching gives you a new Epicbox address.'), findsOneWidget);

      await _tap(tester, find.text('Switch to box.stack.invalid'));
      expect(h.session.serverSwitches.single.epicboxDomain, 'box.stack.invalid');
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
      final h = _Harness(advanced: true);
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
      expect(find.text('Not connected · box.epic.invalid'), findsOneWidget);
      expect(find.text(_l.statusEpicboxBlocked), findsNothing);
      expect(find.textContaining('Switch to'), findsNothing);
      expect(find.text(_l.commonRetry), findsOneWidget);
    });
  });

  group('by file', () {
    testWidgets('a card for everyone with Open file, Paste and its help', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.byFile(tester);
      expect(find.text(_l.receiveFileTitle), findsOneWidget);
      expect(find.text(_l.receiveFileOpen), findsOneWidget);
      expect(find.text(_l.commonPaste), findsOneWidget);
      // The sheet loops its animation, so it never settles.
      await tester.tap(find.byTooltip(_l.sendHelp));
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
      await _tap(tester, find.text(_l.receiveFileOpen));
      expect(find.text(_l.slateNotTransactionFile), findsOneWidget);
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
      await _tap(tester, find.text(_l.receiveFileOpen));
      expect(find.text('from-bob.tx'), findsOneWidget);
      await _tap(tester, find.text(_l.slateAcceptPayment));
      expect(h.session.receivedSlates, [incoming]);
      await _tap(tester, find.text(_l.slateSaveToDevice));
      expect(h.files.saved.single.name, 'from-bob.tx.response');
      await _toastGone(tester);
      await _tap(tester, find.text(_l.commonShare));
      expect(h.files.shared.single.name, 'from-bob.tx.response');
      expect(find.text(_l.slateCopyReply), findsNothing);
    });

    testWidgets('paste: an empty clipboard and text that is no payment', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester);
      await h.byFile(tester);
      await _tap(tester, find.text(_l.commonPaste));
      expect(
        find.text(_l.receivePasteEmpty),
        findsOneWidget,
      );
      h.clipboard = 'hello';
      await _tap(tester, find.text(_l.commonPaste));
      expect(find.text(_l.slateNotTransactionFile), findsOneWidget);
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
      await _tap(tester, find.text(_l.commonPaste));
      expect(find.text(_l.slatePastedTitle), findsOneWidget);
      expect(find.text('Someone is sending you 3.0\u00a0EPIC.'), findsOneWidget);
      await _tap(tester, find.text(_l.slateAcceptPayment));
      expect(h.session.receivedSlates, [incoming]);
      expect(
        find.text('Accepted. Return incoming.response to the sender.'),
        findsOneWidget,
      );
      await _tap(tester, find.text(_l.slateCopyReply));
      expect(h.copied, [h.session.responseSlate.json]);
      await _toastGone(tester);
      await _tap(tester, find.text(_l.slateSaveToDevice));
      expect(h.files.saved.single.name, 'incoming.response');
      expect(h.files.saved.single.json, h.session.responseSlate.json);
      // The reply is secret text: its clipboard clear is pending (WAL-04).
      await clearCopiedPhrase();
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
        expect(find.text(_l.receiveFileOpen), findsOneWidget);
      });

      testWidgets('tap targets and contrast, ${state.name}', (tester) async {
        final handle = tester.ensureSemantics();
        final h = _Harness();
        await h.pump(tester);
        await h.listener(tester, state);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        // The file page's back and help buttons are the shared header's (48 x 44): only its
        // own controls are measured.
        await h.byFile(tester);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}
