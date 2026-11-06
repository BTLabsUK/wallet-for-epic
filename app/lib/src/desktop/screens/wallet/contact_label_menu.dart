// SPDX-License-Identifier: Apache-2.0
/// The desktop's label picker: a small menu anchored on the avatar's corner mark. The label is
/// local to this wallet's user (see [ContactLabel]).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../contact_label.dart';
import '../../../ui/contact_label_mark.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

ValueKey<String> deskContactLabelItemKey(ContactLabel label) => ValueKey('desk-contact-label-${label.name}');

/// Builds [builder] with a callback that opens the label menu under it; choosing a row calls
/// [onPicked] (also for the label already set, which does nothing there).
class ContactLabelMenu extends StatelessWidget {
  const ContactLabelMenu({super.key, required this.current, required this.onPicked, required this.builder});

  final ContactLabel current;
  final ValueChanged<ContactLabel> onPicked;
  final Widget Function(BuildContext context, VoidCallback open) builder;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return MenuAnchor(
      consumeOutsideTap: true,
      menuChildren: [
        for (final label in ContactLabel.values)
          MenuItemButton(
            key: deskContactLabelItemKey(label),
            onPressed: () => onPicked(label),
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(220.u, 40.u)),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.u))),
              backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) ? c.s3 : null),
            ),
            leadingIcon: ContactLabelGlyph(label, size: Ctl.iconSm, color: label == current ? c.accent : c.dim),
            trailingIcon: label == current ? Icon(EIcons.check, size: Ctl.iconSm, color: c.accent) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(contactLabelName(l, label), style: ts.body),
                if (label == ContactLabel.wallet) ...[SizedBox(width: Sp.x2), Text(l.deskConLabelDefault, style: ts.small)],
              ],
            ),
          ),
      ],
      builder: (context, controller, _) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): controller.close},
        child: builder(context, () => controller.isOpen ? controller.close() : controller.open()),
      ),
    );
  }
}

/// The Label row of the Save in your contacts dialog: the chosen label, opening the menu.
class ContactLabelField extends StatelessWidget {
  const ContactLabelField({super.key, required this.value, required this.onChanged});

  final ContactLabel value;
  final ValueChanged<ContactLabel> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return ContactLabelMenu(
      current: value,
      onPicked: onChanged,
      builder: (context, open) => Semantics(
        button: true,
        label: '${l.deskConLabelTitle}: ${contactLabelName(l, value)}',
        child: ExcludeSemantics(
          child: EInkWell(
            onTap: open,
            borderRadius: BorderRadius.circular(Rad.sm),
            child: Container(
              constraints: BoxConstraints(minHeight: 40.u),
              padding: EdgeInsets.symmetric(horizontal: Sp.x3),
              decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
              child: Row(
                children: [
                  ContactLabelGlyph(value, size: Ctl.iconSm, color: c.dim),
                  SizedBox(width: Sp.x2),
                  Expanded(child: Text(contactLabelName(l, value), style: ts.body)),
                  Icon(EIcons.chevronDown, size: Ctl.iconSm, color: c.dim),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
