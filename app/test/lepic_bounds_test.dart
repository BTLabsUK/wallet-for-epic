// SPDX-License-Identifier: Apache-2.0
// What the core no longer holds and the app keeps: a new password of 8 characters or more, and
// minimum confirmations of 1 to 30. A stand-in `EpicWallet` records what reaches LEPIC.
import 'package:epic_wallet/src/lepic_wallet_service.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lepic/lepic.dart' as lepic;

class _Wallet implements lepic.EpicWallet {
  final List<String> calls = [];

  @override
  bool get isDisposed => false;

  @override
  void lock() {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('reached LEPIC: ${invocation.memberName}');

  @override
  Stream<lepic.WalletEvent> events() => const Stream.empty();

  @override
  Future<void> setMinimumConfirmations({required BigInt count}) async => calls.add('confirmations $count');

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async => calls.add('password $newPassword');
}

void main() {
  late _Wallet wallet;
  late LepicWalletSession session;

  setUp(() {
    wallet = _Wallet();
    session = LepicWalletSession(wallet);
  });

  test('a new password under 8 characters is refused before LEPIC', () async {
    await expectLater(
      session.changePassword(currentPassword: 'old-password', newPassword: 'short77'),
      throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.invalidArgument)),
    );
    expect(wallet.calls, isEmpty);

    await session.changePassword(currentPassword: 'old-password', newPassword: 'long-enough');
    expect(wallet.calls, ['password long-enough']);
  });

  test('minimum confirmations stay 1 to 30', () async {
    for (final bad in [0, 31, -1, 1000]) {
      await expectLater(
        session.setMinimumConfirmations(bad),
        throwsA(isA<WalletError>().having((e) => e.kind, 'kind', WalletErrorKind.invalidArgument)),
        reason: '$bad',
      );
    }
    expect(wallet.calls, isEmpty);

    await session.setMinimumConfirmations(1);
    await session.setMinimumConfirmations(30);
    expect(wallet.calls, ['confirmations 1', 'confirmations 30']);
  });
}
