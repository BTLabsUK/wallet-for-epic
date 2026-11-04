// SPDX-License-Identifier: Apache-2.0
/// The phone's directories: the open wallet's [DirectoryService] and its providers.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network_gate.dart';
import '../providers.dart';
import 'directory_providers.dart';
import 'directory_service.dart';
import 'directory_store.dart';

/// The open wallet's directories, or null while locked. Read on open; the app's foreground tick
/// and its resume call [DirectoryService.sync].
final directoryServiceProvider = Provider<DirectoryService?>((ref) {
  final session = ref.watch(sessionProvider);
  final config = ref.watch(walletConfigProvider.select((c) => c == null ? null : (chain: c.chain, walletId: c.walletId)));
  if (session == null || config == null) return null;
  final service = DirectoryService(
    host: SessionDirectoryHost(
      session,
      net: netOfChain(config.chain),
      verifier: ref.read(walletServiceProvider).verifyListingSignature,
      online: () => !NetGate.epicboxOff && !torOnlyWaiting,
    ),
    store: DirectoryStore(ref.watch(secretStoreProvider), chain: config.chain, walletId: config.walletId),
    onDrained: (_) {
      if (ref.exists(homeProvider)) ref.invalidate(homeProvider);
    },
  );
  ref.onDispose(service.dispose);
  unawaited(service.load().then((_) => service.sync(DirectorySyncTrigger.unlock)).catchError((Object _) {}));
  return service;
});

final phoneDirectories = DirectoryProviders(directoryServiceProvider);
