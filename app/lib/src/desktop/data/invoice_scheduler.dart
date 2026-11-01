// SPDX-License-Identifier: Apache-2.0
/// When the desktop wallet asks Epicbox for the payments of issued invoices by itself: the
/// payments address is drained every [InvoiceScheduler.paymentsEvery] while an issued invoice
/// waits and the Epicbox listener is off (the listener finalizes payments itself while it
/// runs). Invoices from paired contacts arrive with the contacts' mailbox collect (the shell's
/// tick and resume, `app/shell.dart`) as events; opening the wallet and the Invoices page
/// ask through [DeskWalletApi.checkInvoices] (`invoice_state.dart`).
///
/// One scheduler per open wallet session: [InvoiceScheduler.stop] on lock and on a wallet or
/// server switch. Nothing here pays: it only drains and sweeps.
library;

import 'dart:async';

import '../../log.dart';

class InvoiceScheduler {
  InvoiceScheduler({
    required this.drainPayments,
    required this.paymentsWanted,
    this.paymentsEvery = const Duration(seconds: 60),
  });

  /// Drains the payments address, then sweeps.
  final Future<void> Function() drainPayments;

  /// True while an issued invoice waits and the Epicbox listener is off.
  final bool Function() paymentsWanted;

  final Duration paymentsEvery;

  Timer? _payments;

  bool get running => _payments != null;

  void start() {
    if (running) return;
    _payments = Timer.periodic(paymentsEvery, (_) => unawaited(paymentsTick()));
  }

  void stop() {
    _payments?.cancel();
    _payments = null;
  }

  /// One drain of the payments address, when [paymentsWanted].
  Future<void> paymentsTick() async {
    if (!running || !paymentsWanted()) return;
    try {
      await drainPayments();
    } on Object catch (e) {
      logDebug('invoices', 'scheduled payments drain failed: ${e.runtimeType}');
    }
  }
}
