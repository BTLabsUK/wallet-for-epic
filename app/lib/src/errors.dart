// SPDX-License-Identifier: Apache-2.0
import 'advanced.dart' show NetworkMode;
import 'l10n.dart';
import 'network_gate.dart';
import 'pairing_text.dart';
import 'pin_wrap.dart' show PinKeyLost;
import 'wallet_service.dart';

/// Turns anything thrown by the wallet layer into a sentence for the user, in [l]'s language.
///
/// Never returns a stack trace. Unknown errors get a generic message. Log lines pass
/// [englishStrings], so the log stays readable for whoever receives it.
///
/// Some errors carry the core's own sentence, which is English. English shows it as it is.
/// Other languages show the matching translation where the sentence is one of the core's
/// fixed history-file messages, and otherwise a translated summary with the core's first line
/// as detail.
String describeError(AppLocalizations l, Object error) {
  if (error is PinKeyLost) return l.errorPinKeyLost;
  if (error is WalletError) {
    return switch (error.kind) {
      WalletErrorKind.invalidMnemonic => l.errorInvalidMnemonic,
      WalletErrorKind.wrongPassword => l.errorWrongPassword,
      WalletErrorKind.walletAlreadyExists => l.errorWalletAlreadyExists,
      WalletErrorKind.walletNotFound => l.errorWalletNotFound,
      WalletErrorKind.nodeUnreachable => l.errorNodeUnreachable,
      WalletErrorKind.notEnoughFunds => l.errorNotEnoughFunds,
      // An invoice that cannot be paid: before LEPIC named these, they came as invalidSlate.
      WalletErrorKind.invalidSlate ||
      WalletErrorKind.invoiceAlreadyPaid ||
      WalletErrorKind.invoiceLockedAboveTip ||
      WalletErrorKind.invoiceChanged => l.errorInvalidSlate,
      WalletErrorKind.invoiceNotForThisChain => l.reqOtherChain,
      WalletErrorKind.invalidArgument ||
      WalletErrorKind.invoiceNotFound ||
      WalletErrorKind.amountMismatch =>
        _coreSentence(l, error.message) ??
            _withDetail(l.errorInvalidInput, error.message),
      WalletErrorKind.transportFailed => _withDetail(
        l.errorTransportFailed,
        error.message,
      ),
      WalletErrorKind.chainBusy => l.errorChainBusy,
      WalletErrorKind.walletBusy => l.errorWalletBusy,
      WalletErrorKind.networkOff => l.netBlockKillSwitch,
      // The core's sentence says whether the funds are unlocked now or at the next refresh;
      // the fallback claims neither.
      WalletErrorKind.paymentExpired =>
        (l.localeName == 'en' ? _plainSentence(error.message) : null) ??
            l.errorPaymentExpired,
      WalletErrorKind.io ||
      WalletErrorKind.damagedDatabase => _withDetail(l.errorIo, error.message),
      // A bad address or URL: the core's sentence names what is wrong with it.
      WalletErrorKind.httpUrlInvalid ||
      WalletErrorKind.plainHttpNotAllowed ||
      WalletErrorKind.onionAddressInvalid =>
        _coreSentence(l, error.message) ??
            _withDetail(l.errorInvalidInput, error.message),
      // A Tor send that did not happen or did not arrive: the input was fine, so no "Invalid
      // input"; the detail ("tor did not connect in time", "not reached") is for the log.
      WalletErrorKind.torNotRunning => l.errorTorNotRunning,
      WalletErrorKind.onionUnreachable => l.errorOnionUnreachable,
      // The scanner words these itself; elsewhere a QR that is no payment reads like a file
      // that is none.
      WalletErrorKind.notQrSlate ||
      WalletErrorKind.foreignQrCode ||
      WalletErrorKind.mixedQrCodes ||
      WalletErrorKind.invalidQrCode ||
      WalletErrorKind.qrCodeTooLarge => l.errorInvalidSlate,
      WalletErrorKind.pairingFailed => pairingFailureText(
        l,
        pairingFailureOf(error) ?? PairingFailure.invalid,
      ),
      // Receive, send or an invoice before the restore's scan from block 0 has finished; Home
      // shows that scan (restore_scan.dart).
      WalletErrorKind.restoreScanRequired => l.errorRestoreScanRequired,
      // The key check beside the encrypted records did not match: nothing was touched.
      WalletErrorKind.wrongKey => l.errorStoreWrongKey,
      // Another wallet with this phrase spent the coins; the send is released and a refresh follows.
      WalletErrorKind.inputsSpentElsewhere => l.errorInputsSpentElsewhere,
      // A late post of a cancelled payment whose coins were moved: the node only says "internal
      // error", LEPIC tells which coins were gone (a spend back refused is CancelResult.alreadyPaid).
      WalletErrorKind.inputsSpentByOwnPayment ||
      WalletErrorKind.peerInputsSpent => l.errorPaymentCancelledCoinsMoved,
      WalletErrorKind.phraseMismatch ||
      WalletErrorKind.unsupported ||
      WalletErrorKind.cancelled ||
      WalletErrorKind.other => _withDetail(l.errorOther, error.message),
    };
  }
  if (error is ScanFailed) return _withDetail(l.errorScanFailed, error.detail);
  // Plain http:// to another device with the Tor switch on: a Tor exit could take it.
  if (error is PlainHttpOffWithTor) return l.sendPlainHttpOffWithTor;
  // The network mode refused it (network_gate.dart). The Advanced page's own lines say why.
  if (error is NetBlocked) {
    if (error.epicboxOff) return l.netBlockEpicboxOff;
    return switch (error.mode) {
      NetworkMode.torOnly => l.advModeTorOnlyLine,
      NetworkMode.killSwitch => l.netBlockKillSwitch,
      _ => l.netBlockNodeOnly,
    };
  }
  if (error is LocalizedFormatException) return error.text(l);
  if (error is FormatException) return error.message;
  return l.errorUnexpected;
}

/// The core reported a failed scan in its last progress event without throwing.
class ScanFailed implements Exception {
  const ScanFailed(this.detail);

  /// The core's English text, after "Scan failed:".
  final String detail;

  @override
  String toString() => 'ScanFailed: $detail';
}

/// History-file messages the core writes for people, without a final full stop.
const List<String> _historyFileMessages = [
  'This is not a history file',
  'This history file',
];

/// The core's fixed history-file sentences, translated. Exact English text: the core's tests
/// pin it (core/export.rs, core/session.rs). A message code in the bridge would replace this.
final List<(RegExp, String Function(AppLocalizations l, RegExpMatch m))>
_historyFileTranslations = [
  (
    RegExp(r'^This is not a history file exported by this app\.?$'),
    (l, _) => l.errorHistoryNotOurs,
  ),
  (
    RegExp(r'^This history file was made by a newer version of the app\.?$'),
    (l, _) => l.errorHistoryNewer,
  ),
  (
    RegExp(r'^This history file is damaged\.?$'),
    (l, _) => l.errorHistoryDamaged,
  ),
  (
    RegExp(r'^This history file belongs to a different wallet\.?$'),
    (l, _) => l.errorHistoryOtherWallet,
  ),
  (
    RegExp(
      r'^This history file is from (another network|\w+, but this wallet is on \w+)\.?$',
    ),
    (l, m) => l.errorHistoryOtherNetwork,
  ),
];

/// The core's [detail] as the whole message: the app's own words for a known history-file
/// sentence (in English too, where they say more than the core's), else in English as it is,
/// else null so a translated summary goes in front.
String? _coreSentence(AppLocalizations l, String detail) {
  final sentence = _plainSentence(detail);
  if (sentence == null) return null;
  final line = detail.trim().split('\n').first.trim();
  for (final (pattern, translate) in _historyFileTranslations) {
    final match = pattern.firstMatch(line);
    if (match != null) return translate(l, match);
  }
  return l.localeName == 'en' ? sentence : null;
}

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
