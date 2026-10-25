/// The pieces every pairing screen shares, on the phone (SPEC 3): the word tiles, the trust
/// badges, the contact avatar, the countdown, the switch rows with their info icon, the share
/// box and the outcome card. The desktop reads the tiles and badges too.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../wallet_service.dart';
import '../badge.dart';
import '../contact_page.dart' show contactInitials;
import '../info_hint.dart';
import '../status_icons.dart';
import '../theme/brand.dart';
import '../theme/protocol.dart';
import '../theme/tokens.dart';

/// The tile sizes: the words check on the phone, the pairing words, a desktop panel.
enum WordTileSize {
  check(72, 16),
  words(62, 14),
  small(44, 11);

  const WordTileSize(this.tile, this.name);

  final double tile;
  final double name;
}

/// A row of word tiles (the four of the check, the five pairing words): each emoji in a
/// square tile with its name under it. A null entry is an empty slot (dashed, its number in
/// it) while the words are typed; indexes in [bad] get a risk border. Tiles shrink to fit the
/// width, never below two thirds of their size.
class WordTiles extends StatelessWidget {
  const WordTiles({
    super.key,
    required this.words,
    required this.label,
    this.size = WordTileSize.words,
    this.bad = const {},
    this.dim = false,
  });

  final List<SasWord?> words;

  /// The group's label for a screen reader ("The four words").
  final String label;
  final WordTileSize size;
  final Set<int> bad;

  /// Faded, for expired words.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = _l10n(context);
    const gap = 8.0;
    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, box) {
          final n = words.length;
          final fit = (box.maxWidth - gap * (n - 1)) / n;
          final side = fit < size.tile ? (fit < size.tile * 2 / 3 ? size.tile * 2 / 3 : fit) : size.tile;
          final scale = side / size.tile;
          final tiles = [
            for (var i = 0; i < n; i++)
              _WordTile(
                word: words[i],
                index: i,
                side: side,
                nameSize: size.name * (scale < 1 ? (0.85 + 0.15 * scale) : 1),
                bad: bad.contains(i),
                emptyLabel: l.pairWordSlot(i + 1),
                tokens: t,
              ),
          ];
          return Opacity(
            opacity: dim ? 0.55 : 1,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: 12,
              children: tiles,
            ),
          );
        },
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.word,
    required this.index,
    required this.side,
    required this.nameSize,
    required this.bad,
    required this.emptyLabel,
    required this.tokens,
  });

  final SasWord? word;
  final int index;
  final double side;
  final double nameSize;
  final bool bad;
  final String emptyLabel;
  final WalletTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final w = word;
    final Widget square;
    if (w == null) {
      square = CustomPaint(
        painter: _DashedBox(t.lineStrong, t.radiusSmall),
        child: SizedBox.square(
          dimension: side,
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(fontFamily: t.monoFamily, fontSize: side * 0.24, color: t.faint),
            ),
          ),
        ),
      );
    } else {
      square = Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: bad ? t.risk : t.line, width: bad ? 2 : 1),
          borderRadius: BorderRadius.circular(t.radiusSmall),
          boxShadow: [BoxShadow(color: t.accent.withValues(alpha: dark ? 0.14 : 0.08), blurRadius: side * 0.35, spreadRadius: -side * 0.08)],
        ),
        child: CustomPaint(
          foregroundPainter: CornerTicksPainter(t.tick, length: 8, width: 2),
          child: Center(
            // The emoji is drawn by the platform's colour font.
            child: Text(w.emoji, style: TextStyle(fontSize: side * 0.48, height: 1)),
          ),
        ),
      );
    }
    return Semantics(
      label: w?.name ?? emptyLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: side + 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            square,
            const SizedBox(height: 6),
            Text(
              w?.name ?? '…',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(fontFamily: t.headFamily, fontWeight: FontWeight.w600, fontSize: nameSize, color: w == null ? t.faint : t.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBox extends CustomPainter {
  const _DashedBox(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color || old.radius != radius;
}

/// The strings, also where only the desktop's localizations are (its screens use these parts).
AppLocalizations _l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ?? englishStrings;

/// The trust badge of [record] (SPEC 3): Verified (ok), Paired, not verified (warn, "Paired"
/// with [short]), Keys changed (risk). Nothing for a pending record.
class TrustBadge extends StatelessWidget {
  const TrustBadge(this.record, {super.key, this.short = false});

  final PairingRecord? record;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    final r = record;
    if (r == null) return const SizedBox.shrink();
    return switch (r.state) {
      PairingState.verified => EBadge(l.trustVerified, icon: EpicGlyphs.verified, tone: BadgeTone.ok),
      PairingState.paired => EBadge(short ? l.trustPairedShort : l.trustPaired, icon: EpicGlyphs.paired, tone: BadgeTone.warn),
      PairingState.keysChanged => EBadge(l.trustKeysChanged, icon: EpicGlyphs.keysChanged, tone: BadgeTone.risk),
      PairingState.pendingInvite || PairingState.pendingReply => const SizedBox.shrink(),
    };
  }
}

/// The Sealed badge; "Sealed for Anna" with [name].
class SealedBadge extends StatelessWidget {
  const SealedBadge({super.key, this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    final n = name;
    return EBadge(n == null ? l.trustSealed : l.trustSealedFor(n), icon: EpicGlyphs.sealed);
  }
}

/// The "Name chosen by them" chip: the name came from the other side and is not checked.
class ClaimedNameBadge extends StatelessWidget {
  const ClaimedNameBadge({super.key, this.long = false});

  final bool long;

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    return EBadge(long ? l.pairNameClaimed : l.pairNameClaimedShort, icon: Icons.person_outline);
  }
}

/// A contact's avatar: its initials in a corner-ticked tile, in the accent's text colour for
/// a person and the info colour for a shop or an exchange.
class PairAvatar extends StatelessWidget {
  const PairAvatar({super.key, required this.name, this.kind = PairingParty.person, this.size = 48});

  final String name;
  final PairingParty kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlyphTile(
      size: size,
      child: Text(
        contactInitials(name),
        style: TextStyle(
          fontFamily: t.headFamily,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: kind == PairingParty.person ? t.accentText : t.info,
        ),
      ),
    );
  }
}

/// A clock line that counts down to [until]: [label] (or the time left) in mono, the warn
/// colour in the last minute ([lastMinute] replaces the words then). Rebuilds every second.
class PairCountdown extends ConsumerStatefulWidget {
  const PairCountdown({super.key, required this.until, this.label, this.clock = false, this.lastMinute, this.leading});

  final DateTime until;

  /// The words before the time, as `Invite expires in`.
  final String? label;

  /// `9:32` instead of `23 h 12 min`.
  final bool clock;
  final String? lastMinute;

  /// Shown before the time instead of the clock glyph.
  final Widget? leading;

  @override
  ConsumerState<PairCountdown> createState() => _PairCountdownState();
}

class _PairCountdownState extends ConsumerState<PairCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = _l10n(context);
    final theme = Theme.of(context);
    final left = widget.until.difference(ref.watch(pairingClockProvider)());
    final last = left < const Duration(minutes: 1);
    final color = last ? t.warn : t.info;
    final time = widget.clock ? pairingClock(left) : pairingSpan(l, left);
    return Semantics(
      container: true,
      child: Row(
        children: [
          widget.leading ?? Icon(Icons.schedule, size: 18, color: color),
          const SizedBox(width: 8),
          if (last && widget.lastMinute != null)
            Expanded(
              child: Text(widget.lastMinute!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: t.text)),
            )
          else if (widget.label != null)
            Expanded(
              child: Text(widget.label!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: t.text)),
            )
          else
            const Spacer(),
          Text(time, style: TextStyle(fontFamily: t.monoFamily, fontSize: 13, color: last ? t.warn : t.dim)),
        ],
      ),
    );
  }
}

/// A card of rows with hairlines between them, as the pairing block and the settings use.
class PairCard extends StatelessWidget {
  const PairCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // A Material, not a decorated box: the rows are list tiles whose ink paints on it.
    return Material(
      color: t.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: t.line),
        borderRadius: BorderRadius.circular(t.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A switch row: the label with its info icon (the sheet holds the explanation), a hint under
/// it, the switch. A null [onChanged] disables it.
class PairSwitchRow extends StatelessWidget {
  const PairSwitchRow({
    super.key,
    required this.label,
    required this.info,
    required this.value,
    required this.onChanged,
    this.hint,
    this.switchKey,
  });

  final String label;

  /// The info sheet's text; empty for none.
  final String info;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? hint;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final on = onChanged;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: on == null ? t.dim : t.text))),
                        if (info.isNotEmpty) InfoHint(info, title: label),
                      ],
                    ),
                    if (hint case final h?)
                      Text(h, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                  ],
                ),
              ),
              Switch(key: switchKey, value: value, onChanged: on),
            ],
          ),
        ),
      ),
    );
  }
}

/// A notice inside a screen: the tone's colour as the card's edge, a bold title, the body and
/// optional buttons. [tone] is ok, info, warn or risk.
class PairEdgeNotice extends StatelessWidget {
  const PairEdgeNotice({super.key, required this.tone, required this.title, this.body, this.actions = const []});

  final BadgeTone tone;
  final String title;
  final String? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final edge = switch (tone) {
      BadgeTone.ok => t.ok,
      BadgeTone.warn => t.warn,
      BadgeTone.risk => t.risk,
      BadgeTone.info => t.info,
      BadgeTone.gold => t.accent,
      BadgeTone.neutral => t.lineStrong,
    };
    final icon = switch (tone) {
      BadgeTone.ok => Icons.check_circle_outline,
      BadgeTone.warn => Icons.warning_amber_rounded,
      BadgeTone.risk => Icons.error_outline,
      _ => Icons.info_outline,
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: EdgeCard(
        edge: edge,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: edge),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (body case final b?) ...[
                      const SizedBox(height: 4),
                      Text(b, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: actions),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text to send in a box: mono where it is a link, selectable.
class ShareBox extends StatelessWidget {
  const ShareBox({super.key, required this.text, this.label});

  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label case final lb?) ...[
          Text(lb, style: theme.textTheme.labelMedium?.copyWith(color: t.dim)),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: t.field,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(t.radiusSmall),
          ),
          child: SelectableText(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(fontFamily: t.monoFamily, fontSize: 12.5, height: 1.45),
          ),
        ),
      ],
    );
  }
}

/// The small print under a section: dim, small.
class PairSmallPrint extends StatelessWidget {
  const PairSmallPrint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim));
}

/// A screen's lead paragraph.
class PairLead extends StatelessWidget {
  const PairLead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.tokens.dim));
}

/// A section head with the gold rule, as `ProtocolSectionHead`, with room above it.
class PairSection extends StatelessWidget {
  const PairSection(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: ProtocolSectionHead(title, trailing: trailing),
  );
}
