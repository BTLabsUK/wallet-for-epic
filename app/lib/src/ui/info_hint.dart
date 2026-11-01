// SPDX-License-Identifier: Apache-2.0
/// The phone's explanation marks: a row shows its label only, and the sentence that explains
/// it sits behind a small info icon. A tap opens an info sheet ([InfoSheet]): a small card
/// with the icon, the title (the row's name) and the full explanation, above the navigation
/// bar, closed by a tap outside, a swipe or Back. It is the phone's twin of the desktop's
/// hover card, and never a tooltip: a tooltip near the bottom of a phone screen lands under
/// the navigation bar (android-18). Settings rows, switches and status rows use it; the main
/// view never carries explanation text.
library;

import 'phone_sheet.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import 'theme/tokens.dart';

/// The info icon with [text] as its explanation, [size] square (a 40 dp target inside a row
/// that is itself the 48 dp target). A tap opens [InfoSheet] with [title] (the row's name,
/// required: a sheet with no title reads as a stray sentence) and [icon] beside it; [onHelp]
/// adds "More in Help" under the text, as the desktop's popover does.
class InfoHint extends StatelessWidget {
  const InfoHint(this.text, {super.key, this.size = 40, required this.title, this.icon, this.labelled = true, this.label, this.onHelp});

  final String text;
  final double size;
  final String title;
  final IconData? icon;

  /// What a screen reader calls the icon when the row beside it already carries [title] (a
  /// switch row): "About Undercover", so the icon is not announced as the switch again.
  final String? label;

  /// Opens the Help topic that says more (an explanation longer than a few lines lives there).
  final VoidCallback? onHelp;

  /// False where the row's own title names it already: a disabled row merges the icon into
  /// itself, and its label would say the title twice.
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final glyph = SizedBox.square(
      dimension: size,
      child: Center(child: Icon(Icons.info_outline, size: 18, color: t.dim)),
    );
    // The semantics node carries the tap itself: the row around it is a button too, and a
    // tap sent to this node (a screen reader, a browser with semantics on) must open the
    // hint, not the row.
    void open() => showInfoSheet(context, title: title, text: text, icon: icon, onHelp: onHelp);
    return Semantics(
      button: true,
      label: labelled ? (label ?? title) : null,
      hint: text,
      excludeSemantics: true,
      onTap: open,
      child: InkResponse(radius: size / 2, onTap: open, child: glyph),
    );
  }
}

/// Opens the info sheet for [title] and [text].
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required String text,
  IconData? icon,
  VoidCallback? onHelp,
}) => showPhoneSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => InfoSheet(title: title, text: text, icon: icon, onHelp: onHelp),
);

/// The info card: the icon and the title on one line, the explanation under it at a reading
/// width, and Close. It sits inside the safe area, so a navigation bar never covers it, and a
/// long explanation (large text on a short phone) scrolls under the title with Close still in
/// reach. The desktop's hover card ([EInfoHint] with a title) has the same shape.
class InfoSheet extends StatelessWidget {
  const InfoSheet({super.key, required this.title, required this.text, this.icon, this.onHelp});

  final String title;
  final String text;
  final IconData? icon;

  /// "More in Help": closes the sheet, then opens the topic.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: t.accentText),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(color: t.dim, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onHelp case final help?)
                  TextButton(
                    key: const ValueKey('info-sheet-help'),
                    onPressed: () {
                      Navigator.pop(context);
                      help();
                    },
                    // The desktop popover's words, shared.
                    child: Text(l.deskKitMoreInHelp),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A row title with its [InfoHint] after it: `Text(title)` for a `ListTile.title` that has an
/// explanation. The title keeps the row's text style; the icon is 32 dp square, which keeps
/// the row at its usual height. The sheet is titled [sheetTitle], or [title] itself, with
/// [icon] beside it.
class TitleWithHint extends StatelessWidget {
  const TitleWithHint(this.title, {super.key, required this.hint, this.sheetTitle, this.icon, this.labelled = true, this.hintKey, this.onHelp});

  final String title;
  final String hint;
  final String? sheetTitle;
  final IconData? icon;

  /// [InfoHint.labelled].
  final bool labelled;

  /// The key of the [InfoHint] itself (a tap on the title is the row's).
  final Key? hintKey;

  /// [InfoHint.onHelp].
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(title)),
      const SizedBox(width: 4),
      InfoHint(hint, key: hintKey, size: 32, title: sheetTitle ?? title, icon: icon, labelled: labelled, onHelp: onHelp),
    ],
  );
}

/// A switch row whose title carries an [InfoHint]: a `ListTile` with a `Switch`, not a
/// `SwitchListTile`, because that one merges its semantics and the info icon would vanish
/// into the switch (a screen reader could not reach it, and with semantics on, as in a
/// browser, a tap on the icon toggled the switch). A tap on the row toggles; the icon opens
/// its sheet, titled [sheetTitle] or [title], with [sheetIcon] or the row's [icon] beside it.
class HintSwitchTile extends StatelessWidget {
  const HintSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.sheetTitle,
    this.sheetIcon,
    this.onHelp,
  });

  final IconData icon;
  final String title;

  /// The explanation behind the title's info icon; a plain title without one (the settings
  /// switch row, `settings_rows.dart`).
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? subtitle;
  final String? sheetTitle;
  final IconData? sheetIcon;

  /// [InfoHint.onHelp].
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final tile = ListTile(
      leading: Icon(icon),
      title: hint == null
          ? Text(title)
          : TitleWithHint(
              title,
              hint: hint!,
              sheetTitle: sheetTitle,
              icon: sheetIcon ?? icon,
              // Disabled, the row takes the icon into its own node, which has the title already.
              labelled: onChanged != null,
              onHelp: onHelp,
            ),
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged(!value),
    );
    // Without an info icon the row reads as one switch with its title, as SwitchListTile does.
    return hint == null ? MergeSemantics(child: tile) : tile;
  }
}
