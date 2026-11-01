// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../desk_l10n.dart';
import '../../tor_routes.dart';
import 'kit.dart';

/// The badge beside a page title that says how this connection goes now (Send, Receive):
/// Over Tor, Tor starting, Tor not connected, or Not over Tor. Null shows nothing (File: no
/// connection), and so does a route Tor stops ([TorWay.off]): one source per page for Tor.
class TorChip extends StatelessWidget {
  const TorChip(this.way, {super.key, this.quiet = false});

  final TorWay? way;

  /// A banner on the page already says Tor is not connected: the chip keeps its words in the
  /// neutral look, never a second red signal (D-04).
  final bool quiet;

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
    // The chip states the route this connection takes; one Tor stops (a plain http:// send
    // while Tor is on) takes none, and the field says why: no "Without Tor" beside "does not
    // work with Tor on" (D-04).
    if (w == null || w == TorWay.off) return const SizedBox.shrink();
    return EBadge.tor(label(context.l10n, w), key: const ValueKey('tor-chip'), way: quiet && w == TorWay.blocked ? TorWay.off : w, liveRegion: !quiet);
  }
}
