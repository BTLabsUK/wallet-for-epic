import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'help_screen.dart';
import 'slate_file_screen.dart';
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// Receiving: epicbox payments arrive by themselves while connected; a transaction file or
/// text can still be accepted by hand. There is no HTTP receive, because a phone cannot
/// accept connections.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  final _incoming = TextEditingController();
  /// A repeat carries the answer given the first time.
  ReceivedSlate? _response;
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
      setState(() => _error = context.l10n.receivePasteFirst);
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
      // A repeat changed nothing, so home keeps what it shows.
      if (!response.repeated) container.invalidate(homeProvider);
      if (mounted) setState(() => _response = response);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
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
    final l = context.l10n;
    final address = ref.watch(addressProvider);
    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      appBar: AppBar(
        title: Text(l.receiveTitle),
        actions: [
          const _ConnectionDot(),
          IconButton(
            tooltip: l.receiveHelpTooltip,
            icon: const Icon(Icons.help_outline),
            onPressed: () => openHelp(context, HelpTopic.receiving),
          ),
        ],
      ),
      body: CenteredBody(
        children: [
          switch (address) {
            AsyncData(:final value) => _AddressCard(address: value),
            AsyncError(:final error) => ErrorText(describeError(l, error)),
            _ => const LinearProgressIndicator(),
          },
          // Transaction files are a technical route; epicbox needs nothing from the user.
          if (AdvancedOptions.of(context)) ...[
            const SizedBox(height: 24),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l.receiveFileSection),
              childrenPadding: const EdgeInsets.only(bottom: 16),
              children: _fileSection(l),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _fileSection(AppLocalizations l) {
    final response = _response;
    return [
      BusyButton(
        label: l.receiveOpenFile,
        onPressed: () => openSlateFile(context, ref),
      ),
      const SizedBox(height: 8),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l.receivePasteSection),
        children: [
          if (response == null) ...[
            SlateInput(controller: _incoming, label: l.receiveSlateLabel),
            const SizedBox(height: 16),
            if (_error != null) ErrorText(_error!),
            BusyButton(label: l.receiveAccept, busy: _busy, onPressed: _sign),
          ] else ...[
            SlateBox(
              title: response.repeated
                  ? l.receiveRepeatedTitle
                  : l.receiveResponseTitle,
              json: response.json,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _reset, child: Text(l.receiveAnother)),
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
    final t = context.tokens;
    final dark = theme.brightness == Brightness.dark;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          // The corner ticks frame the code as the screen's one object, like Home's balance.
          child: CustomPaint(
            foregroundPainter: CornerTicksPainter(t.tick, length: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Dark modules on white scan reliably in either theme.
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(t.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: t.accent.withValues(alpha: dark ? 0.22 : 0.12),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Semantics(
                  label: l.receiveQrLabel,
                  image: true,
                  child: SizedBox.square(
                    dimension: 260,
                    child: PrettyQrView.data(data: address),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // The QR code, Copy and Share always carry the full address. On screen it is short,
        // without this wallet's own relay, unless Advanced options is on. It is data, so the
        // mono face.
        SelectableText(
          AdvancedOptions.of(context)
              ? address
              : shortAddress(address, ownServer: ownEpicboxServer(ref)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(fontFamily: t.monoFamily),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () =>
                    copyText(context, address, l.receiveAddressCopied),
                icon: const Icon(Icons.copy),
                label: Text(l.commonCopy),
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
                  label: Text(l.commonShare),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A small dot for the epicbox connection: filled when connected, red when offline, hollow
/// while connecting. The words are in its tooltip and semantics label only.
class _ConnectionDot extends ConsumerWidget {
  const _ConnectionDot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listener = ref.watch(listenerProvider);
    final colors = Theme.of(context).colorScheme;
    final l = context.l10n;
    final (label, color, filled) = listener.connected
        ? (l.receiveEpicboxConnected, colors.primary, true)
        : listener.lost
        ? (l.receiveEpicboxOffline, colors.error, true)
        : (l.receiveEpicboxConnecting, colors.outline, false);
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        liveRegion: true,
        child: SizedBox.square(
          // A 48 dp target, so the tooltip opens on a long press.
          dimension: 48,
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? color : null,
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
