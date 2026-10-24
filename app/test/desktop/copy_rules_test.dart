// The copy sweep (W4 spec 11, P2): no user-facing string in the desktop UI says "listener",
// "the relay", "Epic address" (it is the Epicbox address), or "Advanced" next to Tor. "Link"
// is a method name again since the one Tor switch (Epicbox / Link / File). Reads every .dart file under lib/src/desktop; comments and log
// lines (internal tags) do not count. No allow-list.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _literal = RegExp(r"'((?:[^'\\]|\\.)*)'" r'|"((?:[^"\\]|\\.)*)"');
final _log = RegExp(r'\blog(Info|Warn|Error|Debug)\(');

void main() {
  test('no banned words in the desktop UI copy', () {
    final hits = <String>[];
    final files = Directory('lib/src/desktop').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final t = line.trimLeft();
        if (t.startsWith('//') || t.startsWith('*') || t.startsWith('import ') || t.startsWith('export ') || _log.hasMatch(line)) continue;
        for (final m in _literal.allMatches(line)) {
          final s = m.group(1) ?? m.group(2) ?? '';
          final lower = s.toLowerCase();
          String? why;
          if (lower.contains('listener')) {
            why = 'listener';
          } else if (lower.contains('the relay')) {
            why = 'the relay';
          } else if (s.contains('Epic address')) {
            why = 'Epic address';
          } else if (s.contains('Advanced')) {
            final at = line.indexOf('Advanced');
            final around = [for (var j = i - 1; j <= i + 1; j++) if (j >= 0 && j < lines.length) lines[j]].join(' ');
            final from = (around.indexOf(line) + at - 80).clamp(0, around.length);
            final to = (around.indexOf(line) + at + 88).clamp(0, around.length);
            if (around.substring(from, to).contains('Tor')) why = 'Advanced next to Tor';
          }
          if (why != null) hits.add('${f.path}:${i + 1}: $why: $s');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
