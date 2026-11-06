// SPDX-License-Identifier: Apache-2.0
/// A domain-backed contact's relay move on the phone (`relay_moves.dart`): the sheet it shows
/// once, and the Accept and Refuse the contact page repeats.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart' show contactsProvider;
import '../../l10n.dart';
import '../../models.dart';
import '../../pairing_providers.dart';
import '../../providers.dart' show networkChoiceProvider;
import '../../relay_moves.dart';
import '../../server_list_store.dart';
import '../phone_sheet.dart';
import '../theme/tokens.dart';

const Key relayMoveSheetKey = ValueKey('relay-move-sheet');
const Key relayMoveAcceptKey = ValueKey('relay-move-accept');
const Key relayMoveRefuseKey = ValueKey('relay-move-refuse');

/// Whether [relay] is missing from the Epicbox servers, so Accept adds it.
bool relayMoveAddsServer(WidgetRef ref, String relay) {
  final chain = ref.watch(networkChoiceProvider).value?.preset.chain;
  if (chain == null) return false;
  final list = ref.watch(serverListProvider((ServerKind.relay, chain))).value;
  return list != null && !list.has(ServerKind.relay, relayLabelOf(relay));
}

/// Accept: [relay] joins the Epicbox servers (last, never the one in use) if it is not there,
/// then the contact moves to it.
Future<void> acceptPhoneRelayMove(WidgetRef ref, PairingRecord p, String relay) async {
  final chain = ref.read(networkChoiceProvider).value?.preset.chain;
  if (chain != null) {
    final kind = (ServerKind.relay, chain);
    final list = await ref.read(serverListProvider(kind).future);
    if (!list.has(ServerKind.relay, relayLabelOf(relay))) await ref.read(serverListProvider(kind).notifier).add(relayLabelOf(relay));
  }
  await pairingCall(ref, (api) => api.acceptRelayMove(p.id, relay));
}

/// Refuse: nothing moves and the contact is not told; the same relay is not asked again.
Future<void> refusePhoneRelayMove(WidgetRef ref, PairingRecord p, String relay) =>
    pairingCall(ref, (api) => api.refuseRelayMove(p.id, relay));

/// Shows [p]'s request once: marked shown first, so a sheet closed without a choice leaves the
/// request on the contact page and never shows again.
Future<void> askPhoneRelayMove(BuildContext context, WidgetRef ref, PairingRecord p) async {
  final relay = p.requestedRelay;
  if (relay == null) return;
  final l = context.l10n;
  final name = pairingName(p, ref.read(contactsProvider).value ?? const <Contact>[], l: l);
  await pairingCall(ref, (api) => api.markRelayMoveShown(p.id, relay));
  if (!context.mounted) return;
  final accept = await showPhoneSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) => RelayMoveSheet(name: name, relay: relayLabelOf(relay), addsServer: relayMoveAddsServer(ref, relay)),
    ),
  );
  switch (accept) {
    case true:
      await acceptPhoneRelayMove(ref, p, relay);
    case false:
      await refusePhoneRelayMove(ref, p, relay);
    case null:
      break;
  }
}

/// The request: who moved, where to, what Refuse means; Accept pops true, Refuse false.
class RelayMoveSheet extends StatelessWidget {
  const RelayMoveSheet({super.key, required this.name, required this.relay, required this.addsServer});

  final String name;
  final String relay;

  /// [relay] is not in the Epicbox servers: Accept adds it, and the sheet says so.
  final bool addsServer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(color: t.dim, height: 1.5);
    const target = Size(64, 44);
    return Padding(
      key: relayMoveSheetKey,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, size: 22, color: t.dim),
              const SizedBox(width: 10),
              Expanded(child: Semantics(header: true, child: Text(l.relayMoveTitle(name), style: theme.textTheme.titleMedium))),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.relayMoveBody(name, relay), style: body),
                if (addsServer) ...[const SizedBox(height: 8), Text(l.relayMoveAddsServer(relay), style: body)],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  key: relayMoveRefuseKey,
                  style: OutlinedButton.styleFrom(minimumSize: target),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.relayMoveRefuse),
                ),
                FilledButton(
                  key: relayMoveAcceptKey,
                  style: FilledButton.styleFrom(minimumSize: target),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.relayMoveAccept),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
