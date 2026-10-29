// SPDX-License-Identifier: Apache-2.0
/// The desktop's Node and Epicbox lists ([ServerList], shared with the phone): `settings.toml`'s
/// `[node] servers` and `[epicbox] servers` (`server_list_file.dart`), a hand edit too. The first
/// entry is the one in use; the status site never adds to them.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network.dart' show EpicboxRelay;
import '../../server_list.dart';
import '../../server_list_file.dart';
import '../../settings_file/settings_providers.dart';
import 'models.dart';

export '../../server_list.dart';

/// What a panel shows while the list is read, and who runs each server.
@immutable
class DeskServerSource {
  const DeskServerSource({this.public = const [], this.own = const [], this.operators = const {}, this.inUse, this.keep = const []});

  /// The public servers in their order: the default copy's first, then the directory's.
  final List<String> public;

  /// Servers the user added that the wallet knows of.
  final List<String> own;

  /// Who runs each public server, by [serverKeyOf].
  final Map<String, String> operators;

  /// The server in use.
  final String? inUse;

  /// Servers a selection keeps listed.
  final List<String> keep;
}

/// The node list's source: the wallet's public nodes and the node in use.
DeskServerSource nodeSource(List<NodeServer> nodes, {String? inUse}) => DeskServerSource(
  public: [for (final n in nodes) if (!n.own) n.url],
  own: [for (final n in nodes) if (n.own) n.url],
  operators: {
    for (final n in nodes)
      if (!n.own && n.operator != null) serverKeyOf(ServerKind.node, n.url): n.operator!,
  },
  inUse: inUse,
);

/// The relay list's source: the public relays and the one in use.
DeskServerSource relaySource(List<EpicboxServer> boxes, {String? inUse}) => DeskServerSource(
  public: [for (final b in boxes) relayLabel(b)],
  operators: {
    for (final b in boxes)
      if (b.operator != null) serverKeyOf(ServerKind.relay, relayLabel(b)): b.operator!,
  },
  inUse: inUse,
);

/// A relay as the list stores it: `host`, or `host:port` off 443.
String relayLabel(EpicboxServer b) => EpicboxRelay(host: b.domain, port: b.port).label;

final deskServerListProvider = NotifierProvider.family<DeskServerListController, ServerList?, ServerKind>(DeskServerListController.new);

/// One kind's list: the settings file's, followed live (a hand edit too).
class DeskServerListController extends Notifier<ServerList?> {
  DeskServerListController(this.kind);

  final ServerKind kind;

  @override
  ServerList? build() => serverListOf(ref.watch(hostSettingsProvider), kind);

  Future<void> _set(ServerList next) async {
    if (next == state) return;
    state = next;
    await ref.read(hostSettingsProvider.notifier).setAll(serverListValues(kind, next));
  }

  Future<void> add(String value, {int? at, bool own = false}) async => _set((state ?? const ServerList()).add(kind, value, at: at, own: own));

  /// Takes [value] out and returns where it was, for Undo.
  Future<int?> remove(String value) async {
    final r = (state ?? const ServerList()).remove(kind, value);
    await _set(r.list);
    return r.at;
  }
}
