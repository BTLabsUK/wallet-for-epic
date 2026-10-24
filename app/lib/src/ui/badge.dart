/// The one badge of the app, on the phone and on the desktop: a small pill with a glyph and
/// one to three words, for a fact beside a title or a row ("Default", "Experimental",
/// "Epicbox", "Link · Tor", "Over Tor", "On", "Added by you").
///
/// Rules:
///  - A badge states, it never acts: no tap. A tappable chip is a button.
///  - Icon first where the fact has a glyph (a method, a connection, a pen); words always.
///  - Tone is the second signal, never the only one: the words already say the state.
///  - [BadgeTone.gold] is the brand, not a state (a default, a highlight); [BadgeTone.ok] is
///    working or trusted, [BadgeTone.info] in progress, [BadgeTone.warn] needs attention,
///    [BadgeTone.risk] wrong or not connected, [BadgeTone.neutral] a plain fact.
///
/// Colours and the size come from [BadgeStyle], which each theme builds from its own tokens
/// (`buildWalletTheme`, `buildDeskTheme`), so the badge needs no theme of its own.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../recipient.dart' show RecipientKind;
import '../tor_routes.dart' show TorWay;
import 'status_icons.dart';

/// What a badge says with its colour; the words say it first.
enum BadgeTone { neutral, ok, warn, risk, info, gold }

/// The badge's colours and scale, one per theme. [scale] is the theme's interface scale
/// (1 on the phone, the desktop's factor), applied to every size but the text, which the
/// app's `TextScaler` scales.
@immutable
class BadgeStyle extends ThemeExtension<BadgeStyle> {
  const BadgeStyle({
    required this.neutral,
    required this.neutralFill,
    required this.ok,
    required this.okFill,
    required this.warn,
    required this.warnFill,
    required this.risk,
    required this.riskFill,
    required this.info,
    required this.infoFill,
    required this.gold,
    required this.goldFill,
    this.scale = 1,
  });

  final Color neutral, neutralFill;
  final Color ok, okFill;
  final Color warn, warnFill;
  final Color risk, riskFill;
  final Color info, infoFill;
  final Color gold, goldFill;
  final double scale;

  /// Ink and fill for [tone].
  (Color ink, Color fill) inks(BadgeTone tone) => switch (tone) {
    BadgeTone.neutral => (neutral, neutralFill),
    BadgeTone.ok => (ok, okFill),
    BadgeTone.warn => (warn, warnFill),
    BadgeTone.risk => (risk, riskFill),
    BadgeTone.info => (info, infoFill),
    BadgeTone.gold => (gold, goldFill),
  };

  static BadgeStyle of(BuildContext context) {
    final s = Theme.of(context).extension<BadgeStyle>();
    assert(s != null, 'BadgeStyle missing from the theme: buildWalletTheme and buildDeskTheme add it');
    return s ?? _fallback;
  }

  static const _fallback = BadgeStyle(
    neutral: Color(0xFF8A8A8A),
    neutralFill: Color(0x1A8A8A8A),
    ok: Color(0xFF3DBE6B),
    okFill: Color(0x1F3DBE6B),
    warn: Color(0xFFE0A431),
    warnFill: Color(0x1FE0A431),
    risk: Color(0xFFE05A5A),
    riskFill: Color(0x1FE05A5A),
    info: Color(0xFF5B9BE0),
    infoFill: Color(0x1F5B9BE0),
    gold: Color(0xFFE2B84B),
    goldFill: Color(0x1FE2B84B),
  );

  @override
  BadgeStyle copyWith({double? scale}) => BadgeStyle(
    neutral: neutral,
    neutralFill: neutralFill,
    ok: ok,
    okFill: okFill,
    warn: warn,
    warnFill: warnFill,
    risk: risk,
    riskFill: riskFill,
    info: info,
    infoFill: infoFill,
    gold: gold,
    goldFill: goldFill,
    scale: scale ?? this.scale,
  );

  @override
  BadgeStyle lerp(ThemeExtension<BadgeStyle>? other, double t) {
    if (other is! BadgeStyle) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return BadgeStyle(
      neutral: c(neutral, other.neutral),
      neutralFill: c(neutralFill, other.neutralFill),
      ok: c(ok, other.ok),
      okFill: c(okFill, other.okFill),
      warn: c(warn, other.warn),
      warnFill: c(warnFill, other.warnFill),
      risk: c(risk, other.risk),
      riskFill: c(riskFill, other.riskFill),
      info: c(info, other.info),
      infoFill: c(infoFill, other.infoFill),
      gold: c(gold, other.gold),
      goldFill: c(goldFill, other.goldFill),
      scale: t < 0.5 ? scale : other.scale,
    );
  }
}

/// The badge: 20 dp tall, a 12 dp glyph (or a spinner while [busy]) and the [label] in 11 px
/// semibold, a soft fill in the tone and no border. The label stays on one line and is cut
/// with an ellipsis when the row is narrow; a `Flexible` parent lets it shrink. With a null
/// [label] only the glyph shows and [semanticsLabel] must say the words.
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
  }) : assert(label != null || semanticsLabel != null, 'A glyph-only badge needs semanticsLabel');

  /// The kind of an address as a badge: the method's glyph and its name ("Epicbox",
  /// "Link Payment · HTTP", "Link Payment · Tor"). A fact, so neutral.
  EBadge.kind(RecipientKind kind, {super.key, required AppLocalizations l, this.tooltip})
    : label = switch (kind) {
        RecipientKind.epicbox => l.methodEpicbox,
        RecipientKind.http => l.methodDirectHttp,
        RecipientKind.tor => l.methodDirectTor,
      },
      icon = kindIcon(kind),
      tone = BadgeTone.neutral,
      busy = false,
      dot = false,
      semanticsLabel = null,
      liveRegion = false;

  /// On (ok, filled dot) or off (neutral, hollow dot): [label] carries the word, from the
  /// screen's own strings ("On", "Off", "Always on").
  const EBadge.state(this.label, {super.key, required bool on, this.tooltip, this.liveRegion = false})
    : icon = null,
      tone = on ? BadgeTone.ok : BadgeTone.neutral,
      busy = false,
      dot = true,
      semanticsLabel = null;

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
      semanticsLabel = null;

  final String? label;
  final IconData? icon;
  final BadgeTone tone;

  /// A small spinner in the glyph's place: in progress.
  final bool busy;

  /// A 6 dp dot in the glyph's place: filled for [BadgeTone.ok], a ring otherwise.
  final bool dot;

  /// What a screen reader says instead of [label] (required without one).
  final String? semanticsLabel;

  /// Shown on hover, and on a tap on the phone.
  final String? tooltip;

  /// Announced when it appears or changes.
  final bool liveRegion;

  /// The method glyph of [kind].
  static IconData kindIcon(RecipientKind kind) => switch (kind) {
    RecipientKind.epicbox => EpicGlyphs.epicbox,
    RecipientKind.http => EpicGlyphs.http,
    RecipientKind.tor => EpicGlyphs.tor,
  };

  @override
  Widget build(BuildContext context) {
    final s = BadgeStyle.of(context);
    double px(double v) => (v * s.scale).roundToDouble();
    final (ink, fill) = s.inks(tone);
    final words = label;
    final leading = icon != null || busy || dot;
    final base = Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    Widget? glyph;
    if (busy) {
      glyph = SizedBox.square(
        dimension: px(10),
        child: CircularProgressIndicator(strokeWidth: 1.5, color: ink),
      );
    } else if (dot) {
      final on = tone == BadgeTone.ok;
      glyph = Container(
        width: px(6),
        height: px(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? ink : Colors.transparent,
          border: Border.all(color: ink, width: px(1.5)),
        ),
      );
    } else if (icon != null) {
      glyph = Icon(icon, size: px(12), color: ink);
    }
    Widget badge = Container(
      constraints: BoxConstraints(minHeight: px(20), minWidth: px(20)),
      padding: EdgeInsetsDirectional.fromSTEB(
        leading ? (words == null ? px(4) : px(6)) : px(8),
        0,
        words == null ? px(4) : px(8),
        0,
      ),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(px(999))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?glyph,
          if (glyph != null && words != null) SizedBox(width: px(4)),
          if (words != null)
            Flexible(
              child: Text(
                words,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
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
