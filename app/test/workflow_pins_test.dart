// SPDX-License-Identifier: Apache-2.0
// No GitHub Actions: builds and tests run on our own machines, and nothing reaches Tor, an onion,
// or a node from GitHub. A hosted workflow would also run with the repository's secrets. Should
// one ever come back, pin every action it uses by full commit SHA (a moved tag cannot change what
// runs) and replace this test with that check.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the tree has no hosted workflows', () {
    final dir = Directory('../.github/workflows');
    final files = dir.existsSync() ? dir.listSync().whereType<File>().map((f) => f.path).toList() : <String>[];
    expect(files, isEmpty);
  });
}
