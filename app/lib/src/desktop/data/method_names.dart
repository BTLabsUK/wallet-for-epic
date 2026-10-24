/// The one place the desktop names a payment method: Epicbox, Link Payment · HTTP, Link Payment · Tor or
/// File. Link is the method; HTTP and Tor are its transport, so neither stands alone as a
/// method. (Tor as the privacy switch is not a method and is worded where the switch is.)
library;

import '../desk_l10n.dart' show AppLocalizations;
import 'models.dart' show TxMethod;

String methodLabel(AppLocalizations l, TxMethod m) => switch (m) {
  TxMethod.epicbox => l.methodEpicbox,
  TxMethod.http => l.methodDirectHttp,
  TxMethod.tor => l.methodDirectTor,
  TxMethod.file => l.deskTxMethodFile,
};

/// The name of a method given as LEPIC names its transport (`epicbox`, `http`, `tor`, `file`);
/// anything else comes back as it is.
String methodLabelOfTransport(AppLocalizations l, String transport) {
  for (final m in TxMethod.values) {
    if (m.name == transport) return methodLabel(l, m);
  }
  return transport;
}
