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

/// BT Labs' contact: its address is the signed btlabs.json's when one was verified this run
/// ([useSignedDonation]), else `[support] donation` of `app-config.toml`. Null when that line
/// is left out: then the contact shows nowhere, and the signed file cannot add one.
SeedContact? get btLabsContact {
  final bundled = hostSettings.supportDonation;
  if (bundled == null) return null;
  return SeedContact(id: 'btlabs', name: 'BT Labs', address: _signedDonation ?? bundled, note: 'BT Labs, the makers of this wallet.');
}

/// The BT Labs address of the signed file in use (the copy read at start, or the last good
/// one kept); null until one verified.
String? _signedDonation;

/// Takes BT Labs' address from the seed contacts of a verified file
/// ([seedContactsFrom]) for [btLabsContact]; a file without one changes nothing. A screen
/// that shows the address reads it once when it opens, so what it copies is what it showed.
void useSignedDonation(List<SeedContact> fromFile) {
  for (final c in fromFile) {
    if (c.id == 'btlabs') _signedDonation = c.address;
  }
}

/// Forgets the signed donation address (tests).
void resetSignedDonation() => _signedDonation = null;

/// The id of the wallet's source code in the signed file's `links` (kind `github`).
const String signedSourceLinkId = 'wallet-source';

/// The source code link of the signed file in use; null until one verified with that link.
String? _signedSource;

/// The wallet's source code: the signed btlabs.json's `wallet-source` link when one was verified
/// this run ([useSignedLinks]), else `[links] source` of `app-config.toml`. Null when that line
/// is left out: then no Source code row shows, and the signed file cannot add one.
String? get projectRepoUrl {
  final bundled = hostSettings.linkSource;
  if (bundled == null) return null;
  return _signedSource ?? bundled;
}

/// Takes the source code link from a verified file for [projectRepoUrl]; a file without one
/// changes nothing. Only a link on the bundled link's host is taken (FORMAT.md: clients open
/// only hosts they already know).
void useSignedLinks(BtlabsPublic file) {
  final bundled = hostSettings.linkSource;
  if (bundled == null) return;
  for (final link in file.links) {
    if (link.id == signedSourceLinkId && link.kind == 'github' && Uri.parse(link.url).host == Uri.parse(bundled).host) {
      _signedSource = link.url;
    }
  }
}

/// Forgets the signed source link (tests).
void resetSignedLinks() => _signedSource = null;

/// What the app ships with; used whenever the website cannot be read.
List<SeedContact> get bundledSeedContacts => [?btLabsContact];

/// BT Labs' signed public file (btlabs-public FORMAT.md): the contact's address may change
/// there. The desktop also takes its onions; the phone reads only the address. The keys that may sign it are in `btlabs_keys.dart`.
/// Null when `app-config.toml` names none: it is not read.
String? get btlabsPublicUrl => hostSettings.supportDirectory;

/// The seed contacts in a verified file: for each bundled seed id, the address of its Epic
/// mainnet Epicbox entry (`donations` in the file) when [validAddress] accepts it (the wallet core's checksum). Only
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
