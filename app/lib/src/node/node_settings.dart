/// The local node's settings of one chain, kept in the app's settings store under
/// `node.<chain>.<name>`. A value that does not read (garbage, an older format) gives the
/// default, never an error.
library;

import 'dart:convert';

import '../builtin_node.dart';
import '../models.dart' show Chain;
import '../secret_store_api.dart';
import 'fallback.dart';

class NodeSettings {
  NodeSettings(this.store, this.chain);

  final SecretStore store;
  final Chain chain;

  String key(String name) => 'node.${chain.name}.$name';

  /// Start the node when the app starts. Default true.
  Future<bool> startWithApp() async =>
      switch (await _read('startWithApp')) {
        'false' => false,
        _ => true,
      };

  Future<void> setStartWithApp(bool on) => store.write(key('startWithApp'), '$on');

  /// Where the chain data lives; null is the node folder's `chain_data`.
  Future<String?> chainDataPath() async {
    final v = (await _read('chainDataPath'))?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  Future<void> setChainDataPath(String? path) => _writeOrDelete(
    'chainDataPath',
    path == null || path.trim().isEmpty ? null : path.trim(),
  );

  /// `peers_preferred`, as saved (invalid entries are dropped when the toml is written).
  Future<List<String>> preferredPeers() async {
    final raw = await _read('preferredPeers');
    if (raw == null) return const [];
    try {
      final v = jsonDecode(raw);
      return v is List ? v.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> setPreferredPeers(List<String> peers) {
    final clean = [
      for (final p in peers)
        if (p.trim().isNotEmpty) p.trim(),
    ];
    return _writeOrDelete(
      'preferredPeers',
      clean.isEmpty ? null : jsonEncode(clean),
    );
  }

  /// `peer_max_inbound_count`; null is the node's default.
  Future<int?> maxInbound() => _count('maxInbound');

  Future<void> setMaxInbound(int? n) => _setCount('maxInbound', n);

  /// `peer_max_outbound_count`; null is the node's default.
  Future<int?> maxOutbound() => _count('maxOutbound');

  Future<void> setMaxOutbound(int? n) => _setCount('maxOutbound', n);

  /// The user's answer about the public-node fallback while the local node syncs.
  Future<FallbackChoice> fallbackChoice() async {
    final raw = await _read('fallbackConsent');
    if (raw == null) return const FallbackChoice.unasked();
    try {
      return FallbackChoice.fromJson(jsonDecode(raw));
    } on FormatException {
      return const FallbackChoice.unasked();
    }
  }

  Future<void> setFallbackChoice(FallbackChoice choice) =>
      store.write(key('fallbackConsent'), jsonEncode(choice.toJson()));

  /// The toml options these settings make.
  Future<NodeTomlOptions> toOptions() async => NodeTomlOptions(
    chainDataPath: await chainDataPath(),
    preferredPeers: await preferredPeers(),
    maxInbound: await maxInbound(),
    maxOutbound: await maxOutbound(),
  );

  /// Saves every field of [o].
  Future<void> saveOptions(NodeTomlOptions o) async {
    await setChainDataPath(o.chainDataPath);
    await setPreferredPeers(o.preferredPeers);
    await setMaxInbound(o.maxInbound);
    await setMaxOutbound(o.maxOutbound);
  }

  Future<String?> _read(String name) async {
    try {
      return await store.read(key(name));
    } on Object {
      // an unreadable store gives the defaults
      return null;
    }
  }

  Future<void> _writeOrDelete(String name, String? value) =>
      value == null ? store.delete(key(name)) : store.write(key(name), value);

  Future<int?> _count(String name) async {
    final n = int.tryParse((await _read(name))?.trim() ?? '');
    return n == null || n < 0 ? null : n;
  }

  Future<void> _setCount(String name, int? n) =>
      _writeOrDelete(name, n == null || n < 0 ? null : '$n');
}
