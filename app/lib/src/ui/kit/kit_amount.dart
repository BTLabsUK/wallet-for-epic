// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../tip.dart';
import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The amount being typed (wallet.css `.big`): the figure at 68 (50 when it is longer than
/// [_longFrom] characters) with the EPIC [unit] after it in gold, 13 (12 when long) and 10 (6)
/// from the top of the line, and under it one fiat line with the swap chevrons. The figure
/// groups its whole part by thousands (display only). A [placeholder] figure ("0") shows in faint. With [dimFraction]
/// the digits from [point] on are drawn at 42 %, as Max shows an exact figure.
class KitAmountDisplay extends StatelessWidget {
  const KitAmountDisplay({
    super.key,
    required this.amount,
    required this.unit,
    this.fiat,
    this.onSwap,
    this.swapId,
    this.semanticsId,
    this.dimFraction = false,
    this.point = '.',
    this.swapReachBelow = 8,
  });

  final String amount;
  final String unit;

  /// The other currency ("≈ $25.82"); hidden when null.
  final String? fiat;
  final VoidCallback? onSwap;

  /// A figure longer than this is drawn in the smaller size.
  static const int _longFrom = 8;
  final String? swapId;
  final String? semanticsId;
  final bool dimFraction;

  /// The decimal separator the figure is typed with.
  final String point;

  /// How far the swap target reaches under the fiat line: the page takes it from the gap below
  /// (16 gives the 48 of a touch).
  final double swapReachBelow;

  /// [text] with its whole part (before [point]) grouped in threes, as the frames show 1,300.
  static String _grouped(String text, String point) {
    final at = text.indexOf(point);
    final whole = at < 0 ? text : text.substring(0, at);
    if (whole.length < 4 || !RegExp(r'^\d+$').hasMatch(whole)) return text;
    final sep = point == ',' ? '.' : ',';
    final out = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) out.write(sep);
      out.write(whole[i]);
    }
    return '$out${at < 0 ? '' : text.substring(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final empty = amount.isEmpty || amount == '0';
    final long = amount.length > _longFrom;
    final color = empty ? t.faint : t.text;
    final style = (long ? KitType.amountEntryLong : KitType.amountEntry).copyWith(color: color);
    final shown = _grouped(amount.isEmpty ? '0' : amount, point);
    final cut = dimFraction ? shown.lastIndexOf(point) : -1;
    final figure = cut <= 0
        ? Text(shown, style: style, textScaler: TextScaler.noScaling)
        : Text.rich(
            TextSpan(
              style: style,
              children: [
                TextSpan(text: shown.substring(0, cut)),
                TextSpan(text: shown.substring(cut), style: TextStyle(color: color.withValues(alpha: 0.42))),
              ],
            ),
            textScaler: TextScaler.noScaling,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        kitId(
          semanticsId,
          Semantics(
            label: '$amount $unit',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    figure,
                    // `.big u`: margin-left 10, top-aligned and moved down 10 (6 with the long figure).
                    Padding(
                      padding: EdgeInsets.only(left: 10, top: long ? 6 : 10),
                      child: Text(
                        unit,
                        style: KitType.unit.copyWith(color: t.accentText, fontSize: long ? 12 : 13, height: 1),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (fiat != null)
          kitId(
              swapId,
              Tip(
                context.l10n.phoneKitSwapCurrency,
                excludeFromSemantics: true,
                child: Semantics(
                button: onSwap != null,
                label: context.l10n.phoneKitSwapCurrency,
                excludeSemantics: true,
                onTap: onSwap,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSwap,
                  // `.lbl` at 15: the figure and the chevrons, 6 apart. The target is 14 above the
                  // line (the 6 gap over it and the frame's 8) and [swapReachBelow] under it.
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(Kit.gutter, 14, Kit.gutter, swapReachBelow),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Larger text shrinks the figure to fit beside the chevrons.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(fiat!, maxLines: 1, style: KitType.rowSub.copyWith(color: t.dim, fontSize: 15, height: 1.2)),
                          ),
                        ),
                        if (onSwap != null) ...[const SizedBox(width: 6), Icon(KitIcons.swap, size: 15, color: t.dim)],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
      ],
    );
  }
}

/// "Available 1,284.7321 [Max]" (wallet.css `.avail`): a 46 px pill, as wide as its content and
/// centred, with the figure in mono and a Max pill at the end. It turns risk-red when the typed
/// amount is [over]. [maxOn] fills Max in gold, with a check, while it is the amount in use.
/// The figure is formatted by the screen.
class KitAvailableBar extends StatelessWidget {
  const KitAvailableBar({super.key, required this.available, required this.onMax, this.over = false, this.maxOn = false, this.maxId, this.margin = const EdgeInsets.symmetric(horizontal: Kit.gutter)});

  final String available;
  final VoidCallback? onMax;
  final bool over;
  final bool maxOn;
  final String? maxId;
  final EdgeInsetsGeometry margin;

  /// The bar is drawn 46 high in a 48 slot: 1 above and below.
  static const double _inset = (Kit.hitTarget - Kit.availableBar) / 2;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return Padding(
      padding: margin,
      child: Center(
        // The bar is drawn 46 high inside a 48 slot, so Max's target is the 48 of a touch.
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: _inset,
              bottom: _inset,
              child: DecoratedBox(decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rPill))),
            ),
            // The outline is drawn over the bar, so it takes no room from Max's target.
            Positioned.fill(
              top: _inset,
              bottom: _inset,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Kit.rPill),
                    border: Border.all(color: over ? t.risk.withValues(alpha: 0.45) : t.hair),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Semantics(
                      container: true,
                      label: '${l.phoneKitAvailable} $available',
                      excludeSemantics: true,
                      // Larger text shrinks the pair to fit beside Max rather than overflowing.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.phoneKitAvailable, style: KitType.body.copyWith(color: over ? t.risk : t.dim, fontSize: 14)),
                            const SizedBox(width: 10),
                            Text(available, style: KitType.rowAmount.copyWith(color: over ? t.risk : t.text), maxLines: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  kitId(
                    maxId,
                    Semantics(
                      container: true,
                      button: true,
                      toggled: maxOn,
                      label: l.sendMax,
                      excludeSemantics: true,
                      onTap: onMax,
                      // The touch target is the bar's whole height; the pill is drawn inside.
                      child: SizedBox(
                        height: Kit.hitTarget,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onMax,
                          child: Center(
                            widthFactor: 1,
                            child: Material(
                              color: maxOn ? t.accent : Colors.transparent,
                              shape: StadiumBorder(side: BorderSide(color: maxOn ? t.accent : t.goldLine)),
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: onMax,
                                child: SizedBox(
                                  height: Kit.maxPill,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Center(
                                      widthFactor: 1,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (maxOn) ...[Icon(KitIcons.check, size: 14, color: t.accentInk), const SizedBox(width: 5)],
                                          Text(l.sendMax, style: KitType.buttonSmall.copyWith(color: maxOn ? t.accentInk : t.accentText)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Leaves 1,271.2 after the 0.0125 fee" (wallet.css `.after`): 13 dim, centred, the figures in
/// mono. [bad] draws it in risk, when the amount and the fee do not fit.
class KitLeavesLine extends StatelessWidget {
  const KitLeavesLine({super.key, required this.amount, required this.fee, this.bad = false});

  /// What stays in the wallet, formatted by the screen.
  final String amount;
  final String fee;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return KitAfterLine(line: context.l10n.phoneKitLeaves(KitAfterLine.first, fee), figures: [amount], bad: bad);
  }
}

/// A sentence under the amount (`.after`): [line] holds [first] and [second] where the figures
/// [figures] go, which are drawn in mono and in the text colour (risk when [bad]).
class KitAfterLine extends StatelessWidget {
  const KitAfterLine({super.key, required this.line, this.figures = const [], this.bad = false, this.textKey, this.live = false, this.oneLine = false});

  static const first = '\u0001';
  static const second = '\u0002';

  final String line;
  final List<String> figures;
  final bool bad;

  /// Key of the line's text.
  final Key? textKey;

  /// Announces the line when it appears.
  final bool live;

  /// Keeps the line on one row: it shrinks to fit the width, never wraps (the frame's over line).
  final bool oneLine;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = bad ? t.risk : t.dim;
    final base = KitType.rowSub.copyWith(color: color);
    final mono = KitType.rowSub.copyWith(color: bad ? t.risk : t.text, fontFamily: t.monoFamily, letterSpacing: -0.26, fontFeatures: const [FontFeature.tabularFigures()]);
    final spans = <InlineSpan>[];
    var rest = line;
    while (rest.isNotEmpty) {
      final ia = rest.indexOf(first), ib = rest.indexOf(second);
      final hits = [ia, ib].where((i) => i >= 0).toList()..sort();
      if (hits.isEmpty) {
        spans.add(TextSpan(text: rest));
        break;
      }
      final i = hits.first;
      if (i > 0) spans.add(TextSpan(text: rest.substring(0, i)));
      final n = i == ia ? 0 : 1;
      spans.add(TextSpan(text: n < figures.length ? figures[n] : '', style: mono));
      rest = rest.substring(i + 1);
    }
    var spoken = line;
    for (var n = 0; n < figures.length; n++) {
      spoken = spoken.replaceAll(n == 0 ? first : second, figures[n]);
    }
    return Semantics(
      container: true,
      liveRegion: live || bad,
      label: spoken,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: oneLine
            ? FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(TextSpan(style: base, children: spans), key: textKey, maxLines: 1, softWrap: false, textAlign: TextAlign.center),
              )
            : Text.rich(TextSpan(style: base, children: spans), key: textKey, textAlign: TextAlign.center),
      ),
    );
  }
}
