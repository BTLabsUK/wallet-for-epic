import 'wallet_service.dart';

/// A chain with the node and epicbox relay the wallet uses by default.
class NetworkPreset {
  const NetworkPreset({
    required this.chain,
    required this.label,
    required this.description,
    required this.nodeUrl,
    required this.epicboxDomain,
    required this.epicboxPort,
  });

  final Chain chain;
  final String label;
  final String description;
  final String nodeUrl;
  final String epicboxDomain;
  final int epicboxPort;

  WalletConfig config({required String dataDir, required String nodeUrl}) =>
      WalletConfig(
        dataDir: dataDir,
        chain: chain,
        nodeUrl: nodeUrl,
        epicboxDomain: epicboxDomain,
        epicboxPort: epicboxPort,
      );
}

const NetworkPreset mainnetPreset = NetworkPreset(
  chain: Chain.mainnet,
  label: 'Mainnet',
  description: 'Real EPIC.',
  nodeUrl: 'https://node.btlabs.uk',
  epicboxDomain: 'epicbox.epiccash.com',
  epicboxPort: 443,
);

const NetworkPreset floonetPreset = NetworkPreset(
  chain: Chain.floonet,
  label: 'Floonet',
  description:
      'Public test network. Coins are worthless; get some from '
      'floo-explorer.btlabs.uk.',
  nodeUrl: 'https://floo-node.btlabs.uk',
  epicboxDomain: 'flooepicbox.btlabs.uk',
  epicboxPort: 443,
);

const NetworkPreset usernetPreset = NetworkPreset(
  chain: Chain.usernet,
  label: 'Usernet',
  description: 'Local development network on this machine.',
  nodeUrl: 'http://127.0.0.1:23413',
  epicboxDomain: '127.0.0.1',
  epicboxPort: 3423,
);

const List<NetworkPreset> networkPresets = [
  mainnetPreset,
  floonetPreset,
  usernetPreset,
];

/// Human name of a chain for titles.
String chainLabel(Chain chain) => switch (chain) {
  Chain.mainnet => 'Mainnet',
  Chain.floonet => 'Floonet',
  Chain.usernet => 'Usernet',
};
