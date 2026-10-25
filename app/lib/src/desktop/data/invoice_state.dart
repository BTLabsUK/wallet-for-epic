/// Riverpod state for invoices on desktop (`docs/invoices/flow.md` on `plan/invoices`): the
/// open wallet's [InvoiceBook], reloaded on the wallet's change events, drained when the wallet
/// opens and when the Invoices page opens (flow.md §4.1; the wallet drains on its own timer and
/// on focus, `invoice_scheduler.dart`), and the calls the screens make. Null while locked,
/// loading, or when the wallet has no invoices.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import 'api.dart';
import 'invoices.dart';
import 'models.dart' show SelfSend;
import 'state.dart';
import 'pairing_state.dart' show deskInvoicesOnProvider;

export 'invoices.dart';

/// Timers run in the app, not under `flutter test` (a pending timer fails a widget test).
final bool _timers = kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

class DeskInvoices extends Notifier<InvoiceBook?> {
  DeskWalletApi get _api => ref.read(deskApiProvider);

  StreamSubscription<void>? _changes;
  Timer? _clock;

  /// Time since the book was read: a tick moves its clock by this, the wallet's or the
  /// prototype's alike, without reading it again.
  final Stopwatch _sinceLoad = Stopwatch();
  DateTime? _loadedAt;

  @override
  InvoiceBook? build() {
    final api = ref.watch(deskApiProvider);
    final open = ref.watch(deskProvider.select((s) => s.account != null));
    ref.onDispose(_stop);
    // Invoices off (Settings › Advanced): no book, so nothing of invoices shows or is checked.
    if (!api.supportsInvoices || !ref.watch(deskInvoicesOnProvider) || !open) return null;
    _changes = api.changes().listen((_) => unawaited(load()));
    // The invoice address carries the relay: a switch moves the payments address, read again.
    ref.listen(deskProvider.select((s) => s.epicboxAddress), (before, now) {
      if (before != null && before != now) unawaited(load());
    });
    if (_timers) {
      // Countdowns read the book's clock; a fresh book every 20 s keeps them moving.
      _clock = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
    }
    // The wallet just opened: what waits is read, then the relay is asked.
    unawaited(load().then((_) => _timers ? check(quiet: true) : null));
    return null;
  }

  void _stop() {
    _changes?.cancel();
    _changes = null;
    _clock?.cancel();
    _clock = null;
  }

  bool get supported => _api.supportsInvoices;

  /// Countdowns read the book's clock: a new one every tick, with nothing read again.
  void _tick() {
    final at = _loadedAt;
    final book = state;
    if (at == null || book == null) return;
    state = book.at(at.add(_sinceLoad.elapsed));
  }

  Future<void> load() async {
    if (!supported) return;
    try {
      final book = await _api.invoices();
      _loadedAt = book.now;
      _sinceLoad
        ..reset()
        ..start();
      state = book;
    } on Object {
      // Locked meanwhile; the next unlock reads again.
    }
  }

  /// Drains the invoice and payments addresses. A failure keeps the lists and marks the check
  /// failed (the screens show the relay status); [quiet] swallows it for the timers.
  Future<void> check({bool quiet = false}) async {
    if (!supported) return;
    final before = state;
    if (before != null) state = before.withCheck(InvoiceCheck.checking);
    try {
      state = await _api.checkInvoices();
    } on Object {
      final now = state ?? await _api.invoices();
      state = now.withCheck(InvoiceCheck.failed, problem: now.checkProblem ?? 'relay');
      if (!quiet) rethrow;
    }
  }

  Future<IssuedRequest> request(PaymentRequestDraft draft) => _then('request', () => _api.requestPayment(draft));
  Future<void> withdraw(String slateId) => _then('withdraw', () => _api.withdrawRequest(slateId));
  Future<void> repost(String slateId) => _then('repost', () => _api.repostRequest(slateId));
  Future<void> cancelRequestPayment(String slateId) => _then('cancelRequestPayment', () => _api.cancelRequestPayment(slateId));
  Future<IncomingInvoice> pay(String slateId, {required int amount, required String password}) =>
      _then('pay', () => _api.payInvoice(slateId, amount: amount, password: password));
  Future<IncomingInvoice> retry(String slateId) => _then('retry', () => _api.retryInvoiceReply(slateId));
  Future<void> decline(String slateId) => _then('decline', () => _api.declineInvoice(slateId));
  Future<void> cancelPayment(String slateId) => _then('cancelPayment', () => _api.cancelInvoicePayment(slateId));
  Future<SelfSend> spendToSelf(String slateId) => _then('spendToSelf', () => _api.spendCancelledToSelf(slateId));
  Future<void> setExpiry(Duration expiry) => _then('setExpiry', () => _api.setInvoiceExpiry(expiry));

  /// Runs [call], then reads the book again (and the wallet, for balance and Activity) whether
  /// it worked or not. A failure is logged by its kind; the screens word it.
  Future<T> _then<T>(String what, Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (e) {
      logWarn('invoices', '$what failed: ${deskFailureKind(e)}');
      rethrow;
    } finally {
      await load();
      unawaited(ref.read(deskProvider.notifier).refresh());
    }
  }
}

final deskInvoicesProvider = NotifierProvider<DeskInvoices, InvoiceBook?>(DeskInvoices.new);

/// The open wallet's invoice notices (paid, declined, expired, sent back, withdrawn); the shell
/// shows each as a toast.
final deskInvoiceNoticesProvider = StreamProvider<InvoiceNotice>((ref) {
  final api = ref.watch(deskApiProvider);
  return api.supportsInvoices && ref.watch(deskInvoicesOnProvider) ? api.invoiceNotices() : const Stream.empty();
});

/// What the sidebar badge counts: invoices to answer and payments to settle.
final deskInvoiceBadgeProvider = Provider<int>((ref) => ref.watch(deskInvoicesProvider)?.attention ?? 0);
