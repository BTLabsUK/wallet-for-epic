// SPDX-License-Identifier: Apache-2.0
import 'network_gate.dart' show NetGate;
import 'settings_file/host_settings.dart';
import 'wallet_service.dart';

/// A chain with the node and Epicbox server the wallet uses there. The addresses come from the
/// settings file (`docs/settings-file.md`) of the chain the app runs on: mainnet's
/// `settings.toml`, a hidden dev chain's own (`<data>/dev/<chain>/settings.toml`). One chain's
/// settings are open at a time; a chain switch opens the other chain's file first.
class NetworkPreset {
  const NetworkPreset({required this.chain});

  /// Its name and description on screen: `chainName` and `chainDescription` in l10n.dart.
  final Chain chain;

  /// The node every wallet uses (`node.use`).
  String get nodeUrl => hostSettings.nodeUse;

  /// The Epicbox server every wallet's address names (`epicbox.use`).
  EpicboxRelay get defaultRelay => EpicboxRelay.parse(hostSettings.epicboxUse) ?? EpicboxRelay(host: hostSettings.epicboxUse);

  String get epicboxDomain => defaultRelay.host;
  int get epicboxPort => defaultRelay.port;

  /// The status site lists servers for these chains; usernet is local only.
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
      // Kill switch: every session opened meanwhile is an offline one.
      offline: NetGate.killSwitch,
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

/// The server of an Epicbox address written without one (`epicbox.default`).
String get defaultEpicboxHost => hostSettings.epicboxDefault;

const NetworkPreset mainnetPreset = NetworkPreset(chain: Chain.mainnet);

const NetworkPreset floonetPreset = NetworkPreset(chain: Chain.floonet);

const NetworkPreset usernetPreset = NetworkPreset(chain: Chain.usernet);

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

/// The preset of [chain].
NetworkPreset presetOf(Chain chain) => networkPresets.firstWhere((p) => p.chain == chain);

/// The hidden dev chain whose own settings file a run opens: null for mainnet, which every
/// release build runs on.
String? devChainOf(Chain chain) => chain == Chain.mainnet ? null : chain.name;
