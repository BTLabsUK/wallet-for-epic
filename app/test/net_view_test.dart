// SPDX-License-Identifier: Apache-2.0
// One source of truth for what the connection mode shows: the mode mark, the health the Home pill
// gives and the Tor badge of each route. Every mode × Tor state × node/Epicbox state.
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:epic_wallet/src/ui/net_view.dart';
import 'package:epic_wallet/src/ui/network_status.dart' show nodeTorWay;
import 'package:epic_wallet/src/ui/status.dart';
import 'package:flutter_test/flutter_test.dart';

WalletStatus _s(NodeState node, EpicboxState? box) => (node: NodeStatus(node), epicbox: box);

void main() {
  group('mode mark', () {
    test('none in Normal, a mark in every other mode', () {
      expect(netModeMark(NetworkMode.standard), isNull);
      for (final m in [NetworkMode.torOnly, NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
        expect(netModeMark(m), isNotNull, reason: m.name);
      }
    });
  });

  group('health', () {
    test('Kill switch is paused whatever the services say', () {
      for (final n in NodeState.values) {
        for (final b in [null, ...EpicboxState.values]) {
          expect(netHealth(NetworkMode.killSwitch, _s(n, b)), HomeConnection.paused, reason: '$n $b');
        }
      }
    });

    test('Node only counts the node alone: Epicbox, whatever it says, is not asked', () {
      for (final b in [null, ...EpicboxState.values]) {
        expect(netHealth(NetworkMode.nodeOnly, _s(NodeState.online, b)), HomeConnection.ready, reason: '$b');
        expect(netHealth(NetworkMode.nodeOnly, _s(NodeState.syncing, b)), HomeConnection.syncing, reason: '$b');
        expect(netHealth(NetworkMode.nodeOnly, _s(NodeState.connecting, b)), HomeConnection.reconnecting, reason: '$b');
        expect(netHealth(NetworkMode.nodeOnly, _s(NodeState.offline, b)), HomeConnection.offline, reason: '$b');
      }
    });

    for (final mode in [NetworkMode.standard, NetworkMode.torOnly]) {
      test('${mode.name} counts the node and Epicbox', () {
        expect(netHealth(mode, _s(NodeState.online, EpicboxState.online)), HomeConnection.ready);
        expect(netHealth(mode, _s(NodeState.online, null)), HomeConnection.ready);
        expect(netHealth(mode, _s(NodeState.syncing, EpicboxState.online)), HomeConnection.syncing);
        expect(netHealth(mode, _s(NodeState.online, EpicboxState.connecting)), HomeConnection.reconnecting);
        expect(netHealth(mode, _s(NodeState.online, EpicboxState.offline)), HomeConnection.reconnecting);
        expect(netHealth(mode, _s(NodeState.online, EpicboxState.blocked)), HomeConnection.reconnecting);
        expect(netHealth(mode, _s(NodeState.connecting, EpicboxState.online)), HomeConnection.reconnecting);
        expect(netHealth(mode, _s(NodeState.offline, EpicboxState.online)), HomeConnection.reconnecting);
        expect(netHealth(mode, _s(NodeState.offline, EpicboxState.offline)), HomeConnection.offline);
        expect(netHealth(mode, _s(NodeState.offline, EpicboxState.blocked)), HomeConnection.offline);
      });
    }

    test('the same state in two modes differs only where the mode drops a service', () {
      final s = _s(NodeState.online, EpicboxState.connecting);
      expect(netHealth(NetworkMode.standard, s), HomeConnection.reconnecting);
      expect(netHealth(NetworkMode.nodeOnly, s), HomeConnection.ready);
      expect(netHealth(NetworkMode.killSwitch, s), HomeConnection.paused);
    });
  });

  group('Tor badges follow the mode and the Tor state at once', () {
    const routes = [TorRoute.epicbox, TorRoute.node, TorRoute.appHttp];

    test('Kill switch: every route is off, Tor on or not', () {
      for (final t in TorState.values) {
        for (final r in routes) {
          expect(torWayIn(r, t, NetworkMode.killSwitch), TorWay.off, reason: '$r $t');
        }
        expect(nodeTorWay('https://node.example.invalid', t, NetworkMode.killSwitch), TorWay.off);
      }
    });

    test('Node only: Epicbox is off; the node follows the Tor switch', () {
      for (final t in TorState.values) {
        expect(torWayIn(TorRoute.epicbox, t, NetworkMode.nodeOnly), TorWay.off, reason: '$t');
        expect(torWayIn(TorRoute.node, t, NetworkMode.nodeOnly), torWay(TorRoute.node, t), reason: '$t');
      }
      expect(nodeTorWay('https://node.example.invalid', TorState.off, NetworkMode.nodeOnly), TorWay.clearnet);
      expect(nodeTorWay('https://node.example.invalid', TorState.on, NetworkMode.nodeOnly), TorWay.overTor);
    });

    test('Normal: every covered route follows the Tor switch', () {
      for (final t in TorState.values) {
        for (final r in routes) {
          expect(torWayIn(r, t, NetworkMode.standard), torWay(r, t), reason: '$r $t');
        }
      }
    });

    test('Tor only: never the clearnet, also before the switch has come on', () {
      for (final t in TorState.values) {
        for (final r in routes) {
          final way = torWayIn(r, t, NetworkMode.torOnly);
          expect(way == TorWay.clearnet, isFalse, reason: '$r $t');
        }
      }
      expect(torWayIn(TorRoute.epicbox, TorState.off, NetworkMode.torOnly), TorWay.wait);
      expect(torWayIn(TorRoute.epicbox, TorState.on, NetworkMode.torOnly), TorWay.overTor);
    });
  });
}
