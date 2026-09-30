import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../errors.dart';
import '../providers.dart';
import 'common.dart';
import 'scan_screen.dart';

/// The address book. With [pick], tapping a contact returns it instead of opening it.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key, this.pick = false});

  final bool pick;

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Contact> _filter(List<Contact> contacts) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return contacts;
    return [
      for (final c in contacts)
        if (c.name.toLowerCase().contains(query) ||
            c.address.toLowerCase().contains(query) ||
            (c.note?.toLowerCase().contains(query) ?? false))
          c,
    ];
  }

  Future<void> _open(Contact contact) async {
    if (widget.pick) {
      Navigator.pop(context, contact);
      return;
    }
    await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(
        builder: (_) => ContactEditScreen(contact: contact),
      ),
    );
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(builder: (_) => const ContactEditScreen()),
    );
    if (saved != null && widget.pick && mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pick ? 'Choose a contact' : 'Contacts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add),
        label: const Text('Add contact'),
      ),
      body: ScreenBody(
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search contacts',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          switch (contacts) {
            AsyncData(:final value) when value.isEmpty => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No contacts yet. Add the people you pay often, so you do not '
                'have to paste their address each time.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            AsyncData(:final value) => _list(_filter(value), theme),
            AsyncError(:final error) => ErrorText(describeError(error)),
            _ => const LinearProgressIndicator(),
          },
          // Room for the floating button.
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _list(List<Contact> contacts, ThemeData theme) {
    if (contacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('No contact matches.', textAlign: TextAlign.center),
      );
    }
    return Column(
      children: [
        for (final c in contacts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Text(c.name.characters.first.toUpperCase()),
            ),
            title: Text(c.name),
            // Start and end of the key, so contacts on the same server stay apart.
            subtitle: Text(
              shortAddress(c.address),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _open(c),
          ),
      ],
    );
  }
}

/// Adds a contact, prefilled with [address], or edits [contact]. Pops with the saved contact.
class ContactEditScreen extends ConsumerStatefulWidget {
  const ContactEditScreen({super.key, this.address, this.contact});

  final String? address;
  final Contact? contact;

  @override
  ConsumerState<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends ConsumerState<ContactEditScreen> {
  late final _name = TextEditingController(text: widget.contact?.name);
  late final _address = TextEditingController(
    text: widget.contact?.address ?? widget.address,
  );
  late final _note = TextEditingController(text: widget.contact?.note);
  String? _nameError;
  String? _addressError;
  String? _error;
  bool _busy = false;

  bool get _editing => widget.contact != null;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Another contact already saved under the address being entered.
  Contact? _duplicate(List<Contact> contacts) {
    final address = parseRecipient(_address.text).address;
    final other = contactFor(contacts, address);
    return other == null || other.id == widget.contact?.id ? null : other;
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _address.text = text;
    setState(() => _addressError = null);
  }

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text == null || !mounted) return;
    _address.text = parseRecipient(text).address;
    setState(() => _addressError = null);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final recipient = parseRecipient(_address.text);
    setState(() {
      _nameError = name.isEmpty ? 'Enter a name.' : null;
      _addressError = checkRecipient(
        ref.read(walletServiceProvider),
        _address.text,
      );
      _error = null;
    });
    if (_nameError != null || _addressError != null) return;
    final note = _note.text.trim();
    setState(() => _busy = true);
    try {
      final saved = await ref
          .read(contactsProvider.notifier)
          .save(
            Contact(
              id: widget.contact?.id ?? '',
              name: name,
              address: recipient.address,
              note: note.isEmpty ? null : note,
            ),
          );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final contact = widget.contact;
    if (contact == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${contact.name}?'),
        content: const Text(
          'The address is removed from your contacts. Past payments are '
          'not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await ref.read(contactsProvider.notifier).delete(contact.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final duplicate = _duplicate(contacts);
    final scanner = ref.watch(qrScannerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit contact' : 'New contact'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Delete contact',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ScreenBody(
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _nameError = null),
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _nameError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 1,
            maxLines: null,
            onChanged: (_) => setState(() => _addressError = null),
            decoration: InputDecoration(
              labelText: 'Address or wallet URL',
              errorText: _addressError,
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Paste',
                    icon: const Icon(Icons.content_paste),
                    onPressed: _paste,
                  ),
                  if (scanner.supported)
                    IconButton(
                      tooltip: 'Scan QR code',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scan,
                    ),
                ],
              ),
            ),
          ),
          if (duplicate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This address is already saved as ${duplicate.name}.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
          BusyButton(label: 'Save contact', busy: _busy, onPressed: _save),
        ],
      ),
    );
  }
}
