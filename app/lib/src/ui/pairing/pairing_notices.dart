// SPDX-License-Identifier: Apache-2.0
/// The pairing events as notices: docked under the app bar, one line, the next
/// step as its action. Mounted on home, so they show wherever the user is. A request that
/// arrives from an address not in Contacts is dismissed here, before anyone sees it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../connection_grace.dart';
import '../../contacts.dart';
import '../../name_service/name_service_service.dart' show NameServiceSyncTrigger;
import '../../name_service/phone_name_service.dart' show nameServiceProvider;
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../providers.dart' show homeProvider, pendingInvoicesProvider, sessionProvider;
import '../../scan/scan_checks.dart' show CodeOrigin;
import '../../trust/profile_watch.dart';
import '../../wallet_service.dart';
import '../common.dart';
import '../contact_page.dart';
import '../invoices_screen.dart';
import '../levels/shell_pairing.dart' show offerPairRequest;
import '../scan_route.dart' show showPairingSheet;
import '../tx_details_screen.dart';
import 'invite_links.dart';
import 'pair_check.dart';
import 'pair_incoming.dart' show openPairingLink;
import 'pair_way1.dart' show PairRequestsScreen;

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
    ((e.kind == PairingEventKind.replied || e.kind == PairingEventKind.confirmed || e.kind == PairingEventKind.heard) &&
        pairingWordsOnScreen.any((handles) => handles(e))) ||
    pairingNewsOnScreen.any((shows) => shows(e));

/// Invites whose "No answer from" was said this session.
final Set<String> _noAnswerSaid = {};

/// The text and level of [e]'s notice, or null for an event that shows none.
({String text, NoticeLevel level})? pairingNoticeOf(AppLocalizations l, PairingEvent e) {
  final name = e.name;
  // A request of this wallet's that ran out unanswered: once per request, and only when it
  // has a name to say ("No answer from" alone said nothing). Its row stays.
  if (e.kind == PairingEventKind.failed && (e.failure ?? PairingFailure.invalid) == PairingFailure.noAnswer) {
    if (name.trim().isEmpty) return null;
    final id = e.pairingId;
    if (id != null && !_noAnswerSaid.add(id)) return null;
  }
  String epic(BigInt? a) => a == null ? '' : epicFor(l, a, unit: false);
  return switch (e.kind) {
    PairingEventKind.replied => (text: l.noticePairingReplied(name), level: NoticeLevel.success),
    PairingEventKind.confirmed => (text: l.noticePairingConfirmed(name), level: NoticeLevel.success),
    PairingEventKind.heard => (text: l.pairPairedWith(name), level: NoticeLevel.success),
    PairingEventKind.peerVerified => (text: l.pairConfirmedToo(name), level: NoticeLevel.info),
    PairingEventKind.ended => (text: pairingEndedText(l, e.endedReason ?? PairingEndReason.neverFinished, name), level: NoticeLevel.warning),
    PairingEventKind.requested => (text: l.pairWantsToPair(name), level: NoticeLevel.info),
    PairingEventKind.pairedElsewhere => (text: l.pairPairedOn(name), level: NoticeLevel.info),
    PairingEventKind.failed => (text: pairingFailureText(l, e.failure ?? PairingFailure.invalid, name: name), level: NoticeLevel.warning),
    PairingEventKind.keysRestored => (text: '${l.contactKeysBack(name)} ${l.contactKeysBackBody}', level: NoticeLevel.success),
    PairingEventKind.keysChanged => (text: l.noticeKeysChanged(name), level: NoticeLevel.warning),
    // A warning, so the "Saved as" that follows the attach queues behind it.
    PairingEventKind.keyCheckRefused => (text: l.noticeKeyCheckRefused(name), level: NoticeLevel.warning),
    PairingEventKind.invoiceFromContact => (text: l.noticeRequest(name, epic(e.amount)), level: NoticeLevel.info),
    PairingEventKind.withdrawalFromContact => (text: l.noticeWithdrawal(epic(e.amount), name), level: NoticeLevel.success),
    PairingEventKind.homeRelayUnreachable => (text: l.noticeRelayDown(name), level: NoticeLevel.warning),
    PairingEventKind.outboxStuck => (text: l.noticeOutboxStuck(name), level: NoticeLevel.warning),
    PairingEventKind.relayMoveRefused => (text: l.noticeRelayMoveRefused(name, e.relay ?? ''), level: NoticeLevel.warning),
    PairingEventKind.sealedUnopenable => (text: l.openSealedOtherTitle, level: NoticeLevel.warning),
    PairingEventKind.secondReply => (text: l.pairSecondReplyTitle(name), level: NoticeLevel.warning),
    PairingEventKind.duplicateRequests => (text: l.reqTwoSame(name, e.count, epic(e.amount)), level: NoticeLevel.warning),
    PairingEventKind.tooManyRequests => (text: l.noticeTooMany(name), level: NoticeLevel.warning),
    PairingEventKind.requestWithdrawn => (text: l.noticeWithdrew(name), level: NoticeLevel.info),
    PairingEventKind.unpaired => (text: l.noticeUnpaired(name), level: NoticeLevel.warning),
    // The payment's row, the contact page and the tracker move on by themselves.
    PairingEventKind.contactUpdated ||
    PairingEventKind.addressUpdated ||
    PairingEventKind.sealedReceived ||
    PairingEventKind.outboxDelivered ||
    // For the linked device only.
    PairingEventKind.requestAnswered ||
    PairingEventKind.paymentFinalized => null,
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
  late final PeerProfileWatch _profiles = PeerProfileWatch(ref.read(pairingClockProvider));

  void _collect(PairingCollectTrigger trigger) {
    final api = ref.read(pairingApiProvider);
    if (api.supported) api.collect(trigger: trigger).ignore();
    // The name services' payloads and listing drains go with every collect.
    final sync = trigger == PairingCollectTrigger.open ? NameServiceSyncTrigger.resume : NameServiceSyncTrigger.tick;
    unawaited(ref.read(nameServiceProvider)?.sync(sync) ?? Future<void>.value());
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

  /// An incoming pair invite (a tapped link, a scheme open): the confirm sheet, never a
  /// pairing by itself.
  Future<void> _pairInvite(BuildContext _, InviteLink link) async {
    if (!mounted) return;
    // A core without pairing: the sheet that says so, never the pairing calls.
    if (!ref.read(pairingSupportedProvider)) return showPairingSheet(context, link.invite, origin: CodeOrigin.link);
    // Just send and receive: a notice with See request, not the sheet over the screen.
    if (await offerPairRequest(context, ref, link.invite) || !mounted) return;
    await openPairingLink(context, ref, link.invite);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unregisterInviteHandler(InviteKind.pair, _pairInvite);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Home shows once the wallet is open or unlocked: every mailbox, then the tick.
    WidgetsBinding.instance.addObserver(this);
    registerInviteHandler(InviteKind.pair, _pairInvite);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _collect(PairingCollectTrigger.open);
    });
    _startTick();
    ref.listenManual<AsyncValue<PairingEvent>>(pairingEventsProvider, (_, next) {
      final e = next.value;
      if (e != null && mounted) unawaited(_show(e));
    });
    // A contact whose keys came back docks the notice on its page, whenever that opens.
    ref.listenManual(keysBackProvider, (_, _) {});
    // A paired contact that starts or stops taking payments, said once a day per direction.
    ref.listenManual(pairingsProvider, (_, next) {
      final records = next.value;
      if (records == null || !mounted) return;
      for (final c in _profiles.update(records)) {
        final l = context.l10n;
        final name = pairingName(c.record, ref.read(contactsProvider).value ?? const <Contact>[], l: l);
        ref.read(noticeProvider.notifier).show(c.takesPayments ? l.contactTakesPaymentsAgain(name) : l.contactNoPaymentsNamed(name), level: NoticeLevel.info);
      }
    }, fireImmediately: true);
  }

  Future<void> _show(PairingEvent e) async {
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
    // A request to pair: the list reads it again (and dismisses a stranger's once the address
    // book is known); only a contact's shows a notice. One that came before the book loaded
    // waits for it.
    var event = e;
    if (e.kind == PairingEventKind.requested) {
      if (!ref.read(contactsProvider).hasValue) {
        try {
          await ref.read(contactsProvider.future);
        } on Object {
          // Not loaded: no notice; the list shows the request once the book is known.
        }
        if (!mounted) return;
      }
      unawaited(ref.read(pairRequestsProvider.notifier).reload());
      final loaded = ref.read(contactsProvider);
      final keys = phoneContactKeys(loaded, closed: !(ref.read(sessionProvider)?.contactsAvailable ?? true));
      if (!requestFromContact(keys, e)) return;
      final key = epicboxKey(e.sender!);
      final contact = loaded.value!.where((c) => c.epicbox != null && epicboxKey(c.epicbox!) == key).firstOrNull;
      if (contact != null) event = PairingEvent(e.kind, requestId: e.requestId, sender: e.sender, name: contact.name);
    }
    final notice = pairingNoticeOf(l, event);
    if (notice == null || pairingEventOnScreen(event)) return;
    // Item 11: no server warning during the connection grace after start and resume; the
    // contact's page still says it.
    if (event.kind == PairingEventKind.homeRelayUnreachable && ref.read(connectionGraceProvider)) return;
    final id = event.pairingId;
    // An answer or a confirm gives the record its words: the list read before the event does
    // not have them yet, and the action would be missing.
    if (id != null && (event.kind == PairingEventKind.replied || event.kind == PairingEventKind.confirmed)) {
      await ref.read(pairingsProvider.notifier).reload();
      if (!mounted) return;
    }
    final contactId = id == null ? null : ref.read(pairingByIdProvider(id))?.contactId;
    final contact = contactId == null
        ? null
        : (ref.read(contactsProvider).value ?? const <Contact>[]).where((c) => c.id == contactId).firstOrNull;
    // The navigator now, while this widget is mounted: the action may run after it was rebuilt
    // away, and a context of its own would then open nothing.
    final nav = Navigator.of(context);
    void push(Widget screen) => nav.push<void>(MaterialPageRoute<void>(builder: (_) => screen));
    final NoticeAction? action = switch (event.kind) {
      PairingEventKind.replied || PairingEventKind.confirmed when id != null && (ref.read(pairingByIdProvider(id))?.sas.isNotEmpty ?? false) =>
        NoticeAction(l.noticeCheckWords, () => push(CheckWordsScreen(pairingId: id))),
      PairingEventKind.requested => NoticeAction(l.noticeOpen, () => push(const PairRequestsScreen())),
      PairingEventKind.keysChanged ||
      PairingEventKind.keysRestored ||
      PairingEventKind.homeRelayUnreachable ||
      PairingEventKind.relayMoveRefused ||
      PairingEventKind.heard ||
      PairingEventKind.peerVerified ||
      PairingEventKind.ended ||
      PairingEventKind.unpaired when contact != null =>
        NoticeAction(l.noticeOpen, () => push(ContactPage(contactId: contact.id, initial: contact))),
      PairingEventKind.invoiceFromContact ||
      PairingEventKind.duplicateRequests ||
      PairingEventKind.tooManyRequests => NoticeAction(l.noticeView, () => push(const InvoicesScreen())),
      PairingEventKind.withdrawalFromContact when event.slateId != null =>
        NoticeAction(l.noticeView, () {
          // The row's key is the wallet's; find it by its slate.
          final tx = ref.read(homeProvider).value?.transactions.where((t) => t.slateId == event.slateId).firstOrNull;
          push(TxDetailsScreen(txKey: tx?.key ?? 's:${event.slateId}'));
        }),
      _ => null,
    };
    final tag = switch (event.kind) {
      PairingEventKind.homeRelayUnreachable || PairingEventKind.keysChanged || PairingEventKind.keysRestored when id != null =>
        pairingContactNoticeTag(id),
      PairingEventKind.withdrawalFromContact when event.slateId != null => pairingSlateNoticeTag(event.slateId!),
      _ => null,
    };
    // Old keys not checked is news the user must not miss: it stays until closed.
    ref.read(noticeProvider.notifier).show(
      notice.text,
      level: notice.level,
      action: action,
      tag: tag,
      persistent: event.kind == PairingEventKind.keyCheckRefused,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the open wallet's name services alive while Home is up.
    ref.watch(nameServiceProvider);
    return const SizedBox.shrink();
  }
}
