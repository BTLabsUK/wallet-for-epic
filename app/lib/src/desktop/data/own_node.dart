/// Owner access to the user's own node (own-node spec §3–§4): the node's `.api_secret`, kept per
/// node URL in the app's secret store (the keyring), unlocks its owner API: the sync stage,
/// the connected peers and Ban / Unban. Nothing else of the owner API is offered.
///
/// The secret goes only to an own node ([NodeClass.own]): never to a public node, never over
/// Tor (a node on this computer, the local network or a VPN is reached directly through the
/// node relay; an own https server is not asked while the Tor switch is on), never on a
/// redirect (the client follows none), never to another host than the row's (the relay looks
/// a `.lan` name up once). It is not in the settings, the wallet data file, the logs or the
/// feedback report.
library;

import 'dart:async';

import '../../log.dart';
import '../../net/local_address.dart';
import '../../net/tor_switch.dart';
import '../../node/node_api.dart';
import '../../node/node_api_types.dart';
import '../../node/peers.dart';
import '../../node/sync_progress.dart';
import '../../secret_store_api.dart';

/// The secret store key of [url]'s owner secret: `node.ownerSecret.<scheme>://<host>:<port>`,
/// the default port written out, so `http://10.0.1.24:3413/` and `http://10.0.1.24:3413`
/// share one.
String ownerSecretKey(String url) {
  final u = Uri.tryParse(url.trim());
  if (u == null || u.host.isEmpty) return 'node.ownerSecret.${url.trim()}';
  return 'node.ownerSecret.${u.scheme}://${u.host.toLowerCase()}:${u.port}';
}

/// Whether an owner secret may be sent to [url] now: an own node only, and an own https server
/// only while the Tor switch is off ([torOn]).
bool ownerSecretMayTravel(String url, {required bool mine, required bool torOn}) {
  final cls = nodeClassOf(url, mine: mine, unlisted: mine);
  if (!cls.own) return false;
  final scheme = Uri.tryParse(url.trim())?.scheme;
  if (cls.local) return scheme == 'http' || scheme == 'https';
  return scheme == 'https' && !torOn;
}

/// Whether the secret travels unencrypted to [url]: plain http on the home network. This
/// computer (loopback) and a VPN (WireGuard carries it) need no warning.
bool ownerSecretPlainOnLan(String url) =>
    Uri.tryParse(url.trim())?.scheme == 'http' && nodeClassOf(url) == NodeClass.homeNetwork;

/// What the one check of an added secret found.
enum OwnerCheck {
  /// The node took it: kept.
  ok,

  /// The node said 401: not kept.
  refused,

  /// The node did not answer: kept, checked again when the panel next asks.
  noAnswer,
}

/// Why owner calls to a node are not made now.
enum OwnerOff {
  /// No secret stored.
  notSet,

  /// The node refused the stored secret (401) at [OwnerRefused.since].
  refused,

  /// An own https server while the Tor switch is on: the secret never goes over Tor.
  torOn,
}

class OwnerUnavailable implements Exception {
  const OwnerUnavailable(this.why, {this.since});

  final OwnerOff why;
  final DateTime? since;

  @override
  String toString() => 'OwnerUnavailable: ${why.name}';
}

/// What the owner API says about an own node (`get_status` with the secret).
class OwnNodeStatus {
  const OwnNodeStatus({required this.at, required this.syncStatus, required this.progress, required this.peers, this.version, this.height});

  final DateTime at;

  /// `no_sync`, `header_sync`, …
  final String syncStatus;

  /// The sync stage and its share, by the built-in node's rules (null at the tip).
  final SyncProgress? progress;
  final int peers;
  final String? version;
  final int? height;

  bool get synced => syncStatus == 'no_sync' && peers > 0;
}

/// Owner access for any own node URL: the secrets, one owner client and one peer service per
/// node. The desktop's [DeskNodeApi] delegates here.
class OwnNodeAccess {
  OwnNodeAccess(
    this._secrets, {
    bool Function()? torOn,
    bool Function(String url)? mine,
    NodeApiClient Function(String url, Future<String?> Function() secret)? clientFor,
    DateTime Function()? clock,
  }) : _torOn = torOn ?? (() => TorSwitch.on),
       _mine = mine ?? ((_) => false),
       _clientFor = clientFor ?? ((url, secret) => NodeApiClient(url, secret: secret)),
       _clock = clock ?? DateTime.now;

  final SecretStore _secrets;
  final bool Function() _torOn;
  final bool Function(String url) _mine;
  final NodeApiClient Function(String url, Future<String?> Function() secret) _clientFor;
  final DateTime Function() _clock;
  final Map<String, PeerService> _peers = {};

  /// When each node first refused its stored secret this session.
  final Map<String, DateTime> _refusedSince = {};

  Future<bool> has(String url) async => (await _read(url))?.isNotEmpty ?? false;

  Future<String?> _read(String url) async {
    try {
      return await _secrets.read(ownerSecretKey(url));
    } on Object catch (e) {
      logWarn('node', 'owner secret not read: ${e.runtimeType}');
      return null;
    }
  }

  /// The secret for a call to [url], or null where it may not travel now.
  Future<String?> _secretFor(String url) async =>
      ownerSecretMayTravel(url, mine: _mine(url), torOn: _torOn()) ? _read(url) : null;

  NodeApiClient _client(String url, [String? only]) => _clientFor(url, () async => only ?? await _secretFor(url));

  /// Checks [secret] with one owner call that needs it (`get_connected_peers`: the node answers
  /// `get_status` without one) and keeps it unless the node refused it.
  Future<OwnerCheck> add(String url, String secret) async {
    final s = secret.trim().split(RegExp(r'\r?\n')).first.trim();
    if (s.isEmpty || !ownerSecretMayTravel(url, mine: _mine(url), torOn: _torOn())) return OwnerCheck.refused;
    var result = OwnerCheck.ok;
    try {
      await _client(url, s).connectedPeers();
    } on NodeRpcException catch (e) {
      if (e.kind == NodeRpcError.unauthorized) return OwnerCheck.refused;
      result = OwnerCheck.noAnswer;
    }
    await _secrets.write(ownerSecretKey(url), s);
    _refusedSince.remove(url);
    _peers.remove(url);
    logInfo('node', 'owner access added for an own node (${nodeClassOf(url, mine: _mine(url)).name}), check ${result.name}');
    return result;
  }

  Future<void> remove(String url) async {
    await _secrets.delete(ownerSecretKey(url));
    _refusedSince.remove(url);
    _peers.remove(url);
  }

  Future<NodeApiClient> _ready(String url) async {
    if (!await has(url)) throw const OwnerUnavailable(OwnerOff.notSet);
    if (!ownerSecretMayTravel(url, mine: _mine(url), torOn: _torOn())) throw const OwnerUnavailable(OwnerOff.torOn);
    return _client(url);
  }

  Future<T> _owner<T>(String url, Future<T> Function(NodeApiClient api) call) async {
    final api = await _ready(url);
    try {
      final r = await call(api);
      _refusedSince.remove(url);
      return r;
    } on NodeRpcException catch (e) {
      if (e.kind != NodeRpcError.unauthorized) rethrow;
      final since = _refusedSince.putIfAbsent(url, _clock);
      throw OwnerUnavailable(OwnerOff.refused, since: since);
    }
  }

  /// `get_status` plus one call that needs the secret, so a rotated secret shows at once.
  Future<OwnNodeStatus> status(String url, {int? networkHeight}) => _owner(url, (api) async {
    final s = await api.status();
    await api.connectedPeers();
    return OwnNodeStatus(
      at: _clock(),
      syncStatus: s.syncStatus,
      progress: s.syncStatus == 'no_sync' ? null : progressOf(s, networkHeight: networkHeight),
      peers: s.connections,
      version: s.version,
      height: s.tip.height,
    );
  });

  PeerService _service(String url) => _peers.putIfAbsent(url, () => PeerService(_client(url)));

  Future<PeerSnapshot> peers(String url) => _owner(url, (_) => _service(url).refresh());

  List<PeerCountSample> peerHistory(String url) => _peers[url]?.history ?? const [];

  Future<void> ban(String url, String addr) => _owner(url, (_) => _service(url).ban(addr));

  Future<void> unban(String url, String addr) => _owner(url, (_) => _service(url).unban(addr));
}
