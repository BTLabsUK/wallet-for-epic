// SPDX-License-Identifier: Apache-2.0
/// The words of the messages the wallet keeps unread (LEPIC's quarantine, [KeptMessage]), for
/// the phone sheet and the desktop dialog that the Needs a look row opens: what each one is,
/// why it was not read, and the facts copied for support.
library;

import '../../l10n/app_localizations.dart';
import '../pairing_api.dart';
import 'common.dart';

/// What [m] is, as far as its reason tells: a payment, a payment or invoice file, a contact
/// notice, or unknown (a hold covers any message).
String keptKind(AppLocalizations l, KeptMessage m) => switch (m.reason) {
  KeptReason.receiptCap || KeptReason.receiveRefused => l.msgKeptKindPayment,
  KeptReason.undecodableSlate => l.msgKeptKindSlate,
  KeptReason.unknownNotice => l.msgKeptKindNotice,
  KeptReason.holdBound || KeptReason.other => l.msgKeptKindUnknown,
};

/// Why [m] was not read, in plain words: only what LEPIC records.
String keptWhy(AppLocalizations l, KeptMessage m) => switch (m.reason) {
  KeptReason.holdBound => l.msgKeptWhyHold,
  KeptReason.undecodableSlate => l.msgKeptWhySlate,
  KeptReason.unknownNotice => l.msgKeptWhyNotice,
  KeptReason.receiptCap => l.msgKeptWhyCap,
  KeptReason.receiveRefused => l.msgKeptWhyRefused,
  KeptReason.other => l.msgKeptWhyOther,
};

/// "From Anna", or "From a paired contact" when the contact is no longer known ([name] empty).
String keptFrom(AppLocalizations l, String name) => name.isEmpty ? l.msgKeptFromUnknown : l.msgKeptFrom(name);

/// The facts of [kept] for support, in English and in the core's own words: no names, the
/// contact's address shortened. [addressOf] gives a contact's Epicbox address, when known.
String keptSupportText(List<KeptMessage> kept, {required String? Function(String contactId) addressOf, String? appVersion}) {
  final b = StringBuffer('Messages not read: ${kept.length}');
  if (appVersion != null && appVersion.isNotEmpty) b.write('\nApp: $appVersion');
  for (final m in kept) {
    b
      ..write('\n\nid: ${m.id}')
      ..write('\nreason: ${m.code}')
      ..write('\nfirst seen: ${m.firstSeen.toUtc().toIso8601String()}')
      ..write('\ntries: ${m.attempts}')
      ..write('\nsize: ${m.size} bytes')
      ..write('\ncontact: ${m.contactId}');
    final address = addressOf(m.contactId);
    if (address != null && address.isNotEmpty) b.write('\naddress: ${shortAddress(address)}');
  }
  return b.toString();
}

/// "Arrived 21 Sep 2026, 14:05".
String keptArrived(AppLocalizations l, KeptMessage m) => l.msgKeptArrived(formatDateTime(l, m.firstSeen.toLocal()));
