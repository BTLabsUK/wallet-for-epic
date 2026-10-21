import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'tx_display.dart';

/// Starts Contacts with one selected, editing, adding, or empty.
class ContactsArgs {
  const ContactsArgs({this.selectedId, this.editing = false, this.adding = false, this.empty = false});

  final String? selectedId;
  final bool editing;
  final bool adding;
  final bool empty;
}

enum _Sort { name, recent }

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

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final all = _args.empty ? const <Contact>[] : ref.watch(deskProvider.select((s) => s.contacts));
    final split = MediaQuery.sizeOf(context).width >= Bp.desktop;
    final selected = all?.where((x) => x.id == _selected).firstOrNull ?? (split && !_adding && (all?.isNotEmpty ?? false) ? all!.first : null);
    final paneOpen = _adding || _editing || (selected != null && (_selected != null || split));

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
      return _ContactDetail(
        contact: selected!,
        onEdit: () => setState(() => _editing = true),
        onDeleted: () => setState(() => _selected = null),
      );
    }

    if (all == null) {
      return const EPage(title: 'Contacts', child: Padding(padding: EdgeInsets.all(Sp.x10), child: Center(child: ESpinner())));
    }
    if (all.isEmpty && !_adding) {
      return EPage(
        title: 'Contacts',
        width: EPageWidth.narrow,
        child: Container(
          decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
          child: EEmpty(
            icon: EIcons.contacts,
            title: 'No contacts yet',
            text: 'Save the people and services you pay often. Contacts stay on this computer.',
            actions: [
              EButton.primary(label: 'Add contact', icon: EIcons.userPlus, onPressed: _add),
              EButton.ghost(label: 'Send to an address', size: EBtnSize.md, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.send)),
            ],
          ),
        ),
      );
    }
    if (!split && paneOpen) {
      return EPage(
        title: _adding ? 'New contact' : (_editing ? 'Edit contact' : selected!.name),
        width: EPageWidth.narrow,
        onBack: () => setState(() {
          _adding = false;
          _editing = false;
          _selected = null;
        }),
        child: pane(),
      );
    }

    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final x in all)
        if (q.isEmpty || x.name.toLowerCase().contains(q) || x.address.toLowerCase().contains(q)) x,
    ]..sort(
        (a, b) => _sort == _Sort.name
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : (b.lastUsed ?? DateTime(2000)).compareTo(a.lastUsed ?? DateTime(2000)),
      );

    final list = Container(
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Sp.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EInput(controller: _query, hint: 'Name or address', leading: EIcons.search, onChanged: (_) => setState(() {})),
                const SizedBox(height: Sp.x3),
                Row(
                  children: [
                    Expanded(child: Text('${all.length} contacts', style: ts.small)),
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
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Sp.x5),
              child: Column(
                children: [
                  Text('No match', style: ts.bodyDim),
                  const SizedBox(height: Sp.x2),
                  EButton.ghost(label: 'Clear search', onPressed: () => setState(() => _query.clear())),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(Sp.x2),
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
      actions: [EButton.primary(label: 'Add contact', icon: EIcons.userPlus, size: EBtnSize.sm, onPressed: _add)],
      child: split
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: list),
                const SizedBox(width: Sp.x6),
                Expanded(
                  child: paneOpen
                      ? Container(
                          padding: const EdgeInsets.all(Sp.x6),
                          decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: pane()),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            )
          : list,
    );
  }
}

/// The address's kind as a tag.
(String, ETone) _kind(String address) {
  if (address.contains('.onion')) return ('Tor', ETone.neutral);
  if (address.startsWith('http')) return ('HTTP', ETone.neutral);
  return ('Epicbox', ETone.gold);
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
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
            decoration: BoxDecoration(
              color: widget.selected ? c.s3 : (_hover ? c.hover : null),
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: Row(
              children: [
                EAvatar(x.name, size: 36),
                const SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(x.name, style: ts.strong, overflow: TextOverflow.ellipsis)),
                          if (x.favourite) ...[const SizedBox(width: Sp.x1), Icon(EIcons.star, size: 14, color: c.accentText)],
                        ],
                      ),
                      Text(shortAddress(x.address), style: ts.mono(size: Fs.xs, color: c.faint), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.x2),
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
    final txs = (ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[]).where((t) => t.counterparty == x.address).take(4).toList();
    final (kind, _) = _kind(x.address);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EAvatar(x.name, size: 56),
            const SizedBox(width: Sp.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(x.name, style: ts.h2)),
                  if (x.note != null) Text(x.note!, style: ts.bodyDim),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Sp.x5),
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            EButton.primary(label: 'Send', icon: EIcons.send, size: EBtnSize.sm, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.send, x)),
            EButton(label: 'Edit', icon: EIcons.pencil, size: EBtnSize.sm, onPressed: onEdit),
            EButton(
              label: x.favourite ? 'Unstar' : 'Star',
              icon: x.favourite ? EIcons.star : EIcons.starOutline,
              size: EBtnSize.sm,
              onPressed: () => ref.read(deskProvider.notifier).saveContact(
                Contact(id: x.id, name: x.name, address: x.address, note: x.note, favourite: !x.favourite, lastUsed: x.lastUsed),
              ),
            ),
            EButton(
              label: 'Delete',
              icon: EIcons.trash,
              kind: EBtnKind.danger,
              size: EBtnSize.sm,
              onPressed: () async {
                final ok = await showDeleteContactDialog(context, x);
                if (ok == true) {
                  await ref.read(deskProvider.notifier).deleteContact(x.id);
                  onDeleted();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: Sp.x6),
        Text('$kind address', style: ts.label),
        const SizedBox(height: 6),
        EAddress(x.address),
        const SizedBox(height: Sp.x6),
        Text('Recent', style: ts.label),
        const SizedBox(height: Sp.x2),
        if (txs.isEmpty)
          Text('No transactions with this contact.', style: ts.bodyDim)
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
            child: Column(
              children: [
                for (final (i, t) in txs.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.line),
                  TxRow(tx: t, compact: true, onTap: () => ref.read(deskNavProvider.notifier).go(DeskRoute.activity, t.id)),
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
  bool _tried = false;
  bool _saving = false;

  String? get _nameError => _name.text.trim().isEmpty ? 'Enter a name' : null;
  String? get _addressError {
    final a = _address.text.trim();
    if (a.isEmpty) return 'Enter an address';
    final epicbox = RegExp(r'^[0-9A-Za-z]{40,60}(@[\w.-]+(:\d+)?)?$').hasMatch(a);
    final http = RegExp(r'^https?://').hasMatch(a);
    if (!epicbox && !http) return 'Not an Epicbox address or http(s) URL';
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_nameError != null || _addressError != null) return;
    setState(() => _saving = true);
    final id = widget.contact?.id ?? 'c${DateTime.now().microsecondsSinceEpoch}';
    await ref.read(deskProvider.notifier).saveContact(
      Contact(
        id: id,
        name: _name.text.trim(),
        address: _address.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        favourite: widget.contact?.favourite ?? false,
        lastUsed: widget.contact?.lastUsed,
      ),
    );
    if (mounted) widget.onDone(id);
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EAvatar(_name.text.isEmpty ? '?' : _name.text, size: 56),
            const SizedBox(width: Sp.x4),
            Semantics(header: true, child: Text(widget.contact == null ? 'New contact' : 'Edit contact', style: ts.h2)),
          ],
        ),
        const SizedBox(height: Sp.x6),
        EField(
          label: 'Name',
          error: _tried ? _nameError : null,
          child: EInput(controller: _name, invalid: _tried && _nameError != null, onChanged: (_) => setState(() {}), autofocus: true),
        ),
        const SizedBox(height: Sp.x5),
        EField(
          label: 'Address',
          help: 'Epicbox address, or an http(s) or .onion URL for direct sends.',
          error: _tried ? _addressError : null,
          child: EInput(controller: _address, mono: true, invalid: _tried && _addressError != null, onChanged: (_) => setState(() {})),
        ),
        const SizedBox(height: Sp.x5),
        EField(label: 'Note', optional: true, child: EInput(controller: _note, maxLines: 3)),
        const SizedBox(height: Sp.x6),
        Row(
          children: [
            EButton(label: 'Cancel', onPressed: () => widget.onDone(null)),
            const Spacer(),
            EButton.primary(label: 'Save contact', busy: _saving, onPressed: _save),
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
    description: 'The contact is removed from this computer. Transactions keep their address.',
    actions: [
      EButton(label: 'Keep', size: EBtnSize.sm, onPressed: () => Navigator.pop(context, false)),
      EButton(label: 'Delete', kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
    ],
  ),
);
