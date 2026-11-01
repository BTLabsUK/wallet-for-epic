// SPDX-License-Identifier: Apache-2.0
/// Advanced: the expert features a wallet shows and the network mode it runs in. One model for
/// the phone (`AppSettings.advanced`) and the desktop (`DeskSettings.advanced`), so the Advanced
/// page reads the same on both.
///
/// Every feature is off for a new wallet but Linked devices, which is on until the user turns it
/// off (opt-out, still marked Experimental). On, it appears where it belongs (the Outputs page in
/// Settings or the sidebar, the technical rows on a transaction, the strategy fold on Send); the
/// Advanced page only holds the switches and says in one line what each shows.
library;

import 'tor_build.dart';

/// A feature the simple app hides. Each is one switch on the Advanced page.
enum AdvancedFeature {
  /// The Outputs page: the wallet's coins, Split and Consolidate, the send defaults.
  outputs,

  /// Technical rows on transactions and outputs: kernel, slate id, commitments, block height,
  /// the fee breakdown.
  technicalDetails,

  /// Send › strategy (Smallest / All) and Split change for one send.
  sendOptions,

  /// Server details: hosts, latency, version and height in the pickers and status cards.
  serverDetails,

  /// Recheck balance from a height or a date; Delete unconfirmed; restore from a height.
  recheckFromHeight,

  /// The built-in node (desktop): the "This computer" node option, Start node on Overview.
  builtInNode,

  /// Logs and diagnostics: the log folder, Clear logs.
  logs,

  /// Transaction files (phone only): the File switch under Settings › Transactions. The
  /// desktop offers File to everyone and never lists this.
  transactionFiles,

  /// Experimental: pairing (RFC 0002): Pair, paired contacts, trust badges, the pairing
  /// mailboxes. Off, the open wallet's pairing reads as unsupported and nothing collects;
  /// what LEPIC stored stays and comes back.
  pairing,

  /// Experimental: invoices from and to paired contacts. Needs [pairing]
  /// ([AdvancedPrefs.withExperimental] keeps the rule).
  invoices,

  /// Experimental: linked devices (`devices/`): this wallet on two or more devices that tell
  /// each other about their payments. On by default (opt-out): a stored value without it reads
  /// as on, a user who turned it off stays off. Linking itself needs the QR and the check on
  /// both devices, and nothing connects while no device is linked or being linked. Runs the
  /// pairing engine for the devices' private pairings even while [pairing] is off; nothing of
  /// it shows in Contacts or Pairing.
  linkedDevices,
}

/// The features listed in Settings › Advanced › Experimental, not with the others: Hide all
/// leaves them and the count of features on does not include them.
const experimentalFeatures = {AdvancedFeature.pairing, AdvancedFeature.invoices, AdvancedFeature.linkedDevices};

/// Features a stored value may still name that no switch shows any more: pairing is on for
/// everyone, so its old switch value is read and ignored, never migrated or reused.
const retiredFeatures = {AdvancedFeature.pairing};

/// How the wallet reaches the network (Settings › Network & privacy). One choice, kept in the
/// settings file's `[network] mode` (`network_mode_file.dart`); the Privacy page's Tor switch is
/// the user's in [standard] and [nodeOnly], locked on in [torOnly] and off in [killSwitch].
enum NetworkMode {
  /// Normal: connects directly. Tor can be turned on in Privacy.
  standard,

  /// Every connection goes through Tor. Without Tor the wallet stays offline and says so; it
  /// never connects directly.
  torOnly,

  /// Only the node in use (the first of the node list): no Epicbox, no Link, no status site,
  /// price, update checks or any other request of the app's own. QR Payment and File Transfer
  /// work through the node. The node goes over Tor while the Tor switch is on. Stored by
  /// builds before 26.10.25 as `offline`.
  nodeOnly,

  /// Kill switch: no connection at all, the node included; Tor and the built-in node never
  /// start. The balance and history stay as last known; File and QR payments are made, signed
  /// and finalized without a node and posted elsewhere.
  killSwitch,
}

/// The mode stored as [name] (the enum's name, or the settings file's snake case), with the
/// old `offline` read as [NetworkMode.nodeOnly]; null when unknown.
NetworkMode? networkModeNamed(String? name) => switch (name) {
  'standard' || 'normal' => NetworkMode.standard,
  'torOnly' || 'tor_only' => NetworkMode.torOnly,
  'nodeOnly' || 'node_only' || 'offline' => NetworkMode.nodeOnly,
  'killSwitch' || 'kill_switch' => NetworkMode.killSwitch,
  _ => null,
};

/// What the Advanced page holds, as stored.
class AdvancedPrefs {
  const AdvancedPrefs({
    this.features = const {AdvancedFeature.linkedDevices},
    NetworkMode networkMode = NetworkMode.standard,
    this.nodeFailover = true,
  }) : networkMode = !torBuilt && networkMode == NetworkMode.torOnly ? NetworkMode.standard : networkMode;

  final Set<AdvancedFeature> features;
  /// Never [NetworkMode.torOnly] in the build without Tor ([torBuilt]): a stored Tor only reads
  /// as Standard.
  final NetworkMode networkMode;

  /// Node failover (`node_failover.dart`): when the node in use stops answering, the wallet
  /// uses the next working node in the list for this session. On by default; a stored value
  /// from before it existed reads as on.
  final bool nodeFailover;

  /// The defaults: nothing on but Linked devices, standard network, node failover on.
  static const AdvancedPrefs none = AdvancedPrefs();

  /// Every feature on (tests and the screenshot tour), standard network.
  static final AdvancedPrefs all = AdvancedPrefs(features: AdvancedFeature.values.toSet());

  bool has(AdvancedFeature f) => features.contains(f);

  /// Pairing is on for everyone: its Experimental switch is gone, and a stored value is
  /// ignored.
  bool get pairingOn => true;

  /// Invoices are on (Settings › Advanced › Experimental; off by default).
  bool get invoicesOn => has(AdvancedFeature.invoices);

  /// Linked devices are on (Settings › Advanced › Experimental), independent of [pairingOn].
  bool get linkedDevicesOn => has(AdvancedFeature.linkedDevices);

  /// The pairing engine runs: for contacts ([pairingOn]) or for linked devices.
  bool get pairingEngineOn => pairingOn || linkedDevicesOn;

  /// The features on outside [experimentalFeatures]: what the Advanced page counts and Hide
  /// all turns off.
  Set<AdvancedFeature> get shownFeatures => features.difference(experimentalFeatures);

  /// [withFeature] with the experimental rule: Invoices on turns Pairing on, Pairing off
  /// turns Invoices off.
  AdvancedPrefs withExperimental(AdvancedFeature f, bool on) {
    var next = withFeature(f, on);
    return next;
  }

  /// Hide all: every feature off but the experimental ones.
  AdvancedPrefs withoutShown() => AdvancedPrefs(
    features: features.intersection(experimentalFeatures),
    networkMode: networkMode,
    nodeFailover: nodeFailover,
  );

  /// Whether anything is on beyond the simple app: the hub's state line and the About row
  /// read it. Node failover is on by default, so only its being off counts.
  /// Linked devices is on by default, so only its being off counts.
  bool get any =>
      features.any((f) => f != AdvancedFeature.linkedDevices) || !linkedDevicesOn || networkMode != NetworkMode.standard || !nodeFailover;

  /// Tor is wanted at launch ([NetworkMode.torOnly]).
  bool get startsWithTor => networkMode == NetworkMode.torOnly;

  AdvancedPrefs withFeature(AdvancedFeature f, bool on) => AdvancedPrefs(
    features: on ? {...features, f} : features.where((x) => x != f).toSet(),
    networkMode: networkMode,
    nodeFailover: nodeFailover,
  );

  AdvancedPrefs withMode(NetworkMode mode) =>
      AdvancedPrefs(features: features, networkMode: mode, nodeFailover: nodeFailover);

  AdvancedPrefs withNodeFailover(bool on) =>
      AdvancedPrefs(features: features, networkMode: networkMode, nodeFailover: on);

  /// `outputs,sendOptions|torOnly`, with `|noFailover` when node failover is off and
  /// `|noLinkedDevices` when Linked devices is off (on by default, so never listed): one string
  /// for a key-value store. Without [mode] the mode is written as Normal: the store keeps no
  /// mode since 26.10.25 (settings.toml does, `network_mode_file.dart`).
  String encode({bool mode = true}) =>
      '${(features.where((f) => f != AdvancedFeature.linkedDevices).map((f) => f.name).toList()..sort()).join(',')}|${(mode ? networkMode : NetworkMode.standard).name}'
      '${nodeFailover ? '' : '|noFailover'}${linkedDevicesOn ? '' : '|noLinkedDevices'}';

  /// Unknown names are dropped, so a build without a feature still opens its settings.
  static AdvancedPrefs decode(String? raw) {
    if (raw == null || raw.isEmpty) return none;
    final parts = raw.split('|');
    final features = <AdvancedFeature>{
      for (final n in parts.first.split(','))
        for (final f in AdvancedFeature.values)
          if (f.name == n) f,
    };
    final mode = parts.length > 1 ? networkModeNamed(parts[1]) ?? NetworkMode.standard : NetworkMode.standard;
    return AdvancedPrefs(
      features: {...features, if (!parts.skip(2).contains('noLinkedDevices')) AdvancedFeature.linkedDevices},
      networkMode: mode,
      nodeFailover: !parts.skip(2).contains('noFailover'),
    );
  }

  /// Without [mode] no `networkMode` (the desktop's store: settings.toml keeps the mode).
  Map<String, Object?> toJson({bool mode = true}) => {
    'features': (features.where((f) => f != AdvancedFeature.linkedDevices).map((f) => f.name).toList()..sort()),
    if (mode) 'networkMode': networkMode.name,
    'nodeFailover': nodeFailover,
    'linkedDevices': linkedDevicesOn,
  };

  static AdvancedPrefs fromJson(Object? j) {
    if (j is! Map) return none;
    final list = j['features'];
    final mode = j['networkMode'];
    return AdvancedPrefs(
      features: {
        if (list is List)
          for (final n in list)
            for (final f in AdvancedFeature.values)
              if (f.name == n && f != AdvancedFeature.linkedDevices) f,
        // On unless the user turned it off.
        if (j['linkedDevices'] != false) AdvancedFeature.linkedDevices,
      },
      networkMode: networkModeNamed(mode is String ? mode : null) ?? NetworkMode.standard,
      nodeFailover: j['nodeFailover'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdvancedPrefs &&
      other.networkMode == networkMode &&
      other.nodeFailover == nodeFailover &&
      other.features.length == features.length &&
      other.features.containsAll(features);

  @override
  int get hashCode =>
      Object.hash(networkMode, nodeFailover, Object.hashAllUnordered(features));
}

extension NetworkModeRestricted on NetworkMode {
  /// Nothing but the node in use ([NetworkMode.nodeOnly]) or nothing at all
  /// ([NetworkMode.killSwitch]) reaches the network.
  bool get restricted => this == NetworkMode.nodeOnly || this == NetworkMode.killSwitch;
}
