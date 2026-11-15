// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../onion_notice.dart' show markOnionNoticeSeen, onionNoticeDue;
import '../../providers.dart' show secretStoreProvider;
import '../../wallet_registry.dart' show WalletRegistry;
import 'state.dart';

/// Whether the open wallet still has the one notice about its changed Tor address to see
/// (onion_notice.dart): a wallet from before the onion's own key, once. False with no wallet
/// open and in a build without Tor.
final deskOnionNoticeProvider = AsyncNotifierProvider<DeskOnionNotice, bool>(DeskOnionNotice.new);

class DeskOnionNotice extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final account = ref.watch(deskProvider.select((s) => s.account));
    if (account == null) return false;
    return onionNoticeDue(ref.read(secretStoreProvider), chain: account.network, walletId: _walletIdOf(account.id));
  }

  /// OK: never again for this wallet.
  Future<void> dismiss() async {
    final account = ref.read(deskProvider).account;
    state = const AsyncData(false);
    if (account == null) return;
    try {
      await markOnionNoticeSeen(ref.read(secretStoreProvider), chain: account.network, walletId: _walletIdOf(account.id));
    } on Object catch (e) {
      logWarn('desk', 'onion notice marker not saved: ${e.runtimeType}');
    }
  }

  /// The registry id as the wallet's config id: null for wallet 1 (`legacy-<chain>`), as
  /// [WalletEntry.walletId] has it.
  static String? _walletIdOf(String? id) => id == null || id.startsWith(WalletRegistry.legacyPrefix) ? null : id;
}
