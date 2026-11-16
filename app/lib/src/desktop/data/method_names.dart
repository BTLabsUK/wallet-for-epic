// SPDX-License-Identifier: Apache-2.0
/// The desktop names a payment method through `ui/method_icons.dart` (the one source):
/// Epicbox, Link · HTTP, Link · Tor, Direct · File Transfer. LEPIC's `TxMethod` names the
/// transport; [methodKindOf] maps it to the method. An Epicbox route through a relay the status
/// site marks as Epicmail goes by that name ([relayListedAsEpicmail]).
library;

import '../../network.dart' show EpicboxRelay;
import '../../payment_method.dart';
import '../../ui/method_icons.dart' show MethodIcons;
import '../desk_l10n.dart' show AppLocalizations;
import 'models.dart' show EpicboxServer, TxMethod;

/// Whether the status site's list ([boxes], as the wallet's state holds it) marks [relay] as an
/// Epicmail relay. False for no relay, one the site does not list, and a list not read.
bool relayListedAsEpicmail(Iterable<EpicboxServer>? boxes, EpicboxRelay? relay) =>
    relay != null && (boxes ?? const []).any((b) => b.epicmail && b.port == relay.port && b.domain.toLowerCase() == relay.host.toLowerCase());

/// The method a payment over transport [m] belongs to.
MethodKind methodKindOf(TxMethod m) => switch (m) {
  TxMethod.epicbox => MethodKind.epicbox,
  TxMethod.http => MethodKind.linkHttp,
  TxMethod.tor => MethodKind.linkTor,
  TxMethod.file => MethodKind.directFile,
};

/// The full name of the method behind transport [m].
String methodLabel(AppLocalizations l, TxMethod m) => MethodIcons.fullName(l, methodKindOf(m));

/// The short name (badges, table cells, segments) of the method behind transport [m].
String methodShortLabel(AppLocalizations l, TxMethod m) => MethodIcons.shortName(l, methodKindOf(m));

/// The name of a method given as LEPIC names its transport (`epicbox`, `http`, `tor`, `file`);
/// anything else comes back as it is.
String methodLabelOfTransport(AppLocalizations l, String transport) {
  for (final m in TxMethod.values) {
    if (m.name == transport) return methodLabel(l, m);
  }
  return transport;
}
