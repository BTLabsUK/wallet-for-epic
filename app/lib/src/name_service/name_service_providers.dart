// SPDX-License-Identifier: Apache-2.0
/// Riverpod glue for name services, shared by the phone and the desktop: each app makes a
/// [NameServiceProviders] over its own provider of the open wallet's [NameService] (null
/// while locked) and the screens read [NameServiceProviders.view].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'name_service_model.dart';
import 'name_service_service.dart';
import 'membership.dart';
import 'receipts.dart';

/// What the screens show of the service: its book and where each words step stands.
class NameServiceView {
  const NameServiceView({required this.book, required this.steps, required this.loaded});

  factory NameServiceView.of(NameService s) => NameServiceView(
    book: s.book,
    steps: s.steps,
    loaded: s.loaded,
  );

  final NameServiceBook book;

  /// The steps of the pairings the service tracks; see [stepOf].
  final Map<String, HelloStep> steps;
  final bool loaded;

  /// The name service the user verified for [pairingId], or null: its page shows Join or Leave.
  NameServiceEntry? verifiedFor(String pairingId) {
    final e = book.byPairing(pairingId);
    return e != null && e.pinned ? e : null;
  }

  /// The name service a valid hello named on [pairingId], before the user compared the code.
  NameServiceEntry? helloFor(String pairingId) {
    final e = book.byPairing(pairingId);
    return e != null && !e.pinned ? e : null;
  }
}

class NameServiceProviders {
  NameServiceProviders(this.service);

  /// The app's provider of the open wallet's service.
  final Provider<NameService?> service;

  /// The view, rebuilt on every change; null while there is no service.
  late final NotifierProvider<NameServiceViewNotifier, NameServiceView?> view =
      NotifierProvider<NameServiceViewNotifier, NameServiceView?>(() => NameServiceViewNotifier(service));

  /// The name service verified for a pairing, null for none.
  late final nameServiceOfPairing = Provider.family<NameServiceEntry?, String>(
    (ref, pairingId) => ref.watch(view)?.verifiedFor(pairingId),
  );

  /// [NameServiceMembership] over the open wallet's service, for [nameServiceMembershipProvider].
  late final Provider<NameServiceMembership> membership = Provider<NameServiceMembership>(
    (ref) => ref.watch(service) ?? const NoNameServiceMembership(),
  );

  /// [NameServiceReceipts] over the open wallet's service, for [nameServiceReceiptsProvider].
  late final Provider<NameServiceReceipts> receipts = Provider<NameServiceReceipts>(
    (ref) => ref.watch(service) ?? const NoNameServiceReceipts(),
  );
}

class NameServiceViewNotifier extends Notifier<NameServiceView?> {
  NameServiceViewNotifier(this._service);

  final Provider<NameService?> _service;

  @override
  NameServiceView? build() {
    final s = ref.watch(_service);
    if (s == null) return null;
    final sub = s.changes.listen((_) => state = NameServiceView.of(s));
    ref.onDispose(sub.cancel);
    return NameServiceView.of(s);
  }
}
