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
        'This transaction text is not valid for this step. Check that you '
            'pasted all of it.',
      WalletErrorKind.invalidArgument =>
        _plainSentence(error.message) ??
            _withDetail('Invalid input.', error.message),
      WalletErrorKind.transportFailed => _withDetail(
        'Could not reach the recipient.',
        error.message,
      ),
      WalletErrorKind.chainBusy =>
        'The wallet is still busy on the other network. Wait a moment and try '
            'again, or close and reopen the app.',
      WalletErrorKind.walletBusy =>
        'The wallet is still finishing a task. Try again in a moment.',
      // The core's sentence says whether the funds are unlocked now or at the next refresh;
      // the fallback claims neither.
      WalletErrorKind.paymentExpired =>
        _plainSentence(error.message) ??
            'The answer to this payment came too late, so the payment was '
                'cancelled. Nothing was sent.',
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

/// History-file messages the core writes for people, without a final full stop.
const List<String> _historyFileMessages = [
  'This is not a history file',
  'This history file',
];

/// [detail]'s first line when it is already a sentence for the user, so no "Invalid input."
/// needs to go in front: it starts with a capital and ends with a full stop, question or
/// exclamation mark, or it is one of the core's history-file messages (given a full stop).
String? _plainSentence(String detail) {
  final line = detail.trim().split('\n').first.trim();
  if (line.isEmpty) return null;
  if (_historyFileMessages.any(line.startsWith)) {
    return RegExp(r'[.!?]$').hasMatch(line) ? line : '$line.';
  }
  final capital = RegExp(r'^[A-Z]').hasMatch(line);
  return capital && RegExp(r'[.!?]$').hasMatch(line) ? line : null;
}

String _withDetail(String summary, String detail) {
  final firstLine = detail.trim().split('\n').first;
  return firstLine.isEmpty ? summary : '$summary $firstLine';
}
