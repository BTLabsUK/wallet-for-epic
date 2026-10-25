// The pairing word table is LEPIC's (`testdata/sas/emoji-v1.txt`): the app's copy must match
// the pinned clone entry for entry, or typed pairing words a LEPIC wallet shows are refused.
// Skipped without the clone (tools/lepic.sh sync).
import 'dart:io';

import 'package:epic_wallet/src/sas_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final file = File('third_party/lepic/testdata/sas/emoji-v1.txt');

  test('the word table is the pinned LEPIC table', () {
    final lepic = [
      for (final line in file.readAsLinesSync())
        if (line.trim().isNotEmpty && !line.startsWith('#')) line.split('\t'),
    ];
    expect(lepic, hasLength(256));
    expect(sasTable, hasLength(256));
    for (var i = 0; i < 256; i++) {
      expect((sasTable[i].emoji, sasTable[i].name), (lepic[i][0], lepic[i][1]), reason: 'entry $i');
    }
    // Every name resolves, as Enter link or words looks it up.
    for (final w in lepic) {
      expect(sasWordNamed(w[1])?.emoji, w[0]);
    }
  }, skip: file.existsSync() ? false : 'needs the LEPIC clone (tools/lepic.sh sync)');
}
