// SPDX-License-Identifier: Apache-2.0
// The one predicate for a domain-backed contact (`domain_backed.dart`): a BT Labs key or a
// proven domain makes it; a claimed or refused domain does not.
import 'dart:typed_data';

import 'package:epic_wallet/src/domain_backed.dart';
import 'package:epic_wallet/src/history/domain_check_book.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isDomainBacked', () {
    test('a BT Labs key is, with or without a proven domain', () {
      expect(isDomainBacked((peerEncKey: FakePairing.serviceKey, domainProven: false)), isTrue);
      expect(isDomainBacked((peerEncKey: FakePairing.serviceKey, domainProven: true)), isTrue);
    });

    test('a proven domain is, whatever the key', () {
      expect(isDomainBacked((peerEncKey: Uint8List(32), domainProven: true)), isTrue);
      expect(isDomainBacked((peerEncKey: null, domainProven: true)), isTrue);
    });

    test('another key, or none, with no proven domain is not', () {
      expect(isDomainBacked((peerEncKey: Uint8List(32), domainProven: false)), isFalse);
      expect(isDomainBacked((peerEncKey: null, domainProven: false)), isFalse);
    });
  });

  group('PairingRecord.domainFacts', () {
    test('only a proven status counts as proven', () {
      final api = FakeWalletSession().pairing;
      PairingRecord seed(String name, {String? domain, DomainStatus? status}) => api.seedPaired(name: name, peerDomain: domain, domainStatus: status);

      expect(seed('None').domainFacts.domainProven, isFalse);
      expect(seed('Claimed', domain: 'a.example').domainFacts.domainProven, isFalse);
      expect(seed('Refused', domain: 'b.example', status: DomainStatus.refused).domainFacts.domainProven, isFalse);
      expect(isDomainBacked(seed('Proven', domain: 'c.example', status: DomainStatus.proven).domainFacts), isTrue);
    });
  });
}
