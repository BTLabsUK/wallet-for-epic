/// The Node and Epicbox lists the phone and the desktop share: one editable list per kind,
/// seeded from the built-in servers and status.btlabs.uk, then the user's.
///
/// A list is its [ServerList.entries] (values in list order: a node URL or a relay label) and
/// [ServerList.removed] (keys of public servers the user took out, so a directory update does
/// not bring them back until "Restore removed servers"). Nothing here reads or writes a store
/// or the network: each app keeps its list where it keeps its settings.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable, listEquals, setEquals;

import 'network.dart' show EpicboxRelay;
import 'public_servers.dart' show nodeKey;
import 'relay_directory.dart' show ServerIcon;

/// A list's kind: nodes or Epicbox relays.
enum ServerKind { node, relay }

/// The picker's selection mode: a set of up to [limit] servers, ticked in the list, for a
/// setting that uses several servers at once (Connection servers, limit 3; the linked devices'
/// Servers, limit 2). `null` where a picker takes one server, as the Node and Epicbox settings do.
///
/// The picker keeps the set itself while open, starting from [chosen]; every tick, untick,
/// reset and Undo calls [onChanged] with the whole new set (list values).
@immutable
class RelaySelection {
  const RelaySelection({
    required this.limit,
    required this.chosen,
    required this.defaults,
    required this.onChanged,
    required this.title,
    required this.note,
  });

  /// How many servers may be chosen at most; one always is.
  final int limit;

  /// The set now, as list values.
  final List<String> chosen;

  /// The set "Reset to defaults" restores, as list values; the list shows them first.
  final List<String> defaults;

  /// Called with the new set after every change.
  final void Function(List<String> chosen) onChanged;

  /// The picker's title ("Connection servers").
  final String title;

  /// The line under the field ("Choose up to 3.").
  final String note;
}

/// Why a tick was refused.
enum SelectionRefusal { keepOne, limit }

/// What a tick on [value] does to [chosen] in a selection with [limit]: the new set, or why not.
({List<String>? next, SelectionRefusal? refusal}) toggleSelection(ServerKind kind, List<String> chosen, String value, int limit) {
  final k = serverKeyOf(kind, value);
  final at = chosen.indexWhere((c) => serverKeyOf(kind, c) == k);
  if (at >= 0) {
    if (chosen.length <= 1) return (next: null, refusal: SelectionRefusal.keepOne);
    return (next: [...chosen]..removeAt(at), refusal: null);
  }
  if (chosen.length >= limit) return (next: null, refusal: SelectionRefusal.limit);
  return (next: [...chosen, value], refusal: null);
}

/// Whether [a] and [b] hold the same servers of [kind], in any order.
bool sameServerSet(ServerKind kind, Iterable<String> a, Iterable<String> b) =>
    setEquals({for (final v in a) serverKeyOf(kind, v)}, {for (final v in b) serverKeyOf(kind, v)});

/// The list in a selection's order: the defaults first (in the defaults' order), then the rest
/// in list order. Chosen rows keep their place.
List<T> selectionOrder<T>(ServerKind kind, List<T> rows, String Function(T) valueOf, List<String> defaults) {
  final keys = [for (final d in defaults) serverKeyOf(kind, d)];
  int rank(T r) {
    final i = keys.indexOf(serverKeyOf(kind, valueOf(r)));
    return i < 0 ? keys.length : i;
  }
  final out = [...rows];
  // A stable sort: equal ranks keep the list's order.
  final indexed = [for (var i = 0; i < out.length; i++) (i, out[i])];
  indexed.sort((a, b) => rank(a.$2) != rank(b.$2) ? rank(a.$2).compareTo(rank(b.$2)) : a.$1.compareTo(b.$1));
  return [for (final e in indexed) e.$2];
}

/// What makes two values the same server: `host:port` for nodes, the label for relays.
String serverKeyOf(ServerKind kind, String value) => kind == ServerKind.node
    ? (nodeKey(value) ?? value)
    : (EpicboxRelay.parse(value)?.label ?? value);

/// Whether [a] and [b] are the same server of [kind].
bool sameServer(ServerKind kind, String a, String b) =>
    serverKeyOf(kind, a) == serverKeyOf(kind, b);

/// One kind's list: the values in their order, and the keys of public servers the user removed.
@immutable
class ServerList {
  const ServerList({this.entries = const [], this.removed = const {}, this.added = const {}});

  final List<String> entries;
  final Set<String> removed;

  /// Keys of the servers the user typed in ("Added by you"), as opposed to built-in and
  /// directory servers. A server the directory lists is not one any more ([absorb]). Lists
  /// stored before this existed hold none.
  final Set<String> added;

  /// Whether the user typed [value] in.
  bool isAddedByUser(ServerKind kind, String value) => added.contains(serverKeyOf(kind, value));

  /// The list a first use starts with: [builtIn] in its order, then [carried] (what an older
  /// version's own list held), one row per server.
  factory ServerList.seed(
    ServerKind kind,
    Iterable<String> builtIn, {
    Iterable<String> carried = const [],
  }) {
    final list = const ServerList().absorb(kind, [...builtIn, ...carried]);
    // What an older version's own list held was typed in by the user.
    final own = {for (final v in carried) serverKeyOf(kind, v)}..removeAll([for (final v in builtIn) serverKeyOf(kind, v)]);
    return own.isEmpty ? list : ServerList(entries: list.entries, removed: list.removed, added: own);
  }

  /// A stored list, or null when [raw] is missing or broken (the caller seeds again).
  static ServerList? decode(String? raw) {
    if (raw == null) return null;
    try {
      final d = jsonDecode(raw);
      if (d is! Map) return null;
      return ServerList(
        entries: [
          if (d['entries'] is List)
            for (final e in d['entries'] as List)
              if (e is String && e.isNotEmpty) e,
        ],
        removed: {
          if (d['removed'] is List)
            for (final e in d['removed'] as List)
              if (e is String && e.isNotEmpty) e,
        },
        added: {
          if (d['added'] is List)
            for (final e in d['added'] as List)
              if (e is String && e.isNotEmpty) e,
        },
      );
    } on FormatException {
      return null;
    }
  }

  String encode() => jsonEncode({
    'entries': entries,
    'removed': [...removed],
    if (added.isNotEmpty) 'added': [...added],
  });

  bool has(ServerKind kind, String value) {
    final k = serverKeyOf(kind, value);
    return entries.any((e) => serverKeyOf(kind, e) == k);
  }

  /// Directory servers seen now: those neither listed nor removed join the end, in order.
  ServerList absorb(ServerKind kind, Iterable<String> public) {
    final out = [...entries];
    final keys = {for (final e in entries) serverKeyOf(kind, e)};
    for (final v in public) {
      final k = serverKeyOf(kind, v);
      if (removed.contains(k) || !keys.add(k)) continue;
      out.add(v);
    }
    // A server the directory lists is public, whoever typed it in first.
    final publicKeys = {for (final v in public) serverKeyOf(kind, v)};
    final stillAdded = {for (final a in added) if (!publicKeys.contains(a)) a};
    if (listEquals(out, entries) && setEquals(stillAdded, added)) return this;
    return ServerList(entries: out, removed: removed, added: stillAdded);
  }

  /// [public] values not yet in the list and not removed: what [absorb] would add.
  List<String> missing(ServerKind kind, Iterable<String> public) => [
    for (final v in public)
      if (!has(kind, v) && !removed.contains(serverKeyOf(kind, v))) v,
  ];

  /// Adds [value] at [at] (else last); its key leaves [removed], so it stays. A listed server
  /// leaves the list as it is. [own] marks a server the user typed in ("Added by you").
  ServerList add(ServerKind kind, String value, {int? at, bool own = false}) {
    final k = serverKeyOf(kind, value);
    if (has(kind, value)) return this;
    final out = [...entries];
    out.insert(at == null ? out.length : at.clamp(0, out.length), value);
    return ServerList(entries: out, removed: {...removed}..remove(k), added: own ? {...added, k} : added);
  }

  /// Takes [value] out and remembers its key as removed. [at] is where it was, for Undo;
  /// null when it was not listed.
  ({ServerList list, int? at}) remove(ServerKind kind, String value) {
    final k = serverKeyOf(kind, value);
    final i = entries.indexWhere((e) => serverKeyOf(kind, e) == k);
    if (i < 0) return (list: this, at: null);
    // [added] keeps the key, so Undo brings the badge back.
    return (list: ServerList(entries: [...entries]..removeAt(i), removed: {...removed, k}, added: added), at: i);
  }

  /// The [public] servers the user removed: "Restore removed servers" shows while any is.
  List<String> restorable(ServerKind kind, Iterable<String> public) => [
    for (final v in public)
      if (removed.contains(serverKeyOf(kind, v)) && !has(kind, v)) v,
  ];

  /// Forgets every removal and puts the [public] servers back at the end, in their order.
  ServerList restore(ServerKind kind, Iterable<String> public) {
    final back = ServerList(entries: entries, added: added).absorb(kind, public);
    if (listEquals(back.entries, entries) && setEquals(removed, const {}) && setEquals(back.added, added)) return this;
    return back;
  }

  @override
  bool operator ==(Object other) =>
      other is ServerList &&
      listEquals(other.entries, entries) &&
      setEquals(other.removed, removed) &&
      setEquals(other.added, added);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(entries), Object.hashAll(removed.toList()..sort()), Object.hashAll(added.toList()..sort()));
}

/// What the field at the top holds when Add is tapped: the value as the list stores it, or
/// null when it is not a server address ("Not a server address. Use host or host:port.").
///
/// A node is `host` or `host:port` (https unless `http://` is typed; a host needs a dot unless
/// it has a port); a relay is `host` or `host:port`, with a `wss://` or `https://` in front
/// dropped. Spaces, paths, queries and user names are refused.
String? typedServerValue(ServerKind kind, String text) =>
    kind == ServerKind.node ? typedNodeUrl(text) : typedRelayLabel(text);

/// A typed node address as the wallet stores it (`https://host[:port]`), or null.
String? typedNodeUrl(String text) {
  var t = text.trim();
  if (t.isEmpty || t.contains(' ')) return null;
  if (!t.contains('://')) t = 'https://$t';
  final u = Uri.tryParse(t);
  if (u == null ||
      (u.scheme != 'https' && u.scheme != 'http') ||
      u.host.isEmpty ||
      (!u.host.contains('.') && !u.hasPort) ||
      u.userInfo.isNotEmpty ||
      u.hasQuery ||
      (u.path.isNotEmpty && u.path != '/')) {
    return null;
  }
  return u.hasPort
      ? '${u.scheme}://${u.host.toLowerCase()}:${u.port}'
      : '${u.scheme}://${u.host.toLowerCase()}';
}

/// A typed relay as the list stores it (its label: `host`, or `host:port` off 443), or null.
String? typedRelayLabel(String text) {
  var t = text.trim().replaceFirst(RegExp(r'^(wss|https)://', caseSensitive: false), '');
  if (t.endsWith('/')) t = t.substring(0, t.length - 1);
  final relay = EpicboxRelay.parse(t);
  if (relay == null) return null;
  final host = relay.host;
  if (host.startsWith('.') || host.endsWith('.') || host.contains('..')) return null;
  if (!host.contains('.') && !t.contains(':')) return null;
  return relay.label;
}

/// Whether a row matches what is typed: the host, or the operator's name. A typed scheme is
/// ignored, so a pasted `https://node…` still finds its row.
bool serverMatches(String query, {required String host, String? operator}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final needle = q.replaceFirst(RegExp(r'^[a-z]+://'), '').replaceFirst(RegExp(r'/+$'), '');
  return host.toLowerCase().contains(needle) || (operator ?? '').toLowerCase().contains(q);
}

/// The initials a tile shows when the operator has no icon: two letters from the first two
/// words of the operator's name (a camel-cased name splits), or the first two of a one-word
/// name; without a name, the first two of the host's first label past `node.`, `epicbox.` or
/// `www.`.
String serverInitials(String? operator, String host) {
  final name = (operator ?? '').trim();
  if (name.isNotEmpty) {
    final words = name
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .split(RegExp(r'[\s\-_.]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
    if (words.length == 1) {
      final w = words[0];
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
  }
  final labels = host
      .replaceFirst(RegExp(r'^[a-z]+://'), '')
      .split(':')
      .first
      .split('.')
      .where((p) => p.isNotEmpty && !const {'node', 'epicbox', 'www'}.contains(p))
      .toList();
  if (labels.isEmpty) return '?';
  final w = labels.first;
  return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
}

/// The icon for a row: the server's own from the monitor, else one the monitor holds for
/// another server of the same operator (spaces, dots and case aside), else null.
/// [known] is every (operator, icon) the monitor listed, nodes and relays alike.
ServerIcon? serverIconFor(
  ServerIcon? own,
  String? operator,
  Iterable<({String? operator, ServerIcon? icon})> known,
) {
  if (own != null) return own;
  final name = _operatorKey(operator);
  if (name.isEmpty) return null;
  for (final k in known) {
    if (k.icon != null && _operatorKey(k.operator) == name) return k.icon;
  }
  return null;
}

/// An operator's name for matching: letters and digits only, lower case, so the app's "BT Labs"
/// is the monitor's "btlabs".
String _operatorKey(String? name) =>
    (name ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
