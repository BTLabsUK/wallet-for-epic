// SPDX-License-Identifier: Apache-2.0
// Connection servers (connection_servers.dart): the stored set, the state line, the defaults,
// and what the fake pairing sees of the set.
import 'package:epic_wallet/src/connection_servers.dart';
import 'package:epic_wallet/src/models.dart' show Chain;
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/relay_directory.dart' show NodeHealthState;
import 'package:epic_wallet/src/server_list.dart';
import 'package:flutter_test/flutter_test.dart';

const _cash = 'epicbox.epiccash.com';
const _stack = 'epicbox.stackwallet.com';
const _floo = 'flooepicbox.btlabs.uk';
const _net = 'epicbox.epicnet.us';

ConnectionServersLine _line(
  List<String> chosen, {
  Map<String, NodeHealthState?> health = const {},
  bool epicboxOff = false,
  bool offline = false,
}) => connectionServersLine(
  chosen: chosen,
  defaults: defaultConnectionServers(Chain.mainnet),
  health: health,
  epicboxOff: epicboxOff,
  offline: offline,
);

void main() {
  test('the defaults are the three meeting relays on mainnet; floonet and usernet have none and hide the setting', () {
    expect(defaultConnectionServers(Chain.mainnet), [_cash, _stack, _floo]);
    expect(connectionServersShown(Chain.mainnet), isTrue);
    expect(connectionServersShown(Chain.floonet), isFalse);
    expect(connectionServersShown(Chain.usernet), isFalse);
  });

  test('a stored set decodes to at most three valid servers, each once; anything else is the defaults', () {
    expect(decodeConnectionServers(null), isNull);
    expect(decodeConnectionServers('not json'), isNull);
    expect(decodeConnectionServers('[]'), isNull);
    expect(decodeConnectionServers('["not a server"]'), isNull);
    expect(decodeConnectionServers('["$_cash","$_cash","wss://$_net/","a.example.org","b.example.org"]'), [_cash, _net, 'a.example.org']);
    expect(encodeConnectionServers([_cash, _net]), '["$_cash","$_net"]');
  });

  test('the defaults, in any order, store nothing; any other set is stored', () {
    expect(storableConnectionServers(Chain.mainnet, [_cash, _stack, _floo]), isNull);
    expect(storableConnectionServers(Chain.mainnet, [_cash, _stack]), [_cash, _stack]);
    expect(storableConnectionServers(Chain.mainnet, [_cash, _net, _floo]), [_cash, _net, _floo]);
    expect(connectionServersIn(Chain.mainnet, null), [_cash, _stack, _floo]);
    expect(connectionServersIn(Chain.mainnet, [_net]), [_net]);
  });

  test('the state line: Defaults, Changed, a server not responding, none responding, a server that is not a default', () {
    var line = _line([_cash, _stack, _floo]);
    expect((line.kind, line.n), (ConnectionServersLineKind.defaults, 3));
    line = _line([_cash, _stack]);
    expect((line.kind, line.n), (ConnectionServersLineKind.changed, 2));
    line = _line([_cash, _stack, _floo], health: {_stack: NodeHealthState.down});
    expect((line.kind, line.down, line.n), (ConnectionServersLineKind.down, 1, 3));
    expect(line.warn, isTrue);
    line = _line([_cash, _stack], health: {_cash: NodeHealthState.down, _stack: NodeHealthState.down});
    expect(line.kind, ConnectionServersLineKind.allDown);
    expect(line.risk, isTrue);
    line = _line([_cash, 'relay.example.org']);
    expect((line.kind, line.host), (ConnectionServersLineKind.nonDefault, 'relay.example.org'));
    // Unknown health counts as answering; a degraded server is not down.
    expect(_line([_cash], health: {_cash: null}).kind, ConnectionServersLineKind.changed);
    expect(_line([_cash, _stack, _floo], health: {_cash: NodeHealthState.degraded}).kind, ConnectionServersLineKind.defaults);
  });

  test('Offline and Epicbox off pause the line, whatever the health says', () {
    final down = {_cash: NodeHealthState.down};
    expect(_line([_cash, _stack, _floo], health: down, epicboxOff: true).kind, ConnectionServersLineKind.epicboxOff);
    expect(_line([_cash, _stack, _floo], health: down, offline: true, epicboxOff: true).kind, ConnectionServersLineKind.offline);
  });

  test('the fake pairing sees the set a words call is made with; null is the defaults', () async {
    final p = FakePairing();
    await p.makeInvite(name: 'Alex', expiry: const Duration(minutes: 10), words: true);
    p.setConnectionServers([_cash, _net]);
    await p.makeInvite(name: 'Alex', expiry: const Duration(minutes: 10), words: true);
    await p.makeInvite(name: 'Alex', expiry: const Duration(hours: 24));
    expect([for (final e in p.wordsServers) '${e.call}:${e.servers?.join(',')}'], ['invite:null', 'invite:$_cash,$_net']);
    p.setConnectionServers(null);
    expect(p.connectionServers, isNull);
    expect(p.supported, isTrue);
  });

  test('a selection toggles within its limit and keeps one', () {
    const kind = ServerKind.relay;
    expect(toggleSelection(kind, [_cash], _cash, 3).refusal, SelectionRefusal.keepOne);
    expect(toggleSelection(kind, [_cash, _stack, _floo], _net, 3).refusal, SelectionRefusal.limit);
    expect(toggleSelection(kind, [_cash, _stack], _net, 3).next, [_cash, _stack, _net]);
    expect(toggleSelection(kind, [_cash, _stack], _stack, 3).next, [_cash]);
    expect(sameServerSet(kind, [_cash, _stack], [_stack, _cash]), isTrue);
    expect(selectionOrder(kind, [_net, _floo, _cash], (v) => v, [_cash, _stack, _floo]), [_cash, _floo, _net]);
  });
}
