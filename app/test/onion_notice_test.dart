// SPDX-License-Identifier: Apache-2.0
/// When the one notice about the changed Tor address fires (onion_notice.dart): once for a
/// wallet from before the update, never for one made on this version, never without Tor.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/onion_notice.dart';
import 'package:epic_wallet/src/secret_store_api.dart';

void main() {
  group('onion notice', () {
    test('an existing wallet sees it once, also when dismissed without the link', () async {
      final store = MemorySecretStore();
      expect(await onionNoticeDue(store, chain: 'mainnet', walletId: null, torBuilt: true), isTrue);
      // Shown (or closed): marked.
      await markOnionNoticeSeen(store, chain: 'mainnet', walletId: null);
      expect(await onionNoticeDue(store, chain: 'mainnet', walletId: null, torBuilt: true), isFalse);
      // The next launch reads the same store: still not due.
      expect(await onionNoticeDue(store, chain: 'mainnet', walletId: null, torBuilt: true), isFalse);
    });

    test('a wallet made or restored on this version never sees it', () async {
      final store = MemorySecretStore();
      // Creation and restore write the marker before the wallet first opens.
      await markOnionNoticeSeen(store, chain: 'mainnet', walletId: 'w2');
      expect(await onionNoticeDue(store, chain: 'mainnet', walletId: 'w2', torBuilt: true), isFalse);
    });

    test('each wallet decides for itself', () async {
      final store = MemorySecretStore();
      await markOnionNoticeSeen(store, chain: 'mainnet', walletId: 'w2');
      expect(await onionNoticeDue(store, chain: 'mainnet', walletId: null, torBuilt: true), isTrue);
      expect(await onionNoticeDue(store, chain: 'floonet', walletId: 'w2', torBuilt: true), isTrue);
      expect(await onionNoticeDue(store, chain: 'mainnet', walletId: 'w2', torBuilt: true), isFalse);
    });

    test('a build without Tor shows nothing', () async {
      final store = MemorySecretStore();
      expect(await onionNoticeDue(store, chain: 'mainnet', walletId: null, torBuilt: false), isFalse);
    });

    test('a store that cannot be read shows nothing', () async {
      expect(await onionNoticeDue(_BrokenStore(), chain: 'mainnet', walletId: null, torBuilt: true), isFalse);
    });

    test('the marker key names the chain and the wallet', () {
      expect(onionNoticeKey('mainnet', null), 'onion_notice.mainnet.legacy');
      expect(onionNoticeKey('mainnet', 'w2'), 'onion_notice.mainnet.w2');
    });
  });
}

class _BrokenStore implements SecretStore {
  @override
  Future<String?> read(String key) => throw StateError('keyring locked');

  @override
  Future<void> write(String key, String value) => throw StateError('keyring locked');

  @override
  Future<void> delete(String key) => throw StateError('keyring locked');
}
