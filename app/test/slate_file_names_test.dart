import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/slate_files.dart';

void main() {
  const uuid = '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d';

  test('names use the first 8 characters of the slate id', () {
    expect(sendFileName(uuid), '0a1b2c3d.tx');
    expect(responseFileName(uuid), '0a1b2c3d.response');
    expect(sendFileName('slate-1'), 'slate-1.tx');
  });

  test('a taken name gets -2, -3 before the suffix', () {
    final taken = <String>{};
    String next(String name) {
      final n = uniqueFileName(name, taken.contains);
      taken.add(n);
      return n;
    }

    expect(next('ab12cd34.response'), 'ab12cd34.response');
    expect(next('ab12cd34.response'), 'ab12cd34-2.response');
    expect(next('ab12cd34.response'), 'ab12cd34-3.response');
    expect(next('ab12cd34.tx'), 'ab12cd34.tx');
    expect(next('plain'), 'plain');
    expect(next('plain'), 'plain-2');
  });

  test('reading never looks at the file name', () {
    final json = utf8.encode('{"id":"x"}');
    // decodeSlateFile takes bytes only; any name picked is accepted, content decides.
    expect(decodeSlateFile(json), '{"id":"x"}');
    expect(() => decodeSlateFile(utf8.encode('hello.tx')), throwsA(anything));
  });
}
