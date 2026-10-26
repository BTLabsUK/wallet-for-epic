// The pairing word table is LEPIC's (`testdata/sas/emoji-v1.txt`): the app's copy must match
// the pinned clone entry for entry, or typed pairing words a LEPIC wallet shows are refused.
// Skipped without the clone (tools/lepic.sh sync).
import 'dart:io';

import 'package:epic_wallet/src/pairing_text.dart';
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

  group('pasted pairing words', () {
    final five = [sasTable[0], sasTable[1], sasTable[2], sasTable[0], sasTable[255]];
    final names = five.map((w) => w.name).toList();

    test('a copy is the names alone, and reads back as them', () {
      expect(pairingWordsText(five), names.join(' '));
      expect(pairingWordParts(pairingWordsText(five)), names);
    });

    test('words with their emoji, as the old copy put them: one word each', () {
      expect(pairingWordParts(five.map((w) => '${w.emoji} ${w.name}').join('  ')), names);
      expect(pairingWordParts(five.map((w) => '${w.name} ${w.emoji}').join(' ')), names);
      expect(pairingWordParts(five.map((w) => '${w.emoji}${w.name}').join()), names);
    });

    test('emoji alone, a mix, case, punctuation, new lines and extra spaces', () {
      expect(pairingWordParts(five.map((w) => w.emoji).join()), names);
      expect(pairingWordParts(five.map((w) => '${w.emoji}\u{FE0F}').join(' ')), names);
      final mixed = '${five[0].emoji}, ${five[1].name.toUpperCase()}.\n\n  ${five[2].emoji} ${five[2].name} · '
          '${five[3].name}; ${five[4].emoji}!';
      expect(pairingWordParts(mixed), names);
    });

    test('the same word twice stays twice; an unknown word stays as typed', () {
      expect(pairingWordParts('${five[0].name} ${five[0].name}'), [names[0], names[0]]);
      expect(pairingWordParts('${five[0].emoji} ${five[0].emoji}'), [names[0], names[0]]);
      expect(pairingWordParts('${five[0].emoji} ${five[0].name} ${five[0].emoji} ${five[0].name}'), [names[0], names[0]]);
      expect(pairingWordParts('${five[0].name} kitt'), [names[0], 'kitt']);
    });
  });
}
