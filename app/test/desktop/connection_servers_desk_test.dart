// Settings › Advanced › Connection servers on the desktop (connection_servers_row.dart): the row
// sits under the Pairing switch, hidden while Pairing is off; the field lists every chosen host;
// the list takes ticks up to three and stores the set (the defaults store nothing); the state
// line follows the set and the network mode.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/pairing_state.dart';
import 'package:epic_wallet/src/desktop/screens/settings/connection_servers_row.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

late ProviderContainer _container;

Future<void> _open(WidgetTester tester, {bool pairing = true, AdvancedPrefs? advanced}) async {
  tester.view.physicalSize = const Size(1280, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final wallet = MockDeskWallet(delay: Duration.zero);
  _container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(wallet)], retry: (_, _) => null);
  addTearDown(_container.dispose);
  await tester.runAsync(() async {
    final n = _container.read(deskProvider.notifier);
    await n.refresh();
    final prefs = advanced ?? (pairing ? AdvancedPrefs.none.withExperimental(AdvancedFeature.pairing, true) : AdvancedPrefs.none);
    await n.saveSettings(_container.read(deskProvider).settings.copyWith(advanced: prefs, tourSeen: true));
  });
  _container.read(deskNavProvider.notifier).reset(DeskRoute.settingsAdvanced);
  await tester.pumpWidget(UncontrolledProviderScope(container: _container, child: const DeskApp()));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Finder _row(String host) => find.byKey(ValueKey('server-row-$host'));

void main() {
  testWidgets('the row shows under Pairing with the defaults and its state line', (tester) async {
    await _open(tester);
    expect(find.byKey(connectionServersRowKey), findsOneWidget);
    expect(find.text('Connection servers'), findsOneWidget);
    expect(find.text('Where two wallets find each other when they connect. The other wallet must use at least one of them too.'), findsOneWidget);
    expect(find.text('epicbox.epiccash.com, epicbox.stackwallet.com, flooepicbox.btlabs.uk'), findsOneWidget);
    expect(find.text('3 servers · Defaults'), findsOneWidget);
  });

  testWidgets('Pairing off hides the row', (tester) async {
    await _open(tester, pairing: false);
    expect(find.byKey(connectionServersRowKey), findsNothing);
  });

  testWidgets('the list takes ticks up to three; the set is kept, the defaults keep nothing', (tester) async {
    await _open(tester);
    await tester.tap(find.text('epicbox.epiccash.com, epicbox.stackwallet.com, flooepicbox.btlabs.uk'));
    await _settle(tester);
    expect(find.text('Choose up to 3.'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);

    await tester.tap(_row('epicbox.epicnet.us'));
    await _settle(tester);
    expect(find.text('3 of 3 chosen. Untick one to choose another.'), findsOneWidget);
    expect(_container.read(deskPairingRelaysProvider), isNull);

    await tester.tap(_row('flooepicbox.btlabs.uk'));
    await _settle(tester);
    expect(_container.read(deskPairingRelaysProvider), ['epicbox.epiccash.com', 'epicbox.stackwallet.com']);
    expect(find.text('2 servers · Changed'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('server-list-reset')));
    await _settle(tester);
    expect(_container.read(deskPairingRelaysProvider), isNull);
    expect(find.text('3 servers · Defaults'), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
  });

  testWidgets('Offline and Epicbox off pause the line', (tester) async {
    await _open(tester, advanced: const AdvancedPrefs(networkMode: NetworkMode.offline).withExperimental(AdvancedFeature.pairing, true));
    expect(find.text('Paused while Offline is on.'), findsOneWidget);
  });
}
