// SPDX-License-Identifier: Apache-2.0
/// The phone's Node and Epicbox lists ([ServerList], shared with the desktop): the settings
/// file's `[node]` and `[epicbox]` lists (`server_list_file.dart`). The file is the chain's
/// own (a dev chain has its own file), so a list belongs to the chain the app runs on.
///
/// The sheets add the directory's servers as they are seen; "Restore removed servers" and
/// "Reset to defaults" take the shipped file's.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart' show Chain;
import 'network.dart';
import 'public_servers.dart';
import 'server_list.dart';
import 'server_list_file.dart';
import 'settings_file/settings_providers.dart';

export 'server_list.dart';

/// The public nodes of a network: the shipped settings' (of the chain the app runs on).
List<PublicNode> builtInNodesFor(NetworkPreset preset) => builtInNodes;

/// The public relays of a network: the shipped settings'.
List<PublicRelay> builtInRelaysFor(NetworkPreset preset) => builtInRelays;

/// The shipped servers of a kind, as list values.
List<String> builtInValues(ServerKind kind, Chain chain) => shippedServers(kind);

/// The user's list of a kind on a chain: the settings file's.
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
  Future<ServerList> build() async => serverListOf(ref.watch(hostSettingsProvider), kind);

  Future<void> _apply(ServerList Function(ServerList now) change, {Map<String, String> operators = const {}}) async {
    final now = await future;
    final next = change(now);
    if (next == now) return;
    state = AsyncData(next);
    final settings = ref.read(hostSettingsProvider.notifier);
    await settings.setAll(serverListValues(ref.read(hostSettingsProvider), kind, next, operators: operators));
  }

  /// Directory servers seen now: those neither listed nor removed join the end, with who
  /// runs them ([operators], by [serverKeyOf]).
  Future<void> absorb(Iterable<String> public, {Map<String, String> operators = const {}}) =>
      _apply((l) => l.absorb(kind, public), operators: operators);

  /// Adds [value] at [at], else last; it is no longer removed. [own]: the user typed it in.
  Future<void> add(String value, {int? at, bool own = false}) => _apply((l) => l.add(kind, value, at: at, own: own));

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
  Future<void> restore(Iterable<String> public) => _apply((l) => restoreRemoved(kind, l, public));

  /// Replaces the whole list (a settings backup read back).
  Future<void> replace(ServerList list) => _apply((_) => list);
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
  if (nodeUrl != null) {
    await ref.read(serverListProvider((ServerKind.node, chain)).notifier).add(nodeUrl);
  }
  if (relay != null) {
    await ref.read(serverListProvider((ServerKind.relay, chain)).notifier).add(relay.label);
  }
}
