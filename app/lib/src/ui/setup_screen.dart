import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../network.dart';
import '../providers.dart';
import 'common.dart';
import 'launch_screen.dart';

/// Network and node settings. Saving restarts the app flow on the chosen network.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  NetworkPreset? _preset;
  final _nodeUrl = TextEditingController();
  String? _urlError;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final choice = await ref.read(networkChoiceProvider.future);
      if (!mounted) return;
      setState(() {
        _preset = choice.preset;
        _nodeUrl.text = choice.nodeUrl;
      });
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    }
  }

  @override
  void dispose() {
    _nodeUrl.dispose();
    super.dispose();
  }

  Future<void> _selectPreset(NetworkPreset preset) async {
    setState(() {
      _preset = preset;
      _urlError = null;
      _error = null;
    });
    final url = await ref
        .read(networkChoiceProvider.notifier)
        .nodeUrlFor(preset);
    if (mounted && _preset == preset) setState(() => _nodeUrl.text = url);
  }

  static bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _save() async {
    final preset = _preset;
    if (preset == null) return;
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
    try {
      await ref.read(networkChoiceProvider.notifier).save(preset, url);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = _preset;
    return Scaffold(
      appBar: AppBar(title: const Text('Network settings')),
      body: ScreenBody(
        children: preset == null
            ? [
                if (_error != null)
                  ErrorText(_error!)
                else
                  const LinearProgressIndicator(),
              ]
            : [
                Text('Network', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<NetworkPreset>(
                  segments: [
                    for (final p in networkPresets)
                      ButtonSegment(value: p, label: Text(p.label)),
                  ],
                  selected: {preset},
                  onSelectionChanged: (selection) =>
                      _selectPreset(selection.first),
                ),
                const SizedBox(height: 8),
                Text(preset.description),
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
                  'Epicbox relay: ${preset.epicboxDomain}:${preset.epicboxPort}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Each network has its own wallet. A network without one gets '
                  'a new wallet.',
                ),
                const SizedBox(height: 24),
                if (_error != null) ErrorText(_error!),
                BusyButton(label: 'Save', busy: _busy, onPressed: _save),
              ],
      ),
    );
  }
}
