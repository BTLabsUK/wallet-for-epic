// SPDX-License-Identifier: Apache-2.0
// Every GitHub Action a workflow uses is pinned to a full commit SHA: a moved tag cannot change
// what runs with the workflow's secrets (the Apple build holds LEPIC deploy keys). No Dependabot
// keeps them current, as it would open pull requests on the published copies; a version moves
// by hand, with its new SHA and the tag in a comment.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workflow actions are pinned by commit', () {
    final dir = Directory('../.github/workflows');
    // The public tree has no hosted workflows (builds and tests run on our own machines).
    if (!dir.existsSync()) return markTestSkipped('no workflows in this tree');
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'));
    expect(files, isNotEmpty);
    final uses = RegExp(r'^\s*(?:-\s*)?uses:\s*([^\s#]+)', multiLine: true);
    for (final f in files) {
      for (final m in uses.allMatches(f.readAsStringSync())) {
        final ref = m[1]!;
        if (ref.startsWith('./') || ref.startsWith('docker://')) continue;
        expect(ref, matches(RegExp(r'@[0-9a-f]{40}$')), reason: '${f.path}: $ref');
      }
    }
  });
}
