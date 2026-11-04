// SPDX-License-Identifier: Apache-2.0
/// Riverpod glue for directories, shared by the phone and the desktop: each app makes a
/// [DirectoryProviders] over its own provider of the open wallet's [DirectoryService] (null
/// while locked) and the screens read [DirectoryProviders.view].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'directory_model.dart';
import 'directory_service.dart';
import 'membership.dart';
import 'payment_refusals.dart';
import 'receipts.dart';

/// What the screens show of the service: its book and where each words step stands.
class DirectoryView {
  const DirectoryView({required this.book, required this.steps, required this.loaded});

  factory DirectoryView.of(DirectoryService s) => DirectoryView(
    book: s.book,
    steps: s.steps,
    loaded: s.loaded,
  );

  final DirectoryBook book;

  /// The steps of the pairings the service tracks; see [stepOf].
  final Map<String, HelloStep> steps;
  final bool loaded;

  /// The directory the user verified for [pairingId], or null: its page shows Join or Leave.
  DirectoryEntry? verifiedFor(String pairingId) {
    final e = book.byPairing(pairingId);
    return e != null && e.pinned ? e : null;
  }

  /// The directory a valid hello named on [pairingId], before the user compared the code.
  DirectoryEntry? helloFor(String pairingId) {
    final e = book.byPairing(pairingId);
    return e != null && !e.pinned ? e : null;
  }
}

class DirectoryProviders {
  DirectoryProviders(this.service);

  /// The app's provider of the open wallet's service.
  final Provider<DirectoryService?> service;

  /// The view, rebuilt on every change; null while there is no service.
  late final NotifierProvider<DirectoryViewNotifier, DirectoryView?> view =
      NotifierProvider<DirectoryViewNotifier, DirectoryView?>(() => DirectoryViewNotifier(service));

  /// The directory verified for a pairing, null for none.
  late final directoryOfPairing = Provider.family<DirectoryEntry?, String>(
    (ref, pairingId) => ref.watch(view)?.verifiedFor(pairingId),
  );

  /// [DirectoryMembership] over the open wallet's service, for [directoryMembershipProvider].
  late final Provider<DirectoryMembership> membership = Provider<DirectoryMembership>(
    (ref) => ref.watch(service) ?? const NoDirectoryMembership(),
  );

  /// [PaymentRefusals] over the open wallet's book, for [paymentRefusalsProvider].
  late final Provider<PaymentRefusals> refusals = Provider<PaymentRefusals>((ref) {
    final v = ref.watch(view);
    return v == null ? const NoPaymentRefusals() : BookRefusals(v.book);
  });

  /// [DirectoryReceipts] over the open wallet's service, for [directoryReceiptsProvider].
  late final Provider<DirectoryReceipts> receipts = Provider<DirectoryReceipts>(
    (ref) => ref.watch(service) ?? const NoDirectoryReceipts(),
  );
}

class DirectoryViewNotifier extends Notifier<DirectoryView?> {
  DirectoryViewNotifier(this._service);

  final Provider<DirectoryService?> _service;

  @override
  DirectoryView? build() {
    final s = ref.watch(_service);
    if (s == null) return null;
    final sub = s.changes.listen((_) => state = DirectoryView.of(s));
    ref.onDispose(sub.cancel);
    return DirectoryView.of(s);
  }
}
