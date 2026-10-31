// SPDX-License-Identifier: Apache-2.0
// The level-1 quiet shell on Home: two status icons in the bar, no tiles, the Epicbox sheet on
// a tap, and the relay offer as a notice whose Switch calls through. Level 3 keeps today's icons.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/levels/relay_switch_providers.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/levels/quiet_invoices.dart';
import 'package:epic_wallet/src/ui/levels/shell_status.dart';
import 'package:epic_wallet/src/ui/levels/status_sheets.dart';
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: 'https://node');
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoUpdates extends UpdateNotifier {}

const EpicboxRelay _from = EpicboxRelay(host: 'relay-a.example.invalid');
const EpicboxRelay _to = EpicboxRelay(host: 'relay-b.example.invalid');

/// An offer standing from the start; Switch counts its calls.
class _Offer extends RelaySwitchNotifier {
  int accepts = 0;

  @override
  RelaySwitchOffer? build() => const RelaySwitchOffer(from: _from, to: _to, name: 'Relay B');

  @override
  Future<RelaySwitchResult?> accept(WidgetRef widgetRef) async {
    accepts++;
    state = null;
    return const RelaySwitchResult(from: _from, relay: _to, name: 'Relay B', address: 'esNew@relay-b.example.invalid');
  }
}

Future<void> _pump(WidgetTester tester, {required String level, _Offer? offer, bool invoice = false}) async {
  // The test font is twice Roboto's width: a 600 dp view keeps the notice buttons on their row.
  tester.view.physicalSize = const Size(1800, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final store = MemorySecretStore({
    'app.level': level,
    'wallet.mainnet.backedUp': '1',
  });
  final session = FakeWalletSession(
    summary: WalletSummary(
      lastConfirmedHeight: BigInt.from(100),
      minimumConfirmations: BigInt.from(3),
      total: BigInt.from(5000000000),
      spendable: BigInt.from(3000000000),
      awaitingConfirmation: BigInt.from(1250000000),
      awaitingFinalization: BigInt.zero,
      immature: BigInt.zero,
      locked: BigInt.from(750000000),
      validatedWithNode: true,
    ),
  );
  if (invoice) {
    session.pendingInvoicesValue['inv-1'] = PendingInvoice(
      slateId: 'inv-1',
      senderAddress: 'esCoffee@relay-a.example.invalid',
      amount: BigInt.from(420000000),
      message: 'Flat white ×2',
      receivedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
    );
  }
  final service = FakeWalletService(session: session);
  session.owner = service;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        relayProbeProvider.overrideWithValue(FakeRelayProbe()),
        walletServiceProvider.overrideWithValue(service),
        secretStoreProvider.overrideWithValue(store),
        updatePlatformProvider.overrideWithValue(null),
        updateProvider.overrideWith(_NoUpdates.new),
        priceSourceProvider.overrideWithValue(_NoPrice()),
        sessionProvider.overrideWith(() => _OpenSession(session)),
        walletConfigProvider.overrideWith(_Config.new),
        if (offer != null) relaySwitchProvider.overrideWith(() => offer),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('level 1: two status icons in the bar, no tiles, a quiet line', (tester) async {
    await _pump(tester, level: '1');
    expect(find.byKey(shellNetworkIconKey), findsOneWidget);
    expect(find.byKey(shellEpicboxIconKey), findsOneWidget);
    expect(find.byType(StatusIcon), findsNWidgets(2));
    expect(find.byKey(nodeStatusKey), findsNothing);
    expect(find.byType(BalanceTiles), findsNothing);
    expect(find.byType(HomeDestinations), findsNothing);
    expect(find.byKey(balanceCaptionKey), findsNothing);
    expect(find.text('+12.5000 arriving · 7.5000 on hold'), findsOneWidget);
    // The hide-amounts eye moved to Settings › Appearance.
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    expect(tester.widget<StatusIcon>(find.byKey(shellNetworkIconKey)).label, startsWith('Network · '));
  });

  testWidgets('level 1: an invoice waiting is a row under Recent activity, never a notice', (tester) async {
    await _pump(tester, level: '1', invoice: true);
    expect(find.byKey(quietInvoiceKey('inv-1')), findsOneWidget);
    expect(find.text('Invoice · waiting for your approval'), findsOneWidget);
    expect(find.byKey(noticeKey), findsNothing);
    // No explainer card about a send that waits: the rows say "Waiting for …" themselves.
    expect(find.textContaining('A payment is waiting'), findsNothing);
  });

  testWidgets('level 1: a tap on Epicbox opens its sheet', (tester) async {
    await _pump(tester, level: '1');
    await tester.tap(find.byKey(shellEpicboxIconKey));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(epicboxSheetKey), findsOneWidget);
    expect(find.text('For support'), findsOneWidget);
    expect(find.byKey(sheetCopyDetailsKey), findsOneWidget);
  });

  testWidgets('level 1: the relay offer is a notice; Switch calls through', (tester) async {
    final offer = _Offer();
    await _pump(tester, level: '1', offer: offer);
    expect(find.byKey(noticeKey), findsOneWidget);
    expect(find.textContaining('Relay B is ready to take over'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    await tester.tap(find.text('Switch to Relay B'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(offer.accepts, 1);
    expect(find.text('Now on Relay B. Your new address is ready.'), findsOneWidget);
    expect(find.text('Show new address'), findsOneWidget);
  });

  testWidgets("level 3: today's icons under the figure, the tiles, nothing in the bar", (tester) async {
    await _pump(tester, level: '3');
    expect(find.byKey(shellNetworkIconKey), findsNothing);
    expect(find.byKey(walletStatusesKey), findsOneWidget);
    expect(find.byKey(nodeStatusKey), findsOneWidget);
    expect(find.byKey(epicboxStatusKey), findsOneWidget);
    expect(find.byType(BalanceTiles), findsOneWidget);
    expect(find.byKey(balanceCaptionKey), findsOneWidget);
  });
}
