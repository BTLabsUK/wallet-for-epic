// SPDX-License-Identifier: Apache-2.0
// The local node's fit check: the verdict rules, the open-time count, the dialog's buttons per
// verdict and its "Don't show this again", and Settings › Node's pick of the local node going
// through it (nothing starts before its Start).
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/node_fit_facts.dart';
import 'package:epic_wallet/src/desktop/data/node_view.dart' show bytesText;
import 'package:epic_wallet/src/desktop/screens/onboarding/local_node_step.dart' show LocalNodeSetupDialog;
import 'package:epic_wallet/src/desktop/screens/settings/local_node_dialogs.dart' show fallbackAskedThisSession;
import 'package:epic_wallet/src/desktop/screens/settings/node_fit_check.dart';
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/settings_node.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/desktop/widgets/server_list_panel.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/secret_store_api.dart' show MemorySecretStore;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;
const _gb = 1000 * 1000 * 1000;
final _chain = bytesText(5 * _gb, _l);

/// This computer's answers, without a store or PowerShell.
class _Fit extends NodeFitFacts {
  _Fit({this.hours, this.meter}) : super(null);

  final double? hours;
  final bool? meter;
  bool skipped = false;

  @override
  Future<double?> hoursPerDay({DateTime? now}) async => hours;

  @override
  Future<bool?> metered() async => meter;

  @override
  Future<bool> skip() async => skipped;

  @override
  Future<void> setSkip(bool skip) async => skipped = skip;
}

/// The mock node with no chain data to reuse and the free space as given.
class _Node extends MockDeskNode {
  _Node({this.free = 118 * _gb});

  final int? free;

  @override
  Future<List<ChainDataInfo>> chainDataCandidates() async => const [];

  @override
  Future<LocalNodeFacts> facts() async => LocalNodeFacts(chainBytes: 5 * _gb, chainBytesMeasured: false, freeBytes: free, minFreeBytes: 2 * _gb, firewallPrompt: false);
}

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  final List<String> calls = [];

  @override
  Future<void> useBuiltInNode(bool on) {
    calls.add('builtin $on');
    return super.useBuiltInNode(on);
  }
}

void main() {
  group('rules', () {
    test('the suggested answer from the hours a day; an hour or two when unknown', () {
      expect(fitOpenOf(null), FitOpen.hours);
      expect(fitOpenOf(0), FitOpen.minutes);
      expect(fitOpenOf(0.3), FitOpen.minutes);
      expect(fitOpenOf(0.34), FitOpen.hours);
      expect(fitOpenOf(2.9), FitOpen.hours);
      expect(fitOpenOf(3), FitOpen.day);
      expect(fitOpenOf(11), FitOpen.day);
    });

    test('verdict: no space, then short visits, then metered, then how long it is open', () {
      expect(fitVerdict(open: FitOpen.day, metered: false), FitVerdict.good);
      expect(fitVerdict(open: FitOpen.hours, metered: false), FitVerdict.wait);
      expect(fitVerdict(open: FitOpen.minutes, metered: false), FitVerdict.public);
      expect(fitVerdict(open: FitOpen.minutes, metered: true), FitVerdict.public);
      expect(fitVerdict(open: FitOpen.day, metered: true), FitVerdict.metered);
      expect(fitVerdict(open: FitOpen.hours, metered: true), FitVerdict.metered);
      expect(fitVerdict(open: FitOpen.day, metered: false, enoughSpace: false), FitVerdict.noSpace);
      expect(fitVerdict(open: FitOpen.minutes, metered: true, enoughSpace: false), FitVerdict.noSpace);
      expect(fitVerdict(open: FitOpen.day, metered: false, enoughSpace: true), FitVerdict.good);
      expect(fitVerdict(open: FitOpen.day, metered: false, enoughSpace: null), FitVerdict.good, reason: 'unknown free space does not decide');
      expect([for (final v in FitVerdict.values) if (fitStarts(v)) v], [FitVerdict.good, FitVerdict.wait, FitVerdict.metered]);
    });

    test('hours a day: whole days since counting began, at most 7, today left out', () {
      final now = DateTime(2026, 11, 9, 15);
      expect(openHoursPerDay({}, now), isNull);
      expect(openHoursPerDay({'2026-11-09': 7200}, now), isNull, reason: 'only today: no whole day yet');
      expect(openHoursPerDay({'2026-11-08': 7200, '2026-11-09': 99999}, now), 2);
      // Counting began three days ago; the day without an open counts as none.
      expect(openHoursPerDay({'2026-11-06': 3600 * 6, '2026-11-08': 3600 * 3}, now), 3);
      final week = {for (var d = 1; d <= 8; d++) '2026-11-0$d': 3600 * d};
      expect(openHoursPerDay(week, now), closeTo((2 + 3 + 4 + 5 + 6 + 7 + 8) / 7, 1e-9), reason: 'the 8th day back is left out');
    });

    test('the count adds per day and keeps today and the 7 days before', () async {
      final fit = NodeFitFacts(DeskStore(MemorySecretStore()));
      for (var d = 1; d <= 9; d++) {
        await fit.addOpen(const Duration(hours: 1), now: DateTime(2026, 11, d, 10));
      }
      await fit.addOpen(const Duration(minutes: 30), now: DateTime(2026, 11, 9, 11));
      expect(await fit.hoursPerDay(now: DateTime(2026, 11, 9, 12)), 1);
      expect(await fit.hoursPerDay(now: DateTime(2026, 11, 10, 12)), closeTo(7.5 / 7, 1e-9), reason: 'the 2nd was dropped when the 10th came: today and 7 days kept');
      expect(await fit.skip(), isFalse);
      await fit.setSkip(true);
      expect(await fit.skip(), isTrue);
    });
  });

  group('dialog', () {
    bool? out;

    Future<void> open(WidgetTester tester, _Fit fit, {_Node? node, bool inUse = false}) async {
      out = null;
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nodeFitFactsProvider.overrideWithValue(fit), deskNodeProvider.overrideWithValue(node ?? _Node())],
          child: MaterialApp(
            theme: buildDeskTheme(Brightness.dark),
            home: Scaffold(body: Builder(builder: (c) => EButton(label: 'open', onPressed: () async => out = await showNodeFitCheck(c, inUse: inUse)))),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('open most of the day: Good fit, Start is the main button and starts', (tester) async {
      await open(tester, _Fit(hours: 6, meter: false));
      expect(find.text(_l.deskNodeFitTitle), findsOneWidget);
      expect(find.text(_l.deskNodeFitGood), findsOneWidget);
      expect(find.text(_l.deskNodeFitOpenHint(6)), findsOneWidget);
      expect(find.text(_l.deskNodeFitNetHintFree), findsOneWidget);
      expect(find.textContaining(_l.deskNodeFitDiskFree(bytesText(118 * _gb, _l), _chain), findRichText: true), findsOneWidget);
      expect(find.widgetWithText(EButton, _l.deskNodeFitNotNow), findsOneWidget);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.deskNodeFitStart)).kind, EBtnKind.primary);
      await tester.tap(find.text(_l.deskNodeFitStart));
      await tester.pumpAndSettle();
      expect(out, isTrue);
    });

    testWidgets('nothing known: an hour or two and no data limit, no hints; Not now keeps the node', (tester) async {
      final fit = _Fit();
      await open(tester, fit);
      expect(find.text(_l.deskNodeFitWait), findsOneWidget);
      expect(find.text(_l.deskNodeFitNetHintFree), findsNothing);
      expect(find.text(_l.deskNodeFitNetHintMetered), findsNothing);
      await tester.tap(find.text(_l.deskNodeFitNotNow));
      await tester.pumpAndSettle();
      expect(out, isFalse);
      expect(fit.skipped, isFalse);
    });

    testWidgets('Windows says metered: the download verdict and its size; the answer can be changed', (tester) async {
      await open(tester, _Fit(hours: 5, meter: true));
      expect(find.text(_l.deskNodeFitNetHintMetered), findsOneWidget);
      expect(find.text(_l.deskNodeFitMetered), findsOneWidget);
      expect(find.text(_l.deskNodeFitMeteredText(_chain)), findsOneWidget);
      expect(find.text(_l.deskNodeFitDownload(_chain)), findsOneWidget);
      await tester.tap(find.text(_l.deskNodeFitNetFree));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskNodeFitGood), findsOneWidget);
    });

    testWidgets('a few minutes: a public node fits better; Keep public node is the main button', (tester) async {
      final fit = _Fit(hours: 6, meter: false);
      await open(tester, fit);
      await tester.tap(find.text(_l.deskNodeFitOpenMinutes));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskNodeFitPublic), findsOneWidget);
      expect(find.text(_l.deskNodeFitStart), findsNothing);
      expect(tester.widget<EButton>(find.widgetWithText(EButton, _l.deskNodeFitKeepPublic)).kind, EBtnKind.primary);
      // Don't show this again is kept with either button.
      await tester.tap(find.text(_l.deskNodeFitDontShow));
      await tester.pump();
      await tester.tap(find.text(_l.deskNodeFitKeepPublic));
      await tester.pumpAndSettle();
      expect(out, isFalse);
      expect(fit.skipped, isTrue);
    });

    testWidgets('too little free space: the space verdict; Start it anyway still starts', (tester) async {
      await open(tester, _Fit(hours: 6), node: _Node(free: 6 * _gb));
      expect(find.text(_l.deskNodeFitNoSpace), findsOneWidget);
      expect(find.text(_l.deskNodeFitNoSpaceText(_chain, bytesText(2 * _gb, _l))), findsOneWidget);
      await tester.tap(find.text(_l.deskNodeFitStartAnyway));
      await tester.pumpAndSettle();
      expect(out, isTrue);
    });

    testWidgets('from Help with the local node in use: only Close, no checkbox', (tester) async {
      await open(tester, _Fit(hours: 6), inUse: true);
      expect(find.text(_l.deskNodeFitInUse), findsOneWidget);
      expect(find.text(_l.deskNodeFitDontShow), findsNothing);
      expect(find.text(_l.deskNodeFitStart), findsNothing);
      await tester.tap(find.text(_l.commonClose));
      await tester.pumpAndSettle();
      expect(out, isFalse);
    });
  });

  group('Settings › Node', () {
    late _Node node;
    late _Wallet wallet;
    late _Fit fit;
    late ProviderContainer container;

    setUp(() {
      node = _Node();
      wallet = _Wallet();
      fit = _Fit(hours: 6, meter: false);
      fallbackAskedThisSession = false;
      container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet), deskNodeProvider.overrideWithValue(node), nodeFitFactsProvider.overrideWithValue(fit)]);
    });

    tearDown(() => container.dispose());

    Future<void> show(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsNodeScreen())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> end(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
    }

    void pickLocal(WidgetTester tester) => tester.widget<ServerListPanel>(find.byType(ServerListPanel)).onChoose(builtinNode);

    testWidgets('picking the local node opens the fit check; Not now starts nothing', (tester) async {
      await show(tester);
      pickLocal(tester);
      await settle(tester);
      expect(find.text(_l.deskNodeFitTitle), findsOneWidget);
      await tester.tap(find.text(_l.deskNodeFitNotNow));
      await settle(tester);
      expect(wallet.calls, isEmpty);
      expect(container.read(settingsPrefsProvider).builtin, isFalse);
      await end(tester);
    });

    testWidgets('Start: the node starts with the public node meanwhile, said in the toast', (tester) async {
      await show(tester);
      pickLocal(tester);
      await settle(tester);
      await tester.tap(find.text(_l.deskNodeFitStart));
      await settle(tester);
      expect(find.byType(LocalNodeSetupDialog), findsNothing, reason: 'nothing for the setup step to settle');
      expect(wallet.calls, ['builtin true']);
      expect(container.read(settingsPrefsProvider).builtin, isTrue);
      expect((await node.fallbackChoice()).consent, FallbackConsent.accepted);
      expect(find.text(_l.deskNodeFitStarted), findsOneWidget);
      expect(find.textContaining('until the node is in sync'), findsOneWidget);
      await end(tester);
    });

    testWidgets('a public node turned down before stays off: the toast says the wallet waits', (tester) async {
      await node.setFallbackChoice(const FallbackChoice(FallbackConsent.declined));
      fit.skipped = true;
      await show(tester);
      pickLocal(tester);
      await settle(tester);
      expect(find.text(_l.deskNodeFitTitle), findsNothing, reason: 'turned off with Don’t show this again');
      expect(wallet.calls, ['builtin true']);
      expect((await node.fallbackChoice()).consent, FallbackConsent.declined);
      expect(find.text(_l.deskNodeFitStartedAlone), findsOneWidget);
      await end(tester);
    });

    testWidgets('another node answers here: the setup step follows the fit check', (tester) async {
      node.probeAnswer = const LocalNodeProbe(url: 'http://127.0.0.1:3413', answers: true);
      await show(tester);
      pickLocal(tester);
      await settle(tester);
      await tester.tap(find.text(_l.deskNodeFitStart));
      await settle(tester);
      expect(find.byType(LocalNodeSetupDialog), findsOneWidget);
      expect(wallet.calls, isEmpty);
      await tester.tap(find.text(_l.commonCancel));
      await settle(tester);
      expect(wallet.calls, isEmpty);
      await end(tester);
    });

    testWidgets('from Help: the fit check done, the page starts the node without asking again', (tester) async {
      tester.view.physicalSize = const Size(1280, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: SettingsNodeScreen(arg: NodeFitStart()))),
        ),
      );
      await settle(tester);
      expect(find.text(_l.deskNodeFitTitle), findsNothing);
      expect(wallet.calls, ['builtin true']);
      await end(tester);
    });
  });
}
