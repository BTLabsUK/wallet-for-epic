// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../desk_l10n.dart';
import '../../tor_routes.dart';
import 'kit.dart';

/// The badge beside a page title that says how this connection goes now (Send, Receive):
/// Over Tor, Tor starting, Tor not connected, or Not over Tor. Null shows nothing (File: no
/// connection).
class TorChip extends StatelessWidget {
  const TorChip(this.way, {super.key});

  final TorWay? way;

  /// The badge's words for [way].
  static String label(AppLocalizations l, TorWay way) => switch (way) {
    TorWay.overTor => l.deskKitChipOverTor,
    TorWay.wait => l.deskKitChipStarting,
    TorWay.blocked => l.deskKitChipNotConnected,
    TorWay.clearnet || TorWay.needsTor || TorWay.off => l.deskKitChipNotOverTor,
  };

  @override
  Widget build(BuildContext context) {
    final w = way;
    if (w == null) return const SizedBox.shrink();
    return EBadge.tor(label(context.l10n, w), key: const ValueKey('tor-chip'), way: w, liveRegion: true);
  }
}
