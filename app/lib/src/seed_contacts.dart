// SPDX-License-Identifier: Apache-2.0
/// Contacts every new wallet starts with: the bundled list, and BT Labs' signed
/// `btlabs.json` that may update its address later. Pure Dart, shared by the phone and the
/// desktop; the seeding rule (insert once, never re-add a deleted one, leave an edited one
/// alone) lives with each app's contacts store.
library;

import 'btlabs_public.dart';
import 'settings_file/host_settings.dart' show hostSettings;

/// One contact a new wallet starts with. [id] stays the same when the website changes the
/// address, so an update can find the contact it seeded.
class SeedContact {
  const SeedContact({required this.id, required this.name, required this.address, required this.note});

  final String id;
  final String name;
  final String address;
  final String note;

  @override
  bool operator ==(Object other) =>
      other is SeedContact && other.id == id && other.name == name && other.address == address && other.note == note;

  @override
  int get hashCode => Object.hash(id, name, address, note);

  @override
  String toString() => 'SeedContact($id, $name, $address)';
}

/// BT Labs' donation address (`[support] donation` of `app-config.toml`), or null when that
/// line is left out: then no donation entry shows anywhere, and the signed file cannot add one.
SeedContact? get btLabsContact {
  final address = hostSettings.supportDonation;
  if (address == null) return null;
  return SeedContact(id: 'btlabs', name: 'BT Labs', address: address, note: 'Donations support development of this wallet.');
}

/// What the app ships with; used whenever the website cannot be read.
List<SeedContact> get bundledSeedContacts => [?btLabsContact];

/// BT Labs' signed public file (btlabs-public FORMAT.md): the donation address may change
/// there; nothing else is read from it yet. The keys that may sign it are in `btlabs_keys.dart`.
/// Null when `app-config.toml` names none: it is not read.
String? get btlabsPublicUrl => hostSettings.supportDirectory;

/// The seed contacts in a verified file: for each bundled seed id, the address of its Epic
/// mainnet Epicbox donation when [validAddress] accepts it (the wallet core's checksum). Only
/// the address comes from the file; name and note stay the bundled ones, so even a stolen
/// signing key cannot put text of its choosing into users' contact lists.
List<SeedContact> seedContactsFrom(BtlabsPublic file, {required bool Function(String address) validAddress}) {
  final bundled = {for (final c in bundledSeedContacts) c.id: c};
  final out = <SeedContact>[];
  final seen = <String>{};
  for (final d in file.donationsFor(coin: 'epic', network: 'mainnet', method: 'epicbox')) {
    final b = bundled[d.id];
    final a = d.address.trim();
    if (b == null || !validAddress(a) || !seen.add(d.id)) continue;
    out.add(SeedContact(id: b.id, name: b.name, address: a, note: b.note));
  }
  return out;
}
