// SPDX-License-Identifier: Apache-2.0
/// The one test for a contact backed by a domain the app trusts.
library;

import 'dart:typed_data';

import 'key_picture.dart' show btLabsKeyOf;
import 'models.dart' show PairingRecord;

/// What [isDomainBacked] reads of a contact: the 32-byte encryption key of its card
/// (`ContactView.peerEncKey`, [PairingRecord.peerEncKey]).
typedef DomainFacts = ({Uint8List? peerEncKey});

/// Whether [facts] is backed by a domain the app trusts: for now, its encryption key is one of
/// the BT Labs services' built-in keys (`btLabsKeys`). Such a contact's relay move is a
/// request the user accepts or refuses (`relay_moves.dart`); any other contact's is followed
/// on its own. Every caller goes through here.
bool isDomainBacked(DomainFacts facts) {
  final key = facts.peerEncKey;
  return key != null && btLabsKeyOf(key) != null;
}

extension PairingDomainFacts on PairingRecord {
  /// This pairing's facts for [isDomainBacked].
  DomainFacts get domainFacts => (peerEncKey: peerEncKey);
}
