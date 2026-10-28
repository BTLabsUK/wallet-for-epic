// SPDX-License-Identifier: Apache-2.0
/// Demos on disk: `<root>/demos/<id>/` with `demo.json`, the wallet and its secret store.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// A demo: a random id, when it started and when it ends.
class DemoRecord {
  const DemoRecord({
    required this.id,
    required this.created,
    required this.expires,
  });

  /// 64 lowercase hex characters from a CSPRNG. Only [shortDemoId] of it is ever logged.
  final String id;
  final DateTime created;
  final DateTime expires;

  bool expiredAt(DateTime now) => !now.isBefore(expires);

  Map<String, Object?> toJson() => {
    'version': 1,
    'created': created.toUtc().millisecondsSinceEpoch,
    'expires': expires.toUtc().millisecondsSinceEpoch,
  };

  /// Null when [json] is not a `demo.json` this server wrote.
  static DemoRecord? fromJson(String id, Object? json) {
    if (json is! Map<String, Object?> || json['version'] != 1) return null;
    final created = json['created'];
    final expires = json['expires'];
    if (created is! int || expires is! int || expires < created) return null;
    return DemoRecord(
      id: id,
      created: DateTime.fromMillisecondsSinceEpoch(created, isUtc: true),
      expires: DateTime.fromMillisecondsSinceEpoch(expires, isUtc: true),
    );
  }
}

final RegExp _demoId = RegExp(r'^[0-9a-f]{64}$');

/// True for an id this server could have made.
bool isDemoId(String text) => _demoId.hasMatch(text);

/// The part of a demo id logs may show.
String shortDemoId(String id) => id.length <= 8 ? id : id.substring(0, 8);

/// A fresh id: 32 bytes from [Random.secure], as hex.
String newDemoId([Random? random]) {
  final r = random ?? Random.secure();
  return [
    for (var i = 0; i < 32; i++)
      r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// Sets POSIX permissions. dart:io has no chmod, so this runs the system's.
Future<void> chmod(String mode, String path) async {
  if (Platform.isWindows) return;
  final r = await Process.run('chmod', [mode, path]);
  if (r.exitCode != 0) {
    throw FileSystemException('chmod $mode failed: ${r.stderr}', path);
  }
}

/// Writes [text] to [path] through a temporary file and a rename, so a reader never sees half
/// of it. [mode], when set, is applied before the rename.
Future<void> writeAtomic(String path, String text, {String? mode}) async {
  final tmp = File('$path.tmp');
  await tmp.writeAsString(text, flush: true);
  if (mode != null) await chmod(mode, tmp.path);
  await tmp.rename(path);
}

class DemoStore {
  DemoStore(this.root);

  /// The server's data root.
  final String root;

  String get demosDir => '$root/demos';

  String dirOf(String id) => '$demosDir/$id';

  /// The wallet's data directory, given to every wallet call of the demo.
  String walletDirOf(String id) => '${dirOf(id)}/wallet';

  /// The demo's secret store file (`FileSecretStore`).
  String secretsOf(String id) => '${dirOf(id)}/secrets.json';

  String _recordOf(String id) => '${dirOf(id)}/demo.json';

  /// Creates the data root, readable by this user only.
  Future<void> prepare() async {
    await Directory(demosDir).create(recursive: true);
    await chmod('700', root);
    await chmod('700', demosDir);
  }

  /// Makes a demo directory and its `demo.json`.
  Future<DemoRecord> create({
    required DateTime now,
    required Duration ttl,
  }) async {
    String id;
    do {
      id = newDemoId();
    } while (await Directory(dirOf(id)).exists());
    final record = DemoRecord(
      id: id,
      created: now.toUtc(),
      expires: now.add(ttl).toUtc(),
    );
    await Directory(walletDirOf(id)).create(recursive: true);
    await chmod('700', dirOf(id));
    await writeAtomic(_recordOf(id), jsonEncode(record.toJson()), mode: '600');
    return record;
  }

  /// Removes a demo's directory and everything in it.
  Future<void> remove(String id) async {
    if (!isDemoId(id)) throw ArgumentError.value(id, 'id', 'not a demo id');
    final dir = Directory(dirOf(id));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// The live demos on disk. Removes, first, every expired demo and every entry that is not a
  /// directory named by a demo id holding a valid `demo.json`. Returns how many it removed with
  /// the live ones.
  Future<({List<DemoRecord> live, int removed})> loadAndPurge(
    DateTime now,
  ) async {
    final live = <DemoRecord>[];
    var removed = 0;
    final dir = Directory(demosDir);
    if (!await dir.exists()) return (live: live, removed: 0);
    await for (final entry in dir.list(followLinks: false)) {
      final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      final record = entry is Directory && isDemoId(name)
          ? await _read(name)
          : null;
      if (record != null && !record.expiredAt(now)) {
        live.add(record);
        continue;
      }
      await entry.delete(recursive: true);
      removed++;
    }
    return (live: live, removed: removed);
  }

  Future<DemoRecord?> _read(String id) async {
    try {
      return DemoRecord.fromJson(
        id,
        jsonDecode(await File(_recordOf(id)).readAsString()),
      );
    } on Object {
      return null;
    }
  }
}
