// The Outputs page's cards and its Split and Consolidate dialogs (design spec §5.3, §6.5).
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/models.dart' show nothingToConsolidate;
import 'package:epic_wallet/src/desktop/screens/wallet/outputs_dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/outputs_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

int _nano(double epic) => (epic * nanoPerEpic).round();

/// The mock wallet with the self-sends scripted and recorded.
class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  /// What spending everything holds; the estimates share it out.
  int spendable = _nano(100);
  int inputs = 3;
  final splitAsks = <int>[];
  final splits = <int>[];
  int consolidates = 0;
  Object? sendThrows;
  final reposts = <int>[];
  final cancels = <int>[];
  OutputPrefs? saved;

  SendEstimate _est(int n) {
    final fee = _nano(0.001) * (4 * n + inputs - 1);
    return SendEstimate(amount: (spendable - fee) ~/ n, fee: fee, inputCount: inputs, locked: spendable, change: spendable - fee - (spendable - fee) ~/ n, changeOutputs: n - 1);
  }

  @override
  Future<SendEstimate> estimateSplit(int outputs) async {
    splitAsks.add(outputs);
    return _est(outputs);
  }

  /// What [estimateConsolidate] throws instead, when set.
  Object? consolidateThrows;

  @override
  Future<SendEstimate> estimateConsolidate() async {
    if (consolidateThrows != null) throw consolidateThrows!;
    return _est(1);
  }

  @override
  Future<SelfSend> splitOutputs(int outputs) async {
    splits.add(outputs);
    if (sendThrows != null) throw sendThrows!;
    final e = _est(outputs);
    return SelfSend(txId: 50, receivedTxId: 51, amount: e.amount, fee: e.fee, inputCount: inputs, outputCount: outputs);
  }

  @override
  Future<SelfSend> consolidateOutputs() async {
    consolidates++;
    final e = _est(1);
    return SelfSend(txId: 50, receivedTxId: 51, amount: e.amount, fee: e.fee, inputCount: inputs, outputCount: 1);
  }

  @override
  Future<void> repostTx(int id) async => reposts.add(id);

  @override
  Future<void> cancelTx(int id) async => cancels.add(id);

  @override
  Future<void> saveOutputPrefs(OutputPrefs prefs) async {
    saved = prefs;
    await super.saveOutputPrefs(prefs);
  }
}

void main() {
  late _Wallet wallet;
  late ProviderContainer container;

  setUp(() {
    wallet = _Wallet();
    container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)]);
  });

  tearDown(() => container.dispose());

  Future<void> host(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, Future<void> Function(BuildContext) dialog, {bool settle = true}) async {
    await host(tester, Builder(builder: (c) => TextButton(onPressed: () => dialog(c), child: const Text('open'))));
    await tester.tap(find.text('open'));
    // The posting spinner never settles.
    settle ? await tester.pumpAndSettle() : await tester.pump(const Duration(milliseconds: 500));
  }

  VoidCallback? pressed(WidgetTester tester, String label) => tester.widget<EButton>(find.widgetWithText(EButton, label)).onPressed;

  VoidCallback? iconPressed(WidgetTester tester, String label) =>
      tester.widget<EIconButton>(find.byWidgetPredicate((w) => w is EIconButton && w.label == label)).onPressed;

  group('Split', () {
    testWidgets('the stepper keeps 2 to 10, estimates each count, keys step it', (tester) async {
      await open(tester, (c) => showSplitDialog(c));
      expect(wallet.splitAsks, [4]);
      expect(find.text('Split into 4'), findsOneWidget);

      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Fewer'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Fewer'));
      await tester.pumpAndSettle();
      expect(find.text('Split into 2'), findsOneWidget);
      expect(iconPressed(tester, 'Fewer'), isNull);
      expect(wallet.splitAsks.last, 2);

      // End jumps to 10 from the value field.
      await tester.tap(find.descendant(of: find.byType(EStepper), matching: find.byType(EditableText)));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('Split into 10'), findsOneWidget);
      expect(iconPressed(tester, 'More'), isNull);
      expect(wallet.splitAsks.last, 10);
      expect(find.textContaining('Network fee'), findsOneWidget);
    });

    testWidgets('outputs under 0.5 EPIC each cannot be made', (tester) async {
      wallet.spendable = _nano(1.5);
      await open(tester, (c) => showSplitDialog(c));
      expect(find.text('Each output must be at least 0.5 EPIC.'), findsOneWidget);
      expect(pressed(tester, 'Split into 4'), isNull);
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Fewer'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Fewer'));
      await tester.pumpAndSettle();
      expect(find.text('Each output must be at least 0.5 EPIC.'), findsNothing);
      expect(pressed(tester, 'Split into 2'), isNotNull);
    });

    testWidgets('posting cannot be closed', (tester) async {
      await open(tester, (c) => showSplitDialog(c, demo: const SelfSendDemo(SelfSendPhase.posting)), settle: false);
      expect(find.text('Building and posting the split. Keep the app open.'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Close (Esc)'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Split outputs'), findsOneWidget);
    });

    testWidgets('a split posts and says so', (tester) async {
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      expect(wallet.splits, [4]);
      expect(find.text('Split posted'), findsOneWidget);
      expect(find.textContaining('The wallet now has 4 outputs of about'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Split outputs'), findsNothing);
    });

    testWidgets('not posted offers Post again and Cancel, and calls them', (tester) async {
      wallet.sendThrows = const DeskError('Not posted', notPostedTx: 77);
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      expect(find.text('Not posted.'), findsOneWidget);
      await tester.tap(find.text('Post again'));
      await tester.pumpAndSettle();
      expect(wallet.reposts, [77]);
      expect(find.text('Split posted'), findsOneWidget);
    });

    testWidgets('not posted, cancelled', (tester) async {
      wallet.sendThrows = const DeskError('Not posted', notPostedTx: 77);
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel the split'));
      await tester.pumpAndSettle();
      expect(wallet.cancels, [77]);
      expect(find.text('Split outputs'), findsNothing);
    });

    testWidgets('any other failure keeps the outputs and offers Try again', (tester) async {
      wallet.sendThrows = const DeskError('Node not answering');
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      expect(find.text('Node not answering. The outputs are unchanged.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Split into 4'), findsOneWidget);
    });
  });

  group('Consolidate', () {
    testWidgets('one output: nothing to do', (tester) async {
      await open(tester, (c) => showConsolidateDialog(c, spendableCount: 1));
      expect(find.textContaining('Nothing to consolidate'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Consolidate outputs'), findsNothing);
    });

    testWidgets('the wallet core finds nothing to merge: said, not an error', (tester) async {
      wallet.consolidateThrows = const DeskError(nothingToConsolidate);
      await open(tester, (c) => showConsolidateDialog(c, spendableCount: 2));
      expect(find.textContaining('fewer than two spendable outputs', findRichText: true), findsOneWidget);
      expect(find.text('No estimate'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Consolidate outputs'), findsNothing);
    });

    testWidgets('several: fee, then one output', (tester) async {
      await open(tester, (c) => showConsolidateDialog(c, spendableCount: 3));
      expect(find.text('Network fee'), findsOneWidget);
      await tester.tap(find.widgetWithText(EButton, 'Consolidate'));
      await tester.pumpAndSettle();
      expect(wallet.consolidates, 1);
      expect(find.text('Consolidate posted'), findsOneWidget);
    });
  });

  group('Cards', () {
    Output out(int i, double epic, OutputStatus s) => Output(commitment: '08${'$i'.padLeft(64, 'a')}', value: _nano(epic), status: s, height: 100 + i, confirmations: 10);
    Balance bal(double spendable, {double locked = 0, double confirming = 0}) =>
        Balance(spendable: _nano(spendable), awaitingConfirmation: _nano(confirming), locked: _nano(locked), awaitingFinalization: 0);

    Future<void> page(WidgetTester tester, List<Output> outputs, Balance b) async {
      await host(tester, OutputsScreen(arg: OutputsArgs(outputs: outputs, balance: b)));
      await tester.pumpAndSettle();
    }

    testWidgets('several spendable, nothing locked: both open', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent), out(2, 20, OutputStatus.unspent)], bal(30));
      expect(pressed(tester, 'Split…'), isNotNull);
      expect(pressed(tester, 'Consolidate…'), isNotNull);
      expect(find.textContaining('Fee from'), findsOneWidget);
    });

    testWidgets('something locked: both wait', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent), out(2, 20, OutputStatus.locked)], bal(10, locked: 20));
      expect(pressed(tester, 'Split…'), isNull);
      expect(pressed(tester, 'Consolidate…'), isNull);
      expect(find.text('Wait until the send confirms (about 3 blocks).'), findsNWidgets(2));
      expect(find.textContaining('Locked outputs are being spent'), findsOneWidget);
    });

    testWidgets('one spendable: split only', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent)], bal(10));
      expect(pressed(tester, 'Split…'), isNotNull);
      expect(pressed(tester, 'Consolidate…'), isNull);
      expect(find.text('Nothing to consolidate: one spendable output.'), findsOneWidget);
    });

    testWidgets('only confirming: nothing yet', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.confirming)], bal(0, confirming: 10));
      expect(pressed(tester, 'Split…'), isNull);
      expect(find.text('Nothing to split yet.'), findsOneWidget);
      expect(find.text('Nothing to consolidate yet.'), findsOneWidget);
    });

    testWidgets('no outputs: the empty state, cards closed', (tester) async {
      await page(tester, const [], bal(0));
      expect(find.text('No outputs yet'), findsOneWidget);
      expect(pressed(tester, 'Split…'), isNull);
      expect(pressed(tester, 'Consolidate…'), isNull);
    });

    testWidgets('the defaults are saved at once', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent)], bal(10));
      await tester.tap(find.descendant(of: find.byType(ESegmented<SelectionStrategy>), matching: find.text('All')));
      await tester.pumpAndSettle();
      expect(wallet.saved?.strategy, SelectionStrategy.all);
      await tester.tap(find.byType(ESwitch));
      await tester.pumpAndSettle();
      expect(wallet.saved, const OutputPrefs(strategy: SelectionStrategy.all, smartOutputs: false));
    });

    testWidgets('spent outputs show only when asked; tiles count outputs', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent), out(2, 5, OutputStatus.spent)], bal(10));
      expect(find.text('Spent'), findsNothing);
      expect(find.text('1 output'), findsOneWidget);
      await tester.tap(find.text('Show spent'));
      await tester.pumpAndSettle();
      expect(find.text('Spent'), findsOneWidget);
    });
  });
}
