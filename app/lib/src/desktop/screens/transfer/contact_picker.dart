import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// The way a contact's address is sent to.
TxMethod contactMethod(Contact c) {
  final a = c.address.toLowerCase();
  if (a.contains('.onion')) return TxMethod.tor;
  if (a.startsWith('http')) return TxMethod.http;
  return TxMethod.epicbox;
}

String shortAddress(String a) => a.length > 28 ? '${a.substring(0, 12)}…${a.substring(a.length - 14)}' : a;

/// Opens the contact picker over the current page; resolves to the chosen contact or null.
Future<Contact?> showContactPicker(BuildContext context) =>
    showEDialog<Contact>(context, builder: (_) => const ContactPickerDialog());

/// For the screenshot tour: the picker, result ignored.
Future<void> showContactPickerDialog(BuildContext context) => showContactPicker(context);

class ContactPickerDialog extends ConsumerStatefulWidget {
  const ContactPickerDialog({super.key, this.query = ''});

  final String query;

  @override
  ConsumerState<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends ConsumerState<ContactPickerDialog> {
  late final TextEditingController _q = TextEditingController(text: widget.query);

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final contacts = ref.watch(deskProvider.select((s) => s.contacts));
    final q = _q.text.trim().toLowerCase();
    final shown = contacts == null
        ? const <Contact>[]
        : ([...contacts]
            .where((x) => q.isEmpty || x.name.toLowerCase().contains(q) || x.address.toLowerCase().contains(q))
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
    final Widget list;
    if (contacts == null) {
      list = const Padding(padding: EdgeInsets.all(Sp.x6), child: Center(child: ESpinner(size: 20)));
    } else if (contacts.isEmpty) {
      list = const EEmpty(icon: EIcons.contacts, title: 'No contacts', text: 'Saved contacts are listed here.');
    } else if (shown.isEmpty) {
      list = Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.x6),
        child: Center(child: Text('No contact matches "${_q.text.trim()}".', style: ts.small)),
      );
    } else {
      list = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: shown.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
          itemBuilder: (_, i) => _PickRow(contact: shown[i], onTap: () => Navigator.of(context).pop(shown[i])),
        ),
      );
    }
    return EDialog(
      title: 'Choose contact',
      description: 'The address fills the recipient field.',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contacts != null && contacts.isNotEmpty) ...[
            EInput(
              controller: _q,
              hint: 'Search contacts',
              leading: EIcons.search,
              autofocus: true,
              semanticLabel: 'Search contacts',
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (shown.isNotEmpty) Navigator.of(context).pop(shown.first);
              },
            ),
            const SizedBox(height: Sp.x3),
          ],
          list,
        ],
      ),
      actions: [
        EButton(label: 'Cancel', kind: EBtnKind.ghost, size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

class _PickRow extends StatefulWidget {
  const _PickRow({required this.contact, required this.onTap});

  final Contact contact;
  final VoidCallback onTap;

  @override
  State<_PickRow> createState() => _PickRowState();
}

class _PickRowState extends State<_PickRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final m = contactMethod(widget.contact);
    return Semantics(
      button: true,
      label: '${widget.contact.name}, ${shortAddress(widget.contact.address)}',
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            color: _hover ? c.hover : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: Sp.x3, horizontal: Sp.x2),
            child: Row(
              children: [
                EAvatar(widget.contact.name, size: 32),
                const SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.contact.name, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(shortAddress(widget.contact.address), style: ts.mono(size: Fs.xs, color: c.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: Sp.x2),
                ETag(
                  switch (m) { TxMethod.epicbox => 'Epicbox', TxMethod.tor => 'Tor', _ => 'HTTP' },
                  tone: m == TxMethod.epicbox ? ETone.gold : ETone.neutral,
                  icon: m == TxMethod.epicbox ? EIcons.antenna : (m == TxMethod.tor ? EIcons.shield : EIcons.web),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
