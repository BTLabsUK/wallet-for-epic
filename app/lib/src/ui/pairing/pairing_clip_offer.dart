/// The phone's clipboard offer (Pairing UX plan 4.7, 5): a pairing link copied in a chat is
/// offered once, as a small sheet, when the app comes to the front or Pair or Contacts opens.
/// Use it runs what a paste runs. The rules are `pairing_clipboard.dart`'s.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../pairing_clip_probe.dart';
import '../../pairing_clipboard.dart';
import '../../pairing_providers.dart';
import '../../providers.dart' show secretStoreProvider;
import '../../slate_files.dart';
import '../../wallet_service.dart';
import '../common.dart';
import 'pair_incoming.dart';
import 'pairing_parts.dart';

/// Keys for tests.
const Key pairClipUseKey = ValueKey('pair-clip-use');
const Key pairClipNotNowKey = ValueKey('pair-clip-not-now');

/// The pairings whose message step is on screen (the inviter's wait for the reply, the
/// joiner's wait for the finish link): a link for one of them, pasted or offered, leaves the
/// next screen to that step, which moves on by itself.
final Set<String> pairingStepsOnScreen = {};

/// The links offered once, or shared from this wallet, as hashes; kept on the device.
final pairingClipSeenProvider = AsyncNotifierProvider<PairingClipSeenStore, PairingClipSeen>(PairingClipSeenStore.new);

class PairingClipSeenStore extends AsyncNotifier<PairingClipSeen> {
  static const key = 'pairing.clip_seen';

  @override
  Future<PairingClipSeen> build() async => PairingClipSeen.decode(await ref.read(secretStoreProvider).read(key));

  Future<void> add(String link) async {
    final now = (await future).add(link);
    state = AsyncData(now);
    await ref.read(secretStoreProvider).write(key, now.encode());
  }
}

/// [link] is never offered from the clipboard: it was offered once, or this wallet sent it.
Future<void> markPairingLinkSeen(WidgetRef ref, String link) async {
  try {
    await ref.read(pairingClipSeenProvider.notifier).add(link);
  } on Object {
    // Not kept: at worst it is offered once more.
  }
}

/// Shares one of the three messages ([text], holding [link]) on the share sheet, or copies it
/// with [copy] or where there is none. The link is this wallet's own, so it is never offered
/// back from the clipboard.
Future<void> sharePairingMessage(BuildContext context, WidgetRef ref, String text, {required String link, bool copy = false}) async {
  final l = context.l10n;
  await markPairingLinkSeen(ref, link);
  final files = ref.read(slateFilesProvider);
  if (!context.mounted) return;
  if (copy || !files.canShareText) {
    await copyText(context, text, l.pairMessageCopied);
  } else {
    await files.shareText(text);
  }
}

bool _looking = false;

/// Looks for a pairing link on the clipboard on [trigger] and offers it, once. Nothing is read
/// while Pairing is off or the wallet locked, or while a dialog or sheet is up. [cardOpen]
/// while the in-person code is shown.
Future<void> lookForPairingLink(BuildContext context, WidgetRef ref, PairingClipTrigger trigger, {bool cardOpen = false}) async {
  if (kIsWeb || _looking || !ref.read(pairingSupportedProvider)) return;
  _looking = true;
  try {
    bool calm() {
      if (!context.mounted) return false;
      Route<dynamic>? top;
      Navigator.of(context, rootNavigator: true).popUntil((r) {
        top = r;
        return true;
      });
      return top is! PopupRoute;
    }

    if (!calm()) return;
    final List<PairingRecord> records;
    final PairingClipSeen seen;
    try {
      records = await ref.read(pairingsProvider.future);
      seen = await ref.read(pairingClipSeenProvider.future);
    } on Object {
      return;
    }
    final found = await ref.read(pairingClipReaderProvider).look(
      trigger: trigger,
      allowed: ref.read(pairingSupportedProvider),
      pending: PairingClipPending.of(records, now: ref.read(pairingClockProvider)(), cardOpen: cardOpen),
      seen: seen,
    );
    if (found == null) return;
    // Offered once, whatever the answer.
    await markPairingLinkSeen(ref, found.link);
    PairingInvitePreview? preview;
    if (found.kind == PairingLinkKind.invite) {
      try {
        preview = await ref.read(pairingApiProvider).openInvite(found.link);
      } on Object {
        // Expired, used or this wallet's own: nothing to offer.
        return;
      }
    }
    if (!calm() || !context.mounted) return;
    final use = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PairingClipSheet(kind: found.kind, name: preview?.name ?? ''),
    );
    if (use != true || !context.mounted) return;
    if (preview != null) {
      await showIncomingInvite(context, ref, preview);
    } else {
      await openPairingLink(context, ref, found.link);
    }
  } finally {
    _looking = false;
  }
}

/// "Pairing link found": what is on the clipboard, Use it or Not now. Pops true for Use it.
class PairingClipSheet extends StatelessWidget {
  const PairingClipSheet({super.key, required this.kind, this.name = ''});

  final PairingLinkKind kind;

  /// The inviter's name for an invite, as it claims it.
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final body = switch (kind) {
      PairingLinkKind.invite => l.pairClipInvite(name),
      PairingLinkKind.reply => l.pairClipReply,
      PairingLinkKind.confirm => l.pairClipFinish,
      PairingLinkKind.card => l.pairClipCard,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l.pairClipTitle, style: theme.textTheme.titleLarge)),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
          if (kind == PairingLinkKind.invite) ...[const SizedBox(height: 8), const Align(alignment: AlignmentDirectional.centerStart, child: ClaimedNameBadge())],
          const SizedBox(height: 20),
          FilledButton(
            key: pairClipUseKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.pairClipUse),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: pairClipNotNowKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.pairNotNow),
          ),
        ],
      ),
    );
  }
}
