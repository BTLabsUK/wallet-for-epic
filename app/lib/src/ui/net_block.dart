/// What the Advanced network mode says to a screen with a network action: one answer
/// ([watchNetBlock]), one reason line ([NetBlockNote]) for Send, Recheck balance, feedback and
/// the rest, so they all say the same thing. The rule itself is `netBlockFor`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../network_gate.dart';
import '../phone_tor.dart';
import '../tor_phone.dart';
import 'settings_sections.dart' show SettingsSection, openSettingsSection;
import 'theme/advanced.dart';
import 'theme/tokens.dart';

/// The key of a [NetBlockNote], for tests.
const Key netBlockNoteKey = ValueKey('net-block-note');

/// What the stored network mode and Tor allow now. Rebuilds when either changes.
NetBlock watchNetBlock(BuildContext context, WidgetRef ref) => netBlockFor(
  AdvancedOptions.of(context).networkMode,
  phoneTorState(ref.watch(phoneTorProvider)),
);

/// The one-line reason a network action is off, null when nothing stops it.
String? netBlockReason(AppLocalizations l, NetBlock block) => switch (block) {
  NetBlock.none => null,
  NetBlock.offline => l.netBlockOffline,
  NetBlock.waitingForTor => l.netBlockWaitingForTor,
};

/// The reason line under a disabled network action. Offline opens the Advanced page, where the
/// mode is changed; nothing shows when [block] is [NetBlock.none].
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
        child: block == NetBlock.offline
            ? InkWell(
                onTap: () =>
                    openSettingsSection(context, SettingsSection.advanced),
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
