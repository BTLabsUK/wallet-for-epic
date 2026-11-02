// SPDX-License-Identifier: Apache-2.0
@TestOn('browser')
library;

import 'package:epic_wallet/src/app_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('log', () {
    test('the web log keeps lines in memory, redacted', () async {
      await startLogging();
      logInfo('w03', 'web log line');
      final tail = await AppLog.sink.tail(4096);
      expect(AppLog.sink, isA<MemoryLogSink>());
      expect(tail, contains('dart.w03: web log line'));
    });
  });
}
