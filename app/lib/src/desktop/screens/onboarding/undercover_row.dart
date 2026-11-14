// SPDX-License-Identifier: Apache-2.0
/// Welcome's Tor only switch (Tor builds): the first connection is already made through Tor.
library;

import 'package:flutter/material.dart';

import '../../../ui/status_icons.dart' show EpicGlyphs;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The switch's key, for tests.
const Key deskUndercoverKey = ValueKey('welcome-undercover');

/// What Tor only from the start does.
Future<void> showUndercoverHelp(BuildContext context) => showEDialog<void>(
  context,
  builder: (context) {
    final l = context.l10n;
    return EDialog(
      title: l.undercoverTitle,
      icon: EIcons.help,
      description: l.undercoverHelp,
      actions: [EButton(label: l.commonOk, autofocus: true, onPressed: () => Navigator.pop(context))],
    );
  },
);

/// Tor only from the start: a hairline and one quiet line (the Tor mark, lit when on, the name,
/// its ⓘ; the line is the toggle).
class DeskUndercoverRow extends StatelessWidget {
  const DeskUndercoverRow({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final title = l.undercoverTitle;
    final onChanged = this.onChanged;
    // A hairline, then one quiet centred line: the Tor mark, dim while off and lit when on,
    // "Tor only" and its ⓘ. The line is the toggle: a click, or Enter or Space once focused.
    void toggle() => onChanged?.call(!value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, thickness: 1, color: c.line),
        SizedBox(height: Sp.x2),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Semantics(
                  container: true,
                  toggled: value,
                  label: title,
                  excludeSemantics: true,
                  onTap: onChanged == null ? null : toggle,
                  child: FocusableActionDetector(
                    enabled: onChanged != null,
                    mouseCursor: onChanged == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
                    actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => toggle())},
                    child: Builder(
                      builder: (context) => GestureDetector(
                        key: deskUndercoverKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: onChanged == null ? null : toggle,
                        child: FocusRing(
                          focused: Focus.of(context).hasFocus,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: 40.u),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Sp.x3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration: Dur.base,
                                    child: Icon(EpicGlyphs.tor, key: ValueKey(value), size: 18.u, color: value ? c.accentText : c.faint),
                                  ),
                                  SizedBox(width: Sp.x2),
                                  Flexible(child: Text(title, style: context.ts.small.copyWith(color: value ? c.text : c.dim))),
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
              EIconButton(icon: EIcons.info, label: l.deskUndercoverAbout, size: EBtnSize.inline, onPressed: () => showUndercoverHelp(context)),
            ],
          ),
        ),
      ],
    );
  }
}
