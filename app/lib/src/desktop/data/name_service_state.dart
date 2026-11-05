// SPDX-License-Identifier: Apache-2.0
/// The desktop's name services: the open wallet's [NameService] (shared with the phone,
/// `name_service/`) and the providers over it. The shell's 45 s tick, a window focus and the unlock
/// call [NameService.sync]; nothing runs while the app is closed.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../name_service/name_service_providers.dart';
import '../../name_service/name_service_service.dart';
import '../../name_service/name_service_store.dart';
import '../../name_service/receipts.dart';
import '../../models.dart' show Chain;
import '../../network_gate.dart';
import '../../providers.dart' show secretStoreProvider;
import 'state.dart';

/// The open wallet's name services, or null while locked. Its host follows the session through a
/// reopen, like the devices' host does.
final deskNameServiceProvider = Provider<NameService?>((ref) {
  final account = ref.watch(deskProvider.select((s) => s.account == null ? null : (s.account!.id, s.account!.network)));
  if (account == null) return null;
  final api = ref.read(deskApiProvider);
  final host = api.nameServiceHost(online: () => !NetGate.epicboxOff && !torOnlyWaiting);
  if (host == null) return null;
  final service = NameService(
    host: host,
    store: NameServiceStore(ref.watch(secretStoreProvider), chain: account.$2 == 'floonet' ? Chain.floonet : Chain.mainnet, walletId: account.$1),
    onDrained: (_) => unawaited(ref.read(deskProvider.notifier).reloadWallet()),
  );
  ref.onDispose(service.dispose);
  unawaited(service.load().then((_) => service.sync(NameServiceSyncTrigger.unlock)).catchError((Object _) {}));
  return service;
});

final deskNameServices = NameServiceProviders(deskNameServiceProvider);

/// The records of payments made from links, over the open wallet's meta file, for
/// [linkPaymentRecordsProvider]; a change bumps [linkPaymentTickProvider].
final deskLinkPayments = Provider<LinkPaymentRecords>((ref) {
  final account = ref.watch(deskProvider.select((s) => s.account == null ? null : (s.account!.id, s.account!.network)));
  if (account == null) return MemoryLinkPayments();
  return ref.read(deskApiProvider).linkPaymentRecords(onChange: () => ref.read(linkPaymentTickProvider.notifier).bump());
});
