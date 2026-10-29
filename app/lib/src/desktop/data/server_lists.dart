// SPDX-License-Identifier: Apache-2.0
/// The desktop's Node and Epicbox lists ([ServerList], shared with the phone): the settings
/// file's `[node]` and `[epicbox]` lists (`server_list_file.dart`), a hand edit too.
///
/// The directory's new servers join as they are seen and removed ones stay out until
/// "Restore the public list".
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../network.dart' show EpicboxRelay;
import '../../server_list.dart';
import '../../server_list_file.dart';
import '../../settings_file/settings_providers.dart';
import 'models.dart';

export '../../server_list.dart';

/// What a list is kept in step with.
@immutable
class DeskServerSource {
  const DeskServerSource({this.public = const [], this.own = const [], this.operators = const {}, this.inUse, this.keep = const []});

  /// The public servers in their order: the shipped ones first, then the directory's.
  final List<String> public;

  /// Servers the user added that the wallet knows of: listed as "Added by you" unless removed.
  final List<String> own;

  /// Who runs each public server, by [serverKeyOf]: written with a server the list takes in.
  final Map<String, String> operators;

  /// The server in use: always listed.
  final String? inUse;

  /// Servers that are always listed (a selection's chosen set), whatever the directory says.
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

  Future<void> _set(ServerList next, {Map<String, String> operators = const {}}) async {
    if (next == state) return;
    state = next;
    await ref.read(hostSettingsProvider.notifier).setAll(serverListValues(ref.read(hostSettingsProvider), kind, next, operators: operators));
  }

  /// Adds the directory's servers not yet seen (removed ones stay out) and the server in use.
  /// Nothing is written when nothing changed.
  Future<void> sync(DeskServerSource s) async {
    var list = (state ?? const ServerList()).absorb(kind, s.public);
    final inUse = s.inUse;
    if (inUse != null && inUse.isNotEmpty && !list.has(kind, inUse)) list = list.add(kind, inUse);
    for (final v in s.keep) {
      if (!list.has(kind, v)) list = list.add(kind, v);
    }
    for (final v in s.own) {
      if (!list.has(kind, v) && !list.removed.contains(serverKeyOf(kind, v))) list = list.add(kind, v, own: true);
    }
    try {
      await _set(list, operators: s.operators);
    } on Object catch (e) {
      // Runs by itself when a panel opens: a file that cannot be written (a read-only or
      // full disk) keeps the list shown and says so in the log, never as an uncaught error
      // (WIN-4). The user's own changes still report their failure.
      logWarn('desk', 'server list not saved: ${e.runtimeType}');
    }
  }

  Future<void> add(String value, {int? at, bool own = false}) async => _set((state ?? const ServerList()).add(kind, value, at: at, own: own));

  /// Takes [value] out and returns where it was, for Undo.
  Future<int?> remove(String value) async {
    final r = (state ?? const ServerList()).remove(kind, value);
    await _set(r.list);
    return r.at;
  }

  /// Forgets every removal and puts the [public] servers back.
  Future<void> restore(Iterable<String> public) async => _set(restoreRemoved(kind, state ?? const ServerList(), public));
}
