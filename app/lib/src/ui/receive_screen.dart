import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../errors.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'help_screen.dart';
import 'slate_file_screen.dart';

/// Receiving: mailbox (epicbox) payments arrive by themselves while connected; a transaction
/// file or text can still be accepted by hand. There is no HTTP receive, because a phone cannot
/// accept connections.
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
    if (_busy) return;
    final json = _incoming.text.trim();
    final session = ref.read(sessionProvider);
    if (session == null) return;
    if (json.isEmpty) {
      setState(() => _error = 'Paste the transaction text you received.');
      return;
    }
    // Captured now: after the await the screen may be gone, and home must still refresh.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await session.receiveSlate(slateJson: json);
      container.invalidate(homeProvider);
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
    final address = ref.watch(addressProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => openHelp(context, HelpTopic.receiving),
          ),
        ],
      ),
      body: ScreenBody(
        children: [
          switch (address) {
            AsyncData(:final value) => _AddressCard(address: value),
            AsyncError(:final error) => ErrorText(describeError(error)),
            _ => const LinearProgressIndicator(),
          },
          const SizedBox(height: 16),
          _ListenerLine(relay: address.value?.split('@').last),
          const SizedBox(height: 24),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Receive a transaction file'),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            children: _fileSection(),
          ),
        ],
      ),
    );
  }

  List<Widget> _fileSection() {
    final response = _response;
    return [
      const Text(
        'For senders who use files instead of the mailbox. Open the .tx file the '
        'sender gave you. The wallet accepts it and makes a .response file to '
        'send back.',
      ),
      const SizedBox(height: 16),
      BusyButton(
        label: 'Open transaction file',
        onPressed: () => openSlateFile(context, ref),
      ),
      const SizedBox(height: 8),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Paste the transaction text instead'),
        children: [
          if (response == null) ...[
            SlateInput(controller: _incoming, label: 'Transaction text'),
            const SizedBox(height: 16),
            if (_error != null) ErrorText(_error!),
            BusyButton(label: 'Accept payment', busy: _busy, onPressed: _sign),
          ] else ...[
            SlateBox(
              title: 'Return this response to the sender',
              json: response.json,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _reset,
              child: const Text('Receive another payment'),
            ),
          ],
        ],
      ),
    ];
  }
}

/// The address as a large QR code, with copy and share.
class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(slateFilesProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            // Dark modules on white scan reliably in either theme.
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label: 'QR code of your address',
              image: true,
              child: SizedBox.square(
                dimension: 260,
                child: PrettyQrView.data(data: address),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Your address', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        SelectableText(address, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          'Give it to people who pay you. It stays the same as long as you '
          'keep the same mailbox server.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => copyText(context, address, 'Address'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ),
            if (files.canShareText) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => ref
                      .read(autoLockHoldProvider.notifier)
                      .during(() => files.shareText(address)),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Whether the app is connected to the mailbox server.
class _ListenerLine extends ConsumerWidget {
  const _ListenerLine({required this.relay});

  final String? relay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listener = ref.watch(listenerProvider);
    final at = relay == null ? '' : ' $relay';
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(
            listener.connected ? Icons.wifi_tethering : Icons.sync,
            size: 18,
            color: listener.connected
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // One sentence about when payments arrive, so it cannot read as two
              // contradicting ones.
              '${listener.connected ? 'Connected to the mailbox server$at.' : 'Connecting to the mailbox server$at…'} '
              'Payments arrive while the app is open; ones sent while it is '
              'closed arrive the next time you unlock.',
            ),
          ),
        ],
      ),
    );
  }
}
