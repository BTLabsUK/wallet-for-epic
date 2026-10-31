// SPDX-License-Identifier: Apache-2.0
/// The ⓘ sheets of the level picker and the Change level screen: what the level decides, and
/// Undercover (Tor only) at first start and later.
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../info_hint.dart';

/// "What this decides": the level is presentation only. The picker's footer goes in here too,
/// as it is hidden on a small screen.
class LevelHelpHint extends StatelessWidget {
  const LevelHelpHint({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InfoHint(
      '${l.lvPickHelpText}\n\n${l.levelFooter}',
      key: const ValueKey('level-help'),
      title: l.lvPickHelpTitle,
      size: 48,
    );
  }
}

/// Undercover's ⓘ: on the first-start picker ([later] false, nothing has connected yet) or on
/// the Change level screen.
class UndercoverHelpHint extends StatelessWidget {
  const UndercoverHelpHint({super.key, this.later = false});

  final bool later;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InfoHint(
      later ? l.lvPickUndercoverLaterHelp : l.lvPickUndercoverHelp,
      key: const ValueKey('level-undercover-help'),
      title: later ? l.lvPickUndercover : l.levelUndercoverTitle,
      size: 44,
    );
  }
}
