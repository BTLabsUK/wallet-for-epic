/// The phone's Node and Epicbox lists ([ServerList], shared with the desktop), kept in the
/// secret store: one JSON object per kind and chain under `app.serverList.<kind>.<chain>`.
///
/// A first use seeds the list from the built-in servers and what the old "My nodes" / "My
/// servers" lists held; the sheets add the directory's servers as they are seen.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart' show Chain;
import 'network.dart';
import 'providers.dart';
import 'public_servers.dart';
import 'push_registration.dart' show PushRegistration;
import 'server_list.dart';

export 'server_list.dart';

/// The secret-store key of a kind's list on a chain.
String serverListKey(ServerKind kind, Chain chain) => 'app.serverList.${kind.name}.${chain.name}';

/// Where 26.10.11 and older kept the nodes the user added (a JSON list of addresses); read
/// once, into the first list.
String myNodesKey(Chain chain) => 'app.myNodes.${chain.name}';

/// Where 26.10.11 and older kept the relays the wallet used (a JSON list of labels).
String myRelaysKey(Chain chain) => 'app.myRelays.${chain.name}';

/// The built-in nodes of a network: the public mainnet list, else the network's own node.
List<PublicNode> builtInNodesFor(NetworkPreset preset) => preset.chain == Chain.mainnet
    ? builtInNodes
    : [PublicNode(url: preset.nodeUrl, operator: preset.chain == Chain.floonet ? 'BT Labs' : '')];

/// The built-in relays of a network: the public mainnet list and the push relay, else the
/// network's own relay (on floonet that is the push relay).
List<PublicRelay> builtInRelaysFor(NetworkPreset preset) => preset.chain == Chain.mainnet
    ? [
        ...builtInRelays,
        const PublicRelay(
          relay: EpicboxRelay(host: PushRegistration.relayHost),
          operator: 'BT Labs',
        ),
      ]
    : [
        PublicRelay(
          relay: preset.defaultRelay,
          operator: preset.chain == Chain.floonet ? 'BT Labs' : '',
        ),
      ];

/// The built-in servers of a kind on a chain, as list values.
List<String> builtInValues(ServerKind kind, Chain chain) {
  final preset = networkPresets.firstWhere((p) => p.chain == chain);
  return kind == ServerKind.node
      ? [for (final n in builtInNodesFor(preset)) n.url]
      : [for (final r in builtInRelaysFor(preset)) r.relay.label];
}

/// The user's list of a kind on a chain.
final serverListProvider =
    AsyncNotifierProvider.family<ServerListNotifier, ServerList, (ServerKind, Chain)>(
      ServerListNotifier.new,
    );

class ServerListNotifier extends AsyncNotifier<ServerList> {
  ServerListNotifier(this.arg);

  final (ServerKind, Chain) arg;

  ServerKind get kind => arg.$1;
  Chain get chain => arg.$2;

  @override
  Future<ServerList> build() async {
    final store = ref.watch(secretStoreProvider);
    final saved = ServerList.decode(await store.read(serverListKey(kind, chain)));
    if (saved != null) return saved;
    // First use (or a broken record): the built-in servers, then what the old list held.
    final carried = <String>[];
    final old = await store.read(kind == ServerKind.node ? myNodesKey(chain) : myRelaysKey(chain));
    if (old != null) {
      try {
        final decoded = jsonDecode(old);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is String && e.isNotEmpty) carried.add(e);
          }
        }
      } on FormatException {
        // Nothing to carry over.
      }
    }
    final seeded = ServerList.seed(kind, builtInValues(kind, chain), carried: carried);
    await store.write(serverListKey(kind, chain), seeded.encode());
    return seeded;
  }

  Future<void> _apply(ServerList Function(ServerList now) change) async {
    final now = await future;
    final next = change(now);
    if (next == now) return;
    state = AsyncData(next);
    await ref.read(secretStoreProvider).write(serverListKey(kind, chain), next.encode());
  }

  /// Directory servers seen now: those neither listed nor removed join the end.
  Future<void> absorb(Iterable<String> public) => _apply((l) => l.absorb(kind, public));

  /// Adds [value] at [at], else last; it is no longer removed.
  Future<void> add(String value, {int? at}) => _apply((l) => l.add(kind, value, at: at));

  /// Takes [value] out and returns where it was, for Undo.
  Future<int?> remove(String value) async {
    int? at;
    await _apply((l) {
      final r = l.remove(kind, value);
      at = r.at;
      return r.list;
    });
    return at;
  }

  /// Forgets every removal and puts the [public] servers back.
  Future<void> restore(Iterable<String> public) => _apply((l) => l.restore(kind, public));
}

/// After a switch: the servers the wallet moved onto are in their lists, whichever way they
/// were chosen, and no longer counted as removed.
Future<void> rememberServers(
  WidgetRef ref,
  NetworkPreset preset, {
  String? nodeUrl,
  EpicboxRelay? relay,
}) async {
  final chain = preset.chain;
  if (nodeUrl != null)
    await ref.read(serverListProvider((ServerKind.node, chain)).notifier).add(nodeUrl);
  if (relay != null)
    await ref.read(serverListProvider((ServerKind.relay, chain)).notifier).add(relay.label);
}
