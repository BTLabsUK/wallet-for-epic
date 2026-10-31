// SPDX-License-Identifier: Apache-2.0
// The tooltip rule (docs/audit/tooltips.md): every tooltip goes through the one wrapper per
// platform (lib/src/ui/tip.dart `Tip`, lib/src/desktop/widgets/tip.dart `ETip`) or a button's own
// `tooltip:`, and its look, width and timing come from the theme. Fails on a raw `Tooltip(` or a
// per-call timing or trigger anywhere else under lib/src. A line that must stay ends with
// `// tip-ok` and the reason.
//
//   flutter test test/tooltip_rule_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _wrappers = {'lib/src/ui/tip.dart', 'lib/src/desktop/widgets/tip.dart'};

final _raw = RegExp(r'(?<![\w.])Tooltip\(');
final _override = RegExp(r'\b(waitDuration|showDuration|exitDuration|triggerMode|TooltipTriggerMode)\b');

void main() {
  test('tooltips go through Tip / ETip, styled by the theme only', () {
    final found = <String>[];
    for (final f in Directory('lib/src').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || _wrappers.contains(path) || path.contains('/theme/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final code = line.split('//').first;
        if (line.trimRight().endsWith('// tip-ok') || line.contains('// tip-ok ')) continue;
        if (_raw.hasMatch(code) || _override.hasMatch(code)) found.add('$path:${i + 1}: ${line.trim()}');
      }
    }
    expect(found, isEmpty, reason: 'Use Tip / ETip (see lib/src/ui/tip.dart):\n${found.join('\n')}');
  });
}
