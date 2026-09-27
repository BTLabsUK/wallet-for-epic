import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../network.dart';
import '../providers.dart';
import '../relay_directory.dart';
import 'common.dart';
import 'launch_screen.dart';

/// Network, node and relay settings. Saving restarts the app flow on the chosen network.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  NetworkPreset? _preset;
  EpicboxRelay? _relay;

  /// The relay saved when the screen opened, so a change can be flagged.
  EpicboxRelay? _savedRelay;
  final _nodeUrl = TextEditingController();
  final _customRelay = TextEditingController();
  String? _urlError;
  String? _relayError;
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
        _relay = choice.relay;
        _savedRelay = choice.relay;
        _nodeUrl.text = choice.nodeUrl;
      });
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    }
  }

  @override
  void dispose() {
    _nodeUrl.dispose();
    _customRelay.dispose();
    super.dispose();
  }

  Future<void> _selectPreset(NetworkPreset preset) async {
    setState(() {
      _preset = preset;
      _urlError = null;
      _relayError = null;
      _error = null;
    });
    final notifier = ref.read(networkChoiceProvider.notifier);
    final url = await notifier.nodeUrlFor(preset);
    final relay = await notifier.relayFor(preset);
    if (mounted && _preset == preset) {
      setState(() {
        _nodeUrl.text = url;
        _relay = relay;
        _savedRelay = relay;
      });
    }
  }

  static bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _useCustomRelay() {
    final relay = EpicboxRelay.parse(_customRelay.text);
    setState(() {
      _relayError = relay == null
          ? 'Enter a host such as epicbox.example.com'
          : null;
      if (relay != null) {
        _relay = relay;
        _customRelay.clear();
      }
    });
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
      await ref
          .read(networkChoiceProvider.notifier)
          .save(preset, url, relay: _relay);
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
                const SizedBox(height: 24),
                Text('Epicbox relay', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _RelayPicker(
                  preset: preset,
                  selected: _relay ?? preset.defaultRelay,
                  onSelected: (relay) => setState(() => _relay = relay),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customRelay,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _useCustomRelay(),
                  decoration: InputDecoration(
                    labelText: 'Other relay (host or host:port)',
                    errorText: _relayError,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Use this relay',
                      icon: const Icon(Icons.check),
                      onPressed: _useCustomRelay,
                    ),
                  ),
                ),
                if (_relay != null && _relay != _savedRelay) ...[
                  const SizedBox(height: 8),
                  const ErrorText(
                    'Changing the relay changes your epicbox address. Give '
                    'senders the new address. Payments sent to the old one '
                    'wait on the old relay until you switch back.',
                  ),
                ],
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

/// The relays `status.btlabs.uk` knows for this network, with their health, plus the selected
/// relay if the monitor does not list it.
class _RelayPicker extends ConsumerWidget {
  const _RelayPicker({
    required this.preset,
    required this.selected,
    required this.onSelected,
  });

  final NetworkPreset preset;
  final EpicboxRelay selected;
  final ValueChanged<EpicboxRelay> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(relayStatusProvider(preset));
    final listed = status.value ?? const <RelayStatus>[];
    final entries = [
      ...listed,
      if (!listed.any((s) => s.relay == selected))
        RelayStatus(relay: selected, healthy: false, verified: false),
    ];
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<EpicboxRelay>(
          groupValue: selected,
          onChanged: (relay) {
            if (relay != null) onSelected(relay);
          },
          child: Column(
            children: [
              for (final s in entries)
                RadioListTile<EpicboxRelay>(
                  contentPadding: EdgeInsets.zero,
                  value: s.relay,
                  title: Text(s.relay.label),
                  subtitle: Text(_describe(s, listed.contains(s))),
                  secondary: listed.contains(s)
                      ? Icon(
                          s.healthy ? Icons.check_circle : Icons.error_outline,
                          color: s.healthy
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                          semanticLabel: s.healthy ? 'Healthy' : 'Down',
                        )
                      : null,
                ),
            ],
          ),
        ),
        switch (status) {
          AsyncLoading() => const LinearProgressIndicator(),
          AsyncError() => Text(
            'Relay health unavailable from status.btlabs.uk.',
            style: small,
          ),
          _ when preset.statusChain != null => Text(
            'Health from status.btlabs.uk, measured from its server.',
            style: small,
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  static String _describe(RelayStatus s, bool listed) {
    if (!listed) return 'Not monitored';
    final parts = [
      s.healthy ? 'Up' : 'Down',
      if (s.operator != null) s.operator!,
      if (s.verified) 'official',
      if (s.uptime24h != null)
        '${(s.uptime24h! * 100).toStringAsFixed(1)}% 24h',
    ];
    return parts.join(' · ');
  }
}
