// SPDX-License-Identifier: Apache-2.0
/// What the user picked in a cancel confirmation whose cancel could also move the coins back
/// to this wallet (cancel_final.dart): an invoice this wallet paid, a send both wallets signed
/// that the network refused, the phone's Release coins. Shared by the phone and desktop dialogs.
library;

enum CancelChoice {
  /// Don't cancel: the dismiss, also what closing the dialog means.
  keep,

  /// Cancel without moving the coins back: free, nothing is spent, and the other side could
  /// still finish the payment (`spendBack: false`).
  stopWaiting,

  /// Cancel and move the coins back to this wallet, for the normal network fee, so the old
  /// payment can never go through (`spendBack: true`, today's cancel).
  cancelForSure,
}

extension CancelChoiceX on CancelChoice {
  bool get cancels => this != CancelChoice.keep;
  bool get spendBack => this == CancelChoice.cancelForSure;
}
