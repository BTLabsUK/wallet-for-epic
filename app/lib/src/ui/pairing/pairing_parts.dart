// SPDX-License-Identifier: Apache-2.0
/// The pieces every pairing screen shares, on the phone: the word tiles, the trust
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
import '../notices.dart' show InlineNotice, NoticeLevel;
import '../sas_picture.dart';
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

/// A row of word tiles (the four of the check, the five pairing words): each picture in a
/// square tile with its name under it. A null entry is an empty slot (dashed, its number in
/// it) while the words are typed; indexes in [bad] get a risk border. Tiles shrink to fit the
/// width, never below two thirds of their size. Each name has its whole slot and shrinks to
/// fit it: the names are read out to the other side, so none is ever cut.
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
          // n slots fit one row; the tile is the slot less 12, the name the whole slot.
          final full = box.maxWidth.isFinite ? (box.maxWidth - gap * (n - 1)) / n : double.infinity;
          final fit = full - 12;
          final side = fit < size.tile ? (fit < size.tile * 2 / 3 ? size.tile * 2 / 3 : fit) : size.tile;
          final scale = side / size.tile;
          // Wide rows keep the tiles together: a slot is at most the tile and a long name.
          final slot = full.clamp(side + 12, side + 48).toDouble();
          final tiles = [
            for (var i = 0; i < n; i++)
              _WordTile(
                word: words[i],
                index: i,
                side: side,
                slot: slot,
                nameSize: size.name * (scale < 1 ? (0.85 + 0.15 * scale) : 1),
                bad: bad.contains(i),
                dim: dim,
                emptyLabel: l.pairWordSlot(i + 1),
                tokens: t,
              ),
          ];
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: 12,
            children: tiles,
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
    required this.slot,
    required this.nameSize,
    required this.bad,
    required this.dim,
    required this.emptyLabel,
    required this.tokens,
  });

  final SasWord? word;
  final int index;
  final double side;

  /// The width the name has: the tile's share of the row.
  final double slot;
  final double nameSize;
  final bool bad;

  /// Expired: the square fades, the name stays readable in dim.
  final bool dim;
  final String emptyLabel;
  final WalletTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final w = word;
    final Widget square;
    if (w == null) {
      // An empty slot, or a typed word not in the table (outlined risk).
      square = CustomPaint(
        painter: _DashedBox(bad ? t.risk : t.lineStrong, t.radiusSmall, width: bad ? 2 : 1.5),
        child: SizedBox.square(
          dimension: side,
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(fontFamily: t.monoFamily, fontSize: side * 0.24, color: bad ? t.risk : t.dim),
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
            // The bundled picture, the same on every system; the tile's label says its name.
            child: SasPicture(w, size: side * 0.6, excludeFromSemantics: true),
          ),
        ),
      );
    }
    return Semantics(
      label: w?.name ?? emptyLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: slot,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(opacity: dim ? 0.5 : 1, child: square),
            const SizedBox(height: 6),
            // The whole name on one line, smaller when it is long: never cut.
            SizedBox(
              width: slot,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  w?.name ?? '…',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(fontFamily: t.headFamily, fontWeight: FontWeight.w600, fontSize: nameSize, color: w == null || dim ? t.dim : t.text),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBox extends CustomPainter {
  const _DashedBox(this.color, this.radius, {this.width = 1.5});

  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
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
  bool shouldRepaint(_DashedBox old) => old.color != color || old.radius != radius || old.width != width;
}

/// The strings, also where only the desktop's localizations are (its screens use these parts).
AppLocalizations _l10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ?? englishStrings;

/// The trust badge of [record]: Waiting (info), Verified (ok), Paired, not verified (warn,
/// "Paired" with [short]), Keys changed (risk), Ended (neutral; "Removed by" when the other
/// side removed it), Not answering (warn; [PairingRecord.notAnswering] replaces the trust it
/// had). Nothing for a pending code or answer.
class TrustBadge extends StatelessWidget {
  const TrustBadge(this.record, {super.key, this.short = false});

  final PairingRecord? record;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    final r = record;
    if (r == null) return const SizedBox.shrink();
    // Nothing sent through it arrives any more, whatever its trust was.
    if (r.removedByPeer) {
      final name = pairingName(r, const <Contact>[]);
      return EBadge(short || name.isEmpty ? l.trustRemovedShort : l.trustRemovedBy(name), icon: EpicGlyphs.keysChanged, tone: BadgeTone.risk);
    }
    // The check after a long gap got no answer: this says more than the trust it had.
    if (r.notAnswering && !r.ended && !r.state.isPending) return EBadge(l.trustNotAnswering, icon: Icons.cloud_off_outlined, tone: BadgeTone.warn);
    return switch (r.state) {
      PairingState.verified => EBadge(l.trustVerified, icon: EpicGlyphs.verified, tone: BadgeTone.ok),
      PairingState.paired => EBadge(short ? l.trustPairedShort : l.trustPaired, icon: EpicGlyphs.paired, tone: BadgeTone.warn),
      PairingState.keysChanged => EBadge(l.trustKeysChanged, icon: EpicGlyphs.keysChanged, tone: BadgeTone.risk),
      PairingState.waiting => EBadge(l.trustWaiting, icon: Icons.schedule, tone: BadgeTone.info),
      PairingState.ended => EBadge(l.trustEnded, icon: Icons.block, tone: BadgeTone.neutral),
      PairingState.pendingInvite || PairingState.pendingReply => const SizedBox.shrink(),
    };
  }
}

/// The No payments badge: the mark and the words, for a contact's page, the Check the code head
/// row and the pairing result.
class NoPaymentsBadge extends StatelessWidget {
  const NoPaymentsBadge({super.key});

  @override
  Widget build(BuildContext context) =>
      EBadge(_l10n(context).contactNoPayments, icon: EpicGlyphs.noPayments, tone: BadgeTone.neutral);
}

/// The bare No payments mark of a list row, after the trust badge: 16 px, dim, no words and no
/// tooltip; a screen reader reads the words.
class NoPaymentsMark extends StatelessWidget {
  const NoPaymentsMark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: _l10n(context).contactNoPayments,
    child: ExcludeSemantics(child: Icon(EpicGlyphs.noPayments, size: 16, color: context.tokens.dim)),
  );
}

/// "Waiting": a request sent or a code answered for the contact, not finished yet.
class PairPendingBadge extends StatelessWidget {
  const PairPendingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l = _l10n(context);
    return EBadge(l.trustWaiting, tone: BadgeTone.info, busy: true);
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

/// A contact's avatar: its initials in a corner-ticked tile, in the accent's text colour.
class PairAvatar extends StatelessWidget {
  const PairAvatar({super.key, required this.name, this.size = 48});

  final String name;
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
          color: t.accentText,
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
    // No words beside it: the clock and the time stay together, centred.
    final bare = widget.label == null && !(last && widget.lastMinute != null);
    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: bare ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
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
            ),
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
    // Not merged: a screen reader reaches the info button on its own, and the switch carries
    // the row's label and hint.
    return ConstrainedBox(
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
                      Flexible(
                        child: ExcludeSemantics(
                          child: Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: on == null ? t.dim : t.text)),
                        ),
                      ),
                      if (info.isNotEmpty) InfoHint(info, title: label),
                    ],
                  ),
                  if (hint case final h?)
                    ExcludeSemantics(child: Text(h, style: theme.textTheme.bodySmall?.copyWith(color: t.dim))),
                ],
              ),
            ),
            Semantics(
              label: label,
              hint: hint,
              // Disabled reads as disabled: not the accent of a switch that can be used.
              child: Opacity(opacity: on == null ? 0.38 : 1, child: Switch(key: switchKey, value: value, onChanged: on)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A notice inside a screen: an [InlineNotice] of [tone]'s level (ok, info, warn or risk), a
/// bold title, the body and optional buttons under the words; announced when it appears.
class PairEdgeNotice extends StatelessWidget {
  const PairEdgeNotice({super.key, required this.tone, required this.title, this.body, this.actions = const [], this.stretchActions = false});

  final BadgeTone tone;
  final String title;
  final String? body;
  final List<Widget> actions;

  /// The actions one under the other, each the card's width: a choice of three reads as one.
  final bool stretchActions;

  static NoticeLevel levelOf(BadgeTone tone) => switch (tone) {
    BadgeTone.ok => NoticeLevel.success,
    BadgeTone.warn => NoticeLevel.warning,
    BadgeTone.risk => NoticeLevel.error,
    BadgeTone.info || BadgeTone.gold || BadgeTone.neutral => NoticeLevel.info,
  };

  @override
  Widget build(BuildContext context) => InlineNotice(
    level: levelOf(tone),
    title: title,
    text: body,
    liveRegion: true,
    actions: stretchActions ? const [] : actions,
    actionsBelow: true,
    below: stretchActions && actions.isNotEmpty
        ? Padding(
            padding: const EdgeInsetsDirectional.only(top: 10, end: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(height: 8), actions[i]],
              ],
            ),
          )
        : null,
  );
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
          decoration: t.well,
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
