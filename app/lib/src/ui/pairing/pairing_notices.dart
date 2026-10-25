/// The pairing events as notices (SPEC 2.10): docked under the app bar, one line, the next
/// step as its action. Mounted on home, so they show wherever the user is.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../contacts.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../providers.dart' show homeProvider, pendingInvoicesProvider;
import '../../wallet_service.dart';
import '../common.dart';
import '../contact_page.dart';
import '../invoices_screen.dart';
import 'pair_check.dart';
import 'pending_invites.dart';
import '../tx_details_screen.dart';

/// Screens and dialogs that show a pairing's words, or open them on its next answer, add a
/// test here while they are up: the "answered" and "paired" notices for an event one of them
/// handles would only repeat what it shows.
final Set<bool Function(PairingEvent e)> pairingWordsOnScreen = {};

/// Pages that show an event's news themselves (a contact's relay or keys on its page, a
/// withdrawal on its transaction): the notice would repeat it, with a way to the page that is
/// already open.
final Set<bool Function(PairingEvent e)> pairingNewsOnScreen = {};

/// The tag of a contact's relay and keys notices: its page closes them when it opens.
String pairingContactNoticeTag(String pairingId) => 'pairing-contact:$pairingId';

/// The tag of a withdrawal's notice: its transaction page closes it when it opens.
String pairingSlateNoticeTag(String slateId) => 'pairing-slate:$slateId';

/// Whether [e] is an answer a screen already turns into the words check, or news an open page
/// already shows.
bool pairingEventOnScreen(PairingEvent e) =>
    ((e.kind == PairingEventKind.replied || e.kind == PairingEventKind.confirmed) && pairingWordsOnScreen.any((handles) => handles(e))) ||
    pairingNewsOnScreen.any((shows) => shows(e));

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

class _PairingNoticesState extends ConsumerState<PairingNotices> with WidgetsBindingObserver {
  /// The foreground tick of RFC 8.4: the mailboxes of contacts with something pending.
  static const _tick = Duration(seconds: 45);
  Timer? _timer;

  void _collect(PairingCollectTrigger trigger) {
    final api = ref.read(pairingApiProvider);
    if (api.supported) api.collect(trigger: trigger).ignore();
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _collect(PairingCollectTrigger.foreground));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _collect(PairingCollectTrigger.open);
      _startTick();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Home shows once the wallet is open or unlocked: every mailbox, then the tick.
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _collect(PairingCollectTrigger.open);
    });
    _startTick();
    ref.listenManual<AsyncValue<PairingEvent>>(pairingEventsProvider, (_, next) {
      final e = next.value;
      if (e != null && mounted) _show(e);
    });
    // A contact whose keys came back docks the notice on its page, whenever that opens.
    ref.listenManual(keysBackProvider, (_, _) {});
  }

  void _push(Widget screen) => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => screen));

  void _show(PairingEvent e) {
    final l = context.l10n;
    // A withdrawal or a withdrawn request changes the wallet's transactions.
    if (e.kind == PairingEventKind.withdrawalFromContact || e.kind == PairingEventKind.requestWithdrawn) {
      ref.invalidate(homeProvider);
    }
    // A request from a contact: an open Invoices screen lists it now (PAIR-AND-3).
    if (e.kind == PairingEventKind.invoiceFromContact || e.kind == PairingEventKind.requestWithdrawn) {
      ref.read(pendingInvoicesProvider.notifier).reload().ignore();
    }
    final notice = pairingNoticeOf(l, e);
    if (notice == null || pairingEventOnScreen(e)) return;
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
        NoticeAction(l.noticeView, () {
          // The row's key is the wallet's; find it by its slate.
          final tx = ref.read(homeProvider).value?.transactions.where((t) => t.slateId == e.slateId).firstOrNull;
          _push(TxDetailsScreen(txKey: tx?.key ?? 's:${e.slateId}'));
        }),
      _ => null,
    };
    final tag = switch (e.kind) {
      PairingEventKind.homeRelayUnreachable || PairingEventKind.keysChanged || PairingEventKind.keysRestored when id != null =>
        pairingContactNoticeTag(id),
      PairingEventKind.withdrawalFromContact when e.slateId != null => pairingSlateNoticeTag(e.slateId!),
      _ => null,
    };
    ref.read(noticeProvider.notifier).show(notice.text, level: notice.level, action: action, tag: tag);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
