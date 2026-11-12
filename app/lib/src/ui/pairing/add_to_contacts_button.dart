// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../trust_ids.dart';
import '../kit/kit_button.dart';
import '../kit/kit_group.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_row.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_support.dart' show kitId;
import '../kit/kit_tokens.dart';

const Key addToContactsKey = ValueKey('add-to-contacts');
const Key addToContactsNewKey = ValueKey('add-to-contacts-new');
const Key addToContactsExistingKey = ValueKey('add-to-contacts-existing');

/// Add to contacts for a pairing in no contact: one button, its sheet holds Save as a new
/// contact ([onNew]) and Add to a contact ([onExisting]). Null [onNew] and [onExisting] while
/// one runs disable it.
class AddToContactsButton extends StatelessWidget {
  const AddToContactsButton({super.key, required this.onNew, required this.onExisting});

  final VoidCallback? onNew;
  final VoidCallback? onExisting;

  Future<void> _open(BuildContext context) async {
    final l = context.l10n;
    final pick = await showKitSheet<VoidCallback>(
      context: context,
      builder: (ctx) => kitId(
        TrustIds.pairflowAddSheet,
        KitSheet(
          title: l.txDetailsAddToContacts,
          child: KitGroup(
            onSheet: true,
            dividerInset: Kit.dividerInsetPlain,
            children: [
              if (onNew case final go?)
                KitRow(
                  key: addToContactsNewKey,
                  title: l.pairSaveNewContact,
                  leading: const KitIconWell(KitIcons.add),
                  size: KitRowSize.sheet,
                  semanticsId: TrustIds.pairflowAddNew,
                  onTap: () => Navigator.of(ctx).pop(go),
                ),
              if (onExisting case final go?)
                KitRow(
                  key: addToContactsExistingKey,
                  title: l.pairAddToAContact,
                  leading: const KitIconWell(KitIcons.contact),
                  size: KitRowSize.sheet,
                  semanticsId: TrustIds.pairflowAddExisting,
                  onTap: () => Navigator.of(ctx).pop(go),
                ),
            ],
          ),
        ),
      ),
    );
    pick?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onNew != null || onExisting != null;
    return KitButton(
      key: addToContactsKey,
      label: context.l10n.txDetailsAddToContacts,
      icon: KitIcons.contact,
      kind: KitButtonKind.quiet,
      semanticsId: TrustIds.pairflowAddButton,
      onPressed: enabled ? () => _open(context) : null,
    );
  }
}
