import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../network.dart';
import '../providers.dart';
import 'common.dart';
import 'create_screen.dart';
import 'restore_screen.dart';
import 'unlock_screen.dart';

/// First screen: pick the network and node, then continue to unlock or to wallet creation.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  NetworkPreset _preset = mainnetPreset;
  final _nodeUrl = TextEditingController(text: mainnetPreset.nodeUrl);
  String? _urlError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _nodeUrl.dispose();
    super.dispose();
  }

  void _selectPreset(NetworkPreset preset) {
    setState(() {
      _preset = preset;
      _nodeUrl.text = preset.nodeUrl;
      _urlError = null;
      _error = null;
    });
  }

  static bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _continue() async {
    final url = _nodeUrl.text.trim();
    if (!_isValidUrl(url)) {
      setState(
        () => _urlError = 'Enter a full URL such as https://node.example.com',
      );
      return;
    }
    setState(() {
      _busy = true;
      _urlError = null;
      _error = null;
    });
    // A wallet left open (e.g. after backing out of a restore) would pin its chain.
    ref.read(sessionProvider.notifier).lock();
    try {
      final dataDir = await ref.read(walletDirProvider)(_preset.chain);
      final config = _preset.config(dataDir: dataDir, nodeUrl: url);
      final exists = await ref
          .read(walletServiceProvider)
          .walletExists(config: config);
      ref.read(walletConfigProvider.notifier).select(config);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              exists ? const UnlockScreen() : const NewWalletScreen(),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Epic Cash Wallet')),
      body: ScreenBody(
        children: [
          Text('Network', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<NetworkPreset>(
            segments: [
              for (final preset in networkPresets)
                ButtonSegment(value: preset, label: Text(preset.label)),
            ],
            selected: {_preset},
            onSelectionChanged: (selection) => _selectPreset(selection.first),
          ),
          const SizedBox(height: 8),
          Text(_preset.description),
          const SizedBox(height: 24),
          TextField(
            controller: _nodeUrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Node URL',
              errorText: _urlError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Epicbox relay: ${_preset.epicboxDomain}:${_preset.epicboxPort}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (_error != null) ErrorText(_error!),
          BusyButton(label: 'Continue', busy: _busy, onPressed: _continue),
        ],
      ),
    );
  }
}

/// Shown when the chosen network has no wallet yet.
class NewWalletScreen extends ConsumerWidget {
  const NewWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(walletConfigProvider);
    final network = config == null ? '' : ' on ${chainLabel(config.chain)}';
    return Scaffold(
      appBar: AppBar(title: const Text('New wallet')),
      body: ScreenBody(
        children: [
          Text(
            'There is no wallet$network on this device yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create a new wallet'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CreateScreen()),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.restore),
            label: const Text('Restore from recovery phrase'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RestoreScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
