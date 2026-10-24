// Phone first run with Use status.btlabs.uk off: the network setup lists the built-in Epicbox
// servers, says nothing about the site and asks it nothing.
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/public_servers.dart';
import 'package:epic_wallet/src/push.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/ui/network_menu.dart';
import 'package:epic_wallet/src/ui/server_list_sheet.dart';
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoPrice implements PriceSource {
  const _NoPrice();

  @override
  Future<double?> price(String currency) async => null;
}

void main() {
  tearDown(() => statusSite.on = true);

  for (final on in [false, true]) {
    testWidgets('first run, site ${on ? 'on but down' : 'off'}: built-in servers, no request${on ? ' storm' : ''}', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final store = MemorySecretStore();
      if (!on) store.values[AppSettingsNotifier.statusSiteKey] = 'false';
      // As main.dart does before the first frame.
      statusSite.loadFrom(readUseStatusSite(store));
      final hosts = <String>[];
      final directory = HttpRelayDirectory(
        get: (url, {timeout = defaultHttpTimeout}) async {
          hosts.add(url.host);
          return const HttpReply(503, '');
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            walletServiceProvider.overrideWithValue(FakeWalletService()),
            walletDirProvider.overrideWithValue((chain) async => '/fake/wallets/${chain.name}'),
            secretStoreProvider.overrideWithValue(store),
            biometricStoreProvider.overrideWithValue(MemoryBiometricStore(available: false)),
            updatePlatformProvider.overrideWithValue(null),
            pushPlatformProvider.overrideWithValue(null),
            relayDirectoryProvider.overrideWithValue(directory),
            slateFilesProvider.overrideWithValue(FakeSlateFiles()),
            priceSourceProvider.overrideWithValue(const _NoPrice()),
          ],
          child: const WalletApp(),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(TextButton, 'Node and Epicbox');
      await tester.tap(button.evaluate().isNotEmpty ? button : find.byTooltip('Node and Epicbox'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(networkMenuEpicboxKey));
      await tester.pumpAndSettle();
      expect(find.byType(ServerListSheet), findsOneWidget);
      final host = builtInRelays.first.relay.host;
      final relay = find.textContaining(host);
      if (relay.evaluate().isEmpty) {
        await tester.scrollUntilVisible(relay, 300, scrollable: find.byType(Scrollable).first);
      }
      expect(relay, findsWidgets);
      expect(find.textContaining('status.btlabs.uk not reachable', skipOffstage: false), on ? findsWidgets : findsNothing);
      expect(hosts, on ? hasLength(1) : isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
