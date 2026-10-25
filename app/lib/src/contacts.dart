/// Recipients and the address book: names for epicbox addresses, Tor addresses and wallet
/// URLs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';
import 'providers.dart';
import 'recipient.dart';
import 'wallet_service.dart';

export 'recipient.dart';
export 'wallet_service.dart' show Contact;

// `Contact` is the core's type, exported by wallet_service.dart. An empty id means not saved yet.

/// Where contacts are stored: the address book's repository. Screens and providers reach
/// contacts only through it, so a store shared by every wallet on the device can replace the
/// open wallet's [SessionContactBook] without touching them.
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
    final saved = contact.copyWith(id: id);
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

/// The contact saved under [address], any of its addresses, if any. Addresses compare
/// without surrounding whitespace; epicbox addresses and URLs are case-sensitive in their key
/// part, so case counts.
Contact? contactFor(Iterable<Contact> contacts, String? address) {
  if (address == null) return null;
  final wanted = address.trim();
  if (wanted.isEmpty) return null;
  for (final contact in contacts) {
    if (contact.addresses.any((a) => a.trim() == wanted)) return contact;
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
          : l.contactsAddressInvalidAny;
  }
}

/// [checkRecipient] for a contact's address: a wallet URL is refused, since the wallet pays
/// over epicbox and by transaction file only (OD-2), as Send refuses it.
String? checkContactAddress(
  AppLocalizations l,
  WalletService service,
  String text,
) {
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
