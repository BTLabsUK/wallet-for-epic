/// What the Advanced network mode says to a screen with a network action: one answer
/// ([watchNetBlock]), one reason line ([NetBlockNote]) for Send, Recheck balance, feedback and
/// the rest, so they all say the same thing. The rule itself is `netBlockFor`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../network_gate.dart';
import '../providers.dart' show localNodeProvider;
import '../settings.dart' show appSettingsProvider;
import '../phone_tor.dart';
import '../tor_phone.dart';
import 'info_hint.dart' show showInfoSheet;
import 'settings_sections.dart' show SettingsSection, openSettingsSection;
import 'theme/advanced.dart';
import 'theme/tokens.dart';

/// The key of a [NetBlockNote], for tests.
const Key netBlockNoteKey = ValueKey('net-block-note');

/// The key of the Offline line that the local node has no peers, for tests.
const Key offlineNoPeersKey = ValueKey('offline-no-peers');

/// The key of an [OfflineNodeNote], for tests.
const Key offlineNodeNoteKey = ValueKey('offline-node-note');

/// Offline on a node that is not local, for a transaction file or QR Payment action, which
/// still runs there ([offlineUsesNode]). Rebuilds when the mode or the node changes.
bool watchOfflineUsesNode(BuildContext context, WidgetRef ref) =>
    offlineUsesNode(AdvancedOptions.of(context).networkMode, localNode: ref.watch(localNodeProvider));

/// The line under a transaction file or QR Payment action while Offline on a node that is not
/// local: "Uses the node" with an info icon; a tap opens the sheet with the whole explanation
/// (reads the chain and posts; a local node for the most privacy). A warning, never a block.
class OfflineNodeNote extends StatelessWidget {
  const OfflineNodeNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    void open() => showInfoSheet(
      context,
      title: l.advHomeOffline,
      text: l.netOfflineNodeHint,
      icon: Icons.info_outline,
    );
    return Semantics(
      key: offlineNodeNoteKey,
      button: true,
      label: l.netOfflineNodeLine,
      hint: l.netOfflineNodeHint,
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: t.info),
              const SizedBox(width: 6),
              Text(
                l.netOfflineNodeLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.info),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the stored network mode and Tor allow now. Rebuilds when either changes. [localNode]
/// for an action that reaches only the node in use ([localNodeProvider]), or a Direct send.
/// [epicbox] for an action over Epicbox: the switch on Settings › Transactions counts too.
NetBlock watchNetBlock(BuildContext context, WidgetRef ref, {bool localNode = false, bool epicbox = false}) => netBlockFor(
  AdvancedOptions.of(context).networkMode,
  phoneTorState(ref.watch(phoneTorProvider)),
  localNode: localNode,
  epicbox: !epicbox || ref.watch(appSettingsProvider.select((s) => s.value?.payments.epicbox ?? true)),
);

/// The one-line reason a network action is off, null when nothing stops it.
String? netBlockReason(AppLocalizations l, NetBlock block) => switch (block) {
  NetBlock.none => null,
  NetBlock.offline => l.netBlockOffline,
  NetBlock.waitingForTor => l.netBlockWaitingForTor,
  NetBlock.epicboxOff => l.netBlockEpicboxOff,
};

/// The reason line under a disabled network action. Offline opens the Advanced page, where the
/// mode is changed, Epicbox off the Transactions page; nothing shows when [block] is
/// [NetBlock.none].
class NetBlockNote extends StatelessWidget {
  const NetBlockNote(this.block, {super.key, this.line});

  final NetBlock block;

  /// Replaces the standard reason (Receive says it can't receive).
  final String? line;

  @override
  Widget build(BuildContext context) {
    final text = line ?? netBlockReason(context.l10n, block);
    if (text == null) return const SizedBox.shrink();
    final t = context.tokens;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: block == NetBlock.waitingForTor ? t.info : t.dim,
    );
    return Semantics(
      key: netBlockNoteKey,
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: block == NetBlock.offline || block == NetBlock.epicboxOff
            ? InkWell(
                onTap: () => openSettingsSection(
                  context,
                  block == NetBlock.offline ? SettingsSection.advanced : SettingsSection.transactions,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(text, textAlign: TextAlign.center, style: style),
                ),
              )
            : Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}
