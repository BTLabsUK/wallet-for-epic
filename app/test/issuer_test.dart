// Issuing invoices (I-05) against the fake: issue, withdraw, each payer answer to its state,
// the bounced signal, records in wfe_meta.json across a reopen, the payments drain on open and
// on resume, and that no issuer path spends.
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/history/wallet_history.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/settings_history.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A valid fake epicbox address with a key made of [c].
String addr(String c, {String relay = 'epicbox.epiccash.com'}) =>
    '${'es$c'.padRight(52, c)}@$relay';

final payer = addr('P');
final five = BigInt.from(500000000);

Matcher invalidArgument(String text) => throwsA(
  isA<WalletError>()
      .having((e) => e.kind, 'kind', WalletErrorKind.invalidArgument)
      .having((e) => e.message, 'message', contains(text)),
);

/// Lets broadcast events and archive writes finish.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

/// Nothing an issuer does may spend: no send, no slate, no invoice payment.
void expectNothingSpent(FakeWalletSession s) {
  expect(s.sentAmounts, isEmpty);
  expect(s.epicboxSends, isEmpty);
  expect(s.invoicePayments, 0);
}

void main() {
  group('cutMessage', () {
    test('trims, drops a blank message and keeps a short one', () {
      expect(cutMessage(null), isNull);
      expect(cutMessage('   '), isNull);
      expect(cutMessage('  Order 7 '), 'Order 7');
    });

    test('cuts at 256 bytes on a character boundary', () {
      // 2 bytes each: 128 fit.
      expect(cutMessage('é' * 300), 'é' * 128);
      // A family emoji is one character of 25 bytes; it is kept whole or not at all.
      const family = '👨‍👩‍👧‍👦';
      final cut = cutMessage('${'a' * 250}$family')!;
      expect(cut, 'a' * 250);
      expect(utf8.encode(cutMessage('a' * 400)!).length, 256);
    });
  });

  group('fake session', () {
    late FakeWalletSession s;
    late List<IssuerEvent> events;
    late DateTime now;

    setUp(() {
      s = FakeWalletSession();
      now = DateTime(2026, 10, 5, 12);
      s.clock = () => now;
      events = [];
      s.issuerEvents().listen(events.add);
    });

    test('issues a request that waits, with a day to run', () async {
      final issued = await s.issueInvoice(
        amount: five,
        address: ' $payer ',
        message: '  Dinner  ',
      );
      expect(issued.payerAddress, payer);
      expect(issued.amount, five);
      expect(issued.message, 'Dinner');
      expect(issued.state, IssuedInvoiceState.waiting);
      expect(issued.withdrawable, isTrue);
      expect(issued.issuedAt, now);
      expect(issued.expiresAt, now.add(const Duration(hours: 24)));
      expect(
        issued.timeLeftAt(now.add(const Duration(hours: 25))),
        Duration.zero,
      );
      expect(await s.issuedInvoices(), [issued]);
      expect(await s.issuedInvoice(slateId: issued.slateId), issued);
      expect(s.issuedRequests.single.to, payer);
      expectNothingSpent(s);
    });

    test('cuts the message as Send does', () async {
      await s.issueInvoice(amount: five, address: payer, message: 'é' * 300);
      expect(s.issuedRequests.single.message, 'é' * 128);
    });

    test(
      'refuses an invalid address, its own addresses and no amount',
      () async {
        await expectLater(
          s.issueInvoice(amount: five, address: 'not-an-address'),
          invalidArgument('not an epicbox address'),
        );
        await expectLater(
          s.issueInvoice(amount: five, address: s.address),
          invalidArgument('own addresses'),
        );
        await expectLater(
          s.issueInvoice(amount: BigInt.zero, address: payer),
          invalidArgument('above zero'),
        );
        expect(await s.issuedInvoices(), isEmpty);
      },
    );

    test('a request the relay did not take leaves nothing', () async {
      s.issueError = const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'relay',
      );
      await expectLater(
        s.issueInvoice(amount: five, address: payer),
        throwsA(isA<WalletError>()),
      );
      expect(await s.issuedInvoices(), isEmpty);
    });

    test('each payer answer moves the request once, with its event', () async {
      final a = await s.issueInvoice(amount: five, address: payer);
      final b = await s.issueInvoice(amount: five, address: payer);
      final c = await s.issueInvoice(amount: five, address: payer);
      await s.payIssued(a.slateId);
      await s.declineIssued(b.slateId);
      await s.expireIssued(c.slateId);
      // Final states do not move again.
      await s.expireIssued(a.slateId);
      await s.payIssued(b.slateId);
      await settle();
      final states = {
        for (final i in await s.issuedInvoices()) i.slateId: i.state,
      };
      expect(states, {
        a.slateId: IssuedInvoiceState.paid,
        b.slateId: IssuedInvoiceState.declined,
        c.slateId: IssuedInvoiceState.expired,
      });
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.paid,
          slateId: a.slateId,
          payerAddress: payer,
        ),
        IssuerEvent(
          kind: IssuerEventKind.declined,
          slateId: b.slateId,
          payerAddress: payer,
        ),
        IssuerEvent(
          kind: IssuerEventKind.expired,
          slateId: c.slateId,
          payerAddress: payer,
        ),
      ]);
      // A decline is final, so the wallet withdrew the request itself.
      expect(s.cancelledTxIds, [b.txId]);
      expectNothingSpent(s);
    });

    test('withdraw cancels a waiting request only', () async {
      final a = await s.issueInvoice(amount: five, address: payer);
      final withdrawn = await s.withdrawInvoice(slateId: a.slateId);
      expect(withdrawn.state, IssuedInvoiceState.withdrawn);
      expect(s.cancelledTxIds, [a.txId]);
      await settle();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.withdrawn,
          slateId: a.slateId,
          payerAddress: payer,
        ),
      ]);
      await expectLater(
        s.withdrawInvoice(slateId: a.slateId),
        invalidArgument('only a waiting invoice'),
      );
      final b = await s.issueInvoice(amount: five, address: payer);
      await s.payIssued(b.slateId);
      await expectLater(
        s.withdrawInvoice(slateId: b.slateId),
        invalidArgument('only a waiting invoice'),
      );
      await expectLater(
        s.withdrawInvoice(slateId: 'nope'),
        invalidArgument('no issued invoice'),
      );
      expect(s.cancelledTxIds, [a.txId]);
    });

    test('a bounce withdraws that request once and names its payer', () async {
      final a = await s.issueInvoice(amount: five, address: payer);
      final b = await s.issueInvoice(amount: five, address: addr('Q'));
      expect(await s.peerCapability(address: payer), PeerCapability.unknown);
      await s.bounceIssued(a.slateId);
      await s.bounceIssued(a.slateId);
      await settle();
      expect(events, [
        IssuerEvent(
          kind: IssuerEventKind.bounced,
          slateId: a.slateId,
          payerAddress: payer,
        ),
      ]);
      expect(s.cancelledTxIds, [a.txId]);
      expect(
        (await s.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.bounced,
      );
      expect(
        (await s.issuedInvoice(slateId: b.slateId))!.state,
        IssuedInvoiceState.waiting,
      );
      expect(await s.peerCapability(address: payer), PeerCapability.noInvoices);
      expectNothingSpent(s);
    });

    test('a drain sweeps requests whose day ran out', () async {
      final a = await s.issueInvoice(amount: five, address: payer);
      await s.drainPayments();
      expect(
        (await s.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.waiting,
      );
      now = now.add(const Duration(hours: 24));
      await s.drainPayments();
      expect(
        (await s.issuedInvoice(slateId: a.slateId))!.state,
        IssuedInvoiceState.expired,
      );
    });

    test('every issuer call is refused without invoices', () async {
      s.invoicesSupported = false;
      for (final call in <Future<Object?> Function()>[
        () => s.issueInvoice(amount: five, address: payer),
        s.issuedInvoices,
        () => s.issuedInvoice(slateId: 'x'),
        () => s.withdrawInvoice(slateId: 'x'),
        s.drainPayments,
      ]) {
        await expectLater(call(), throwsA(isA<WalletError>()));
      }
      expect(s.issuerEvents, throwsA(isA<WalletError>()));
    });
  });

  group('records in wfe_meta.json', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('wfe-issuer-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('survive a reopen with their state', () async {
      final first = FakeWalletSession(
        invoiceHistory: await WalletHistory.open(dir.path, Chain.floonet),
      )..clock = () => DateTime.utc(2026, 10, 5, 12, 0, 0, 750);
      final a = await first.issueInvoice(
        amount: five,
        address: payer,
        message: 'Dinner',
      );
      final b = await first.issueInvoice(amount: BigInt.one, address: payer);
      await first.payIssued(b.slateId);
      first.invoiceHistory.close();

      final raw = jsonDecode(
        File('${dir.path}/wfe_meta.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final kept = raw['issued_invoices'] as Map<String, dynamic>;
      expect(kept.keys, unorderedEquals([a.slateId, b.slateId]));
      expect((kept[b.slateId] as Map)['state'], 'paid');

      // LEPIC's store outlives the app; the archive adds the states.
      final reopened = FakeWalletSession(
        invoiceHistory: await WalletHistory.open(dir.path, Chain.floonet),
        transactions: first.transactionsValue,
      );
      expect(await reopened.issuedInvoice(slateId: a.slateId), a);
      expect(
        (await reopened.issuedInvoice(slateId: b.slateId))!.state,
        IssuedInvoiceState.paid,
      );
      // Newest first.
      expect(
        [for (final i in await reopened.issuedInvoices()) i.slateId],
        [b.slateId, a.slateId],
      );
      reopened.invoiceHistory.close();
    });

    test('are not part of a history file', () async {
      final history = await WalletHistory.open(dir.path, Chain.floonet);
      final s = FakeWalletSession(invoiceHistory: history);
      await s.issueInvoice(amount: five, address: payer);
      final payload = history.exportPayload(
        const [],
        walletFp: 'fp',
        appVersion: 'test',
      );
      expect(utf8.decode(payload.encode()), isNot(contains('issued')));
      history.close();
    });
  });

  group('providers', () {
    late FakeWalletSession s;
    late ProviderContainer c;

    setUp(() {
      s = FakeWalletSession();
      c = ProviderContainer(retry: (_, _) => null);
      addTearDown(c.dispose);
    });

    test('the payments drain runs once a wallet opens', () async {
      c.listen(paymentsDrainProvider, (_, _) {});
      await settle();
      expect(s.drainPaymentCalls, 0, reason: 'nothing while locked');
      c.read(sessionProvider.notifier).unlocked(s);
      await settle();
      expect(s.drainPaymentCalls, 1);
      expect(c.read(paymentsDrainProvider), const PaymentsDrainReport());
      await c.read(paymentsDrainProvider.notifier).drain();
      expect(s.drainPaymentCalls, 2);
    });

    test('no drain without invoices', () async {
      s.invoicesSupported = false;
      c.listen(paymentsDrainProvider, (_, _) {});
      c.read(sessionProvider.notifier).unlocked(s);
      await settle();
      await c.read(paymentsDrainProvider.notifier).drain();
      expect(s.drainPaymentCalls, 0);
    });

    test('a bounce reaches the notice once', () async {
      c.listen(paymentsDrainProvider, (_, _) {});
      c.read(sessionProvider.notifier).unlocked(s);
      await settle();
      final issued = await s.issueInvoice(amount: five, address: payer);
      await s.bounceIssued(issued.slateId);
      await settle();
      final first = c.read(issuerNoticeProvider)!;
      expect(
        first.event,
        IssuerEvent(
          kind: IssuerEventKind.bounced,
          slateId: issued.slateId,
          payerAddress: payer,
        ),
      );
      await s.bounceIssued(issued.slateId);
      await settle();
      expect(c.read(issuerNoticeProvider)!.id, first.id, reason: 'no second');
    });

    test('the list issues, withdraws and follows the payer', () async {
      c.read(sessionProvider.notifier).unlocked(s);
      final sub = c.listen(issuedInvoicesProvider, (_, _) {});
      expect(await c.read(issuedInvoicesProvider.future), isEmpty);
      final a = await c
          .read(issuedInvoicesProvider.notifier)
          .issue(amount: five, address: payer, message: 'Dinner');
      expect(await c.read(issuedInvoicesProvider.future), [a]);

      final details = c.listen(issuedInvoiceProvider(a.slateId), (_, _) {});
      expect(await c.read(issuedInvoiceProvider(a.slateId).future), a);
      await s.payIssued(a.slateId);
      await settle();
      expect(
        (await c.read(issuedInvoicesProvider.future)).single.state,
        IssuedInvoiceState.paid,
      );
      expect(
        (await c.read(issuedInvoiceProvider(a.slateId).future))!.state,
        IssuedInvoiceState.paid,
      );

      final b = await c
          .read(issuedInvoicesProvider.notifier)
          .issue(amount: five, address: payer);
      await c.read(issuedInvoicesProvider.notifier).withdraw(b.slateId);
      expect(
        (await c.read(issuedInvoicesProvider.future)).first.state,
        IssuedInvoiceState.withdrawn,
      );
      details.close();
      sub.close();
      expectNothingSpent(s);
    });

    test('empty while locked', () async {
      expect(await c.read(issuedInvoicesProvider.future), isEmpty);
      expect(await c.read(issuedInvoiceProvider('x').future), isNull);
      expect(c.read(issuerNoticeProvider), isNull);
    });
  });

  group('the app', () {
    testWidgets('drains the payments address on open and on every resume', (
      tester,
    ) async {
      final h = _AppHarness();
      await h.pump(tester);
      expect(h.session.drainPaymentCalls, 0, reason: 'nothing while locked');
      await h.unlock(tester);
      expect(h.session.drainPaymentCalls, 1);

      for (var round = 2; round <= 3; round++) {
        for (final state in const [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(h.session.drainPaymentCalls, round);
      }
      // The listener runs beside it.
      expect(h.session.listenerStarts, greaterThan(0));
      expectNothingSpent(h.session);
    });
  });
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoPush implements PushPlatform {
  @override
  Future<bool> start() async => false;

  @override
  Future<bool> configured() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get foreground => const Stream.empty();
}

/// The whole app over the fake, with a mainnet wallet behind PIN 123456.
class _AppHarness {
  _AppHarness() {
    store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    store.values['wallet.mainnet.backedUp'] = '1';
    service = FakeWalletService(
      existingWallets: {'/fake/wallets/mainnet'},
      session: session,
    );
  }

  static const _pin = '123456';
  final store = MemorySecretStore();
  final session = FakeWalletSession();
  late final FakeWalletService service;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          walletServiceProvider.overrideWithValue(service),
          walletDirProvider.overrideWithValue(
            (chain) async => '/fake/wallets/${chain.name}',
          ),
          secretStoreProvider.overrideWithValue(store),
          biometricStoreProvider.overrideWithValue(
            MemoryBiometricStore(available: false),
          ),
          updatePlatformProvider.overrideWithValue(null),
          relayDirectoryProvider.overrideWithValue(_NoRelays()),
          slateFilesProvider.overrideWithValue(FakeSlateFiles()),
          historyFilesProvider.overrideWithValue(FakeHistoryFiles()),
          priceSourceProvider.overrideWithValue(_NoPrice()),
          pushPlatformProvider.overrideWithValue(_NoPush()),
          qrScannerProvider.overrideWithValue(FakeQrScanner(supported: false)),
        ],
        child: const WalletApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  Future<void> unlock(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, 'PIN'), _pin);
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider), isNotNull);
  }
}
