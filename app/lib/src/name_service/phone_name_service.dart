// SPDX-License-Identifier: Apache-2.0
/// The phone's name services: the open wallet's [NameService] and its providers.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network_gate.dart';
import '../providers.dart';
import 'name_service_providers.dart';
import 'name_service_service.dart';
import 'name_service_store.dart';
import 'receipts.dart';

/// The open wallet's name services, or null while locked. Read on open; the app's foreground tick
/// and its resume call [NameService.sync].
final nameServiceProvider = Provider<NameService?>((ref) {
  final session = ref.watch(sessionProvider);
  final config = ref.watch(walletConfigProvider.select((c) => c == null ? null : (chain: c.chain, walletId: c.walletId)));
  if (session == null || config == null) return null;
  final service = NameService(
    host: SessionNameServiceHost(
      session,
      net: netOfChain(config.chain),
      verifier: ref.read(walletServiceProvider).verifyListingSignature,
      online: () => !NetGate.epicboxOff && !torOnlyWaiting,
    ),
    store: NameServiceStore(ref.watch(secretStoreProvider), chain: config.chain, walletId: config.walletId),
    onDrained: (_) {
      if (ref.exists(homeProvider)) ref.invalidate(homeProvider);
    },
  );
  ref.onDispose(service.dispose);
  unawaited(service.load().then((_) => service.sync(NameServiceSyncTrigger.unlock)).catchError((Object _) {}));
  return service;
});

final phoneNameServices = NameServiceProviders(nameServiceProvider);

/// The records of payments made from links, over the open wallet's meta file, for
/// [linkPaymentRecordsProvider]; a change bumps [linkPaymentTickProvider].
final phoneLinkPayments = Provider<LinkPaymentRecords>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return MemoryLinkPayments();
  return session.linkPaymentRecords(onChange: () => ref.read(linkPaymentTickProvider.notifier).bump());
});
