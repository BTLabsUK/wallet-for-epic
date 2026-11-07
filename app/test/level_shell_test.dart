// SPDX-License-Identifier: Apache-2.0
// The level-1 shell on Home: the deeper levels' balance block with level 1's two status icons
// under the figure, no tiles, one Contacts entry, the Epicbox sheet on a tap, and the relay offer
// as a notice whose Switch calls through. Level 3 keeps its full row of icons and the tiles.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/levels/relay_switch_providers.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/onion_notice.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/levels/quiet_invoices.dart';
import 'package:epic_wallet/src/ui/home_status.dart' show barNodeIconKey, connectionsSheetKey;
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

final _l = englishStrings;

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
    onionNoticeKey('mainnet', null): onionNoticeSeen,
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
  testWidgets('level 1: the balance block as at level 3, two status icons under the figure, no tiles, Contacts', (tester) async {
    await _pump(tester, level: '1');
    // The same block as the deeper levels: the caption, the figure, the icon row with the fiat
    // value and the eye; level 1's two icons in it, nothing in the app bar.
    expect(find.byKey(balanceCaptionKey), findsOneWidget);
    expect(find.byKey(shellNetworkIconKey), findsOneWidget);
    expect(find.byKey(shellEpicboxIconKey), findsOneWidget);
    expect(find.byType(StatusIcon), findsNWidgets(2));
    expect(find.byKey(nodeStatusKey), findsNothing);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    expect(tester.widget<StatusIcon>(find.byKey(shellNetworkIconKey)).label, startsWith('Network · '));
    final icons = tester.getTopLeft(find.byKey(shellNetworkIconKey));
    final bar = tester.getRect(find.byType(AppBar));
    expect(icons.dy, greaterThan(bar.bottom), reason: 'the icons are under the figure, not in the bar');
    // No tiles; of the destinations only Contacts, one entry under the balance.
    expect(find.byType(BalanceTiles), findsNothing);
    expect(find.byType(HomeDestinations), findsNothing);
    expect(find.text('+12.5 arriving · 7.5 on hold'), findsNothing);
    expect(find.byType(HomeContactsEntry), findsOneWidget);
    expect(find.byKey(homeDestinationKey(HomeDestination.contacts)), findsOneWidget);
    expect(find.text(_l.settingsContacts), findsOneWidget);
    expect(tester.getSize(find.byType(HomeContactsEntry)).height, greaterThanOrEqualTo(48));
  });

  testWidgets('level 1: the Contacts entry opens Contacts', (tester) async {
    await _pump(tester, level: '1');
    await tester.tap(find.byKey(homeDestinationKey(HomeDestination.contacts)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ContactsScreen), findsOneWidget);
  });

  testWidgets('level 1: Send and Receive carry the two icons in the balance header', (tester) async {
    await _pump(tester, level: '1');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(_l.homeSendButton)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(balanceHeaderKey), findsOneWidget);
    expect(find.descendant(of: find.byKey(balanceHeaderKey), matching: find.byKey(shellBarNetworkIconKey)), findsOneWidget);
    expect(find.descendant(of: find.byKey(balanceHeaderKey), matching: find.byKey(shellBarEpicboxIconKey)), findsOneWidget);
    expect(find.byKey(barNodeIconKey), findsNothing);
  });

  testWidgets('level 1: an invoice waiting is a row under Recent activity, never a notice', (tester) async {
    await _pump(tester, level: '1', invoice: true);
    expect(find.byKey(quietInvoiceKey('inv-1')), findsOneWidget);
    expect(find.text(_l.lvPolInvoiceWaiting), findsOneWidget);
    expect(find.byKey(noticeKey), findsNothing);
    // No explainer card about a send that waits: the rows say "Waiting for …" themselves.
    expect(find.textContaining('A payment is waiting'), findsNothing);
  });

  testWidgets('the Network sheet keeps Close clear of the bottom system inset', (tester) async {
    await _pump(tester, level: '1');
    // An edge-to-edge phone: a 48 dp navigation bar under the sheet.
    tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48 * 3);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.tap(find.byKey(shellNetworkIconKey));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The icon opens the connections sheet; its Network row the Network sheet.
    expect(find.byKey(connectionsSheetKey), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(connectionsSheetKey), matching: find.textContaining(_l.settingsAboutNetwork)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(networkSheetKey), findsOneWidget);
    final okBottom = tester.getBottomLeft(find.widgetWithText(TextButton, _l.commonClose)).dy;
    expect(okBottom, lessThanOrEqualTo(2400 / 3 - 48));
  });

  testWidgets('level 1: a tap on Epicbox opens the connections sheet, its row the Epicbox sheet', (tester) async {
    await _pump(tester, level: '1');
    await tester.tap(find.byKey(shellEpicboxIconKey));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(connectionsSheetKey), findsOneWidget);
    expect(find.byKey(epicboxSheetKey), findsNothing);
    await tester.tap(find.descendant(of: find.byKey(connectionsSheetKey), matching: find.textContaining(_l.netStatusEpicbox)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(epicboxSheetKey), findsOneWidget);
    expect(find.text('For support'), findsNothing);
    expect(find.text(_l.lvShellSwitchServer), findsOneWidget);
  });

  for (final level in ['1', '3']) {
    testWidgets('level $level: the relay offer is a notice; Switch calls through', (tester) async {
      final offer = _Offer();
      await _pump(tester, level: level, offer: offer);
      expect(find.byKey(noticeKey), findsOneWidget);
      // Compact (item 11): a title, one line naming the server, Switch; the close button is
      // Not now.
      expect(find.text(_l.lvShellRelayDownTitle), findsOneWidget);
      expect(find.text('Relay B can take over; your address changes with it.'), findsOneWidget);
      expect(find.text(_l.homeHistoryReminderNotNow), findsNothing);
      expect(offer.accepts, 0, reason: 'nothing moves without a tap');
      await tester.tap(find.widgetWithText(TextButton, 'Switch'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(offer.accepts, 1, reason: 'only the tap moves');
      expect(find.text('Now on Relay B. Your new address is ready.'), findsOneWidget);
      expect(find.text(_l.lvShellShowNewAddress), findsOneWidget);
    });
  }

  testWidgets('level 3: the full row of icons under the figure, the tiles', (tester) async {
    await _pump(tester, level: '3');
    expect(find.byKey(shellNetworkIconKey), findsNothing);
    expect(find.byType(HomeContactsEntry), findsNothing);
    expect(find.byKey(walletStatusesKey), findsOneWidget);
    expect(find.byKey(nodeStatusKey), findsOneWidget);
    expect(find.byKey(epicboxStatusKey), findsOneWidget);
    expect(find.byType(BalanceTiles), findsOneWidget);
    expect(find.byKey(balanceCaptionKey), findsOneWidget);
  });
}
