/// The pairing events as notices (SPEC 2.10): docked under the app bar, one line, the next
/// step as its action. Mounted on home, so they show wherever the user is.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../contacts.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../providers.dart' show homeProvider;
import '../../wallet_service.dart';
import '../common.dart';
import '../contact_page.dart';
import '../invoices_screen.dart';
import 'pair_check.dart';
import 'pending_invites.dart';
import '../tx_details_screen.dart';

/// The text and level of [e]'s notice, or null for an event that shows none.
({String text, NoticeLevel level})? pairingNoticeOf(AppLocalizations l, PairingEvent e) {
  final name = e.name;
  String epic(BigInt? a) => a == null ? '' : localDigits(l, displayEpic(a));
  return switch (e.kind) {
    PairingEventKind.replied => (text: l.noticePairingReplied(name), level: NoticeLevel.success),
    PairingEventKind.confirmed => (text: l.noticePairingConfirmed(name), level: NoticeLevel.success),
    PairingEventKind.failed => (text: pairingFailureText(l, e.failure ?? PairingFailure.invalid, name: name), level: NoticeLevel.warning),
    PairingEventKind.keysRestored => (text: '${l.contactKeysBack(name)} ${l.contactKeysBackBody}', level: NoticeLevel.success),
    PairingEventKind.keysChanged => (text: l.noticeKeysChanged(name), level: NoticeLevel.warning),
    PairingEventKind.invoiceFromContact => (text: l.noticeRequest(name, epic(e.amount)), level: NoticeLevel.info),
    PairingEventKind.withdrawalFromContact => (text: l.noticeWithdrawal(epic(e.amount), name), level: NoticeLevel.success),
    PairingEventKind.homeRelayUnreachable => (text: l.noticeRelayDown(name), level: NoticeLevel.warning),
    PairingEventKind.outboxStuck => (text: l.noticeOutboxStuck(name), level: NoticeLevel.warning),
    PairingEventKind.sealedUnopenable => (text: l.openSealedOtherTitle, level: NoticeLevel.warning),
    PairingEventKind.secondReply => (text: l.pairSecondReplyTitle(name), level: NoticeLevel.warning),
    PairingEventKind.duplicateRequests => (text: l.reqTwoSame(name, e.count, epic(e.amount)), level: NoticeLevel.warning),
    PairingEventKind.tooManyRequests => (text: l.noticeTooMany(name), level: NoticeLevel.warning),
    PairingEventKind.requestWithdrawn => (text: l.noticeWithdrew(name), level: NoticeLevel.info),
    PairingEventKind.contactUpdated || PairingEventKind.sealedReceived || PairingEventKind.outboxDelivered => null,
  };
}

/// Listens to the open wallet's pairing events and shows each as a notice with the screen its
/// next step lives on. Draws nothing.
class PairingNotices extends ConsumerStatefulWidget {
  const PairingNotices({super.key});

  @override
  ConsumerState<PairingNotices> createState() => _PairingNoticesState();
}

class _PairingNoticesState extends ConsumerState<PairingNotices> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<PairingEvent>>(pairingEventsProvider, (_, next) {
      final e = next.value;
      if (e != null && mounted) _show(e);
    });
  }

  void _push(Widget screen) => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => screen));

  void _show(PairingEvent e) {
    final l = context.l10n;
    // A withdrawal or a withdrawn request changes the wallet's transactions.
    if (e.kind == PairingEventKind.withdrawalFromContact || e.kind == PairingEventKind.requestWithdrawn) {
      ref.invalidate(homeProvider);
    }
    final notice = pairingNoticeOf(l, e);
    if (notice == null) return;
    final id = e.pairingId;
    final contactId = id == null ? null : ref.read(pairingByIdProvider(id))?.contactId;
    final contact = contactId == null
        ? null
        : (ref.read(contactsProvider).value ?? const <Contact>[]).where((c) => c.id == contactId).firstOrNull;
    final NoticeAction? action = switch (e.kind) {
      PairingEventKind.replied || PairingEventKind.confirmed when id != null =>
        NoticeAction(l.noticeCheckWords, () => _push(CheckWordsScreen(pairingId: id))),
      PairingEventKind.failed || PairingEventKind.secondReply => NoticeAction(l.noticeOpen, () => _push(const PendingInvitesScreen())),
      PairingEventKind.keysChanged || PairingEventKind.keysRestored || PairingEventKind.homeRelayUnreachable when contact != null =>
        NoticeAction(l.noticeOpen, () => openContactPage(context, contact)),
      PairingEventKind.invoiceFromContact ||
      PairingEventKind.duplicateRequests ||
      PairingEventKind.tooManyRequests => NoticeAction(l.noticeView, () => _push(const InvoicesScreen())),
      PairingEventKind.withdrawalFromContact when e.slateId != null =>
        NoticeAction(l.noticeView, () => _push(TxDetailsScreen(txKey: 's:${e.slateId}'))),
      _ => null,
    };
    ref.read(noticeProvider.notifier).show(notice.text, level: notice.level, action: action);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
