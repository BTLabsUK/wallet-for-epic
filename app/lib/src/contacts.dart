/// Recipients and the address book: names for epicbox addresses, Tor addresses and wallet
/// URLs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';
import 'providers.dart';
import 'wallet_service.dart';

export 'wallet_service.dart' show Contact;

/// Where a payment goes.
enum RecipientKind { epicbox, tor, http }

class Recipient {
  const Recipient(this.kind, this.address);

  final RecipientKind kind;

  /// `<address>@<relay>` for epicbox, `<56 characters>.onion` for Tor, the full URL for HTTP.
  final String address;
}

/// Reads a bare epicbox address, `epicbox://<address>`, an onion address in any of its forms,
/// or an `http(s)://` wallet URL from typed, pasted or scanned text. Removes whitespace, which
/// QR codes and chat apps sometimes add. An onion (F9: with or without `.onion`, with
/// `http://`, a port, a trailing slash, in upper case) comes back as `<56 characters>.onion`
/// in lower case, the one form the app shows. Does not validate; see [checkRecipient].
Recipient parseRecipient(String text) {
  final clean = text.replaceAll(RegExp(r'\s'), '');
  final lower = clean.toLowerCase();
  // Before the URL check: `http://<onion>` goes over Tor, not HTTP.
  if (onionAddressFormat(clean)) {
    return Recipient(RecipientKind.tor, onionHost(clean));
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return Recipient(RecipientKind.http, clean);
  }
  const scheme = 'epicbox://';
  final address = lower.startsWith(scheme)
      ? clean.substring(scheme.length)
      : clean;
  return Recipient(RecipientKind.epicbox, address);
}

// `Contact` is the core's type, exported by wallet_service.dart. An empty id means not saved yet.

/// Where contacts are stored.
abstract interface class ContactBook {
  Future<List<Contact>> list();

  /// Saves [contact]; an empty id creates a new one. Returns the saved contact.
  Future<Contact> save(Contact contact);

  Future<void> delete(String id);
}

/// Contacts in the open wallet's history file, through the core.
class SessionContactBook implements ContactBook {
  const SessionContactBook(this._session);

  final WalletSession _session;

  @override
  Future<List<Contact>> list() => _session.contacts();

  @override
  Future<Contact> save(Contact contact) =>
      _session.saveContact(contact: contact);

  @override
  Future<void> delete(String id) => _session.deleteContact(id: id);
}

/// Contacts in memory. Stands in while the wallet is locked, when there is nothing to show.
class MemoryContactBook implements ContactBook {
  final Map<String, Contact> _byId = {};
  int _next = 1;

  @override
  Future<List<Contact>> list() async => _byId.values.toList();

  @override
  Future<Contact> save(Contact contact) async {
    final id = contact.id.isEmpty ? 'c${_next++}' : contact.id;
    final saved = Contact(
      id: id,
      name: contact.name,
      address: contact.address,
      note: contact.note,
    );
    _byId[id] = saved;
    return saved;
  }

  @override
  Future<void> delete(String id) async => _byId.remove(id);
}

/// The open wallet's contacts; an empty book while locked.
final contactBookProvider = Provider<ContactBook>((ref) {
  final session = ref.watch(sessionProvider);
  return session == null ? MemoryContactBook() : SessionContactBook(session);
});

/// Contacts sorted by name.
final contactsProvider = AsyncNotifierProvider<ContactsNotifier, List<Contact>>(
  ContactsNotifier.new,
);

class ContactsNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() async {
    final contacts = await ref.watch(contactBookProvider).list();
    return contacts
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<Contact> save(Contact contact) async {
    final saved = await ref.read(contactBookProvider).save(contact);
    ref.invalidateSelf();
    await future;
    return saved;
  }

  Future<void> delete(String id) async {
    await ref.read(contactBookProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

/// The contact saved under [address], if any. Addresses compare without surrounding
/// whitespace; epicbox addresses and URLs are case-sensitive in their key part, so case counts.
Contact? contactFor(Iterable<Contact> contacts, String? address) {
  if (address == null) return null;
  final wanted = address.trim();
  if (wanted.isEmpty) return null;
  for (final contact in contacts) {
    if (contact.address.trim() == wanted) return contact;
  }
  return null;
}

/// The name of the contact saved under [address], if any.
String? contactNameFor(Iterable<Contact> contacts, String? address) =>
    contactFor(contacts, address)?.name;

/// Checks that [text] is something the wallet can send to: a full epicbox address valid on the
/// open wallet's chain, an onion address whose checksum holds, or an `http(s)` wallet URL.
/// Returns a sentence for the user in [l]'s language, or null.
String? checkRecipient(AppLocalizations l, WalletService service, String text) {
  if (text.trim().isEmpty) return l.contactsAddressMissing;
  final recipient = parseRecipient(text);
  switch (recipient.kind) {
    case RecipientKind.tor:
      return service.validateOnionAddress(address: recipient.address)
          ? null
          : l.sendOnionIncomplete;
    case RecipientKind.http:
      final uri = Uri.tryParse(recipient.address);
      if (uri == null || uri.host.isEmpty) {
        return l.contactsUrlIncomplete('http://203.0.113.5:3415');
      }
      return null;
    case RecipientKind.epicbox:
      return service.validateEpicboxAddress(address: recipient.address)
          ? null
          : l.contactsAddressInvalid('es5x…@epicbox.epiccash.com');
  }
}

/// [checkRecipient] for a contact's address: a wallet URL is refused, since the wallet pays
/// over epicbox and by transaction file only (OD-2), as Send refuses it.
String? checkContactAddress(
  AppLocalizations l,
  WalletService service,
  String text,
) {
  if (text.trim().isNotEmpty &&
      parseRecipient(text).kind == RecipientKind.http) {
    return l.sendUrlUnsupported;
  }
  return checkRecipient(l, service, text);
}

/// The last [limit] distinct addresses this wallet sent to, newest first. Only sends that name
/// their recipient count; cancelled sends are left out, since a cancel often follows a mistyped
/// address.
List<String> recentRecipients(Iterable<TxEntry> transactions, {int limit = 3}) {
  final sends =
      transactions
          .where((t) => t.kind == TxKind.sent && t.counterparty != null)
          .toList()
        ..sort((a, b) => b.timeUnix.compareTo(a.timeUnix));
  final seen = <String>{};
  final out = <String>[];
  for (final tx in sends) {
    final address = tx.counterparty!.trim();
    if (address.isEmpty || !seen.add(address)) continue;
    out.add(address);
    if (out.length == limit) break;
  }
  return out;
}
