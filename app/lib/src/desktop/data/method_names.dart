// SPDX-License-Identifier: Apache-2.0
/// The desktop names a payment method through `ui/method_icons.dart` (the one source):
/// Epicbox, Link · HTTP, Link · Tor, Direct · File Transfer. LEPIC's `TxMethod` names the
/// transport; [methodKindOf] maps it to the method.
library;

import '../../payment_method.dart';
import '../../ui/method_icons.dart' show MethodIcons;
import '../desk_l10n.dart' show AppLocalizations;
import 'models.dart' show TxMethod;

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
