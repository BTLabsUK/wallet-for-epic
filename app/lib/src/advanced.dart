/// Advanced: the expert features a wallet shows and the network mode it runs in. One model for
/// the phone (`AppSettings.advanced`) and the desktop (`DeskSettings.advanced`), so the Advanced
/// page reads the same on both.
///
/// Every feature is off for a new wallet. On, it appears where it belongs (the Outputs page in
/// Settings or the sidebar, the technical rows on a transaction, the strategy fold on Send); the
/// Advanced page only holds the switches and says in one line what each shows.
library;

/// A feature the simple app hides. Each is one switch on the Advanced page.
enum AdvancedFeature {
  /// The Outputs page: the wallet's coins, Split and Consolidate, the send defaults.
  outputs,

  /// Technical rows on transactions and outputs: kernel, slate id, commitments, block height,
  /// the fee breakdown, payment proofs.
  technicalDetails,

  /// Send › strategy (Smallest / All) and Split change for one send.
  sendOptions,

  /// Direct receiving: HTTP and Tor addresses, the listener settings, the Direct method on Send.
  directReceiving,

  /// Server details: hosts, latency, version and height in the pickers and status cards.
  serverDetails,

  /// Recheck balance from a height or a date; Delete unconfirmed; restore from a height.
  recheckFromHeight,

  /// The built-in node (desktop): the "This computer" node option, Start node on Overview.
  builtInNode,

  /// Logs and diagnostics: the log folder, Clear logs, the node debug screen.
  logs,
}

/// How the wallet reaches the network. One choice; the Privacy page's Tor switch is the user's
/// in [standard], locked on in [torOnly] and off in [offline].
enum NetworkMode {
  /// Connects directly. Tor can be turned on in Privacy for this session.
  standard,

  /// Every connection goes through Tor. Without Tor the wallet stays offline and says so; it
  /// never connects directly.
  torOnly,

  /// No network at all: the balance stays as last seen, nothing is sent or received; the
  /// transaction file method still works for cold use.
  offline,
}

/// What the Advanced page holds, as stored.
class AdvancedPrefs {
  const AdvancedPrefs({
    this.features = const {},
    this.networkMode = NetworkMode.standard,
  });

  final Set<AdvancedFeature> features;
  final NetworkMode networkMode;

  /// The defaults: nothing on, standard network.
  static const AdvancedPrefs none = AdvancedPrefs();

  /// Every feature on (tests and the screenshot tour), standard network.
  static final AdvancedPrefs all = AdvancedPrefs(features: AdvancedFeature.values.toSet());

  bool has(AdvancedFeature f) => features.contains(f);

  /// Whether anything is on: the hub's state line and the About row read it.
  bool get any => features.isNotEmpty || networkMode != NetworkMode.standard;

  /// Tor is wanted at launch ([NetworkMode.torOnly]).
  bool get startsWithTor => networkMode == NetworkMode.torOnly;

  /// Direct connections are refused ([NetworkMode.torOnly]) or there is no network at all.
  bool get refusesDirect =>
      networkMode == NetworkMode.torOnly || networkMode == NetworkMode.offline;

  AdvancedPrefs withFeature(AdvancedFeature f, bool on) => AdvancedPrefs(
    features: on ? {...features, f} : features.where((x) => x != f).toSet(),
    networkMode: networkMode,
  );

  AdvancedPrefs withMode(NetworkMode mode) =>
      AdvancedPrefs(features: features, networkMode: mode);

  /// `outputs,sendOptions|torOnly`: one string for a key-value store.
  String encode() =>
      '${(features.map((f) => f.name).toList()..sort()).join(',')}|${networkMode.name}';

  /// Unknown names are dropped, so a build without a feature still opens its settings.
  static AdvancedPrefs decode(String? raw) {
    if (raw == null || raw.isEmpty) return none;
    final parts = raw.split('|');
    final features = <AdvancedFeature>{
      for (final n in parts.first.split(','))
        for (final f in AdvancedFeature.values)
          if (f.name == n) f,
    };
    final mode = parts.length > 1
        ? NetworkMode.values.where((m) => m.name == parts[1]).firstOrNull ??
              NetworkMode.standard
        : NetworkMode.standard;
    return AdvancedPrefs(features: features, networkMode: mode);
  }

  Map<String, Object?> toJson() => {
    'features': (features.map((f) => f.name).toList()..sort()),
    'networkMode': networkMode.name,
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
              if (f.name == n) f,
      },
      networkMode:
          NetworkMode.values.where((m) => m.name == mode).firstOrNull ??
          NetworkMode.standard,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdvancedPrefs &&
      other.networkMode == networkMode &&
      other.features.length == features.length &&
      other.features.containsAll(features);

  @override
  int get hashCode =>
      Object.hash(networkMode, Object.hashAllUnordered(features));
}
