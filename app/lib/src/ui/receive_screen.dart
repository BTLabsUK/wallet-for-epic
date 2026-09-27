import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';

/// Receiving: epicbox payments arrive by themselves through the listener; a manual slate can
/// still be signed here. There is no HTTP receive, because a phone cannot accept connections.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _incoming = TextEditingController();
  Slate? _response;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _incoming.dispose();
    super.dispose();
  }

  Future<void> _sign() async {
    final json = _incoming.text.trim();
    final session = ref.read(sessionProvider);
    if (session == null) return;
    if (json.isEmpty) {
      setState(() => _error = 'Paste the slate you received.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await session.receiveSlate(slateJson: json);
      if (mounted) setState(() => _response = response);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    _incoming.clear();
    setState(() {
      _response = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final response = _response;
    final address = ref.watch(addressProvider);
    final listener = ref.watch(listenerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: ScreenBody(
        children: [
          Text('Over epicbox', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Give the sender this address. Payments arrive by themselves '
            'while this wallet is open.',
          ),
          const SizedBox(height: 8),
          switch (address) {
            AsyncData(:final value) => Card(
              child: ListTile(
                title: SelectableText(value),
                trailing: IconButton(
                  tooltip: 'Copy address',
                  icon: const Icon(Icons.copy),
                  onPressed: () => copyText(context, value, 'Address'),
                ),
              ),
            ),
            AsyncError(:final error) => ErrorText(describeError(error)),
            _ => const LinearProgressIndicator(),
          },
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(
                  listener.connected ? Icons.wifi_tethering : Icons.sync,
                  size: 18,
                  semanticLabel: listener.connected ? 'Connected' : 'Waiting',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    listener.connected
                        ? 'Listening on the relay.'
                        : listener.status ?? 'Connecting to the relay…',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('By slate', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Paste the slate the sender gave you, then return the response '
            'slate to them so they can finalize the transaction.',
          ),
          const SizedBox(height: 16),
          if (response == null) ...[
            SlateInput(controller: _incoming, label: 'Incoming slate'),
            const SizedBox(height: 16),
            if (_error != null) ErrorText(_error!),
            BusyButton(label: 'Sign slate', busy: _busy, onPressed: _sign),
          ] else ...[
            SlateBox(
              title: 'Return this response to the sender',
              json: response.json,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _reset,
              child: const Text('Receive another slate'),
            ),
          ],
        ],
      ),
    );
  }
}
