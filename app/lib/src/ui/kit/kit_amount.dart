// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_headers.dart' show KitIconButton;
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The amount being typed (HANDOFF 7.7): the figure at 68 (50 when it is longer than
/// [longFrom] characters) with the EPIC [unit] after it in gold, and under it one fiat line
/// with a swap button. The figure turns risk-red when [over]. A [placeholder] figure ("0")
/// shows in faint.
class KitAmountDisplay extends StatelessWidget {
  const KitAmountDisplay({
    super.key,
    required this.amount,
    required this.unit,
    this.fiat,
    this.onSwap,
    this.over = false,
    this.longFrom = 8,
    this.swapId,
    this.semanticsId,
  });

  final String amount;
  final String unit;

  /// The other currency ("≈ $25.82"); hidden when null.
  final String? fiat;
  final VoidCallback? onSwap;
  final bool over;
  final int longFrom;
  final String? swapId;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final empty = amount.isEmpty || amount == '0';
    final style = (amount.length > longFrom ? KitType.amountEntryLong : KitType.amountEntry).copyWith(
      color: over ? t.risk : (empty ? t.faint : t.text),
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
                  // `.big u`: 13, aligned to the top of the line and 10 down, 10 after the figure.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(amount.isEmpty ? '0' : amount, style: style, textScaler: TextScaler.noScaling),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(unit, style: KitType.unit.copyWith(color: t.accentText, fontSize: 13, height: 1), textScaler: TextScaler.noScaling),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (fiat != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fiat!, style: KitType.rowTitle.copyWith(color: t.dim, fontWeight: FontWeight.w400)),
                if (onSwap != null) KitIconButton(icon: KitIcons.swap, label: context.l10n.phoneKitSwapCurrency, onPressed: onSwap, color: t.dim, semanticsId: swapId),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Available 1,284.7321 [Max]" (HANDOFF 7.7): a 46 px pill with the figure in mono and a Max
/// pill at the end. It turns risk-red when the typed amount is [over]. [maxOn] fills Max in
/// gold while it is the amount in use. The figure is formatted by the screen.
class KitAvailableBar extends StatelessWidget {
  const KitAvailableBar({super.key, required this.available, required this.onMax, this.over = false, this.maxOn = false, this.maxId, this.margin = const EdgeInsets.symmetric(horizontal: Kit.gutter)});

  final String available;
  final VoidCallback? onMax;
  final bool over;
  final bool maxOn;
  final String? maxId;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return Padding(
      padding: margin,
      child: Container(
        height: Kit.availableBar,
        padding: const EdgeInsetsDirectional.only(start: 16, end: 6),
        decoration: BoxDecoration(
          color: t.fill,
          borderRadius: BorderRadius.circular(Kit.rPill),
          border: Border.all(color: over ? t.risk.withValues(alpha: 0.45) : t.hair),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: '${l.phoneKitAvailable} $available',
                excludeSemantics: true,
                child: Row(
                  children: [
                    Text(l.phoneKitAvailable, style: KitType.body.copyWith(color: over ? t.risk : t.dim, fontSize: 14)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        available,
                        style: KitType.rowAmount.copyWith(color: over ? t.risk : t.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            kitId(
              maxId,
              Semantics(
                button: true,
                toggled: maxOn,
                label: l.sendMax,
                excludeSemantics: true,
                onTap: onMax,
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
                          child: Text(l.sendMax, style: KitType.buttonSmall.copyWith(color: maxOn ? t.accentInk : t.accentText)),
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
    );
  }
}

/// "Leaves 1,271.2 after the 0.0125 fee" (HANDOFF 7.7): 13 dim, centred, the two figures in
/// mono. [bad] draws it in risk, when the amount and the fee do not fit.
class KitLeavesLine extends StatelessWidget {
  const KitLeavesLine({super.key, required this.amount, required this.fee, this.bad = false});

  /// What stays in the wallet, formatted by the screen.
  final String amount;
  final String fee;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = bad ? t.risk : t.dim;
    final base = KitType.rowSub.copyWith(color: color);
    final mono = KitType.rowSub.copyWith(color: bad ? t.risk : t.text, fontFamily: t.monoFamily, fontFeatures: const [FontFeature.tabularFigures()]);
    // The localised sentence has {amount} and {fee} in some order; split it on markers.
    const a = '\u0001', f = '\u0002';
    final line = context.l10n.phoneKitLeaves(a, f);
    final spans = <InlineSpan>[];
    var rest = line;
    while (rest.isNotEmpty) {
      final ia = rest.indexOf(a), ifee = rest.indexOf(f);
      final hits = [ia, ifee].where((i) => i >= 0).toList()..sort();
      if (hits.isEmpty) {
        spans.add(TextSpan(text: rest));
        break;
      }
      final i = hits.first;
      if (i > 0) spans.add(TextSpan(text: rest.substring(0, i)));
      spans.add(TextSpan(text: i == ia ? amount : fee, style: mono));
      rest = rest.substring(i + 1);
    }
    return Semantics(
      container: true,
      liveRegion: bad,
      label: line.replaceAll(a, amount).replaceAll(f, fee),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: Text.rich(TextSpan(style: base, children: spans), textAlign: TextAlign.center),
      ),
    );
  }
}
