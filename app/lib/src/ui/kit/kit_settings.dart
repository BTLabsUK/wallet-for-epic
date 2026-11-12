// SPDX-License-Identifier: Apache-2.0
/// The small parts the Settings pages share beyond the row and the group (HANDOFF 9): the dim
/// note under a group, the lead line of a page, the tag next to a name and the −/+ stepper.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// A dim 13 note under a group ("The wallet locks by itself after 15 minutes away from the
/// app."), lined up with the group's label.
class KitFootnote extends StatelessWidget {
  const KitFootnote(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 8, Kit.gutter + 4, 0),
    child: Text(text, style: KitType.rowSub.copyWith(color: color ?? context.tokens.faint, height: 1.45)),
  );
}

/// The one line of text under a page's title (Advanced: "Each switch shows one more part of the
/// wallet…"): 15, dim.
class KitLead extends StatelessWidget {
  const KitLead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 6, Kit.gutter + 4, 0),
    child: Text(text, style: KitType.body.copyWith(color: context.tokens.dim, fontSize: 14, height: 1.45)),
  );
}

/// A small neutral tag next to a name or at a row's end ("Experiment").
class KitTag extends StatelessWidget {
  const KitTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rPill)),
      child: Text(label, style: KitType.tag.copyWith(color: t.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// A −, a count and a + in one pill (Confirmations). Each end is a 44 px target; a null
/// callback greys it.
class KitStepper extends StatelessWidget {
  const KitStepper({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.minusLabel,
    required this.plusLabel,
    required this.valueLabel,
    this.minusId,
    this.plusId,
    this.valueKey,
    this.minusKey,
    this.plusKey,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final String minusLabel;
  final String plusLabel;

  /// What a screen reader says for the count ("3 confirmations").
  final String valueLabel;
  final String? minusId;
  final String? plusId;
  final Key? valueKey;
  final Key? minusKey;
  final Key? plusKey;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget end(Key? key, IconData icon, String label, VoidCallback? onTap, String? id) => kitId(
      id,
      Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(Kit.rButtonSmall),
          onTap: onTap,
          child: SizedBox(
            width: Kit.hitMin,
            height: Kit.stepperHeight,
            child: Icon(icon, size: 20, color: onTap == null ? t.faint : t.text),
          ),
        ),
      ),
    );
    return Container(
      width: Kit.stepperWidth,
      height: Kit.stepperHeight,
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rButtonSmall)),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: [
            end(minusKey, KitIcons.remove, minusLabel, onMinus, minusId),
            Expanded(
              child: Semantics(
                label: valueLabel,
                liveRegion: true,
                excludeSemantics: true,
                child: Text('$value', key: valueKey, textAlign: TextAlign.center, style: KitType.rowTitle.copyWith(color: t.text, fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ),
            end(plusKey, KitIcons.add, plusLabel, onPlus, plusId),
          ],
        ),
      ),
    );
  }
}
