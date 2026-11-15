// SPDX-License-Identifier: Apache-2.0
// LEPIC's `native_direct`, which the experimental "epic1 payments" switch stored before epic1
// became a payment method: a wallet that stored it on has it stored off at open, and nothing
// sets it again. Against a stand-in `EpicWallet`; no native library is loaded.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

import 'support/no_boosts.dart';

class _Wallet with NoBoosts implements lepic.EpicWallet {
  _Wallet(this.stored);

  bool stored;
  final List<bool> writes = [];

  /// Set: reading the setting fails with this.
  Object? readError;

  @override
  bool get isDisposed => false;
  @override
  bool nativeDirectInUse() => stored;
  @override
  bool nativeDirect() => readError == null ? stored : throw readError!;
  @override
  void setNativeDirect({required bool enabled}) {
    writes.add(enabled);
    stored = enabled;
  }

  @override
  void lock() {}
  @override
  void dispose() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');
}

void main() {
  test('stored on by the old experimental switch: stored off, once', () {
    final wallet = _Wallet(true);
    final session = LepicWalletSession(wallet);
    addTearDown(session.dispose);
    session.retireNativeDirect();
    expect(wallet.writes, [false]);
    expect(wallet.stored, isFalse);
    session.retireNativeDirect();
    expect(wallet.writes, [false], reason: 'already off: nothing is written');
  });

  test('never turned on: nothing is written', () {
    final wallet = _Wallet(false);
    final session = LepicWalletSession(wallet);
    addTearDown(session.dispose);
    session.retireNativeDirect();
    expect(wallet.writes, isEmpty);
  });

  test('a setting that cannot be read does not fail the unlock', () {
    final wallet = _Wallet(true)..readError = lepic.WalletError(kind: lepic.WalletErrorKind.values.first, code: 0, message: 'x');
    final session = LepicWalletSession(wallet);
    addTearDown(session.dispose);
    expect(session.retireNativeDirect, returnsNormally);
    expect(wallet.writes, isEmpty);
  });
}
