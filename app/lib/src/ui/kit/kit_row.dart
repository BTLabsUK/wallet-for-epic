// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The three row heights of the redesign: a list row 62, a settings row 56, a sheet row 48.
enum KitRowSize {
  list(Kit.rowList),
  settings(Kit.rowSettings),
  sheet(Kit.rowSheet);

  const KitRowSize(this.height);

  final double height;
}

/// A row of a [KitGroup] (HANDOFF 7.3): optional [leading] (a [KitAvatar] or [KitIconWell]), a
/// 15/500 [title], one [subtitle] line, and at the end a [value] (dim), a [trailing] widget (a
/// [KitSwitch], an amount), a tick when [selected] or a chevron when [chevron]. A row with
/// [onTap] reads as a button. The text keeps one line and ends in an ellipsis; the title
/// wraps to a second line before it is cut, so a large text size never hides it.
class KitRow extends StatelessWidget {
  const KitRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.value,
    this.trailing,
    this.chevron = false,
    this.selected = false,
    this.onTap,
    this.size = KitRowSize.list,
    this.titleColor,
    this.semanticsId,
    this.semanticsLabel,
    this.toggled,
  });

  /// A row with a switch at the end. Tapping the row flips it.
  factory KitRow.toggle({
    Key? key,
    required String title,
    String? subtitle,
    Widget? leading,
    required bool value,
    required ValueChanged<bool>? onChanged,
    KitRowSize size = KitRowSize.settings,
    String? semanticsId,
  }) => KitRow(
    key: key,
    title: title,
    subtitle: subtitle,
    leading: leading,
    size: size,
    trailing: IgnorePointer(child: ExcludeSemantics(child: KitSwitch(value: value, onChanged: onChanged))),
    onTap: onChanged == null ? null : () => onChanged(!value),
    semanticsId: semanticsId,
    toggled: value,
  );

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// A dim value before the chevron ("Dark", "After 15 minutes").
  final String? value;
  final Widget? trailing;
  final bool chevron;

  /// A tick at the end: the chosen row of a picker.
  final bool selected;
  final VoidCallback? onTap;
  final KitRowSize size;
  final Color? titleColor;
  final String? semanticsId;
  final String? semanticsLabel;

  /// Set by [KitRow.toggle], so a screen reader hears a switch, not a button.
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final end = <Widget>[
      if (value != null)
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(value!, style: KitType.rowSub.copyWith(color: t.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ?trailing,
      if (selected) Icon(KitIcons.check, size: 22, color: t.accentText),
      if (chevron) Icon(KitIcons.chevron, size: 22, color: t.faint),
    ];
    final body = ConstrainedBox(
      constraints: BoxConstraints(minHeight: size.height),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KitType.rowTitle.copyWith(color: titleColor ?? t.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(subtitle!, style: KitType.rowSub.copyWith(color: t.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            for (var i = 0; i < end.length; i++) ...[SizedBox(width: i == 0 ? 10 : 6), end[i]],
          ],
        ),
      ),
    );
    final row = onTap == null
        ? Semantics(container: true, child: body)
        : Semantics(
            button: toggled == null,
            toggled: toggled,
            selected: selected ? true : null,
            label: semanticsLabel,
            // A given label is the whole reading: the texts inside would repeat it.
            hint: semanticsLabel == null ? null : subtitle,
            excludeSemantics: semanticsLabel != null,
            onTap: semanticsLabel == null ? null : onTap,
            child: InkWell(onTap: onTap, child: body),
          );
    return kitId(semanticsId, Material(type: MaterialType.transparency, child: row));
  }
}

/// The rounded square behind a row's icon: 40 px, radius 13, the quiet fill.
class KitIconWell extends StatelessWidget {
  const KitIconWell(this.icon, {super.key, this.color, this.size = Kit.avatar});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(Kit.rAvatar)),
      child: ExcludeSemantics(child: Icon(icon, size: 22, color: color ?? t.dim)),
    );
  }
}

/// The switch of a settings row: 50 × 30, a 24 px knob; on is the text colour with a ground
/// knob, as the desktop's. Gold is the brand and the primary action only.
class KitSwitch extends StatelessWidget {
  const KitSwitch({super.key, required this.value, required this.onChanged, this.semanticsId, this.semanticsLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticsId;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final enabled = onChanged != null;
    const pad = (Kit.switchHeight - Kit.switchKnob) / 2;
    final track = AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
      width: Kit.switchWidth,
      height: Kit.switchHeight,
      padding: const EdgeInsets.all(pad),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? t.text : t.fill,
        borderRadius: BorderRadius.circular(Kit.rPill),
        border: Border.all(color: value ? t.text : t.hair2),
      ),
      child: Container(
        width: Kit.switchKnob - 2,
        height: Kit.switchKnob - 2,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(color: value ? t.bg : t.dim, shape: BoxShape.circle),
      ),
    );
    return kitId(
      semanticsId,
      Semantics(
        toggled: value,
        enabled: enabled,
        label: semanticsLabel,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => onChanged!(!value) : null,
            child: SizedBox(width: Kit.switchWidth, height: Kit.hitMin, child: Center(child: track)),
          ),
        ),
      ),
    );
  }
}
