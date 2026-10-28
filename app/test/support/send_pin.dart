// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every send asks the wallet's PIN right before money moves. The send tests' wallets have
/// this one.
const String sendTestPin = '123456';

/// A secret store holding a mainnet wallet sealed under [sendTestPin].
MemorySecretStore sendPinStore() =>
    MemorySecretStore()
      ..values['wallet.mainnet.pinSealed'] = fakeSealedPassword(sendTestPin);

/// Lets [session] check the PIN, as a session opened by a [FakeWalletService] can.
void allowPinCheck(FakeWalletSession session, [FakeWalletService? service]) =>
    session.owner ??= service ?? FakeWalletService();

/// Answers the PIN dialog when it shows; does nothing when it does not. [settle] false pumps
/// one frame instead of settling, for a send whose spinner turns.
Future<void> answerPin(WidgetTester tester, {bool settle = true}) async {
  final field = find.widgetWithText(TextField, 'PIN');
  if (field.evaluate().isEmpty) return;
  await tester.enterText(field, sendTestPin);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // The PIN check, then the send starting.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }
}
