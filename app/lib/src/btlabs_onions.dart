// SPDX-License-Identifier: Apache-2.0
// Where servers can be reached over Tor: the onion routes of the settings file (`[tor]
// onions`), and for hosts under `[tor] onion_only_domains` the signed btlabs.json's
// (`infrastructure.onions`) once a verified one is read. This file only holds the mapping:
// nothing here opens a connection.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'btlabs_public.dart';
import 'models.dart' show TorOnionRoute;
import 'net/socks.dart' show isOnionOnlyHost;
import 'settings_file/host_settings.dart';

/// The settings file's onion routes as directory entries: the same list for the same settings.
List<BtlOnion> settingsOnions([HostSettings? settings]) {
  final from = settings ?? hostSettings;
  final cached = _onionsCache;
  if (cached != null && identical(cached.$1, from)) return cached.$2;
  final list = List<BtlOnion>.unmodifiable([
    for (final r in from.torOnions)
      BtlOnion(
        id: r.host,
        service: 'other',
        host: r.host.toLowerCase(),
        port: r.port,
        onion: r.onion,
        onionPort: r.onionPort,
        tls: r.tls,
      ),
  ]);
  _onionsCache = (from, list);
  return list;
}

(HostSettings, List<BtlOnion>)? _onionsCache;

/// [settingsOnions] of the settings in use: the routes before any signed file.
List<BtlOnion> get builtInOnions => settingsOnions();

/// The current host-to-onion mapping: the settings file's routes; once a verified btlabs.json
/// carries `infrastructure.onions`, its entries for hosts under the onion-only domains take the
/// place of the settings' routes under those domains (the file's other routes stay). Only [adopt] with a file that passed [verifyBtlabsPublic] (or
/// [loadCachedBtlabsPublic]) may be used; there is no other way in.
class OnionDirectory {
  /// Starts from the settings in use (read at every lookup, so a hand edit applies), or from
  /// [initial] alone in tests.
  OnionDirectory({List<BtlOnion>? initial}) : _fixed = initial;

  final List<BtlOnion>? _fixed;
  List<BtlOnion>? _signed;

  /// The entries in use.
  List<BtlOnion> get entries {
    final base = _fixed ?? settingsOnions();
    final signed = [
      for (final e in _signed ?? const <BtlOnion>[])
        if (isOnionOnlyHost(e.host)) e,
    ];
    if (_signed == null) return base;
    return [
      for (final e in base)
        if (!isOnionOnlyHost(e.host)) e,
      ...signed,
    ];
  }

  /// The onion entry for [host]:[port], or null when none is listed.
  BtlOnion? onionFor(String host, [int port = 443]) {
    final h = host.toLowerCase();
    for (final e in entries) {
      if (e.host == h && e.port == port) return e;
    }
    return null;
  }

  /// Takes the onions of a VERIFIED [file]; a file without the field changes nothing.
  void adopt(BtlabsPublic file) {
    final onions = file.infrastructure.onions;
    if (onions != null) _signed = onions;
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
