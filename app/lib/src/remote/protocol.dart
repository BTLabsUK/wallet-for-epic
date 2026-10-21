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
}

/// [WalletSession] members the server answers, sent with the session handle.
enum SessionMember {
  dispose,
  mnemonic,
  mnemonicWithPin,
  changePin,
  confirmPinChange,
  cancelTransaction,
  repostTransaction,
  releaseStuckSend,
  createSendSlate,
  epicboxAddress,
  estimateFee,
  finalizeAndPost,
  sendEpicbox,
  startListener,
  stopListener,
  receiveSlate,
  scan,
  summary,
  refresh,
  transactions,
  enrichHistory,
  setTxNote,
  contacts,
  saveContact,
  deleteContact,
  exportHistory,
  exportHistoryCsv,
  importHistory,
  estimateMax,
  invoiceAddress,
  rotateInvoiceAddress,
  trustedServices,
  addTrustedService,
  removeTrustedService,
  drainInvoices,
  pendingInvoices,
  payInvoice,
  resendInvoiceReply,
  declineInvoice,
  paidInvoice,
  invoiceEvents,
  issueInvoice,
  issuedInvoices,
  issuedInvoice,
  withdrawInvoice,
  drainPayments,
  issuerEvents,
  peerCapability,
}

/// Interface members the client answers without the server.
const Set<String> localServiceMembers = {
  'validateMnemonic',
  'validateEpicboxAddress',
  // Reads a file on the app's own computer; refused by the client.
  'importWalletSeed',
};
const Set<String> localSessionMembers = {'supportsInvoices'};

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
