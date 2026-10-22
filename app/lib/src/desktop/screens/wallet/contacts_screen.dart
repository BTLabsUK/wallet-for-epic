import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/http_address.dart';
import '../../widgets/kit.dart';
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

    final list = Container(
      decoration: panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(Sp.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): () {
                      if (_query.text.isNotEmpty) setState(_query.clear);
                    },
                  },
                  child: EInput(
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
                if (long) ...[
                  SizedBox(height: Sp.x3),
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
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          if (shown.isEmpty)
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
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340.u, child: list),
                SizedBox(width: Sp.x6),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(Sp.x6),
                    decoration: panel,
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
                ),
              ],
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

/// The address's kind as a tag.
(String, ETone) _kind(String address) {
  if (address.contains('.onion')) return ('Tor', ETone.neutral);
  if (address.startsWith('http')) return ('HTTP', ETone.neutral);
  return ('Epicbox', ETone.gold);
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
    final ts = context.ts;
    final x = widget.contact;
    final (kind, tone) = _kind(x.address);
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
            constraints: BoxConstraints(minHeight: 56.u),
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
            decoration: BoxDecoration(color: widget.selected ? c.s3 : (_hover ? c.hover : null), borderRadius: BorderRadius.circular(Rad.sm)),
            child: Row(
              children: [
                _Pic(name: x.name, picture: x.hasPicture, size: 36.u),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(x.name, style: ts.strong, overflow: TextOverflow.ellipsis),
                          ),
                          if (x.favourite) ...[SizedBox(width: Sp.x1), Icon(EIcons.star, size: 14.u, color: c.accentText)],
                        ],
                      ),
                      Text(
                        shortAddress(x.address),
                        style: ts.mono(size: Fs.xs, color: c.faint),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Sp.x2),
                ETag(kind, tone: tone),
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
    final (kind, _) = _kind(x.address);
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
                    Contact(id: x.id, name: x.name, address: x.address, note: x.note, favourite: !x.favourite, lastUsed: x.lastUsed, hasPicture: x.hasPicture),
                  ),
            ),
            EButton(
              label: 'Delete',
              icon: EIcons.trash,
              kind: EBtnKind.danger,
              size: EBtnSize.sm,
              onPressed: () async {
                final ok = await showDeleteContactDialog(context, x);
                if (ok != true) return;
                await ref.read(deskProvider.notifier).deleteContact(x.id);
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
  late bool _picture = widget.contact?.hasPicture ?? false;
  final _nameFocus = FocusNode();
  final _addressFocus = FocusNode();

  /// Fields left with something in them: their errors show from then on.
  final Set<String> _touched = {};
  bool _tried = false;
  bool _saving = false;

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
  String? get _addressError {
    final a = _address.text.trim();
    final epicboxOnly = !DeskFeatures.httpDirect && !DeskFeatures.tor;
    if (a.isEmpty) return epicboxOnly ? 'Add an Epicbox address to send to.' : 'Add an Epicbox or an HTTP address to send to.';
    if (epicboxOnly && (RegExp(r'^https?:', caseSensitive: false).hasMatch(a) || a.toLowerCase().contains('.onion'))) {
      return 'Enter an Epicbox address.';
    }
    if (RegExp(r'^https?:', caseSensitive: false).hasMatch(a)) {
      final problem = httpAddressProblem(a);
      return problem == null ? null : 'This is not an HTTP address: ${problem[0].toLowerCase()}${problem.substring(1)}.';
    }
    final epicbox = RegExp(r'^es[0-9A-Za-z]{38,58}(@[\w.-]+(:\d+)?)?$').hasMatch(a);
    return epicbox ? null : 'This is not a complete Epicbox address. Copy it again from the recipient’s Receive page.';
  }

  String? _shown(String key, String? error) => _tried || _touched.contains(key) ? error : null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    _nameFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_nameError != null) return _nameFocus.requestFocus();
    if (_addressError != null) return _addressFocus.requestFocus();
    setState(() => _saving = true);
    final id = widget.contact?.id ?? 'c${DateTime.now().microsecondsSinceEpoch}';
    await ref
        .read(deskProvider.notifier)
        .saveContact(
          Contact(
            id: id,
            name: _name.text.trim(),
            address: _address.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            favourite: widget.contact?.favourite ?? false,
            lastUsed: widget.contact?.lastUsed,
            hasPicture: _picture,
          ),
        );
    if (mounted) widget.onDone(id);
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final nameError = _shown('name', _nameError);
    final addressError = _shown('address', _addressError);
    return Column(
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
                        onPressed: () => setState(() => _picture = true),
                      ),
                      if (_picture) EButton(label: 'Remove', kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => setState(() => _picture = false)),
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
          help: DeskFeatures.httpDirect || DeskFeatures.tor
              ? 'Epicbox: starts with “es”, then @ and the server, e.g. @epicbox.epiccash.com. Or an ${DeskFeatures.tor ? 'http(s) or .onion' : 'http(s)'} address.'
              : 'Starts with “es”, then @ and the server, e.g. @epicbox.epiccash.com.',
          error: addressError,
          child: EInput(controller: _address, focusNode: _addressFocus, mono: true, invalid: addressError != null, onChanged: (_) => setState(() {})),
        ),
        SizedBox(height: Sp.x5),
        EField(
          label: 'Note',
          optional: true,
          child: EInput(controller: _note, maxLines: 3),
        ),
        SizedBox(height: Sp.x6),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            EButton(label: 'Cancel', onPressed: () => widget.onDone(null)),
            EButton.primary(label: 'Save contact', icon: EIcons.check, busy: _saving, onPressed: _save),
          ],
        ),
      ],
    );
  }
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
