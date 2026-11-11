// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../phone_sheet.dart';
import '../theme/tokens.dart';
import 'kit_button.dart';
import 'kit_row.dart';
import 'kit_group.dart';
import 'kit_tokens.dart';

/// The grabber of a sheet: 36 × 5, 16 below it.
class KitGrabber extends StatelessWidget {
  const KitGrabber({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Center(
        child: Container(
          width: Kit.grabberWidth,
          height: Kit.grabberHeight,
          decoration: BoxDecoration(color: context.tokens.text.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(3)),
        ),
      ),
    ),
  );
}

/// The inside of a sheet (HANDOFF 7.5): the grabber, a 20 [title], the [child] (a group, text, a
/// field), then a gold [primary] button and an optional quiet [secondary] below it. Scrolls when
/// the content is taller than the screen. Show it with [showKitSheet]. The sheet's own ground,
/// 28 top radius and scrim come from the theme.
class KitSheet extends StatelessWidget {
  const KitSheet({
    super.key,
    this.title,
    this.child,
    this.primary,
    this.secondary,
    this.primaryLabel,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
    this.primaryId,
    this.secondaryId,
    this.primaryKind = KitButtonKind.gold,
  });

  final String? title;
  final Widget? child;

  /// A custom primary/secondary widget instead of the labelled buttons.
  final Widget? primary;
  final Widget? secondary;
  final String? primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final String? primaryId;
  final String? secondaryId;
  final KitButtonKind primaryKind;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primaryButton = primary ??
        (primaryLabel == null
            ? null
            : KitButton(label: primaryLabel!, onPressed: onPrimary, kind: primaryKind, semanticsId: primaryId));
    final secondaryButton = secondary ??
        (secondaryLabel == null
            ? null
            : KitButton(label: secondaryLabel!, onPressed: onSecondary, kind: KitButtonKind.quiet, semanticsId: secondaryId));
    return ColoredBox(
      color: t.sheet,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KitGrabber(),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Semantics(header: true, child: Text(title!, style: KitType.sheetTitle.copyWith(color: t.text))),
                ),
              ?child,
              if (primaryButton != null || secondaryButton != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Kit.gutter, 18, Kit.gutter, 0),
                  child: Column(
                    children: [
                      ?primaryButton,
                      if (primaryButton != null && secondaryButton != null) const SizedBox(height: 10),
                      ?secondaryButton,
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

/// Opens [builder]'s content as a redesign sheet over [showPhoneSheet], so the bottom inset
/// stays clear. The theme gives the ground, the 28 radius and the scrim.
Future<T?> showKitSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) => showPhoneSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  builder: builder,
);

/// One choice of a [KitPickerSheet].
class KitChoice<T> {
  const KitChoice({required this.value, required this.title, this.subtitle, this.leading, this.semanticsId});

  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? semanticsId;
}

/// A picker (HANDOFF 7.5): a title and rows with a tick on the chosen one. A tap saves the
/// choice and closes the sheet, so there is no Save button. Use [KitPickerSheet.show].
class KitPickerSheet<T> extends StatelessWidget {
  const KitPickerSheet({super.key, required this.title, required this.choices, required this.selected, required this.onSelected});

  final String title;
  final List<KitChoice<T>> choices;
  final T? selected;
  final ValueChanged<T> onSelected;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<KitChoice<T>> choices,
    required T? selected,
    ValueChanged<T>? onSelected,
  }) => showKitSheet<T>(
    context: context,
    builder: (sheetContext) => KitPickerSheet<T>(
      title: title,
      choices: choices,
      selected: selected,
      onSelected: (v) {
        onSelected?.call(v);
        Navigator.of(sheetContext).pop(v);
      },
    ),
  );

  @override
  Widget build(BuildContext context) => KitSheet(
    title: title,
    child: KitGroup(
      onSheet: true,
      dividerInset: Kit.dividerInsetPlain,
      children: [
        for (final c in choices)
          KitRow(
            title: c.title,
            subtitle: c.subtitle,
            leading: c.leading,
            size: KitRowSize.sheet,
            selected: c.value == selected,
            onTap: () => onSelected(c.value),
            semanticsId: c.semanticsId,
          ),
      ],
    ),
  );
}
