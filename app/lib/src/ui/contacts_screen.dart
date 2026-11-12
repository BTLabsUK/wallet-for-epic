// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart' show mergeSort;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contact_epic1.dart';
import '../contact_label.dart';
import '../contacts.dart';
import '../name_service/payment_refusals.dart' show paymentRefusalsProvider;
import '../errors.dart';
import '../initials.dart' show nameInitials;
import '../l10n.dart';
import '../tor_build.dart';
import '../pairing_providers.dart';
import '../pairing_text.dart' show peerLabel, sameNamedContact;
import '../providers.dart';
import '../scan/scan_checks.dart' show addressOfScan;
import '../trust_ids.dart';
import '../wallet_service.dart';
import 'address_view.dart' show ShortAddressText;
import 'app_dialog.dart';
import 'common.dart';
import 'contact_activity_row.dart';
import 'contact_page.dart';
import 'contacts_transfer.dart';
import 'contact_label_mark.dart' show AvatarLabelMark;
import 'invoice_review_screen.dart';
import 'kit/kit_avatar.dart';
import 'kit/kit_button.dart';
import 'kit/kit_empty_state.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_search_field.dart';
import 'kit/kit_support.dart';
import 'kit/kit_tokens.dart';
import 'epic1/epic1_common.dart' show ClassicOnlyText, classicOnlyProvider;
import 'tip.dart';
import 'inline_button.dart';
import 'method_names.dart';
import 'pairing/pair_check.dart' show attachPairingTo, confirmRemovePairing, pickContactForPairing, savePairingAsNewContact;
import 'pairing/pair_incoming.dart' show confirmCancelPairing;
import 'pairing/pair_screen.dart';
import 'pairing/pair_way1.dart' show PairRequestsRow;
import 'pairing/pairing_parts.dart';
import '../pairing_text.dart' show pairingEndedRowText;
import 'scan_screen.dart';
import 'status_icons.dart';
import 'theme/tokens.dart';
import 'tour/tour_target.dart';

/// Keys for tests.
const Key contactsPairKey = ValueKey('contacts-pair');
const Key contactsAddItemKey = ValueKey('contacts-add-item');
const Key contactsMoreKey = ValueKey('contacts-more');
const Key contactsImportKey = ValueKey('contacts-import');
const Key contactsExportKey = ValueKey('contacts-export');

/// The row menu of a pairing in no contact, by its id, and the row itself.
Key contactsOrphanMenuKey(String id) => ValueKey('contacts-orphan-menu-$id');
Key contactsPairingRowKey(String id) => ValueKey('contacts-pairing-row-$id');
const Key contactsCancelPairingKey = ValueKey('contacts-cancel-pairing');
const Key contactAddAnotherKey = ValueKey('contact-add-another');
const Key contactKeepOldKey = ValueKey('contact-keep-old');
const Key contactReplaceKey = ValueKey('contact-replace');

/// The key of the address field at [index] of the contact form, for tests.
Key contactAddressFieldKey(int index) => ValueKey('contact-address-$index');

/// The key of the remove button of the address field at [index].
Key contactAddressRemoveKey(int index) => ValueKey('contact-address-remove-$index');

/// A field's error that screen readers announce as soon as it appears, for
/// `InputDecoration.error`.
class LiveFieldError extends StatelessWidget {
  const LiveFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// What the Contacts tab knows of one contact: its latest payment, and the invoice it waits on
/// the user to approve.
class ContactActivity {
  const ContactActivity({this.latest, this.asks, this.all = const []});

  final TxEntry? latest;

  /// Every payment of the contact (the latest among them).
  final List<TxEntry> all;
  final PendingInvoice? asks;
}

/// [ContactActivity] by contact id, for the contacts that have any. A payment belongs to the
/// contact saved under its address, else to the contact of the pairing it went through; an
/// invoice to the contact of the pairing that signed it.
final contactActivityProvider = Provider<Map<String, ContactActivity>>((ref) {
  final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
  if (contacts.isEmpty) return const {};
  final pairings = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
  final byPairing = {
    for (final p in pairings)
      if (p.contactId != null) p.id: p.contactId!,
  };
  final txs = ref.watch(homeProvider.select((h) => h.value?.transactions)) ?? const <TxEntry>[];
  final invoices = ref.watch(pendingInvoicesProvider).value ?? const <PendingInvoice>[];
  final latest = <String, TxEntry>{};
  final every = <String, List<TxEntry>>{};
  for (final tx in txs) {
    final id = contactFor(contacts, tx.counterparty)?.id ?? byPairing[tx.pairingId];
    if (id == null) continue;
    (every[id] ??= []).add(tx);
    final seen = latest[id];
    if (seen == null || tx.timeUnix > seen.timeUnix) latest[id] = tx;
  }
  final asks = <String, PendingInvoice>{};
  for (final i in invoices) {
    final id = byPairing[i.pairingId];
    if (id != null) asks.putIfAbsent(id, () => i);
  }
  return {
    for (final id in {...latest.keys, ...asks.keys}) id: ContactActivity(latest: latest[id], asks: asks[id], all: every[id] ?? const []),
  };
});

/// The address book. With [pick], tapping a contact returns it instead of opening its page.
/// As a tab it reads as the phone's Contacts (HANDOFF 6): a title with Add and, where the
/// wallet pairs, Pair; a search field; a strip of faces; and the contacts, by latest payment
/// with a contact that needs the user on top, or A to Z. The list starts with Pair requests
/// while contacts' requests wait, and carries each pairing's badge and the pending rows.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key, this.pick = false, this.forPayment = false});

  final bool pick;

  /// With [pick]: the pick is a recipient. A contact that takes no payments stays in the list,
  /// dimmed and not pressable, with its reason.
  final bool forPayment;

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

/// More contacts than this get letter headers.
const int _groupAbove = 8;

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _search = TextEditingController();

  /// The list is A to Z instead of by latest payment.
  bool _az = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Contact> _filter(List<Contact> contacts) {
    final query = _search.text.trim().toLowerCase();
    final sorted = [...contacts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (query.isEmpty) return sorted;
    return [
      for (final c in sorted)
        if (c.name.toLowerCase().contains(query) ||
            c.addresses.any((a) => a.toLowerCase().contains(query)) ||
            (c.note?.toLowerCase().contains(query) ?? false))
          c,
    ];
  }

  /// [contacts] in the Recent order: those that need the user, then by latest payment, then
  /// the rest by name (the order [contacts] has).
  List<Contact> _recent(List<Contact> contacts, Map<String, ContactActivity> activity) {
    int rank(Contact c) {
      final a = activity[c.id];
      return a?.asks != null ? 0 : (a?.latest != null ? 1 : 2);
    }

    final out = [...contacts];
    mergeSort(out, compare: (a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final ta = activity[a.id]?.latest?.timeUnix ?? 0;
      final tb = activity[b.id]?.latest?.timeUnix ?? 0;
      return tb.compareTo(ta);
    });
    return out;
  }

  Future<void> _open(Contact contact) async {
    if (widget.pick) {
      Navigator.pop(context, contact);
      return;
    }
    await openContactPage(context, contact);
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(builder: (_) => const ContactEditScreen()),
    );
    if (saved != null && widget.pick && mounted) Navigator.pop(context, saved);
  }

  void _pair() => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PairScreen()));

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    final l = context.l10n;
    final t = context.tokens;
    final pairs = ref.watch(pairingSupportedProvider) && !widget.pick;
    final requests = pairs ? (ref.watch(pairRequestsProvider).value ?? const <PairRequest>[]).length : 0;
    // Pairings in no contact: stored ones, and an answer to a code waiting for its confirm.
    final orphans = pairs
        ? [
            ...ref.watch(orphanPairingsProvider),
            for (final r in ref.watch(pendingPairingsProvider))
              if (r.contactId == null) r,
          ]
        : const <PairingRecord>[];
    final canExport = contacts.value?.isNotEmpty ?? false;
    // With no contacts at all, a search field has nothing to search: the empty state fills the
    // space instead.
    // A shared book this wallet has no key to yet: said closed, never shown as an empty one.
    final closed = !(ref.watch(sessionProvider)?.contactsAvailable ?? true);
    final none = closed || switch (contacts) {
      AsyncData(:final value) => value.isEmpty && requests == 0 && orphans.isEmpty,
      _ => false,
    };
    final Widget content;
    if (closed) {
      content = KitEmptyState(
        key: const ValueKey('contacts-closed'),
        icon: KitIcons.lock,
        title: l.contactsClosedTitle,
        message: l.contactsClosedText,
      );
    } else if (none) {
      content = KitEmptyState(
        icon: KitIcons.contacts,
        title: l.contactsEmptyTitle,
        message: l.contactsEmptyCaption,
        actionLabel: l.contactsAdd,
        actionKind: KitButtonKind.gold,
        actionId: TrustIds.contactsAdd,
        onAction: _add,
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sticky: the list scrolls under it.
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: KitSearchField(
              controller: _search,
              hint: l.phoneContactsSearchHint,
              semanticsId: TrustIds.contactsSearch,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: switch (contacts) {
              AsyncData(:final value) => _list(value, orphans, canExport),
              AsyncError(:final error) => ListView(
                padding: const EdgeInsets.all(Kit.gutter),
                children: [ErrorText(describeError(l, error))],
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      );
    }
    final body = PhoneTourTarget(
      id: 'tour-contacts-list',
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.pick)
                  KitTabTitle(
                    l.contactsTitle,
                    // One gold "+" opens Add a contact, Pair, Import and Export (the frame has
                    // nothing else in the title row).
                    trailing: Builder(
                      builder: (btn) => KitIconButton(
                        key: contactsMoreKey,
                        icon: KitIcons.add,
                        label: l.contactMore,
                        color: t.accentText,
                        onPressed: () => _plusMenu(btn, canExport: canExport, pairs: pairs),
                        semanticsId: TrustIds.contactsMore,
                      ),
                    ),
                  ),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
    );
    return SlotScaffold(
      idle: contacts.isLoading ? SlotProgress(label: l.contactsTitle) : null,
      appBar: widget.pick
          ? AppBar(
              title: Text(l.contactsPickTitle),
              actions: [
                IconButton(
                  tooltip: l.contactsAdd,
                  icon: TrustId(TrustIds.contactsAdd, child: const Icon(Icons.person_add_alt)),
                  onPressed: _add,
                ),
                const SizedBox(width: 4),
              ],
            )
          : null,
      body: body,
    );
  }

  Future<void> _plusMenu(BuildContext btn, {required bool canExport, required bool pairs}) async {
    final l = context.l10n;
    final box = btn.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(btn).context.findRenderObject()! as RenderBox;
    final rect = RelativeRect.fromRect(
      Rect.fromPoints(box.localToGlobal(Offset.zero, ancestor: overlay), box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay)),
      Offset.zero & overlay.size,
    );
    final v = await showMenu<String>(
      context: btn,
      position: rect,
      items: [
        PopupMenuItem(
          key: contactsAddItemKey,
          value: 'add',
          child: kitId(TrustIds.contactsAdd, ListTile(leading: const Icon(Icons.person_add_alt), title: Text(l.contactsAdd))),
        ),
        if (pairs)
          PopupMenuItem(
            key: contactsPairKey,
            value: 'pair',
            child: kitId(TrustIds.contactsPair, ListTile(leading: const Icon(EpicGlyphs.verified), title: Text(l.pairTitle))),
          ),
        PopupMenuItem(
          key: contactsImportKey,
          value: 'import',
          child: ListTile(leading: const Icon(Icons.file_download_outlined), title: Text(l.contactsImport)),
        ),
        PopupMenuItem(
          key: contactsExportKey,
          value: 'export',
          // A contact without an address is a pairing's, which the file never carries.
          enabled: canExport,
          child: ListTile(enabled: canExport, leading: const Icon(Icons.file_upload_outlined), title: Text(l.contactsExport)),
        ),
      ],
    );
    if (!mounted || v == null) return;
    switch (v) {
      case 'add':
        _add();
      case 'pair':
        _pair();
      case 'import':
        await importContacts(context, ref);
      default:
        await exportContacts(context, ref);
    }
  }

  Widget _list(List<Contact> all, List<PairingRecord> orphans, bool canExport) {
    final contacts = _filter(all);
    final t = context.tokens;
    final l = context.l10n;
    final query = _search.text.trim().toLowerCase();
    final pairs = ref.watch(pairingSupportedProvider) && !widget.pick;
    final activity = ref.watch(contactActivityProvider);
    final pick = widget.pick;
    final az = _az || pick;
    final children = <Widget>[
      // Requests from contacts, while any wait.
      if (pairs && query.isEmpty) const PairRequestsRow(),
      // Pairings in no contact, by the name they chose: waiting or ended with their row, the
      // rest with Add to contacts or Remove pairing.
      ...[
        for (final r in orphans)
          if (query.isEmpty || peerLabel(context.l10n, r).toLowerCase().contains(query)) _OrphanRow(key: ValueKey(r.id), record: r, contacts: all),
      ].map((row) => Padding(padding: const EdgeInsets.only(bottom: 8), child: KitGroup(children: [row]))),
    ];
    if (contacts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: Kit.gutter),
        children: [
          ...children,
          if (all.isNotEmpty && query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Kit.gutter, vertical: 32),
              child: Text(l.contactsNoMatchQuery(_search.text.trim()), textAlign: TextAlign.center, style: KitType.body.copyWith(color: t.dim)),
            ),
        ],
      );
    }
    final ordered = az ? contacts : _recent(contacts, activity);
    Widget rowOf(Contact c) {
      final a = activity[c.id];
      void open() => _open(c);
      if (!pick) {
        if (a?.asks != null) return _AsksRow(contact: c, invoice: a!.asks!, onTap: open);
        if (!az && a?.latest != null) return ContactActivityRow(tx: a!.latest!, name: c.name, onOpen: open, others: a.all);
      }
      return _ContactRow(contact: c, onTap: open, forPayment: pick && widget.forPayment, noPaymentsYet: !pick && !az && a?.latest == null);
    }

    if (!pick && contacts.isNotEmpty && query.isEmpty) {
      children.add(_Faces(contacts: ordered.take(24).toList(), activity: activity, onOpen: _open));
    }
    if (!pick) {
      children.add(
        KitSectionHead(
          az ? l.phoneContactsAtoZ : l.phoneHomeRecent,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              kitId(
                TrustIds.contactsAtoz,
                KitPress(
                  onTap: () => setState(() => _az = !_az),
                  radius: Kit.rButton,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: Kit.hitMin),
                    child: Center(
                      widthFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(az ? l.phoneHomeRecent : l.phoneContactsAtoZ, style: KitType.rowSub.copyWith(color: t.accentText, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final grouped = az && ordered.length > _groupAbove;
    if (grouped) {
      String? letter;
      var run = <Widget>[];
      void flush() {
        if (run.isEmpty) return;
        children.add(KitGroup(children: run));
        run = <Widget>[];
      }

      for (final c in ordered) {
        final first = c.name.trim().characters.firstOrNull?.toUpperCase();
        final head = first != null && RegExp(r'\p{L}', unicode: true).hasMatch(first) ? first : '#';
        if (head != letter) {
          flush();
          letter = head;
          children.add(_LetterHead(head));
        }
        run.add(rowOf(c));
      }
      flush();
    } else {
      children.add(KitGroup(children: [for (final c in ordered) rowOf(c)]));
    }
    return ListView(padding: const EdgeInsets.only(bottom: Kit.gutter), children: children);
  }
}

/// The strip of faces under the search field: a tap opens the contact. A gold dot marks one
/// that needs the user.
class _Faces extends StatelessWidget {
  const _Faces({required this.contacts, required this.activity, required this.onOpen});

  final List<Contact> contacts;
  final Map<String, ContactActivity> activity;
  final void Function(Contact) onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return Semantics(
      container: true,
      label: l.phoneContactsFaces,
      child: SizedBox(
        height: Kit.avatarStrip + 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(Kit.gutter - 6, 14, Kit.gutter - 6, 0),
          itemCount: contacts.length,
          itemBuilder: (context, i) {
            final c = contacts[i];
            final needs = activity[c.id]?.asks != null;
            return kitId(
              TrustIds.contactsFace,
              KitPress(
                onTap: () => onOpen(c),
                radius: Kit.rAvatarStrip,
                semanticsLabel: c.name,
                child: SizedBox(
                  width: 74,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AvatarLabelMark(
                            avatar: KitAvatar(initials: nameInitials(c.name), large: true),
                            size: Kit.avatarStrip,
                            label: c.label.listMark,
                          ),
                          if (needs)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
                                child: const SizedBox.square(dimension: 9),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        c.name.trim().split(RegExp(r'\s+')).first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: KitType.rowSub.copyWith(color: needs ? t.text : t.dim, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A contact that needs the user: a gold-tinted row, "Asks for {amount}", and Review, which opens
/// the invoice. A tap elsewhere on the row opens the contact.
class _AsksRow extends ConsumerWidget {
  const _AsksRow({required this.contact, required this.invoice, required this.onTap});

  final Contact contact;
  final PendingInvoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final display = amountDisplay(ref);
    final amount = shownEpic(l, invoice.amount, hidden: display.hidden);
    final asks = l.phoneContactsAsks(amount);
    return ColoredBox(
      color: t.accentSoft,
      child: KitPress(
        onTap: onTap,
        semanticsLabel: '${contact.name}. $asks',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Kit.rowList),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                AvatarLabelMark(avatar: KitAvatar(initials: nameInitials(contact.name)), size: Kit.avatar, label: contact.label.listMark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowTitle.copyWith(color: t.text)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
                              child: const SizedBox.square(dimension: 7),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(child: Text(asks, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowSub.copyWith(color: t.accentText))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                KitButton(
                  label: l.phoneReview,
                  small: true,
                  expand: false,
                  semanticsId: TrustIds.contactsReview,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InvoiceReviewScreen(invoice: invoice))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pairing of this wallet in no contact: the name it chose, its trust badge and
/// "Not in contacts"; the menu adds it to the contacts (a contact of its name first, which
/// starts a re-pair's key check) or removes the pairing.
class _OrphanRow extends ConsumerStatefulWidget {
  const _OrphanRow({super.key, required this.record, required this.contacts});

  final PairingRecord record;
  final List<Contact> contacts;

  @override
  ConsumerState<_OrphanRow> createState() => _OrphanRowState();
}

class _OrphanRowState extends ConsumerState<_OrphanRow> {
  /// Remove or Cancel is running: the core tells the contact first, waiting up to 10 s for
  /// the relay, and the row stays until it is done.
  bool _busy = false;

  PairingRecord get record => widget.record;

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

  Future<void> _attach(BuildContext context, WidgetRef ref, Contact? contact) async {
    if (contact == null || !context.mounted) return;
    final l = context.l10n;
    final to = await attachPairingTo(context, ref, record, contact);
    if (to != null) ref.read(noticeProvider.notifier).show(l.pairSavedAs(to.name), level: NoticeLevel.success);
  }

  Future<void> _choose(BuildContext context, WidgetRef ref, String choice, Contact? suggested) async {
    switch (choice) {
      case 'named':
        await _attach(context, ref, suggested);
      case 'new':
        final saved = await savePairingAsNewContact(context, record);
        if (context.mounted) await _attach(context, ref, saved);
      case 'add':
        final picked = await pickContactForPairing(context);
        if (context.mounted) await _attach(context, ref, picked);
      case 'cancel':
        if (await confirmCancelPairing(context, peerLabel(context.l10n, record))) {
          await _run(() => pairingCall(ref, (api) => api.cancelInvite(record.id)));
        }
      case 'remove':
        if (record.ended || await confirmRemovePairing(context, peerLabel(context.l10n, record))) await _run(() => pairingCall(ref, (api) => api.removePairing(record.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final name = peerLabel(l, record);
    final all = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final suggested = sameNamedContact<Contact>(
      record,
      widget.contacts,
      (c) => c.name,
      paired: (c) => all.any((p) => p.id != record.id && p.contactId == c.id && p.state.isPaired),
      epicboxOf: (c) => c.epicbox,
    );
    final r = record;
    // Still being set up: Cancel. A stored pairing, heard or not, is removed (and the other
    // wallet told); one not heard yet is not added to a contact.
    final inFlight = r.state.isPending;
    final waiting = r.state == PairingState.waiting;
    // The row is named for the other wallet: the ended line does not repeat the name.
    final subtitle = r.ended
        ? pairingEndedRowText(l, r.endedReason ?? PairingEndReason.neverFinished)
        : r.state == PairingState.waiting
            ? l.pairAnsweredNotHeard
            : r.state == PairingState.pendingReply
                ? l.pairPairingWith(name)
                : l.pairNotInContacts;
    // The same tile and text column as a contact's row (_ContactRow).
    return KitPress(
      key: contactsPairingRowKey(r.id),
      onTap: null,
      button: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Kit.rowList),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(
            children: [
              KitAvatar(initials: nameInitials(name), neutral: r.state.isPending),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowTitle.copyWith(color: t.text))),
                        const SizedBox(width: 8),
                        if (r.state.isPending) const Flexible(child: PairPendingBadge()) else Flexible(child: TrustBadge(r, short: true)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: KitType.rowSub.copyWith(color: t.dim)),
                  ],
                ),
              ),
              if (_busy)
                const Padding(padding: EdgeInsets.all(12), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              else
                PopupMenuButton<String>(
                  key: contactsOrphanMenuKey(r.id),
                  tooltip: l.contactMore,
                  icon: Icon(KitIcons.more, color: t.dim),
                  onSelected: (v) => _choose(context, ref, v, suggested),
                  itemBuilder: (context) => [
                    if (!inFlight && !waiting && !r.ended) ...[
                      if (suggested != null) PopupMenuItem(value: 'named', child: Text(l.pairAddToNamed(suggested.name))),
                      PopupMenuItem(value: 'new', child: Text(l.pairSaveNewContact)),
                      PopupMenuItem(value: 'add', child: Text(l.pairAddToAContact)),
                    ],
                    if (inFlight)
                      PopupMenuItem(key: contactsCancelPairingKey, value: 'cancel', child: Text(l.commonCancel, style: TextStyle(color: t.risk)))
                    else
                      PopupMenuItem(value: 'remove', child: Text(l.contactRemovePairing, style: TextStyle(color: t.risk))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small star after a starred contact's name, as the desktop shows it: an icon with a
/// label, so it is not colour alone.
class ContactStar extends StatelessWidget {
  const ContactStar({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.star_rounded, size: size, color: context.tokens.accentText, semanticLabel: context.l10n.contactStarred);
}

/// A letter over the contacts whose names start with it.
class _LetterHead extends StatelessWidget {
  const _LetterHead(this.letter);

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Kit.gutter + 4, 18, Kit.gutter + 4, 8),
      child: Semantics(
        header: true,
        child: Text(letter, style: KitType.groupLabel.copyWith(color: context.tokens.dim)),
      ),
    );
  }
}

/// One contact: the avatar, the name with its trust badge (or, unpaired, its address kind),
/// then what it is reached at: the short address, the kind badges when it has several, or
/// "Allows invoices"; the note under it. A contact with no payments shows in the Contacts tab
/// as this row.
class _ContactRow extends ConsumerWidget {
  const _ContactRow({required this.contact, required this.onTap, this.forPayment = false, this.noPaymentsYet = false});

  final Contact contact;
  final VoidCallback onTap;

  /// The Contacts tab: the contact has no payment to show, and the row says so.
  final bool noPaymentsYet;

  /// Picking a recipient: a contact that takes no payments is dimmed, not pressable, and says why.
  final bool forPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final dim = KitType.rowSub.copyWith(color: t.dim);
    final note = contact.note?.trim();
    final pairing = ref.watch(pairingSupportedProvider) ? ref.watch(contactPairingProvider(contact.id)) : null;
    // A request sent to this contact, or its code answered: Waiting until it is paired.
    final pending = pairing == null && ref.watch(pairingSupportedProvider) ? ref.watch(contactPendingPairingProvider(contact.id)) : null;
    final inFlight = pending != null;
    final starred = ref.watch(favouriteContactsProvider).value?.contains(contact.id) ?? false;
    final several = contact.kinds.length > 1;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: pairing?.id, address: contact.epicbox);
    // epic1 mode: a contact without epic1 cannot be picked to pay.
    final classicOnly = forPayment && ref.watch(classicOnlyProvider(contact.id));
    final disabled = forPayment && noPayments || classicOnly;
    final Widget reach;
    if (classicOnly) {
      reach = const ClassicOnlyText();
    } else if (disabled) {
      reach = Text(l.contactTakesNoPayments, style: dim);
    } else if (noPaymentsYet) {
      reach = Text(l.phoneContactsNoPayments, style: dim);
    } else if (pairing != null && pairing.allowInvoices) {
      reach = Text(l.trustAllowsInvoices, style: dim);
    } else if (several) {
      reach = Wrap(spacing: 4, runSpacing: 4, children: [for (final k in contact.kinds) EBadge.kind(k, l: l)]);
    } else if (contact.addresses.isEmpty) {
      reach = const SizedBox.shrink();
    } else {
      reach = ShortAddressText(contact.addresses.first, style: KitType.address.copyWith(color: t.dim, fontSize: 12.5));
    }
    final row = KitPress(
      onTap: disabled ? null : onTap,
      semanticsLabel: null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Kit.rowList),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              AvatarLabelMark(avatar: KitAvatar(initials: nameInitials(contact.name)), size: Kit.avatar, label: contact.label.listMark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(contact.name, style: KitType.rowTitle.copyWith(color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (starred) ...[const SizedBox(width: 4), const ContactStar()],
                        const SizedBox(width: 8),
                        // Paired: its trust badge, never beside an Epicbox address the pairing did
                        // not bring; not paired: how it is reached.
                        if (pairing != null && pairingVouchesFor(pairing, contact.epicbox))
                          Flexible(child: TrustBadge(pairing, short: true))
                        else if (inFlight)
                          const Flexible(child: PairPendingBadge())
                        // Like the label mark, a list row marks only a kind that is not the default Epicbox.
                        else if (!several && contact.addresses.isNotEmpty && (forPayment || contact.kinds.first != RecipientKind.epicbox))
                          Flexible(child: EBadge.kind(contact.kinds.first, l: l)),
                        if (noPayments) ...[
                          const SizedBox(width: 6),
                          const NoPaymentsMark(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    reach,
                    if (note != null && note.isNotEmpty) Text(note, style: dim, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (!disabled) ...[const SizedBox(width: 6), Icon(KitIcons.chevron, size: 22, color: t.faint)],
            ],
          ),
        ),
      ),
    );
    if (classicOnly) return Tip(l.deskE1PhClassicOnlyTip, child: Semantics(enabled: false, child: row));
    return disabled ? Opacity(opacity: 0.5, child: Semantics(enabled: false, child: row)) : kitId(TrustIds.contactsRow, row);
  }
}

/// One address field of the form: its text and, once checked, the kind it holds.
class _AddressField {
  _AddressField([String? text]) : text = TextEditingController(text: text);

  final TextEditingController text;
  String? error;

  /// The kind another field already holds, when this one was given the same kind: the form
  /// asks Keep the old one or Replace it.
  RecipientKind? clash;

  /// LEPIC's verdict on an epic1 text, and the text it was for.
  String? epic1Text;
  Epic1Check? epic1;

  /// [epic1] when it is for [text], else null (not checked yet).
  Epic1Check? epic1For(String text) => epic1Text == text ? epic1 : null;

  void dispose() => text.dispose();

  /// Disposes after the frame that drops the field's row, which still holds the text until then.
  void disposeLater() => WidgetsBinding.instance.addPostFrameCallback((_) => dispose());
}

/// Adds a contact, prefilled with [name] and [address], or edits [contact]. One address per
/// kind: the kind shows on the field once the address is valid, Add another address
/// adds a field while a kind is free, and a second address of a kind asks which to keep. Pops
/// with the saved contact.
/// The phone's field: a filled group-coloured box with the button radius and no outline; the
/// gold edge shows only while the field has focus.
InputDecoration _kitField(WalletTokens t, {required String labelText, Widget? error, Widget? suffixIcon}) {
  OutlineInputBorder edge(Color c, [double w = 0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Kit.rButton),
    borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: labelText,
    error: error,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: t.group,
    border: edge(t.group),
    enabledBorder: edge(t.group),
    focusedBorder: edge(t.accent, 1.5),
    errorBorder: edge(t.risk, 1),
    focusedErrorBorder: edge(t.risk, 1.5),
  );
}

class ContactEditScreen extends ConsumerStatefulWidget {
  const ContactEditScreen({super.key, this.address, this.contact, this.name, this.addressOptional = false});

  final String? address;
  final Contact? contact;
  final String? name;

  /// Saved for a pairing, which pays the contact: an address may be added, never needed.
  final bool addressOptional;

  @override
  ConsumerState<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends ConsumerState<ContactEditScreen> {
  late final _name = TextEditingController(text: widget.contact?.name ?? widget.name);
  late final List<_AddressField> _fields = [
    if (widget.contact case final c? when c.addresses.isNotEmpty)
      for (final a in c.addresses) _AddressField(a)
    else
      _AddressField(widget.address),
  ];
  late final _note = TextEditingController(text: widget.contact?.note);
  String? _nameError;
  String? _error;
  bool _busy = false;

  bool get _editing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    // A saved epic1 link shows its kind on opening, as a typed one does.
    for (final f in _fields) {
      _checkEpic1(f);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  /// The kind [f] holds when its text is a valid address, else null. An epic1 link counts once
  /// LEPIC has read it.
  RecipientKind? _kindOf(_AddressField f) {
    final text = f.text.text.trim();
    if (text.isEmpty) return null;
    final kind = parseRecipient(text).kind;
    if (kind == RecipientKind.epic1) return f.epic1For(text) == Epic1Check.link ? kind : null;
    final l = context.l10n;
    if (_problem(l, ref.read(walletServiceProvider), text) != null) return null;
    return kind;
  }

  /// [checkContactAddress], except that the onion this contact already has stays in the build
  /// without Tor: it is kept and shown, only a new one is refused. An epic1 text gets LEPIC's
  /// verdict once [f] has it.
  String? _problem(AppLocalizations l, WalletService service, String text, [_AddressField? f]) {
    final to = parseRecipient(text);
    if (!torBuilt) {
      if (to.kind == RecipientKind.tor && to.address == widget.contact?.tor) return null;
    }
    final epic1 = to.kind == RecipientKind.epic1 ? f?.epic1For(text) : null;
    if (epic1 != null) return epic1CheckText(l, epic1, invalid: torBuilt ? l.contactsAddressInvalidAny : l.contactsAddressInvalidAnyNoTor);
    return checkContactAddress(l, service, text);
  }

  /// Has LEPIC read [f]'s epic1 text, unless it has already; then shows its line under the field
  /// (an address alone, another network, not a link), or nothing for a link it can pay.
  Future<void> _checkEpic1(_AddressField f) async {
    final text = f.text.text.trim();
    if (parseRecipient(text).kind != RecipientKind.epic1) return;
    final verdict = f.epic1For(text) ?? await checkEpic1(ref.read(epic1Provider), text);
    if (!mounted || f.text.text.trim() != text) return;
    f.epic1Text = text;
    f.epic1 = verdict;
    final kind = _kindOf(f);
    f.error = _problem(context.l10n, ref.read(walletServiceProvider), text, f);
    f.clash = kind != null && _fields.any((o) => o != f && _kindOf(o) == kind) ? kind : null;
    setState(() {});
  }

  Set<RecipientKind> get _taken => {for (final f in _fields) ?_kindOf(f)};

  List<RecipientKind> get _free => [for (final k in contactKinds) if (!_taken.contains(k)) k];

  /// After [f] changed: a valid address of a kind another field holds asks which to keep.
  void _check(_AddressField f) {
    final kind = _kindOf(f);
    f.error = null;
    f.clash = null;
    if (kind != null && _fields.any((o) => o != f && _kindOf(o) == kind)) f.clash = kind;
    setState(() {});
    _checkEpic1(f);
  }

  void _keepOld(_AddressField f) => setState(() {
    if (_fields.length > 1) {
      _fields.remove(f);
      f.disposeLater();
    } else {
      f.text.clear();
      f.clash = null;
    }
  });

  void _replace(_AddressField f) => setState(() {
    final kind = f.clash;
    final old = _fields.firstWhere((o) => o != f && _kindOf(o) == kind);
    old.text.text = f.text.text;
    _fields.remove(f);
    f.disposeLater();
  });

  void _remove(int i) => setState(() {
    if (_fields.length > 1) {
      _fields.removeAt(i).disposeLater();
    } else {
      _fields[i].text.clear();
      _fields[i].error = null;
    }
  });

  void _addField() => setState(() => _fields.add(_AddressField()));

  Future<void> _paste(_AddressField f) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    f.text.text = parseRecipient(text).address;
    _check(f);
  }

  Future<void> _scan(_AddressField f) async {
    final text = await ref.read(qrScannerProvider).scanCode(context);
    if (text == null || !mounted) return;
    // An epic1 link is kept whole: its servers are in the query.
    f.text.text = epic1Shaped(text)
        ? parseRecipient(text).address
        : parseRecipient(addressOfScan(ref.read(walletServiceProvider), text)).address;
    _check(f);
  }

  /// Another contact already saved under one of the addresses being entered.
  Contact? _duplicate(List<Contact> contacts, _AddressField f) {
    final text = f.text.text.trim();
    if (text.isEmpty) return null;
    final other = contactFor(contacts, parseRecipient(text).address);
    return other == null || other.id == widget.contact?.id ? null : other;
  }

  Future<void> _save() async {
    final l = context.l10n;
    final name = _name.text.trim();
    final service = ref.read(walletServiceProvider);
    setState(() => _busy = true);
    await Future.wait([for (final f in _fields) _checkEpic1(f)]);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _nameError = name.isEmpty ? l.contactsNameMissing : null;
      for (final f in _fields) {
        final text = f.text.text.trim();
        f.error = text.isEmpty ? null : _problem(l, service, text, f);
      }
      // A contact saved without one (from a pairing) may stay so: only a new plain contact
      // needs an address.
      final optional = widget.addressOptional || (widget.contact?.addresses.isEmpty ?? false);
      if (!optional && _fields.every((f) => f.text.text.trim().isEmpty)) _fields.first.error = l.contactsAddressMissing;
      _error = null;
    });
    if (_nameError != null || _fields.any((f) => f.error != null || f.clash != null)) return;
    final note = _note.text.trim();
    String? of(RecipientKind kind) {
      for (final f in _fields) {
        final text = f.text.text.trim();
        if (text.isNotEmpty && parseRecipient(text).kind == kind) return parseRecipient(text).address;
      }
      return null;
    }

    setState(() => _busy = true);
    try {
      final saved = await ref
          .read(contactsProvider.notifier)
          .save(
            Contact(
              id: widget.contact?.id ?? '',
              name: name,
              epicbox: of(RecipientKind.epicbox),
              http: of(RecipientKind.http),
              tor: of(RecipientKind.tor),
              epic1: of(RecipientKind.epic1),
              note: note.isEmpty ? null : note,
              label: widget.contact?.label ?? ContactLabel.wallet,
            ),
          );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final contact = widget.contact;
    if (contact == null) return;
    final pairing = ref.read(contactPairingProvider(contact.id));
    final l = context.l10n;
    final sure = await confirmAppDialog(
      context,
      title: l.contactsDeleteTitle(contact.name),
      icon: Icons.person_remove_outlined,
      tone: DialogTone.risk,
      description: pairing == null ? l.contactsDeleteBody : '${l.contactsDeleteBody}\n\n${l.contactDeletePaired(contact.name)}',
      cancelLabel: l.contactsKeep,
      confirmLabel: l.commonDelete,
      risk: true,
    );
    if (!sure || !mounted) return;
    try {
      // Deleting a paired contact removes its pairing (C-19).
      if (pairing != null) await pairingCall(ref, (api) => api.removePairing(pairing.id));
      await ref.read(contactsProvider.notifier).delete(contact.id);
      // The contact's page under this form closes by itself once the contact is gone.
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final scan = offersQrScan(ref);
    final free = _free;
    final lastFilled = _fields.isNotEmpty && _fields.last.text.text.trim().isNotEmpty && _kindOf(_fields.last) != null;
    final shownName = _name.text.trim().isEmpty ? l.contactTitle : _name.text.trim();
    return SlotScaffold(
      appBar: AppBar(
        title: Text(_editing ? l.contactsEditTitle : l.contactsNewTitle),
        actions: [
          if (_editing)
            IconButton(
              tooltip: l.contactsDeleteTooltip,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ScreenBody(
        bottom: BusyButton(
          label: l.contactsSave,
          busy: _busy,
          onPressed: _fields.any((f) => f.clash != null) ? null : _save,
        ),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _nameError = null),
            decoration: _kitField(t, labelText: l.contactsNameLabel, error: _nameError == null ? null : LiveFieldError(_nameError!)),
          ),
          for (var i = 0; i < _fields.length; i++) ...[
            const SizedBox(height: 12),
            _addressField(l, i, scan, shownName, contacts),
          ],
          if (lastFilled && free.isNotEmpty) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InlineTextButton(
                key: contactAddAnotherKey,
                icon: const Icon(Icons.add),
                onPressed: _addField,
                child: Text(l.addrAddAnother),
              ),
            ),
            if (free.length == 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(l.addrOneFree(recipientMethodWord(l, free.single)), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim)),
              ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: _kitField(t, labelText: l.contactsNoteLabel),
          ),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
        ],
      ),
    );
  }

  Widget _addressField(AppLocalizations l, int i, bool scan, String shownName, List<Contact> contacts) {
    final f = _fields[i];
    final kind = _kindOf(f);
    final duplicate = _duplicate(contacts, f);
    final clash = f.clash;
    final error = clash != null ? l.addrDuplicateType(shownName, recipientMethodWord(l, clash)) : f.error;
    return Column(
      key: ObjectKey(f),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: contactAddressFieldKey(i),
          controller: f.text,
          autocorrect: false,
          enableSuggestions: false,
          minLines: 1,
          maxLines: null,
          onChanged: (_) => _check(f),
          decoration: _kitField(
            context.tokens,
            // Any kind fits: the badge names the one it holds.
            labelText: l.addrField,
            error: error == null ? null : LiveFieldError(error),
            suffixIcon: kind != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EBadge.kind(kind, l: l),
                      IconButton(
                        key: contactAddressRemoveKey(i),
                        tooltip: l.addrRemove(recipientMethodWord(l, kind)),
                        icon: const Icon(Icons.close),
                        onPressed: () => _remove(i),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l.commonPaste,
                        icon: const Icon(Icons.content_paste),
                        onPressed: () => _paste(f),
                      ),
                      if (scan)
                        IconButton(
                          tooltip: l.scanQrTooltip,
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () => _scan(f),
                        ),
                    ],
                  ),
          ),
        ),
        if (clash != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: [
                KitButton(key: contactKeepOldKey, label: l.addrKeepOld, onPressed: () => _keepOld(f), kind: KitButtonKind.quiet, small: true, expand: false),
                KitButton(key: contactReplaceKey, label: l.addrReplace, onPressed: () => _replace(f), small: true, expand: false),
              ],
            ),
          )
        else if (duplicate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.contactsDuplicate(duplicate.name))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
