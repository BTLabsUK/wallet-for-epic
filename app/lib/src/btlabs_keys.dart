// SPDX-License-Identifier: Apache-2.0
/// The keys that may sign BT Labs' public files: `btlabs.json` (the donation contact) and the
/// wallet's release manifest, `update.json` (btlabs-public FORMAT.md §2 and §6).
///
/// Rank 1 signs; rank 2 is the offline next key, used only to retire key 1 (ADR 0001 §4). A
/// copy of btlabs-public `keys/btlabs-keyring.json`; a new pair ships with an app release.
library;

import 'btlabs_public.dart';

/// `https://btlabs-epic.github.io/btlabs-keyring.json` serves the same keys.
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
