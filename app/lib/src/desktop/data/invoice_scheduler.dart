/// When the desktop wallet asks Epicbox for invoices and payments by itself
/// (`docs/invoices/flow.md` §3.3 and §4.1). The invoice address has no listener, so it is
/// drained every [invoicesEvery] and when the window gains focus; the payments address is
/// drained every [paymentsEvery] while an issued invoice waits and the Epicbox listener is off
/// (the listener finalizes payments itself while it runs). Opening the wallet and the Invoices
/// page ask through [DeskWalletApi.checkInvoices] (`invoice_state.dart`).
///
/// One scheduler per open wallet session: [stop] on lock and on a wallet or server switch.
/// Nothing here pays: it only drains and sweeps.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../log.dart';

class InvoiceScheduler {
  InvoiceScheduler({
    required this.drainInvoices,
    required this.drainPayments,
    required this.paymentsWanted,
    this.invoicesEvery = const Duration(minutes: 2),
    this.paymentsEvery = const Duration(seconds: 60),
    this.watchFocus = true,
  });

  /// Drains the invoice address, then sweeps.
  final Future<void> Function() drainInvoices;

  /// Drains the payments address, then sweeps.
  final Future<void> Function() drainPayments;

  /// True while an issued invoice waits and the Epicbox listener is off.
  final bool Function() paymentsWanted;

  final Duration invoicesEvery;
  final Duration paymentsEvery;

  /// Drain when the window gains focus (off in tests without a binding).
  final bool watchFocus;

  Timer? _invoices;
  Timer? _payments;
  AppLifecycleListener? _focus;
  bool _draining = false;

  bool get running => _invoices != null;

  void start() {
    if (running) return;
    _invoices = Timer.periodic(invoicesEvery, (_) => unawaited(tick()));
    _payments = Timer.periodic(paymentsEvery, (_) => unawaited(paymentsTick()));
    if (watchFocus) {
      try {
        _focus = AppLifecycleListener(onResume: () => unawaited(tick()));
      } on Object catch (e) {
        // No Flutter binding (a plain Dart run): the timers still drain.
        logDebug('invoices', 'no focus drain: ${e.runtimeType}');
      }
    }
  }

  void stop() {
    _invoices?.cancel();
    _invoices = null;
    _payments?.cancel();
    _payments = null;
    _focus?.dispose();
    _focus = null;
  }

  /// One drain of the invoice address. A drain under way is not doubled; a failure is logged
  /// only (the Invoices page shows the relay status of its own checks).
  Future<void> tick() async {
    if (!running || _draining) return;
    _draining = true;
    try {
      await drainInvoices();
    } on Object catch (e) {
      logDebug('invoices', 'scheduled invoice drain failed: ${e.runtimeType}');
    } finally {
      _draining = false;
    }
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
