// Labels on any payment, typed details on a scan find, and the import's "Details differ":
// the title rule, the inline field (Enter, blur, Esc, empty), the pen as a Tab stop with its
// screen-reader name, the details editor only on restored rows, the proof dialog, the dialog
// defaulting to Mine and Cancel writing nothing.
import 'package:epic_wallet/src/desktop/data/history_files.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/screens/settings/backup.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_detail.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_label.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Time passing while a spinner turns behind a dialog: pumpAndSettle would never return.
Future<void> _flow(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

late MockDeskWallet _api;
late ProviderContainer _container;

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A blinking caret would keep pumpAndSettle going.
  EditableText.debugDeterministicCursor = true;
  addTearDown(() => EditableText.debugDeterministicCursor = false);
  _api = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(
    overrides: [
      deskApiProvider.overrideWithValue(_api),
      deskHistoryFilesProvider.overrideWithValue(MockDeskHistoryFiles()),
    ],
  );
  addTearDown(_container.dispose);
  await tester.runAsync(() => _container.read(deskProvider.notifier).refresh());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// The row as the screens hold it. The mock's own calls wait on real timers: a test awaits them in runAsync.
Tx _tx(int id) => _container.read(deskProvider).txs!.firstWhere((t) => t.id == id);

Tx _plain({String? label, String? contact, String? address, bool restored = false}) => Tx(
  id: 7,
  slateId: 'abc',
  direction: TxDirection.received,
  state: TxState.confirmed,
  method: TxMethod.epicbox,
  amount: nanoPerEpic,
  fee: 0,
  created: DateTime(2026, 10, 1),
  label: label,
  contactName: contact,
  counterparty: address,
  foundByScan: restored,
);

const _addr = 'esZr8mQ2pVtW5kNcY7uLfB3hJd9gA4sXeR6oTnC1vK8xHwP2b@epicbox.epicnet.us';

void main() {
  group('the title rule', () {
    test('label, then contact, then short address, then the fallback word', () {
      final l = englishStrings;
      expect(titleOf(l, _plain(label: 'Rent', contact: 'Tom', address: _addr)), 'Rent');
      expect(titleOf(l, _plain(label: '  ', contact: 'Tom', address: _addr)), 'Tom');
      expect(titleOf(l, _plain(address: _addr)), shortAddress(_addr));
      expect(shortAddress(_addr), startsWith('esZr8m'));
      expect(shortAddress(_addr), contains('…'));
      expect(titleOf(l, _plain()), 'Unknown sender');
    });

    test('a scan find is "Restored" until a sender is typed, then that address', () {
      final l = englishStrings;
      expect(titleOf(l, _plain(restored: true)), 'Found by scan');
      expect(titleOf(l, _plain(restored: true, address: _addr)), startsWith('esZr8m'));
      expect(titleOf(l, _plain(restored: true, label: 'Pool')), 'Pool');
    });
  });

  group('Activity', () {
    testWidgets('the pen: its screen-reader name, and a Tab stop that opens the field with Enter', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Rent')));
      expect(find.bySemanticsLabel('Edit label'), findsOneWidget);
      expect(find.text('Rent, October'), findsOneWidget);
      // Tab until the pen has the focus.
      final pen = find.descendant(of: find.byType(TxPen), matching: find.byType(GestureDetector)).first;
      var focused = false;
      for (var i = 0; i < 30 && !focused; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        focused = Focus.of(tester.element(pen)).hasPrimaryFocus;
      }
      expect(focused, isTrue, reason: 'the pen is reachable by Tab');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(TxLabelField), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a row with no label says Add label', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Mining pool payouts')));
      expect(find.bySemanticsLabel('Add label'), findsWidgets);
      expect(find.bySemanticsLabel('Edit label'), findsNothing);
      semantics.dispose();
    });

    Future<void> openField(WidgetTester tester) async {
      await tester.tap(find.byType(TxPen).first);
      await tester.pumpAndSettle();
      expect(find.byType(TxLabelField), findsOneWidget);
    }

    testWidgets('Enter saves, says so, and the row shows the label', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Rent')));
      await openField(tester);
      // Pre-filled, cursor at the end.
      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.controller!.text, 'Rent, October');
      expect(field.controller!.selection.baseOffset, 'Rent, October'.length);
      expect(field.maxLength, 60);
      await tester.enterText(find.byType(TextField).last, 'Rent, November');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect((_tx(35)).label, 'Rent, November');
      expect(find.text('Label saved'), findsOneWidget);
      expect(find.byType(TxLabelField), findsNothing);
      expect(find.text('Rent, November'), findsWidgets);
    });

    testWidgets('a tap outside saves', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Rent')));
      await openField(tester);
      await tester.enterText(find.byType(TextField).last, 'Flat');
      await tester.tapAt(const Offset(1200, 880));
      await tester.pumpAndSettle();
      expect((_tx(35)).label, 'Flat');
      expect(find.text('Label saved'), findsOneWidget);
    });

    testWidgets('the mouse moving off the row keeps the typed text, and a click outside saves it (#107)', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Rent')));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.byType(TxPen).first));
      await tester.pump();
      await openField(tester);
      await tester.enterText(find.byType(TextField).last, 'Flat');
      // Into the field, off the row: the row's hover look changes, the field stays as typed.
      for (final at in [tester.getCenter(find.byType(TxLabelField)), const Offset(640, 600), const Offset(20, 20)]) {
        await mouse.moveTo(at);
        await tester.pump();
        expect(tester.widget<TextField>(find.descendant(of: find.byType(TxLabelField), matching: find.byType(TextField))).controller!.text, 'Flat');
      }
      await tester.tapAt(const Offset(1200, 880));
      await tester.pumpAndSettle();
      expect((_tx(35)).label, 'Flat');
      await mouse.removePointer();
    });

    testWidgets('Esc cancels: nothing written, the old title back', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Rent')));
      await openField(tester);
      await tester.enterText(find.byType(TextField).last, 'Not this');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect((_tx(35)).label, 'Rent, October');
      expect(find.byType(TxLabelField), findsNothing);
      expect(find.text('Rent, October'), findsOneWidget);
      expect(find.textContaining('Label'), findsNothing, reason: 'no notice');
    });

    testWidgets('an empty field removes the label; the contact name is the title again', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Tom')));
      // Tom has more rows than this one now (his Epicbox address): the pen on its line.
      final y = tester.getCenter(find.text('Rent, October')).dy;
      final pens = find.byType(TxPen).evaluate().toList()
        ..sort((a, b) => (tester.getCenter(find.byWidget(a.widget)).dy - y).abs().compareTo((tester.getCenter(find.byWidget(b.widget)).dy - y).abs()));
      await tester.tap(find.byWidget(pens.first.widget));
      await tester.pumpAndSettle();
      expect(find.byType(TxLabelField), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final t = _tx(35);
      expect(t.label, isNull);
      expect(t.manualFields, isEmpty);
      expect(find.text('Label removed'), findsOneWidget);
      expect(find.text('Tom'), findsWidgets);
    });

    testWidgets('unchanged text writes nothing and says nothing', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Rent')));
      await openField(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining('Label '), findsNothing);
    });

    testWidgets('a label that replaces the contact name keeps the name on the second line', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'Exchange top-up')));
      final row = find.byType(TxRow);
      expect(find.descendant(of: row, matching: find.text('Exchange top-up')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.textContaining('Exchange deposit', findRichText: true)), findsOneWidget);
    });

    testWidgets('only one field is open: opening another saves the first', (tester) async {
      await _pump(tester, const ActivityScreen(arg: ActivityArgs(query: 'o')));
      final pens = find.byType(TxPen);
      expect(pens, findsWidgets);
      await tester.tap(pens.first);
      await tester.pumpAndSettle();
      final key = _container.read(txLabelEditingProvider)!.key;
      await tester.enterText(find.byType(TextField).last, 'First');
      // Open the field of another row: the first one saves.
      final other = _container.read(deskProvider).txs!.firstWhere((t) => t.key != key && t.labelText == null).key;
      _container.read(txLabelEditingProvider.notifier).open(other, txLabelRowPlace);
      await tester.pumpAndSettle();
      expect(_container.read(deskProvider).txs!.firstWhere((t) => t.key == key).label, 'First');
    });
  });

  group('details', () {
    testWidgets('the panel title is the label with its tag; Edit label opens the field there', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 35));
      expect(find.text('Rent, October'), findsWidgets);
      expect(find.text('Added by you'), findsWidgets);
      await tester.tap(find.widgetWithText(EButton, 'Edit label'));
      await tester.pumpAndSettle();
      expect(find.byType(TxLabelField), findsOneWidget);
      // Esc puts the title back.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(TxLabelField), findsNothing);
    });

    testWidgets('the details editor is offered only on a restored row', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 102));
      expect(find.widgetWithText(EButton, 'Add details'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const ActivityScreen(arg: 35));
      expect(find.widgetWithText(EButton, 'Add details'), findsNothing);
      expect(find.widgetWithText(EButton, 'Edit'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const ActivityScreen(arg: 103));
      expect(find.widgetWithText(EButton, 'Edit'), findsOneWidget);
    });

    testWidgets('the dialog saves sender, method and note, tagged Added by you', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 102));
      await tester.tap(find.widgetWithText(EButton, 'Add details'));
      await tester.pumpAndSettle();
      expect(find.byType(EDialog), findsOneWidget);
      await tester.tap(find.text('Link · HTTP'));
      final fields = find.descendant(of: find.byType(EDialog), matching: find.byType(TextField));
      await tester.enterText(fields.at(0), '   ');
      await tester.enterText(fields.at(1), 'From the pool');
      await tester.tap(find.widgetWithText(EButton, 'Save'));
      await tester.pumpAndSettle();
      final t = _tx(102);
      expect(t.transport, 'http');
      expect(t.note, 'From the pool');
      expect(t.manualFields, containsAll([ManualField.transport, ManualField.note]));
      expect(t.manualFields, isNot(contains(ManualField.counterparty)));
      expect(find.text('Details added'), findsOneWidget);
    });

    testWidgets('a sender that is no address is refused', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 102));
      await tester.tap(find.widgetWithText(EButton, 'Add details'));
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: find.byType(EDialog), matching: find.byType(TextField)).first, 'not an address');
      await tester.tap(find.widgetWithText(EButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Use an Epicbox, http(s) or .onion address.'), findsOneWidget);
      expect((_tx(102)).counterparty, isNull);
    });

    testWidgets('the mock refuses details on a payment that is not restored', (tester) async {
      await _pump(tester, const ActivityScreen(arg: 35));
      final key = _tx(35).key;
      await tester.runAsync(() => expectLater(_api.setTxDetails(key, note: 'x'), throwsA(isA<DeskError>())));
    });

    testWidgets('the proof never shows a sender the user typed', (tester) async {
      await _pump(
        tester,
        Builder(builder: (c) => TextButton(onPressed: () => showTxProofDialog(c, _tx(103)), child: const Text('open'))),
      );
      expect(_tx(103).manualFields, contains(ManualField.counterparty));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('esZr8m'), findsNothing);
    });
  });

  group('History import', () {
    late String k35, k103;

    Future<void> openImport(WidgetTester tester) async {
      await _pump(tester, Builder(builder: (c) => TextButton(onPressed: () => showImportHistoryDialog(c), child: const Text('open'))));
      k35 = (_tx(35)).key;
      k103 = (_tx(103)).key;
      _api.importConflicts = [
        ImportConflict(key: k35, field: ManualField.label, mine: 'Rent, October', theirs: 'Tom, rent', timeUnix: 1760000000, amount: BigInt.from(-4000000000)),
        ImportConflict(key: k103, field: ManualField.note, mine: null, theirs: 'From the backup', timeUnix: 1760100000, amount: BigInt.from(425000000)),
      ];
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(EButton, 'Choose file…'));
      await _flow(tester);
    }

    testWidgets('Details differ: every field starts as Mine; Cancel writes nothing', (tester) async {
      await openImport(tester);
      expect(find.text('Details differ'), findsOneWidget);
      expect(find.textContaining('2 payments you described'), findsOneWidget);
      // Both Mine cards are selected, the Backup ones are not.
      final selected = tester.widgetList<EChoiceCard>(find.byType(EChoiceCard)).map((c) => '${c.title}:${c.selected}').toList();
      expect(selected, ['Mine:true', 'File:false', 'Mine:true', 'File:false']);
      expect(find.text('empty'), findsOneWidget);
      await tester.tap(find.widgetWithText(EButton, 'Cancel').last);
      await _flow(tester);
      expect(find.text('Details differ'), findsNothing);
      expect(_api.lastUseBackup, isNull, reason: 'only the first call, with no choices, went out');
      expect((_tx(35)).label, 'Rent, October');
      expect((_tx(103)).note, 'Weekly payout from the pool.');
      expect(find.text('Imported'), findsNothing);
    });

    testWidgets('Import applies the choices: Backup replaces, the rest stays; the summary says so', (tester) async {
      await openImport(tester);
      await tester.tap(find.text('File').first);
      await _flow(tester);
      await tester.tap(find.widgetWithText(EButton, 'Import'));
      await _flow(tester);
      expect(_api.lastUseBackup, {'$k35|label': true, '$k103|note': false});
      expect((_tx(35)).label, 'Tom, rent');
      expect((_tx(103)).note, 'Weekly payout from the pool.');
      expect(find.text('1 detail replaced, the rest kept as yours.'), findsOneWidget);
    });

    testWidgets('Keep all mine imports with every field kept', (tester) async {
      await openImport(tester);
      await tester.tap(find.text('File').first);
      await tester.tap(find.widgetWithText(EButton, 'Keep all mine'));
      await _flow(tester);
      expect(_api.lastUseBackup, {'$k35|label': false, '$k103|note': false});
      expect((_tx(35)).label, 'Rent, October');
    });
  });
}
