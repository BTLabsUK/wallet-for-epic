/// Which payment methods Send and Receive show: the ones Settings › Transactions offers
/// (`AppSettings.payments`), plus any a payment in use still needs. A method is never taken
/// away under a payment half-way: a file send waiting for its reply keeps Direct · File Transfer,
/// and an address
/// of that kind pasted into Send keeps its method (see the screens).
library;

import '../models.dart';
import '../payment_prefs.dart';
import 'method_art.dart';

/// [m] as the Send and Receive screens name it (Link · HTTP and Link · Tor are one Link
/// there: the address picks the route).
TransferMethod transferMethodOf(MethodKind m) => switch (m) {
  MethodKind.epicbox => TransferMethod.epicbox,
  MethodKind.linkHttp || MethodKind.linkTor => TransferMethod.direct,
  MethodKind.directQr => TransferMethod.qr,
  MethodKind.directFile => TransferMethod.file,
};

/// Sends over Epicbox that still wait for the recipient's reply: Settings warns before Epicbox
/// is turned off while any is (the reply arrives once it is on again).
int pendingEpicboxSends(Iterable<TxEntry>? txs) =>
    txs
        ?.where((x) => x.kind == TxKind.sent && x.status == TxStatus.awaitingRecipient && x.transport == 'epicbox')
        .length ??
    0;

/// A payment made by file that still waits for the other wallet's reply: Finalize happens
/// from Direct · File Transfer, so it stays on Receive and Send while one is open.
bool hasPendingFileSend(Iterable<TxEntry>? txs) =>
    txs?.any(
      (x) =>
          x.kind == TxKind.sent &&
          x.status == TxStatus.awaitingRecipient &&
          x.transport == 'file',
    ) ??
    false;
