// Invoices end to end on a device, on floonet: the real UI and LEPIC against a LEPIC CLI wallet
// acting as the service. Run it with `integration_test/invoice_e2e.sh`, which makes the
// service, passes `--dart-define=WFE_E2E=floonet-invoices` and answers the `WFE_E2E` lines
// below; without that define the test is skipped.
//
// The app approves one invoice and declines another through the review screen, the service
// finalizes and posts the approved one, and the payment's details show the service's receipt.
import 'dart:io';

import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/ui/invoices_screen.dart' show invoicesEntryKey;
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/shell_header.dart' show balanceFigureKey;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _mode = String.fromEnvironment('WFE_E2E');
const _service = String.fromEnvironment('WFE_SERVICE_ADDRESS');
const _pin = '271828';
const _label = 'Floo shop';

final BigInt _epic = BigInt.from(100000000);

/// Pumps frames until [finder] matches, poking now and then, since the chain runs in real time.
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(minutes: 2),
  Future<void> Function()? poke,
  Duration pokeEvery = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  var nextPoke = DateTime.now().add(pokeEvery);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
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
  Duration every = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (true) {
    final value = await check();
    if (value != null) return value;
    if (DateTime.now().isAfter(end)) fail('Timed out after $timeout: $what');
    for (var i = 0; i < every.inMilliseconds ~/ 200; i++) {
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

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await _pumpUntil(tester, field);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 300));
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

WalletSession _session(WidgetTester tester) =>
    _container(tester).read(sessionProvider)!;

void _clearNotices(WidgetTester tester) =>
    _container(tester).read(noticeProvider.notifier).clear();

Future<void> _backHome(WidgetTester tester) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .popUntil((route) => route.isFirst);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Drains the invoice address as pull to refresh does.
Future<void> _drain(WidgetTester tester) async {
  try {
    await _container(tester).read(pendingInvoicesProvider.notifier).refresh();
  } catch (_) {
    // A relay hiccup; the next poke tries again.
  }
}

/// On the Invoices screen, opens the invoice for [amount] EPIC.
Future<PendingInvoice> _openInvoice(WidgetTester tester, BigInt amount) async {
  final invoice = await _waitFor(tester, 'the invoice for $amount', () async {
    final pending =
        _container(tester).read(pendingInvoicesProvider).value ?? const [];
    return pending.where((i) => i.amount == amount).firstOrNull;
  });
  final text = '${formatEpic(amount)} EPIC';
  final tile = find.ancestor(
    of: find.text(text),
    matching: find.byType(ListTile),
  );
  await _pumpUntil(tester, tile);
  _clearNotices(tester);
  await _tap(tester, tile.first);
  await _pumpUntil(tester, find.text('$_label asks you to pay'));
  return invoice;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'floonet invoices: approve one, decline one, the service posts and reports it',
    (tester) async {
      await initLepic();
      final started = DateTime.now();
      void step(String name) => debugPrint(
        'WFE_E2E step=$name after ${DateTime.now().difference(started)}',
      );
      final base = await getApplicationDocumentsDirectory();
      final root = await Directory(
        '${base.path}/wfe-invoice-e2e-${started.millisecondsSinceEpoch}',
      ).create(recursive: true);
      addTearDown(() => root.delete(recursive: true));
      final store = MemorySecretStore();
      await store.write('app.network', 'floonet');

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
          ],
          child: const WalletApp(),
        ),
      );

      // 1. First run, then the payments address for the faucet.
      await _enter(tester, 'PIN', _pin);
      await _enter(tester, 'Repeat PIN', _pin);
      await _pumpUntil(
        tester,
        find.byKey(balanceFigureKey),
        timeout: const Duration(minutes: 3),
      );
      step('home');
      expect(_session(tester).supportsInvoices, isTrue);
      debugPrint('WFE_E2E payments=${await _session(tester).epicboxAddress()}');

      // 2. Settings > Invoices: the invoice address, and the service as trusted.
      await _tap(tester, find.byTooltip('Settings'));
      await _tapText(tester, 'Invoice address and trusted services');
      final invoiceAddress = await _session(tester).invoiceAddress();
      expect(invoiceAddress, isNot(await _session(tester).epicboxAddress()));
      // Shown short unless Advanced options is on, as on Receive.
      await _pumpUntil(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              (w.data ?? '').startsWith(invoiceAddress.substring(0, 6)),
        ),
      );
      await _tapText(tester, 'Add a service');
      await _enter(tester, 'Name', _label);
      await _enter(tester, "The service's epicbox address", _service);
      await _tapText(tester, 'Add service');
      await _pumpUntil(tester, find.text('$_label can now send you invoices.'));
      expect(
        (await _session(tester).trustedServices()).single,
        const TrustedService(address: _service, label: _label),
      );
      debugPrint('WFE_E2E invoice-address=$invoiceAddress');
      step('trusted');
      await _backHome(tester);

      // 3. The faucet's 10 EPIC, spendable after 10 blocks.
      await _waitFor(
        tester,
        'spendable funds from the faucet',
        () async {
          final s = await _session(
            tester,
          ).summary(refresh: true, minimumConfirmations: minimumConfirmations);
          return s.spendable >= BigInt.from(3) * _epic ? s : null;
        },
        timeout: const Duration(minutes: 40),
        every: const Duration(seconds: 20),
      );
      step('funded');

      // 4. Both invoices on the Invoices screen, from the service by its label.
      _clearNotices(tester);
      await _tap(tester, find.byKey(invoicesEntryKey));
      await _waitFor(
        tester,
        'both invoices',
        () async {
          await _drain(tester);
          final pending =
              _container(tester).read(pendingInvoicesProvider).value ??
              const [];
          return pending.length >= 2 ? pending : null;
        },
        timeout: const Duration(minutes: 5),
        every: const Duration(seconds: 10),
      );
      step('invoices');

      // 5. Approve 1.5 EPIC behind the PIN.
      final approved = await _openInvoice(
        tester,
        BigInt.from(15) * _epic ~/ BigInt.from(10),
      );
      expect(approved.senderAddress, _service);
      expect(find.textContaining('order 1'), findsOneWidget);
      await _tapText(tester, 'Approve and pay');
      await _enter(tester, 'PIN', _pin);
      await _pumpUntil(
        tester,
        find.text('Paid. $_label now finishes the payment.'),
        timeout: const Duration(minutes: 2),
      );
      final paid = await _session(tester)
          .paidInvoice(slateId: approved.slateId);
      expect(paid?.status, InvoiceStatus.replied);
      step('approved');

      // 6. Decline 0.7 EPIC.
      await _pumpUntil(tester, find.text('Invoices'));
      final declined = await _openInvoice(
        tester,
        BigInt.from(7) * _epic ~/ BigInt.from(10),
      );
      await _tapText(tester, 'Decline');
      await _tap(tester, find.widgetWithText(FilledButton, 'Decline'));
      await _pumpUntil(tester, find.text('Invoice declined.'));
      expect(
        (await _session(tester).pendingInvoices()).map((i) => i.slateId),
        isNot(contains(declined.slateId)),
      );
      step('declined');

      // 7. The service finalizes and posts; its receipt comes with a drain.
      final posted = await _waitFor(
        tester,
        'the posted receipt',
        () async {
          await _drain(tester);
          final p = await _session(tester)
              .paidInvoice(slateId: approved.slateId);
          return p?.status == InvoiceStatus.posted ? p : null;
        },
        timeout: const Duration(minutes: 10),
        every: const Duration(seconds: 15),
      );
      expect(posted.kernelExcess, isNotEmpty);
      step('posted');

      // 8. The payment's details show the service and its receipt.
      await _backHome(tester);
      _clearNotices(tester);
      await _tapText(tester, 'See all');
      final row = find.textContaining('-1.5 EPIC');
      await _pumpUntil(
        tester,
        row,
        timeout: const Duration(minutes: 1),
        poke: () async => _container(tester).invalidate(homeProvider),
      );
      // The receipt's notice floats over the top rows.
      _clearNotices(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await _tap(tester, row.first);
      await _pumpUntil(
        tester,
        find.text(
          '$_label reports it posted the payment. It completes once the network '
          'confirms it.',
        ),
        timeout: const Duration(seconds: 30),
      );
      step('done');

      _container(tester).read(sessionProvider.notifier).lock();
      await tester.pumpWidget(const SizedBox.shrink());
    },
    skip: _mode != 'floonet-invoices' || _service.isEmpty,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}
