// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/last_session.dart';
import 'package:flutter_test/flutter_test.dart';

ExitAnswer _android(String? reason, {int at = 2000, String? trace}) => (
  supported: true,
  exit: reason == null ? null : AndroidExit(reason: reason, timestamp: at, description: 'Input dispatching timed out', trace: trace),
);

void main() {
  late Directory logs;
  setUp(() => logs = Directory.systemTemp.createTempSync('last_session_test'));
  tearDown(() => logs.deleteSync(recursive: true));

  File marker() => File('${logs.path}/$sessionMarkerName');

  LastSession session({ExitAnswer? exits, List<int>? asked}) => LastSession(
    logs,
    exits: (since) async {
      asked?.add(since);
      return exits;
    },
    now: () => DateTime.utc(2026, 10, 31, 22),
  );

  Future<void> begin(LastSession s, {String log = 'last line\n'}) => s.begin(
    log: () async => log,
    ring: () async => [(name: 'lepic.0.log', text: 'ring line\n')],
    version: '26.10.26',
  );

  group('judgeLastSession', () {
    test('the marker alone decides where Android keeps no record', () {
      expect(judgeLastSession(markerLeft: false), isNull);
      expect(judgeLastSession(markerLeft: true)?.end, LastSessionEnd.closed);
      expect(judgeLastSession(markerLeft: true, exits: (supported: false, exit: null))?.cause, 'not closed');
    });

    test('Android 11+: only an ANR or a crash counts, whatever the marker says', () {
      expect(judgeLastSession(markerLeft: false, exits: _android('anr'))?.end, LastSessionEnd.froze);
      expect(judgeLastSession(markerLeft: false, exits: _android('crash'))?.end, LastSessionEnd.closed);
      expect(judgeLastSession(markerLeft: false, exits: _android('native'))?.cause, 'native crash');
      // An update, the user or the system ending the app is no incident.
      expect(judgeLastSession(markerLeft: true, exits: _android('other')), isNull);
      expect(judgeLastSession(markerLeft: true, exits: _android(null)), isNull);
    });
  });

  test('a clean end leaves nothing to offer', () async {
    final first = session();
    await begin(first);
    expect(marker().existsSync(), isTrue);
    first.clean();
    expect(marker().existsSync(), isFalse);
    final next = session();
    await begin(next);
    expect(next.due, isFalse);
    expect(await next.read(), isNull);
  });

  test('a session that never closed keeps its log, offered once', () async {
    await begin(session());
    // Killed: no clean().
    final next = session();
    await begin(next, log: 'froze here\n');
    expect(next.due, isTrue);
    final kept = (await next.read())!;
    expect(kept.end, LastSessionEnd.closed);
    expect(kept.cause, 'not closed');
    expect(kept.version, '26.10.26');
    expect(kept.log, 'froze here\n');
    expect(kept.ring, [(name: 'lepic.0.log', text: 'ring line\n')]);
    expect(kept.trace, isNull);
    // This session runs.
    expect(marker().existsSync(), isTrue);

    next.offered();
    expect(next.due, isFalse);
    // The kept log stays readable for a report until the next incident.
    expect(await next.read(), isNotNull);
    next.clean();
    final third = session();
    await begin(third);
    expect(third.due, isFalse);
  });

  test('not offered yet (never unlocked): still due at the next clean start', () async {
    await begin(session());
    final next = session();
    await begin(next);
    next.clean();
    final third = session();
    await begin(third);
    expect(third.due, isTrue);
  });

  test('an Android ANR keeps the trace, and each end is judged once', () async {
    final asked = <int>[];
    final s = session(exits: _android('anr', at: 5000, trace: '"main" prio=5 tid=1 Blocked\n'), asked: asked);
    await begin(s);
    final kept = (await s.read())!;
    expect(kept.end, LastSessionEnd.froze);
    expect(kept.cause, 'anr');
    expect(kept.endedAt, DateTime.fromMillisecondsSinceEpoch(5000, isUtc: true));
    expect(kept.trace, contains('Input dispatching timed out'));
    expect(kept.trace, contains('"main" prio=5'));
    s.offered();
    // The next start asks only for ends after that one.
    final next = session(exits: _android(null), asked: asked);
    await begin(next);
    expect(asked, [0, 5000]);
    expect(next.due, isFalse);
  });

  test('a half-written marker still counts as a session', () async {
    marker().writeAsStringSync('{"star');
    final s = session();
    await begin(s);
    expect(s.due, isTrue);
  });
}
