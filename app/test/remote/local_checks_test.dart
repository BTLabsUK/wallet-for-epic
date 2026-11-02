// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/remote/local_checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('local checks', () {
    test('mnemonic checksum, word count and words, as BIP-39', () {
      final abandon = List.filled(11, 'abandon');
      expect(validMnemonic([...abandon, 'about'].join(' ')), true);
      expect(
        validMnemonic('${List.filled(23, 'abandon').join(' ')} art'),
        true,
      );
      expect(validMnemonic('${List.filled(11, 'zoo').join(' ')} wrong'), true);
      expect(
        validMnemonic(
          '  Abandon\t${[...abandon.skip(1), 'ABOUT'].join('  ')} ',
        ),
        true,
      );
      expect(validMnemonic([...abandon, 'abandon'].join(' ')), false);
      expect(validMnemonic([...abandon, 'zzzz'].join(' ')), false);
      expect(validMnemonic(List.filled(23, 'abandon').join(' ')), false);
      expect(validMnemonic(List.filled(27, 'abandon').join(' ')), false);
      expect(validMnemonic(''), false);
    });
  });
}
