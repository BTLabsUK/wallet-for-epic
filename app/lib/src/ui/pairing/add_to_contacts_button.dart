// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../l10n.dart';

const Key addToContactsKey = ValueKey('add-to-contacts');
const Key addToContactsNewKey = ValueKey('add-to-contacts-new');
const Key addToContactsExistingKey = ValueKey('add-to-contacts-existing');

/// Add to contacts for a pairing in no contact: one button, its menu holds Save as a new
/// contact ([onNew]) and Add to a contact ([onExisting]). Null [onNew] and [onExisting] while
/// one runs disable it.
class AddToContactsButton extends StatelessWidget {
  const AddToContactsButton({super.key, required this.onNew, required this.onExisting});

  final VoidCallback? onNew;
  final VoidCallback? onExisting;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final enabled = onNew != null || onExisting != null;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          key: addToContactsNewKey,
          leadingIcon: const Icon(Icons.person_add_alt_outlined),
          onPressed: onNew,
          child: Text(l.pairSaveNewContact),
        ),
        MenuItemButton(
          key: addToContactsExistingKey,
          leadingIcon: const Icon(Icons.person_outline),
          onPressed: onExisting,
          child: Text(l.pairAddToAContact),
        ),
      ],
      builder: (context, controller, _) => FilledButton.tonalIcon(
        key: addToContactsKey,
        onPressed: enabled ? () => controller.isOpen ? controller.close() : controller.open() : null,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: Text(l.txDetailsAddToContacts, textAlign: TextAlign.center),
      ),
    );
  }
}
