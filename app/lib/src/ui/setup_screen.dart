import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../network.dart';
import '../providers.dart';
import '../server_switch.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'launch_screen.dart';
import 'server_picker.dart';

/// Network, node and relay settings. Saving another node or relay of the open wallet's network
/// switches it live, keeping it unlocked; saving another network restarts the app flow on it.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  NetworkPreset? _preset;
  EpicboxRelay? _relay;

  /// The network saved when the screen opened; only another one restarts the app flow.
  NetworkPreset? _savedPreset;

  /// The relay saved when the screen opened, so a change can be flagged.
  EpicboxRelay? _savedRelay;

  /// The node saved when the screen opened (the list marks it Current).
  String? _savedNodeUrl;
  final _nodeUrl = TextEditingController();
  final _customRelay = TextEditingController();
  String? _urlError;
  String? _relayError;
  String? _error;
  bool _busy = false;
  bool _testing = false;

  /// The result of the last connection test, and whether it succeeded.
  ({String text, bool ok})? _test;

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
        _savedPreset = choice.preset;
        _relay = choice.relay;
        _savedRelay = choice.relay;
        _savedNodeUrl = choice.nodeUrl;
        _nodeUrl.text = choice.nodeUrl;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = describeError(context.l10n, error));
      }
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
        _savedNodeUrl = url;
        _test = null;
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
      _relayError = relay == null ? context.l10n.setupCustomRelayInvalid : null;
      if (relay != null) {
        _relay = relay;
        _customRelay.clear();
      }
    });
  }

  Future<void> _testConnection() async {
    final preset = _preset;
    if (preset == null) return;
    final l = context.l10n;
    final url = _nodeUrl.text.trim();
    if (!_isValidUrl(url)) {
      setState(() => _urlError = l.setupNodeUrlInvalid);
      return;
    }
    setState(() {
      _testing = true;
      _urlError = null;
      _test = null;
    });
    ({String text, bool ok}) result;
    try {
      // The node call needs no wallet, so no data directory.
      final tip = await askNodeTip(
        ref.read(walletServiceProvider),
        ref.read(sessionProvider),
        preset.config(dataDir: '', nodeUrl: url),
      );
      result = (
        text: l.setupTestConnected(groupDigits(l, tip.height), tip.nodeVersion),
        ok: true,
      );
    } catch (error) {
      result = (text: l.setupTestFailed(describeError(l, error)), ok: false);
    }
    if (!mounted) return;
    final current = _nodeUrl.text.trim() == url && _preset == preset;
    setState(() {
      _testing = false;
      if (current) _test = result;
    });
  }

  Future<void> _save() async {
    final preset = _preset;
    if (preset == null) return;
    final l = context.l10n;
    final url = _nodeUrl.text.trim();
    if (!_isValidUrl(url)) {
      setState(() => _urlError = l.setupNodeUrlInvalid);
      return;
    }
    final relay = _relay ?? preset.defaultRelay;
    final live = preset == _savedPreset && ref.read(sessionProvider) != null;
    final saved = _savedRelay;
    if (live &&
        saved != null &&
        !await confirmRelaySwitch(context, from: saved, to: relay)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = true;
      _urlError = null;
      _error = null;
    });
    try {
      if (live && await switchServersLive(ref, nodeUrl: url, relay: relay)) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (!live) {
        await ref
            .read(networkChoiceProvider.notifier)
            .save(preset, url, relay: _relay);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(l, error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final preset = _preset;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.setupTitle)),
      body: ScreenBody(
        bottom: preset == null
            ? null
            : BusyButton(label: l.commonSave, busy: _busy, onPressed: _save),
        children: preset == null
            ? [
                if (_error != null)
                  ErrorText(_error!)
                else
                  const LinearProgressIndicator(),
              ]
            : [
                Text(l.setupNetworkHeading, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<NetworkPreset>(
                  segments: [
                    for (final p in networkPresets)
                      // Usernet is a local test network for developers.
                      if (p.chain != Chain.usernet ||
                          !kReleaseMode ||
                          p == preset)
                        ButtonSegment(
                          value: p,
                          label: Text(chainName(l, p.chain)),
                        ),
                  ],
                  selected: {preset},
                  onSelectionChanged: (selection) =>
                      _selectPreset(selection.first),
                ),
                const SizedBox(height: 8),
                Text(chainDescription(l, preset.chain)),
                const SizedBox(height: 16),
                ServerList(
                  kind: ServerKind.node,
                  preset: preset,
                  current: _savedNodeUrl,
                  selected: _nodeUrl.text.trim(),
                  onSelected: (url) => setState(() {
                    _nodeUrl.text = url;
                    _urlError = null;
                    _test = null;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nodeUrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: l.setupNodeUrlLabel,
                    errorText: _urlError,
                    border: const OutlineInputBorder(),
                  ),
                  // The list above follows the field's address.
                  onChanged: (_) => setState(() => _test = null),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: _testing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: Text(l.setupTestConnection),
                    onPressed: _testing || _busy ? null : _testConnection,
                  ),
                ),
                if (_test case final test?)
                  if (test.ok)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              semanticLabel: l.setupConnectedIconLabel,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(test.text)),
                          ],
                        ),
                      ),
                    )
                  else
                    ErrorText(test.text),
                const SizedBox(height: 24),
                Text(l.setupRelayHeading, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l.setupRelayHint),
                const SizedBox(height: 8),
                ServerList(
                  kind: ServerKind.relay,
                  preset: preset,
                  current: _savedRelay?.label,
                  selected: (_relay ?? preset.defaultRelay).label,
                  onSelected: (label) => setState(
                    () => _relay = EpicboxRelay.parse(label) ?? _relay,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customRelay,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => _useCustomRelay(),
                  // The use button appears with text, so an empty field does not look confirmed.
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l.setupCustomRelayLabel,
                    errorText: _relayError,
                    border: const OutlineInputBorder(),
                    suffixIcon: _customRelay.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: l.setupCustomRelayUse,
                            icon: const Icon(Icons.check),
                            onPressed: _useCustomRelay,
                          ),
                  ),
                ),
                if (_relay != null && _relay != _savedRelay) ...[
                  const SizedBox(height: 8),
                  ErrorText(l.setupRelayChangeWarning),
                ],
                const SizedBox(height: 8),
                Text(l.setupWalletPerNetwork),
                const SizedBox(height: 24),
                if (_error != null) ErrorText(_error!),
              ],
      ),
    );
  }
}
