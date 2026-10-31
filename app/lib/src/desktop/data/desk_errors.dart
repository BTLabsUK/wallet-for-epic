// SPDX-License-Identifier: Apache-2.0
/// The words of the desktop's errors: what screens show for an error the data layer threw.
/// Screens import this, never the LEPIC adapter (`lepic_desk_wallet.dart`).
library;

import 'package:flutter/services.dart' show PlatformException;

import '../../advanced.dart' show NetworkMode;
import '../../l10n.dart' show AppLocalizations, englishStrings;
import '../../models.dart';
import '../../network_gate.dart';
import '../../pairing_text.dart';
import '../../secret_store_api.dart' show SecretProtectError;
import '../../ui/network_mode_text.dart' show networkModeName;
import 'models.dart' show DeskError;

/// A second scan asked while one runs.
const String scanRunning = 'A scan is already running.'; // l10n-ok: the English the tests compare; the throws word deskErrScanRunning

/// Why a cancel was refused: LEPIC reports a payment in the pool or on chain as invalid input.
const String cancelRefusedText = 'Not cancelled: the node already has this payment.'; // l10n-ok: the English the tests compare; the throws word deskErrCancelRefused

/// A keychain read or write macOS refused (flutter_secure_storage reports the OSStatus as the
/// code): the login keychain's password is wrong (-25293) or it is locked and may not ask
/// (-25308), the user cancelled its prompt (-128), or the app lacks the entitlement (-34018).
/// An unsigned app meets these after every update (a new signature) or a password change.
bool isMacKeychainRefusal(Object error) =>
    error is PlatformException && const {'-25293', '-25308', '-128', '-34018'}.contains(error.code);

/// [error] in [l]'s language; English without [l] (logs, and callers not yet localised).
String deskErrorText(Object error, [AppLocalizations? l]) {
  l ??= englishStrings;
  if (error is DeskError) return error.text(l);
  if (error is SecretProtectError) return l.deskErrSecretProtect;
  if (error is PlainHttpOffWithTor) return l.sendPlainHttpOffWithTor;
  // The network mode refused it (network_gate.dart).
  if (error is NetBlocked) {
    return error.mode == NetworkMode.torOnly ? l.deskSetAdvModeTorOnlyText : l.statusOffByMode(networkModeName(l, error.mode));
  }
  if (isMacKeychainRefusal(error)) return l.deskErrMacKeychain;
  if (error is! WalletError) return l.deskErrSomethingWrong;
  final detail = error.message.split('\n').first.trim();
  return switch (error.kind) {
    WalletErrorKind.wrongPassword => l.deskErrWrongPassword,
    WalletErrorKind.invalidMnemonic => l.deskErrPhraseInvalid,
    WalletErrorKind.walletAlreadyExists => l.deskErrWalletExists,
    WalletErrorKind.walletNotFound => l.deskErrWalletNotFound,
    WalletErrorKind.nodeUnreachable => l.deskErrNodeNotAnswering,
    WalletErrorKind.notEnoughFunds => l.deskErrNotEnoughFunds,
    WalletErrorKind.invalidSlate ||
    WalletErrorKind.notQrSlate ||
    WalletErrorKind.foreignQrCode ||
    WalletErrorKind.mixedQrCodes ||
    WalletErrorKind.invalidQrCode ||
    WalletErrorKind.qrCodeTooLarge => l.deskErrNotTxFile,
    WalletErrorKind.transportFailed => l.deskErrEpicboxUnreachable,
    WalletErrorKind.httpUrlInvalid => l.deskErrNotHttpAddress,
    WalletErrorKind.plainHttpNotAllowed => l.deskErrPlainHttp,
    WalletErrorKind.onionAddressInvalid => l.deskErrNotOnion,
    WalletErrorKind.torNotRunning => l.deskErrTorNotConnected,
    WalletErrorKind.onionUnreachable => l.deskErrOnionUnreachable,
    WalletErrorKind.chainBusy || WalletErrorKind.walletBusy => l.deskErrWalletBusy,
    WalletErrorKind.networkOff => l.statusOffByMode(networkModeName(l, NetGate.mode)),
    WalletErrorKind.damagedDatabase => l.deskErrDbDamaged,
    WalletErrorKind.paymentExpired => detail.isEmpty ? l.deskErrPaymentExpired : detail,
    WalletErrorKind.invoiceNotFound => l.deskErrInvoiceNotFound,
    WalletErrorKind.amountMismatch => l.deskErrAmountMismatch,
    WalletErrorKind.invoiceAlreadyPaid => l.deskErrInvoicePaid,
    WalletErrorKind.invoiceLockedAboveTip => l.deskErrInvoiceLocked,
    WalletErrorKind.invoiceChanged => l.deskErrInvoiceChanged,
    WalletErrorKind.invoiceNotForThisChain => l.reqOtherChain,
    WalletErrorKind.invalidArgument => detail == sendUnbuildable ? l.deskErrSendUnbuildable : detail == nothingToConsolidate ? l.deskErrNothingToConsolidate : detail.isEmpty ? l.deskErrNotAccepted : l.deskErrNotAcceptedDetail(detail),
    WalletErrorKind.io => detail.isEmpty ? l.deskErrDisk : l.deskErrDiskDetail(detail),
    WalletErrorKind.pairingFailed => pairingFailureText(l, pairingFailureOf(error) ?? PairingFailure.invalid),
    WalletErrorKind.restoreScanRequired => l.deskErrRestoreScanRequired,
    WalletErrorKind.inputsSpentElsewhere => l.deskErrInputsSpentElsewhere,
    WalletErrorKind.inputsSpentByOwnPayment || WalletErrorKind.peerInputsSpent => l.errorPaymentCancelledCoinsMoved,
    WalletErrorKind.phraseMismatch => l.deskOnbForgotOtherWallet(l.deskOnbUnlockThisWallet),
    WalletErrorKind.unsupported ||
    WalletErrorKind.cancelled ||
    WalletErrorKind.other => detail.isEmpty ? l.deskErrSomethingWrong : detail,
  };
}

/// Why tor is down or the onion is not published, for the Tor line.
String torFailureText(AppLocalizations l, TorFailure? f) => switch (f) {
  TorFailure.missing => l.deskErrTorMissing,
  TorFailure.network => l.deskErrTorNetwork,
  TorFailure.clock => l.deskErrTorClock,
  TorFailure.publish || TorFailure.keys || TorFailure.listener => l.deskErrOnionNotPublished,
  TorFailure.start => l.deskErrTorStart,
  TorFailure.stopped || null => l.deskErrTorStopped,
};
