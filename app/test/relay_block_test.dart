// SPDX-License-Identifier: Apache-2.0
// An Epicbox relay this network blocks (report gwuouzfy): only refused TLS handshakes count,
// twice in a row, and the relay offered instead is one the monitor saw up.
import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/public_servers.dart';
import 'package:epic_wallet/src/relay_block.dart';
import 'package:epic_wallet/src/relay_directory.dart';

/// Word for word from the phone's log (26.10.16 r2, Virgin Media's filter proxy).
const filtered = 'could not connect to the relay: received fatal alert: CloseNotify';

void main() {
  test('a TLS alert during the handshake is a refused handshake', () {
    expect(refusedHandshake(filtered), isTrue);
    expect(
      refusedHandshake('could not connect to the relay: received fatal alert: InternalError'),
      isTrue,
    );
  });

  test('ordinary outages are not', () {
    for (final reason in [
      null,
      '',
      'could not connect to the relay: Connection refused (os error 111)',
      'could not connect to the relay: Connection reset by peer (os error 104)',
      'could not connect to the relay: failed to lookup address information: Name or service not known',
      'could not connect to the relay: invalid peer certificate: Expired',
      'timed out awaiting the connection',
      'websocket error: HTTP error: 502 Bad Gateway',
      'websocket error: Connection reset without closing handshake',
      'the relay closed the connection: code 1006',
      // An alert later, on a connection that was up, is a drop, not a refusal.
      'websocket error: IO error: received fatal alert: DecodeError',
    ]) {
      expect(refusedHandshake(reason), isFalse, reason: '$reason');
    }
  });

  test('blocked after two refused handshakes in a row, not one', () {
    final watch = RelayBlockWatch();
    expect(watch.failed(filtered), isFalse);
    expect(watch.failed(filtered), isTrue);
    expect(watch.failed(filtered), isTrue);
    // Another failure starts the count again.
    expect(watch.failed('timed out awaiting the connection'), isFalse);
    expect(watch.failed(filtered), isFalse);
    watch.reset();
    expect(watch.blocked, isFalse);
  });

  group('relayInstead', () {
    const blocked = EpicboxRelay(host: 'epicbox.epiccash.com');
    RelayStatus seen(String host, bool healthy) => RelayStatus(
      relay: EpicboxRelay(host: host),
      healthy: healthy,
      verified: true,
    );

    test('the first other relay the monitor saw up', () {
      final public = mergePublicRelays([
        seen('epicbox.epiccash.com', true),
        seen('epicbox.stackwallet.com', false),
        seen('epicbox.epicnet.us', true),
        seen('epicbox.iniaku.my.id', true),
      ]);
      expect(relayInstead(blocked, public)?.host, 'epicbox.epicnet.us');
    });

    test('without the monitor, the first other built-in relay', () {
      expect(relayInstead(blocked, mergePublicRelays(null))?.host, 'epicbox.stackwallet.com');
    });

    test('skips relays this network blocked before; none left is null', () {
      final public = mergePublicRelays(null);
      expect(
        relayInstead(
          blocked,
          public,
          skip: {const EpicboxRelay(host: 'epicbox.stackwallet.com')},
        )?.host,
        'epicbox.epicnet.us',
      );
      expect(relayInstead(blocked, public, skip: {for (final r in public) r.relay}), isNull);
    });
  });
}
