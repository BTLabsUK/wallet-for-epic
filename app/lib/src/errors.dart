import 'wallet_service.dart';

/// Turns anything thrown by the wallet layer into a sentence for the user.
///
/// Never returns a stack trace. Unknown errors get a generic message.
String describeError(Object error) {
  if (error is WalletError) {
    return switch (error.kind) {
      WalletErrorKind.invalidMnemonic =>
        'The recovery phrase is not valid. Check each word and the word order.',
      WalletErrorKind.wrongPassword => 'Wrong password.',
      WalletErrorKind.walletAlreadyExists =>
        'A wallet already exists for this network.',
      WalletErrorKind.walletNotFound => 'No wallet found for this network.',
      WalletErrorKind.nodeUnreachable =>
        'Cannot reach the node. Check the node URL and your connection.',
      WalletErrorKind.notEnoughFunds =>
        'Not enough spendable funds for this amount plus the fee.',
      WalletErrorKind.invalidSlate =>
        'This slate is not valid for this step. Check that you pasted the '
            'complete JSON.',
      WalletErrorKind.invalidArgument => _withDetail(
        'Invalid input.',
        error.message,
      ),
      WalletErrorKind.transportFailed => _withDetail(
        'Could not reach the recipient.',
        error.message,
      ),
      WalletErrorKind.io => _withDetail(
        'Could not read or write wallet files.',
        error.message,
      ),
      WalletErrorKind.other => _withDetail('Wallet error.', error.message),
    };
  }
  if (error is FormatException) return error.message;
  return 'Unexpected error. Please try again.';
}

String _withDetail(String summary, String detail) {
  final firstLine = detail.trim().split('\n').first;
  return firstLine.isEmpty ? summary : '$summary $firstLine';
}
