// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models.dart' show PairingRecord;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'pair_screens.dart' show deskPutPairingInContacts;

const Key deskAddToContactsKey = ValueKey('desk-add-to-contacts');
const Key deskAddToContactsNewKey = ValueKey('desk-add-to-contacts-new');
const Key deskAddToContactsExistingKey = ValueKey('desk-add-to-contacts-existing');

/// Add to contacts for a pairing in no contact: one button, its menu holds Save as a new
/// contact and Add to a contact ([deskPutPairingInContacts]); [onSaved] runs once it is in.
class DeskAddToContactsButton extends ConsumerWidget {
  const DeskAddToContactsButton({super.key, required this.record, this.primary = false, this.size = EBtnSize.sm, this.onSaved});

  final PairingRecord record;
  final bool primary;
  final EBtnSize size;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    Widget item(Key key, IconData icon, String label, bool asNew) => MenuItemButton(
      key: key,
      onPressed: () async {
        if (await deskPutPairingInContacts(context, ref, record, asNew: asNew)) onSaved?.call();
      },
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(200.u, 40.u)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.u))),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) ? c.s3 : null,
        ),
      ),
      leadingIcon: Icon(icon, size: Ctl.iconSm, color: c.dim),
      child: Text(label, style: ts.body),
    );
    return MenuAnchor(
      consumeOutsideTap: true,
      menuChildren: [
        item(deskAddToContactsNewKey, EIcons.userPlus, l.pairSaveNewContact, true),
        item(deskAddToContactsExistingKey, EIcons.user, l.pairAddToAContact, false),
      ],
      builder: (context, controller, _) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): controller.close},
        child: EButton(
          key: deskAddToContactsKey,
          label: l.txDetailsAddToContacts,
          icon: EIcons.userPlus,
          kind: primary ? EBtnKind.primary : EBtnKind.secondary,
          size: size,
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}
