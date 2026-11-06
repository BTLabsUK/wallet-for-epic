// SPDX-License-Identifier: Apache-2.0
/// A domain-backed contact's relay move on the desktop (`relay_moves.dart`): the dialog it
/// shows once, and the Accept and Refuse the contact details repeat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models.dart' show PairingRecord;
import '../../../relay_moves.dart';
import '../../../server_list.dart';
import '../../data/pairing_state.dart';
import '../../data/server_lists.dart' show deskServerListProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

const Key deskRelayMoveDialogKey = ValueKey('desk-relay-move-dialog');
const Key deskRelayMoveAcceptKey = ValueKey('desk-relay-move-accept');
const Key deskRelayMoveRefuseKey = ValueKey('desk-relay-move-refuse');

/// Whether [relay] is missing from the Epicbox servers, so Accept adds it.
bool deskRelayMoveAddsServer(WidgetRef ref, String relay) {
  final list = ref.watch(deskServerListProvider(ServerKind.relay));
  return list != null && !list.has(ServerKind.relay, relayLabelOf(relay));
}

/// Accept: [relay] joins the Epicbox servers (last, never the one in use) if it is not there,
/// then the contact moves to it.
Future<void> deskAcceptRelayMove(WidgetRef ref, PairingRecord p, String relay) async {
  final list = ref.read(deskServerListProvider(ServerKind.relay));
  if (!(list?.has(ServerKind.relay, relayLabelOf(relay)) ?? false)) {
    await ref.read(deskServerListProvider(ServerKind.relay).notifier).add(relayLabelOf(relay));
  }
  await deskPairingCall(ref, (api) => api.acceptRelayMove(p.id, relay));
}

/// Refuse: nothing moves and the contact is not told; the same relay is not asked again.
Future<void> deskRefuseRelayMove(WidgetRef ref, PairingRecord p, String relay) =>
    deskPairingCall(ref, (api) => api.refuseRelayMove(p.id, relay));

/// Shows [p]'s request once: marked shown first, so a dialog closed without a choice leaves
/// the request on the contact's details and never shows again.
Future<void> deskAskRelayMove(BuildContext context, WidgetRef ref, PairingRecord p) async {
  final relay = p.requestedRelay;
  if (relay == null) return;
  final name = ref.read(deskPairingNameProvider(p.id));
  await deskPairingCall(ref, (api) => api.markRelayMoveShown(p.id, relay));
  if (!context.mounted) return;
  final accept = await showEDialog<bool>(
    context,
    builder: (_) => DeskRelayMoveDialog(name: name, relay: relay),
  );
  switch (accept) {
    case true:
      await deskAcceptRelayMove(ref, p, relay);
    case false:
      await deskRefuseRelayMove(ref, p, relay);
    case null:
      break;
  }
}

/// The request: who moved, where to, what Refuse means; Accept pops true, Refuse false.
class DeskRelayMoveDialog extends ConsumerWidget {
  const DeskRelayMoveDialog({super.key, required this.name, required this.relay});

  final String name;
  final String relay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final shown = relayLabelOf(relay);
    return EDialog(
      key: deskRelayMoveDialogKey,
      title: l.relayMoveTitle(name),
      description: l.relayMoveBody(name, shown),
      icon: EIcons.epicbox,
      tone: ETone.info,
      body: deskRelayMoveAddsServer(ref, relay) ? Text(l.relayMoveAddsServer(shown), style: context.ts.bodyDim) : null,
      actions: [
        EButton(key: deskRelayMoveRefuseKey, label: l.relayMoveRefuse, onPressed: () => Navigator.pop(context, false)),
        EButton.primary(key: deskRelayMoveAcceptKey, label: l.relayMoveAccept, onPressed: () => Navigator.pop(context, true)),
      ],
    );
  }
}
