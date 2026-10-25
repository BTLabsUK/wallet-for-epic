/// Settings › Invoices, its own tab below Receiving (SPEC 2.7, desktop): who may ask this
/// wallet to pay. A paired, verified contact with Allow invoices on; the group lists them with
/// their switch, Pair with a shop or exchange opens Pair, and Time to pay stays in the
/// collapsed details.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models.dart' show PairingRecord, PairingState;
import '../../data/invoice_state.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/pairing_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../invoices/invoice_parts.dart';
import '../pairing/pair_screens.dart';
import 'settings_frame.dart' show SettingsFrame;

/// Settings › Invoices: its own tab, right below Receiving.
class SettingsInvoicesScreen extends StatelessWidget {
  const SettingsInvoicesScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context) => const SettingsFrame(route: DeskRoute.settingsInvoices, child: InvoiceSettingsBlock());
}

class InvoiceSettingsBlock extends ConsumerWidget {
  const InvoiceSettingsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final book = ref.watch(deskInvoicesProvider);
    final n = ref.read(deskInvoicesProvider.notifier);
    final contacts = ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[];
    final paired = ref.watch(deskPairedProvider);
    final paused = ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff;
    final nav = ref.read(deskNavProvider.notifier);

    Widget row(PairingRecord r) {
      final contact = contacts.where((x) => x.id == r.contactId).firstOrNull;
      final name = contact?.name ?? r.shownName;
      final verified = r.state == PairingState.verified;
      final text = contact == null
          ? l.pairNotInContacts
          : verified
          ? (r.allowInvoices ? l.invSetRowAllowed : l.trustVerified)
          : l.invSetRowCheckFirst;
      return ESetRow(
        title: name,
        text: text,
        control: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact == null) ...[
              EButton(
                label: l.pairAddToContacts,
                size: EBtnSize.sm,
                onPressed: () async {
                  final id = await ref.read(deskProvider.notifier).saveContact(Contact(id: '', name: name, address: r.paymentsAddress));
                  await deskPairingCall(ref, (api) => api.attach(r.id, id));
                },
              ),
              SizedBox(width: Sp.x2),
              EButton(label: l.contactRemovePairing, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => deskPairingCall(ref, (api) => api.removePairing(r.id))),
              SizedBox(width: Sp.x3),
            ] else if (!verified && r.state == PairingState.paired) ...[
              EButton(label: l.sasTitle, size: EBtnSize.sm, onPressed: () => showDeskCheckWords(context, ref, r.id)),
              SizedBox(width: Sp.x3),
            ] else
              EInfoHint(l.contactAllowInfo(name)),
            ESwitch(
              value: verified && r.allowInvoices,
              semanticLabel: l.invSetAllowFor(name),
              onChanged: !verified || paused
                  ? null
                  : (v) async {
                      try {
                        final declined = await deskPairingCall(ref, (api) => api.setAllowInvoices(r.id, v));
                        if (!v && context.mounted) {
                          showEToast(context, l.invSetSwitchedOff(name), text: declined > 0 ? l.invSetDeclinedCount(declined) : null, tone: ETone.info);
                        }
                      } on Object catch (e) {
                        if (context.mounted) showEToast(context, deskErrorText(e, l), tone: ETone.risk);
                      }
                    },
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(EIcons.invoice, size: Ctl.icon, color: c.dim),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(l.invSetTitle, style: ts.h3)),
          ],
        ),
        SizedBox(height: Sp.x2),
        Text(l.invSetLeadDesktop, style: ts.bodyDim),
        SizedBox(height: Sp.x5),
        if (paused) ...[
          ENotice(title: l.contactPausedEpicboxOff, text: l.invSetPausedBody, tone: ETone.info, icon: Icons.pause_circle_outline),
          SizedBox(height: Sp.x4),
        ],
        ESetGroup(
          title: l.invSetPaired,
          trailing: EButton(label: l.invSetPairShop, icon: EIcons.trusted, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair)),
          rows: [
            if (paired.isEmpty) ESetRow(text: l.invSetEmpty) else for (final r in paired) row(r),
          ],
        ),
        if (book != null)
          EDetails(
            title: l.invSetTimeToPay,
            child: ESetGroup(
              rows: [
                ESetRow(
                  title: l.deskInvSetExpiry,
                  text: l.deskInvSetExpiryHint,
                  control: SizedBox(
                    width: InvW.md,
                    child: ESelect<int>(
                      semanticLabel: l.deskInvSetExpiry,
                      value: book.expiry.inHours,
                      items: [for (final e in invoiceExpiries) ESelectItem(e.inHours, l.deskInvSetHours(e.inHours))],
                      onChanged: (h) => n.setExpiry(Duration(hours: h)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
