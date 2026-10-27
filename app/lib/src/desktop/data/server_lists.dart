/// The desktop's Node and Epicbox lists ([ServerList], shared with the phone): one per kind on
/// the app's chain, kept in [DeskStore] (`desk.serverList.<kind>.<chain>`).
///
/// A first use seeds the list from the public servers the wallet lists (built-in, then
/// status.btlabs.uk's), what the old My nodes held and the server in use; the public servers
/// the old Settings › Node took out (`removedNodes`) start as removed. After that the
/// directory's new servers join as they are seen and removed ones stay out until "Restore the
/// public list".
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../network.dart' show EpicboxRelay;
import '../../server_list.dart';
import 'desk_node.dart';
import 'desk_store.dart';
import 'models.dart';

export '../../server_list.dart';

/// What a list is seeded with on first use, and kept in step with after.
@immutable
class DeskServerSource {
  const DeskServerSource({this.public = const [], this.carried = const [], this.removed = const {}, this.inUse});

  /// The public servers in their order: built-in first, then the directory's.
  final List<String> public;

  /// What an older version's own list held: joins the first list after [public].
  final List<String> carried;

  /// Keys of public servers an older version took out: they start removed.
  final Set<String> removed;

  /// The server in use: always listed.
  final String? inUse;
}

/// The node list's source: the wallet's public nodes and own nodes (the old My nodes), the old
/// `removedNodes`, and the node in use.
DeskServerSource nodeSource(List<NodeServer> nodes, {Set<String> removedNodes = const {}, String? inUse}) => DeskServerSource(
  public: [for (final n in nodes) if (!n.own) n.url],
  carried: [for (final n in nodes) if (n.own) n.url],
  removed: {for (final u in removedNodes) serverKeyOf(ServerKind.node, u)},
  inUse: inUse,
);

/// The relay list's source: the public relays and the one in use.
DeskServerSource relaySource(List<EpicboxServer> boxes, {String? inUse}) => DeskServerSource(
  public: [for (final b in boxes) relayLabel(b)],
  inUse: inUse,
);

/// A relay as the list stores it: `host`, or `host:port` off 443.
String relayLabel(EpicboxServer b) => EpicboxRelay(host: b.domain, port: b.port).label;

final deskServerListProvider = NotifierProvider.family<DeskServerListController, ServerList?, ServerKind>(DeskServerListController.new);

/// One kind's list: null until read from the store and seeded ([sync]).
class DeskServerListController extends Notifier<ServerList?> {
  DeskServerListController(this.kind);

  final ServerKind kind;
  late Future<ServerList?> _saved;

  String get _chain => ref.read(deskNodeProvider).chain.name;

  @override
  ServerList? build() {
    final store = ref.read(deskStoreProvider);
    _saved = store == null ? Future.value() : store.serverList(kind, _chain).catchError((Object _) => null);
    return null;
  }

  Future<void> _set(ServerList next) async {
    if (next == state) return;
    state = next;
    await ref.read(deskStoreProvider)?.saveServerList(kind, _chain, next);
  }

  /// Seeds the list on first use, then adds the directory's servers not yet seen (removed
  /// ones stay out) and the server in use. Nothing is written when nothing changed.
  Future<void> sync(DeskServerSource s) async {
    final saved = await _saved;
    var list = state ?? saved ?? ServerList(removed: s.removed).absorb(kind, [...s.public, ...s.carried]);
    list = list.absorb(kind, s.public);
    final inUse = s.inUse;
    if (inUse != null && inUse.isNotEmpty && !list.has(kind, inUse)) list = list.add(kind, inUse);
    try {
      await _set(list);
    } on Object catch (e) {
      // Runs by itself when a panel opens: a store that cannot be written (a read-only or
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
  Future<void> restore(Iterable<String> public) async => _set((state ?? const ServerList()).restore(kind, public));
}
