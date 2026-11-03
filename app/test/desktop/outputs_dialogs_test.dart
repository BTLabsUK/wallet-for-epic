// SPDX-License-Identifier: Apache-2.0
// The Outputs page's cards and its Split and Consolidate dialogs.
import 'package:epic_wallet/src/cancel_final.dart' show CancelResult;
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/models.dart' show nothingToConsolidate;
import 'package:epic_wallet/src/desktop/screens/wallet/outputs_dialogs.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/outputs_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

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
  Future<CancelResult> cancelTx(int id, {bool spendBack = true}) async {
    cancels.add(id);
    return CancelResult.cancelled;
  }

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

      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == _l.deskOutStepperFewer));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == _l.deskOutStepperFewer));
      await tester.pumpAndSettle();
      expect(find.text('Split into 2'), findsOneWidget);
      expect(iconPressed(tester, _l.deskOutStepperFewer), isNull);
      expect(wallet.splitAsks.last, 2);

      // End jumps to 10 from the value field.
      await tester.tap(find.descendant(of: find.byType(EStepper), matching: find.byType(EditableText)));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('Split into 10'), findsOneWidget);
      expect(iconPressed(tester, 'More'), isNull);
      expect(wallet.splitAsks.last, 10);
      expect(find.textContaining(_l.deskOutFactFee), findsOneWidget);
    });

    testWidgets('a new count waits for its own estimate before Split can go', (tester) async {
      await open(tester, (c) => showSplitDialog(c));
      expect(pressed(tester, 'Split into 4'), isNotNull);
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == _l.deskOutStepperFewer));
      await tester.pump();
      expect(pressed(tester, 'Split into 3'), isNull, reason: 'the estimate is still for 4');
      await tester.pumpAndSettle();
      expect(wallet.splitAsks.last, 3);
      expect(pressed(tester, 'Split into 3'), isNotNull);
    });

    testWidgets('outputs under 0.5 EPIC each cannot be made', (tester) async {
      wallet.spendable = _nano(1.5);
      await open(tester, (c) => showSplitDialog(c));
      expect(find.text(_l.deskOutEachMin), findsOneWidget);
      expect(pressed(tester, 'Split into 4'), isNull);
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == _l.deskOutStepperFewer));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byWidgetPredicate((w) => w is EIconButton && w.label == _l.deskOutStepperFewer));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOutEachMin), findsNothing);
      expect(pressed(tester, 'Split into 2'), isNotNull);
    });

    testWidgets('posting cannot be closed', (tester) async {
      await open(tester, (c) => showSplitDialog(c, demo: const SelfSendDemo(SelfSendPhase.posting)), settle: false);
      expect(find.text(_l.deskOutPostingSplit), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is EIconButton && w.label == 'Close (Esc)'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(_l.deskOutSplitDialogTitle), findsOneWidget);
    });

    testWidgets('a split posts and says so', (tester) async {
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      expect(wallet.splits, [4]);
      expect(find.text(_l.deskOutSplitPosted), findsOneWidget);
      expect(find.textContaining('4 outputs of about'), findsOneWidget);
      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOutSplitDialogTitle), findsNothing);
    });

    testWidgets('not posted offers Post again and Cancel, and calls them', (tester) async {
      wallet.sendThrows = const DeskError('Not posted', notPostedTx: 77);
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOutNotPostedTitle), findsOneWidget);
      await tester.tap(find.text(_l.deskOutPostAgain));
      await tester.pumpAndSettle();
      expect(wallet.reposts, [77]);
      expect(find.text(_l.deskOutSplitPosted), findsOneWidget);
    });

    testWidgets('not posted, cancelled', (tester) async {
      wallet.sendThrows = const DeskError('Not posted', notPostedTx: 77);
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l.deskOutCancelSplit));
      await tester.pumpAndSettle();
      expect(wallet.cancels, [77]);
      expect(find.text(_l.deskOutSplitDialogTitle), findsNothing);
    });

    testWidgets('any other failure keeps the outputs and offers Try again', (tester) async {
      wallet.sendThrows = const DeskError('Node not answering');
      await open(tester, (c) => showSplitDialog(c));
      await tester.tap(find.text('Split into 4'));
      await tester.pumpAndSettle();
      expect(find.text('Node not answering. The outputs are unchanged.'), findsOneWidget);
      await tester.tap(find.text(_l.deskOutTryAgain));
      await tester.pumpAndSettle();
      expect(find.text('Split into 4'), findsOneWidget);
    });
  });

  group('Consolidate', () {
    testWidgets('one output: nothing to do', (tester) async {
      await open(tester, (c) => showConsolidateDialog(c, spendableCount: 1));
      expect(find.textContaining('Nothing to consolidate'), findsOneWidget);
      await tester.tap(find.text(_l.commonDone));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOutConsDialogTitle), findsNothing);
    });

    testWidgets('the wallet core finds nothing to merge: said, not an error', (tester) async {
      wallet.consolidateThrows = const DeskError(nothingToConsolidate, nothingToMerge: true);
      await open(tester, (c) => showConsolidateDialog(c, spendableCount: 2));
      expect(find.textContaining(_l.deskOutWhatFewer, findRichText: true), findsOneWidget);
      expect(find.text(_l.deskOutNoEstimate), findsNothing);
      await tester.tap(find.text(_l.commonDone));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOutConsDialogTitle), findsNothing);
    });

    testWidgets('several: fee, then one output', (tester) async {
      await open(tester, (c) => showConsolidateDialog(c, spendableCount: 3));
      expect(find.text(_l.deskOutFactFee), findsOneWidget);
      await tester.tap(find.widgetWithText(EButton, _l.deskOutConsolidateButton));
      await tester.pumpAndSettle();
      expect(wallet.consolidates, 1);
      expect(find.text(_l.deskOutConsPosted), findsOneWidget);
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
      expect(pressed(tester, _l.deskOutSplitCardButton), isNotNull);
      expect(pressed(tester, _l.deskOutConsCardButton), isNotNull);
      expect(find.textContaining('Fee at least'), findsOneWidget);
    });

    testWidgets('something locked: both wait', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent), out(2, 20, OutputStatus.locked)], bal(10, locked: 20));
      expect(pressed(tester, _l.deskOutSplitCardButton), isNull);
      expect(pressed(tester, _l.deskOutConsCardButton), isNull);
      expect(find.text('Wait until the send confirms (about 6 blocks).'), findsNWidgets(2));
      // The note sits behind the Locked tile's info icon, not in the main view.
      expect(find.byWidgetPredicate((w) => w is EInfoHint && w.text.startsWith('Locked outputs are being spent')), findsOneWidget);
    });

    testWidgets('one spendable: split only', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent)], bal(10));
      expect(pressed(tester, _l.deskOutSplitCardButton), isNotNull);
      expect(pressed(tester, _l.deskOutConsCardButton), isNull);
      expect(find.text(_l.deskOutConsOne), findsOneWidget);
    });

    testWidgets('only confirming: nothing yet', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.confirming)], bal(0, confirming: 10));
      expect(pressed(tester, _l.deskOutSplitCardButton), isNull);
      expect(find.text(_l.deskOutSplitNothing), findsOneWidget);
      expect(find.text(_l.deskOutConsNothing), findsOneWidget);
    });

    testWidgets('no outputs: the empty state, cards closed', (tester) async {
      await page(tester, const [], bal(0));
      expect(find.text(_l.deskOutNoneTitle), findsOneWidget);
      expect(pressed(tester, _l.deskOutSplitCardButton), isNull);
      expect(pressed(tester, _l.deskOutConsCardButton), isNull);
    });

    // The send defaults (strategy, Split change) moved to Settings › Transactions:
    // test/desktop/transactions_settings_test.dart.

    testWidgets('spent outputs show only when asked; tiles count outputs', (tester) async {
      await page(tester, [out(1, 10, OutputStatus.unspent), out(2, 5, OutputStatus.spent)], bal(10));
      expect(find.text(_l.deskOutStatusSpent), findsNothing);
      // Spendable and Total count the one unspent output; the spent one is in no tile.
      expect(find.text('1 output'), findsNWidgets(2));
      // Confirming, Immature and Locked: every tile is always there, so the row never jumps.
      expect(find.text('0 outputs'), findsNWidgets(3));
      await tester.tap(find.text(_l.deskOutShowSpent));
      await tester.pumpAndSettle();
      expect(find.text(_l.deskOutStatusSpent), findsOneWidget);
    });
  });
}
