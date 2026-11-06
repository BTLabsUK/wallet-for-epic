// SPDX-License-Identifier: Apache-2.0
/// The one test for a contact backed by a domain the app trusts.
library;

import 'dart:typed_data';

import 'history/domain_check_book.dart' show DomainStatus;
import 'key_picture.dart' show btLabsKeyOf;
import 'models.dart' show PairingRecord;

/// What [isDomainBacked] reads of a contact: the 32-byte encryption key of its card
/// (`ContactView.peerEncKey`, [PairingRecord.peerEncKey]) and whether the domain it claims is
/// proven by the file the domain serves ([PairingRecord.domainStatus], `domain_check.dart`).
typedef DomainFacts = ({Uint8List? peerEncKey, bool domainProven});

/// Whether [facts] is backed by a domain the app trusts: its encryption key is one of the BT
/// Labs services' built-in keys (`btLabsKeys`), or the domain it claims is proven. Such a
/// contact's relay move is a request the user accepts or refuses (`relay_moves.dart`); any
/// other contact's is followed on its own. Every caller goes through here.
bool isDomainBacked(DomainFacts facts) {
  if (facts.domainProven) return true;
  final key = facts.peerEncKey;
  return key != null && btLabsKeyOf(key) != null;
}

extension PairingDomainFacts on PairingRecord {
  /// This pairing's facts for [isDomainBacked].
  DomainFacts get domainFacts => (peerEncKey: peerEncKey, domainProven: domainStatus == DomainStatus.proven);
}
