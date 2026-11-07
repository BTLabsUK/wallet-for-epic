// SPDX-License-Identifier: Apache-2.0
/// When the one notice about the changed Tor address fires (onion_notice.dart): once for a
/// wallet from before the update, never for one made on this version, never without Tor.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/onion_notice.dart';
import 'package:epic_wallet/src/providers.dart' show secretStoreProvider;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/tor_build.dart' show torBuilt;
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;

const _password = 'test-pass-1234';

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

  group('onion notice on the desktop adapter', () {
    late Directory support;
    late MemorySecretStore secrets;
    late core.FakeWalletService service;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('desk-onion-notice-');
      secrets = MemorySecretStore();
      service = core.FakeWalletService(password: _password);
    });

    tearDown(() => support.delete(recursive: true));

    LepicDeskWallet wallet() => LepicDeskWallet(
      service: service,
      walletDir: (chain) async {
        final d = Directory(WalletRegistry.firstWalletDir(support.path, chain));
        await d.create(recursive: true);
        return d.path;
      },
      secrets: secrets,
      filesDir: () async => support,
      nodePoll: const Duration(hours: 1),
      rememberDir: () async => Directory('${support.path}/remember'),
    );

    ProviderContainer container(LepicDeskWallet w) {
      final c = ProviderContainer(
        overrides: [
          deskApiProvider.overrideWithValue(w),
          deskStoreProvider.overrideWithValue(DeskStore(secrets)),
          secretStoreProvider.overrideWithValue(secrets),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a new wallet opens without it; an old one sees it until OK, then never', () async {
      final w = wallet();
      await w.createWallet(password: _password);
      expect(await w.unlock(_password), isTrue);
      final c = container(w);
      await c.read(deskProvider.notifier).refresh();
      expect(c.read(deskProvider).account, isNotNull);
      expect(await c.read(deskOnionNoticeProvider.future), isFalse);

      // The same wallet as an update finds it: no marker.
      secrets.values.remove(onionNoticeKey('mainnet', null));
      c.invalidate(deskOnionNoticeProvider);
      expect(await c.read(deskOnionNoticeProvider.future), isTrue);
      await c.read(deskOnionNoticeProvider.notifier).dismiss();
      c.invalidate(deskOnionNoticeProvider);
      expect(await c.read(deskOnionNoticeProvider.future), isFalse);
      await w.dispose();
    }, skip: !torBuilt ? 'no Tor in this build' : null);

    test('a restored first wallet and a second wallet are marked at birth', () async {
      final w = wallet();
      await w.restoreWallet(password: _password, phrase: service.phrase.split(' '));
      expect(await onionNoticeDue(secrets, chain: 'mainnet', walletId: null, torBuilt: true), isFalse);
      await w.createWallet(name: 'Two', password: _password);
      final ids = [for (final e in await w.wallets()) e.id];
      expect(ids, hasLength(2));
      for (final id in ids) {
        final walletId = id.startsWith(WalletRegistry.legacyPrefix) ? null : id;
        expect(await onionNoticeDue(secrets, chain: 'mainnet', walletId: walletId, torBuilt: true), isFalse, reason: id);
      }
      await w.dispose();
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
