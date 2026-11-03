// SPDX-License-Identifier: Apache-2.0
// A desktop install with a wallet on disk is past Welcome, the only screen that answers the
// first-start step, so it is never held: also when the keychain came back empty (a new code
// signature) or holds a pending step from such a start (desktop/data/desk_levels.dart).
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
}
