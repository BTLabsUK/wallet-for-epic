// SPDX-License-Identifier: Apache-2.0
/// What this wallet keeps of its contacts' relay moves (`relay_moves.dart`), apart from the
/// rules so the meta file reads it without Flutter.
library;

/// One move this wallet made: contact [id] went from relay [from] to [to] at [at] (Unix ms).
class RelayMoveRec {
  const RelayMoveRec({required this.id, required this.from, required this.to, required this.at});

  factory RelayMoveRec.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('relay move');
    final id = json['id'], from = json['from'], to = json['to'], at = json['at'];
    if (id is! String || from is! String || to is! String || at is! int) throw const FormatException('relay move');
    return RelayMoveRec(id: id, from: from, to: to, at: at);
  }

  final String id;
  final String from;
  final String to;
  final int at;

  Map<String, Object?> toJson() => {'id': id, 'from': from, 'to': to, 'at': at};

  @override
  bool operator ==(Object other) => other is RelayMoveRec && other.id == id && other.from == from && other.to == to && other.at == at;

  @override
  int get hashCode => Object.hash(id, from, to, at);
}

/// The moves made, and the asked moves the user saw or refused, by `"<pairing id> <relay>"`
/// ([relayMoveKey]). The meta file holds it under one key, `relay_moves`, with its version; a
/// file without the key has nothing recorded. Written only when not empty, and not part of a
/// history file.
class RelayMoveBook {
  RelayMoveBook({List<RelayMoveRec>? moved, Iterable<String>? shown, Iterable<String>? refused})
    : moved = moved ?? [],
      shown = {...?shown},
      refused = {...?refused};

  /// The version [toJson] writes. A later one is read as far as it goes.
  static const int version = 1;

  factory RelayMoveBook.fromJson(Object? json) {
    if (json == null) return RelayMoveBook();
    if (json is! Map) throw const FormatException('relay_moves');
    List<Object?> list(String key) => switch (json[key]) {
      null => const [],
      final List<Object?> l => l,
      _ => throw FormatException('relay_moves $key'),
    };
    Iterable<String> strings(String key) => [
      for (final v in list(key)) v is String ? v : throw FormatException('relay_moves $key'),
    ];
    return RelayMoveBook(
      moved: [for (final m in list('moved')) RelayMoveRec.fromJson(m)],
      shown: strings('shown'),
      refused: strings('refused'),
    );
  }

  /// Moves made, oldest first; [MoveLog.recordMove] drops those past [relayMoveKeptFor].
  final List<RelayMoveRec> moved;

  /// Requests a domain-backed contact made that the dialog or sheet showed once.
  final Set<String> shown;

  /// Requests the user refused: never asked again; a move to another relay asks again.
  final Set<String> refused;

  bool get isEmpty => moved.isEmpty && shown.isEmpty && refused.isEmpty;

  Map<String, Object?> toJson() => {
    'v': version,
    if (moved.isNotEmpty) 'moved': [for (final m in moved) m.toJson()],
    if (shown.isNotEmpty) 'shown': [...shown],
    if (refused.isNotEmpty) 'refused': [...refused],
  };

  /// Adds what [other] holds and this lacks.
  void addAll(RelayMoveBook other) {
    for (final m in other.moved) {
      if (!moved.contains(m)) moved.add(m);
    }
    moved.sort((a, b) => a.at.compareTo(b.at));
    shown.addAll(other.shown);
    refused.addAll(other.refused);
  }

  /// Records that [id] moved from [from] to [to] at [at] (Unix ms), and drops moves older
  /// than [relayMoveKeptFor].
  void recordMove(String id, String from, String to, int at) {
    moved.add(RelayMoveRec(id: id, from: from, to: to, at: at));
    moved.removeWhere((m) => m.at <= at - relayMoveKeptFor.inMilliseconds);
  }
}

/// How long a move is kept: the "Moved here on" line shows for as long.
const Duration relayMoveKeptFor = Duration(days: 30);

/// The key of the move of pairing [id] to [relay] in [RelayMoveBook.shown] and
/// [RelayMoveBook.refused]. [relay] is written as the list stores it (`host`, or `host:port`).
String relayMoveKey(String id, String relay) => '$id $relay';

/// Where the moves are kept. [MetaMoveLog] (`wallet_history.dart`) holds them in the wallet's
/// meta file; [MemoryMoveLog] stands in for tests and the fake.
abstract class MoveLog {
  RelayMoveBook get book;

  Future<void> recordMove(String id, String from, String to, DateTime at);

  Future<void> markShown(String id, String relay);

  Future<void> refuse(String id, String relay);
}

class MemoryMoveLog implements MoveLog {
  MemoryMoveLog([RelayMoveBook? book]) : book = book ?? RelayMoveBook();

  @override
  final RelayMoveBook book;

  @override
  Future<void> recordMove(String id, String from, String to, DateTime at) async => book.recordMove(id, from, to, at.millisecondsSinceEpoch);

  @override
  Future<void> markShown(String id, String relay) async => book.shown.add(relayMoveKey(id, relay));

  @override
  Future<void> refuse(String id, String relay) async => book.refused.add(relayMoveKey(id, relay));
}
