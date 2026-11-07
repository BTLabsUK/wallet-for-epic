// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contact_label.dart';
import '../contacts.dart';
import '../name_service/payment_refusals.dart' show paymentRefusalsProvider;
import '../errors.dart';
import '../l10n.dart';
import '../tor_build.dart';
import '../pairing_providers.dart';
import '../pairing_text.dart' show peerLabel, sameNamedContact;
import '../providers.dart';
import '../scan/scan_checks.dart' show addressOfScan;
import '../wallet_service.dart';
import 'address_view.dart' show ShortAddressText;
import 'app_dialog.dart';
import 'centered_body.dart';
import 'common.dart';
import 'contact_page.dart';
import 'contacts_transfer.dart';
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
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tour/tour_target.dart';

/// Keys for tests.
const Key contactsPairKey = ValueKey('contacts-pair');
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

/// The address book. With [pick], tapping a contact returns it instead of opening its page.
/// Where the wallet pairs, the app bar offers Pair; the list starts with Pair requests while
/// contacts' requests wait, and carries each pairing's badge and the pending rows.
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
    // With no contacts at all, a search field has nothing to search: the empty state sits in
    // the middle instead.
    // A shared book this wallet has no key to yet: said closed, never shown as an empty one.
    final closed = !(ref.watch(sessionProvider)?.contactsAvailable ?? true);
    final none = closed || switch (contacts) {
      AsyncData(:final value) => value.isEmpty && requests == 0 && orphans.isEmpty,
      _ => false,
    };
    return SlotScaffold(
      centered: none,
      idle: contacts.isLoading ? SlotProgress(label: l.contactsTitle) : null,
      appBar: AppBar(
        // Room for the title beside the labelled Pair in German and Russian at 360 dp.
        titleSpacing: pairs ? 4 : null,
        title: Text(widget.pick ? l.contactsPickTitle : l.contactsTitle),
        actions: [
          // Pair in one place, labelled, beside Add contact; never a gold button (Pairing UX
          // plan 4.1).
          if (pairs)
            Semantics(
              label: l.contactsPairTooltip,
              button: true,
              excludeSemantics: true,
              child: OutlinedButton.icon(
                key: contactsPairKey,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                icon: const Icon(EpicGlyphs.verified, size: 18),
                label: Text(l.pairTitle),
                onPressed: _pair,
              ),
            ),
          IconButton(
            tooltip: l.contactsAdd,
            icon: const Icon(Icons.person_add_alt),
            onPressed: _add,
          ),
          if (!widget.pick)
            PopupMenuButton<String>(
              key: contactsMoreKey,
              tooltip: l.contactMore,
              onSelected: (v) => v == 'import' ? importContacts(context, ref) : exportContacts(context, ref),
              itemBuilder: (context) => [
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
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: PhoneTourTarget(
        id: 'tour-contacts-list',
        child: closed
          ? CenteredBody(
              children: [
                EmptyState(
                  key: const ValueKey('contacts-closed'),
                  icon: const Icon(Icons.lock_outline),
                  message: l.contactsClosedTitle,
                  action: Text(
                    l.contactsClosedText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim),
                  ),
                ),
              ],
            )
          : none
          ? CenteredBody(
              children: [
                EmptyState(
                  icon: const Icon(Icons.people_outline),
                  message: l.contactsEmptyTitle,
                  action: Column(
                    children: [
                      Text(
                        l.contactsEmptyCaption,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: context.tokens.dim),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(l.contactsAdd),
                        onPressed: _add,
                      ),
                      if (pairs) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                          icon: const Icon(EpicGlyphs.verified, size: 18),
                          label: Text(l.pairTitle),
                          onPressed: _pair,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sticky: the list scrolls under it.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: l.contactsSearchHint,
                            isDense: true,
                            constraints: const BoxConstraints(minHeight: 44),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l.commonClose,
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(_search.clear),
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: switch (contacts) {
                          AsyncData(:final value) => _list(value, orphans),
                          AsyncError(:final error) => ListView(
                            padding: const EdgeInsets.all(16),
                            children: [ErrorText(describeError(l, error))],
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _list(List<Contact> all, List<PairingRecord> orphans) {
    final contacts = _filter(all);
    final t = context.tokens;
    final l = context.l10n;
    final query = _search.text.trim().toLowerCase();
    final pairs = ref.watch(pairingSupportedProvider) && !widget.pick;
    final rows = <Widget>[
      // Requests from contacts, while any wait.
      if (pairs && query.isEmpty) const PairRequestsRow(),
      // Pairings in no contact, by the name they chose: waiting or ended with their row, the
      // rest with Add to contacts or Remove pairing.
      for (final r in orphans)
        if (query.isEmpty || peerLabel(context.l10n, r).toLowerCase().contains(query)) _OrphanRow(key: ValueKey(r.id), record: r, contacts: all),
    ];
    if (contacts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: [
          ...rows,
          if (all.isNotEmpty && query.isNotEmpty)
            Text(
              l.contactsNoMatchQuery(_search.text.trim()),
              textAlign: TextAlign.center,
              style: TextStyle(color: t.dim),
            ),
        ],
      );
    }
    final grouped = contacts.length > _groupAbove;
    String? letter;
    for (final c in contacts) {
      if (grouped) {
        final first = c.name.trim().characters.firstOrNull?.toUpperCase();
        final head =
            first != null && RegExp(r'\p{L}', unicode: true).hasMatch(first)
            ? first
            : '#';
        if (head != letter) {
          letter = head;
          rows.add(_LetterHead(head));
        }
      }
      rows.add(_ContactRow(contact: c, onTap: () => _open(c), forPayment: widget.pick && widget.forPayment));
    }
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: rows);
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
    // The same tile and text column as a contact's row (_ContactRow): 48 tile, 12 gap.
    return ListTile(
      key: contactsPairingRowKey(r.id),
      minTileHeight: 64,
      horizontalTitleGap: 12,
      leading: PairAvatar(name: name, size: 48),
      subtitleTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
      title: Row(
        children: [
          Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          if (r.state.isPending) const PairPendingBadge() else TrustBadge(r, short: true),
        ],
      ),
      subtitle: Text(subtitle),
      trailing: _busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : PopupMenuButton<String>(
            key: contactsOrphanMenuKey(r.id),
            tooltip: l.contactMore,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          letter,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: context.tokens.dim),
        ),
      ),
    );
  }
}

/// One contact: the initials tile, the name with its trust badge (or, unpaired, its address
/// kind), then what it is reached at: the short address, the kind badges when it has several,
/// or "Allows invoices"; the note under it.
class _ContactRow extends ConsumerWidget {
  const _ContactRow({required this.contact, required this.onTap, this.forPayment = false});

  final Contact contact;
  final VoidCallback onTap;

  /// Picking a recipient: a contact that takes no payments is dimmed, not pressable, and says why.
  final bool forPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    final note = contact.note?.trim();
    final pairing = ref.watch(pairingSupportedProvider) ? ref.watch(contactPairingProvider(contact.id)) : null;
    // A request sent to this contact, or its code answered: Waiting until it is paired.
    final pending = pairing == null && ref.watch(pairingSupportedProvider) ? ref.watch(contactPendingPairingProvider(contact.id)) : null;
    final inFlight = pending != null;
    final starred = ref.watch(favouriteContactsProvider).value?.contains(contact.id) ?? false;
    final several = contact.kinds.length > 1;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: pairing?.id, address: contact.epicbox);
    final disabled = forPayment && noPayments;
    final Widget reach;
    if (disabled) {
      reach = Text(l.contactTakesNoPayments, style: theme.textTheme.bodySmall?.copyWith(color: t.dim));
    } else if (pairing != null && pairing.allowInvoices) {
      reach = Text(l.trustAllowsInvoices, style: theme.textTheme.bodySmall?.copyWith(color: t.dim));
    } else if (several) {
      reach = Wrap(spacing: 4, runSpacing: 4, children: [for (final k in contact.kinds) EBadge.kind(k, l: l)]);
    } else if (contact.addresses.isEmpty) {
      reach = const SizedBox.shrink();
    } else {
      reach = ShortAddressText(contact.address, style: const TextStyle(fontSize: 13));
    }
    final row = InkWell(
      onTap: disabled ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              PairAvatar(name: contact.name, size: 48, label: contact.label),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            contact.name,
                            style: theme.textTheme.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (starred) ...[const SizedBox(width: 4), const ContactStar()],
                        const SizedBox(width: 8),
                        // Paired: its trust badge, never beside an Epicbox address the pairing did
                        // not bring; not paired: how it is reached.
                        if (pairing != null && pairingVouchesFor(pairing, contact.epicbox))
                          Flexible(child: TrustBadge(pairing, short: true))
                        else if (inFlight)
                          const Flexible(child: PairPendingBadge())
                        else if (!several && contact.addresses.isNotEmpty)
                          Flexible(child: EBadge.kind(parseRecipient(contact.address).kind, l: l)),
                        if (noPayments) ...[
                          const SizedBox(width: 6),
                          const NoPaymentsMark(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    reach,
                    if (note != null && note.isNotEmpty)
                      Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.dim,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return disabled ? Opacity(opacity: 0.5, child: Semantics(enabled: false, child: row)) : row;
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

  void dispose() => text.dispose();

  /// Disposes after the frame that drops the field's row, which still holds the text until then.
  void disposeLater() => WidgetsBinding.instance.addPostFrameCallback((_) => dispose());
}

/// Adds a contact, prefilled with [name] and [address], or edits [contact]. One address per
/// kind: the kind shows on the field once the address is valid, Add another address
/// adds a field while a kind is free, and a second address of a kind asks which to keep. Pops
/// with the saved contact.
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
  void dispose() {
    _name.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  /// The kind [f] holds when its text is a valid address, else null.
  RecipientKind? _kindOf(_AddressField f) {
    final text = f.text.text.trim();
    if (text.isEmpty) return null;
    final l = context.l10n;
    if (_problem(l, ref.read(walletServiceProvider), text) != null) return null;
    return parseRecipient(text).kind;
  }

  /// [checkContactAddress], except that the onion this contact already has stays in the build
  /// without Tor: it is kept and shown, only a new one is refused.
  String? _problem(AppLocalizations l, WalletService service, String text) {
    if (!torBuilt) {
      final to = parseRecipient(text);
      if (to.kind == RecipientKind.tor && to.address == widget.contact?.tor) return null;
    }
    return checkContactAddress(l, service, text);
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
    f.text.text = parseRecipient(
      addressOfScan(ref.read(walletServiceProvider), text),
    ).address;
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
    setState(() {
      _nameError = name.isEmpty ? l.contactsNameMissing : null;
      for (final f in _fields) {
        final text = f.text.text.trim();
        f.error = text.isEmpty ? null : _problem(l, service, text);
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
            decoration: InputDecoration(
              labelText: l.contactsNameLabel,
              error: _nameError == null ? null : LiveFieldError(_nameError!),
              border: const OutlineInputBorder(),
            ),
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
            decoration: InputDecoration(
              labelText: l.contactsNoteLabel,
              border: const OutlineInputBorder(),
            ),
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
          decoration: InputDecoration(
            labelText: kind == null ? l.addrField : l.addrFieldTyped(recipientMethodWord(l, kind)),
            error: error == null ? null : LiveFieldError(error),
            border: const OutlineInputBorder(),
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
                OutlinedButton(key: contactKeepOldKey, onPressed: () => _keepOld(f), child: Text(l.addrKeepOld)),
                FilledButton.tonal(key: contactReplaceKey, onPressed: () => _replace(f), child: Text(l.addrReplace)),
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
