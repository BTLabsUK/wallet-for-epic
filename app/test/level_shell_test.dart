// SPDX-License-Identifier: Apache-2.0
// Home at every level (the phone redesign: one Home, the level no longer changes it), the
// connections sheet behind the status pill, the Contacts tab, the invoice slot card, and the
// relay offer as a notice whose Switch calls through.
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/levels/relay_switch_providers.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/onion_notice.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart' show networkModeProvider;
import 'package:epic_wallet/src/send_preflight.dart' show FakeRelayProbe, relayProbeProvider;
import 'package:epic_wallet/src/ui/contacts_screen.dart';
import 'package:epic_wallet/src/ui/home_parts.dart';
import 'package:epic_wallet/src/ui/home_screen.dart';
import 'package:epic_wallet/src/ui/home_status.dart' show barNodeIconKey, connectionsSheetKey;
import 'package:epic_wallet/src/ui/home_tab.dart' show homeFigureKey, homePillKey;
import 'package:epic_wallet/src/ui/kit/kit_tab_bar.dart';
import 'package:epic_wallet/src/ui/levels/shell_status.dart';
import 'package:epic_wallet/src/ui/network_mode_phone.dart' show networkModeChangeKey, networkModeMarkKey, networkSectionKey;
import 'package:epic_wallet/src/ui/notices.dart';
import 'package:epic_wallet/src/ui/shell_header.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'support/shell_where.dart';
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

Future<void> _pump(
  WidgetTester tester, {
  required String level,
  _Offer? offer,
  bool invoice = false,
  NetworkMode mode = NetworkMode.standard,
}) async {
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
        networkModeProvider.overrideWithValue(mode),
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
  for (final level in ['1', '3']) {
    testWidgets('level $level: Home is the same: the pill, the figure and two buttons, no icons, no tiles', (tester) async {
      await _pump(tester, level: level);
      expect(find.byKey(homePillKey), findsOneWidget);
      expect(find.byKey(homeFigureKey), findsOneWidget);
      expect(find.byType(StatusIcon), findsNothing);
      expect(find.byKey(walletStatusesKey), findsNothing);
      expect(find.byKey(shellNetworkIconKey), findsNothing);
      expect(find.byKey(nodeStatusKey), findsNothing);
      expect(find.byType(BalanceTiles), findsNothing);
      expect(find.byType(HomeDestinations), findsNothing);
      expect(find.byType(HomeContactsEntry), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      // Contacts is a tab now, the same at every level.
      expect(find.descendant(of: find.byType(KitTabBar), matching: find.text(_l.settingsContacts)), findsOneWidget);
    });
  }

  testWidgets('Normal shows no mode line in the connections sheet', (tester) async {
    await _pump(tester, level: '1');
    expect(find.byKey(networkModeMarkKey), findsNothing);
    await tester.tap(find.byKey(homePillKey));
    await tester.pumpAndSettle();
    expect(find.byKey(connectionsSheetKey), findsOneWidget);
    expect(find.byKey(networkModeMarkKey), findsNothing);
  });

  for (final mode in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
    testWidgets('${mode.name} names the mode in the connections sheet, nothing on Home; Change opens the setting', (tester) async {
      await _pump(tester, level: '1', mode: mode);
      // Home keeps the pill alone: the mode is named where it leads.
      expect(find.byKey(networkModeMarkKey), findsNothing);
      await tester.tap(find.byKey(homePillKey));
      await tester.pumpAndSettle();
      final line = find.descendant(of: find.byKey(connectionsSheetKey), matching: find.byKey(networkModeMarkKey));
      expect(line, findsOneWidget);
      final name = mode == NetworkMode.nodeOnly ? _l.advModeNodeOnly : _l.advModeKillSwitch;
      expect(find.descendant(of: line, matching: find.text(_l.netMarkRowLabel(name))), findsOneWidget);
      await tester.tap(find.byKey(networkModeChangeKey));
      await tester.pumpAndSettle();
      expect(find.byKey(connectionsSheetKey), findsNothing);
      expect(find.byKey(networkSectionKey), findsOneWidget);
    });
  }

  testWidgets('the Contacts tab opens Contacts', (tester) async {
    await _pump(tester, level: '1');
    await shellGo(tester, _l.settingsContacts);
    expect(find.byType(ContactsScreen), findsOneWidget);
  });

  testWidgets('level 1: Send and Receive carry the two icons in the balance header', (tester) async {
    await _pump(tester, level: '1');
    await shellGo(tester, _l.homeSendButton, settle: false);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(balanceHeaderKey), findsOneWidget);
    expect(find.descendant(of: find.byKey(balanceHeaderKey), matching: find.byKey(shellBarNetworkIconKey)), findsOneWidget);
    expect(find.descendant(of: find.byKey(balanceHeaderKey), matching: find.byKey(shellBarEpicboxIconKey)), findsOneWidget);
    expect(find.byKey(barNodeIconKey), findsNothing);
  });

  testWidgets('an invoice waiting is the slot card on Home, never a notice', (tester) async {
    await _pump(tester, level: '1', invoice: true);
    await shellContainer(tester).read(pendingInvoicesProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-slot-invoice-inv-1')), findsOneWidget);
    expect(find.byKey(noticeKey), findsNothing);
    // No explainer card about a send that waits: the rows say "Waiting for …" themselves.
    expect(find.textContaining('A payment is waiting'), findsNothing);
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
}
