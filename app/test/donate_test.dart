// SPDX-License-Identifier: Apache-2.0
// An old [donate] table in settings.toml is left alone.
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

void main() {
  test('a [donate] table from an earlier build is not reported as unknown', () {
    final read = readSettings('[donate]\npage = "https://donate.lab.invalid/"\ncontact = "https://contact.lab.invalid/"\n', shipped: testSettings());
    expect(read.unknown, isEmpty);
    expect(read.issues, isEmpty);
  });
}
