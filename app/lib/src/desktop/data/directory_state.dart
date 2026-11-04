// SPDX-License-Identifier: Apache-2.0
/// The desktop's directories: the open wallet's [DirectoryService] (shared with the phone,
/// `directory/`) and the providers over it. The shell's 45 s tick, a window focus and the unlock
/// call [DirectoryService.sync]; nothing runs while the app is closed.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../directory/directory_providers.dart';
import '../../directory/directory_service.dart';
import '../../directory/directory_store.dart';
import '../../models.dart' show Chain;
import '../../network_gate.dart';
import '../../providers.dart' show secretStoreProvider;
import 'state.dart';

/// The open wallet's directories, or null while locked. Its host follows the session through a
/// reopen, like the devices' host does.
final deskDirectoryServiceProvider = Provider<DirectoryService?>((ref) {
  final account = ref.watch(deskProvider.select((s) => s.account == null ? null : (s.account!.id, s.account!.network)));
  if (account == null) return null;
  final api = ref.read(deskApiProvider);
  final host = api.directoryHost(online: () => !NetGate.epicboxOff && !torOnlyWaiting);
  if (host == null) return null;
  final service = DirectoryService(
    host: host,
    store: DirectoryStore(ref.watch(secretStoreProvider), chain: account.$2 == 'floonet' ? Chain.floonet : Chain.mainnet, walletId: account.$1),
    onDrained: (_) => unawaited(ref.read(deskProvider.notifier).reloadWallet()),
  );
  ref.onDispose(service.dispose);
  unawaited(service.load().then((_) => service.sync(DirectorySyncTrigger.unlock)).catchError((Object _) {}));
  return service;
});

final deskDirectories = DirectoryProviders(deskDirectoryServiceProvider);
