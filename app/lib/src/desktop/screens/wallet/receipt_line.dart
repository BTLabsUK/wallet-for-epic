// SPDX-License-Identifier: Apache-2.0
/// The optional receipt line of a payment made from a payment link on the desktop (tg-pay §5.5):
/// one unticked line, off by default, never automatic; see `ui/receipt_line.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../name_service/receipts.dart';
import '../../../ui/receipt_line.dart' show ReceiptTexts, tickReceipt;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// Keys for tests.
const Key deskReceiptLineKey = ValueKey('desk-receipt-line');
const Key deskReceiptToldKey = ValueKey('desk-receipt-told');

class DeskReceiptLine extends ConsumerStatefulWidget {
  const DeskReceiptLine({super.key, required this.slateId, required this.posted, this.finalizedAtUnix});

  final String slateId;

  /// The payment was finalized and posted: the second stage.
  final bool posted;
  final int? finalizedAtUnix;

  @override
  ConsumerState<DeskReceiptLine> createState() => _DeskReceiptLineState();
}

class _DeskReceiptLineState extends ConsumerState<DeskReceiptLine> {
  bool _busy = false;

  /// The desktop's transactions carry no finalize time: the posted stage is stamped with the
  /// time the line was first shown, the same second the ticked receipt carries.
  late final int _shownAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  int get _finalizedAt => widget.finalizedAtUnix ?? _shownAt;

  Future<void> _tick(int stage, String name) async {
    setState(() => _busy = true);
    final ok = await tickReceipt(ref, slateId: widget.slateId, stage: stage, finalizedAtUnix: _finalizedAt);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok && !(ref.read(linkPaymentRecordsProvider).of(widget.slateId)?.told.contains(stage) ?? false)) {
      showEToast(context, context.l10n.receiptNotSent(name), tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(nameServiceReceiptsProvider);
    final rec = ref.watch(linkPaymentProvider(widget.slateId));
    final state = receiptLineOf(receipts, rec, posted: widget.posted);
    if (rec == null || state == null) return const SizedBox.shrink();
    final l = context.l10n;
    final c = context.dc;
    final texts = ReceiptTexts(l, rec, state.stage, linkPayeeName(receipts, rec), _finalizedAt);
    if (state.told) {
      return Row(
        key: deskReceiptToldKey,
        children: [
          Icon(EIcons.check, size: 16.u, color: c.ok),
          SizedBox(width: Sp.x2),
          Expanded(child: Text(texts.told, style: context.ts.body)),
        ],
      );
    }
    return Row(
      key: deskReceiptLineKey,
      children: [
        ECheckbox(value: _busy, onChanged: (v) => _busy || !v ? null : _tick(state.stage, texts.name), label: texts.tell),
        SizedBox(width: Sp.x1),
        EInfoHint(texts.sees, title: l.receiptHintTitle),
      ],
    );
  }
}
