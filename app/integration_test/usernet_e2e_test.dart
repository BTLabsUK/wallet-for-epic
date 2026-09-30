// Full stack on a device against the local usernet: the real UI, the real core, the local epicbox
// relay and a stock epic-wallet CLI on the other side. Run it with
// `integration_test/usernet_e2e.sh`, which prepares the host side and passes
// `--dart-define=WFE_E2E=usernet`; without that define the test is skipped.
//
// The host script watches this test's output for `WFE_E2E address=<address>` and then has the
// CLI send to it. Everything else (mining, the CLI answering our send) runs on the host
// throughout. The recovery phrase is read through the core and never printed.
import 'dart:io';
import 'dart:typed_data';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/rust/frb_generated.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _mode = String.fromEnvironment('WFE_E2E');
const _cliAddress = String.fromEnvironment('WFE_CLI_ADDRESS');
const _pin = '314159';
const _note = 'e2e: 0.3 back to the CLI';

final BigInt _epic = BigInt.from(100000000);

/// Saves the history backup in the app's documents directory and hands it back on import:
/// the test-only stand-in for the system file dialogs.
class _DocumentsHistoryFiles implements HistoryFiles {
  _DocumentsHistoryFiles(this.dir);

  final Directory dir;
  File get _file => File('${dir.path}/e2e-backup.wfeh');

  @override
  bool get canShare => false;

  @override
  Future<bool> save({required String name, required Uint8List bytes}) async {
    await _file.writeAsBytes(bytes, flush: true);
    return true;
  }

  @override
  Future<bool> share({required String name, required Uint8List bytes}) async =>
      false;

  @override
  Future<Uint8List?> pick() async =>
      await _file.exists() ? _file.readAsBytes() : null;
}

/// Pumps frames until [finder] matches, since native calls and the chain run in real time.
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(minutes: 2),
  Future<void> Function()? poke,
  Duration pokeEvery = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  var nextPoke = DateTime.now().add(pokeEvery);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      // What is on screen, from `Text` widgets only: text fields (the phrase) are not included.
      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .where((t) => t.isNotEmpty)
          .take(60)
          .join(' | ');
      fail('Timed out after $timeout waiting for $finder. On screen: $shown');
    }
    if (poke != null && DateTime.now().isAfter(nextPoke)) {
      await poke();
      nextPoke = DateTime.now().add(pokeEvery);
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Polls [check] (a core read) until it holds, pumping frames in between.
Future<T> _waitFor<T>(
  WidgetTester tester,
  String what,
  Future<T?> Function() check, {
  Duration timeout = const Duration(minutes: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (true) {
    final value = await check();
    if (value != null) return value;
    if (DateTime.now().isAfter(end)) fail('Timed out after $timeout: $what');
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _pumpUntil(tester, field);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps the first match of [label], scrolling a lazy list until it is built if need be.
Future<void> _tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (finder.evaluate().isEmpty) {
    final lists = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    if (lists.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: lists.last,
        maxScrolls: 60,
      );
    }
  }
  await _pumpUntil(tester, finder);
  await _tap(tester, finder.first);
}

Future<void> _pinSetup(WidgetTester tester) async {
  await _enter(tester, 'PIN', _pin);
  await _enter(tester, 'Repeat PIN', _pin);
}

Future<void> _refreshHome(WidgetTester tester) async {
  final refresh = find.byTooltip('Refresh');
  if (refresh.evaluate().isNotEmpty) {
    await tester.tap(refresh.first);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// In History, opens the 0.3 EPIC send and checks its details show the note.
Future<void> _openPaymentWithNote(WidgetTester tester) async {
  final row = find.textContaining('-0.3 EPIC');
  await _pumpUntil(tester, row, timeout: const Duration(minutes: 1));
  _clearNotices(tester);
  await tester.pump(const Duration(milliseconds: 500));
  await _tap(tester, row.first);
  await _pumpUntil(
    tester,
    find.textContaining(_note),
    timeout: const Duration(seconds: 30),
  );
  expect(find.text('Completed'), findsWidgets);
}

/// Back to home: pops every route above it.
Future<void> _backHome(WidgetTester tester) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .popUntil((route) => route.isFirst);
  // Not pumpAndSettle: progress indicators and the listener never settle.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Hides snack bars (payment notices), which can sit over the row a test taps.
void _clearNotices(WidgetTester tester) {
  for (final m in tester.stateList<ScaffoldMessengerState>(
    find.byType(ScaffoldMessenger),
  )) {
    m.clearSnackBars();
  }
}

/// On home, refreshes until [n] rows say Completed (10 confirmations, as the app counts).
Future<void> _untilCompleted(WidgetTester tester, int n) async {
  final end = DateTime.now().add(const Duration(minutes: 6));
  while (find.text('Completed').evaluate().length < n) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out waiting for $n completed rows');
    }
    await _refreshHome(tester);
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

WalletSession _session(WidgetTester tester) =>
    _container(tester).read(sessionProvider)!;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'usernet end to end: receive, send with a note, back up, delete, restore, import',
    (tester) async {
      await RustLib.init();
      final started = DateTime.now();
      final base = await getApplicationDocumentsDirectory();
      final root = await Directory(
        '${base.path}/wfe-e2e-${started.millisecondsSinceEpoch}',
      ).create(recursive: true);
      addTearDown(() => root.delete(recursive: true));
      final store = MemorySecretStore();
      // Usernet preselected, as the network settings would save it. Its preset reaches the
      // host's node and relay through `adb reverse`.
      await store.write('app.network', 'usernet');

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            walletDirProvider.overrideWithValue((chain) async {
              final dir = Directory('${root.path}/${chain.name}');
              await dir.create(recursive: true);
              return dir.path;
            }),
            secretStoreProvider.overrideWithValue(store),
            biometricStoreProvider.overrideWithValue(
              MemoryBiometricStore(available: false),
            ),
            updatePlatformProvider.overrideWithValue(null),
            historyFilesProvider.overrideWithValue(
              _DocumentsHistoryFiles(root),
            ),
          ],
          child: const WalletApp(),
        ),
      );

      // 1. First run: PIN, then home.
      await _pinSetup(tester);
      await _pumpUntil(tester, find.text('Spendable'));
      debugPrint(
        'WFE_E2E step=home after ${DateTime.now().difference(started)}',
      );

      // 2. The address, as the Receive screen shows it.
      await _tapText(tester, 'Receive');
      final addressText = find.byWidgetPredicate(
        (w) => w is SelectableText && (w.data ?? '').contains('@127.0.0.1'),
      );
      await _pumpUntil(tester, addressText);
      final address = (tester.widget<SelectableText>(addressText.first)).data!;
      expect(address, await _session(tester).epicboxAddress());
      debugPrint('WFE_E2E address=$address');
      await _backHome(tester);

      // 3. The CLI sends 1 EPIC: the notice, then Completed once the host has mined.
      await _pumpUntil(
        tester,
        find.textContaining('on the way'),
        timeout: const Duration(minutes: 3),
      );
      debugPrint(
        'WFE_E2E step=on-the-way after ${DateTime.now().difference(started)}',
      );
      await _pumpUntil(
        tester,
        find.text('Completed'),
        timeout: const Duration(minutes: 6),
        poke: () => _refreshHome(tester),
      );
      await _tapText(tester, 'See all');
      await _pumpUntil(tester, find.text('Completed'));
      await _backHome(tester);
      final received = await _waitFor(
        tester,
        'the receive in the core',
        () async {
          final txs = await _session(tester).transactions(refresh: false);
          return txs
              .where(
                (t) =>
                    t.kind == TxKind.received && t.status == TxStatus.confirmed,
              )
              .firstOrNull;
        },
      );
      expect(received.amountCredited, _epic);
      debugPrint(
        'WFE_E2E step=received after ${DateTime.now().difference(started)}',
      );

      // 4. Send 0.3 EPIC back to the CLI with a note: Review, Send, "Payment started".
      await _tapText(tester, 'Send');
      await _enter(tester, 'To', _cliAddress);
      await _enter(tester, 'Amount (EPIC)', '0.3');
      await _enter(tester, 'Note (optional)', _note);
      await _tapText(tester, 'Review');
      final sendButton = find.textContaining(RegExp(r'^Send 0\.3'));
      await _pumpUntil(tester, sendButton, timeout: const Duration(minutes: 1));
      await _tap(tester, sendButton.first);
      await _pumpUntil(
        tester,
        find.textContaining('Payment started'),
        timeout: const Duration(minutes: 1),
      );
      await _tapText(tester, 'Done');
      final sent = await _waitFor(
        tester,
        'the send answered by the CLI and confirmed',
        () async {
          final txs = await _session(tester).transactions(refresh: true);
          return txs
              .where(
                (t) =>
                    t.kind == TxKind.sent &&
                    t.status == TxStatus.confirmed &&
                    t.note == _note,
              )
              .firstOrNull;
        },
        timeout: const Duration(minutes: 8),
      );
      expect(sent.counterparty, _cliAddress);
      expect(sent.fee, isNotNull);
      await _untilCompleted(tester, 2);
      await _tapText(tester, 'See all');
      await _openPaymentWithNote(tester);
      await _backHome(tester);
      debugPrint(
        'WFE_E2E step=sent after ${DateTime.now().difference(started)}',
      );

      // 5. Back up the history from Settings.
      await _tap(tester, find.byTooltip('Settings'));
      await _tapText(tester, 'Export history backup');
      final backup = File('${root.path}/e2e-backup.wfeh');
      await _waitFor(
        tester,
        'the backup file',
        () async => await backup.exists() ? true : null,
        timeout: const Duration(seconds: 30),
      );
      await tester.pump(const Duration(seconds: 1));
      // Close whatever the export said (a dialog or a snack bar).
      final ok = find.text('OK');
      if (ok.evaluate().isNotEmpty) await _tap(tester, ok.first);

      // The phrase, read through the core for the restore below. Never printed.
      final container = _container(tester);
      final password = await container
          .read(vaultProvider)
          .unlockWithPin(Chain.usernet, _pin);
      final phrase = await _session(tester).mnemonic(password: password);
      expect(phrase.split(' '), hasLength(24));

      // Delete the wallet: confirm, type the word, enter the PIN.
      await _tapText(tester, 'Delete this wallet');
      await _tapText(tester, 'I have written down my recovery phrase');
      await _enter(tester, 'Type "delete" to confirm', 'delete');
      await _tap(tester, find.widgetWithText(FilledButton, 'Delete wallet'));
      await _enter(tester, 'PIN', _pin);
      debugPrint(
        'WFE_E2E step=deleted after ${DateTime.now().difference(started)}',
      );

      // Restore from the phrase, scan, import the backup.
      await _tapText(tester, 'I already have a wallet: restore it');
      await _enter(tester, 'Recovery phrase', phrase);
      await _tapText(tester, 'Continue');
      await _pinSetup(tester);
      await _pumpUntil(
        tester,
        find.text('Import a history backup'),
        timeout: const Duration(minutes: 6),
      );
      debugPrint(
        'WFE_E2E step=restored after ${DateTime.now().difference(started)}',
      );
      await _tapText(tester, 'Import a history backup');
      await _pumpUntil(tester, find.text('History imported'));
      await _tapText(tester, 'OK');
      await _pumpUntil(tester, find.text('Spendable'));

      final back = await _waitFor(
        tester,
        'the send back from the backup',
        () async {
          final txs = await _session(tester).transactions(refresh: false);
          return txs
              .where((t) => t.kind == TxKind.sent && t.note == _note)
              .firstOrNull;
        },
        timeout: const Duration(minutes: 1),
      );
      expect(back.key, sent.key);
      expect(back.fee, sent.fee);
      expect(back.counterparty, _cliAddress);
      expect(
        back.amountDebited - back.amountCredited,
        sent.amountDebited - sent.amountCredited,
      );
      await _tapText(tester, 'See all');
      await _openPaymentWithNote(tester);
      debugPrint(
        'WFE_E2E step=done after ${DateTime.now().difference(started)}',
      );

      container.read(sessionProvider.notifier).lock();
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: _mode != 'usernet' || _cliAddress.isEmpty,
    timeout: const Timeout(Duration(minutes: 40)),
  );
}
