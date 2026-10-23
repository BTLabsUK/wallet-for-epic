/// The phone's explanation marks: a row shows its label only, and the sentence that explains
/// it sits behind a small info icon. A plain hint is a tooltip (a tap or a long press shows
/// it, themed dark like every tooltip); a hint with a [InfoHint.title] opens an info sheet,
/// a small card with the icon, the title and the lines, the phone's twin of the desktop's
/// hover card. Settings rows, switches and status rows use it; the main view never carries
/// explanation text.
library;

import 'package:flutter/material.dart';

import '../l10n.dart';
import 'theme/tokens.dart';

/// The info icon with [text] as its explanation, [size] square (a 40 dp target inside a row
/// that is itself the 48 dp target). With a [title], a tap opens [InfoSheet] instead of a
/// tooltip, with [icon] beside the title.
class InfoHint extends StatelessWidget {
  const InfoHint(this.text, {super.key, this.size = 40, this.title, this.icon});

  final String text;
  final double size;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final glyph = SizedBox.square(
      dimension: size,
      child: Center(child: Icon(Icons.info_outline, size: 18, color: t.dim)),
    );
    final title = this.title;
    if (title != null) {
      return Semantics(
        button: true,
        label: title,
        hint: text,
        excludeSemantics: true,
        child: InkResponse(
          radius: size / 2,
          onTap: () => showInfoSheet(context, title: title, text: text, icon: icon),
          child: glyph,
        ),
      );
    }
    return Tooltip(
      message: text,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: Semantics(button: true, child: glyph),
    );
  }
}

/// Opens the info sheet for [title] and [text].
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required String text,
  IconData? icon,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => InfoSheet(title: title, text: text, icon: icon),
);

/// The info card: the icon and the title on one line, the explanation under it at a reading
/// width, and Close. The desktop's hover card ([EInfoHint] with a title) has the same shape.
class InfoSheet extends StatelessWidget {
  const InfoSheet({super.key, required this.title, required this.text, this.icon});

  final String title;
  final String text;
  final IconData? icon;

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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: t.dim, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.commonClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row title with its [InfoHint] after it: `Text(title)` for a `ListTile.title` that has an
/// explanation. The title keeps the row's text style; the icon is 32 dp square, which keeps
/// the row at its usual height. [sheetTitle] and [icon] make the hint an info sheet.
class TitleWithHint extends StatelessWidget {
  const TitleWithHint(this.title, {super.key, required this.hint, this.sheetTitle, this.icon});

  final String title;
  final String hint;
  final String? sheetTitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(title)),
      const SizedBox(width: 4),
      InfoHint(hint, size: 32, title: sheetTitle, icon: icon),
    ],
  );
}

/// A switch row whose title carries an [InfoHint]: a `ListTile` with a `Switch`, not a
/// `SwitchListTile`, because that one merges its semantics and the info icon would vanish
/// into the switch (a screen reader could not reach it, and with semantics on, as in a
/// browser, a tap on the icon toggled the switch). A tap on the row toggles; the icon opens
/// its hint.
class HintSwitchTile extends StatelessWidget {
  const HintSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.sheetTitle,
    this.sheetIcon,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? subtitle;
  final String? sheetTitle;
  final IconData? sheetIcon;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return ListTile(
      leading: Icon(icon),
      title: TitleWithHint(title, hint: hint, sheetTitle: sheetTitle, icon: sheetIcon),
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged(!value),
    );
  }
}
