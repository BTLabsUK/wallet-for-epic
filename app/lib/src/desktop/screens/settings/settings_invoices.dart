/// Settings › Invoices, its own tab below Receiving (docs/invoices/flow.md §1, §2, §7): the invoice address in
/// its own frame, the trusted senders, and under Advanced the rotation and the time to pay.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import '../invoices/invoice_address.dart';
import '../invoices/invoice_parts.dart';
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
    if (book == null) return const SizedBox.shrink();
    final n = ref.read(deskInvoicesProvider.notifier);
    final contacts = ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(EIcons.invoice, size: Ctl.icon, color: c.dim),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(l.deskInvSetTitle, style: ts.h3)),
          ],
        ),
        SizedBox(height: Sp.x2),
        Text(l.deskInvSetIntro, style: ts.bodyDim),
        SizedBox(height: Sp.x4),
        InvoiceAddressFrame(address: book.invoiceAddress, index: book.invoiceIndex),
        SizedBox(height: Sp.x3),
        // A restore without the history file starts again at index 1 (P-16). Whether the wallet
        // was restored is not known reliably (older restores kept no mark), so the first index
        // alone shows the line, worded for a restore.
        if (book.invoiceIndex == 1) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(EIcons.info, size: Ctl.iconSm, color: c.dim),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskInvSetRestoredHint, style: ts.small.copyWith(color: c.dim))),
            ],
          ),
          SizedBox(height: Sp.x2),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EIcons.monitor, size: Ctl.iconSm, color: c.dim),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(l.deskInvOneDevice, style: ts.small.copyWith(color: c.dim))),
          ],
        ),
        SizedBox(height: Sp.x5),
        ESetGroup(
          title: l.deskInvSetTrusted,
          trailing: InvButton(label: l.deskInvSetAdd, icon: EIcons.plus, width: InvW.md, onPressed: () => _add(context, ref)),
          rows: [
            if (book.trusted.isEmpty)
              ESetRow(text: l.deskInvSetTrustedNone)
            else
              for (final t in book.trusted)
                ESetRow(
                  title: t.label,
                  text: '${shortAddress(t.address, compact: true)} · ${l.deskInvSetSince(invWhen(context, t.since).split(',').first)}',
                  control: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (t.contactId != null && contacts.any((x) => x.id == t.contactId)) ...[ETag(l.deskInvSetContactTag, icon: EIcons.contacts), SizedBox(width: Sp.x3)],
                      InvButton(label: l.deskInvSetRemove, kind: EBtnKind.danger, onPressed: () => _remove(context, ref, t)),
                    ],
                  ),
                ),
          ],
        ),
        if (book.dropped > 0) ...[
          SizedBox(height: Sp.x3),
          Row(
            children: [
              Icon(EIcons.shield, size: Ctl.iconSm, color: c.dim),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskInvSetDropped(book.dropped), style: ts.small.copyWith(color: c.dim))),
            ],
          ),
        ],
        SizedBox(height: Sp.x4),
        EDetails(
          title: l.deskInvAdvanced,
          child: ESetGroup(
            rows: [
              ESetRow(
                title: l.deskInvSetRotate,
                text: l.deskInvSetRotateHint,
                control: InvButton(label: l.deskInvSetRotate, width: InvW.md, onPressed: () => _rotate(context, ref)),
              ),
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

  Future<void> _rotate(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        title: l.deskInvSetRotateTitle,
        description: l.deskInvSetRotateBody,
        icon: EIcons.alert,
        tone: ETone.warn,
        actions: [
          InvButton(label: l.deskInvSetKeep, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(false)),
          InvButton(label: l.deskInvSetRotateConfirm, kind: EBtnKind.primary, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(deskInvoicesProvider.notifier).rotate();
    if (context.mounted) showEToast(context, l.deskInvSetRotated, tone: ETone.warn);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, TrustedSender t) async {
    final l = context.l10n;
    final ok = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        title: l.deskInvSetRemoveTitle(t.label),
        description: l.deskInvSetRemoveBody(t.label),
        icon: EIcons.trusted,
        actions: [
          InvButton(label: l.deskInvSetKeep, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(false)),
          InvButton(label: l.deskInvSetRemove, kind: EBtnKind.danger, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(deskInvoicesProvider.notifier).untrust(t.address);
    if (context.mounted) showEToast(context, l.deskInvSetRemoved(t.label), tone: ETone.neutral);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) => showEDialog<void>(context, builder: (_) => const TrustSenderDialog());
}

/// Trust a sender: a name and its payments address.
class TrustSenderDialog extends ConsumerStatefulWidget {
  const TrustSenderDialog({super.key, this.name, this.address, this.submitted = false});

  /// Starting values (the screenshot tour fills them).
  final String? name;
  final String? address;
  final bool submitted;

  @override
  ConsumerState<TrustSenderDialog> createState() => _TrustSenderDialogState();
}

class _TrustSenderDialogState extends ConsumerState<TrustSenderDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _address = TextEditingController(text: widget.address);
  late bool _submitted = widget.submitted;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  String? get _nameErr => _name.text.trim().isEmpty ? context.l10n.deskInvSetNameMissing : null;

  String? get _addressErr {
    final t = _address.text.trim();
    if (t.isEmpty) return context.l10n.deskInvSetSenderMissing;
    final p = parseAddress(t, ref.read(deskApiProvider));
    return p.kind == AddressKind.epicbox && p.complete ? null : context.l10n.deskInvSetSenderInvalid;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_nameErr != null || _addressErr != null) return;
    setState(() => _busy = true);
    final l = context.l10n;
    final name = _name.text.trim();
    await ref.read(deskInvoicesProvider.notifier).trust(_address.text.trim(), name);
    if (!mounted) return;
    Navigator.of(context).pop();
    showEToast(context, l.deskInvSetAdded(name));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      title: l.deskInvSetAdd,
      description: l.deskInvSetAddBody,
      icon: EIcons.trusted,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: l.deskInvSetName,
            error: _submitted ? _nameErr : null,
            child: EInput(controller: _name, invalid: _submitted && _nameErr != null, semanticLabel: l.deskInvSetName, onChanged: (_) => setState(() {})),
          ),
          SizedBox(height: Sp.x4),
          EField(
            label: l.deskInvSetSenderAddress,
            error: _submitted ? _addressErr : null,
            child: EInput(
              controller: _address,
              mono: true,
              invalid: _submitted && _addressErr != null,
              hint: l.deskInvAddressHint,
              semanticLabel: l.deskInvSetSenderAddress,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
      actions: [
        InvButton(label: l.deskInvSetCancel, width: InvW.md, onPressed: () => Navigator.of(context).pop()),
        InvButton(label: l.deskInvSetTrust, kind: EBtnKind.primary, width: InvW.md, busy: _busy, onPressed: _busy ? null : _save),
      ],
    );
  }
}
