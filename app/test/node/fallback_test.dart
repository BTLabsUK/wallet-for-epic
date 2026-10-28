// The one confirmed public node while the local node syncs; never a rotation.
import 'package:epic_wallet/src/builtin_node.dart';
import 'package:epic_wallet/src/node/fallback.dart';
import 'package:epic_wallet/src/node/local_node_state.dart';
import 'package:epic_wallet/src/node/node_maintenance.dart';
import 'package:epic_wallet/src/node/node_settings.dart';
import 'package:flutter_test/flutter_test.dart';

LocalNodeState _local(NodeStatusKind kind, {bool? ready, int height = 3764980}) => deriveLocalNodeState(
  BuiltInNodeState(kind, height: height, readyForTxs: ready),
  now: DateTime.utc(2026, 10, 22),
  dataFolder: '/n/main',
  chainDataPath: '/n/main/chain_data',
);

void main() {
  final unasked = const FallbackChoice.unasked();
  final yes = FallbackChoice(FallbackConsent.accepted, at: DateTime.utc(2026, 10, 22));
  const no = FallbackChoice(FallbackConsent.declined);

  test('a synced local node is used whatever the answer', () {
    final synced = _local(NodeStatusKind.running, ready: true);
    expect(synced.online, isTrue);
    for (final c in [unasked, yes, no]) {
      expect(decideFallback(synced, c).action, FallbackAction.useLocal);
    }
  });

  test('unasked: ask once the node starts or syncs, not while it is stopped', () {
    expect(decideFallback(_local(NodeStatusKind.starting), unasked).action, FallbackAction.ask);
    final syncing = decideFallback(_local(NodeStatusKind.syncing, height: 0), unasked);
    expect(syncing.action, FallbackAction.ask);
    expect(syncing.nodeUrl, defaultFallbackNodeUrl);
    expect(decideFallback(_local(NodeStatusKind.stopped), unasked).action, FallbackAction.useLocal);
    expect(decideFallback(_local(NodeStatusKind.failed), unasked).action, FallbackAction.useLocal);
  });

  test('accepted: the agreed node until synced, also while stopped or failing', () {
    for (final k in [NodeStatusKind.starting, NodeStatusKind.syncing, NodeStatusKind.stopped, NodeStatusKind.failed]) {
      final d = decideFallback(_local(k, height: 0), yes);
      expect(d.action, FallbackAction.usePublic, reason: '$k');
      expect(d.active, isTrue);
      expect(d.nodeUrl, defaultFallbackNodeUrl);
    }
    // "running" at height 0 is still syncing: the fallback stays.
    expect(decideFallback(_local(NodeStatusKind.running, ready: false, height: 0), yes).active, isTrue);
  });

  test('declined: the wallet waits on the local node and is not asked again', () {
    final d = decideFallback(_local(NodeStatusKind.syncing, height: 0), no);
    expect(d.action, FallbackAction.useLocal);
    expect(d.active, isFalse);
  });

  test('the yes is for one node: another agreed node is the one used', () {
    const other = FallbackChoice(FallbackConsent.accepted, nodeUrl: 'https://node.epiccash.com:3413');
    expect(decideFallback(_local(NodeStatusKind.syncing, height: 0), other).nodeUrl, 'https://node.epiccash.com:3413');
  });

  test('the stored answer round-trips and garbage is unasked', () {
    expect(FallbackChoice.fromJson(yes.toJson()), yes);
    expect(FallbackChoice.fromJson(no.toJson()), no);
    expect(FallbackChoice.fromJson('x'), unasked);
    expect(FallbackChoice.fromJson({'consent': 'maybe', 'nodeUrl': 'https://a.b'}), unasked);
    expect(FallbackChoice.fromJson({'consent': 'accepted', 'nodeUrl': 'http://a.b'}), unasked, reason: 'https only');
  });

  test('a picked folder holds the chain data in chain_data; reused data is outside the node folder', () {
    expect(NodeMaintenance.chainDataIn('/data/epic'), '/data/epic/chain_data');
    expect(NodeMaintenance.chainDataIn('/data/epic/'), '/data/epic/chain_data');
    expect(NodeMaintenance.chainDataIn('/data/chain_data'), '/data/chain_data');
    expect(_local(NodeStatusKind.running).chainDataReused, isFalse);
    LocalNodeState at(ChainDataOrigin o) => deriveLocalNodeState(
      const BuiltInNodeState(NodeStatusKind.stopped),
      now: DateTime.utc(2026),
      dataFolder: '/n/main',
      chainDataPath: '/elsewhere/chain_data',
      chainDataOrigin: o,
    );
    expect(at(ChainDataOrigin.pointed).chainDataReused, isTrue);
    expect(at(ChainDataOrigin.moved).chainDataReused, isFalse, reason: 'moved by the app: still its own');
  });
}
