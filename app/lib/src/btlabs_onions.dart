// SPDX-License-Identifier: Apache-2.0
// Where BT Labs' public hosts can be reached over Tor. The list comes from the signed
// btlabs.json (`infrastructure.onions`); a copy is built in so a wallet with Tor on can reach
// them before its first fetch. This file only holds the mapping: nothing here opens a connection.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'btlabs_public.dart';
import 'models.dart' show TorOnionRoute;

/// The list that shipped with the app (serial 3 of btlabs.json).
const List<BtlOnion> builtInOnions = [
  BtlOnion(
    id: 'epicbox',
    service: 'epicbox',
    host: 'epicbox.btlabs.uk',
    port: 443,
    onion: 'j2xf5rizkow5jtrdf6edotk5qam4kohavip23dqeuih5bq4yqisbz5ad.onion',
    onionPort: 443,
    tls: true,
  ),
  BtlOnion(
    id: 'node',
    service: 'node',
    host: 'node.btlabs.uk',
    port: 443,
    onion: '5drwoknehnzducfsxsl45dazaw3cwcmpx3ycamynagmcpv6aalrbrtqd.onion',
    onionPort: 443,
    tls: true,
  ),
  BtlOnion(
    id: 'support',
    service: 'support',
    host: 'support.btlabs.uk',
    port: 443,
    onion: 'lowiz5jnnu5vyyqc5guig3zag3k7azorbjfkcszfqwdxh3yarfei66yd.onion',
    onionPort: 443,
    tls: true,
  ),
  BtlOnion(
    id: 'status',
    service: 'status',
    host: 'status.btlabs.uk',
    port: 443,
    onion: 't6furoapbsowxp3hvmjwp223zenmauwldfv2noddih7bfuuavwyvaqad.onion',
    onionPort: 80,
    tls: false,
  ),
];

/// The current host-to-onion mapping: the built-in copy until a verified btlabs.json carries
/// `infrastructure.onions`, then that list. Only [adopt] with a file that passed
/// [verifyBtlabsPublic] (or [loadCachedBtlabsPublic]) may be used; there is no other way in.
class OnionDirectory {
  /// Starts with the built-in copy, or [initial] in tests.
  OnionDirectory({List<BtlOnion> initial = builtInOnions}) : _list = initial;

  List<BtlOnion> _list;

  /// The entries in use.
  List<BtlOnion> get entries => _list;

  /// The onion entry for [host]:[port], or null when none is listed.
  BtlOnion? onionFor(String host, [int port = 443]) {
    final h = host.toLowerCase();
    for (final e in _list) {
      if (e.host == h && e.port == port) return e;
    }
    return null;
  }

  /// Takes the onions of a VERIFIED [file]; a file without the field changes nothing.
  void adopt(BtlabsPublic file) {
    final onions = file.infrastructure.onions;
    if (onions != null) _list = onions;
  }
}

/// The TLS entries of [directory] as LEPIC's onion routes: through tor these hosts are reached
/// at their onion, still checking the host's certificate. Plain-HTTP onions stay out.
List<TorOnionRoute> onionRoutesOf(OnionDirectory directory) => [
  for (final e in directory.entries)
    if (e.tls) (host: e.host, port: e.port, onion: e.onion, onionPort: e.onionPort),
];

/// The app's one directory.
final onionDirectoryProvider = Provider<OnionDirectory>((ref) => OnionDirectory());
