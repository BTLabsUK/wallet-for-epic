// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../relay_block_phone.dart';
import 'status.dart' show relayLabel;
import 'theme/tokens.dart';

/// The key of [RelayBlockedNote], for tests.
const Key relayBlockedKey = ValueKey('relay-blocked');

/// The key of its Switch button, for tests.
const Key relayBlockedSwitchKey = ValueKey('relay-blocked-switch');

/// What Receive and the Epicbox server list say while this network blocks the wallet's relay
/// ([ListenerState.blocked]): the sentence, then one button that moves the wallet to another
/// relay at once ([relayInsteadProvider]) and a line that the address changes. No Retry: a
/// restart changes nothing here, and LEPIC keeps trying by itself.
class RelayBlockedNote extends ConsumerStatefulWidget {
  const RelayBlockedNote({super.key, this.center = true});

  /// Centred, as on Receive; start-aligned in the server list.
  final bool center;

  @override
  ConsumerState<RelayBlockedNote> createState() => _RelayBlockedNoteState();
}

class _RelayBlockedNoteState extends ConsumerState<RelayBlockedNote> {
  bool _busy = false;
  String? _error;

  Future<void> _switch() async {
    final relay = ref.read(relayInsteadProvider);
    if (relay == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await switchToRelayInstead(ref, relay);
      if (mounted) setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = describeError(context.l10n, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final config = ref.watch(walletConfigProvider);
    final instead = ref.watch(relayInsteadProvider);
    final align = widget.center ? TextAlign.center : TextAlign.start;
    final button = TextButton.icon(
      key: relayBlockedSwitchKey,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      icon: _busy
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.swap_horiz),
      label: Text(instead == null ? '' : l.epicboxSwitchTo(instead.label)),
      onPressed: _busy ? null : () => unawaited(_switch()),
    );
    return Column(
      key: relayBlockedKey,
      crossAxisAlignment: widget.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          l.epicboxBlockedBody(config == null ? 'Epicbox' : relayLabel(config)),
          textAlign: align,
          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
        if (instead != null) ...[
          button,
          Text(
            l.slSwitchBody,
            textAlign: align,
            style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
          ),
        ],
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              textAlign: align,
              style: theme.textTheme.bodySmall?.copyWith(color: t.risk),
            ),
          ),
      ],
    );
  }
}
