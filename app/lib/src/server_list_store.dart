// SPDX-License-Identifier: Apache-2.0
/// The phone's Node and Epicbox lists ([ServerList], shared with the desktop): `settings.toml`'s
/// `[node] servers` and `[epicbox] servers` (`server_list_file.dart`), whose first entry is the
/// one in use. The file is the chain's own (a dev chain has its own file), so a list belongs to
/// the chain the app runs on. The status site never adds to them.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart' show Chain;
import 'network.dart';
import 'public_servers.dart';
import 'server_list.dart';
import 'server_list_file.dart';
import 'settings_file/settings_providers.dart';

export 'server_list.dart';

/// The public nodes of a network: the default copy's (of the chain the app runs on).
List<PublicNode> builtInNodesFor(NetworkPreset preset) => builtInNodes;

/// The public relays of a network: the default copy's.
List<PublicRelay> builtInRelaysFor(NetworkPreset preset) => builtInRelays;

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

  Future<void> _apply(ServerList Function(ServerList now) change) async {
    final now = await future;
    final next = change(now);
    if (next == now) return;
    state = AsyncData(next);
    await ref.read(hostSettingsProvider.notifier).setAll(serverListValues(kind, next));
  }

  /// Adds [value] at [at], else last. [own]: the user typed it in.
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

  /// Replaces the whole list (a settings backup read back).
  Future<void> replace(ServerList list) => _apply((_) => list);
}
