// SPDX-License-Identifier: Apache-2.0
/// The optional receipt line of a payment made from a payment link (tg-pay §5.5): one unticked
/// line, off by default, never automatic. Ticking posts a type 5 receipt for that stage once;
/// the line then reads as done. Hidden unless the directory can be told.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart' show epicFor;
import '../directory/pins.dart';
import '../directory/receipts.dart';
import '../l10n.dart';
import 'info_hint.dart';
import 'theme/tokens.dart';

/// Keys for tests.
const Key receiptLineKey = ValueKey('receipt-line');
const Key receiptToldKey = ValueKey('receipt-told');

/// The words of a receipt line for [rec] at [stage].
class ReceiptTexts {
  ReceiptTexts(AppLocalizations l, LinkPaymentRec rec, int stage, String? name, int? finalizedAtUnix)
    : name = name ?? l.linkPayeeMid,
      _l = l,
      _rec = rec,
      _stage = stage,
      _time = localClock(
        l,
        DateTime.fromMillisecondsSinceEpoch(receiptAt(rec, stage, finalizedAtUnix) * 1000),
      );

  final AppLocalizations _l;
  final LinkPaymentRec _rec;
  final int _stage;
  final String _time;
  final String name;

  String get tell => _stage == 2 ? _l.receiptTellPosted(name) : _l.receiptTellSent(name);
  String get told => _l.receiptTold(name);
  String get sees {
    final amount = epicFor(_l, _rec.amount);
    return _stage == 2
        ? _l.receiptSeesPosted(name, _rec.shortId, amount, _time)
        : _l.receiptSeesSent(name, _rec.shortId, amount, _time);
  }
}

/// Posts the receipt for the line the user ticked. True when it went; the caller shows the
/// failure otherwise.
Future<bool> tickReceipt(
  WidgetRef ref, {
  required String slateId,
  required int stage,
  required int? finalizedAtUnix,
}) async {
  final records = ref.read(linkPaymentRecordsProvider);
  final rec = records.of(slateId);
  if (rec == null) return false;
  final ok = await tellPayee(
    receipts: ref.read(directoryReceiptsProvider),
    records: records,
    slateId: slateId,
    stage: stage,
    at: receiptAt(rec, stage, finalizedAtUnix),
  );
  if (ok) ref.read(linkPaymentTickProvider.notifier).bump();
  return ok;
}

class ReceiptLine extends ConsumerStatefulWidget {
  const ReceiptLine({super.key, required this.slateId, required this.posted, this.finalizedAtUnix});

  final String slateId;

  /// The payment was finalized and posted: the second stage.
  final bool posted;
  final int? finalizedAtUnix;

  @override
  ConsumerState<ReceiptLine> createState() => _ReceiptLineState();
}

class _ReceiptLineState extends ConsumerState<ReceiptLine> {
  bool _busy = false;

  Future<void> _tick(int stage, String name) async {
    setState(() => _busy = true);
    final ok = await tickReceipt(
      ref,
      slateId: widget.slateId,
      stage: stage,
      finalizedAtUnix: widget.finalizedAtUnix,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok && !(ref.read(linkPaymentRecordsProvider).of(widget.slateId)?.told.contains(stage) ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.receiptNotSent(name))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = ref.watch(linkPaymentProvider(widget.slateId));
    final state = receiptLineOf(ref.watch(directoryReceiptsProvider), rec, posted: widget.posted);
    if (rec == null || state == null) return const SizedBox.shrink();
    final l = context.l10n;
    final texts = ReceiptTexts(
      l,
      rec,
      state.stage,
      linkPayeeName(ref.watch(directoryReceiptsProvider), rec),
      widget.finalizedAtUnix,
    );
    final t = context.tokens;
    if (state.told) {
      return Padding(
        key: receiptToldKey,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 20, color: t.ok),
            const SizedBox(width: 12),
            Expanded(child: Text(texts.told)),
          ],
        ),
      );
    }
    return CheckboxListTile(
      key: receiptLineKey,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _busy,
      onChanged: _busy ? null : (v) => v == true ? _tick(state.stage, texts.name) : null,
      title: Text(texts.tell),
      secondary: InfoHint(texts.sees, title: l.receiptHintTitle, size: InfoHint.inRow),
    );
  }
}
