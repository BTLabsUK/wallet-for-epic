// SPDX-License-Identifier: Apache-2.0
/// The phone's label picker: a bottom sheet of the four labels with the current one checked.
/// The label is local to this wallet's user (see [ContactLabel]).
library;

import 'package:flutter/material.dart';

import '../contact_label.dart';
import '../l10n.dart';
import 'contact_label_mark.dart';
import 'phone_sheet.dart';
import 'theme/tokens.dart';

const contactLabelSheetKey = ValueKey('contact-label-sheet');
ValueKey<String> contactLabelRowKey(ContactLabel label) => ValueKey('contact-label-${label.name}');

/// Asks for a label; null when the sheet is dismissed (the label stays as it is).
Future<ContactLabel?> showContactLabelPicker(BuildContext context, ContactLabel current) => showPhoneSheet<ContactLabel>(
  context: context,
  showDragHandle: true,
  builder: (context) => ContactLabelSheet(current: current),
);

class ContactLabelSheet extends StatelessWidget {
  const ContactLabelSheet({super.key, required this.current});

  final ContactLabel current;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return SingleChildScrollView(
      key: contactLabelSheetKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Semantics(header: true, child: Text(l.deskConLabelTitle, style: Theme.of(context).textTheme.titleMedium)),
          ),
          for (final label in ContactLabel.values)
            ListTile(
              key: contactLabelRowKey(label),
              selected: label == current,
              selectedColor: t.accentText,
              leading: ContactLabelGlyph(label, size: 24, color: label == current ? t.accentText : t.dim),
              title: Text(contactLabelName(l, label)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label == ContactLabel.wallet)
                    Text(l.deskConLabelDefault, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.faint)),
                  if (label == current) ...[
                    if (label == ContactLabel.wallet) const SizedBox(width: 8),
                    Icon(Icons.check, color: t.accentText),
                  ],
                ],
              ),
              onTap: () => Navigator.pop(context, label),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
