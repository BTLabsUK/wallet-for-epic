import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import 'centered_body.dart';
import 'common.dart';
import 'contact_sheet.dart';
import 'scan_screen.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tour/tour_target.dart';

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

/// The address book. With [pick], tapping a contact returns it instead of opening its sheet.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key, this.pick = false});

  final bool pick;

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
    await showContactSheet(context, contact);
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
    final l = context.l10n;
    // With no contacts at all, a search field has nothing to search: the empty state sits in
    // the middle instead.
    final none = switch (contacts) {
      AsyncData(:final value) => value.isEmpty,
      _ => false,
    };
    return SlotScaffold(
      centered: none,
      idle: contacts.isLoading ? SlotProgress(label: l.contactsTitle) : null,
      appBar: AppBar(
        title: Text(widget.pick ? l.contactsPickTitle : l.contactsTitle),
        actions: [
          IconButton(
            tooltip: l.contactsAdd,
            icon: const Icon(Icons.person_add_alt),
            onPressed: _add,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PhoneTourTarget(
        id: 'tour-contacts-list',
        child: none
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
                          AsyncData(:final value) => _list(value),
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

  Widget _list(List<Contact> all) {
    final contacts = _filter(all);
    final t = context.tokens;
    if (contacts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: [
          Text(
            context.l10n.contactsNoMatchQuery(_search.text.trim()),
            textAlign: TextAlign.center,
            style: TextStyle(color: t.dim),
          ),
        ],
      );
    }
    final grouped = contacts.length > _groupAbove;
    final rows = <Widget>[];
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
      rows.add(_ContactRow(contact: c, onTap: () => _open(c)));
    }
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: rows);
  }
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

/// One contact: the initials tile, the name with its tag, the short address, the note.
class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.onTap});

  final Contact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final note = contact.note?.trim();
    final address = shortAddress(contact.address);
    final at = address.indexOf('@');
    final mono = TextStyle(
      fontFamily: t.monoFamily,
      fontSize: 13,
      color: t.dim,
    );
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ContactTile(name: contact.name),
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
                        const SizedBox(width: 8),
                        ContactTag(contact.address, compact: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: mono,
                        children: [
                          TextSpan(
                            text: at < 0 ? address : address.substring(0, at),
                            style: TextStyle(color: t.text),
                          ),
                          if (at >= 0) TextSpan(text: address.substring(at)),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
      _addressError = checkContactAddress(
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
              invoiceAddress: widget.contact?.invoiceAddress,
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
    final scan = offersQrScan(ref);
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
                  if (scan)
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
