// SPDX-License-Identifier: Apache-2.0
// A desktop install with a wallet on disk is past Welcome, the only screen that answers the
// first-start step, so it is never held: also when the keychain came back empty (a new code
// signature) or holds a pending step from such a start (desktop/data/desk_levels.dart).
import 'dart:io';

import 'package:epic_wallet/main_desktop.dart' show deskWalletsOnDisk;
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/desk_levels.dart';
import 'package:epic_wallet/src/levels/wallet_level.dart';
import 'package:epic_wallet/src/network_gate.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    NetGate.releaseFirstStart();
    NetGate.set(NetworkMode.standard);
  });

  final chosen = const LevelChosen(existingInstallLevel).encode();

  test('an empty keychain with a wallet on disk is not held', () async {
    final store = MemorySecretStore();
    expect(await deskHoldUntilFirstStart(store, walletsOnDisk: () async => true), isFalse);
    expect(NetGate.firstStartHold, isFalse);
    expect(store.values[levelKey], chosen);
  });

  test('a pending step with a wallet on disk is released', () async {
    final store = MemorySecretStore({levelKey: levelPendingValue});
    expect(await deskHoldUntilFirstStart(store, walletsOnDisk: () async => true), isFalse);
    expect(NetGate.firstStartHold, isFalse);
    expect(store.values[levelKey], chosen);
  });

  test('a fresh install with no wallet on disk is still held', () async {
    final store = MemorySecretStore();
    expect(await deskHoldUntilFirstStart(store, walletsOnDisk: () async => false), isTrue);
    expect(NetGate.firstStartHold, isTrue);
    expect(store.values[levelKey], levelPendingValue);
  });

  test('a failing disk check falls back to the keychain', () async {
    final store = MemorySecretStore();
    expect(await deskHoldUntilFirstStart(store, walletsOnDisk: () async => throw StateError('x')), isTrue);
    expect(store.values[levelKey], levelPendingValue);
  });

  group('the check at launch (main_desktop.dart)', () {
    late Directory data;
    setUp(() async => data = await Directory.systemTemp.createTemp('desk-wallets-on-disk-'));
    tearDown(() => data.delete(recursive: true));

    test("no wallets folder, or only the first wallet's empty folder: none", () async {
      expect(await deskWalletsOnDisk(data), isFalse);
      await Directory('${data.path}/wallets/mainnet').create(recursive: true);
      expect(await deskWalletsOnDisk(data), isFalse);
    });

    test('a file anywhere under wallets: a wallet is there', () async {
      await File('${data.path}/wallets/mainnet/lepic/wallet.db').create(recursive: true);
      expect(await deskWalletsOnDisk(data), isTrue);
    });
  });
}
