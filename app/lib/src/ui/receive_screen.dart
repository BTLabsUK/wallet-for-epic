import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';

/// Manual slate receive: sign an incoming slate and hand the response back.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: ScreenBody(
        children: [
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
