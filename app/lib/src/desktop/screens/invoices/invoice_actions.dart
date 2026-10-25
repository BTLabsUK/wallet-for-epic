/// Payer actions other screens call (Activity's Invoice block, Overview): retry a reply that
/// was not delivered, cancel a payment. Owned by the payer part; the bodies show its dialogs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/invoice_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'pay_dialogs.dart';

/// Sends a [PayState.notDelivered] payment's stored reply again; signs nothing. A toast says
/// whether it went.
Future<void> retryInvoicePayment(BuildContext context, WidgetRef ref, IncomingInvoice invoice) => retryPayment(context, invoice);

/// Asks, then cancels a paid invoice's payment ([PayState.cancellable]); errors stay in the
/// dialog, success is a toast.
Future<void> showCancelInvoicePayment(BuildContext context, WidgetRef ref, IncomingInvoice invoice) => showCancelPaymentDialog(context, invoice);

/// Spends a cancelled payment's coins to this wallet ([IncomingInvoice.spendToSelf], D-2),
/// which makes the cancel final. A toast says whether it went.
Future<void> spendCancelledPayment(BuildContext context, WidgetRef ref, IncomingInvoice invoice) async {
  final l = context.l10n;
  try {
    await ref.read(deskInvoicesProvider.notifier).spendToSelf(invoice.slateId);
    if (context.mounted) showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerSpentText, tone: ETone.ok);
  } on Object {
    if (context.mounted) showEToast(context, l.deskInvPayerCancelled, text: l.deskInvPayerSpendFailedText, tone: ETone.warn);
  }
}
