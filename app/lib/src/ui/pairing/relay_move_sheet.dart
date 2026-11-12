// SPDX-License-Identifier: Apache-2.0
/// A domain-backed contact's relay move on the phone (`relay_moves.dart`): the sheet it shows
/// once, and the Accept and Refuse the contact page repeats.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../contacts.dart' show contactsProvider;
import '../../l10n.dart';
import '../../models.dart';
import '../../pairing_providers.dart';
import '../../providers.dart' show networkChoiceProvider;
import '../../relay_moves.dart';
import '../../server_list_store.dart';
import '../../trust_ids.dart';
import '../kit/kit_button.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_tokens.dart';
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
  final accept = await showKitSheet<bool>(
    context: context,
    builder: (_) => Consumer(
      builder: (context, ref, _) => RelayMoveGuard(
        pairingId: p.id,
        relay: relay,
        child: RelayMoveSheet(name: name, relay: relayLabelOf(relay), addsServer: relayMoveAddsServer(ref, relay)),
      ),
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

/// Closes the sheet or dialog it wraps when its request is gone: the contact was unpaired, or
/// asks for another relay than [relay]. It then pops with no answer, as a swipe does, so nothing
/// is accepted or refused for a request that no longer stands. [records] is the pairings
/// provider of the app in use (phone by default).
class RelayMoveGuard extends ConsumerStatefulWidget {
  const RelayMoveGuard({super.key, required this.pairingId, required this.relay, required this.child, this.records});

  final String pairingId;
  final String relay;
  final Widget child;
  final ProviderListenable<AsyncValue<List<PairingRecord>>>? records;

  @override
  ConsumerState<RelayMoveGuard> createState() => _RelayMoveGuardState();
}

class _RelayMoveGuardState extends ConsumerState<RelayMoveGuard> {
  bool _closing = false;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(widget.records ?? pairingsProvider).value;
    if (records != null && !_closing) {
      final now = records.where((r) => r.id == widget.pairingId).firstOrNull;
      if (now == null || now.ended || now.requestedRelay != widget.relay) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
    return widget.child;
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
    final body = KitType.body.copyWith(color: t.dim);
    return KitSheet(
      key: relayMoveSheetKey,
      title: l.relayMoveTitle(name),
      primary: KitButton(
        key: relayMoveAcceptKey,
        label: l.relayMoveAccept,
        semanticsId: TrustIds.pairflowRelayAccept,
        onPressed: () => Navigator.pop(context, true),
      ),
      secondary: KitButton(
        key: relayMoveRefuseKey,
        label: l.relayMoveRefuse,
        kind: KitButtonKind.quiet,
        semanticsId: TrustIds.pairflowRelayRefuse,
        onPressed: () => Navigator.pop(context, false),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.relayMoveBody(name, relay), style: body),
            if (addsServer) ...[const SizedBox(height: 8), Text(l.relayMoveAddsServer(relay), style: body)],
          ],
        ),
      ),
    );
  }
}
