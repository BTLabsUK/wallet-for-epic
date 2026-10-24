import 'package:flutter/material.dart';

import '../desk_l10n.dart';
import '../../tor_routes.dart';
import 'kit.dart';

/// The small chip beside a page title that says how this connection goes now (Send,
/// Receive): Over Tor, Tor starting, Tor not connected, or Not over Tor. Null shows nothing
/// (File: no connection).
class TorChip extends StatelessWidget {
  const TorChip(this.way, {super.key});

  final TorWay? way;

  /// The chip's words for [way].
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
    final c = context.dc;
    final (fg, bg, border) = switch (w) {
      TorWay.overTor => (c.ok, c.okSoft, c.ok.withValues(alpha: 0.45)),
      TorWay.wait => (c.warn, c.warnSoft, c.warn.withValues(alpha: 0.45)),
      TorWay.blocked => (c.risk, c.riskSoft, c.risk.withValues(alpha: 0.45)),
      _ => (c.faint, Colors.transparent, c.lineStrong),
    };
    final text = label(context.l10n, w);
    return Semantics(
      key: const ValueKey('tor-chip'),
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        height: 22.u,
        padding: EdgeInsets.symmetric(horizontal: Sp.x2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Rad.xs), border: Border.all(color: border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            switch (w) {
              TorWay.wait => ESpinner(size: 10.u, color: fg),
              TorWay.overTor => const EStatusDot(ETone.ok, size: 7),
              TorWay.blocked => const EStatusDot(ETone.risk, size: 7),
              _ => const EStatusDot(ETone.neutral, size: 7),
            },
            SizedBox(width: Sp.x1 + 2.u),
            Text(text, maxLines: 1, style: TextStyle(fontSize: Fs.xs, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}
