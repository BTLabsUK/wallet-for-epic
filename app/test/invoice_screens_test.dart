// SPDX-License-Identifier: Apache-2.0
// Invoices screen, review and paid-invoice details (I-03), against FakeWalletSession. The
// rule under test throughout: nothing pays an invoice but Approve, and Approve pays only after
// the PIN or biometric gate.

import 'package:epic_wallet/src/amount.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/cancel_dialog.dart' show cancelForSureKey;
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/invoice_review_screen.dart';
import 'package:epic_wallet/src/ui/invoices_screen.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/ui/settings_invoices.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/ui/tx_details_screen.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/experimental.dart';
import 'package:epic_wallet/src/pairing_providers.dart' show invoicesOnProvider, pairingOnProvider;

const String _pin = '123456';

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A fake epicbox address: `es`, 50 copies of [c], then [relay].
String _address(String c, [String relay = 'epicbox.epiccash.com']) =>
    'es${c * 50}@$relay';

/// The service the user trusts as "My Exchange", on a relay whose name says something else.
final String _shop = _address('S', 'binance.example.com');

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  _Config(this.config);

  final WalletConfig config;

  @override
  WalletConfig? build() => config;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _Harness {
  _Harness() {
    store.values['wallet.mainnet.backedUp'] = '1';
    store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    session.clock = () => now;
    // The PIN check goes through the service that opened the session.
    session.owner = service;
  }

  DateTime now = DateTime(2026, 10, 5, 12);
  final session = FakeWalletSession(summary: _summary);
  final store = MemorySecretStore()..values[phoneAdvancedPrefsKey] = phoneExperimentalOn;
  final bio = MemoryBiometricStore();
  late final service = FakeWalletService(session: session);

  WalletConfig get config => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: 'https://node',
  );

  static final WalletSummary _summary = WalletSummary(
    lastConfirmedHeight: BigInt.from(2500000),
    minimumConfirmations: BigInt.from(3),
    total: _epic(100),
    spendable: _epic(100),
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: true,
  );

  /// Pairs the shop as "My Exchange" with Allow invoices on and relays one invoice from it.
  Future<void> invoice({
    String slateId = 'inv-1',
    num amount = 8,
    String? message = 'Order 1042',
    Duration expiresIn = const Duration(hours: 24),
  }) async {
    if (session.pairing.records.isEmpty) {
      session.pairing.seedPaired(name: 'My Exchange', kind: PairingParty.exchange, allowInvoices: true, paymentsAddress: _shop);
    }
    session.relayInvoice(
      from: _shop,
      slateId: slateId,
      amount: _epic(amount),
      message: message,
      expiresIn: expiresIn,
    );
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

  /// [tall] builds every row of a long screen without scrolling.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    bool tall = false,
  }) async {
    tester.view.physicalSize = Size(1080, tall ? 7200 : 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          secretStoreProvider.overrideWithValue(store),
          // On from the first frame, before the stored settings load.
          pairingOnProvider.overrideWithValue(true),
          invoicesOnProvider.overrideWithValue(true),
          biometricStoreProvider.overrideWithValue(bio),
          updatePlatformProvider.overrideWithValue(null),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          clockProvider.overrideWithValue(() => now),
          invoiceClockProvider.overrideWithValue(() => now),
          sessionProvider.overrideWith(() => _OpenSession(session)),
          walletConfigProvider.overrideWith(() => _Config(config)),
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

  /// Pumps the invoice list over an empty screen, then opens the first invoice.
  Future<void> review(WidgetTester tester) async {
    await pump(tester, const InvoicesScreen());
    await tester.tap(find.text('My Exchange'));
    await tester.pumpAndSettle();
    expect(find.text(_l.reqTitle), findsOneWidget);
  }

  /// Taps Approve and answers the PIN dialog with [pin], or cancels it when null.
  Future<void> approve(WidgetTester tester, {String? pin = _pin}) async {
    await tester.tap(find.text(_l.invoiceApprove));
    await tester.pumpAndSettle();
    expect(find.text(_l.invoicePinReason), findsOneWidget);
    if (pin == null) {
      await tester.tap(find.text(_l.commonCancel));
    } else {
      await tester.enterText(find.byType(TextField).last, pin);
    }
    await tester.pumpAndSettle();
  }
}

/// The text of the visible notice.
String? _notice(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first))
        .read(noticeProvider)
        ?.text;

/// Text inside a row's rich line.
Finder _rich(String text) => find.textContaining(text, findRichText: true);

/// The colour of the span that says [text] exactly.
Color? _spanColor(WidgetTester tester, String text) {
  for (final r in tester.widgetList<RichText>(_rich(text))) {
    Color? found;
    r.text.visitChildren((span) {
      if (span is TextSpan && span.text == text) found = span.style?.color;
      return found == null;
    });
    if (found != null) return found;
  }
  return null;
}

Color _warn(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).tokens.warn;

/// Home's Invoices destination tile: the way in now that the app bar has no icon for it.
final Finder _invoicesTile = find.byKey(
  homeDestinationKey(HomeDestination.invoices),
);

void main() {
  group('home entry', () {
    testWidgets('is hidden when the wallet has no invoices', (tester) async {
      final h = _Harness();
      h.session.invoicesSupported = false;
      await h.pump(tester, const HomeScreen());
      expect(find.byKey(invoicesEntryKey), findsNothing);
      expect(_invoicesTile, findsNothing);
    });

    testWidgets('drains at start and badges the pending invoices', (
      tester,
    ) async {
      final h = _Harness();
      await h.invoice(slateId: 'a');
      await h.invoice(slateId: 'b');
      await h.pump(tester, const HomeScreen());
      expect(h.session.pendingInvoicesValue.keys, ['a', 'b']);
      // The app bar has no icon any more; the destination tile on Home carries the badge.
      expect(find.byKey(invoicesEntryKey), findsNothing);
      expect(_invoicesTile, findsOneWidget);
      expect(
        find.descendant(of: _invoicesTile, matching: find.text('2')),
        findsOneWidget,
      );
      // The arrival is announced, with no way to pay from the notice.
      expect(_notice(tester), _l.invoiceNoticeReceived);
      expect(h.session.invoicePayments, 0);
    });

    testWidgets('shows no badge with nothing pending', (tester) async {
      final h = _Harness();
      await h.pump(tester, const HomeScreen());
      expect(_invoicesTile, findsOneWidget);
      expect(
        find.descendant(
          of: _invoicesTile,
          matching: find.text(_l.invoicesTitle),
        ),
        findsOneWidget,
      );
      // No badge: the tile holds its label and nothing else in words.
      expect(
        find.descendant(of: _invoicesTile, matching: find.byType(Text)),
        findsOneWidget,
      );
    });

    testWidgets('drains again when the app comes back to the front', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const HomeScreen());
      await h.invoice(slateId: 'later');
      expect(h.session.pendingInvoicesValue, isEmpty);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(h.session.pendingInvoicesValue.keys, ['later']);
      expect(
        find.descendant(of: _invoicesTile, matching: find.text('1')),
        findsOneWidget,
      );
    });

    testWidgets(
      'hidden, it still drains and raises notices, and draws nothing',
      (tester) async {
        final h = _Harness();
        await h.invoice(slateId: 'a');
        await h.pump(
          tester,
          const Scaffold(body: InvoicesEntry(visible: false)),
        );
        expect(h.session.pendingInvoicesValue.keys, ['a']);
        expect(find.byKey(invoicesEntryKey), findsNothing);
        expect(_notice(tester), _l.invoiceNoticeReceived);
      },
    );

    testWidgets('an invoice arriving while Invoices is open: listed at once, View opens it', (tester) async {
      final h = _Harness();
      // Paired before: only the invoice is new.
      h.session.pairing.seedPaired(name: 'My Exchange', kind: PairingParty.exchange, allowInvoices: true, paymentsAddress: _shop);
      await h.pump(tester, const HomeScreen());
      await tester.tap(_invoicesTile);
      await tester.pumpAndSettle();
      expect(find.text('My Exchange'), findsNothing);
      // It arrives another way than this screen's drain (a contact's mailbox), with its event.
      await h.invoice(slateId: 'late');
      await tester.runAsync(() => h.session.collectInvoices());
      await tester.pumpAndSettle();
      expect(find.text('My Exchange'), findsOneWidget, reason: 'the open list shows it');
      expect(_notice(tester), _l.invoiceNoticeReceived);
      await tester.tap(find.text(_l.homeNoticeView));
      await tester.pumpAndSettle();
      expect(find.text(_l.reqTitle), findsOneWidget, reason: 'View opens that invoice');
    });

    testWidgets('withdrawn while Review is open: Approve off, the notice names the person, the list drops it', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(name: 'Anna', allowInvoices: true, paymentsAddress: _shop);
      await h.invoice(slateId: 'w1');
      await h.pump(tester, const HomeScreen());
      await tester.tap(_invoicesTile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anna'));
      await tester.pumpAndSettle();
      expect(find.text(_l.reqTitle), findsOneWidget);
      // The withdrawal comes by another drain than this screen's, with its event.
      h.session.relayNotice(from: _shop, kind: InvoiceEventKind.withdrawn, slateId: 'w1');
      await tester.runAsync(() => h.session.collectInvoices());
      await tester.pumpAndSettle();
      expect(find.text(_l.invoiceGone), findsOneWidget);
      expect(_notice(tester), _l.deskInvNoticeWithdrawn('Anna'));
      await tester.tap(find.text(_l.invoiceApprove));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicePinReason), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Anna'), findsNothing, reason: 'the open list dropped it');
    });

    testWidgets('opens the list', (tester) async {
      final h = _Harness();
      await h.invoice();
      await h.pump(tester, const HomeScreen());
      await tester.tap(_invoicesTile);
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicesTitle), findsOneWidget);
      expect(find.text('My Exchange'), findsOneWidget);
    });
  });

  group('list', () {
    testWidgets('shows an empty state per segment, each with its next step', (
      tester,
    ) async {
      final h = _Harness();
      await h.pump(tester, const InvoicesScreen());
      expect(find.text(_l.invoicesEmpty), findsOneWidget);
      await tester.tap(find.text(_l.invoicesEmptyAction));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceSettingsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text(_l.invoicesSegmentSent));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicesSentEmpty), findsOneWidget);
      expect(find.text(_l.invoicesSentEmptyCaption), findsOneWidget);
      // The empty state's action and the app bar's both open the form.
      expect(find.text(_l.invoicesNewRequest), findsNWidgets(2));
      await tester.tap(find.byKey(invoicesNewRequestKey));
      await tester.pumpAndSettle();
      expect(find.text(_l.reqNewTitle), findsOneWidget);
    });

    testWidgets('counts each segment', (tester) async {
      final h = _Harness();
      await h.invoice(slateId: 'a');
      await h.invoice(slateId: 'b');
      await h.pump(tester, const InvoicesScreen());
      expect(
        find.bySemanticsLabel(
          _l.invoicesSegmentCount(_l.invoicesToPaySection, 2),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          _l.invoicesSegmentCount(_l.invoicesSegmentSent, 0),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows each invoice by label, amount and time left', (
      tester,
    ) async {
      final h = _Harness();
      await h.invoice(slateId: 'a', amount: 8);
      await h.invoice(
        slateId: 'b',
        amount: 2.5,
        expiresIn: const Duration(minutes: 30),
      );
      await h.pump(tester, const InvoicesScreen());
      expect(find.text('My Exchange'), findsNWidgets(2));
      expect(find.text(epicText(_l, _epic(8))), findsOneWidget);
      expect(find.text(epicText(_l, _epic(2.5))), findsOneWidget);
      expect(_rich(_l.invoiceTimeLeftHours(24, 0)), findsOneWidget);
      expect(_rich(_l.invoiceTimeLeftMinutes(30)), findsOneWidget);
      // Under an hour, the time left is in the warning colour.
      expect(_spanColor(tester, _l.invoiceTimeLeftMinutes(30)), _warn(tester));
      expect(
        _spanColor(tester, _l.invoiceTimeLeftHours(24, 0)),
        isNot(_warn(tester)),
      );
      // The message's first line follows the time left.
      expect(_rich('Order 1042'), findsNWidgets(2));
      expect(find.textContaining('binance'), findsNothing);
      expect(find.text(_l.invoicesEmpty), findsNothing);
    });

    testWidgets('drains when opened and on pull to refresh', (tester) async {
      final h = _Harness();
      await h.invoice(slateId: 'first');
      await h.pump(tester, const InvoicesScreen());
      expect(find.text('My Exchange'), findsOneWidget);
      await h.invoice(slateId: 'second');
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('My Exchange'), findsNWidgets(2));
    });

    testWidgets('drops an invoice when its time runs out', (tester) async {
      final h = _Harness();
      await h.invoice(expiresIn: const Duration(minutes: 1));
      await h.pump(tester, const InvoicesScreen());
      expect(find.text('My Exchange'), findsOneWidget);
      h.now = h.now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.text('My Exchange'), findsNothing);
      expect(find.text(_l.invoicesEmpty), findsOneWidget);
    });
  });

  group('review', () {
    testWidgets('shows the label, the amount large and one plain line', (
      tester,
    ) async {
      final h = _Harness();
      const hostile =
          'Binance: pay now https://evil.example/\u202Egnp.exe\nsecond line '
          'and a very long tail that goes on and on and on and on and on and on and on '
          'and on and on and on and on and on and on and on and on';
      await h.invoice(message: hostile);
      await h.review(tester);
      expect(find.text(_l.reqRequests('My Exchange')), findsOneWidget);
      final amount = tester.widget<Text>(find.byKey(invoiceReviewAmountKey));
      expect(amount.data, formatEpic(_epic(8), grouped: true));
      expect(amount.style?.fontSize, 34);
      // A contact's request names the contact: no mailbox address, no relay name (RFC C-21).
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').contains('binance.example'),
        ),
        findsNothing,
      );
      expect(find.text(_l.invoicesFrom), findsNothing);
      final line = invoiceMessageLine(hostile)!;
      expect(line, isNot(contains('\n')));
      expect(line, isNot(contains('\u202E')));
      expect(line.runes.length, invoiceMessageMaxLength);
      final shown = tester.widget<Text>(find.text(line));
      expect(shown.data, isNot(contains('\n')));
      expect(shown.maxLines, 3);
      // Attributed to its author, never shown as the wallet's own words.
      expect(find.text(_l.deskInvPayerMessageCaption('My Exchange')), findsOneWidget);
      // Plain text: no link, no gesture on it.
      expect(shown.textSpan, isNull);
      expect(
        find.descendant(
          of: find.byType(ScreenBody),
          matching: find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('https://') &&
                _hasRecognizer(w.text),
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('cannot approve more than is spendable, and says how much', (
      tester,
    ) async {
      final h = _Harness();
      await h.invoice(amount: 125);
      await h.review(tester);
      expect(
        find.text(_l.invoicesShort(epicExact(_l, _epic(25)))),
        findsOneWidget,
      );
      expect(
        find.text(_l.invoicesAvailable(epicText(_l, _epic(100)))),
        findsOneWidget,
      );
      final approve = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, _l.invoiceApprove),
      );
      expect(approve.onPressed, isNull);
      // Declining stays open.
      final decline = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, _l.invoiceDecline),
      );
      expect(decline.onPressed, isNotNull);
    });

    testWidgets('an amount within reach shows no short card', (tester) async {
      final h = _Harness();
      await h.invoice(amount: 100);
      await h.review(tester);
      expect(find.textContaining('short'), findsNothing);
      expect(find.text(_l.invoicesCheckNode), findsOneWidget);
      expect(find.text(_l.invoicesCheckEpicbox), findsOneWidget);
    });

    testWidgets('counts the time left down, then expires', (tester) async {
      final h = _Harness();
      await h.invoice(expiresIn: const Duration(minutes: 3));
      await h.review(tester);
      expect(find.text(_l.invoiceTimeLeftMinutes(3)), findsOneWidget);
      h.now = h.now.add(const Duration(minutes: 1, seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(_l.invoiceTimeLeftMinutes(2)), findsOneWidget);
      h.now = h.now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(_l.invoiceTimeLeftUnderMinute), findsOneWidget);
      h.now = h.now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(_l.invoiceExpired), findsOneWidget);
      final approve = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, _l.invoiceApprove),
      );
      expect(approve.onPressed, isNull);
      await tester.tap(find.text(_l.invoiceApprove));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicePinReason), findsNothing);
      expect(h.session.invoicePayments, 0);
    });

    testWidgets(
      'approve asks for the PIN first and pays nothing when cancelled',
      (tester) async {
        final h = _Harness();
        await h.invoice();
        await h.review(tester);
        await h.approve(tester, pin: null);
        expect(h.session.invoicePayments, 0);
        expect(find.text(_l.reqTitle), findsOneWidget);
        await h.approve(tester, pin: '000000');
        expect(
          find.text(_l.invoicePinReason),
          findsOneWidget,
          reason: 'asked again',
        );
        expect(h.session.invoicePayments, 0);
        await tester.tap(find.text(_l.commonCancel));
        await tester.pumpAndSettle();
        expect(h.session.invoicePayments, 0);
      },
    );

    testWidgets(
      'approve with the PIN pays the invoiced amount and sends the reply',
      (tester) async {
        final h = _Harness();
        await h.invoice();
        await h.review(tester);
        await h.approve(tester);
        expect(h.session.invoicePayments, 1);
        expect(h.session.deliveredReplies, ['inv-1']);
        expect(
          h.session.transactionsValue.single.amountDebited,
          _epic(8) + h.session.fee,
        );
        expect(_notice(tester), _l.invoicePaidNotice('My Exchange'));
        expect(find.text(_l.reqTitle), findsNothing);
        expect(find.text(_l.invoicesEmpty), findsOneWidget);
      },
    );

    testWidgets('approve takes the biometric copy of the PIN', (tester) async {
      final h = _Harness();
      h.store.values['wallet.mainnet.pinBiometrics'] = '1';
      h.bio.values['wallet.mainnet.pin'] = _pin;
      await h.invoice();
      await h.review(tester);
      await tester.tap(find.text(_l.invoiceApprove));
      await tester.pumpAndSettle();
      expect(h.bio.prompts, 1);
      expect(h.session.invoicePayments, 1);
    });

    testWidgets('a dismissed biometric prompt pays nothing', (tester) async {
      final h = _Harness();
      h.store.values['wallet.mainnet.pinBiometrics'] = '1';
      h.bio
        ..values['wallet.mainnet.pin'] = _pin
        ..succeed = false;
      await h.invoice();
      await h.review(tester);
      await tester.tap(find.text(_l.invoiceApprove));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicePinReason), findsOneWidget);
      expect(h.session.invoicePayments, 0);
    });

    testWidgets('a failed reply offers Retry, which resends without the PIN', (
      tester,
    ) async {
      final h = _Harness();
      h.session.replyError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay closed the socket',
      );
      await h.invoice();
      await h.review(tester);
      await h.approve(tester);
      expect(h.session.invoicePayments, 1);
      expect(h.session.deliveredReplies, isEmpty);
      expect(_notice(tester), _l.invoiceReplyFailedNotice);
      expect(
        find.text(_l.invoiceReplyFailedTitle('My Exchange')),
        findsOneWidget,
      );
      expect(find.text(_l.invoiceApprove), findsNothing);
      // Still failing: the error says so and the Retry stays.
      await tester.tap(find.text(_l.invoiceRetry));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicePinReason), findsNothing);
      expect(find.text(_l.invoiceRetry), findsOneWidget);
      h.session.replyError = null;
      await tester.tap(find.text(_l.invoiceRetry));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicePinReason), findsNothing);
      expect(h.session.deliveredReplies, ['inv-1']);
      expect(h.session.invoicePayments, 1, reason: 'approved once');
      expect(_notice(tester), _l.invoicePaidNotice('My Exchange'));
      expect(find.text(_l.reqTitle), findsNothing);
    });

    testWidgets('decline confirms, tells the service and pays nothing', (
      tester,
    ) async {
      final h = _Harness();
      await h.invoice();
      await h.review(tester);
      await tester.tap(find.text(_l.invoiceDecline));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoiceDeclineBody('My Exchange')), findsOneWidget);
      await tester.tap(find.text(_l.invoiceDeclineKeep));
      await tester.pumpAndSettle();
      expect(h.session.declinedInvoices, isEmpty);
      await tester.tap(find.text(_l.invoiceDecline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, _l.invoiceDecline));
      await tester.pumpAndSettle();
      expect(h.session.declinedInvoices, ['inv-1']);
      expect(h.session.invoicePayments, 0);
      expect(_notice(tester), _l.invoiceDeclinedNotice);
      expect(find.text(_l.invoicesEmpty), findsOneWidget);
    });

    testWidgets('an invoice withdrawn while open can no longer be answered', (
      tester,
    ) async {
      final h = _Harness();
      await h.invoice();
      await h.review(tester);
      h.session.relayNotice(
        from: _shop,
        kind: InvoiceEventKind.withdrawn,
        slateId: 'inv-1',
      );
      await h
          .container(tester)
          .read(pendingInvoicesProvider.notifier)
          .refresh();
      await tester.pumpAndSettle();
      expect(find.text(_l.invoiceGone), findsOneWidget);
      await tester.tap(find.text(_l.invoiceApprove));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicePinReason), findsNothing);
      expect(h.session.invoicePayments, 0);
    });
  });

  testWidgets('an invoice withdrawn while the PIN is asked is not paid', (
    tester,
  ) async {
    final h = _Harness();
    await h.invoice();
    await h.review(tester);
    await tester.tap(find.text(_l.invoiceApprove));
    await tester.pumpAndSettle();
    h.session.relayNotice(
      from: _shop,
      kind: InvoiceEventKind.withdrawn,
      slateId: 'inv-1',
    );
    await h.container(tester).read(pendingInvoicesProvider.notifier).refresh();
    await tester.enterText(find.byType(TextField).last, _pin);
    await tester.pumpAndSettle();
    expect(find.text(_l.invoicePinReason), findsNothing);
    expect(h.session.invoicePayments, 0);
    expect(find.text(_l.invoiceGone), findsOneWidget);
    // Stopped before payInvoice, so no error from the wallet either.
    expect(_notice(tester), isNull);
  });

  group('paid details', () {
    /// Pays the shop's invoice the way Approve does, then shows the payment's details.
    Future<_Harness> paid(
      WidgetTester tester, {
      WalletError? replyError,
    }) async {
      final h = _Harness();
      await h.invoice();
      await h.session.collectInvoices();
      h.session.replyError = replyError;
      await h.session.payInvoice(slateId: 'inv-1', amount: _epic(8));
      return h;
    }

    Future<void> details(WidgetTester tester, _Harness h) => h.pump(
      tester,
      TxDetailsScreen(txKey: h.session.transactionsValue.single.key),
      tall: true,
    );

    testWidgets('a paired person\'s request just paid: its own card and steps, no generic Waiting card, no Cancel yet', (tester) async {
      final h = _Harness();
      h.session.pairing.seedPaired(name: 'Floo C', kind: PairingParty.person, allowInvoices: true, paymentsAddress: _shop);
      await h.invoice();
      await h.session.collectInvoices();
      await h.session.payInvoice(slateId: 'inv-1', amount: _epic(8));
      await details(tester, h);
      expect(find.text(_l.reqPaidWaiting('Floo C')), findsOneWidget);
      expect(find.text(_l.reqPaidWaitingBodyPerson), findsOneWidget, reason: 'a person, not "the exchange"');
      expect(find.text(_l.reqTlPaid), findsOneWidget);
      expect(find.byType(TxStatusChip), findsNothing, reason: 'the request block says where it stands');
      expect(find.text(_l.txDetailsWaitingEpicbox), findsNothing);
      expect(find.text(_l.txDetailsCancelPayment), findsNothing, reason: 'Cancel comes once its time runs out');
      // Named by its pairing, never by the mailbox it was paid to.
      expect(find.descendant(of: find.byType(AppBar), matching: find.textContaining('Floo C')), findsOneWidget);
    });

    testWidgets('show the service and message, waiting for the receipt', (
      tester,
    ) async {
      final h = await paid(tester);
      await details(tester, h);
      expect(find.text(_l.invoiceDetailsSection), findsOneWidget);
      expect(find.text('My Exchange'), findsWidgets, reason: 'the block, and the title names it');
      expect(find.text('Order 1042'), findsOneWidget);
      expect(
        find.text(_l.invoiceDetailsReplied('My Exchange')),
        findsOneWidget,
      );
      expect(find.text(_l.invoiceDetailsPosted('My Exchange')), findsNothing);
    });

    testWidgets('say the service reports it posted once the receipt is in', (
      tester,
    ) async {
      final h = await paid(tester);
      h.session.relayNotice(
        from: _shop,
        kind: InvoiceEventKind.posted,
        slateId: 'inv-1',
        kernelExcess: '09abc',
      );
      await h.session.collectInvoices();
      await details(tester, h);
      expect(find.text(_l.invoiceDetailsPosted('My Exchange')), findsOneWidget);
      expect(find.text(_l.invoiceDetailsReplied('My Exchange')), findsNothing);
    });

    testWidgets('offer Retry for a reply that did not get through', (
      tester,
    ) async {
      final h = await paid(
        tester,
        replyError: const WalletError(
          kind: WalletErrorKind.transportFailed,
          message: 'offline',
        ),
      );
      await details(tester, h);
      expect(
        find.text(_l.invoiceDetailsReplyFailed('My Exchange')),
        findsOneWidget,
      );
      h.session.replyError = null;
      await tester.tap(find.text(_l.invoiceRetry));
      await tester.pumpAndSettle();
      expect(find.text(_l.invoicePinReason), findsNothing);
      expect(h.session.deliveredReplies, ['inv-1']);
      expect(h.session.invoicePayments, 1);
      expect(
        find.text(_l.invoiceDetailsReplied('My Exchange')),
        findsOneWidget,
      );
    });

    // linux-12: the reply reached a relay the service never reads, so it is never posted and
    // the coins stay locked with no way on.
    testWidgets(
      'offer Send again for a reply never posted, and say when Cancel comes',
      (tester) async {
        final h = await paid(tester);
        expect(h.session.deliveredReplies, ['inv-1']);
        await details(tester, h);
        expect(
          find.text(_l.invoiceDetailsRepliedHelp('My Exchange')),
          findsOneWidget,
        );
        await tester.tap(find.text(_l.txDetailsSendAgain));
        await tester.pumpAndSettle();
        expect(find.text(_l.invoicePinReason), findsNothing);
        expect(h.session.deliveredReplies, ['inv-1', 'inv-1']);
        expect(h.session.invoicePayments, 1);
      },
    );

    testWidgets('warn of a withdrawal after payment, with a confirmed Cancel', (
      tester,
    ) async {
      final h = await paid(tester);
      h.session.relayNotice(
        from: _shop,
        kind: InvoiceEventKind.withdrawn,
        slateId: 'inv-1',
      );
      await h.session.collectInvoices();
      await details(tester, h);
      expect(
        find.text(_l.invoiceDetailsWithdrawn('My Exchange')),
        findsOneWidget,
      );
      expect(h.session.cancelledTxIds, isEmpty, reason: 'never on its own');
      final cancel = find.descendant(
        of: find.byType(PaidInvoiceBlock),
        matching: find.text(_l.txDetailsCancelPayment),
      );
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(find.text(_l.txDetailsCancelTitle), findsOneWidget);
      await tester.tap(find.text(_l.txDetailsCancelKeep));
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, isEmpty);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      // The dialog's cancelling choice is the red one.
      await tester.tap(
        find.byKey(cancelForSureKey),
      );
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [h.session.transactionsValue.single.id]);
    });

    /// Home open, then the shop's `withdrawn` notice for the paid invoice arrives.
    Future<Notice> withdrawnOnHome(WidgetTester tester, _Harness h) async {
      await h.pump(tester, const HomeScreen());
      h.session.relayNotice(
        from: _shop,
        kind: InvoiceEventKind.withdrawn,
        slateId: 'inv-1',
      );
      await h
          .container(tester)
          .read(pendingInvoicesProvider.notifier)
          .refresh();
      await tester.pumpAndSettle();
      final notice = h.container(tester).read(noticeProvider)!;
      expect(notice.text, _l.invoiceNoticeWithdrawnPaid);
      expect(notice.level, NoticeLevel.warning);
      expect(h.session.cancelledTxIds, isEmpty, reason: 'never on its own');
      return notice;
    }

    Finder noticeButton(String label) =>
        find.descendant(of: find.byKey(noticeKey), matching: find.text(label));

    testWidgets(
      'a withdrawal after payment comes as a warning notice with Cancel',
      (tester) async {
        final h = await paid(tester);
        final notice = await withdrawnOnHome(tester, h);
        expect(notice.action?.label, _l.txDetailsCancelPayment);
        await tester.tap(noticeButton(_l.txDetailsCancelPayment));
        await tester.pumpAndSettle();
        expect(find.text(_l.txDetailsCancelTitle), findsOneWidget);
        await tester.tap(find.text(_l.txDetailsCancelKeep));
        await tester.pumpAndSettle();
        expect(h.session.cancelledTxIds, isEmpty);
      },
    );

    testWidgets("the notice's Cancel cancels once the user confirms", (
      tester,
    ) async {
      final h = await paid(tester);
      await withdrawnOnHome(tester, h);
      await tester.tap(noticeButton(_l.txDetailsCancelPayment));
      await tester.pumpAndSettle();
      // The dialog's cancelling choice is the red one.
      await tester.tap(
        find.byKey(cancelForSureKey),
      );
      await tester.pumpAndSettle();
      expect(h.session.cancelledTxIds, [h.session.transactionsValue.single.id]);
      expect(_notice(tester), _l.txDetailsPaymentCancelled);
    });

    testWidgets('the notice offers View when the payment cannot be cancelled', (
      tester,
    ) async {
      final h = await paid(tester);
      final tx = h.session.transactionsValue.single;
      h.session.transactionsValue = [
        fakeTx(
          id: tx.id,
          slateId: tx.slateId,
          kind: TxKind.sent,
          status: TxStatus.awaitingConfirmation,
          createdAtUnix: tx.createdAtUnix,
          amountDebited: tx.amountDebited,
          fee: tx.fee,
          counterparty: tx.counterparty,
        ),
      ];
      final notice = await withdrawnOnHome(tester, h);
      expect(notice.action?.label, _l.homeNoticeView);
      await tester.tap(noticeButton(_l.homeNoticeView));
      await tester.pumpAndSettle();
      expect(
        find.text(_l.invoiceDetailsWithdrawn('My Exchange')),
        findsOneWidget,
      );
      expect(h.session.cancelledTxIds, isEmpty);
    });

    testWidgets('a payment that paid no invoice has no invoice block', (
      tester,
    ) async {
      final h = _Harness();
      h.session.transactionsValue = [
        fakeTx(
          id: 1,
          slateId: 'plain',
          kind: TxKind.sent,
          status: TxStatus.awaitingRecipient,
          createdAtUnix: 1790000000,
          amountDebited: _epic(1),
        ),
      ];
      await details(tester, h);
      expect(find.text(_l.invoiceDetailsSection), findsNothing);
    });
  });

  test('time left reads in hours and minutes, rounded up', () {
    expect(
      invoiceTimeLeft(_l, const Duration(hours: 23, minutes: 59, seconds: 1)),
      _l.invoiceTimeLeftHours(24, 0),
    );
    expect(
      invoiceTimeLeft(_l, const Duration(hours: 1, minutes: 5)),
      _l.invoiceTimeLeftHours(1, 5),
    );
    expect(
      invoiceTimeLeft(_l, const Duration(minutes: 59, seconds: 30)),
      _l.invoiceTimeLeftHours(1, 0),
    );
    expect(
      invoiceTimeLeft(_l, const Duration(minutes: 1)),
      _l.invoiceTimeLeftMinutes(1),
    );
    expect(
      invoiceTimeLeft(_l, const Duration(seconds: 59)),
      _l.invoiceTimeLeftUnderMinute,
    );
  });

  test('a message keeps nothing that hides or reorders text', () {
    expect(invoiceMessageLine(null), isNull);
    expect(invoiceMessageLine(' \n\t\u200B '), isNull);
    expect(invoiceMessageLine('a\u202Eb\u2066c\u0007d\r\ne'), 'a b c d e');
    expect(invoiceMessageLine('Order  1042'), 'Order 1042');
  });
}

bool _hasRecognizer(InlineSpan span) {
  var found = false;
  span.visitChildren((s) {
    if (s is TextSpan && s.recognizer is GestureRecognizer) found = true;
    return !found;
  });
  return found;
}
