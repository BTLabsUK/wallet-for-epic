// SPDX-License-Identifier: Apache-2.0
// Switch server on the level-1 status sheets: the Epicbox sheet lists the other relays by
// address with the status site's health, healthy first, a down one not tappable; a tap moves
// through the relay offer's path and the sheet then offers the new address. On the Network
// side a tap on a node switches it.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart';
import 'package:epic_wallet/src/levels/relay_switch_providers.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/server_list.dart';
import 'package:epic_wallet/src/server_list_file.dart' show serverListValues;
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart';
import 'package:epic_wallet/src/ui/levels/shallow_switch.dart';
import 'package:epic_wallet/src/ui/levels/status_sheets.dart';
import 'package:epic_wallet/src/ui/server_picker.dart' show publicNodeStatusProvider;
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

const _a = EpicboxRelay(host: 'relay-a.example.invalid');
const _b = EpicboxRelay(host: 'relay-b.example.invalid');
const _c = EpicboxRelay(host: 'relay-c.example.invalid', port: 8443);
const _d = EpicboxRelay(host: 'relay-d.example.invalid');
const _nodeA = 'https://node-a.example.invalid';
const _nodeB = 'https://node-b.example.invalid';
const _nodeC = 'https://node-c.example.invalid';

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(dataDir: '/fake/wallets/mainnet', nodeUrl: _nodeA, relay: _a);
}

class _Hosts extends HostSettingsNotifier {
  @override
  HostSettings build() => hostSettings.withValues({
    ...serverListValues(ServerKind.relay, ServerList(entries: [_a.label, _b.label, _c.label, _d.label])),
    ...serverListValues(ServerKind.node, const ServerList(entries: [_nodeA, _nodeB, _nodeC])),
  });
}

/// No offer; [moveTo] records the relay and sets the result, as the real move does.
class _Relays extends RelaySwitchNotifier {
  final moves = <EpicboxRelay>[];

  @override
  RelaySwitchOffer? build() => null;

  @override
  Future<RelaySwitchResult?> moveTo(WidgetRef widgetRef, RelayCandidate to, {String? address}) async {
    moves.add(to.relay);
    final result = RelaySwitchResult(from: _a, relay: to.relay, name: to.name, address: 'esNew@${to.relay.label}');
    ref.read(relaySwitchResultProvider.notifier).set(result);
    return result;
  }
}

Future<void> _pump(WidgetTester tester, Widget body, {_Relays? relays}) async {
  tester.view.physicalSize = const Size(1800, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = FakeWalletSession();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        secretStoreProvider.overrideWithValue(MemorySecretStore({'app.level': '1'})),
        sessionProvider.overrideWith(() => _OpenSession(session)),
        walletConfigProvider.overrideWith(_Config.new),
        hostSettingsProvider.overrideWith(_Hosts.new),
        relayStatusProvider(mainnetPreset).overrideWith(
          (ref) async => const [
            RelayStatus(relay: _b, healthy: false, verified: true),
            RelayStatus(relay: _c, healthy: true, verified: true),
          ],
        ),
        publicNodeStatusProvider(mainnetPreset).overrideWith(
          (ref) async => const [
            NodeStatus(url: _nodeB, healthy: false, verified: true, state: NodeHealthState.down),
            NodeStatus(url: _nodeC, healthy: true, verified: true, state: NodeHealthState.healthy),
          ],
        ),
        if (relays != null) relaySwitchProvider.overrideWith(() => relays),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: body),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Epicbox: Switch server lists the other relays by address, healthy first; a tap moves', (tester) async {
    final relays = _Relays();
    await _pump(tester, const EpicboxSheet(), relays: relays);
    // No For support group, no Copy details.
    expect(find.text('For support'), findsNothing);
    expect(find.text('Copy details'), findsNothing);
    await tester.tap(find.byKey(shallowSwitchKey(ServerKind.relay)));
    await _settle(tester);
    // The relay in use is not offered; each other one by its address (port when not 443).
    expect(find.byKey(shallowSwitchRowKey(_a.label)), findsNothing);
    expect(find.text('relay-c.example.invalid:8443'), findsOneWidget);
    expect(find.text('relay-b.example.invalid'), findsOneWidget);
    expect(find.text('relay-d.example.invalid'), findsOneWidget);
    // Healthy, then not checked, then down.
    final ys = [
      for (final r in [_c, _d, _b]) tester.getTopLeft(find.byKey(shallowSwitchRowKey(r.label))).dy,
    ];
    expect(ys[0] < ys[1] && ys[1] < ys[2], isTrue);
    expect(find.text(_l.serverHealthy), findsOneWidget);
    expect(find.text(_l.stateUnchecked), findsOneWidget);
    expect(find.text(_l.deskNodeNotAnswering), findsOneWidget);
    // A relay listed as down cannot be picked.
    expect(tester.widget<ListTile>(find.byKey(shallowSwitchRowKey(_b.label))).onTap, isNull);
    await tester.tap(find.byKey(shallowSwitchRowKey(_b.label)));
    await _settle(tester);
    expect(relays.moves, isEmpty);
    await tester.tap(find.byKey(shallowSwitchRowKey(_c.label)));
    await _settle(tester);
    expect(relays.moves, [_c]);
    // The sheet then shows the move as after an accepted offer.
    expect(find.text('Now on relay-c.example.invalid:8443'), findsOneWidget);
    expect(find.byKey(sheetShowAddressKey), findsOneWidget);
  });

  testWidgets('Epicbox: a relay not checked can be picked', (tester) async {
    final relays = _Relays();
    await _pump(tester, const EpicboxSheet(), relays: relays);
    await tester.tap(find.byKey(shallowSwitchKey(ServerKind.relay)));
    await _settle(tester);
    await tester.tap(find.byKey(shallowSwitchRowKey(_d.label)));
    await _settle(tester);
    expect(relays.moves, [_d]);
  });

  testWidgets('Network: a tap on a node switches it; a down node cannot be picked', (tester) async {
    final calls = <(String, EpicboxRelay)>[];
    await _pump(
      tester,
      ShallowServerSwitch(
        kind: ServerKind.node,
        liveSwitch: (ref, {required nodeUrl, required relay}) async {
          calls.add((nodeUrl, relay));
          return true;
        },
      ),
    );
    await tester.tap(find.byKey(shallowSwitchKey(ServerKind.node)));
    await _settle(tester);
    expect(find.byKey(shallowSwitchRowKey(_nodeA)), findsNothing);
    expect(find.text('node-c.example.invalid'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byKey(shallowSwitchRowKey(_nodeB))).onTap, isNull);
    await tester.tap(find.byKey(shallowSwitchRowKey(_nodeC)));
    await _settle(tester);
    expect(calls, [(_nodeC, _a)]);
    expect(find.text('Switched to node-c.example.invalid'), findsOneWidget);
  });

  testWidgets('Network sheet: Switch server, no For support', (tester) async {
    await _pump(tester, const NetworkSheet());
    expect(find.byKey(shallowSwitchKey(ServerKind.node)), findsOneWidget);
    expect(find.text('For support'), findsNothing);
    expect(find.text('Copy details'), findsNothing);
    expect(find.text('node-a.example.invalid'), findsOneWidget);
  });
}
