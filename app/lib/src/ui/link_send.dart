// SPDX-License-Identifier: Apache-2.0
/// Payment links on Send, for the phone and the desktop: what a refusal says, the trust line,
/// and opening a link (checks, then the refusal or the already-paid question, else Send).
/// Nothing here pays: the review and the PIN stay the only way.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../directory/directory.dart';
import '../l10n.dart';
import '../models.dart' show Chain;
import '../providers.dart';
import '../scan/incoming_link.dart' show linkClockProvider;
import '../scan/scan_router.dart';
import 'app_dialog.dart';
import 'sas_picture.dart';
import 'scan_result_sheet.dart';
import 'theme/tokens.dart';

/// The pictures of a listing code, for tests.
const Key linkTrustLineKey = ValueKey('link-trust-line');
const Key linkAmountNoteKey = ValueKey('link-amount-note');

int netOfChain(Chain chain) => chain == Chain.mainnet ? netMainnet : netFloonet;

/// What a refused link says.
String linkRefusalText(AppLocalizations l, LinkRefused refused) => switch (refused.reason) {
  LinkRefusal.notALink => l.linkNotALink,
  LinkRefusal.network => refused.madeFor == netFloonet ? l.linkMadeForFloonet : l.linkMadeForMainnet,
  LinkRefusal.changed => l.linkChanged,
  LinkRefusal.expired => l.linkExpired(localDay(l, refused.expiredAt!)),
  LinkRefusal.forOther => l.linkForOther,
};

/// The trust line's sentence.
String linkTrustText(AppLocalizations l, LinkOpened link) {
  final standing = link.standing;
  switch (standing.trust) {
    case DirectoryTrust.changedWallet:
      return l.linkTrustChanged(localDay(l, standing.changedSince!.toLocal()));
    case DirectoryTrust.notADirectoryYouUse:
      return l.linkTrustOther;
    case DirectoryTrust.directoryYouUse:
      final directory = link.directoryLabel;
      final name = link.payeeLabel;
      if (directory == null) return l.linkTrustDirectory;
      return name == null ? l.linkTrustListedBy(directory) : l.linkTrustListed(name, directory);
  }
}

/// Whether the amount in the form differs from the one the link asked for (a zero amount leaves
/// the choice to the payer).
bool amountEdited(LinkOpened link, BigInt? entered) {
  final asked = link.request.amount;
  return asked > BigInt.zero && entered != null && entered != asked;
}

/// The trust line of a link and the pictures of its listing code. The changed-wallet sentence
/// takes the warning tone.
class LinkTrustLine extends StatelessWidget {
  const LinkTrustLine({super.key, required this.link});

  final LinkOpened link;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final changed = link.standing.trust == DirectoryTrust.changedWallet;
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        key: linkTrustLineKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (changed) ...[Icon(Icons.warning_amber_rounded, size: 20, color: t.warn), const SizedBox(width: 8)],
              Expanded(child: Text(linkTrustText(l, link), style: style?.copyWith(color: changed ? t.warn : t.dim))),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            label: l.linkCodeLabel,
            child: Wrap(
              spacing: 6,
              children: [for (final w in codeWords(link.listingCode)) SasPicture(w, size: 24, excludeFromSemantics: true)],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Not the amount requested", under the amount.
class LinkAmountNote extends StatelessWidget {
  const LinkAmountNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      context.l10n.linkAmountEdited,
      key: linkAmountNoteKey,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim),
    ),
  );
}

/// The extra confirm before sending to a listing that changed wallet.
Future<bool> confirmChangedWallet(BuildContext context, LinkOpened link) {
  final l = context.l10n;
  return confirmAppDialog(
    context,
    title: l.linkChangedConfirmTitle,
    icon: Icons.warning_amber_rounded,
    tone: DialogTone.warn,
    description: linkTrustText(l, link),
    cancelLabel: l.commonCancel,
    confirmLabel: l.homeSendButton,
  );
}

/// Opens [code] for Send on the phone: the checks, then null after a sheet that says why not, or
/// the opened link (after "You paid this request on …" when the request was paid before, if the
/// user taps Pay again).
Future<LinkOpened?> openPaymentLink(
  BuildContext context,
  WidgetRef ref,
  PaymentLink code, {
  Future<void> Function()? scanAgain,
}) async {
  final session = ref.read(sessionProvider);
  final now = ref.read(linkClockProvider)();
  final outcome = await openLink(
    request: code.request,
    error: code.error,
    net: session == null ? netMainnet : netOfChain(session.chain),
    nowSeconds: now.millisecondsSinceEpoch ~/ 1000,
    verifier: ref.read(walletServiceProvider).verifyListingSignature,
    membership: ref.read(directoryMembershipProvider),
    memory: session?.linkMemory() ?? const LinkMemory(),
  );
  if (!context.mounted) return null;
  final l = context.l10n;
  switch (outcome) {
    case LinkRefused():
      final again = await showScanResultSheet(
        context,
        icon: Icons.link_off,
        title: linkRefusalText(l, outcome),
        primary: scanAgain != null ? l.qrScanAgain : l.commonClose,
      );
      if (again && scanAgain != null) await scanAgain();
      return null;
    case LinkOpened(:final standing) when standing.paidBefore != null:
      final pay = await showScanResultSheet(
        context,
        icon: Icons.history,
        title: l.linkPaidTitle,
        text: l.linkPaidBefore(localDay(l, standing.paidBefore!.toLocal())),
        secondary: l.commonCancel,
        primary: l.linkPayAgain,
      );
      return pay ? outcome : null;
    case LinkOpened():
      return outcome;
  }
}
