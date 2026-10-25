import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recipient.dart' show RecipientKind, parseRecipient;
import '../../desk_l10n.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../app/tour.dart';
import '../../../l10n.dart' show AppLocalizations, localDayMonth;
import '../../widgets/kit.dart';
import '../../../models.dart' show KeysChoice, PairingRecord, PairingState, SealMode, contactKinds;
import '../../../ui/method_names.dart' show recipientMethodWord;
import '../../../ui/pairing/pairing_parts.dart' show TrustBadge;
import '../../data/pairing_state.dart';
import '../pairing/pair_screens.dart';
import 'contacts_transfer.dart';
import 'tx_display.dart';

/// Starts Contacts with one selected, editing, adding, or empty.
class ContactsArgs {
  const ContactsArgs({this.selectedId, this.editing = false, this.adding = false, this.empty = false, this.loading = false});

  final String? selectedId;
  final bool editing;
  final bool adding;
  final bool empty;
  final bool loading;
}

enum _Sort { name, recent }

/// The sort toggle and the count only earn their place in a long list.
const int _longList = 6;

/// Contacts: the list with search and sort, the selected contact (or its form) beside it.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  late final ContactsArgs _args = widget.arg is ContactsArgs ? widget.arg! as ContactsArgs : const ContactsArgs();
  late String? _selected = _args.selectedId;
  late bool _editing = _args.editing;
  late bool _adding = _args.adding;
  final _query = TextEditingController();
  _Sort _sort = _Sort.name;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _add() => setState(() {
    _adding = true;
    _editing = false;
    _selected = null;
  });

  void _back() => setState(() {
    _adding = false;
    _editing = false;
    _selected = null;
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final all = _args.loading ? null : (_args.empty ? const <Contact>[] : ref.watch(deskProvider.select((s) => s.contacts)));
    final split = MediaQuery.sizeOf(context).width >= Bp.desktop;
    final selected = all?.where((x) => x.id == _selected).firstOrNull;
    final paneOpen = _adding || (selected != null && (_editing || _selected != null));
    final panel = BoxDecoration(
      color: c.s1,
      border: Border.all(color: c.line),
      borderRadius: BorderRadius.circular(Rad.sm),
    );

    Widget pane() {
      if (_adding || (_editing && selected != null)) {
        return _ContactForm(
          contact: _adding ? null : selected,
          onDone: (saved) => setState(() {
            _adding = false;
            _editing = false;
            if (saved != null) _selected = saved;
          }),
        );
      }
      return _ContactDetail(contact: selected!, onEdit: () => setState(() => _editing = true), onDeleted: () => setState(() => _selected = null));
    }

    if (all == null) {
      return EPage(
        title: l.deskConTitle,
        child: Container(
          decoration: panel,
          padding: EdgeInsets.all(Sp.x8),
          child: Semantics(
            liveRegion: true,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Sp.x3,
              children: [
                const ESpinner(),
                Text(l.deskConLoading, style: ts.bodyDim),
              ],
            ),
          ),
        ),
      );
    }
    final orphans = ref.watch(deskPairsProvider) ? ref.watch(deskOrphanPairingsProvider) : const <PairingRecord>[];
    if (all.isEmpty && orphans.isEmpty && !_adding) {
      return EPage(
        title: l.deskConTitle,
        width: EPageWidth.narrow,
        // Import contacts fills an empty book.
        actions: const [ContactsMoreButton()],
        child: Container(
          decoration: panel,
          child: _Empty(onAdd: _add),
        ),
      );
    }
    if (!split && paneOpen) {
      return EPage(title: _adding ? l.deskConNewTitle : (_editing ? l.deskConEditTitle : selected!.name), width: EPageWidth.narrow, onBack: _back, child: pane());
    }

    final q = _query.text.trim().toLowerCase();
    final shown =
        [
          for (final x in all)
            if (q.isEmpty || x.name.toLowerCase().contains(q) || x.addresses.any((a) => a.toLowerCase().contains(q))) x,
        ]..sort(
          (a, b) => _sort == _Sort.name
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : (b.lastUsed ?? DateTime(2000)).compareTo(a.lastUsed ?? DateTime(2000)),
        );
    final long = all.length > _longList;
    final count = q.isEmpty ? l.deskConCount(all.length) : (shown.isEmpty ? l.deskConNoMatches : l.deskConMatches(shown.length));

    // The search in the list's header band, level with the detail's (docs/plans/w7-layout.md R2).
    final list = TourTarget(
      id: 'contacts-list',
      child: EPanel(
      padding: EdgeInsets.zero,
      head: Padding(
        padding: EdgeInsetsDirectional.only(end: Sp.x3),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_query.text.isNotEmpty) setState(_query.clear);
            },
          },
          child: EInput(
            size: EBtnSize.sm,
            controller: _query,
            hint: l.deskConSearchHint,
            leading: EIcons.search,
            semanticLabel: l.deskConSearchLabel,
            onChanged: (_) => setState(() {}),
            trailing: _query.text.isEmpty
                ? null
                : EIconButton(icon: EIcons.close, label: l.deskConClearSearch, size: EBtnSize.inline, onPressed: () => setState(_query.clear)),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (long) ...[
          Padding(
            padding: EdgeInsets.all(Sp.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Sp.x3,
                    runSpacing: Sp.x2,
                    children: [
                      Semantics(liveRegion: true, child: Text(count, style: ts.small)),
                      ESegmented<_Sort>(
                        segments: [ESegment(_Sort.name, l.deskConSortName), ESegment(_Sort.recent, l.deskConSortRecent)],
                        value: _sort,
                        onChanged: (v) => setState(() => _sort = v),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          ],
          // Pairings in no contact, by the name they chose (PAIR-AND-8).
          for (final r in orphans)
            if (q.isEmpty || r.shownName.toLowerCase().contains(q)) _OrphanRow(record: r),
          if (shown.isEmpty && _query.text.isEmpty && orphans.isEmpty)
            Padding(
              padding: EdgeInsets.all(Sp.x5),
              child: Text(l.deskConNone, style: ts.bodyDim, textAlign: TextAlign.center),
            )
          else if (shown.isEmpty)
            Padding(
              padding: EdgeInsets.all(Sp.x5),
              child: Column(
                children: [
                  Text(l.deskConNoMatchList, style: ts.bodyDim),
                  SizedBox(height: Sp.x2),
                  EButton.ghost(label: l.deskConClearSearch, onPressed: () => setState(_query.clear)),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.all(Sp.x2),
              child: Column(
                children: [
                  for (final x in shown)
                    _ContactRow(
                      contact: x,
                      selected: paneOpen && !_adding && x.id == selected?.id,
                      onTap: () => setState(() {
                        _selected = x.id;
                        _editing = false;
                        _adding = false;
                      }),
                      onDouble: () => ref.read(deskNavProvider.notifier).go(DeskRoute.send, x),
                    ),
                ],
              ),
            ),
        ],
      ),
      ),
    );

    final compactBar = MediaQuery.sizeOf(context).width < Bp.phone;
    return EPage(
      title: l.deskConTitle,
      width: EPageWidth.full,
      actions: [
        // In a phone-wide window the pairing actions are icons (named in their tooltips), so
        // the bar keeps room for the title and Add contact at any text size.
        if (ref.watch(deskPairsProvider)) ...[
          if (ref.watch(deskPendingPairingsProvider).isNotEmpty)
            if (compactBar)
              EIconButton(
                label: '${l.pendingTitle} · ${ref.watch(deskPendingPairingsProvider).length}',
                icon: EIcons.clock,
                onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.pairPending),
              )
            else
              EButton.ghost(
                label: '${l.pendingTitle} · ${ref.watch(deskPendingPairingsProvider).length}',
                icon: EIcons.clock,
                onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.pairPending),
              ),
          if (compactBar)
            EIconButton(label: l.pairTitle, icon: EIcons.trusted, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.pair))
          else
            EButton.ghost(label: l.pairTitle, icon: EIcons.trusted, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.pair)),
        ],
        if (_adding || _editing)
          EButton.ghost(label: l.deskConAdd, icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: _add)
        else
          EButton.primary(label: l.deskConAdd, icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: _add),
        const ContactsMoreButton(),
      ],
      child: split
          // The list and the detail are one unit (docs/plans/w7-layout.md R1): same top and bottom.
          ? PanelRow(
              sideFirst: true,
              sideWidth: Ctl.sideList,
              side: list,
              // A header band like the list's: what the pane shows.
              main: EPanel(
                    title: _adding ? l.deskConNewTitle : (_editing ? l.deskConEditTitle : l.deskConDetailsTitle),
                    padding: EdgeInsets.all(Sp.x6),
                    child: paneOpen
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 600.u),
                              child: pane(),
                            ),
                          )
                        : const _Idle(),
                  ),
            )
          : list,
    );
  }
}

/// Nothing chosen yet (desktop width).
class _Idle extends StatelessWidget {
  const _Idle();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: Sp.x10),
    child: Column(
      children: [
        Icon(EIcons.contacts, size: Ctl.iconLg, color: context.dc.faint),
        SizedBox(height: Sp.x3),
        Text(context.l10n.deskConIdle, style: context.ts.bodyDim, textAlign: TextAlign.center),
      ],
    ),
  );
}

/// No contacts saved yet.
class _Empty extends ConsumerWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x10),
      child: Column(
        children: [
          ExcludeSemantics(child: Icon(EIcons.contacts, size: Ctl.iconLg, color: c.faint)),
          SizedBox(height: Sp.x5),
          Semantics(
            header: true,
            child: Text(l.deskConEmptyTitle, style: ts.h3, textAlign: TextAlign.center),
          ),
          SizedBox(height: Sp.x2),
          Text(l.deskConEmptyText, style: ts.bodyDim, textAlign: TextAlign.center),
          SizedBox(height: Sp.x2),
          Text(
            l.deskConEmptyLocal,
            style: ts.small.copyWith(color: c.faint),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Sp.x5),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              EButton.primary(label: l.deskConAdd, icon: EIcons.userPlus, onPressed: onAdd),
              EButton.ghost(label: l.deskConSendToAddress, size: EBtnSize.md, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.send)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The contact's picture (the mock draws a placeholder), else its initials.
class _Pic extends StatelessWidget {
  const _Pic({required this.name, required this.picture, required this.size});

  final String name;
  final bool picture;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!DeskFeatures.contactPictures || !picture) return EAvatar(name, size: size);
    final c = context.dc;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Rad.sm),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.accent, c.ok]),
        ),
        child: Icon(EIcons.user, size: size * 0.55, color: c.bg),
      ),
    );
  }
}

/// A pairing of this wallet in no contact: the name it chose, its badge and "Not in contacts",
/// with the choices of Settings › Invoices (a contact of its name first, PAIR-LNX-7).
class _OrphanRow extends ConsumerWidget {
  const _OrphanRow({required this.record});

  final PairingRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final r = record;
    final suggested = deskSuggestedContact(ref, r);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DeskPairAvatar(name: r.shownName, size: 40.u),
          SizedBox(width: 14.u),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(r.shownName, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    SizedBox(width: Sp.x2),
                    TrustBadge(r, short: true),
                  ],
                ),
                Text(l.pairNotInContacts, style: ts.small),
                SizedBox(height: Sp.x2),
                Wrap(
                  spacing: Sp.x2,
                  runSpacing: Sp.x2,
                  children: [
                    if (suggested != null)
                      EButton.primary(label: l.pairAddToNamed(suggested.name), size: EBtnSize.sm, onPressed: () => deskAttachPairing(context, ref, r, suggested)),
                    EButton(label: l.pairSaveNewContact, size: EBtnSize.sm, onPressed: () => deskPutPairingInContacts(context, ref, r, asNew: true)),
                    EButton(label: l.pairAddToAContact, size: EBtnSize.sm, onPressed: () => deskPutPairingInContacts(context, ref, r, asNew: false)),
                    EButton(
                      label: l.contactRemovePairing,
                      kind: EBtnKind.danger,
                      size: EBtnSize.sm,
                      onPressed: () async {
                        if (await deskConfirmRemovePairing(context, r.shownName)) await deskPairingCall(ref, (api) => api.removePairing(r.id));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends ConsumerStatefulWidget {
  const _ContactRow({required this.contact, required this.selected, required this.onTap, required this.onDouble});

  final Contact contact;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDouble;

  @override
  ConsumerState<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends ConsumerState<_ContactRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final x = widget.contact;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: x.name,
      child: GestureDetector(
        onDoubleTap: widget.onDouble,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          borderRadius: BorderRadius.circular(Rad.sm),
          child: Container(
            constraints: BoxConstraints(minHeight: 64.u),
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x3),
            decoration: BoxDecoration(color: widget.selected ? c.s3 : (_hover ? c.hover : null), borderRadius: BorderRadius.circular(Rad.sm)),
            child: Row(
              children: [
                _Pic(name: x.name, picture: x.hasPicture, size: 40.u),
                SizedBox(width: 14.u),
                Expanded(
                  child: EAddressLines(
                    name: x.name,
                    address: x.address,
                    addresses: x.addresses,
                    note: x.note,
                    nameTrailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (x.favourite)
                          Padding(
                            padding: EdgeInsets.only(left: Sp.x1),
                            child: Icon(EIcons.star, size: 14.u, color: c.accentText),
                          ),
                        if (ref.watch(deskPairsProvider) ? ref.watch(deskContactPairingProvider(x.id)) : null case final p?)
                          Padding(padding: EdgeInsets.only(left: Sp.x2), child: TrustBadge(p, short: true)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactDetail extends ConsumerWidget {
  const _ContactDetail({required this.contact, required this.onEdit, required this.onDeleted});

  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final x = contact;
    final nav = ref.read(deskNavProvider.notifier);
    final pairs = ref.watch(deskPairsProvider);
    // Its payments: to and from its address, and through any pairing attached to it.
    final pairings = pairs ? {for (final r in ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[]) if (r.contactId == x.id) r.id} : const <String>{};
    final mine = (ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[])
        .where((t) => t.counterparty == x.address || (t.pairingId != null && pairings.contains(t.pairingId)))
        .toList();
    final last = mine.isEmpty ? x.lastUsed : mine.first.created;
    final pairing = pairs ? ref.watch(deskContactPairingProvider(x.id)) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Pic(name: x.name, picture: x.hasPicture, size: 56.u),
            SizedBox(width: Sp.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(x.name, style: ts.h2)),
                  SizedBox(height: Sp.x1),
                  Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (pairing != null) TrustBadge(pairing),
                      if (last != null) Text(l.deskConLastTx(whenText(l, last)), style: ts.small),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Sp.x5),
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            // A contact with no address is paid through its pairing, while it can take one.
            EButton.primary(
              key: const ValueKey('contact-send'),
              label: l.deskConSend,
              icon: EIcons.send,
              size: EBtnSize.sm,
              onPressed: x.addresses.isEmpty && !(pairing?.paysByMailbox ?? false) ? null : () => nav.go(DeskRoute.send, x),
            ),
            EButton(label: l.deskConEdit, icon: EIcons.pencil, size: EBtnSize.sm, onPressed: onEdit),
            EButton(
              label: x.favourite ? l.deskConUnstar : l.deskConStar,
              icon: x.favourite ? EIcons.star : EIcons.starOutline,
              size: EBtnSize.sm,
              onPressed: () => ref
                  .read(deskProvider.notifier)
                  .saveContact(
                    x.copyWith(favourite: !x.favourite),
                  )
                  .then<void>((_) {}, onError: (Object e) {
                    if (context.mounted) showEToast(context, deskErrorText(e, l), tone: ETone.risk);
                  }),
            ),
            EButton(
              label: l.deskConDelete,
              icon: EIcons.trash,
              kind: EBtnKind.danger,
              size: EBtnSize.sm,
              onPressed: () async {
                final ok = await showDeleteContactDialog(context, x, paired: pairing != null);
                if (ok != true || !context.mounted) return;
                try {
                  // Deleting a paired contact removes this wallet's pairing with it (C-19).
                  if (pairing != null) await deskPairingCall(ref, (api) => api.removePairing(pairing.id));
                  await ref.read(deskProvider.notifier).deleteContact(x.id);
                } on Object catch (e) {
                  if (context.mounted) showEToast(context, l.deskConNotDeleted, text: deskErrorText(e, l), tone: ETone.risk);
                  return;
                }
                if (context.mounted) showEToast(context, l.deskConDeleted(x.name), tone: ETone.ok);
                onDeleted();
              },
            ),
          ],
        ),
        if (x.addresses.isEmpty && pairing != null && !pairing.paysByMailbox) ...[
          SizedBox(height: Sp.x2),
          Text(
            pairing.state == PairingState.keysChanged ? l.contactSendKeysChanged : l.contactSendNoSealed(x.name),
            key: const ValueKey('contact-send-reason'),
            style: ts.small,
          ),
        ],
        SizedBox(height: Sp.x6),
        Text(l.contactAddresses, style: ts.label),
        SizedBox(height: 6.u),
        ESetGroup(
          gap: false,
          rows: [
            // A contact with only a pairing: payments go through it.
            if (x.addresses.isEmpty && pairing != null)
              Padding(
                key: const ValueKey('contact-via-pairing'),
                padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
                child: Row(
                  children: [
                    Icon(EIcons.lock, size: 16.u, color: c.dim),
                    SizedBox(width: Sp.x3),
                    Expanded(child: Text(l.contactNoAddressPaired, style: pairing.caps.opensSealed ? ts.body : ts.bodyDim)),
                  ],
                ),
              ),
            // None at all (a pairing-only contact while Pairing is off): said, not an empty
            // group, so the greyed Send has its reason (LNX3-3).
            if (x.addresses.isEmpty && pairing == null)
              Padding(
                key: const ValueKey('contact-no-address'),
                padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
                child: Text(l.contactNoAddresses, style: ts.bodyDim),
              ),
            for (final k in x.kinds)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
                child: Row(
                  children: [
                    EBadge.kind(k, l: l),
                    SizedBox(width: Sp.x3),
                    Expanded(child: EAddress(x.addressOf(k)!, copyLabel: l.contactCopyAddress(recipientMethodWord(l, k)))),
                  ],
                ),
              ),
          ],
        ),
        if (x.note != null) ...[SizedBox(height: Sp.x5), Text(l.deskConNote, style: ts.label), SizedBox(height: Sp.x1), Text(x.note!, style: ts.body)],
        // Pairing (RFC 0002): trust, Seal payments, Allow invoices, the relay, Remove pairing.
        if (pairs) ...[SizedBox(height: Sp.x6), DeskPairingBlock(contact: x, pairing: pairing)],
        SizedBox(height: Sp.x6),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l.deskConTxWith(x.name), style: ts.label, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (mine.isNotEmpty) ELink(label: l.deskConAllTx, onPressed: () => nav.go(DeskRoute.activity)),
          ],
        ),
        SizedBox(height: Sp.x2),
        if (mine.isEmpty)
          Text(l.deskConTxNone, style: ts.bodyDim)
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: Column(
              children: [
                for (final (i, t) in mine.take(5).indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.line),
                  TxRow(tx: t, compact: true, title: t.incoming ? l.deskConTxReceived : l.deskConTxSent, onTap: () => nav.go(DeskRoute.activity, t.id)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm({required this.contact, required this.onDone});

  final Contact? contact;

  /// The saved contact's id, or null when cancelled.
  final ValueChanged<String?> onDone;

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

/// One address field: its text and the kind another field already holds when this one was
/// given the same kind (Keep the old one or Replace it).
class _AddrField {
  _AddrField([String? text]) : text = TextEditingController(text: text);

  final TextEditingController text;
  final FocusNode focus = FocusNode();
  RecipientKind? clash;

  void dispose() {
    text.dispose();
    focus.dispose();
  }

  /// Disposes after the frame that drops the field's row, which still holds both until then.
  void disposeLater() => WidgetsBinding.instance.addPostFrameCallback((_) => dispose());
}

/// The form in the detail pane (SPEC 2.5, desktop): Name, one field per address with its kind
/// badge and ×, a dashed free field while a kind is free, Note.
class _ContactFormState extends ConsumerState<_ContactForm> {
  late final _name = TextEditingController(text: widget.contact?.name);
  late final List<_AddrField> _fields = [
    for (final a in widget.contact?.addresses ?? const <String>[]) _AddrField(a),
    _AddrField(),
  ];
  late final _note = TextEditingController(text: widget.contact?.note);
  late bool _picture = widget.contact?.hasPicture ?? false;
  final _nameFocus = FocusNode();

  /// Fields left with something in them: their errors show from then on.
  final Set<String> _touched = {};
  bool _tried = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _name.text.trim().isNotEmpty) setState(() => _touched.add('name'));
    });
  }

  @override
  void dispose() {
    _name.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    _note.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String? get _nameError => _name.text.trim().isEmpty ? context.l10n.deskConErrName : null;

  /// The kind [f] holds when its text is a valid address this build sends to, else null.
  RecipientKind? _kindOf(_AddrField f) {
    final a = f.text.text.trim();
    if (a.isEmpty) return null;
    final p = parseAddress(a, ref.read(deskApiProvider));
    final allowed = switch (p.kind) {
      AddressKind.tor => DeskFeatures.tor,
      AddressKind.http => DeskFeatures.httpDirect || DeskFeatures.tor,
      AddressKind.epicbox => true,
      AddressKind.none => false,
    };
    if (!allowed || !p.complete) return null;
    return parseRecipient(p.canonical).kind;
  }

  String? _errorOf(_AddrField f) {
    final l = context.l10n;
    if (f.clash != null) return l.addrDuplicateType(_name.text.trim().isEmpty ? l.contactTitle : _name.text.trim(), recipientMethodWord(l, f.clash!));
    if (f.text.text.trim().isEmpty) return null;
    return _kindOf(f) == null ? l.deskConErrAddressInvalid : null;
  }

  List<RecipientKind> get _free => [
    for (final k in contactKinds)
      if (!_fields.any((f) => _kindOf(f) == k)) k,
  ];

  void _changed(_AddrField f) {
    final kind = _kindOf(f);
    f.clash = kind != null && _fields.any((o) => o != f && _kindOf(o) == kind) ? kind : null;
    // One empty field stays at the end while a kind is free.
    final empties = _fields.where((x) => x.text.text.trim().isEmpty).toList();
    if (empties.isEmpty && _free.isNotEmpty) _fields.add(_AddrField());
    while (_fields.where((x) => x.text.text.trim().isEmpty).length > 1) {
      final extra = _fields.lastWhere((x) => x.text.text.trim().isEmpty && x != f);
      _fields.remove(extra);
      extra.disposeLater();
    }
    setState(() {});
  }

  void _remove(_AddrField f) {
    _fields.remove(f);
    f.disposeLater();
    if (!_fields.any((x) => x.text.text.trim().isEmpty)) _fields.add(_AddrField());
    setState(() {});
  }

  void _keepOld(_AddrField f) {
    f.text.clear();
    f.clash = null;
    _changed(f);
  }

  void _replace(_AddrField f) {
    final old = _fields.firstWhere((o) => o != f && _kindOf(o) == f.clash);
    old.text.text = f.text.text;
    _remove(f);
  }

  /// A contact saved without an address (from a pairing) may stay so; only a new one needs
  /// an address (PAIR-AND-9).
  bool get _addressOptional => widget.contact != null && widget.contact!.addresses.isEmpty;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_nameError != null) return _nameFocus.requestFocus();
    final filled = [for (final f in _fields) if (f.text.text.trim().isNotEmpty) f];
    if ((filled.isEmpty && !_addressOptional) || filled.any((f) => _errorOf(f) != null)) return;
    String? of(RecipientKind kind) {
      for (final f in filled) {
        if (_kindOf(f) == kind) return parseAddress(f.text.text, ref.read(deskApiProvider)).canonical;
      }
      return null;
    }

    // The addresses were checked as text above; saving only stores them and never reaches out.
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final String id;
    try {
      id = await ref
          .read(deskProvider.notifier)
          .saveContact(
            Contact(
              id: widget.contact?.id ?? '',
              name: _name.text.trim(),
              epicbox: of(RecipientKind.epicbox),
              http: of(RecipientKind.http),
              tor: of(RecipientKind.tor),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              favourite: widget.contact?.favourite ?? false,
              lastUsed: widget.contact?.lastUsed,
              hasPicture: _picture,
            ),
          );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = deskErrorText(e, context.l10n);
        });
      }
      return;
    }
    if (mounted) widget.onDone(id);
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    final nameError = _tried || _touched.contains('name') ? _nameError : null;
    final free = _free;
    final noAddress = _tried && !_addressOptional && _fields.every((f) => f.text.text.trim().isEmpty);
    // Enter: Name → Address, then Save (the Note keeps Enter for a new line).
    // A form with typed changes holds Back (mouse, Alt+Left).
    final dirty = _name.text != (widget.contact?.name ?? '') ||
        _note.text != (widget.contact?.note ?? '') ||
        [for (final f in _fields) if (f.text.text.trim().isNotEmpty) f.text.text.trim()].join('|') != (widget.contact?.addresses ?? const []).join('|');
    return DeskStepBack(
      onBack: dirty ? () {} : null,
      child: EForm(
      onSubmit: _saving ? null : _save,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Pic(name: _name.text.isEmpty ? '?' : _name.text, picture: _picture, size: 56.u),
            SizedBox(width: Sp.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(widget.contact == null ? l.deskConNewTitle : l.deskConEditTitle, style: ts.h2)),
                  if (DeskFeatures.contactPictures) ...[
                  SizedBox(height: Sp.x2),
                  Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x1,
                    children: [
                      EButton(
                        label: _picture ? l.deskConChangePicture : l.deskConAddPicture,
                        icon: EIcons.camera,
                        kind: EBtnKind.ghost,
                        size: EBtnSize.inline,
                        tabStop: false,
                        onPressed: () => setState(() => _picture = true),
                      ),
                      if (_picture) EButton(label: l.deskConRemovePicture, icon: EIcons.trash, kind: EBtnKind.ghost, size: EBtnSize.inline, tabStop: false, onPressed: () => setState(() => _picture = false)),
                    ],
                  ),
                  SizedBox(height: Sp.x1),
                  Text(l.deskConPictureHelp, style: ts.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Sp.x6),
        EField(
          label: l.deskConFieldName,
          error: nameError,
          child: EInput(controller: _name, focusNode: _nameFocus, invalid: nameError != null, onChanged: (_) => setState(() {}), autofocus: true),
        ),
        SizedBox(height: Sp.x5),
        Text(l.contactAddresses, style: ts.label),
        SizedBox(height: Sp.x2),
        for (final f in _fields) ...[
          if (f.text.text.trim().isNotEmpty || free.isNotEmpty)
            Padding(
              key: ObjectKey(f),
              padding: EdgeInsets.only(bottom: Sp.x3),
              child: _addressField(l, c, f, free, noAddress && f == _fields.first),
            ),
        ],
        Text(l.addrDesktopRule, style: ts.small),
        SizedBox(height: Sp.x5),
        EField(
          label: l.deskConNote,
          optional: true,
          child: EInput(controller: _note, maxLines: 3),
        ),
        SizedBox(height: Sp.x6),
        if (_saveError != null) ...[
          ENotice(title: l.deskConSaveFailed, text: _saveError, tone: ETone.risk),
          SizedBox(height: Sp.x4),
        ],
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            EButton(label: l.commonCancel, tabStop: false, onPressed: () => widget.onDone(null)),
            EButton.primary(label: l.deskConSave, icon: EIcons.check, busy: _saving, onPressed: _fields.any((f) => f.clash != null) ? null : _save),
          ],
        ),
      ],
    ),
    ),
    );
  }

  Widget _addressField(AppLocalizations l, DeskColors c, _AddrField f, List<RecipientKind> free, bool missing) {
    final kind = _kindOf(f);
    final empty = f.text.text.trim().isEmpty;
    final error = missing ? l.deskConErrAddressEmpty : (_tried || !f.focus.hasFocus ? _errorOf(f) : (f.clash != null ? _errorOf(f) : null));
    final hint = empty && _fields.length > 1 && free.isNotEmpty ? l.addrDesktopThird(recipientMethodWord(l, free.first)) : l.deskConFieldAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EField(
          label: kind == null ? l.addrField : l.addrFieldTyped(recipientMethodWord(l, kind)),
          error: error,
          child: EInput(
            controller: f.text,
            focusNode: f.focus,
            mono: true,
            hint: hint,
            invalid: error != null,
            onChanged: (_) => _changed(f),
            trailing: kind == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EBadge.kind(kind, l: l),
                      EIconButton(icon: EIcons.close, label: l.addrRemove(recipientMethodWord(l, kind)), size: EBtnSize.inline, onPressed: () => _remove(f)),
                    ],
                  ),
          ),
        ),
        if (f.clash != null) ...[
          SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            children: [
              EButton(label: l.addrKeepOld, size: EBtnSize.sm, onPressed: () => _keepOld(f)),
              EButton.primary(label: l.addrReplace, size: EBtnSize.sm, onPressed: () => _replace(f)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Asks before deleting a contact; a [paired] one says its pairing goes too.
Future<bool?> showDeleteContactDialog(BuildContext context, Contact x, {bool paired = false}) => showEDialog<bool>(
  context,
  builder: (context) {
    final l = context.l10n;
    return EDialog(
      title: l.deskConDeleteTitle(x.name),
      icon: EIcons.trash,
      tone: ETone.risk,
      description: paired ? '${l.deskConDeleteBody}\n\n${l.contactDeletePaired(x.name)}' : l.deskConDeleteBody,
      actions: [
        EButton(label: l.deskConKeep, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
        EButton(label: l.deskConDeleteAction, icon: EIcons.trash, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
      ],
    );
  },
);

/// A contact's Pairing (SPEC 2.4, desktop): Not paired with Pair; or the status row (Verified
/// with the date and Check again, or Paired, not verified with Check the words), Seal
/// payments and Allow invoices with their info, Delivered via, Remove pairing; the keys-changed
/// and relay notices above it; Issue an invoice for a verified contact that pays requests.
class DeskPairingBlock extends ConsumerStatefulWidget {
  const DeskPairingBlock({super.key, required this.contact, required this.pairing});

  final Contact contact;
  final PairingRecord? pairing;

  @override
  ConsumerState<DeskPairingBlock> createState() => _DeskPairingBlockState();
}

class _DeskPairingBlockState extends ConsumerState<DeskPairingBlock> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() call) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await call();
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final x = widget.contact;
    final p = widget.pairing;
    final nav = ref.read(deskNavProvider.notifier);
    if (p == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.contactPairing, style: ts.label),
          SizedBox(height: Sp.x2),
          ESetGroup(
            gap: false,
            rows: [
              ESetRow(
                title: l.pairNotPaired,
                text: l.pairNotPairedHint,
                control: EButton(label: l.pairTitle, icon: EIcons.trusted, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair, x)),
              ),
            ],
          ),
        ],
      );
    }
    final name = x.name;
    final verified = p.state == PairingState.verified;
    final changed = p.state == PairingState.keysChanged;
    final paused = ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff;
    final locked = _busy || paused || changed;
    final back = ref.watch(deskKeysBackProvider).contains(p.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (changed) ...[
          ENotice(
            title: l.contactKeysChangedTitle(name),
            text: l.contactKeysChangedBody,
            tone: ETone.warn,
            actionsBelow: true,
            actions: [
              EButton.primary(label: l.sasTitle, size: EBtnSize.sm, onPressed: () => showDeskCheckWords(context, ref, p.id, recheck: true)),
              EButton(label: l.contactKeepOldKeys, size: EBtnSize.sm, onPressed: () => _run(() => deskPairingCall(ref, (api) => api.resolveKeysChanged(p.id, KeysChoice.keepOld)))),
              EButton(label: l.contactUseNewKeys, size: EBtnSize.sm, onPressed: () => _run(() => deskPairingCall(ref, (api) => api.resolveKeysChanged(p.id, KeysChoice.useNew)))),
            ],
          ),
          SizedBox(height: Sp.x4),
        ],
        if (back && !changed) ...[
          ENotice(
            title: l.contactKeysBack(name),
            text: l.contactKeysBackBody,
            tone: ETone.ok,
            actions: [EButton(label: l.commonOk, size: EBtnSize.sm, onPressed: () => ref.read(deskKeysBackProvider.notifier).close(p.id))],
          ),
          SizedBox(height: Sp.x4),
        ],
        if (p.relayDown && !paused) ...[
          ENotice(title: l.contactRelayDownTitle(name), text: l.contactRelayDownBody, tone: ETone.warn),
          SizedBox(height: Sp.x4),
        ],
        if (p.seal == SealMode.degraded && !changed) ...[
          ENotice(title: l.contactSealDegradedTitle(name), text: l.contactSealDegradedBody(name), tone: ETone.info),
          SizedBox(height: Sp.x4),
        ],
        if (paused) ...[
          ENotice(title: l.contactPausedEpicboxOff, text: l.contactPausedEpicboxOffBody, tone: ETone.info, icon: Icons.pause_circle_outline),
          SizedBox(height: Sp.x4),
        ],
        Text(l.contactPairing, style: ts.label),
        SizedBox(height: Sp.x2),
        ESetGroup(
          gap: false,
          rows: [
            if (!changed)
              ESetRow(
                title: verified ? l.trustVerified : l.trustPaired,
                text: verified && p.verifiedAt != null ? l.contactWordsChecked(localDayMonth(l, p.verifiedAt!)) : null,
                control: EButton(
                  label: verified ? l.contactCheckAgain : l.sasTitle,
                  size: EBtnSize.sm,
                  onPressed: () => showDeskCheckWords(context, ref, p.id, recheck: verified),
                ),
              )
            else
              ESetRow(title: l.trustKeysChanged, text: l.contactKeysChangedStatus),
            ESetRow(
              title: l.contactSealPayments,
              text: changed ? l.contactPausedUntilChecked : null,
              hint: l.contactSealInfo(name),
              control: ESwitch(
                value: !changed && p.seal != SealMode.off,
                semanticLabel: l.contactSealPayments,
                onChanged: locked ? null : (v) => _run(() => deskPairingCall(ref, (api) => api.setSeal(p.id, v))),
              ),
            ),
            if (ref.watch(deskInvoicesOnProvider)) ESetRow(
              title: l.contactAllowInvoices,
              text: changed ? l.contactPausedUntilChecked : (verified ? null : l.contactCheckWordsFirst),
              hint: l.contactAllowInfoDesktop(name),
              control: ESwitch(
                value: verified && p.allowInvoices,
                semanticLabel: l.contactAllowInvoices,
                onChanged: locked || !verified
                    ? null
                    : (v) => _run(() async {
                        final declined = await deskPairingCall(ref, (api) => api.setAllowInvoices(p.id, v));
                        if (!v && mounted) {
                          showEToast(this.context, l.invSetSwitchedOff(name), text: declined > 0 ? l.invSetDeclinedCount(declined) : null, tone: ETone.info);
                        }
                      }),
              ),
            ),
            ESetRow(title: paused ? l.contactPausedEpicboxOff : l.contactDeliveredVia(p.homeRelay)),
          ],
        ),
        SizedBox(height: Sp.x3),
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            if (verified && p.caps.paysInvoices && ref.watch(deskInvoicesShownProvider))
              EButton(label: l.deskInvIssueAction, icon: EIcons.request, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.invoiceIssue, p.id)),
            EButton(
              label: l.contactRemovePairing,
              kind: EBtnKind.danger,
              size: EBtnSize.sm,
              onPressed: _busy
                  ? null
                  : () async {
                      if (await deskConfirmRemovePairing(context, name)) await _run(() => deskPairingCall(ref, (api) => api.removePairing(p.id)));
                    },
            ),
          ],
        ),
      ],
    );
  }
}
