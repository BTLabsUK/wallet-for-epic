// Transaction labels on the phone: the title rule, the pen and its inline field, the details
// of a restored payment, and the "Details differ" sheet of a history import.

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/ui/history_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/ui/tx_label.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

final DateTime _now = DateTime(2026, 9, 30, 12);

int _at(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

final BigInt _tip = BigInt.from(2500000);

const String _alice =
    'esAliceAddressAbcdefghijkmnpqrstuvwxyz1234567890ABCDEF@epicbox.epiccash.com';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

List<TxEntry> _rows() => [
  fakeTx(
    id: 1,
    slateId: 'plain',
    kind: TxKind.received,
    status: TxStatus.confirmed,
    createdAtUnix: _at(DateTime(2026, 9, 29, 9)),
    amountCredited: _epic(5),
    counterparty: _alice,
    blockHeight: _tip - BigInt.from(10),
  ),
  fakeTx(
    id: 2,
    slateId: 'known',
    kind: TxKind.sent,
    status: TxStatus.confirmed,
    createdAtUnix: _at(DateTime(2026, 9, 28, 9)),
    amountDebited: _epic(3),
    amountCredited: BigInt.zero,
    fee: _epic(0.008),
    counterparty: 'esKnownAddress@epicbox.epiccash.com',
    blockHeight: _tip - BigInt.from(20),
  ),
  fakeTx(
    key: 'c:restored',
    id: 3,
    kind: TxKind.received,
    status: TxStatus.confirmed,
    source: TxSource.restored,
    createdAtUnix: _at(DateTime(2026, 9, 27, 9)),
    amountCredited: _epic(7.25),
    blockHeight: _tip - BigInt.from(30),
  ),
];

class _Harness {
  _Harness() {
    session = FakeWalletSession(
      summary: WalletSummary(
        lastConfirmedHeight: _tip,
        minimumConfirmations: BigInt.from(3),
        total: _epic(10),
        spendable: _epic(10),
        awaitingConfirmation: BigInt.zero,
        awaitingFinalization: BigInt.zero,
        immature: BigInt.zero,
        locked: BigInt.zero,
        validatedWithNode: true,
      ),
      transactions: _rows(),
    );
    session.contactsValue.add(
      Contact(
        id: 'c1',
        name: 'Knut',
        address: 'esKnownAddress@epicbox.epiccash.com',
      ),
    );
    store.values['wallet.mainnet.backedUp'] = '1';
    session.owner = service;
  }

  late final FakeWalletSession session;
  final store = MemorySecretStore();
  final files = FakeHistoryFiles()..canShare = false;
  late final service = FakeWalletService(session: session);

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          relayProbeProvider.overrideWithValue(FakeRelayProbe()),
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(MemoryBiometricStore()),
          updatePlatformProvider.overrideWithValue(null),
          historyFilesProvider.overrideWithValue(files),
          clockProvider.overrideWithValue(() => _now),
          sessionProvider.overrideWith(() => _OpenSession(session)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// The text field the pen opened, or none.
Finder _labelField() => find.byType(TextField);

Future<void> _openPen(WidgetTester tester, String tooltip, [int at = 0]) async {
  await tester.tap(find.byTooltip(tooltip).at(at));
  await tester.pumpAndSettle();
}

void main() {
  group('title rule', () {
    testWidgets('label, else contact, else short address, else the word', (
      tester,
    ) async {
      final h = _Harness();
      h.session.labels['s:plain'] = 'Rent, September';
      await h.pump(tester, const HistoryScreen());
      // The label first; the address it replaced joins the second line.
      expect(find.text('Rent, September'), findsOneWidget);
      expect(find.textContaining('esAlic'), findsOneWidget);
      expect(find.text(_alice), findsNothing);
      // The contact's name.
      expect(find.text('Knut'), findsOneWidget);
      // A payment with no counterparty keeps today's word.
      expect(find.text('Restored funds'), findsOneWidget);
    });

    testWidgets('a short address when nobody is named', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      expect(find.text('Rent, September'), findsNothing);
      expect(find.text(_alice), findsNothing);
      expect(find.textContaining('esAlic'), findsOneWidget);
    });

    testWidgets('a labelled row carries the Added by you tag', (tester) async {
      final h = _Harness();
      h.session.labels['s:plain'] = 'Rent';
      await h.pump(tester, const HistoryScreen());
      // A row has room for the pen only; the words are in the tooltip and in details.
      expect(find.byType(ManualTag), findsOneWidget);
    });

    testWidgets('the search finds a label', (tester) async {
      final h = _Harness();
      h.session.labels['s:plain'] = 'Rent, September';
      await h.pump(tester, const HistoryScreen());
      await tester.enterText(
        find.widgetWithText(TextField, 'Search'),
        'septem',
      );
      await tester.pump(searchDebounce);
      await tester.pumpAndSettle();
      expect(find.text('Rent, September'), findsOneWidget);
      expect(find.text('Knut'), findsNothing);
    });
  });

  group('inline label', () {
    testWidgets('every row has a pen with its semantics', (tester) async {
      final h = _Harness();
      h.session.labels['s:plain'] = 'Rent';
      final semantics = tester.ensureSemantics();
      await h.pump(tester, const HistoryScreen());
      expect(find.bySemanticsLabel('Edit label'), findsOneWidget);
      expect(find.bySemanticsLabel('Add label'), findsNWidgets(2));
      final size = tester.getSize(find.byType(LabelPen).first);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      semantics.dispose();
    });

    testWidgets('the pen can be reached with the keyboard', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      var reached = false;
      for (var i = 0; i < 40 && !reached; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus?.context;
        reached =
            focus != null &&
            find
                .ancestor(
                  of: find.byWidget(focus.widget),
                  matching: find.byType(LabelPen),
                )
                .evaluate()
                .isNotEmpty;
      }
      expect(reached, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_labelField(), findsNWidgets(2)); // search + the label field
    });

    testWidgets('Done saves, and says so', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      await _openPen(tester, 'Add label');
      final field = find.widgetWithText(TextField, '');
      expect(find.text('Add label'), findsWidgets);
      await tester.enterText(field.last, '  Rent   September ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(h.session.labels, {'s:plain': 'Rent September'});
      expect(find.text('Rent September'), findsOneWidget);
      expect(find.text('Label added'), findsOneWidget);
    });

    testWidgets('tapping elsewhere saves', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      await _openPen(tester, 'Add label');
      await tester.enterText(find.byType(TextField).last, 'Coffee');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(h.session.labels, {'s:plain': 'Coffee'});
    });

    testWidgets('opening another pen saves the first', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      await _openPen(tester, 'Add label');
      await tester.enterText(find.byType(TextField).last, 'First');
      await tester.tap(find.byTooltip('Add label').first);
      await tester.pumpAndSettle();
      expect(h.session.labels, {'s:plain': 'First'});
    });

    testWidgets('Esc puts the old label back', (tester) async {
      final h = _Harness();
      h.session.labels['s:plain'] = 'Rent';
      await h.pump(tester, const HistoryScreen());
      await _openPen(tester, 'Edit label');
      await tester.enterText(find.byType(TextField).last, 'Something else');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(h.session.labels, {'s:plain': 'Rent'});
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Something else'), findsNothing);
      expect(find.text('Label saved'), findsNothing);
    });

    testWidgets('an empty field removes the label', (tester) async {
      final h = _Harness();
      h.session.labels['s:plain'] = 'Rent';
      await h.pump(tester, const HistoryScreen());
      await _openPen(tester, 'Edit label');
      await tester.enterText(find.byType(TextField).last, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(h.session.labels, isEmpty);
      expect(find.text('Label removed'), findsOneWidget);
    });

    testWidgets('the field stops at 60 characters', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HistoryScreen());
      await _openPen(tester, 'Add label');
      await tester.enterText(find.byType(TextField).last, 'x' * 90);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(h.session.labels['s:plain'], 'x' * 60);
    });

    testWidgets('no change, no notice', (tester) async {
      final h = _Harness();
      h.session.labels['s:plain'] = 'Rent';
      await h.pump(tester, const HistoryScreen());
      await _openPen(tester, 'Edit label');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Label saved'), findsNothing);
    });
  });

  group('details', () {
    testWidgets('the Add label tile turns into the field in place', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:plain'));
      expect(find.text('Add label'), findsOneWidget);
      await tester.tap(find.text('Add label'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Rent');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(h.session.labels, {'s:plain': 'Rent'});
      // With a label the tile reads Label, the value and the tag.
      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Added by you'), findsOneWidget);
      expect(find.text('Rent'), findsWidgets);
    });

    testWidgets('only a restored payment offers details', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 's:plain'));
      expect(find.text('Add details'), findsNothing);
      expect(find.text('Edit details'), findsNothing);
      await h.pump(tester, const TxDetailsScreen(txKey: 'c:restored'));
      expect(find.text('Add details'), findsOneWidget);
    });

    testWidgets('the sheet saves the sender, method and note', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 'c:restored'));
      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
      // The date is a line, not a field.
      expect(find.text('Date'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tor'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Note'), 'Pool');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(h.session.details['c:restored'], (
        counterparty: null,
        transport: 'tor',
        note: 'Pool',
      ));
      expect(find.text('Details added'), findsOneWidget);
      expect(find.text('Edit details'), findsOneWidget);
      // The method row and the tag follow.
      expect(find.text('Method'), findsOneWidget);
      expect(find.text('Added by you'), findsWidgets);
    });

    testWidgets('a sender that is no address is refused', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 'c:restored'));
      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'From'),
        'nonsense',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(h.session.details, isEmpty);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Cancel writes nothing', (tester) async {
      final h = _Harness();
      await h.pump(tester, const TxDetailsScreen(txKey: 'c:restored'));
      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Note'), 'Pool');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.session.details, isEmpty);
    });
  });

  group('Details differ', () {
    ImportConflict conflict(ManualField field, String? mine, String theirs) =>
        ImportConflict(
          key: 'c:restored',
          field: field,
          mine: mine,
          theirs: theirs,
          timeUnix: _at(DateTime(2026, 9, 27, 9)),
          amount: _epic(7.25),
        );

    /// A screen with a button that runs the import, as Settings does.
    Widget host() => Consumer(
      builder: (context, ref, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => importHistoryBackup(context, ref),
            child: const Text('Import now'),
          ),
        ),
      ),
    );

    Future<_Harness> open(WidgetTester tester) async {
      final h = _Harness();
      h.files.picks.add(
        Uint8List.fromList(utf8.encode('FAKE-WFEH{"notes":{},"contacts":[]}')),
      );
      h.session.importConflicts = [
        conflict(ManualField.note, 'Mine note', 'Backup note'),
        conflict(ManualField.transport, null, 'tor'),
      ];
      await h.pump(tester, host());
      await tester.tap(find.text('Import now'));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('shows both values, Mine chosen', (tester) async {
      await open(tester);
      expect(find.text('Details differ'), findsOneWidget);
      expect(find.text('Mine note'), findsOneWidget);
      expect(find.text('Backup note'), findsOneWidget);
      // Tor is shown in its words; an empty value says so.
      expect(find.text('Tor'), findsOneWidget);
      expect(find.text('empty'), findsOneWidget);
      final mine = tester.getSemantics(
        find.bySemanticsLabel('Mine: Mine note'),
      );
      expect(mine.flagsCollection.isChecked, ui.CheckedState.isTrue);
    });

    testWidgets('Import without a choice keeps mine', (tester) async {
      final h = await open(tester);
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      expect(h.session.lastUseBackup, {
        'c:restored|note': false,
        'c:restored|transport': false,
      });
    });

    testWidgets('Keep all mine keeps every value', (tester) async {
      final h = await open(tester);
      await tester.tap(find.text('Backup note'));
      await tester.pump();
      await tester.tap(find.text('Keep all mine'));
      await tester.pumpAndSettle();
      expect(h.session.lastUseBackup, {
        'c:restored|note': false,
        'c:restored|transport': false,
      });
    });

    testWidgets('choosing the backup replaces, and says how many', (
      tester,
    ) async {
      final h = await open(tester);
      await tester.tap(find.text('Backup note'));
      await tester.pump();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      expect(h.session.lastUseBackup, {
        'c:restored|note': true,
        'c:restored|transport': false,
      });
      expect(
        find.textContaining('1 detail replaced, the rest kept'),
        findsOneWidget,
      );
    });

    testWidgets('Cancel writes nothing', (tester) async {
      final h = await open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      // Only the first call, without choices, was made: nothing was applied.
      expect(h.session.lastUseBackup, isNull);
      expect(h.session.importConflicts, isNotEmpty);
      expect(find.text('History imported'), findsNothing);
    });
  });
}
