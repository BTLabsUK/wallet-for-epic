/// The invoice address, shown so it cannot pass for the payments address (docs/invoices/flow.md
/// §2): its own frame, icon and warning, a copy that repeats the warning, a QR with the same
/// caption. Never on Receive's main card.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';

/// Copies [address] and repeats the warning as a notice.
Future<void> copyInvoiceAddress(BuildContext context, String address) async {
  await Clipboard.setData(ClipboardData(text: address));
  if (context.mounted) showEToast(context, context.l10n.deskInvSetCopied, tone: ETone.warn);
}

class InvoiceAddressFrame extends StatefulWidget {
  const InvoiceAddressFrame({super.key, required this.address, this.index});

  final String address;

  /// Its derivation index, shown small (it changes when rotated).
  final int? index;

  @override
  State<InvoiceAddressFrame> createState() => _InvoiceAddressFrameState();
}

class _InvoiceAddressFrameState extends State<InvoiceAddressFrame> {
  bool _qr = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final caption = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(EIcons.alert, size: Ctl.iconSm, color: c.warn),
        SizedBox(width: Sp.x2),
        Expanded(child: Text(l.deskInvSetAddressWarning, style: ts.small.copyWith(color: c.text))),
      ],
    );
    return Container(
      padding: EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(
        color: c.warnSoft,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: c.warn, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(EIcons.invoiceAddress, size: Ctl.icon, color: c.warn),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskInvSetAddressLabel, style: ts.body.copyWith(fontWeight: FontWeight.w600))),
              if (widget.index != null) Text(l.deskInvSetIndex(widget.index!), style: ts.caption.copyWith(color: c.dim)),
            ],
          ),
          SizedBox(height: Sp.x2),
          caption,
          SizedBox(height: Sp.x3),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x3),
            decoration: BoxDecoration(color: c.s1, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.lineStrong)),
            child: SelectableText(widget.address, style: ts.mono(size: Fs.sm, color: c.text)),
          ),
          SizedBox(height: Sp.x3),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              InvButton(label: l.deskInvSetCopy, icon: EIcons.copy, onPressed: () => copyInvoiceAddress(context, widget.address)),
              InvButton(label: _qr ? l.deskInvSetQrHide : l.deskInvSetQrShow, icon: EIcons.qr, onPressed: () => setState(() => _qr = !_qr)),
            ],
          ),
          // Opens and closes with size and fade, the same both ways; instant with reduced motion.
          ExpandFade(
            open: _qr,
            child: Padding(
              padding: EdgeInsets.only(top: Sp.x4),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(Sp.x3),
                  decoration: BoxDecoration(color: c.s1, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.warn)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(label: l.deskInvSetQrLabel, image: true, child: EQr(widget.address, size: 168.u)),
                      SizedBox(height: Sp.x3),
                      SizedBox(width: 220.u, child: Text(l.deskInvSetAddressWarning, style: ts.caption.copyWith(color: c.text), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
