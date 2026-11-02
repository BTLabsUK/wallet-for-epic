// SPDX-License-Identifier: Apache-2.0
/// The words of Send's recipient field, the same on the phone and the desktop: the method line,
/// the clean-up line, the field's errors, the notices of what the mode holds and the reach
/// check. The rules are in `send_route.dart`; this file only names them.
library;

import '../l10n.dart' show AppLocalizations;
import '../payment_method.dart' show MethodKind;
import '../send_reach.dart';
import '../send_route.dart';

/// The method's name on the method line and in the review: Epicbox, Link · HTTPS, Link · HTTP,
/// Link · Tor.
String sendMethodName(AppLocalizations l, RecipientInput to) => switch (to.kind) {
  RecipientInputKind.epicbox => l.methodEpicbox,
  RecipientInputKind.https => l.sendRouteLinkHttps,
  RecipientInputKind.http => l.methodDirectHttp,
  RecipientInputKind.onion => l.methodDirectTor,
  _ => '',
};

/// The method switch (Settings › Transactions) the address needs, for the existing method-off
/// notes; null for none.
MethodKind? sendMethodKind(RecipientInput to) => switch (to.kind) {
  RecipientInputKind.epicbox => MethodKind.epicbox,
  RecipientInputKind.https || RecipientInputKind.http => MethodKind.linkHttp,
  RecipientInputKind.onion => MethodKind.linkTor,
  _ => null,
};

/// The host exactly as it will be contacted, as plain text: the Epicbox relay, the onion, or
/// `scheme://host:port/path` (the port always written).
String sendContactedText(RecipientInput to) => switch (to.kind) {
  RecipientInputKind.epicbox => to.host,
  RecipientInputKind.onion => to.host,
  RecipientInputKind.https => 'https://${to.hostShown}:${to.port}${to.path}',
  RecipientInputKind.http => 'http://${to.hostShown}:${to.port}${to.path}',
  _ => '',
};

/// The tag beside the method's name: this device, the local network, or Over Tor; null for none.
String? sendRouteTag(AppLocalizations l, RecipientInput to, {required bool phone, required bool overTor}) {
  if (to.isUrl && to.scope == HostScope.thisDevice) return phone ? l.sendRouteThisPhone : l.sendRouteThisComputer;
  if (to.isUrl && to.scope == HostScope.network) return l.sendRouteYourNetwork;
  if (overTor) return l.sendRouteOverTor;
  return null;
}

/// The field's error for [p].
String sendProblemText(AppLocalizations l, RecipientProblem p) => switch (p) {
  RecipientProblem.notAddress => l.sendProblemNotAddress,
  RecipientProblem.otherScheme => l.sendProblemOtherScheme,
  RecipientProblem.incomplete => l.sendProblemIncomplete,
  RecipientProblem.onionIncomplete => l.sendProblemOnion,
  RecipientProblem.badPort => l.sendProblemPort,
  RecipientProblem.credentials => l.sendProblemCredentials,
  RecipientProblem.badCharacters => l.sendProblemCharacters,
  RecipientProblem.tooLong => l.sendProblemTooLong,
};

/// The notice's sentence for [h].
String sendHoldText(AppLocalizations l, SendHold h) => switch (h) {
  SendHold.killSwitch => l.sendHeldKillSwitch,
  SendHold.nodeOnly => l.sendHeldNodeOnly,
  SendHold.torOnlyPlainHttp => l.sendHeldTorOnly,
  SendHold.torOnPlainHttp => l.sendHeldTorOn,
};

/// The notice's one action for [h].
String sendHoldAction(AppLocalizations l, SendHold h) => switch (h) {
  SendHold.killSwitch => l.sendHeldFixKillSwitch,
  SendHold.nodeOnly => l.sendHeldFixNodeOnly,
  SendHold.torOnlyPlainHttp => l.sendHeldFixTorOnly,
  SendHold.torOnPlainHttp => l.torTurnOff,
};

/// Why a contact's address is greyed in its Change menu.
String sendHoldReason(AppLocalizations l, SendHold h) => switch (h) {
  SendHold.killSwitch => l.sendHeldByKillSwitch,
  SendHold.nodeOnly => l.sendHeldByNodeOnly,
  SendHold.torOnlyPlainHttp => l.sendHeldByTorOnly,
  SendHold.torOnPlainHttp => l.sendHeldWhileTorOn,
};

/// Who the reach check asked, for its sentence: the host (with a port other than 443 or 80), or
/// "their Tor address".
String sendReachWho(AppLocalizations l, RecipientInput to) {
  if (to.kind == RecipientInputKind.onion) return l.sendReachTheirOnion;
  final port = to.port;
  return port == null || port == 443 || port == 80 ? to.hostShown : '${to.hostShown}:$port';
}

/// The reach check's failure line, and the line under it; null when there is none to show.
(String, String)? sendReachLines(AppLocalizations l, RecipientInput to, ReachResult r) => switch (r) {
  ReachResult.noAnswer => (l.sendReachNone(sendReachWho(l, to)), l.sendReachOpenFirst),
  ReachResult.notWallet => (l.sendReachNotWallet(sendReachWho(l, to)), l.sendReachCheckAddress),
  _ => null,
};
