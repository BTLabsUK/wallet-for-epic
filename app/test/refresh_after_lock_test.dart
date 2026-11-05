// SPDX-License-Identifier: Apache-2.0
// A refresh that finds the node out of reach reads the local balances, unless the wallet was
// locked while it waited: then the handle is gone and the refresh just ends, with no error
// outside the sync's catch. Against a stand-in `EpicWallet`; no native library is loaded.
import 'dart:async';

import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

/// A refresh that fails "node unreachable" once [answer] completes, and a handle that can be
/// disposed meanwhile; any other call fails the test.
class _Wallet implements lepic.EpicWallet {
  final answer = Completer<void>();
  bool disposed = false;
  int summaries = 0;

  @override
  bool get isDisposed => disposed;

  @override
  Stream<lepic.RefreshProgress> refresh() async* {
    await answer.future;
    throw const lepic.WalletError(kind: lepic.WalletErrorKind.nodeUnreachable, code: 0, message: 'no node');
  }

  @override
  Future<lepic.WalletSummary> summary({required bool refresh}) async {
    summaries++;
    if (disposed) throw StateError('Try to use `RustArc<dynamic>` after it has been disposed');
    throw StateError('not wanted in this test');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');
}

void main() {
  test('a refresh whose wallet was locked while the node did not answer ends quietly', () async {
    final wallet = _Wallet();
    final progress = LepicWalletSession(wallet).refresh(minimumConfirmations: BigInt.one).toList();
    wallet.disposed = true;
    wallet.answer.complete();
    expect(await progress, isEmpty);
    expect(wallet.summaries, 0, reason: 'nothing is read from a disposed handle');
  });
}
