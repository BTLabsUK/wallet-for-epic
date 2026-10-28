// SPDX-License-Identifier: Apache-2.0
/// The one badge of the app, on the phone and on the desktop: a glyph or a dot that carries
/// the state and one to three muted words ("Default", "Experimental", "Epicbox", "Over Tor",
/// "Added by you"), beside a title or in a row.
///
/// Rules:
///  - A badge states, it never acts: no tap. A tappable chip is a button.
///  - The glyph or dot carries the tone; the words stay in the text colour. Nothing is said by
///    colour alone: the words (or the glyph's tooltip and semantics) say the state.
///  - Fewer badges: in a list the glyph alone (`compact`) with the words in its tooltip; the
///    words where the fact is new to the reader (a detail panel, a page title).
///  - [BadgeTone.gold] is the brand, not a state (a default, a highlight); [BadgeTone.ok] is
///    working or trusted, [BadgeTone.info] in progress, [BadgeTone.warn] needs attention,
///    [BadgeTone.risk] wrong or not connected, [BadgeTone.neutral] a plain fact.
///
/// Colours and the size come from [BadgeStyle], read from the theme in force: the desktop's
/// [DeskColors] when the tree is under the desktop theme, the phone's [WalletTokens] otherwise
/// (Protocol by brightness in a bare theme, like `context.tokens`).
library;

import 'package:flutter/material.dart';

import '../desktop/theme/tokens.dart' show DeskColors, deskScale;
import '../l10n.dart';
import '../recipient.dart' show RecipientKind;
import '../tor_routes.dart' show TorWay;
import 'method_icons.dart';
import 'status_icons.dart';
import 'theme/tokens.dart' show WalletTokens, WalletTokensOf;

export 'method_icons.dart';

/// What a badge says with its colour; the words say it first.
enum BadgeTone { neutral, ok, warn, risk, info, gold }

/// How the badge is drawn. Three directions were rendered side by side
/// (2026-10-25); [badgeLook] is the pick, [bare] (no box: the glyph or dot carries the tone),
/// the other two stay so a swap is this one line plus a rebuild.
///  - [bare]: no box. A 6 dp dot or a 13 dp glyph in the tone, then the words in the dim text
///    colour (Linear, Vercel).
///  - [outline]: an 18 dp rounded rectangle with a hairline and no fill; the glyph in the tone,
///    the words dim (Geist, Radix).
///  - [ghost]: an 18 dp rounded rectangle with a faint neutral fill and no hairline; the glyph
///    in the tone, the words in the text colour (Stripe, Arc).
enum BadgeLook { bare, outline, ghost }

/// The look in force. The tours set it from `BADGE_LOOK` to render the directions page.
BadgeLook badgeLook = BadgeLook.bare;

/// The badge's colours and scale, from the theme in force. [scale] is the theme's interface
/// scale (1 on the phone, the desktop's factor), applied to every size but the text, which the
/// app's `TextScaler` scales.
@immutable
class BadgeStyle {
  const BadgeStyle({
    required this.text,
    required this.dim,
    required this.faint,
    required this.line,
    required this.ghostFill,
    required this.neutral,
    required this.ok,
    required this.warn,
    required this.risk,
    required this.info,
    required this.gold,
    this.scale = 1,
  });

  /// Words: [text] in a ghost box, [dim] elsewhere. [faint] is the neutral dot's ring and
  /// [line] the outline's hairline; [ghostFill] the ghost box.
  final Color text, dim, faint, line, ghostFill;
  final Color neutral, ok, warn, risk, info, gold;
  final double scale;

  /// The ink of [tone]: the glyph, the dot and the outline's tint.
  Color ink(BadgeTone tone) => switch (tone) {
    BadgeTone.neutral => neutral,
    BadgeTone.ok => ok,
    BadgeTone.warn => warn,
    BadgeTone.risk => risk,
    BadgeTone.info => info,
    BadgeTone.gold => gold,
  };

  /// From the phone's tokens.
  BadgeStyle.wallet(WalletTokens t)
    : text = t.text,
      dim = t.dim,
      faint = t.faint,
      line = t.lineStrong,
      ghostFill = t.text.withValues(alpha: 0.06),
      neutral = t.faint,
      ok = t.ok,
      warn = t.warn,
      risk = t.risk,
      info = t.info,
      gold = t.accentText,
      scale = 1;

  /// From the desktop tokens, sized by the interface scale.
  BadgeStyle.desk(DeskColors c)
    : text = c.text,
      dim = c.dim,
      faint = c.faint,
      line = c.lineStrong,
      ghostFill = c.text.withValues(alpha: 0.06),
      neutral = c.faint,
      ok = c.ok,
      warn = c.warn,
      risk = c.risk,
      info = c.info,
      gold = c.accentText,
      scale = deskScale;

  /// The style of the theme in force at [context].
  static BadgeStyle of(BuildContext context) {
    final desk = Theme.of(context).extension<DeskColors>();
    return desk == null ? BadgeStyle.wallet(context.tokens) : BadgeStyle.desk(desk);
  }
}

/// The badge. A 13 dp glyph, a 6 dp dot or a 10 dp spinner carries the tone; the [label] is
/// 11 px medium in the dim text colour, one line, cut with an ellipsis when the row is narrow
/// (a `Flexible` parent lets it shrink). A null [label] shows the glyph alone: [semanticsLabel]
/// says the words and [tooltip] shows them on hover or tap.
class EBadge extends StatelessWidget {
  const EBadge(
    this.label, {
    super.key,
    this.icon,
    this.tone = BadgeTone.neutral,
    this.busy = false,
    this.dot = false,
    this.semanticsLabel,
    this.tooltip,
    this.liveRegion = false,
    this.wrap = false,
  }) : assert(label != null || semanticsLabel != null, 'A glyph-only badge needs semanticsLabel');

  /// The kind of an address: the method's glyph ([MethodIcons], the one icon per method) and
  /// its short name ("Epicbox", "HTTP", "Tor"). A fact, so neutral. [compact] shows the glyph
  /// alone with the full name ("Link · Tor") in its tooltip and semantics: for a list row,
  /// where the name repeats on every line.
  EBadge.kind(RecipientKind kind, {super.key, required AppLocalizations l, bool compact = false, String? tooltip})
    : label = compact ? null : MethodIcons.shortName(l, MethodKind.ofRecipient(kind)),
      icon = MethodIcons.of(MethodKind.ofRecipient(kind)),
      tone = BadgeTone.neutral,
      busy = false,
      dot = false,
      semanticsLabel = compact ? MethodIcons.fullName(l, MethodKind.ofRecipient(kind)) : null,
      tooltip = tooltip ?? (compact ? MethodIcons.fullName(l, MethodKind.ofRecipient(kind)) : null),
      liveRegion = false,
      wrap = false;

  /// On (ok, filled dot) or off (neutral, ring): [label] carries the word, from the screen's
  /// own strings ("On", "Off", "Always on").
  const EBadge.state(this.label, {super.key, required bool on, this.tooltip, this.liveRegion = false})
    : icon = null,
      tone = on ? BadgeTone.ok : BadgeTone.neutral,
      busy = false,
      dot = true,
      semanticsLabel = null,
      wrap = false;

  /// How a connection goes over Tor: the Tor glyph, ok over Tor, a spinner while Tor starts,
  /// risk when Tor is not connected, neutral on the clearnet. [label] carries the words.
  EBadge.tor(this.label, {super.key, required TorWay way, this.tooltip, this.liveRegion = false})
    : icon = EpicGlyphs.tor,
      tone = switch (way) {
        TorWay.overTor => BadgeTone.ok,
        TorWay.wait => BadgeTone.info,
        TorWay.blocked => BadgeTone.risk,
        TorWay.clearnet || TorWay.needsTor || TorWay.off => BadgeTone.neutral,
      },
      busy = way == TorWay.wait,
      dot = false,
      semanticsLabel = null,
      wrap = false;

  final String? label;
  final IconData? icon;
  final BadgeTone tone;

  /// A small spinner in the glyph's place: in progress.
  final bool busy;

  /// A 6 dp dot in the glyph's place: filled in the tone, a ring when neutral.
  final bool dot;

  /// What a screen reader says instead of [label] (required without one).
  final String? semanticsLabel;

  /// Shown on hover, and on a tap on the phone.
  final String? tooltip;

  /// Announced when it appears or changes.
  final bool liveRegion;

  /// A sentence-long [label] that breaks onto more lines instead of being cut: the claimed-name
  /// chip in a narrow sheet.
  final bool wrap;

  /// The method glyph of [kind]: [MethodIcons] is the source.
  static IconData kindIcon(RecipientKind kind) => MethodIcons.of(MethodKind.ofRecipient(kind));

  @override
  Widget build(BuildContext context) {
    final s = BadgeStyle.of(context);
    double px(double v) => (v * s.scale).roundToDouble();
    final ink = s.ink(tone);
    final words = label;
    final boxed = badgeLook != BadgeLook.bare;
    final base = Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    Widget? glyph;
    if (busy) {
      glyph = SizedBox.square(
        dimension: px(10),
        child: CircularProgressIndicator(strokeWidth: 1.5, color: ink),
      );
    } else if (dot || (!boxed && icon == null)) {
      // Bare has no box to tint, so a badge without a glyph gets the dot: filled in its tone,
      // a faint ring when neutral ("Default", "Updating"), so the words still read as a tag.
      final filled = tone != BadgeTone.neutral;
      glyph = Container(
        width: px(6),
        height: px(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? ink : Colors.transparent,
          border: filled ? null : Border.all(color: s.faint, width: px(1.5)),
        ),
      );
    } else if (icon != null) {
      glyph = Icon(icon, size: px(words == null && !boxed ? 14 : 13), color: ink);
    }
    final textStyle = base.copyWith(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: badgeLook == BadgeLook.ghost ? s.text : s.dim,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ?glyph,
        if (glyph != null && words != null) SizedBox(width: px(icon == null && !busy ? 6 : 4)),
        if (words != null)
          Flexible(
            child: wrap
                ? Text(words, style: textStyle)
                : Text(words, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: textStyle),
          ),
      ],
    );
    Widget badge;
    if (!boxed) {
      badge = ConstrainedBox(constraints: BoxConstraints(minHeight: px(16)), child: Center(widthFactor: 1, heightFactor: 1, child: row));
    } else {
      final outline = badgeLook == BadgeLook.outline;
      badge = Container(
        constraints: BoxConstraints(minHeight: px(18), minWidth: px(18)),
        padding: EdgeInsetsDirectional.fromSTEB(
          glyph == null ? px(6) : (words == null ? px(1) : px(5)),
          0,
          words == null ? px(1) : px(6),
          0,
        ),
        decoration: BoxDecoration(
          color: outline ? null : s.ghostFill,
          borderRadius: BorderRadius.circular(px(5)),
          border: outline ? Border.all(color: tone == BadgeTone.neutral ? s.line : ink.withValues(alpha: 0.4)) : null,
        ),
        child: row,
      );
    }
    if (tooltip != null) {
      badge = Tooltip(message: tooltip, triggerMode: TooltipTriggerMode.tap, child: badge);
    }
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: semanticsLabel ?? words,
      excludeSemantics: true,
      child: badge,
    );
  }
}
