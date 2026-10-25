/// A contact at a glance (spec §3): the sheet a tap on a contact opens, with the full
/// address to check or copy, its code behind Show code, and Send, Edit and Delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'method_names.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// Keys of the contact sheet, for tests.
const Key contactSheetSendKey = ValueKey('contact-sheet-send');
const Key contactSheetEditKey = ValueKey('contact-sheet-edit');
const Key contactSheetDeleteKey = ValueKey('contact-sheet-delete');

/// Two letters for [name]: the first letters of its first two words, else its first two
/// letters, in upper case. `?` for a name with nothing in it.
String contactInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  if (words.length > 1) {
    return (words.first.characters.first + words.elementAt(1).characters.first)
        .toUpperCase();
  }
  return words.first.characters.take(2).toString().toUpperCase();
}

/// How the app reaches [address]: `Epicbox`, `Link · HTTP` for an http(s) address, `Link ·
/// Tor` for an onion address.
String contactTag(AppLocalizations l, String address) =>
    recipientMethodWord(l, parseRecipient(address).kind);

/// [contactInitials] in a [GlyphTile] of [size], in the display face.
class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlyphTile(
      size: size,
      child: Text(
        contactInitials(name),
        style: TextStyle(
          fontFamily: t.headFamily,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
          color: t.accentText,
        ),
      ),
    );
  }
}

/// The kind of [address] as a badge: Epicbox, Link · HTTP or Link · Tor.
class ContactTag extends StatelessWidget {
  const ContactTag(this.address, {super.key, this.compact = false});

  final String address;

  /// The glyph alone, its name in the tooltip: list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) => EBadge.kind(parseRecipient(address).kind, l: context.l10n, compact: compact);
}

/// Opens [contact]'s sheet over [context], the contacts screen.
Future<void> showContactSheet(BuildContext context, Contact contact) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ContactSheet(contact: contact, host: context),
    );

/// The sheet itself. [host] is the screen under it, which Edit and Send act from once the
/// sheet is closed.
class ContactSheet extends ConsumerStatefulWidget {
  const ContactSheet({super.key, required this.contact, required this.host});

  final Contact contact;
  final BuildContext host;

  @override
  ConsumerState<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<ContactSheet> {
  bool _code = false;

  Contact get _contact => widget.contact;

  void _send() {
    Navigator.pop(context);
    final host = widget.host;
    if (host.mounted) {
      showShellTab(host, ShellTab.send, recipient: _contact.address);
    }
  }

  void _edit() {
    Navigator.pop(context);
    final host = widget.host;
    if (!host.mounted) return;
    Navigator.of(host).push<Contact>(
      MaterialPageRoute<Contact>(
        builder: (_) => ContactEditScreen(contact: _contact),
      ),
    );
  }

  Future<void> _delete() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(l.contactsDeleteTitle(_contact.name)),
          content: Text(l.contactsDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
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
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    try {
      await ref.read(contactsProvider.notifier).delete(_contact.id);
      notices.show(
        l.contactsDeleted(_contact.name),
        level: NoticeLevel.success,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final note = _contact.note?.trim();
    final label = TextStyle(color: t.dim, fontSize: 12);
    // The modal sheet leaves the phone's bottom inset to its content: the action row stays
    // above the gesture or navigation bar.
    final foot = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ContactTile(name: _contact.name, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        _contact.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ContactTag(_contact.address),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l.contactsAddressHeading, style: label),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: t.field,
              border: Border.all(color: t.line),
              borderRadius: BorderRadius.circular(t.radiusSmall),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 0, 4),
            child: Row(
              children: [
                Expanded(child: _FullAddress(_contact.address)),
                IconButton(
                  tooltip: l.commonCopy,
                  color: t.accentText,
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () =>
                      copyText(context, _contact.address, l.contactsCopied),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
              icon: Icon(_code ? Icons.visibility_off : Icons.qr_code_2),
              label: Text(_code ? l.contactsHideCode : l.contactsShowCode),
              onPressed: () => setState(() => _code = !_code),
            ),
          ),
          if (_code)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Dark modules on white scan reliably in either theme.
                  color: protocolLight.surface,
                  borderRadius: BorderRadius.circular(t.radiusSmall),
                ),
                child: Semantics(
                  label: l.contactsQrLabel(_contact.name),
                  image: true,
                  child: MarkedQr(data: _contact.address, size: 200),
                ),
              ),
            ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.contactsNoteHeading, style: label),
            const SizedBox(height: 4),
            Text(note, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: contactSheetSendKey,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.north_east, size: 18),
                  label: Text(l.contactsSendAction),
                  onPressed: _send,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: contactSheetEditKey,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: _edit,
                child: Text(l.contactsEditAction),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: contactSheetDeleteKey,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: t.risk,
                ),
                onPressed: _delete,
                child: Text(l.commonDelete),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The whole address in mono, wrapping, the relay part dim.
class _FullAddress extends StatelessWidget {
  const _FullAddress(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = TextStyle(
      fontFamily: t.monoFamily,
      fontSize: 13,
      color: t.text,
    );
    final at = address.indexOf('@');
    return SelectableText.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: at < 0 ? address : address.substring(0, at)),
          if (at >= 0)
            TextSpan(
              text: address.substring(at),
              style: TextStyle(color: t.dim),
            ),
        ],
      ),
    );
  }
}
