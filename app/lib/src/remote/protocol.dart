// SPDX-License-Identifier: Apache-2.0
/// The wallet protocol's members and its own errors. `app/README.md` ("Web demo", the
/// protocol) describes the frames.
library;

import '../models.dart';

/// [WalletService] members the server answers. Names are the Dart names.
enum ServiceMember {
  inspectSlate,
  walletExists,
  nodeTip,
  create,
  open,
  createWithPin,
  openWithPin,
  pinFailures,
  deleteWallet,
  resetPassword,
}

/// [WalletSession] members the server answers, sent with the session handle.
enum SessionMember {
  dispose,
  mnemonic,
  changePassword,
  mnemonicWithPin,
  changePin,
  confirmPinChange,
  cancelTransaction,
  repostTransaction,
  resendEpicbox,
  releaseStuckSend,
  createSendSlate,
  epicboxAddress,
  restoreScanRequired,
  fingerprint,
  estimateFee,
  finalizeAndPost,
  sendEpicbox,
  startListener,
  stopListener,
  receiveSlate,
  scan,
  summary,
  minimumConfirmations,
  setMinimumConfirmations,
  refresh,
  transactions,
  enrichHistory,
  setTxNote,
  setTxLabel,
  setTxDetails,
  contacts,
  saveContact,
  deleteContact,
  favouriteContacts,
  setFavouriteContact,
  exportHistory,
  exportHistoryCsv,
  importHistory,
  estimateMax,
  drainInvoices,
  pendingInvoices,
  payInvoice,
  payRequestFile,
  resendInvoiceReply,
  declineInvoice,
  paidInvoice,
  invoiceEvents,
  issuedInvoices,
  issuedInvoice,
  withdrawInvoice,
  drainPayments,
  issuerEvents,
  outputs,
  estimateSplit,
  splitOutputs,
  estimateConsolidate,
  consolidateOutputs,
  spendOutputsToSelf,
  setServers,
  nodeTipFor,
  // [WalletSession.pairing]'s calls, one member each.
  pairingList,
  pairingGet,
  pairingForContact,
  pairingStrays,
  pairingRemoveStray,
  pairingMakeInvite,
  pairingCancelInvite,
  pairingOpenReply,
  pairingConfirmLink,
  pairingOpenInvite,
  pairingOpenWords,
  pairingAccept,
  pairingReplyLink,
  pairingOpenConfirm,
  pairingShowCard,
  pairingScanCard,
  pairingCheckWords,
  pairingCollect,
  pairingRemove,
  pairingSetSeal,
  pairingSetAllowInvoices,
  pairingAttach,
  pairingResolveKeys,
  pairingRequestPayment,
  pairingRequestFile,
  pairingSealSlate,
  pairingOpenSlate,
  pairingReceiveSealed,
  pairingFinalizeSealed,
  pairingPaySealedRequest,
  pairingSendViaMailbox,
  pairingPlainSlate,
  pairingUseImported,
  pairingSlateOf,
  pairingEvents,
}

/// PairingApi members the client answers without the server: linked devices' private
/// pairings (not offered through the protocol) and the Connection servers, which only apply to a
/// wallet that pairs in this process.
const Set<String> localPairingMembers = {
  'privateSupported',
  'privatePairings',
  'makePrivateInvite',
  'acceptPrivateInvite',
  'collectPrivate',
  'postPayload',
  'payloads',
  'ackPayloads',
  'setConnectionServers',
};

/// Interface members the client answers without the server.
const Set<String> localServiceMembers = {
  'validateMnemonic',
  'validateEpicboxAddress',
  'epicboxAddressOtherChain',
  'validateOnionAddress',
  // The payment QR is for people next to each other; the protocol does not carry it.
  'encodeQrSlate',
  'decodeQrSlate',
  // Reads a file on the app's own computer; refused by the client.
  'importWalletSeed',
  // Synchronous, so no call can answer it; refused by the client (the open wallet's
  // fingerprint goes to the server).
  'walletFingerprint',
};
const Set<String> localSessionMembers = {
  'supportsInvoices',
  // Linked devices are not offered through the remote protocol: no coins are held here;
  // answered by the client.
  'heldOutputs',
  'supportsRequestFiles',
  // Reach other computers or open a port on the server; refused by the client.
  'sendHttp',
  'resendHttp',
  'startHttpListener',
  'stopHttpListener',
  'httpListenerStatus',
  // Run a tor process and reach other computers from the server; refused by the client.
  'onionAddress',
  'startTor',
  'stopTor',
  'torStatus',
  'refreshTor',
  'torNetworkLost',
  'sendTor',
  'resendTor',
  // Route the server's own Epicbox connection through its tor; answered by the client.
  'setEpicboxOverTor',
  'epicboxOverTor',
  'expectTor',
  'setOnionRoutes',
  // Reads an old wallet's folder on the server's disk; refused by the client.
  'importLegacyHistory',
  // Answered by the client: it cancels the scan stream, and the server stops the scan.
  'cancelScan',
  // Linked devices are the app's own; refused by the client.
  'signWithAddressKey',
  'verifyAddressSignature',
  // The cold flow (Kill switch) is the wallet's own device's; refused by the client.
  'finishedPaymentText',
  'inspectFinished',
  'postFinished',
};

/// The largest frame the dispatcher reads, in UTF-8 bytes.
const int defaultMaxFrameBytes = 256 * 1024;

/// Calls and streams one channel may have running at once.
const int defaultMaxInFlight = 32;

/// Every pending call and stream fails with this once the connection is gone. Its kind is the
/// one the UI already shows as a connection problem.
const WalletError connectionClosed = WalletError(
  kind: WalletErrorKind.nodeUnreachable,
  message: 'the connection to the wallet server closed',
);

/// A session handle the server does not hold: never given, disposed, or dropped by it.
const WalletError unknownSession = WalletError(
  kind: WalletErrorKind.walletNotFound,
  message: 'unknown session',
);

/// Anything but a [WalletError] thrown on the server. The detail stays in the server's log.
const WalletError serverError = WalletError(
  kind: WalletErrorKind.other,
  message: 'server error',
);

const WalletError frameTooLarge = WalletError(
  kind: WalletErrorKind.invalidArgument,
  message: 'frame too large',
);

const WalletError badFrame = WalletError(
  kind: WalletErrorKind.invalidArgument,
  message: 'malformed frame',
);

const WalletError tooManyInFlight = WalletError(
  kind: WalletErrorKind.invalidArgument,
  message: 'too many calls in flight',
);

const WalletError idInUse = WalletError(
  kind: WalletErrorKind.invalidArgument,
  message: 'request id already in use',
);

WalletError unknownMember(String member) => WalletError(
  kind: WalletErrorKind.invalidArgument,
  message: 'unknown member $member',
);

WalletError refusedMember(String member) => WalletError(
  kind: WalletErrorKind.other,
  message: '$member is not available on this server',
);

/// A message the server sent on its own, outside any call: `{"push": name, ...}`.
class RpcPush {
  const RpcPush(this.name, this.data);

  final String name;

  /// The frame's other fields.
  final Map<String, Object?> data;

  @override
  String toString() => 'RpcPush($name)';
}
