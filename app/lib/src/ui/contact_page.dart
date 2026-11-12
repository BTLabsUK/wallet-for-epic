// SPDX-License-Identifier: Apache-2.0
/// A contact as a page: the header with the trust badge, Send and Show code, then
/// the contact's addresses (one per kind) and, where the wallet pairs, its Pairing
/// block: the trust state, Seal payments, Allow invoices, the relay it delivers through, the
/// keys-changed and relay notices, and Remove pairing. Replaces the contact sheet.
library;

import 'dart:async';

import '../name_service/payment_refusals.dart' show paymentRefusalsProvider;
import 'phone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../history/domain_check_book.dart' show DomainStatus;
import '../errors.dart';
import '../initials.dart';
import '../l10n.dart';
import '../pairing_providers.dart';
import '../providers.dart';
import '../settings.dart' show clockProvider;
import '../wallet_service.dart';
import 'address_view.dart' show MarkedAddress;
import 'app_dialog.dart';
import 'common.dart';
import 'inline_button.dart';
import 'invoice_request_screen.dart' show InvoiceRequestScreen;
import 'kit/kit_avatar.dart';
import 'kit/kit_button.dart';
import 'kit/kit_chip.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart' show KitIconButton;
import 'kit/kit_icons.dart';
import 'kit/kit_support.dart';
import 'kit/kit_tokens.dart';
import 'phone_tx_row.dart' show paymentInProgress;
import 'tx_details_screen.dart' show TxDetailsScreen;
import '../trust_ids.dart';
import 'levels/payment_steps.dart' show paymentStepWord;
import 'epic1/epic1_sealed.dart' show phoneShowsSealed;
import 'contact_label_mark.dart' show AvatarLabelMark;
import 'contact_label_picker.dart';
import 'contact_trust_line.dart';
import 'contacts_screen.dart';
import 'history_screen.dart' show HistoryScreen;
import 'method_names.dart';
import 'pairing/contact_pairing_block.dart';
import 'pairing/name_service_parts.dart' show NameServiceBlock;
import 'pairing/pair_check.dart';
import 'pairing/pair_screen.dart';
import 'pairing/pair_way1.dart' show pairWithContact;
import 'pairing/pairing_parts.dart';
import 'pairing/pairing_notices.dart' show pairingContactNoticeTag, pairingNewsOnScreen;
import 'scan_route.dart' show sendPayments;
import 'status_icons.dart' show EpicGlyphs;
import 'theme/logo_qr.dart';
import 'theme/tokens.dart';
import 'tip.dart';
import '../epic1.dart' show PaymentMode;
import 'epic1/epic1_common.dart' show ClassicOnlyText, classicOnlyPairing, classicOnlyProvider;
import 'epic1/epic1_send.dart' show openEpic1LinkSend;

/// Keys of the contact page, for tests.
const Key contactPageSendKey = ValueKey('contact-page-send');
const Key contactPageEditKey = ValueKey('contact-page-edit');
const Key contactPageMoreKey = ValueKey('contact-page-more');
const Key contactPageBackKey = ValueKey('contact-page-back');
const Key contactPageDeleteKey = ValueKey('contact-page-delete');
const Key contactPageHeaderPairKey = ValueKey('contact-page-header-pair');
const Key contactPageStarKey = ValueKey('contact-page-star');
const Key contactPageNoPaymentsKey = ValueKey('contact-page-no-payments');
const Key contactPageSendReasonKey = ValueKey('contact-page-send-reason');
const Key contactPageViaPairingKey = ValueKey('contact-page-via-pairing');

/// Two letters for [name] ([nameInitials]: letters and digits only), `?` for a name with
/// none.
String contactInitials(String name) {
  final letters = nameInitials(name);
  return letters.isEmpty ? '?' : letters;
}

/// How the app reaches [address]: `Epicbox`, `Link Payment · HTTP` for an http(s) address, `Link ·
/// Tor` for an onion address.
String contactTag(AppLocalizations l, String address) => recipientMethodWord(l, parseRecipient(address).kind);

/// How many of the newest payments the conversation shows; the rest are in Activity.
const int contactBubbleCount = 8;

/// The payments with [contact] as a conversation: bubbles by day, oldest first, an incoming
/// one at the start edge and an outgoing one at the end edge (HANDOFF 9). A payment is the
/// contact's by its address or by its pairing. The way to all of them in Activity, searched by
/// the name, sits on top once there are more than the page shows. Says so when there are none.
class _Payments extends ConsumerWidget {
  const _Payments({required this.contact, required this.pairing});

  final Contact contact;
  final PairingRecord? pairing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final all = ref.watch(homeProvider).value?.transactions ?? const <TxEntry>[];
    final pairingId = pairing?.id;
    final mine = [
      for (final tx in all)
        if (contactFor([contact], tx.counterparty) != null || (pairingId != null && tx.pairingId == pairingId)) tx,
    ]..sort((a, b) => b.timeUnix.compareTo(a.timeUnix));
    if (mine.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(l.contactPaymentsNone, style: KitType.rowSub.copyWith(color: t.dim), textAlign: TextAlign.center)),
      );
    }
    final shown = mine.take(contactBubbleCount).toList().reversed.toList();
    final now = ref.watch(clockProvider)();
    final children = <Widget>[];
    int? day;
    for (final tx in shown) {
      final when = localTime(tx.timeUnix);
      final key = when.year * 10000 + when.month * 100 + when.day;
      if (key != day) {
        day = key;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Center(
              child: Semantics(header: true, child: Text(dayLabel(l, when, now), style: KitType.groupLabel.copyWith(color: t.dim))),
            ),
          ),
        );
      }
      children.add(_PaymentBubble(tx: tx));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mine.length > contactBubbleCount)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InlineTextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => HistoryScreen(query: contact.name)),
              ),
              child: Text(l.contactPaymentsAll),
            ),
          ),
        ...children,
      ],
    );
  }
}

/// One payment as a bubble: the amount, the label when it has one, and where it stands. A
/// payment still under way is tinted in the info colour. A tap opens its details.
class _PaymentBubble extends ConsumerWidget {
  const _PaymentBubble({required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final display = amountDisplay(ref);
    final tip = tipHeight(ref);
    final target = confirmationsTargetOf(ref);
    final now = ref.watch(clockProvider)();
    final (:amount, :outgoing) = txAmount(tx);
    final cancelled = tx.status == TxStatus.cancelled;
    final inProgress = paymentInProgress(tx, tip, target: target);
    final sealed = phoneShowsSealed(ref, tx);
    final name = txPartyName(ref, tx);
    final step = paymentStepWord(
      l,
      tx,
      tip,
      target: target,
      now: now,
      who: name,
      pairedWith: txPayeeName(ref, tx),
      paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
    );
    final date = shortDate(l, localTime(tx.timeUnix), now);
    final signed = signedEpic(l, tx, hidden: display.hidden);
    final label = tx.label?.trim();
    final dim = KitType.rowSub.copyWith(color: inProgress ? t.info : t.dim);
    final amountColor = cancelled
        ? t.txCancelled
        : outgoing
        ? t.text
        : t.txReceived;
    final radius = BorderRadius.circular(Kit.rGroup);
    return Align(
      alignment: outgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FractionallySizedBox(
          widthFactor: 0.78,
          alignment: outgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: kitId(
            TrustIds.contactPayment,
            KitPress(
              radius: Kit.rGroup,
              semanticsLabel: txSpokenLabel(
                l,
                tx,
                who: name,
                date: date,
                status: step,
                hidden: display.hidden,
                label: tx.label,
                sealed: sealed,
              ),
              button: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key))),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: inProgress ? t.info.withValues(alpha: 0.12) : t.group,
                  borderRadius: radius,
                  border: inProgress ? Border.all(color: t.info.withValues(alpha: 0.45)) : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        signed,
                        style: TextStyle(
                          fontFamily: t.monoFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: amountColor,
                          decoration: cancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (label != null && label.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(label, style: KitType.rowTitle.copyWith(color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(inProgress ? Icons.schedule_rounded : KitIcons.check, size: 15, color: inProgress ? t.info : t.dim),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              sealed ? '$step$metaSeparator${l.deskE1Sealed}' : step,
                              style: dim,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the page of [contact].
Future<void> openContactPage(BuildContext context, Contact contact) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(builder: (_) => ContactPage(contactId: contact.id, initial: contact)),
);

/// The contact page. It follows the contact by id, so an edit shows at once; [initial] stands
/// in until the list has loaded.
class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key, required this.contactId, this.initial});

  final String contactId;
  final Contact? initial;

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  bool _busy = false;

  /// The page shows this contact's relay and keys itself.
  bool _shows(PairingEvent e) =>
      const {PairingEventKind.homeRelayUnreachable, PairingEventKind.keysChanged, PairingEventKind.keysRestored}.contains(e.kind) &&
      e.pairingId != null &&
      e.pairingId == ref.read(contactPairingProvider(widget.contactId))?.id;

  @override
  void dispose() {
    pairingNewsOnScreen.remove(_shows);
    _notices.dismissTag(_pausedTag);
    super.dispose();
  }

  /// The Epicbox-off notice of this page.
  static const _pausedTag = 'contact-paused-epicbox-off';

  /// Read in [initState]: [dispose] closes the page's notice and may not read providers.
  late final NoticeNotifier _notices;

  @override
  void initState() {
    super.initState();
    _notices = ref.read(noticeProvider.notifier);
    pairingNewsOnScreen.add(_shows);
    // The contact's claimed domain is checked when it is due; the lists read again if it moved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pairing = ref.read(contactPairingProvider(widget.contactId));
      if (pairing?.peerDomain != null) unawaited(ref.read(pairingApiProvider).checkDomain(pairing!.id));
    });
    // Epicbox off pauses the contact's pairing; say so once on the way in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The page shows the contact's relay and keys: their notices have done their job.
      final pairing = ref.read(contactPairingProvider(widget.contactId));
      if (pairing != null) ref.read(noticeProvider.notifier).dismissTag(pairingContactNoticeTag(pairing.id));
      final paired = pairing != null;
      if (paired && ref.read(pairNetProvider) == PairNet.epicboxOff) {
        final l = context.l10n;
        // Persistent, so it pushes the page down instead of covering its header; it goes with
        // the page.
        _notices.show('${l.contactPausedEpicboxOff}. ${l.contactPausedEpicboxOffBody}', level: NoticeLevel.info, persistent: true, tag: _pausedTag);
      }
    });
  }

  Contact? _contact() {
    final all = ref.watch(contactsProvider).value;
    return all?.where((c) => c.id == widget.contactId).firstOrNull ?? (all == null ? widget.initial : null);
  }

  /// Send with the contact's address whose method is on (Epicbox, Tor, HTTP), as Send picks it;
  /// a contact with no address, through its pairing's mailbox.
  /// In epic1 mode, through the pairing that takes epic1, else the contact's epic1 link (the
  /// header offers Send only with one of them).
  void _send(Contact contact, PairingRecord? pairing) {
    final epic1 = ref.read(paymentModeProvider) == PaymentMode.epic1;
    if (epic1 && classicOnlyPairing(pairing) && contact.epic1 != null) {
      unawaited(openEpic1LinkSend(context, contact.epic1!));
    } else if (pairing != null && (contact.addresses.isEmpty || epic1)) {
      showShellFlow(context, ShellFlow.send, pairingTo: pairing.id);
    } else {
      showShellFlow(context, ShellFlow.send, recipient: contactSendAddress(contact, sendPayments(ref).offers));
    }
  }

  void _edit(Contact contact) => Navigator.of(
    context,
  ).push<Contact>(MaterialPageRoute<Contact>(builder: (_) => ContactEditScreen(contact: contact)));

  Future<void> _delete(Contact contact, PairingRecord? pairing) async {
    final l = context.l10n;
    final sure = await confirmAppDialog(
      context,
      title: l.contactsDeleteTitle(contact.name),
      icon: Icons.person_remove_outlined,
      tone: DialogTone.risk,
      description: pairing == null ? l.contactsDeleteConfirmBody : '${l.contactsDeleteConfirmBody}\n\n${l.contactDeletePaired(contact.name)}',
      cancelLabel: l.commonCancel,
      confirmLabel: l.commonDelete,
      risk: true,
    );
    if (!sure || !mounted) return;
    final notices = ref.read(noticeProvider.notifier);
    try {
      // Deleting a paired contact removes its pairing (C-19).
      if (pairing != null) await pairingCall(ref, (api) => api.removePairing(pairing.id));
      await ref.read(contactsProvider.notifier).delete(contact.id);
      notices.show(l.contactsDeleted(contact.name), level: NoticeLevel.success);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
    }
  }

  void _showCode(Contact contact) => showPhoneSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CodeSheet(contact: contact),
  );

  Future<void> _run(Future<void> Function() call) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await call();
    } catch (error) {
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(context.l10n, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final contact = _contact();
    if (contact == null) {
      // Deleted (from its form, or elsewhere): the page has nothing left to show.
      if (ref.watch(contactsProvider).hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
        });
      }
      return SlotScaffold(appBar: AppBar(title: Text(l.contactTitle)), body: const SizedBox.shrink());
    }
    final pairs = ref.watch(pairingSupportedProvider);
    final pairing = pairs ? ref.watch(contactPairingProvider(contact.id)) : null;
    // A request sent to this contact, or its code answered, waiting for the confirm.
    final pending = pairs && (pairing == null || pairing.ended) ? ref.watch(contactPendingPairingProvider(contact.id)) : null;
    final starred = ref.watch(favouriteContactsProvider).value?.contains(contact.id) ?? false;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: pairing?.id, address: contact.epicbox);
    final t = context.tokens;
    final classicOnly = ref.watch(classicOnlyProvider(contact.id));
    final canAsk = pairing != null && !pairing.ended && pairing.state.isPaired && ref.watch(invoicesShownProvider);
    final showSend = !noPayments;
    final sendOn = !classicOnly && !(contact.addresses.isEmpty && !(pairing?.paysByMailbox ?? false));
    Widget bar() {
      final send = KitButton(
        key: contactPageSendKey,
        label: l.contactsSendAction,
        icon: KitIcons.send,
        onPressed: sendOn ? () => _send(contact, pairing) : null,
        semanticsId: TrustIds.contactSend,
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          color: t.bg,
          border: Border(top: BorderSide(color: t.hair)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Kit.gutter, 12, Kit.gutter, 12),
                child: Row(
                  children: [
                    if (showSend) Expanded(child: classicOnly ? Tip(l.deskE1PhClassicOnlyTip, child: send) : send),
                    if (showSend && canAsk) const SizedBox(width: 12),
                    if (canAsk)
                      Expanded(
                        child: KitButton(
                          label: l.phoneContactRequest,
                          icon: KitIcons.receive,
                          kind: KitButtonKind.quiet,
                          semanticsId: TrustIds.contactRequest,
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(builder: (_) => InvoiceRequestScreen(pairingId: pairing.id)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SlotScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _TopBar(
                  onBack: () => Navigator.maybePop(context),
                  more: PopupMenuButton<String>(
                    key: contactPageMoreKey,
                    tooltip: l.contactMore,
                    onSelected: (v) => switch (v) {
                      'edit' => _edit(contact),
                      'star' => _run(() => ref.read(favouriteContactsProvider.notifier).set(contact.id, !starred)),
                      'check' when pairing != null && !pairing.ended && pairing.sas.isNotEmpty => _openCheck(pairing),
                      'delete' => _delete(contact, pairing),
                      _ => null,
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        key: contactPageEditKey,
                        value: 'edit',
                        child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l.contactEdit)),
                      ),
                      PopupMenuItem(
                        key: contactPageStarKey,
                        value: 'star',
                        child: ListTile(
                          leading: Icon(starred ? Icons.star_rounded : Icons.star_outline_rounded),
                          title: Text(starred ? l.contactUnstar : l.contactStar),
                        ),
                      ),
                      if (pairing != null && !pairing.ended && pairing.sas.isNotEmpty)
                        PopupMenuItem(value: 'check', child: ListTile(leading: const Icon(EpicGlyphs.verified), title: Text(l.pairCheckWords))),
                      PopupMenuItem(
                        key: contactPageDeleteKey,
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: t.risk),
                          title: Text(l.contactDelete, style: TextStyle(color: t.risk)),
                        ),
                      ),
                    ],
                    child: const _MoreMark(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              contact: contact,
                              pairing: pairing,
                              starred: starred,
                              onCode: () => _showCode(contact),
                              onPair: pairs && (pairing == null || pairing.ended) && pending == null ? () => _pair(contact) : null,
                              onPending: pairs && (pairing == null || pairing.ended) && pending != null ? () => _showMyCode(contact) : null,
                            ),
                            _Payments(contact: contact, pairing: pairing),
                            const SizedBox(height: 8),
                            // A contact that takes no payments: its own card first, then Pairing, Addresses last.
                            if (noPayments && pairs && pairing != null && !pairing.ended) NameServiceBlock(pairingId: pairing.id, label: contact.name),
                            if (!noPayments) ...[PairSection(l.contactAddresses), _Addresses(contact: contact, pairing: pairing)],
                            if (pairs) ...[
                              PairSection(l.contactPairing),
                              ContactPairingBlock(contact: contact, pairing: pairing, pending: pending, busy: _busy, run: _run, onPair: () => _pair(contact)),
                              // A service the user paired with and took a name from: Pay me as @name · since, the
                              // picture code and Leave, or the button that turns it on.
                              if (!noPayments && pairing != null && !pairing.ended) NameServiceBlock(pairingId: pairing.id, label: contact.name),
                            ],
                            if (noPayments) ...[PairSection(l.contactAddresses), _Addresses(contact: contact, pairing: pairing)],
                            // The compatibility line (trust policy): one sentence, never a badge; a plain
                            // contact's key can answer as another wallet app with pairing off too.
                            ContactTrustLine(contactId: contact.id, name: contact.name),
                            if (contact.note?.trim() case final note? when note.isNotEmpty) ...[
                              PairSection(l.contactsNoteHeading),
                              Text(note, style: KitType.body.copyWith(color: context.tokens.text)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showSend || canAsk) bar(),
          ],
        ),
      ),
    );
  }

  /// Pair: the request sheet when a request can go, else the Pair screen for the contact.
  void _pair(Contact contact) => pairWithContact(context, ref, contact);

  void _showMyCode(Contact contact) => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairScreen(contact: contact)));

  void _openCheck(PairingRecord p) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: p.id, recheck: p.state.isPaired)));
}

/// Asks for the contact's label and saves it on the contact as it stands (every other field
/// is kept). Dismissing the sheet changes nothing.
Future<void> _pickLabel(BuildContext context, WidgetRef ref, Contact contact) async {
  final picked = await showContactLabelPicker(context, contact.label);
  if (picked == null || picked == contact.label) return;
  try {
    await ref.read(contactsProvider.notifier).save(contact.copyWith(label: picked));
  } catch (error) {
    if (context.mounted) ref.read(noticeProvider.notifier).show(describeError(context.l10n, error), level: NoticeLevel.error);
  }
}

/// The top row: the gold back link named after the list it returns to, and the "…" on the end.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.more});

  final VoidCallback onBack;
  final Widget more;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return SizedBox(
      height: Kit.pageTitleHeader + 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            kitId(
              TrustIds.contactBack,
              KitPress(
                key: contactPageBackKey,
                radius: Kit.rIconButton,
                semanticsLabel: l.contactsTitle,
                button: true,
                onTap: onBack,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: Kit.hitMin, minWidth: Kit.hitMin),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(KitIcons.backLink, size: 28, color: t.accentText),
                        Text(l.contactsTitle, style: KitType.navLink.copyWith(color: t.accentText)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            kitId(TrustIds.contactMore, more),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

/// The face of the "…" menu: the quiet square the other icon buttons use.
class _MoreMark extends StatelessWidget {
  const _MoreMark();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rIconButton)),
      child: SizedBox.square(dimension: Kit.hitMin, child: Icon(KitIcons.more, color: t.text)),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.contact,
    required this.pairing,
    required this.starred,
    required this.onCode,
    this.onPair,
    this.onPending,
  });

  final Contact contact;
  final PairingRecord? pairing;
  final bool starred;
  final VoidCallback onCode;

  /// Not paired: Pair opens the Pair screen for this contact.
  final VoidCallback? onPair;

  /// A request sent or its code answered: Waiting opens the Pair screen for the contact.
  final VoidCallback? onPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final p = pairing;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: p?.id, address: contact.epicbox);
    final claimed = p?.name?.trim();
    final classicOnly = ref.watch(classicOnlyProvider(contact.id));
    final paired = p != null && !p.ended && p.state.isPaired;
    final dim = KitType.rowSub.copyWith(color: t.dim);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        AvatarLabelMark(
          avatar: KitAvatar(initials: contactInitials(contact.name), large: true),
          size: Kit.avatarStrip,
          label: contact.label,
          onTap: () => _pickLabel(context, ref, contact),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              text: contact.name,
              children: [
                if (starred)
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(padding: EdgeInsetsDirectional.only(start: 6), child: ContactStar(size: 18)),
                  ),
              ],
            ),
            style: KitType.pageTitle.copyWith(color: t.text, fontSize: 24),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (paired) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(EpicGlyphs.sealed, size: 15, color: t.accentText),
              const SizedBox(width: 6),
              Flexible(child: Text(l.phoneContactPaired, style: dim, textAlign: TextAlign.center)),
            ],
          ),
        ],
        if (classicOnly) ...[const SizedBox(height: 6), const ClassicOnlyText()],
        // Verified is about the Epicbox address: none beside one the pairing did not bring.
        if ((p != null && pairingVouchesFor(p, contact.epicbox)) || noPayments || (!noPayments && p != null && p.allowInvoices)) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              if (p != null && pairingVouchesFor(p, contact.epicbox)) TrustBadge(p),
              if (noPayments) NoPaymentsBadge(key: contactPageNoPaymentsKey),
              if (!noPayments && p != null && p.allowInvoices) EBadge(l.trustAllowsInvoices, icon: Icons.receipt_long_outlined),
            ],
          ),
        ],
        if (claimed != null && claimed.isNotEmpty && claimed != contact.name) ...[
          const SizedBox(height: 4),
          Text(l.pairCallsThemselves(claimed), style: dim, textAlign: TextAlign.center),
        ],
        // Only a proven domain is shown here; claimed or refused is in the details.
        if (p != null && p.peerDomain != null && p.domainStatus == DomainStatus.proven) ...[
          const SizedBox(height: 4),
          Semantics(
            label: '${p.peerDomain}, ${l.contactDomainVerified}',
            excludeSemantics: true,
            child: Row(
              key: contactPageDomainKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 14, color: t.dim),
                const SizedBox(width: 4),
                Flexible(child: Text(p.peerDomain!, style: dim, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
        // Labelled buttons only (UP-028): the row wraps where the words need it (Russian at 360 dp).
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onPair != null)
              Tip(
                l.pairWithName(contact.name),
                excludeFromSemantics: true,
                child: Semantics(
                  label: l.pairWithName(contact.name),
                  button: true,
                  excludeSemantics: true,
                  child: KitButton(
                    key: contactPageHeaderPairKey,
                    label: l.pairTitle,
                    icon: EpicGlyphs.verified,
                    kind: KitButtonKind.quiet,
                    small: true,
                    expand: false,
                    onPressed: onPair,
                  ),
                ),
              )
            else if (onPending != null)
              KitButton(
                key: contactPageHeaderPairKey,
                label: l.trustWaiting,
                icon: Icons.hourglass_empty_rounded,
                kind: KitButtonKind.quiet,
                small: true,
                expand: false,
                onPressed: onPending,
              ),
            KitButton(
              label: l.contactsShowCode,
              icon: KitIcons.qr,
              kind: KitButtonKind.quiet,
              small: true,
              expand: false,
              onPressed: contact.addresses.isEmpty ? null : onCode,
            ),
          ],
        ),
        // A contact with only a pairing that cannot take a payment now: why Send is off.
        if (!noPayments && !classicOnly && contact.addresses.isEmpty && p != null && !p.paysByMailbox) ...[
          const SizedBox(height: 8),
          Text(
            p.state == PairingState.keysChanged ? l.contactSendKeysChanged : l.contactSendNoSealed(contact.name),
            key: contactPageSendReasonKey,
            style: dim,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// One row per address: the kind badge, the short address in mono, Copy. A contact with only
/// a pairing gets one row saying payments go through it (dim while it cannot take one).
class _Addresses extends StatelessWidget {
  const _Addresses({required this.contact, this.pairing});

  final Contact contact;
  final PairingRecord? pairing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final p = pairing;
    if (contact.addresses.isEmpty && p != null) {
      final color = p.caps.opensSealed ? t.text : t.dim;
      return PairCard(
        children: [
          ConstrainedBox(
            key: contactPageViaPairingKey,
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  Icon(EpicGlyphs.sealed, size: 20, color: t.dim),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.contactNoAddressPaired, style: KitType.rowTitle.copyWith(color: color))),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (contact.addresses.isEmpty) return Text(l.contactNoAddresses, style: KitType.body.copyWith(color: t.dim));
    return KitGroup(
      margin: EdgeInsets.zero,
      dividerInset: Kit.dividerInsetPlain,
      children: [
        // Each address in full, its method chip and Copy on the label row above it.
        for (final kind in contact.kinds)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    KitChip(recipientMethodWord(l, kind)),
                    const Spacer(),
                    KitIconButton(
                      icon: KitIcons.copy,
                      label: l.contactCopyAddress(recipientMethodWord(l, kind)),
                      color: t.accentText,
                      semanticsId: TrustIds.contactCopyAddress,
                      onPressed: () => copyText(context, contact.addressOf(kind)!, l.contactsCopied),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: MarkedAddress(contact.addressOf(kind)!, selectable: true),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// An address in mono: the key part in the text colour (its start in the accent's), the relay
/// after `@` dim; short, as in rows, with [short].
class AddressText extends StatelessWidget {
  const AddressText(this.address, {super.key, this.short = false, this.selectable = false});

  final String address;
  final bool short;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shown = short ? shortAddress(address) : address;
    final at = shown.indexOf('@');
    final span = TextSpan(
      style: TextStyle(fontFamily: t.monoFamily, fontSize: 13, color: t.text),
      children: [
        TextSpan(text: at < 0 ? shown : shown.substring(0, at)),
        if (at >= 0) TextSpan(text: shown.substring(at), style: TextStyle(color: t.dim)),
      ],
    );
    return selectable ? SelectableText.rich(span) : Text.rich(span, maxLines: short ? 1 : null, overflow: short ? TextOverflow.ellipsis : null);
  }
}

/// The contact's addresses as codes: one at a time, the kind chosen with segments when there
/// are several, with the full address under the code.
class _CodeSheet extends StatefulWidget {
  const _CodeSheet({required this.contact});

  final Contact contact;

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  late RecipientKind _kind = widget.contact.kinds.first;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final kinds = widget.contact.kinds;
    final address = widget.contact.addressOf(_kind) ?? widget.contact.address;
    final foot = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kinds.length > 1) ...[
            SegmentedButton<RecipientKind>(
              segments: [for (final k in kinds) ButtonSegment(value: k, label: Text(recipientMethodWord(l, k)))],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Dark modules on white scan reliably in either theme.
                color: protocolLight.surface,
                borderRadius: BorderRadius.circular(t.radiusSmall),
              ),
              child: Semantics(
                label: l.contactsQrLabel(widget.contact.name),
                image: true,
                child: LogoQr(data: address, size: 220),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: t.well,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 0, 4),
            child: Row(
              children: [
                Expanded(child: MarkedAddress(address, selectable: true)),
                IconButton(
                  tooltip: l.commonCopy,
                  color: t.accentText,
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => copyText(context, address, l.contactsCopied),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
