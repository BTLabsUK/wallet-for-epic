/// The local node's peers through its owner API: who it is connected to, which peers it banned,
/// ban and unban, and peer counts over the session for small graphs.
///
/// The node gives no ping, connected-since or byte counts. [PeerView.firstSeen] is when this app
/// first saw the peer connected in this session, not when the connection began. A peer missing
/// from one read keeps it (reads are 10 s apart and the list flickers); missing from two in a
/// row, it starts again.
library;

import 'node_api.dart';
import 'node_api_types.dart';

/// One connected peer, with what the node's peer store adds.
class PeerView {
  const PeerView(this.peer, {this.stored, this.firstSeen});

  final ConnectedPeer peer;

  /// The store's entry for the same address, when it has one.
  final StoredPeer? stored;
  final DateTime? firstSeen;

  String get addr => peer.addr;
}

/// One look at the peers.
class PeerSnapshot {
  const PeerSnapshot({required this.at, required this.connected, required this.banned});

  final DateTime at;

  /// Outbound first, then by height (highest first), then by address.
  final List<PeerView> connected;

  /// Every peer the node has banned, most recently banned first.
  final List<StoredPeer> banned;

  int get inbound => connected.where((p) => p.peer.direction == PeerDirection.inbound).length;
  int get outbound => connected.where((p) => p.peer.direction == PeerDirection.outbound).length;

  /// The highest height a connected peer advertises (unverified), or null without peers.
  int? get maxHeight =>
      connected.isEmpty ? null : connected.map((p) => p.peer.height).reduce((a, b) => a > b ? a : b);
}

/// One point of the peer graph.
class PeerCountSample {
  const PeerCountSample(this.at, {required this.inbound, required this.outbound, this.maxHeight});

  final DateTime at;
  final int inbound;
  final int outbound;
  final int? maxHeight;

  int get total => inbound + outbound;
}

/// Peers of one node. Owner calls: the client needs the node's secret.
class PeerService {
  PeerService(
    this._api, {
    DateTime Function()? clock,
    this.historyLimit = 240,
    this.sampleEvery = const Duration(seconds: 30),
  }) : _clock = clock ?? DateTime.now;

  final NodeApiClient _api;
  final DateTime Function() _clock;

  /// Samples kept: 240 at one each 30 s is two hours.
  final int historyLimit;

  /// [refresh] adds a sample to [history] at most this often: the table reads more often than
  /// the graph samples.
  final Duration sampleEvery;

  final Map<String, DateTime> _firstSeen = {};
  final Map<String, int> _missed = {};
  final List<PeerCountSample> _history = [];
  PeerSnapshot? _last;

  PeerSnapshot? get last => _last;

  /// Oldest first.
  List<PeerCountSample> get history => List.unmodifiable(_history);

  /// Reads the connected peers and the peer store; adds a sample to [history] once the last one
  /// is [sampleEvery] old. Throws [NodeRpcException] when the node does not answer.
  Future<PeerSnapshot> refresh() async {
    final live = await _api.connectedPeers();
    final stored = await _api.peers();
    final now = _clock();
    final byAddr = {for (final s in stored) s.addr: s};
    final present = {for (final p in live) p.addr};
    for (final addr in _firstSeen.keys.toList()) {
      if (present.contains(addr)) continue;
      final missed = (_missed[addr] ?? 0) + 1;
      if (missed < 2) {
        _missed[addr] = missed;
      } else {
        _firstSeen.remove(addr);
        _missed.remove(addr);
      }
    }
    for (final addr in present) {
      _firstSeen.putIfAbsent(addr, () => now);
      _missed.remove(addr);
    }
    final connected = [
      for (final p in live) PeerView(p, stored: byAddr[p.addr], firstSeen: _firstSeen[p.addr]),
    ]..sort(_order);
    final banned = stored.where((s) => s.banned).toList()
      ..sort((a, b) => (b.lastBanned ?? _epoch).compareTo(a.lastBanned ?? _epoch));
    final snap = PeerSnapshot(at: now, connected: connected, banned: banned);
    _last = snap;
    // A second of slack, so a timer firing a little early still samples.
    final due = _history.isEmpty || now.difference(_history.last.at) >= sampleEvery - const Duration(seconds: 1);
    if (due) {
      _history.add(PeerCountSample(now, inbound: snap.inbound, outbound: snap.outbound, maxHeight: snap.maxHeight));
      if (_history.length > historyLimit) _history.removeRange(0, _history.length - historyLimit);
    }
    return snap;
  }

  /// Bans [addr] ("ip:port"). The node drops the connection and refuses the peer until unbanned
  /// (or its ban window passes).
  Future<void> ban(String addr) => _api.banPeer(addr);

  Future<void> unban(String addr) => _api.unbanPeer(addr);

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static int _order(PeerView a, PeerView b) {
    final d = _dirRank(a.peer.direction).compareTo(_dirRank(b.peer.direction));
    if (d != 0) return d;
    final h = b.peer.height.compareTo(a.peer.height);
    return h != 0 ? h : a.addr.compareTo(b.addr);
  }

  static int _dirRank(PeerDirection d) => switch (d) {
    PeerDirection.outbound => 0,
    PeerDirection.inbound => 1,
    PeerDirection.unknown => 2,
  };
}
