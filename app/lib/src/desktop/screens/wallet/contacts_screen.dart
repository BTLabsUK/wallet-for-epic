import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../app/tour.dart';
import '../../widgets/kit.dart';
import '../invoices/invoice_address.dart' show copyInvoiceAddress;
import '../invoices/invoice_parts.dart';
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
        title: 'Contacts',
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
                Text('Loading contacts', style: ts.bodyDim),
              ],
            ),
          ),
        ),
      );
    }
    if (all.isEmpty && !_adding) {
      return EPage(
        title: 'Contacts',
        width: EPageWidth.narrow,
        child: Container(
          decoration: panel,
          child: _Empty(onAdd: _add),
        ),
      );
    }
    if (!split && paneOpen) {
      return EPage(title: _adding ? 'New contact' : (_editing ? 'Edit contact' : selected!.name), width: EPageWidth.narrow, onBack: _back, child: pane());
    }

    final q = _query.text.trim().toLowerCase();
    final shown =
        [
          for (final x in all)
            if (q.isEmpty || x.name.toLowerCase().contains(q) || x.address.toLowerCase().contains(q)) x,
        ]..sort(
          (a, b) => _sort == _Sort.name
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : (b.lastUsed ?? DateTime(2000)).compareTo(a.lastUsed ?? DateTime(2000)),
        );
    final long = all.length > _longList;
    final count = q.isEmpty ? '${all.length} contacts' : (shown.isEmpty ? 'No matches' : (shown.length == 1 ? '1 match' : '${shown.length} matches'));

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
            hint: 'Name or address',
            leading: EIcons.search,
            semanticLabel: 'Search contacts',
            onChanged: (_) => setState(() {}),
            trailing: _query.text.isEmpty
                ? null
                : EIconButton(icon: EIcons.close, label: 'Clear search', size: EBtnSize.inline, onPressed: () => setState(_query.clear)),
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
                        segments: const [ESegment(_Sort.name, 'Name'), ESegment(_Sort.recent, 'Recent')],
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
          if (shown.isEmpty && _query.text.isEmpty)
            Padding(
              padding: EdgeInsets.all(Sp.x5),
              child: Text('No contacts yet.', style: ts.bodyDim, textAlign: TextAlign.center),
            )
          else if (shown.isEmpty)
            Padding(
              padding: EdgeInsets.all(Sp.x5),
              child: Column(
                children: [
                  Text('No contacts match', style: ts.bodyDim),
                  SizedBox(height: Sp.x2),
                  EButton.ghost(label: 'Clear search', onPressed: () => setState(_query.clear)),
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

    return EPage(
      title: 'Contacts',
      width: EPageWidth.full,
      actions: [
        if (_adding || _editing)
          EButton.ghost(label: 'Add contact', icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: _add)
        else
          EButton.primary(label: 'Add contact', icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: _add),
      ],
      child: split
          // The list and the detail are one unit (docs/plans/w7-layout.md R1): same top and bottom.
          ? PanelRow(
              sideFirst: true,
              sideWidth: Ctl.sideList,
              side: list,
              // A header band like the list's: what the pane shows.
              main: EPanel(
                    title: _adding ? 'New contact' : (_editing ? 'Edit contact' : 'Details'),
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
        Text('Choose a contact to see their details, send to them, edit or delete them.', style: context.ts.bodyDim, textAlign: TextAlign.center),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Sp.x6, vertical: Sp.x10),
      child: Column(
        children: [
          ExcludeSemantics(child: Icon(EIcons.contacts, size: Ctl.iconLg, color: c.faint)),
          SizedBox(height: Sp.x5),
          Semantics(
            header: true,
            child: Text('No contacts yet', style: ts.h3, textAlign: TextAlign.center),
          ),
          SizedBox(height: Sp.x2),
          Text('Save the people and shops paid often. On Send, pick a name instead of pasting an address.', style: ts.bodyDim, textAlign: TextAlign.center),
          SizedBox(height: Sp.x2),
          Text(
            'Contacts stay on this computer. They are not part of the recovery phrase.',
            style: ts.small.copyWith(color: c.faint),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Sp.x5),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              EButton.primary(label: 'Add contact', icon: EIcons.userPlus, onPressed: onAdd),
              EButton.ghost(label: 'Send to address', size: EBtnSize.md, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.send)),
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

class _ContactRow extends StatefulWidget {
  const _ContactRow({required this.contact, required this.selected, required this.onTap, required this.onDouble});

  final Contact contact;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDouble;

  @override
  State<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<_ContactRow> {
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
                    note: x.note,
                    nameTrailing: x.favourite
                        ? Padding(
                            padding: EdgeInsets.only(left: Sp.x1),
                            child: Icon(EIcons.star, size: 14.u, color: c.accentText),
                          )
                        : null,
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
    final x = contact;
    final nav = ref.read(deskNavProvider.notifier);
    final mine = (ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[]).where((t) => t.counterparty == x.address).toList();
    final last = mine.isEmpty ? x.lastUsed : mine.first.created;
    final kind = switch (addressKindOf(x.address)) {
      AddressKind.tor => 'Tor',
      AddressKind.http => 'HTTP',
      _ => 'Epicbox',
    };
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
                  if (last != null) Text('Last transaction: ${whenText(last)}', style: ts.small),
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
            EButton.primary(label: 'Send', icon: EIcons.send, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.send, x)),
            EButton(label: 'Edit', icon: EIcons.pencil, size: EBtnSize.sm, onPressed: onEdit),
            EButton(
              label: x.favourite ? 'Unstar' : 'Star',
              icon: x.favourite ? EIcons.star : EIcons.starOutline,
              size: EBtnSize.sm,
              onPressed: () => ref
                  .read(deskProvider.notifier)
                  .saveContact(
                    Contact(id: x.id, name: x.name, address: x.address, note: x.note, favourite: !x.favourite, lastUsed: x.lastUsed, hasPicture: x.hasPicture, invoiceAddress: x.invoiceAddress),
                  )
                  .then<void>((_) {}, onError: (Object e) {
                    if (context.mounted) showEToast(context, deskErrorText(e));
                  }),
            ),
            EButton(
              label: 'Delete',
              icon: EIcons.trash,
              kind: EBtnKind.danger,
              size: EBtnSize.sm,
              onPressed: () async {
                final ok = await showDeleteContactDialog(context, x);
                if (ok != true || !context.mounted) return;
                final stopTrust = await _askStopTrusting(context, ref, x);
                try {
                  await ref.read(deskProvider.notifier).deleteContact(x.id);
                  if (stopTrust != null) await ref.read(deskInvoicesProvider.notifier).untrust(stopTrust.address);
                } on Object catch (e) {
                  if (context.mounted) showEToast(context, 'Not deleted', text: deskErrorText(e), tone: ETone.risk);
                  return;
                }
                if (context.mounted) showEToast(context, '${x.name} was deleted');
                onDeleted();
              },
            ),
          ],
        ),
        SizedBox(height: Sp.x6),
        Text('$kind address', style: ts.label),
        SizedBox(height: 6.u),
        EAddress(x.address),
        if (x.note != null) ...[SizedBox(height: Sp.x5), Text('Note', style: ts.label), SizedBox(height: Sp.x1), Text(x.note!, style: ts.body)],
        // Invoices (docs/invoices/flow.md §7): their invoice address, trust, request, share.
        if (ref.watch(deskApiProvider).supportsInvoices) ...[SizedBox(height: Sp.x6), _ContactInvoices(contact: x)],
        SizedBox(height: Sp.x6),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Transactions with ${x.name}', style: ts.label, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (mine.isNotEmpty) ELink(label: 'All transactions', onPressed: () => nav.go(DeskRoute.activity)),
          ],
        ),
        SizedBox(height: Sp.x2),
        if (mine.isEmpty)
          Text('No transactions with this contact yet. Payments sent to them from Send appear here.', style: ts.bodyDim)
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
                  TxRow(tx: t, compact: true, title: t.incoming ? 'Received' : 'Sent', onTap: () => nav.go(DeskRoute.activity, t.id)),
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

class _ContactFormState extends ConsumerState<_ContactForm> {
  late final _name = TextEditingController(text: widget.contact?.name);
  late final _address = TextEditingController(text: widget.contact?.address);
  late final _note = TextEditingController(text: widget.contact?.note);
  late final _invoice = TextEditingController(text: widget.contact?.invoiceAddress);
  late bool _picture = widget.contact?.hasPicture ?? false;
  final _nameFocus = FocusNode();
  final _addressFocus = FocusNode();

  /// Fields left with something in them: their errors show from then on.
  final Set<String> _touched = {};
  bool _tried = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    void watch(FocusNode f, String key, TextEditingController ctl) => f.addListener(() {
      if (!f.hasFocus && ctl.text.trim().isNotEmpty) setState(() => _touched.add(key));
    });
    watch(_nameFocus, 'name', _name);
    watch(_addressFocus, 'address', _address);
  }

  String? get _nameError => _name.text.trim().isEmpty ? 'Give the contact a name.' : null;
  /// One error for every form that is not an address: "Not a recognised address" (spec 7).
  String? get _addressError {
    final a = _address.text.trim();
    if (a.isEmpty) return 'Add an address.';
    final p = parseAddress(a, ref.read(deskApiProvider));
    final allowed = switch (p.kind) {
      AddressKind.tor => DeskFeatures.tor,
      AddressKind.http => DeskFeatures.httpDirect || DeskFeatures.tor,
      AddressKind.epicbox => true,
      AddressKind.none => false,
    };
    return allowed && p.complete ? null : 'Not a recognised address';
  }

  String? _shown(String key, String? error) => _tried || _touched.contains(key) ? error : null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    _invoice.dispose();
    _nameFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  /// Their invoice address, when given: an Epicbox address, not this contact's payments one.
  String? get _invoiceError {
    final t = _invoice.text.trim();
    if (t.isEmpty) return null;
    final p = parseAddress(t, ref.read(deskApiProvider));
    return p.kind == AddressKind.epicbox && p.complete ? null : context.l10n.deskInvIssuerPayerInvalid;
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_nameError != null) return _nameFocus.requestFocus();
    if (_addressError != null) return _addressFocus.requestFocus();
    if (_invoiceError != null) return;
    // The address was checked as text above; saving only stores it and never reaches out.
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
              address: parseAddress(_address.text, ref.read(deskApiProvider)).canonical,
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              favourite: widget.contact?.favourite ?? false,
              lastUsed: widget.contact?.lastUsed,
              hasPicture: _picture,
              invoiceAddress: _invoice.text.trim().isEmpty ? null : _invoice.text.trim(),
            ),
          );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = deskErrorText(e);
        });
      }
      return;
    }
    // A trusted contact renamed: its invoices carry the new name (flow.md §7).
    final address = parseAddress(_address.text, ref.read(deskApiProvider)).canonical;
    final invoice = _invoice.text.trim().isEmpty ? null : _invoice.text.trim();
    final trusted = trustedOf(ref.read(deskInvoicesProvider), address, invoice);
    if (trusted != null && trusted.label != _name.text.trim()) {
      await ref.read(deskInvoicesProvider.notifier).trust(trusted.address, _name.text.trim(), contactId: id);
    }
    if (mounted) widget.onDone(id);
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final nameError = _shown('name', _nameError);
    final addressError = _shown('address', _addressError);
    // Enter: Name → Address, then Save (the Note keeps Enter for a new line).
    // A form with typed changes holds Back (mouse, Alt+Left).
    final dirty = _name.text != (widget.contact?.name ?? '') || _address.text != (widget.contact?.address ?? '') || _note.text != (widget.contact?.note ?? '');
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
                  Semantics(header: true, child: Text(widget.contact == null ? 'New contact' : 'Edit contact', style: ts.h2)),
                  if (DeskFeatures.contactPictures) ...[
                  SizedBox(height: Sp.x2),
                  Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x1,
                    children: [
                      EButton(
                        label: _picture ? 'Change picture' : 'Add picture',
                        icon: EIcons.camera,
                        kind: EBtnKind.ghost,
                        size: EBtnSize.inline,
                        tabStop: false,
                        onPressed: () => setState(() => _picture = true),
                      ),
                      if (_picture) EButton(label: 'Remove', icon: EIcons.trash, kind: EBtnKind.ghost, size: EBtnSize.inline, tabStop: false, onPressed: () => setState(() => _picture = false)),
                    ],
                  ),
                  SizedBox(height: Sp.x1),
                  Text('PNG, JPEG, WebP or GIF, up to 10 MB. A small copy is kept in this app.', style: ts.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Sp.x6),
        EField(
          label: 'Name',
          error: nameError,
          child: EInput(controller: _name, focusNode: _nameFocus, invalid: nameError != null, onChanged: (_) => setState(() {}), autofocus: true),
        ),
        SizedBox(height: Sp.x5),
        EField(
          label: 'Address',
          error: addressError,
          child: EInput(controller: _address, focusNode: _addressFocus, mono: true, invalid: addressError != null, onChanged: (_) => setState(() {})),
        ),
        if (ref.watch(deskApiProvider).supportsInvoices) ...[
          SizedBox(height: Sp.x5),
          EField(
            // No Optional tag: at 560 px and 150 % the label row has no room for it.
            label: context.l10n.deskInvSetAddressLabel,
            help: context.l10n.deskInvIssuerPayerHelp,
            error: _tried ? _invoiceError : null,
            child: EInput(controller: _invoice, mono: true, invalid: _tried && _invoiceError != null, onChanged: (_) => setState(() {})),
          ),
        ],
        SizedBox(height: Sp.x5),
        EField(
          label: 'Note',
          optional: true,
          child: EInput(controller: _note, maxLines: 3),
        ),
        SizedBox(height: Sp.x6),
        if (_saveError != null) ...[
          ENotice(title: 'Contact not saved', text: _saveError, tone: ETone.risk),
          SizedBox(height: Sp.x4),
        ],
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            EButton(label: 'Cancel', tabStop: false, onPressed: () => widget.onDone(null)),
            EButton.primary(label: 'Save contact', icon: EIcons.check, busy: _saving, onPressed: _save),
          ],
        ),
      ],
    ),
    ),
    );
  }
}

/// The trusted entry of a contact, by key: their invoice address when given, else the
/// payments address. LEPIC's list is the only copy.
TrustedSender? trustedOf(InvoiceBook? book, String address, String? invoiceAddress) {
  if (book == null) return null;
  return (invoiceAddress == null ? null : book.trustedFor(invoiceAddress)) ?? book.trustedFor(address);
}

/// For a trusted contact about to be deleted: asks whether to stop trusting it. Returns the
/// entry to remove, or null when the contact is not trusted or the user keeps it trusted.
Future<TrustedSender?> _askStopTrusting(BuildContext context, WidgetRef ref, Contact x) async {
  final t = trustedOf(ref.read(deskInvoicesProvider), x.address, x.invoiceAddress);
  if (t == null) return null;
  final l = context.l10n;
  final stop = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: l.deskInvSetRemoveTitle(t.label),
      description: l.deskInvSetRemoveBody(t.label),
      icon: EIcons.trusted,
      actions: [
        InvButton(label: l.deskInvSetKeep, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(false)),
        InvButton(label: l.deskInvSetRemove, kind: EBtnKind.danger, width: InvW.md, onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    ),
  );
  return stop == true ? t : null;
}

/// Asks before deleting a contact.
Future<bool?> showDeleteContactDialog(BuildContext context, Contact x) => showEDialog<bool>(
  context,
  builder: (context) => EDialog(
    title: 'Delete ${x.name}?',
    icon: EIcons.trash,
    tone: ETone.risk,
    description: 'The contact’s address and note are removed from this wallet. Past transactions stay in Activity. This cannot be undone.',
    actions: [
      EButton(label: 'Keep contact', size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
      EButton(label: 'Delete contact', icon: EIcons.trash, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
    ],
  ),
);

/// A contact's invoices: their invoice address, whether they may bill this wallet, and the two
/// actions (docs/invoices/flow.md §7).
class _ContactInvoices extends ConsumerWidget {
  const _ContactInvoices({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final x = contact;
    final book = ref.watch(deskInvoicesProvider);
    if (book == null) return const SizedBox.shrink();
    final entry = trustedOf(book, x.address, x.invoiceAddress);
    final trusted = entry != null;
    final epicbox = addressKindOf(x.address) == AddressKind.epicbox;
    final n = ref.read(deskInvoicesProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.deskInvSetContactSection, style: ts.label),
        SizedBox(height: Sp.x2),
        ESetGroup(
          rows: [
            ESetRow(
              title: l.deskInvSetTheirInvoice,
              text: x.invoiceAddress == null ? l.deskInvSetTheirInvoiceNone : null,
              below: x.invoiceAddress == null ? null : EAddress(x.invoiceAddress!),
            ),
            if (epicbox)
              ESetRow(
                title: l.deskInvSetTrustedSwitch,
                text: l.deskInvSetTrustedSwitchHelp,
                control: ESwitch(
                  value: trusted,
                  semanticLabel: l.deskInvSetTrustedSwitch,
                  onChanged: (v) => v ? n.trust(x.invoiceAddress ?? x.address, x.name, contactId: x.id) : n.untrust(entry?.address ?? x.address),
                ),
              ),
          ],
        ),
        SizedBox(height: Sp.x3),
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InvButton(
              label: l.deskInvIssueAction,
              icon: EIcons.request,
              width: InvW.lg,
              tooltip: x.invoiceAddress == null ? l.deskInvSetIssueNeeds : null,
              onPressed: x.invoiceAddress == null ? null : () => ref.read(deskNavProvider.notifier).go(DeskRoute.invoiceIssue, x),
            ),
            InvButton(label: l.deskInvSetShare, icon: EIcons.invoiceAddress, width: InvW.lg, onPressed: () => copyInvoiceAddress(context, book.invoiceAddress)),
            if (x.invoiceAddress == null) Text(l.deskInvSetIssueNeeds, style: ts.small),
          ],
        ),
      ],
    );
  }
}
