// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../contact_label.dart' show ContactLabelListMark;
import '../../../epic1.dart' show PaymentMode;
import '../../../models.dart' show PairingRecord;
import '../../../name_service/payment_refusals.dart' show paymentRefusalsProvider;
import '../../../ui/pairing/pairing_parts.dart' show NoPaymentsMark, TrustBadge;
import '../../data/pairing_state.dart' show deskContactPairingProvider, deskPairsProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// Whether Send can reach the contact: HTTP and Tor addresses need their feature on.
bool contactSendable(Contact c) => switch (addressKindOf(c.address)) {
  AddressKind.tor => DeskFeatures.tor,
  _ => true,
};

/// The pairing a contact with no address is paid through (DESIGN 1.3), when the wallet pairs;
/// null for a contact with an address.
PairingRecord? contactPairingOnly(WidgetRef ref, Contact c) =>
    c.addresses.isEmpty && ref.watch(deskPairsProvider) ? ref.watch(deskContactPairingProvider(c.id)) : null;

/// Whether [c] is a contact that takes no payments: its pairing says so, or its address is one's.
bool contactRefusesPayments(WidgetRef ref, Contact c) => ref
    .watch(paymentRefusalsProvider)
    .refusesPayments(pairingId: ref.watch(deskPairsProvider) ? ref.watch(deskContactPairingProvider(c.id))?.id : null, address: c.epicbox);

/// epic1 mode and [c] has neither a pairing that takes epic1 payments nor an epic1 link:
/// "Classic only", not payable.
bool contactClassicOnly(WidgetRef ref, Contact c) =>
    ref.watch(deskPaymentModeProvider) == PaymentMode.epic1 && c.epic1 == null && !contactPairsNatively(ref, c);

/// [c] has a pairing that takes epic1 payments. [watch] false outside build.
bool contactPairsNatively(WidgetRef ref, Contact c, {bool watch = true}) => watch
    ? ref.watch(deskPairsProvider) && (ref.watch(deskContactPairingProvider(c.id))?.nativeSlates ?? false)
    : ref.read(deskPairsProvider) && (ref.read(deskContactPairingProvider(c.id))?.nativeSlates ?? false);

/// The epic1 link epic1 mode pays [c] with: its own, when no pairing takes epic1 payments.
String? contactEpic1Link(WidgetRef ref, Contact c, {bool watch = true}) =>
    c.epic1 != null && !contactPairsNatively(ref, c, watch: watch) ? c.epic1 : null;

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
      Text(context.l10n.sendRecipientPairing(name, context.l10n.sendRoutePairedInline), style: context.ts.small),
    ],
  );
}

/// Opens the contact picker over the current page; resolves to the chosen contact or null.
/// [description] says what the pick is for; Send's line by default.
/// [send] makes it Send's: "Send to a contact", its button naming the chosen one.
Future<Contact?> showContactPicker(BuildContext context, {String? description, bool send = false}) =>
    showEDialog<Contact>(context, builder: (_) => ContactPickerDialog(description: description, send: send));

/// For the screenshot tour: Send's picker, result ignored.
Future<void> showContactPickerDialog(BuildContext context) => showContactPicker(context, send: true);

class ContactPickerDialog extends ConsumerStatefulWidget {
  const ContactPickerDialog({super.key, this.query = '', this.description, this.send = false});

  final String query;
  final String? description;
  final bool send;

  @override
  ConsumerState<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends ConsumerState<ContactPickerDialog> {
  late final TextEditingController _q = TextEditingController(text: widget.query);

  /// The chosen row's contact (Dlg-Contact-pick: ticked, named on the button); the first
  /// payable match until the arrow keys move it.
  String? _chosen;

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
    // Rows that can be paid; the chosen one among them.
    final open = [
      for (final x in shown)
        if (!contactRefusesPayments(ref, x) && !contactClassicOnly(ref, x)) x,
    ];
    final chosen = open.where((x) => x.id == _chosen).firstOrNull ?? open.firstOrNull;
    void move(int by) {
      if (open.isEmpty) return;
      final i = chosen == null ? 0 : open.indexOf(chosen);
      setState(() => _chosen = open[(i + by).clamp(0, open.length - 1)].id);
    }

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
      list = DecoratedBox(
        decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 320.u),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: shown.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
            itemBuilder: (_, i) => _PickRow(
              contact: shown[i],
              chosen: shown[i].id == chosen?.id,
              pairing: contactPairingOnly(ref, shown[i]),
              noPayments: contactRefusesPayments(ref, shown[i]),
              classicOnly: contactClassicOnly(ref, shown[i]),
              onTap: () => Navigator.of(context).pop(shown[i]),
            ),
          ),
        ),
      );
    }
    return EDialog(
      title: widget.send ? l.deskSendPickSendTitle : l.deskSendPickTitle,
      icon: EIcons.contacts,
      description: widget.description ?? (widget.send ? l.deskSendPickSendDesc : l.deskSendPickDesc),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contacts != null && contacts.isNotEmpty) ...[
            // ↑ ↓ in the search field move the choice; Enter takes it.
            Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: (node, e) {
                if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
                if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                  move(1);
                  return KeyEventResult.handled;
                }
                if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                  move(-1);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: ESearch(
                controller: _q,
                hint: l.deskSendPickSearch,
                label: l.deskSendPickSearch,
                clearLabel: l.deskActClearSearch,
                autofocus: true,
                onChanged: (_) => setState(() => _chosen = null),
                onSubmitted: (_) {
                  if (chosen != null) Navigator.of(context).pop(chosen);
                },
              ),
            ),
            SizedBox(height: Sp.x3),
          ],
          list,
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop()),
        if (contacts != null && contacts.isNotEmpty)
          EButton.primary(
            label: chosen == null ? l.deskSendPickChoose : (widget.send ? l.deskSendPickSendTo(chosen.name) : l.deskSendPickChooseName(chosen.name)),
            onPressed: chosen == null ? null : () => Navigator.of(context).pop(chosen),
          ),
      ],
    );
  }
}

class _PickRow extends StatefulWidget {
  const _PickRow({required this.contact, required this.onTap, this.chosen = false, this.pairing, this.noPayments = false, this.classicOnly = false});

  final Contact contact;
  final VoidCallback onTap;

  /// The row Enter and the button take: raised, with a tick.
  final bool chosen;

  /// The contact takes no payments: the row stays, dimmed and not pressable, with the reason.
  final bool noPayments;

  /// epic1 mode and the contact has no epic1: dimmed, "Classic only", not pressable.
  final bool classicOnly;

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
    final classicOnly = widget.classicOnly && !widget.noPayments;
    final noPayments = widget.noPayments || classicOnly;
    final row = Semantics(
      button: true,
      enabled: !noPayments,
      label: classicOnly
          ? '${widget.contact.name}, ${context.l10n.deskE1ClassicOnly}'
          : noPayments
          ? '${widget.contact.name}, ${context.l10n.contactTakesNoPayments}'
          : pairing == null ? '${widget.contact.name}, ${widget.contact.address}' : '${widget.contact.name}, ${context.l10n.sendRecipientPairing(widget.contact.name, context.l10n.sendRoutePairedInline)}',
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: noPayments ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: EInkWell(
          onTap: noPayments ? null : widget.onTap,
          child: Container(
            color: widget.chosen ? c.s3 : (_hover && !noPayments ? c.hover : Colors.transparent),
            padding: EdgeInsets.symmetric(vertical: Sp.x3, horizontal: Sp.x4),
            child: Row(
              children: [
                EAvatar(widget.contact.name, size: 40.u, label: widget.contact.label.listMark),
                SizedBox(width: 14.u),
                Expanded(
                  child: classicOnly
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.contact.name, style: context.ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: Sp.x1),
                            Text(context.l10n.deskE1ClassicOnly, key: const ValueKey('e1-classic-only'), style: context.ts.small.copyWith(color: c.dim)),
                          ],
                        )
                      : noPayments
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(widget.contact.name, style: context.ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                SizedBox(width: Sp.x2),
                                const NoPaymentsMark(),
                              ],
                            ),
                            SizedBox(height: Sp.x1),
                            Text(context.l10n.contactTakesNoPayments, style: context.ts.small),
                          ],
                        )
                      : pairing != null
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
                    address: widget.contact.address.isEmpty ? (widget.contact.epic1 ?? '') : widget.contact.address,
                    note: widget.contact.note,
                    nameTrailing: widget.contact.favourite
                        ? Padding(
                            padding: EdgeInsets.only(left: Sp.x1),
                            child: Icon(EIcons.star, size: 14.u, color: c.accentText),
                          )
                        : null,
                  ),
                ),
                if (widget.chosen) ...[SizedBox(width: Sp.x3), Icon(EIcons.okCircle, size: 18.u, color: c.accentText)],
              ],
            ),
          ),
        ),
      ),
    );
    if (classicOnly) return ETip(context.l10n.deskE1ClassicTip, child: Opacity(opacity: 0.5, child: row));
    return noPayments ? Opacity(opacity: 0.5, child: row) : row;
  }
}
