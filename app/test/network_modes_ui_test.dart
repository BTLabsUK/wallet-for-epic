// SPDX-License-Identifier: Apache-2.0
// The phone's network-mode UI: the Network section (rows, info sheets, the line of the chosen
// mode, the switch confirmation), the cold-payment screens (Finished, not posted; Post a
// finished payment) over a fake wallet, and the words the modes use.

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/tor_build.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/finished_not_posted.dart';
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/network_mode_phone.dart';
import 'package:epic_wallet/src/ui/network_mode_text.dart';
import 'package:epic_wallet/src/ui/post_finished_screen.dart';
import 'package:epic_wallet/src/ui/theme/advanced.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

class _Home extends HomeNotifier {
  _Home(this.txs);

  final List<TxEntry> txs;

  @override
  Future<HomeData> build() async => HomeData(
    summary: WalletSummary(
      lastConfirmedHeight: BigInt.from(100),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.zero,
      spendable: BigInt.zero,
      awaitingConfirmation: BigInt.zero,
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.zero,
      validatedWithNode: false,
    ),
    transactions: txs,
  );
}

class _Tor extends PhoneTor {
  @override
  PhoneTorState build() => const PhoneTorState(phase: PhoneTorPhase.off, onion: 'x');
}

class _Session extends SessionNotifier {
  _Session(this.value);

  final WalletSession? value;

  @override
  WalletSession? build() => value;
}

/// A wallet whose core cannot write the finished payment yet.
class _OldCore extends FakeWalletSession {
  @override
  Future<String> finishedPaymentText({required int txId}) async =>
      throw const WalletError(kind: WalletErrorKind.other, message: 'finished payment needs a newer LEPIC');
}

final _sentEpicbox = fakeTx(key: 's:a', id: 1, slateId: 'a', kind: TxKind.sent, status: TxStatus.awaitingRecipient, transport: 'epicbox');
final _sentFile = fakeTx(key: 's:b', id: 2, slateId: 'b', kind: TxKind.sent, status: TxStatus.awaitingRecipient, transport: 'file');

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget child, {
  List<TxEntry> txs = const [],
  FakeWalletSession? session,
  FakeSlateFiles? files,
  NetworkMode mode = NetworkMode.standard,
  bool bare = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        homeProvider.overrideWith(() => _Home(txs)),
        phoneTorProvider.overrideWith(_Tor.new),
        sessionProvider.overrideWith(() => _Session(session)),
        if (files != null) slateFilesProvider.overrideWithValue(files),
        if (mode != NetworkMode.standard) networkModeProvider.overrideWithValue(mode),
      ],
      child: MaterialApp(
        theme: buildWalletTheme(protocolDark, Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => AdvancedOptions(prefs: AdvancedPrefs(networkMode: mode), child: app!),
        home: bare ? child : Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  // The shell keeps Home alive; the section reads its sends.
  container.listen(homeProvider, (_, _) {}, fireImmediately: true);
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    NetGate.set(NetworkMode.standard);
    useNetworkModeFile(NetworkMode.standard);
  });

  group('the words', () {
    testWidgets('every mode has a name, a line, an info text and a glyph; Normal has no note', (tester) async {
      final l = lookupAppLocalizations(const Locale('en'));
      for (final m in NetworkMode.values) {
        expect(networkModeName(l, m), isNotEmpty);
        expect(networkModeLine(l, m, tor: true), isNotEmpty);
        expect(networkModeHint(l, m, tor: true), isNotEmpty);
        expect(networkModeGlyph(m), isNotNull);
      }
      expect(networkModeName(l, NetworkMode.nodeOnly), 'Node only');
      expect(networkModeName(l, NetworkMode.killSwitch), 'Kill switch');
      expect(networkModeSwitchNote(l, NetworkMode.standard), isNull);
      expect(networkModeSwitchNote(l, NetworkMode.killSwitch), contains('Every connection stops now'));
      expect(statusOffByModeWord(l, NetworkMode.nodeOnly), 'Off (Node only)');
    });

    test('no Tor build: three rows, no Tor sentence in a line or an info text', () {
      final l = lookupAppLocalizations(const Locale('en'));
      expect(offeredNetworkModes(tor: false), [NetworkMode.standard, NetworkMode.nodeOnly, NetworkMode.killSwitch]);
      expect(offeredNetworkModes(tor: true), NetworkMode.values);
      for (final m in offeredNetworkModes(tor: false)) {
        expect(networkModeLine(l, m, tor: false), isNot(contains('Tor')), reason: m.name);
        expect(networkModeHint(l, m, tor: false), isNot(contains('Tor')), reason: m.name);
        expect(networkModeHint(l, m, desktop: true, tor: false), isNot(contains('Tor')), reason: m.name);
      }
      expect(networkHeaderHint(l, tor: false), isNot(contains('Tor')));
      expect(networkHeaderHint(l, tor: true), contains('Tor only'));
    });
  });

  group('the Network section', () {
    testWidgets('a row per mode, each with its line and its info sheet', (tester) async {
      await _pump(tester, const NetworkModeSection());
      final modes = offeredNetworkModes();
      expect(modes.length, torBuilt ? 4 : 3);
      final l = lookupAppLocalizations(const Locale('en'));
      for (final m in modes) {
        expect(find.byKey(networkModeRowKey(m)), findsOneWidget, reason: m.name);
        expect(find.text(networkModeName(l, m)), findsWidgets);
        expect(find.byKey(networkModeHintKey(m)), findsOneWidget);
      }
      await _tapKey(tester, networkModeHintKey(NetworkMode.killSwitch));
      expect(find.byType(InfoSheet), findsOneWidget);
      expect(find.textContaining('cold storage'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      // Normal is the one chosen; it brings no line under the picker.
      expect(tester.widget<Radio<NetworkMode>>(find.descendant(of: find.byKey(networkModeRowKey(NetworkMode.standard)), matching: find.byType(Radio<NetworkMode>))).value, NetworkMode.standard);
      expect(find.byKey(networkModeNoteKey), findsNothing);
    });

    testWidgets('Node only switches at once with no question, and shows its line', (tester) async {
      final container = await _pump(tester, const NetworkModeSection());
      await container.read(appSettingsProvider.future);
      await _tapKey(tester, networkModeRowKey(NetworkMode.nodeOnly));
      expect(find.byKey(networkModeConfirmKey), findsNothing);
      expect(NetGate.mode, NetworkMode.nodeOnly);
      expect(container.read(networkModeProvider), NetworkMode.nodeOnly);
      expect(find.text('Epicbox, Link, price and update checks stop now. A payment waiting over Epicbox continues when you leave Node only.'), findsOneWidget);
    });

    testWidgets('a send waiting over Epicbox: Kill switch asks first, Cancel keeps the mode, Switch applies it', (tester) async {
      final container = await _pump(tester, const NetworkModeSection(), txs: [_sentEpicbox, _sentFile]);
      await container.read(appSettingsProvider.future);
      await _tapKey(tester, networkModeRowKey(NetworkMode.killSwitch));
      expect(find.byKey(networkModeConfirmKey), findsOneWidget);
      expect(find.text('Switch to Kill switch?'), findsOneWidget);
      // The file send does not count: it waits for a file, not for a listener.
      expect(find.textContaining('1 payment is waiting for the recipient over Epicbox or Link. It pauses and continues when you leave Kill switch. Nothing is cancelled.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(NetGate.mode, NetworkMode.standard);
      await _tapKey(tester, networkModeRowKey(NetworkMode.killSwitch));
      await _tapKey(tester, const ValueKey('net-mode-confirm-switch'));
      expect(NetGate.mode, NetworkMode.killSwitch);
      expect(find.text('Every connection stops now, the node included. Waiting payments pause until you leave Kill switch.'), findsOneWidget);
    });

    testWidgets('only a file send waits: no question', (tester) async {
      final container = await _pump(tester, const NetworkModeSection(), txs: [_sentFile]);
      await container.read(appSettingsProvider.future);
      await _tapKey(tester, networkModeRowKey(NetworkMode.killSwitch));
      expect(find.byKey(networkModeConfirmKey), findsNothing);
      expect(NetGate.mode, NetworkMode.killSwitch);
    });

    testWidgets('leaving Kill switch asks nothing, whatever waits', (tester) async {
      final container = await _pump(tester, const NetworkModeSection(), txs: [_sentEpicbox]);
      await container.read(appSettingsProvider.future);
      await container.read(appSettingsProvider.notifier).setNetworkMode(NetworkMode.killSwitch);
      await tester.pumpAndSettle();
      await _tapKey(tester, networkModeRowKey(NetworkMode.standard));
      expect(find.byKey(networkModeConfirmKey), findsNothing);
      expect(NetGate.mode, NetworkMode.standard);
    });
  });

  group('the mode mark', () {
    testWidgets('shown off Normal only, with the mode name', (tester) async {
      final container = await _pump(tester, const NetworkModeMark());
      // Normal: the widget is there and draws nothing.
      expect(find.descendant(of: find.byKey(networkModeMarkKey), matching: find.byType(Icon)), findsNothing);
      expect(find.text('Normal'), findsNothing);
      await container.read(appSettingsProvider.future);
      await container.read(appSettingsProvider.notifier).setNetworkMode(NetworkMode.killSwitch);
      await tester.pumpAndSettle();
      expect(find.byKey(networkModeMarkKey), findsOneWidget);
      expect(find.descendant(of: find.byKey(networkModeMarkKey), matching: find.text('Kill switch')), findsOneWidget);
    });
  });

  group('Finished, not posted', () {
    final stuck = fakeTx(key: 's:fin', id: 7, slateId: 'abcdef0123456789', kind: TxKind.sent, status: TxStatus.awaitingConfirmation, repostable: true, amountDebited: BigInt.from(1000000000), amountCredited: BigInt.zero);

    testWidgets('Kill switch: the title, Save file writes <id8>.finished.tx, Show QR opens the code', (tester) async {
      NetGate.set(NetworkMode.killSwitch);
      final files = FakeSlateFiles();
      await _pump(tester, FinishedNotPosted(tx: stuck), session: FakeWalletSession(), files: files);
      expect(find.byKey(finishedTitleKey), findsOneWidget);
      expect(find.text('Finished, not posted'), findsOneWidget);
      expect(find.textContaining('Kill switch is on, so this phone can’t post it'), findsOneWidget);
      await _tapKey(tester, finishedSaveKey);
      expect(files.saved.single.name, 'abcdef01.finished.tx');
      await _tapKey(tester, finishedQrKey);
      expect(find.text('Finished payment'), findsWidgets);
    });

    testWidgets('a core that cannot write the text yet says so, politely', (tester) async {
      NetGate.set(NetworkMode.killSwitch);
      await _pump(tester, FinishedNotPosted(tx: stuck), session: _OldCore(), files: FakeSlateFiles());
      await _tapKey(tester, finishedSaveKey);
      expect(find.text('This version can’t save a finished payment yet.'), findsOneWidget);
    });

    testWidgets('the row and the status word read To be posted elsewhere under Kill switch only', (tester) async {
      final l = lookupAppLocalizations(const Locale('en'));
      expect(toPostElsewhere(stuck, killSwitch: true), isTrue);
      NetGate.set(NetworkMode.killSwitch);
      expect(txStatusLabel(l, stuck, BigInt.from(100)), 'To be posted elsewhere');
      NetGate.set(NetworkMode.standard);
      expect(txStatusLabel(l, stuck, BigInt.from(100)), isNot('To be posted elsewhere'));
    });
  });

  group('Post a finished payment', () {
    void clipboard(WidgetTester tester, String? text) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') return text == null ? null : <String, Object?>{'text': text};
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    }

    testWidgets('paste, read the summary, post, done', (tester) async {
      final session = FakeWalletSession();
      clipboard(tester, FakeWalletSession.fakeFinishedText(5));
      await _pump(tester, const PostFinishedScreen(), bare: true, session: session);
      expect(find.text('Post a finished payment'), findsOneWidget);
      expect(find.byKey(postFinishedPostKey), findsNothing);
      await _tapKey(tester, postFinishedPasteKey);
      expect(find.byKey(postFinishedSummaryKey), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Fee'), findsOneWidget);
      expect(find.text('Kernel'), findsOneWidget);
      expect(find.text('Posting puts it on the network. The wallet that made it shows it confirming once it sees it on chain.'), findsOneWidget);
      await _tapKey(tester, postFinishedPostKey);
      expect(session.postedFinished, hasLength(1));
      expect(find.byKey(postFinishedDoneKey), findsOneWidget);
      expect(find.text('Posted'), findsOneWidget);
    });

    testWidgets('a text that is not a finished payment says so', (tester) async {
      final session = FakeWalletSession();
      clipboard(tester, '{"not":"a payment"}');
      await _pump(tester, const PostFinishedScreen(), bare: true, session: session);
      await _tapKey(tester, postFinishedPasteKey);
      expect(find.byKey(postFinishedErrorKey), findsOneWidget);
      expect(find.textContaining('Not a finished payment.'), findsOneWidget);
      expect(find.byKey(postFinishedSummaryKey), findsNothing);
    });

    testWidgets('Kill switch: every way in is disabled, with the one-line note', (tester) async {
      NetGate.set(NetworkMode.killSwitch);
      await _pump(tester, const PostFinishedScreen(), bare: true, session: FakeWalletSession(), mode: NetworkMode.killSwitch);
      expect(find.text('Off in Kill switch: nothing connects here.'), findsOneWidget);
      for (final key in [postFinishedOpenKey, postFinishedScanKey, postFinishedPasteKey]) {
        expect(tester.widget<OutlinedButton>(find.byKey(key)).onPressed, isNull, reason: '$key');
      }
    });

    testWidgets('Activity has the entry in its menu', (tester) async {
      await _pump(tester, const HistoryScreen(), bare: true, session: FakeWalletSession());
      await tester.tap(find.byKey(historyMenuKey));
      await tester.pumpAndSettle();
      expect(find.byKey(historyPostFinishedKey), findsOneWidget);
      await tester.tap(find.byKey(historyPostFinishedKey));
      await tester.pumpAndSettle();
      expect(find.byType(PostFinishedScreen), findsOneWidget);
    });
  });
}
