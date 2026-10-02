import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import 'centered_body.dart';
import 'common.dart';
import 'scan_screen.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

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
    final l = context.l10n;
    // With no contacts at all, a search field has nothing to search: the empty state sits in
    // the middle instead.
    final none = switch (contacts) {
      AsyncData(:final value) => value.isEmpty,
      _ => false,
    };
    return SlotScaffold(
      centered: none,
      appBar: AppBar(
        title: Text(widget.pick ? l.contactsPickTitle : l.contactsTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add),
        label: Text(l.contactsAdd),
      ),
      body: none
          ? CenteredBody(
              children: [
                EmptyState(
                  icon: const Icon(Icons.people_outline),
                  message: l.contactsEmpty,
                ),
                // Room for the floating button.
                const SizedBox(height: 72),
              ],
            )
          : ScreenBody(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: l.contactsSearchLabel,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                switch (contacts) {
                  AsyncData(:final value) => _list(_filter(value), theme),
                  AsyncError(:final error) => ErrorText(
                    describeError(l, error),
                  ),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(context.l10n.contactsNoMatch, textAlign: TextAlign.center),
      );
    }
    return Column(
      children: [
        for (final c in contacts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _Initial(c.name),
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
    final l = context.l10n;
    final name = _name.text.trim();
    final recipient = parseRecipient(_address.text);
    setState(() {
      _nameError = name.isEmpty ? l.contactsNameMissing : null;
      _addressError = checkRecipient(
        l,
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
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final contact = widget.contact;
    if (contact == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(l.contactsDeleteTitle(contact.name)),
          content: Text(l.contactsDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.contactsKeep),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.commonDelete),
            ),
          ],
        );
      },
    );
    if (sure != true || !mounted) return;
    try {
      await ref.read(contactsProvider.notifier).delete(contact.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final duplicate = _duplicate(contacts);
    final scanner = ref.watch(qrScannerProvider);
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
          onPressed: _save,
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
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 1,
            maxLines: null,
            onChanged: (_) => setState(() => _addressError = null),
            decoration: InputDecoration(
              labelText: l.contactsAddressLabel,
              error: _addressError == null
                  ? null
                  : LiveFieldError(_addressError!),
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.commonPaste,
                    icon: const Icon(Icons.content_paste),
                    onPressed: _paste,
                  ),
                  if (scanner.supported)
                    IconButton(
                      tooltip: l.scanQrTooltip,
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
                    Expanded(child: Text(l.contactsDuplicate(duplicate.name))),
                  ],
                ),
              ),
            ),
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
}

/// A contact's first letter in a hairline square, the same frame as a payment's direction.
class _Initial extends StatelessWidget {
  const _Initial(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radiusSmall),
        border: Border.all(color: t.lineStrong),
      ),
      child: Text(
        name.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: t.accentText),
      ),
    );
  }
}
