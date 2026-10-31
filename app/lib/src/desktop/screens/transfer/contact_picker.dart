// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models.dart' show PairingRecord;
import '../../../payment_prefs.dart' show PaymentPrefs;
import '../../../recipient.dart' show RecipientKind;
import '../../../ui/pairing/pairing_parts.dart' show TrustBadge;
import '../../data/pairing_state.dart' show deskContactPairingProvider, deskPairsProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The address Send pays [c] at: the first of its addresses, Epicbox, Tor, HTTP (the
/// [Contact.address] order), that this build sends to and whose method is on in [payments];
/// else [Contact.address], so Send names the method that is off.
String contactAddress(Contact c, PaymentPrefs payments) {
  for (final kind in const [RecipientKind.epicbox, RecipientKind.tor, RecipientKind.http]) {
    final address = c.addressOf(kind);
    final built = switch (kind) {
      RecipientKind.tor => DeskFeatures.tor,
      RecipientKind.http => true,
      RecipientKind.epicbox => true,
    };
    if (address != null && built && payments.offers(MethodKind.ofRecipient(kind))) return address;
  }
  return c.address;
}

/// The way a contact's [address] ([Contact.address] when null) is sent to (by its kind).
TxMethod contactMethod(Contact c, [String? address]) => switch (addressKindOf(address ?? c.address)) {
  AddressKind.tor when DeskFeatures.tor => TxMethod.tor,
  AddressKind.http => TxMethod.http,
  _ => TxMethod.epicbox,
};

/// Whether Send can reach the contact: HTTP and Tor addresses need their feature on.
bool contactSendable(Contact c) => switch (addressKindOf(c.address)) {
  AddressKind.tor => DeskFeatures.tor,
  _ => true,
};

/// The pairing a contact with no address is paid through (DESIGN 1.3), when the wallet pairs;
/// null for a contact with an address.
PairingRecord? contactPairingOnly(WidgetRef ref, Contact c) =>
    c.addresses.isEmpty && ref.watch(deskPairsProvider) ? ref.watch(deskContactPairingProvider(c.id)) : null;

/// "Through Anna's pairing" with the trust badge, where a contact with no address shows its
/// address in a list.
class PairingOnlyLine extends StatelessWidget {
  const PairingOnlyLine({super.key, required this.name, required this.pairing});

  final String name;
  final PairingRecord pairing;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Sp.x2,
    runSpacing: Sp.x1,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      TrustBadge(pairing, short: true),
      Text(context.l10n.sendRecipientPairing(name), style: context.ts.small),
    ],
  );
}

/// Opens the contact picker over the current page; resolves to the chosen contact or null.
/// [description] says what the pick is for; Send's line by default.
Future<Contact?> showContactPicker(BuildContext context, {String? description}) =>
    showEDialog<Contact>(context, builder: (_) => ContactPickerDialog(description: description));

/// For the screenshot tour: the picker, result ignored.
Future<void> showContactPickerDialog(BuildContext context) => showContactPicker(context);

class ContactPickerDialog extends ConsumerStatefulWidget {
  const ContactPickerDialog({super.key, this.query = '', this.description});

  final String query;
  final String? description;

  @override
  ConsumerState<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends ConsumerState<ContactPickerDialog> {
  late final TextEditingController _q = TextEditingController(text: widget.query);

  void _openContacts() {
    Navigator.of(context).pop();
    ref.read(deskNavProvider.notifier).go(DeskRoute.contacts);
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final contacts = ref.watch(deskProvider.select((s) => s.contacts));
    final l = context.l10n;
    final q = _q.text.trim().toLowerCase();
    final shown = contacts == null
        ? const <Contact>[]
        : ([...contacts].where(contactSendable).where((x) => q.isEmpty || x.name.toLowerCase().contains(q) || x.address.toLowerCase().contains(q)).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
    final Widget list;
    if (contacts == null) {
      list = Padding(
        padding: EdgeInsets.all(Sp.x6),
        child: Center(child: ESpinner(size: 20.u)),
      );
    } else if (contacts.isEmpty) {
      list = EEmpty(
        icon: EIcons.contacts,
        title: l.deskSendPickNone,
        text: l.deskSendPickNoneText,
        actions: [EButton.primary(label: l.deskSendPickOpen, icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: _openContacts)],
      );
    } else if (shown.isEmpty) {
      list = Padding(
        padding: EdgeInsets.symmetric(vertical: Sp.x6),
        child: Center(child: Text(l.deskSendPickNoMatch(_q.text.trim()), style: ts.small)),
      );
    } else {
      list = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 320.u),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: shown.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
          itemBuilder: (_, i) => _PickRow(contact: shown[i], pairing: contactPairingOnly(ref, shown[i]), onTap: () => Navigator.of(context).pop(shown[i])),
        ),
      );
    }
    return EDialog(
      title: l.deskSendPickTitle,
      description: widget.description ?? l.deskSendPickDesc,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contacts != null && contacts.isNotEmpty) ...[
            // ↓ from the search field to the first row; the rows move with the arrow keys.
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: (node, e) {
                if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.arrowDown && shown.isNotEmpty) {
                  node.nextFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: EInput(
                controller: _q,
                hint: l.deskSendPickSearch,
                leading: EIcons.search,
                autofocus: true,
                semanticLabel: l.deskSendPickSearch,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (shown.isNotEmpty) Navigator.of(context).pop(shown.first);
                },
              ),
            ),
            SizedBox(height: Sp.x3),
          ],
          list,
        ],
      ),
      actions: [
        if (contacts != null && contacts.isNotEmpty) EButton.ghost(label: l.deskSendPickOpen, onPressed: _openContacts),
        EButton(label: l.commonCancel, kind: EBtnKind.ghost, size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _PickRow extends StatefulWidget {
  const _PickRow({required this.contact, required this.onTap, this.pairing});

  final Contact contact;
  final VoidCallback onTap;

  /// The pairing of a contact with no address: its row says payments go through it.
  final PairingRecord? pairing;

  @override
  State<_PickRow> createState() => _PickRowState();
}

class _PickRowState extends State<_PickRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final pairing = widget.pairing;
    return Semantics(
      button: true,
      label: pairing == null ? '${widget.contact.name}, ${widget.contact.address}' : '${widget.contact.name}, ${context.l10n.sendRecipientPairing(widget.contact.name)}',
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            color: _hover ? c.hover : Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: Sp.x3, horizontal: Sp.x2),
            child: Row(
              children: [
                EAvatar(widget.contact.name, size: 40.u),
                SizedBox(width: 14.u),
                Expanded(
                  child: pairing != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.contact.name, style: context.ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: Sp.x1),
                            PairingOnlyLine(name: widget.contact.name, pairing: pairing),
                          ],
                        )
                      : EAddressLines(
                    name: widget.contact.name,
                    address: widget.contact.address,
                    note: widget.contact.note,
                    nameTrailing: widget.contact.favourite
                        ? Padding(
                            padding: EdgeInsets.only(left: Sp.x1),
                            child: Icon(EIcons.star, size: 14.u, color: c.accentText),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
