/// The Import wizard's contacts step: an old GUI's address book into the shared one, through
/// the new wallet's session, and the proof lines that say what happened.
library;

import '../../contact_store.dart' show ContactFields;
import '../../legacy/gui_contacts.dart';
import '../../legacy_gui_profile.dart' as gui;
import '../../log.dart';
import '../../wallet_service.dart' as core;
import 'models.dart' show ImportProof;

/// What the import did with the old contacts.
class ContactImport {
  const ContactImport({
    this.added = 0,
    this.merged = 0,
    this.alreadySaved = 0,
    this.skipped = 0,
    this.addressesLeftOut = 0,
    this.unreadable = false,
    this.failed = false,
  });

  final int added;
  final int merged;
  final int alreadySaved;

  /// Old contacts with no address the app can send to.
  final int skipped;

  /// Valid addresses not saved: a saved contact already has another one of that kind, or the
  /// address is another contact's.
  final int addressesLeftOut;

  /// The old address book was there but could not be read whole.
  final bool unreadable;

  /// Saving stopped with an error; the counts are what was saved before it.
  final bool failed;

  /// The wizard's lines, only those with something to say.
  List<ImportProof> proof() => [
    if (added > 0) ImportProof.l10n((l) => l.deskErrProofContacts(added)),
    if (merged > 0) ImportProof.l10n((l) => l.deskErrProofContactsMerged(merged)),
    if (alreadySaved > 0) ImportProof.l10n((l) => l.deskErrProofContactsKnown(alreadySaved)),
    if (skipped > 0) ImportProof.l10n((l) => l.deskErrProofContactsSkipped(skipped), ok: false),
    if (addressesLeftOut > 0) ImportProof.l10n((l) => l.deskErrProofContactAddressesLeftOut(addressesLeftOut), ok: false),
    if (unreadable) ImportProof.l10n((l) => l.deskErrProofContactsUnreadable, ok: false),
    if (failed) ImportProof.l10n((l) => l.deskErrProofContactsFailed, ok: false),
  ];

  @override
  String toString() =>
      'ContactImport(added: $added, merged: $merged, already: $alreadySaved, skipped: $skipped, ' // l10n-ok: for the log
      'left out: $addressesLeftOut, unreadable: $unreadable, failed: $failed)'; // l10n-ok
}

/// Adds the old GUI's contacts of one wallet to the address book of [session] (shared by every
/// wallet): new ones added, matches merged without changing what is saved. [checks] are the
/// wallet's own address checks. Never throws: a failed save is a line in the proof.
Future<ContactImport> importGuiContacts(core.WalletSession session, gui.LegacyGuiImport profile, AddressChecks checks) async {
  final rows = [
    for (final c in profile.contacts)
      GuiContactRow(name: c.name, externalOne: c.epicboxAddress, externalTwo: c.httpAddress, onion: c.onion, note: c.note),
  ];
  if (rows.isEmpty) return ContactImport(unreadable: profile.addressBookDamaged);
  final List<core.Contact> saved;
  try {
    saved = await session.contacts();
  } on core.WalletError catch (e) {
    logWarn('desk', 'import: contacts not read: ${e.kind.name}');
    return ContactImport(unreadable: profile.addressBookDamaged, failed: true);
  }
  final byId = {for (final c in saved) c.id: c};
  final plan = planGuiContacts(
    rows,
    [for (final c in saved) ContactFields(id: c.id, name: c.name, epicbox: c.epicbox, http: c.http, tor: c.tor, note: c.note)],
    checks,
    epicboxDomain: profile.epicboxDomain,
    epicboxPort: profile.epicboxPort,
  );
  var added = 0, merged = 0;
  var failed = false;
  try {
    for (final c in plan.add) {
      await session.saveContact(contact: core.Contact(id: '', name: c.name, epicbox: c.epicbox, http: c.http, tor: c.tor, note: c.note));
      added++;
    }
    for (final c in plan.update) {
      // Only the kinds and the note the plan filled; anything else stays as saved.
      final was = byId[c.id]!;
      await session.saveContact(
        contact: core.Contact(
          id: was.id,
          name: was.name,
          epicbox: was.epicbox ?? c.epicbox,
          http: was.http ?? c.http,
          tor: was.tor ?? c.tor,
          note: (was.note ?? '').trim().isEmpty ? c.note : was.note,
        ),
      );
      merged++;
    }
  } on core.WalletError catch (e) {
    logWarn('desk', 'import: contacts not saved: ${e.kind.name}');
    failed = true;
  }
  // Merges into a contact this run added count as merged too: [GuiContactPlan.merged] has them.
  final mergedTotal = failed ? merged : plan.merged;
  final r = ContactImport(
    added: added,
    merged: mergedTotal,
    alreadySaved: plan.alreadySaved,
    skipped: plan.skippedNoAddress,
    addressesLeftOut: plan.addressesLeftOut,
    unreadable: profile.addressBookDamaged,
    failed: failed,
  );
  logInfo('desk', 'import: contacts $r');
  return r;
}
