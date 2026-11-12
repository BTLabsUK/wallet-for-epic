// SPDX-License-Identifier: Apache-2.0
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n.dart';
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
    this.actionsTop = 18,
    this.titleGap = 14,
    this.buttonsGap = 10,
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

  /// The space above the buttons.
  final double actionsTop;

  /// Under the title; a sheet whose first row carries its own top padding takes less.
  final double titleGap;
  final double buttonsGap;

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
          // `.sheet` padding-bottom 34 is the home-indicator zone: the inset the SafeArea gives
          // is part of it, a phone with no inset keeps 16. The inset is read from the view: the
          // SafeArea of [showPhoneSheet] above has already taken it out of the MediaQuery.
          padding: EdgeInsets.only(bottom: _viewInsetBottom(context) > 0 ? 0 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KitGrabber(),
              if (title != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, titleGap),
                  child: Semantics(header: true, child: Text(title!, style: KitType.sheetTitle.copyWith(color: t.text))),
                ),
              ?child,
              if (primaryButton != null || secondaryButton != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(Kit.gutter, actionsTop, Kit.gutter, 0),
                  child: Column(
                    children: [
                      ?primaryButton,
                      if (primaryButton != null && secondaryButton != null) SizedBox(height: buttonsGap),
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

double _viewInsetBottom(BuildContext context) {
  final view = View.maybeOf(context);
  return view == null ? MediaQuery.viewPaddingOf(context).bottom : view.padding.bottom / view.devicePixelRatio;
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
  builder: (route) {
    // The phone sheet's SafeArea has taken the bottom inset; the sheet still sees it as view
    // padding, so its own 16 for a phone with no inset is not added on top (`.sheet` 34).
    final inset = MediaQuery.viewPaddingOf(route).bottom;
    return Builder(
      builder: (below) {
        final mq = MediaQuery.of(below);
        return MediaQuery(
          data: mq.copyWith(viewPadding: mq.viewPadding.copyWith(bottom: inset)),
          child: builder(below),
        );
      },
    );
  },
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
/// choice and closes the sheet, so there is no Save button. [onSelected] may return a future:
/// the sheet waits for it, and when it fails the sheet stays open with a line saying the choice
/// was not saved. Use [KitPickerSheet.show].
class KitPickerSheet<T> extends StatefulWidget {
  const KitPickerSheet({super.key, required this.title, required this.choices, required this.selected, required this.onSelected, this.subtitle, this.note});

  final String title;
  final List<KitChoice<T>> choices;
  final T? selected;

  /// Saves the choice; a returned future is awaited (a throw keeps the sheet open).
  final FutureOr<void> Function(T) onSelected;

  /// A line under the title saying what the choice does, and a note under the rows.
  final String? subtitle;
  final String? note;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<KitChoice<T>> choices,
    required T? selected,
    FutureOr<void> Function(T)? onSelected,
    String? subtitle,
    String? note,
  }) => showKitSheet<T>(
    context: context,
    builder: (sheetContext) => KitPickerSheet<T>(
      title: title,
      choices: choices,
      selected: selected,
      subtitle: subtitle,
      note: note,
      onSelected: (v) async {
        if (onSelected != null) await Future<void>.sync(() => onSelected(v));
        if (sheetContext.mounted) Navigator.of(sheetContext).pop(v);
      },
    ),
  );

  @override
  State<KitPickerSheet<T>> createState() => _KitPickerSheetState<T>();
}

class _KitPickerSheetState<T> extends State<KitPickerSheet<T>> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _pick(T value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await Future<void>.sync(() => widget.onSelected(value));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final w = widget;
    return KitSheet(
      title: w.title,
      // A subtitle sits 8 under the title (`.hint`), which already leaves 14.
      titleGap: w.subtitle != null ? 8 : 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (w.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(w.subtitle!, style: KitType.hint.copyWith(color: t.dim)),
            ),
          KitGroup(
            onSheet: true,
            dividerInset: Kit.dividerInsetPlain,
            children: [
              for (final c in w.choices)
                KitRow(
                  title: c.title,
                  subtitle: c.subtitle,
                  leading: c.leading,
                  size: KitRowSize.sheet,
                  selected: c.value == w.selected,
                  onTap: () => _pick(c.value),
                  semanticsId: c.semanticsId,
                ),
            ],
          ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Semantics(liveRegion: true, child: Text(context.l10n.phoneKitPickerSaveFailed, style: KitType.rowSub.copyWith(color: t.risk))),
            ),
          if (w.note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(w.note!, style: KitType.rowSub.copyWith(color: t.dim)),
            ),
        ],
      ),
    );
  }
}
