// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../connection_grace.dart' show connectionGraceProvider;
import '../../../directory/payment_refusals.dart' show paymentRefusalsProvider;
import '../../../recent_activity.dart' show recentActivityCount, showViewAll;
import '../../../recipient.dart' show RecipientKind, parseRecipient;
import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../app/tour.dart';
import '../../../l10n.dart' show AppLocalizations, localDayMonth;
import '../../widgets/kit.dart';
import '../../../models.dart' show KeysChoice, PairRequest, PairingEndReason, PairingRecord, PairingState, SealMode, contactKinds, pairingVouchesFor;
import '../../../pairing_text.dart' show pairingEndedText, peerLabel;
import '../../../ui/method_names.dart' show recipientMethodWord;
import '../../../ui/pairing/pairing_parts.dart' show NoPaymentsBadge, NoPaymentsMark, PairPendingBadge, TrustBadge;
import '../../data/directory_state.dart' show deskDirectories;
import '../../data/pairing_state.dart';
import '../pairing/directory_dialogs.dart' show DeskDirectoryBlock;
import '../pairing/add_to_contacts_button.dart' show DeskAddToContactsButton;
import '../pairing/pair_screens.dart';
import 'contact_trust_line.dart';
import 'contacts_transfer.dart';
import 'tx_display.dart';

/// Starts Contacts with one selected, editing, adding, or empty.
class ContactsArgs {
  const ContactsArgs({this.selectedId, this.editing = false, this.adding = false, this.empty = false, this.loading = false, this.address, this.name, this.fromTx});

  final String? selectedId;
  final bool editing;
  final bool adding;
  final bool empty;
  final bool loading;

  /// Adding: the address the new contact starts with (a payment's other side).
  final String? address;

  /// Adding: the name the new contact starts with (a payment link's label).
  final String? name;

  /// Adding from this payment's detail: Save or Cancel goes back to it in Activity.
  final int? fromTx;
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
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) => _page(context, box.maxWidth >= Lay.xl));

  Widget _page(BuildContext context, bool split) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final all = _args.loading ? null : (_args.empty ? const <Contact>[] : ref.watch(deskProvider.select((s) => s.contacts)));
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
          address: _adding ? _args.address : null,
          name: _adding ? _args.name : null,
          onDone: (saved) {
            if (_args.fromTx case final tx? when _adding) return ref.read(deskNavProvider.notifier).go(DeskRoute.activity, tx);
            setState(() {
              _adding = false;
              _editing = false;
              if (saved != null) _selected = saved;
            });
          },
        );
      }
      return _ContactDetail(contact: selected!, onEdit: () => setState(() => _editing = true), onDeleted: () => setState(() => _selected = null));
    }

    if (all == null) {
      // Loading keeps the page's shape (UD-020): the header button, the search (disabled),
      // three skeleton rows, and Details dimmed, so nothing jumps when the book arrives.
      Widget bone(double w, double h) => Container(width: w, height: h, decoration: BoxDecoration(color: c.s3, borderRadius: BorderRadius.circular(Rad.sm)));
      final loadingList = EPanel(
        padding: EdgeInsets.zero,
        head: Padding(
          padding: EdgeInsetsDirectional.only(end: Sp.x3),
          child: ESearch(controller: _query, enabled: false, hint: l.deskConSearchHint, label: l.deskConSearchLabel, clearLabel: l.deskConClearSearch),
        ),
        child: Semantics(
          liveRegion: true,
          label: l.deskConLoading,
          child: ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.all(Sp.x2),
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      constraints: BoxConstraints(minHeight: 64.u),
                      padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x3),
                      child: Row(
                        children: [
                          bone(40.u, 40.u),
                          SizedBox(width: 14.u),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [bone(120.u, 10.u), SizedBox(height: Sp.x2), bone(200.u, 10.u)],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      return EPage(
        title: l.deskConTitle,
        width: EPageWidth.full,
        actions: [EButton(label: l.deskConAdd, icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: null), const ContactsMoreButton()],
        child: split
            ? PanelRow(
                sideFirst: true,
                sideWidth: Ctl.sideList,
                side: loadingList,
                main: EPanel(title: l.deskConDetailsTitle, child: const Opacity(opacity: 0.5, child: _Idle())),
              )
            : loadingList,
      );
    }
    // A book this wallet has no key to yet: closed, said so, never shown as an empty one.
    if (ref.watch(deskProvider.select((s) => s.status?.contactsClosed ?? false))) {
      return EPage(
        title: l.deskConTitle,
        width: EPageWidth.narrow,
        child: Container(decoration: panel, child: const _Closed()),
      );
    }
    final orphans = ref.watch(deskPairsProvider) ? ref.watch(deskOrphanPairingsProvider) : const <PairingRecord>[];
    if (all.isEmpty && orphans.isEmpty && !_adding) {
      return EPage(
        title: l.deskConTitle,
        width: EPageWidth.narrow,
        // Import contacts fills an empty book.
        actions: [if (ref.watch(deskPairsProvider)) const DeskContactsPairButton(), const ContactsMoreButton()],
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

    // The search in the list's header band, level with the detail's.
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
          child: ESearch(
            controller: _query,
            hint: l.deskConSearchHint,
            label: l.deskConSearchLabel,
            clearLabel: l.deskConClearSearch,
            onChanged: (_) => setState(() {}),
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
          // Pairings in no contact, by the name they chose.
          for (final r in orphans)
            if (q.isEmpty || peerLabel(l, r).toLowerCase().contains(q)) _OrphanRow(key: ValueKey(r.id), record: r),
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
        // Pair in one place, labelled at every width and never gold (Pairing UX plan 4.3).
        // Requests from contacts show beside it while any wait.
        if (ref.watch(deskPairsProvider)) ...[
          if ((ref.watch(deskPairRequestsProvider).value ?? const <PairRequest>[]).isNotEmpty)
            EButton.ghost(
              key: deskContactsRequestsKey,
              label: l.pairRequestsRow((ref.watch(deskPairRequestsProvider).value ?? const <PairRequest>[]).length),
              icon: EIcons.trusted,
              onPressed: () => showDeskPairRequests(context, ref),
            ),
          const DeskContactsPairButton(),
        ],
        // Already on the new contact form: nothing more to add from here.
        compactBar
            ? EIconButton(icon: EIcons.userPlus, label: l.deskConAdd, onPressed: _adding ? null : _add)
            : EButton(label: l.deskConAdd, icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: _adding ? null : _add),
        const ContactsMoreButton(),
      ],
      child: split
          // The list and the detail are one unit: same top and bottom.
          ? PanelRow(
              sideFirst: true,
              sideWidth: Ctl.sideList,
              side: list,
              // A header band like the list's: what the pane shows.
              main: EPanel(
                    title: _adding || _editing ? null : l.deskConDetailsTitle,
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

/// The shared address book is closed to the open wallet: nothing to list, nothing to add.
class _Closed extends StatelessWidget {
  const _Closed();

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final l = context.l10n;
    return Padding(
      key: const ValueKey('contacts-closed'),
      padding: EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x10),
      child: Column(
        children: [
          ExcludeSemantics(child: Icon(EIcons.lock, size: Ctl.iconLg, color: context.dc.faint)),
          SizedBox(height: Sp.x5),
          Semantics(header: true, child: Text(l.contactsClosedTitle, style: ts.h3, textAlign: TextAlign.center)),
          SizedBox(height: Sp.x2),
          Text(l.contactsClosedText, style: ts.bodyDim, textAlign: TextAlign.center),
        ],
      ),
    );
  }
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
/// then Add to contacts (one button; a contact of its name is offered first in its menu) and a
/// ⋯ menu with Remove pairing. One under way has Cancel instead; one that ended, the menu alone.
/// The controls sit at the row's end where the row is wide enough, else on one line under the
/// words: never a stack of buttons.
class _OrphanRow extends ConsumerStatefulWidget {
  const _OrphanRow({super.key, required this.record});

  final PairingRecord record;

  @override
  ConsumerState<_OrphanRow> createState() => _OrphanRowState();
}

class _OrphanRowState extends ConsumerState<_OrphanRow> {
  /// Remove or Cancel is running: the core tells the contact first, waiting up to 10 s for
  /// the relay, and the row stays until it is done.
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
    final r = widget.record;
    final suggested = deskSuggestedContact(ref, r);
    // Still being set up: Cancel. A stored pairing, heard or not, is removed (and the other
    // wallet told); one not heard yet is not added to a contact.
    final inFlight = r.state.isPending;
    final waiting = r.state == PairingState.waiting;
    final line = r.ended
        ? pairingEndedText(l, r.endedReason ?? PairingEndReason.neverFinished, peerLabel(l, r))
        : r.state == PairingState.waiting
            ? l.pairAnsweredNotHeard
            : r.state == PairingState.pendingReply
                ? l.pairPairingWith(peerLabel(l, r))
                : l.pairNotInContacts;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: Text(peerLabel(l, r), style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
            SizedBox(width: Sp.x2),
            if (r.state.isPending) const PairPendingBadge() else TrustBadge(r, short: true),
          ],
        ),
        Text(line, style: ts.small),
      ],
    );
    final controls = [
        if (inFlight)
          EButton(
            key: deskPairingCancelKey,
            label: l.commonCancel,
            size: EBtnSize.sm,
            busy: _busy,
            onPressed: _busy
                ? null
                : () async {
                    if (await deskConfirmCancelPairing(context, peerLabel(l, r))) {
                      await _run(() => deskPairingCall(ref, (api) => api.cancelInvite(r.id)));
                    }
                  },
          )
        // Remove under way: the spinner in the ⋯'s place, so nothing is pressed twice.
        else if (_busy)
          SizedBox.square(key: deskPairingBusyKey(r.id), dimension: 20.u, child: const CircularProgressIndicator(strokeWidth: 2))
        else ...[
          if (!r.ended && !waiting) DeskAddToContactsButton(record: r, suggested: suggested),
          _ContactMoreMenu(
            buttonKey: deskPairingMoreKey(r.id),
            items: [
              (deskPairingRemoveKey, EIcons.trash, l.contactRemovePairing, true, () async {
                if (r.ended || await deskConfirmRemovePairing(context, peerLabel(l, r))) await _run(() => deskPairingCall(ref, (api) => api.removePairing(r.id)));
              }),
            ],
          ),
        ],
    ];
    return Padding(
      key: deskPairingRowKey(r.id),
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
      child: LayoutBuilder(
        builder: (context, box) {
          final beside = box.maxWidth >= Lay.md;
          return Row(
            crossAxisAlignment: beside ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              DeskPairAvatar(name: peerLabel(l, r), size: 40.u),
              SizedBox(width: 14.u),
              Expanded(
                child: beside
                    ? words
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          words,
                          SizedBox(height: Sp.x2),
                          // A long language puts the ⋯ on a second line rather than past the edge.
                          Wrap(spacing: Sp.x1, runSpacing: Sp.x1, crossAxisAlignment: WrapCrossAlignment.center, children: controls),
                        ],
                      ),
              ),
              if (beside) ...[
                SizedBox(width: Sp.x3),
                for (final (i, w) in controls.indexed) ...[if (i > 0) SizedBox(width: Sp.x1), w],
              ],
            ],
          );
        },
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
        child: EInkWell(
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
                    full: true,
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
                        // Never Verified beside an Epicbox address the pairing did not bring.
                        if (ref.watch(deskPairsProvider) ? ref.watch(deskContactPairingProvider(x.id)) : null case final p? when pairingVouchesFor(p, x.epicbox))
                          Padding(padding: EdgeInsets.only(left: Sp.x2), child: TrustBadge(p, short: true))
                        else if (ref.watch(deskPairsProvider) && ref.watch(deskContactPendingProvider(x.id)) != null)
                          Padding(padding: EdgeInsets.only(left: Sp.x2), child: const PairPendingBadge()),
                        if (ref.watch(paymentRefusalsProvider).refusesPayments(
                          pairingId: ref.watch(deskPairsProvider) ? ref.watch(deskContactPairingProvider(x.id))?.id : null,
                          address: x.epicbox,
                        ))
                          Padding(padding: EdgeInsets.only(left: Sp.x2), child: const NoPaymentsMark()),
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
    // The build without Tor sends to no onion: a contact with only one keeps it, unpayable.
    final torOnly = !DeskFeatures.tor && x.addresses.isNotEmpty && x.kinds.every((k) => k == RecipientKind.tor);
    final nav = ref.read(deskNavProvider.notifier);
    final pairs = ref.watch(deskPairsProvider);
    // Its payments: to and from its address, and through any pairing attached to it.
    final pairings = pairs ? {for (final r in ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[]) if (r.contactId == x.id) r.id} : const <String>{};
    final mine = (ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[])
        .where((t) => t.counterparty == x.address || (t.pairingId != null && pairings.contains(t.pairingId)))
        .toList();
    final last = mine.isEmpty ? x.lastUsed : mine.first.created;
    final pairing = pairs ? ref.watch(deskContactPairingProvider(x.id)) : null;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: pairing?.id, address: x.epicbox);
    // The service's entry, when the user took a name from it: shown beside the header badges.
    final service = pairing == null ? null : ref.watch(deskDirectories.directoryOfPairing(pairing.id));
    // The addresses card: last for a contact that takes no payments, else above Pairing.
    final addressesCard = <Widget>[
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
                // The kind beside the address, or above it in a narrow pane.
                child: LayoutBuilder(
                  builder: (context, box) {
                    final address = EAddress(x.addressOf(k)!, copyLabel: l.contactCopyAddress(recipientMethodWord(l, k)));
                    if (box.maxWidth < Lay.sm) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [EBadge.kind(k, l: l), SizedBox(height: Sp.x2), address]);
                    }
                    return Row(children: [EBadge.kind(k, l: l), SizedBox(width: Sp.x3), Expanded(child: address)]);
                  },
                ),
              ),
          ],
        ),
    ];
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
                      if (pairing != null && pairingVouchesFor(pairing, x.epicbox)) TrustBadge(pairing),
                      if (noPayments) const NoPaymentsBadge(),
                      if (service case final e? when e.joined && e.joinedAt != null)
                        Text(
                          l.dirJoined(e.payAsArg, x.name, MaterialLocalizations.of(context).formatMediumDate(e.joinedAt!.toLocal())),
                          style: ts.small,
                        ),
                      if (last != null) Text(l.deskConLastTx(whenText(l, last)), style: ts.small),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Sp.x5),
        // Send and Pair stay buttons; Edit, Star and Delete fold into a ⋯ menu where the pane
        // is too narrow for the row (Pairing UX plan 4.3), so the row never wraps.
        LayoutBuilder(builder: (context, box) {
          final pending = pairs ? ref.watch(deskContactPendingProvider(x.id)) : null;
          final pairLabel = !pairs || (pairing != null && !pairing.ended)
              ? null
              : pending != null
                  ? l.trustWaiting
                  : l.pairTitle;
          final fold = !_actionsFit(context, [
            l.deskConSend,
            ?pairLabel,
            l.deskConEdit,
            x.favourite ? l.deskConUnstar : l.deskConStar,
            l.deskConDelete,
          ], box.maxWidth);
          final star = EButton(
            label: x.favourite ? l.deskConUnstar : l.deskConStar,
            icon: x.favourite ? EIcons.star : EIcons.starOutline,
            size: EBtnSize.sm,
            onPressed: () => ref
                .read(deskProvider.notifier)
                .saveContact(x.copyWith(favourite: !x.favourite))
                .then<void>((_) {}, onError: (Object e) {
                  if (context.mounted) showEToast(context, deskErrorText(e, l), tone: ETone.risk);
                }),
          );
          Future<void> delete() async {
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
          }
          return Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              // A contact with no address is paid through its pairing, while it can take one.
              // The primary of a row of peers: soft gold, not a filled block (Pairing UX plan 4.2).
              if (!noPayments)
              EButton(
                key: const ValueKey('contact-send'),
                kind: EBtnKind.primarySoft,
                label: l.deskConSend,
                icon: EIcons.send,
                size: EBtnSize.sm,
                onPressed: (x.addresses.isEmpty || torOnly) && !(pairing?.paysByMailbox ?? false) ? null : () => nav.go(DeskRoute.send, x),
              ),
              // Not paired, or the pairing ended: Pair (again). Waiting opens the Pair page.
              if (pairs && (pairing == null || pairing.ended))
                pending != null
                    ? EButton(
                        key: deskContactPairKey,
                        label: l.trustWaiting,
                        busy: true,
                        size: EBtnSize.sm,
                        onPressed: () => nav.go(DeskRoute.pair, x),
                      )
                    : EButton(
                        key: deskContactPairKey,
                        label: l.pairTitle,
                        icon: EIcons.trusted,
                        tooltip: l.pairWithName(x.name),
                        size: EBtnSize.sm,
                        onPressed: () => showDeskPairWithContact(context, ref, x),
                      ),
              if (fold)
                _ContactMoreMenu(
                  items: [
                    (deskContactEditKey, EIcons.pencil, l.deskConEdit, false, onEdit),
                    (deskContactStarKey, star.icon!, star.label, false, star.onPressed!),
                    (deskContactDeleteKey, EIcons.trash, l.deskConDelete, true, delete),
                  ],
                )
              else ...[
                EButton(key: deskContactEditKey, label: l.deskConEdit, icon: EIcons.pencil, size: EBtnSize.sm, onPressed: onEdit),
                KeyedSubtree(key: deskContactStarKey, child: star),
                EButton(key: deskContactDeleteKey, label: l.deskConDelete, icon: EIcons.trash, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: delete),
              ],
            ],
          );
        }),
        // The build without Tor: an onion-only contact (older data) has no way to be paid.
        if (torOnly && !(pairing?.paysByMailbox ?? false)) ...[
          SizedBox(height: Sp.x2),
          Text(l.sendTorNotInVersion, key: const ValueKey('contact-send-no-tor'), style: ts.small),
        ],
        if (x.addresses.isEmpty && pairing != null && !pairing.paysByMailbox) ...[
          SizedBox(height: Sp.x2),
          Text(
            pairing.state == PairingState.keysChanged ? l.contactSendKeysChanged : l.contactSendNoSealed(x.name),
            key: const ValueKey('contact-send-reason'),
            style: ts.small,
          ),
        ],
        if (!noPayments) ...addressesCard,
        // A contact that takes no payments: its own card first, then Pairing, Addresses last.
        if (noPayments && pairs && pairing != null && !pairing.ended) DeskDirectoryBlock(pairingId: pairing.id, label: x.name),
        if (x.note != null) ...[SizedBox(height: Sp.x5), Text(l.deskConNote, style: ts.label), SizedBox(height: Sp.x1), Text(x.note!, style: ts.body)],
        // Pairing (RFC 0002): trust, Seal payments, Allow invoices, the relay, Remove pairing.
        if (pairs) ...[SizedBox(height: Sp.x6), DeskPairingBlock(contact: x, pairing: pairing, pending: ref.watch(deskContactPendingProvider(x.id)))],
        // The compatibility line (trust policy): one sentence, never a badge.
        if (!noPayments && pairs && pairing != null && !pairing.ended) DeskDirectoryBlock(pairingId: pairing.id, label: x.name),
        if (noPayments) ...addressesCard,
        DeskContactTrustLine(contact: x),
        SizedBox(height: Sp.x6),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(l.deskConTxWith(x.name), style: ts.label, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (showViewAll(mine.length)) ELink(label: l.deskConAllTx, onPressed: () => nav.go(DeskRoute.activity)),
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
                for (final (i, t) in mine.take(recentActivityCount).indexed) ...[
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
  const _ContactForm({required this.contact, required this.onDone, this.address, this.name});

  final Contact? contact;

  /// A new contact's first address, filled in.
  final String? address;

  /// A new contact's name, filled in.
  final String? name;

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

/// The form in the detail pane: Name, one field per address with its kind
/// badge and ×, a dashed free field while a kind is free, Note.
class _ContactFormState extends ConsumerState<_ContactForm> {
  late final _name = TextEditingController(text: widget.contact?.name ?? widget.name);
  late final List<_AddrField> _fields = [
    for (final a in _startAddresses) _AddrField(a),
    _AddrField(),
  ];

  List<String> get _startAddresses => widget.contact?.addresses ?? [?widget.address];
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
      AddressKind.http => true,
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
    if (_kindOf(f) != null) return null;
    // The build without Tor takes no new onion address.
    if (!DeskFeatures.tor) return addressKindOf(f.text.text.trim()) == AddressKind.tor ? l.sendTorNotInVersion : l.contactsAddressInvalidAnyNoTor;
    return l.deskConErrAddressInvalid;
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
  /// an address.
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
        [for (final f in _fields) if (f.text.text.trim().isNotEmpty) f.text.text.trim()].join('|') != _startAddresses.join('|');
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
        // A heading only over several fields: one field's own label says what it holds (#17).
        if (_fields.where((f) => f.text.text.trim().isNotEmpty || free.isNotEmpty).length > 1) ...[
          Text(l.contactAddresses, style: ts.label),
          SizedBox(height: Sp.x2),
        ],
        for (final f in _fields) ...[
          if (f.text.text.trim().isNotEmpty || free.isNotEmpty)
            Padding(
              key: ObjectKey(f),
              padding: EdgeInsets.only(bottom: Sp.x3),
              child: _addressField(l, c, f, free, noAddress && f == _fields.first),
            ),
        ],
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
    // An empty field is labelled by the kind it takes first ("Epicbox address", as Edit contact
    // labels a typed one); a further one's hint says it may stay empty, the first has none.
    final shownKind = kind ?? (empty && free.isNotEmpty ? free.first : null);
    final hint = empty && _fields.length > 1 && free.isNotEmpty ? l.addrDesktopThird(recipientMethodWord(l, free.first)) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EField(
          label: shownKind == null ? l.addrField : l.addrFieldTyped(recipientMethodWord(l, shownKind)),
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
        EButton(label: l.deskConKeep, onPressed: () => Navigator.pop(context, false)),
        EButton(label: l.deskConDeleteAction, icon: EIcons.trash, kind: EBtnKind.danger, onPressed: () => Navigator.pop(context, true)),
      ],
    );
  },
);

/// A contact's Pairing block, per state: Not paired with Pair; a request sent (the date,
/// Cancel, Show my invite; expired: No answer, Pair again, Remove); Waiting for the other
/// wallet (Check the words, Remove pairing); Paired with "has not checked yet" and Check the words;
/// Verified with "confirmed too"; Keys changed; Ended with its reason, the sealed sends still
/// waiting (each with Cancel) and Remove. Seal payments and Allow invoices as before; Issue an
/// invoice for a verified contact that pays requests.
class DeskPairingBlock extends ConsumerStatefulWidget {
  const DeskPairingBlock({super.key, required this.contact, required this.pairing, this.pending});

  final Contact contact;
  final PairingRecord? pairing;

  /// A request sent to the contact, or an answer to its invite waiting for the confirmation.
  final PairingRecord? pending;

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
    final q = widget.pending;
    final nav = ref.read(deskNavProvider.notifier);
    Widget titled(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Text(l.contactPairing, style: ts.label), SizedBox(height: Sp.x2), ...children],
    );
    if (p == null && q != null) {
      final expired = q.state == PairingState.pendingInvite && q.expiredAt(DateTime.now());
      return titled([
        ESetGroup(
          gap: false,
          rows: [
            ESetRow(
              key: deskContactWaitingKey,
              title: expired ? l.pairNoAnswerFrom(x.name) : l.pairWaitingFor(x.name),
              text: q.state == PairingState.pendingInvite ? l.pairRequestSent(localDayMonth(l, q.createdAt)) : l.pairPairingWith(x.name),
              control: expired
                  ? EButton(key: deskContactPairAgainKey, label: l.pairAgain, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair, x))
                  : EButton(key: deskContactShowInviteKey, label: l.pairShowMyCode, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair, x)),
            ),
          ],
        ),
        SizedBox(height: Sp.x3),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: EButton(
            key: deskContactCancelPairingKey,
            label: expired ? l.contactRemove : l.commonCancel,
            kind: EBtnKind.danger,
            size: EBtnSize.sm,
            onPressed: _busy
                ? null
                : () async {
                    if (expired || await deskConfirmCancelPairing(context, x.name)) await _run(() => deskPairingCall(ref, (api) => api.cancelInvite(q.id)));
                  },
          ),
        ),
      ]);
    }
    if (p == null) {
      return titled([
        ESetGroup(
          gap: false,
          rows: [
            ESetRow(
              title: l.pairNotPaired,
              text: l.pairNotPairedHint,
              control: EButton(label: l.pairTitle, icon: EIcons.trusted, size: EBtnSize.sm, onPressed: () => showDeskPairWithContact(context, ref, x)),
            ),
          ],
        ),
      ]);
    }
    final name = x.name;
    if (p.state == PairingState.ended) {
      final held = ref.watch(deskHeldSendsProvider(p.id));
      return titled([
        ESetGroup(
          key: deskContactEndedKey,
          gap: false,
          rows: [
            ESetRow(title: l.pairEndedShort, text: pairingEndedText(l, p.endedReason ?? PairingEndReason.neverFinished, name)),
            for (final t in held)
              ESetRow(
                key: deskContactHeldSendKey,
                title: l.pairHeldSend,
                text: t.slateId,
                control: EButton(
                  label: l.commonCancel,
                  kind: EBtnKind.danger,
                  size: EBtnSize.sm,
                  onPressed: _busy ? null : () => _run(() async => ref.read(deskProvider.notifier).cancelTx(t.id)),
                ),
              ),
          ],
        ),
        SizedBox(height: Sp.x3),
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            EButton(key: deskContactPairAgainKey, label: l.pairAgain, icon: EIcons.trusted, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair, x)),
            EButton(
              key: deskContactRemovePairingKey,
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
      ]);
    }
    final verified = p.state == PairingState.verified;
    final changed = p.state == PairingState.keysChanged;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: p.id);
    final waiting = p.state == PairingState.waiting;
    final paused = ref.watch(deskPairNetProvider) == DeskPairNet.epicboxOff;
    final locked = _busy || paused || changed || waiting;
    final back = ref.watch(deskKeysBackProvider).contains(p.id);
    final provesOther = p.paymentsAddress != null && x.epicbox != null && !pairingVouchesFor(p, x.epicbox);
    // A pairing made before addresses were proven: nothing confirms the contact's address.
    final unproven = (verified || p.state == PairingState.paired) && p.paymentsAddress == null;
    final statusTitle = changed ? l.trustKeysChanged : waiting ? l.pairWaitingFor(name) : verified ? l.trustVerified : l.trustPaired;
    final statusLine = changed
        ? l.contactKeysChangedStatus
        : waiting
            ? l.pairAnsweredNotHeard
            : (verified && p.peerVerifiedAt != null)
                ? l.pairConfirmedToo(name)
                : l.pairNotChecked(name);
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
              EButton.primary(label: l.pairCheckWords, size: EBtnSize.sm, onPressed: () => showDeskCheckWords(context, ref, p.id, recheck: true)),
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
            actions: [EButton(label: l.commonOk, onPressed: () => ref.read(deskKeysBackProvider.notifier).close(p.id))],
          ),
          SizedBox(height: Sp.x4),
        ],
        if (p.relayDown && !paused && !ref.watch(connectionGraceProvider)) ...[
          ENotice(title: l.contactRelayDownTitle(name), text: l.contactRelayDownBody, tone: ETone.warn),
          SizedBox(height: Sp.x4),
        ],
        // The check after a long gap got no answer: Pair again, until the contact is heard.
        if (p.notAnswering && !paused && !changed) ...[
          ENotice(
            key: deskContactNotAnsweringKey,
            title: l.trustNotAnswering,
            text: l.contactNotAnsweringBody,
            tone: ETone.warn,
            actions: [EButton.primary(key: deskContactPairAgainKey, label: l.pairAgain, icon: EIcons.trusted, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair, x))],
          ),
          SizedBox(height: Sp.x4),
        ],
        // A later card proved another address than the contact's: the user decides.
        if (provesOther) ...[
          ENotice(
            title: l.pairProvesOther(name),
            text: p.paymentsAddress,
            tone: ETone.warn,
            actionsBelow: true,
            actions: [
              EButton.primary(
                key: deskContactUpdateAddressKey,
                label: l.pairUpdateAddress,
                size: EBtnSize.sm,
                onPressed: () => _run(() async {
                  await ref.read(deskProvider.notifier).saveContact(
                    Contact(id: x.id, name: x.name, epicbox: p.paymentsAddress, http: x.http, tor: x.tor, note: x.note, favourite: x.favourite, lastUsed: x.lastUsed, hasPicture: x.hasPicture),
                  );
                }),
              ),
              EButton(key: deskContactDetachKey, label: l.pairDetach, size: EBtnSize.sm, onPressed: () => _run(() => deskPairingCall(ref, (api) => api.attach(p.id, null)))),
            ],
          ),
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
            ESetRow(
              title: statusTitle,
              text: verified && p.verifiedAt != null ? metaLine([l.contactWordsChecked(localDayMonth(l, p.verifiedAt!)), statusLine]) : statusLine,
              control: !changed && p.sas.isNotEmpty && (waiting || p.state == PairingState.paired)
                  ? EButton(key: deskContactCheckKey, label: l.pairCheckWords, size: EBtnSize.sm, onPressed: () => showDeskCheckWords(context, ref, p.id, recheck: !waiting))
                  : null,
            ),
            // A contact that takes no payments has nothing to seal or invoice.
            if (!noPayments)
            ESetRow(
              title: l.contactSealPayments,
              text: changed ? l.contactPausedUntilChecked : (waiting ? l.pairWaitingFor(name) : null),
              hint: l.contactSealInfo(name),
              control: ESwitch(
                value: !changed && !waiting && p.seal != SealMode.off,
                semanticLabel: l.contactSealPayments,
                onChanged: locked ? null : (v) => _run(() => deskPairingCall(ref, (api) => api.setSeal(p.id, v))),
              ),
            ),
            if (!noPayments && ref.watch(deskInvoicesOnProvider))
              ESetRow(
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
            if (unproven)
              ESetRow(
                key: deskContactUnprovenKey,
                title: l.pairAddressNotConfirmed,
                control: EButton(
                  key: deskContactPairAgainUnprovenKey,
                  label: l.pairAgain,
                  icon: EIcons.trusted,
                  size: EBtnSize.sm,
                  onPressed: _busy ? null : () => showDeskPairWithContact(context, ref, x),
                ),
              ),
          ],
        ),
        SizedBox(height: Sp.x3),
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            if (verified && p.caps.paysInvoices && ref.watch(deskInvoicesShownProvider))
              EButton(label: l.deskInvIssueAction, icon: EIcons.request, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.invoiceIssue, p.id)),
            if (waiting) EButton(key: deskContactShowInviteKey, label: l.pairShowMyCode, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair, x)),
            EButton(
              key: deskContactRemovePairingKey,
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

/// Keys of the Pairing block, for tests.
const Key deskContactWaitingKey = ValueKey('desk-contact-waiting');
const Key deskContactEndedKey = ValueKey('desk-contact-ended');
const Key deskContactHeldSendKey = ValueKey('desk-contact-held-send');
const Key deskContactCheckKey = ValueKey('desk-contact-check');
const Key deskContactCancelPairingKey = ValueKey('desk-contact-cancel-pairing');
const Key deskContactRemovePairingKey = ValueKey('desk-contact-remove-pairing');
const Key deskContactShowInviteKey = ValueKey('desk-contact-show-invite');
const Key deskContactNotAnsweringKey = ValueKey('desk-contact-not-answering');
const Key deskContactPairAgainKey = ValueKey('desk-contact-pair-again');
const Key deskContactUnprovenKey = ValueKey('desk-contact-unproven');
const Key deskContactPairAgainUnprovenKey = ValueKey('desk-contact-pair-again-unproven');
const Key deskContactUpdateAddressKey = ValueKey('desk-contact-update-address');
const Key deskContactDetachKey = ValueKey('desk-contact-detach');

/// The Contacts header's Pair (secondary, glyph and label), and its key.
const Key deskContactsPairKey = ValueKey('desk-contacts-pair');
const Key deskContactsRequestsKey = ValueKey('desk-contacts-requests');
const Key deskContactPairKey = ValueKey('desk-contact-pair');
Key deskPairingRowKey(String id) => ValueKey('desk-pairing-row-$id');
const Key deskPairingCancelKey = ValueKey('desk-pairing-cancel');
Key deskPairingMoreKey(String id) => ValueKey('desk-pairing-more-$id');
const Key deskPairingRemoveKey = ValueKey('desk-pairing-remove');
Key deskPairingBusyKey(String id) => ValueKey('desk-pairing-busy-$id');
const Key deskContactMoreKey = ValueKey('desk-contact-more');
const Key deskContactEditKey = ValueKey('desk-contact-edit');
const Key deskContactStarKey = ValueKey('desk-contact-star');
const Key deskContactDeleteKey = ValueKey('desk-contact-delete');

/// Whether the header's buttons ([labels], each an icon and a word at [EBtnSize.sm]) share one
/// line of [width]: measured as [EButton] lays them out, so German and Russian fold where
/// English still fits.
bool _actionsFit(BuildContext context, List<String> labels, double width) {
  // The button's text style, merged as its Text merges it; the face is 1 px of border each side.
  final style = DefaultTextStyle.of(context).style.merge(TextStyle(fontSize: Fs.sm, fontWeight: FontWeight.w600, height: 1.2));
  final scaler = MediaQuery.textScalerOf(context);
  var need = Sp.x2 * (labels.length - 1);
  for (final label in labels) {
    final p = TextPainter(text: TextSpan(text: label, style: style), textDirection: TextDirection.ltr, textScaler: scaler, maxLines: 1)..layout();
    need += 2 + Sp.x3 * 2 + 18.u + Sp.x2 + p.width;
  }
  return need <= width;
}

/// The contact header's ⋯ menu: Edit, Star or Unstar, Delete (in risk ink). A pairing row's
/// holds Remove pairing, under its own [buttonKey].
class _ContactMoreMenu extends StatelessWidget {
  const _ContactMoreMenu({required this.items, this.buttonKey = deskContactMoreKey});

  final List<(Key, IconData, String, bool, VoidCallback)> items;
  final Key buttonKey;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return MenuAnchor(
      consumeOutsideTap: true,
      menuChildren: [
        for (final (key, icon, label, risk, run) in items)
          MenuItemButton(
            key: key,
            onPressed: run,
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(200.u, 40.u)),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.u))),
              backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) ? c.s3 : null),
            ),
            leadingIcon: Icon(icon, size: Ctl.iconSm, color: risk ? c.risk : c.dim),
            child: Text(label, style: risk ? ts.body.copyWith(color: c.risk) : ts.body),
          ),
      ],
      builder: (context, controller, _) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): controller.close},
        child: EIconButton(
          key: buttonKey,
          icon: EIcons.dots,
          label: l.contactMore,
          size: EBtnSize.sm,
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}
const Key deskPairHintKey = ValueKey('desk-pair-hint');
const Key deskPairLearnKey = ValueKey('desk-pair-learn');

/// Pair in the Contacts header.
class DeskContactsPairButton extends ConsumerWidget {
  const DeskContactsPairButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return EButton(key: deskContactsPairKey, label: l.pairTitle, icon: EIcons.trusted, size: EBtnSize.sm, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.pair));
  }
}
