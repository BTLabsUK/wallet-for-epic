// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/net/tor_net.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/tor_phone.dart';
import 'package:epic_wallet/src/tor_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(TorNet.useDirect);

  group('the phone\'s own requests follow the Tor switch', () {
    test('through tor\'s SOCKS port once tor is connected', () {
      const s = PhoneTorState(phase: PhoneTorPhase.ready, receiving: true, socksPort: 9150);
      expect(phoneTorSocks(s)?.port, 9150);
      expect(phoneTorSocks(s)?.host, '127.0.0.1');
      phoneTorFollow(s);
      expect(TorNet.mode, TorNetMode.tor);
    });

    test('waiting, never direct, while tor starts, failed or has no port yet', () {
      for (final s in const [
        PhoneTorState(phase: PhoneTorPhase.starting, receiving: true, socksPort: 9150),
        PhoneTorState(phase: PhoneTorPhase.failed, receiving: true, socksPort: 9150),
        PhoneTorState(phase: PhoneTorPhase.connected, receiving: true),
      ]) {
        expect(phoneTorSocks(s), s.canSend && s.socksPort != null ? isNotNull : isNull);
        phoneTorFollow(s);
        expect(TorNet.mode, TorNetMode.waiting, reason: s.toString());
      }
    });

    test('direct with the switch off', () {
      phoneTorFollow(const PhoneTorState(phase: PhoneTorPhase.ready, socksPort: 9150));
      expect(TorNet.mode, TorNetMode.direct);
      expect(phoneTorState(const PhoneTorState(phase: PhoneTorPhase.ready)), TorState.off);
    });
  });
}
