// SPDX-License-Identifier: Apache-2.0
/// The keys that may sign BT Labs' public files: `btlabs.json` (the BT Labs contact) and the
/// wallet's release manifest, `update.json` (btlabs-public FORMAT.md §2 and §6).
///
/// Rank 1 signs; rank 2 is the offline next key, used only to retire key 1 (ADR 0001 §4). A
/// copy of btlabs-public `keys/btlabs-keyring.json`; a new pair ships with an app release.
library;

import 'btlabs_public.dart';

/// The BT Labs public site serves the same keys as `btlabs-keyring.json`.
const String btlabsKeyringJson = '''
{
  "keys": [
    {
      "keyid": "3eb30c1e66220525",
      "rank": 1,
      "public_key": "9ut79o6FipDX7zYEcWfDyAXoRNuEKnlvtEHpG4wRW08=",
      "label": "btlabs-2026-a"
    },
    {
      "keyid": "f261b50cdc4dae34",
      "rank": 2,
      "public_key": "Cs7+MOuq5fpDA3kVBu6IWP4Ba81XuUngh5epKA3ER2o=",
      "label": "btlabs-2026-b"
    }
  ]
}
''';

/// The bundled keyring, parsed once.
final Keyring btlabsKeyring = Keyring.parse(btlabsKeyringJson);

/// The keys that may sign `announcements.json` (announcements spec §2, §3): their own keyring,
/// so a stolen announcement key signs no release and the release key signs no announcement.
/// Rank 1 signs; rank 2 only revokes rank 1.
///
/// TEST KEYS (made 2026-11-11, public halves only). Replace with the production pair before
/// any release (announcements spec §9): the test keys must not ship.
const String announcementsKeyringJson = '''
{
  "keys": [
    {
      "keyid": "9df7615cea67d189",
      "rank": 1,
      "public_key": "F4Zl8uMhjZWuzdpd9Cl18MBzjUcPQ5Y6dhc+KD2jnxU=",
      "label": "ann-test-a"
    },
    {
      "keyid": "4795449464419841",
      "rank": 2,
      "public_key": "Gjh/UyKnBypVh1ACE/kRIVXyP05daI8xckRYkBD10wM=",
      "label": "ann-test-b"
    }
  ]
}
''';

/// The bundled announcements keyring, parsed once.
final Keyring announcementsKeyring = Keyring.parse(announcementsKeyringJson);
