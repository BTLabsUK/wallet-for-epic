/// Which payment methods Send and Receive show: the ones Settings › Transactions offers
/// (`AppSettings.payments`), plus any a payment in use still needs. A method is never taken
/// away under a payment half-way: a file send waiting for its reply keeps File, and an address
/// of that kind pasted into Send keeps its method (see the screens).
library;

import '../models.dart';
import '../payment_prefs.dart';
import 'method_art.dart';

/// [m] as the Send and Receive screens name it.
TransferMethod transferMethodOf(PayMethod m) => switch (m) {
  PayMethod.epicbox => TransferMethod.epicbox,
  PayMethod.direct => TransferMethod.direct,
  PayMethod.qr => TransferMethod.qr,
  PayMethod.file => TransferMethod.file,
};

/// A payment made by file that still waits for the other wallet's reply: Finalize happens
/// from File, so File stays on Receive and Send while one is open.
bool hasPendingFileSend(Iterable<TxEntry>? txs) =>
    txs?.any(
      (x) =>
          x.kind == TxKind.sent &&
          x.status == TxStatus.awaitingRecipient &&
          x.transport == 'file',
    ) ??
    false;
