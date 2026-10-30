// SPDX-License-Identifier: Apache-2.0
/// Payer actions other screens call (Activity's Invoice block, Overview): retry a reply that
/// was not delivered, cancel a payment. Owned by the payer part; the bodies show its dialogs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/invoice_state.dart';
import 'pay_dialogs.dart';

/// Sends a [PayState.notDelivered] payment's stored reply again; signs nothing. A toast says
/// whether it went.
Future<void> retryInvoicePayment(BuildContext context, WidgetRef ref, IncomingInvoice invoice) => retryPayment(context, invoice);

/// Asks, then cancels a paid invoice's payment ([PayState.cancellable]); errors stay in the
/// dialog, success is a toast.
Future<void> showCancelInvoicePayment(BuildContext context, WidgetRef ref, IncomingInvoice invoice) => showCancelPaymentDialog(context, invoice);
