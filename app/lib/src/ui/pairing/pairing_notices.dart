/// The pairing events as notices: docked under the app bar, one line, the next
/// step as its action. Mounted on home, so they show wherever the user is. It also looks for a
/// pairing link on the clipboard when the app comes to the front (Pairing UX plan 5).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../contacts.dart';
import '../../l10n.dart';
import '../../pairing_clipboard.dart' show PairingClipTrigger;
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../providers.dart' show homeProvider, pendingInvoicesProvider;
import '../../wallet_service.dart';
import '../common.dart';
import '../contact_page.dart';
import '../invoices_screen.dart';
import 'pair_check.dart';
import 'pairing_clip_offer.dart';
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

/// Invites whose "No answer from" was said this session.
final Set<String> _noAnswerSaid = {};

/// The text and level of [e]'s notice, or null for an event that shows none.
({String text, NoticeLevel level})? pairingNoticeOf(AppLocalizations l, PairingEvent e) {
  final name = e.name;
  // An invite of this wallet's that ran out unanswered: once per invite, and only when it has
  // a name to say ("No answer from" alone said nothing). Its Pending row stays (LNX3-2).
  if (e.kind == PairingEventKind.failed && (e.failure ?? PairingFailure.invalid) == PairingFailure.noAnswer) {
    if (name.trim().isEmpty) return null;
    final id = e.pairingId;
    if (id != null && !_noAnswerSaid.add(id)) return null;
  }
  String epic(BigInt? a) => a == null ? '' : localDigits(l, displayEpic(a));
  return switch (e.kind) {
    PairingEventKind.replied => (text: l.noticePairingReplied(name), level: NoticeLevel.success),
    PairingEventKind.confirmed => (text: l.noticePairingConfirmed(name), level: NoticeLevel.success),
    PairingEventKind.failed => (text: pairingFailureText(l, e.failure ?? PairingFailure.invalid, name: name), level: NoticeLevel.warning),
    PairingEventKind.keysRestored => (text: '${l.contactKeysBack(name)} ${l.contactKeysBackBody}', level: NoticeLevel.success),
    PairingEventKind.keysChanged => (text: l.noticeKeysChanged(name), level: NoticeLevel.warning),
    // A warning, so the "Saved as" that follows the attach queues behind it.
    PairingEventKind.keyCheckRefused => (text: l.noticeKeyCheckRefused(name), level: NoticeLevel.warning),
    PairingEventKind.invoiceFromContact => (text: l.noticeRequest(name, epic(e.amount)), level: NoticeLevel.info),
    PairingEventKind.withdrawalFromContact => (text: l.noticeWithdrawal(epic(e.amount), name), level: NoticeLevel.success),
    PairingEventKind.homeRelayUnreachable => (text: l.noticeRelayDown(name), level: NoticeLevel.warning),
    PairingEventKind.outboxStuck => (text: l.noticeOutboxStuck(name), level: NoticeLevel.warning),
    PairingEventKind.sealedUnopenable => (text: l.openSealedOtherTitle, level: NoticeLevel.warning),
    PairingEventKind.secondReply => (text: l.pairSecondReplyTitle(name), level: NoticeLevel.warning),
    PairingEventKind.duplicateRequests => (text: l.reqTwoSame(name, e.count, epic(e.amount)), level: NoticeLevel.warning),
    PairingEventKind.tooManyRequests => (text: l.noticeTooMany(name), level: NoticeLevel.warning),
    PairingEventKind.requestWithdrawn => (text: l.noticeWithdrew(name), level: NoticeLevel.info),
    PairingEventKind.unpaired => (text: l.noticeUnpaired(name), level: NoticeLevel.warning),
    // The payment's row and tracker move on by themselves.
    PairingEventKind.contactUpdated || PairingEventKind.sealedReceived || PairingEventKind.outboxDelivered || PairingEventKind.paymentFinalized => null,
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
  Timer? _clip;

  /// Once per return to the app, after its window has the focus again: Android 10 and later
  /// hand the clipboard only to the app in focus, which comes a moment after the resume.
  void _lookAtClipboard() {
    _clip?.cancel();
    _clip = Timer(const Duration(milliseconds: 400), () {
      if (mounted) lookForPairingLink(context, ref, PairingClipTrigger.resume).ignore();
    });
  }

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
      _lookAtClipboard();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _clip?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clip?.cancel();
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


  void _show(PairingEvent e) {
    final l = context.l10n;
    // A withdrawal, a withdrawn request or a mailbox payment's answer changes the wallet's
    // transactions.
    if (e.kind == PairingEventKind.withdrawalFromContact ||
        e.kind == PairingEventKind.requestWithdrawn ||
        e.kind == PairingEventKind.paymentFinalized) {
      ref.invalidate(homeProvider);
    }
    // A request from a contact: an open Invoices screen lists it now.
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
    // The navigator now, while this widget is mounted: the action may run after it was rebuilt
    // away, and a context of its own would then open nothing.
    final nav = Navigator.of(context);
    void push(Widget screen) => nav.push<void>(MaterialPageRoute<void>(builder: (_) => screen));
    final NoticeAction? action = switch (e.kind) {
      PairingEventKind.replied || PairingEventKind.confirmed when id != null =>
        NoticeAction(l.noticeCheckWords, () => push(CheckWordsScreen(pairingId: id))),
      PairingEventKind.failed || PairingEventKind.secondReply => NoticeAction(l.noticeOpen, () => push(const PendingInvitesScreen())),
      PairingEventKind.keysChanged ||
      PairingEventKind.keysRestored ||
      PairingEventKind.homeRelayUnreachable ||
      PairingEventKind.unpaired when contact != null =>
        NoticeAction(l.noticeOpen, () => push(ContactPage(contactId: contact.id, initial: contact))),
      PairingEventKind.invoiceFromContact ||
      PairingEventKind.duplicateRequests ||
      PairingEventKind.tooManyRequests => NoticeAction(l.noticeView, () => push(const InvoicesScreen())),
      PairingEventKind.withdrawalFromContact when e.slateId != null =>
        NoticeAction(l.noticeView, () {
          // The row's key is the wallet's; find it by its slate.
          final tx = ref.read(homeProvider).value?.transactions.where((t) => t.slateId == e.slateId).firstOrNull;
          push(TxDetailsScreen(txKey: tx?.key ?? 's:${e.slateId}'));
        }),
      _ => null,
    };
    final tag = switch (e.kind) {
      PairingEventKind.homeRelayUnreachable || PairingEventKind.keysChanged || PairingEventKind.keysRestored when id != null =>
        pairingContactNoticeTag(id),
      PairingEventKind.withdrawalFromContact when e.slateId != null => pairingSlateNoticeTag(e.slateId!),
      _ => null,
    };
    // Old keys not checked is news the user must not miss: it stays until closed.
    ref.read(noticeProvider.notifier).show(
      notice.text,
      level: notice.level,
      action: action,
      tag: tag,
      persistent: e.kind == PairingEventKind.keyCheckRefused,
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
