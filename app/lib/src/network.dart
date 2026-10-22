import 'wallet_service.dart';

/// A chain with the node and epicbox relay the wallet uses by default.
class NetworkPreset {
  const NetworkPreset({
    required this.chain,
    required this.nodeUrl,
    required this.epicboxDomain,
    required this.epicboxPort,
  });

  /// Its name and description on screen: `chainName` and `chainDescription` in l10n.dart.
  final Chain chain;
  final String nodeUrl;
  final String epicboxDomain;
  final int epicboxPort;

  /// The default relay of this network.
  EpicboxRelay get defaultRelay =>
      EpicboxRelay(host: epicboxDomain, port: epicboxPort);

  /// `status.btlabs.uk` lists relays for these chains; usernet is local only.
  String? get statusChain => switch (chain) {
    Chain.mainnet => 'mainnet',
    Chain.floonet => 'floonet',
    Chain.usernet => null,
  };

  WalletConfig config({
    required String dataDir,
    required String nodeUrl,
    EpicboxRelay? relay,
    String? walletId,
  }) {
    final r = relay ?? defaultRelay;
    return WalletConfig(
      dataDir: dataDir,
      chain: chain,
      nodeUrl: nodeUrl,
      epicboxDomain: r.host,
      epicboxPort: r.port,
      walletId: walletId,
    );
  }
}

/// An epicbox relay by host and port. The host is part of the wallet's address.
class EpicboxRelay {
  const EpicboxRelay({required this.host, this.port = 443});

  final String host;
  final int port;

  /// `host` for port 443, otherwise `host:port`, as addresses write it.
  String get label => port == 443 ? host : '$host:$port';

  /// Parses `host` or `host:port`.
  static EpicboxRelay? parse(String text) {
    final t = text.trim();
    final match = RegExp(r'^([a-zA-Z0-9.-]+)(?::(\d{1,5}))?$').firstMatch(t);
    if (match == null) return null;
    final port = int.tryParse(match.group(2) ?? '443') ?? 0;
    if (port < 1 || port > 65535) return null;
    return EpicboxRelay(host: match.group(1)!.toLowerCase(), port: port);
  }

  @override
  bool operator ==(Object other) =>
      other is EpicboxRelay && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}

const NetworkPreset mainnetPreset = NetworkPreset(
  chain: Chain.mainnet,
  nodeUrl: 'https://node.btlabs.uk',
  epicboxDomain: 'epicbox.epiccash.com',
  epicboxPort: 443,
);

const NetworkPreset floonetPreset = NetworkPreset(
  chain: Chain.floonet,
  nodeUrl: 'https://floo-node.btlabs.uk',
  epicboxDomain: 'flooepicbox.btlabs.uk',
  epicboxPort: 443,
);

const NetworkPreset usernetPreset = NetworkPreset(
  chain: Chain.usernet,
  nodeUrl: 'http://127.0.0.1:23413',
  epicboxDomain: '127.0.0.1',
  epicboxPort: 3423,
);

const List<NetworkPreset> networkPresets = [
  mainnetPreset,
  floonetPreset,
  usernetPreset,
];

/// The fixed English name of a chain, for logs and the feedback report. The screen uses
/// `chainName` in l10n.dart.
String chainLabel(Chain chain) => switch (chain) {
  Chain.mainnet => 'Mainnet',
  Chain.floonet => 'Floonet',
  Chain.usernet => 'Usernet',
};
