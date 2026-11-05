// SPDX-License-Identifier: Apache-2.0
// The explorer check on Copy: the explorer's own record says whether it has reached a block;
// anything else is no answer, and nothing is said.

import 'dart:async';

import 'package:epic_wallet/src/explorer_check.dart';
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final asked = <Uri>[];
  Future<HttpReply> Function(Uri) answer(int status, String body) => (url) async {
        asked.add(url);
        return HttpReply(status, body);
      };

  setUp(asked.clear);

  test('a block the explorer has: its record answers status 200', () async {
    expect(await explorerHasBlock(3781000, get: answer(200, '{"status":200,"message":"fetched","response":{}}')), ExplorerHas.block);
    expect(asked.single.toString(), hostSettings.explorerIndexed(3781000));
  });

  test('a block it has not reached: HTTP 200 with its own 404 "No Data Found"', () async {
    expect(await explorerHasBlock(3784006, get: answer(200, '{"status":404,"message":"No Data Found","error":{}}')), ExplorerHas.notYet);
  });

  test('a plain HTTP 404 is not there yet either', () async {
    expect(await explorerHasBlock(1, get: answer(404, '')), ExplorerHas.notYet);
  });

  test('a failure, an error page or an unknown body is no answer', () async {
    expect(await explorerHasBlock(1, get: answer(502, 'Bad gateway')), ExplorerHas.unknown);
    expect(await explorerHasBlock(1, get: answer(200, '<html>')), ExplorerHas.unknown);
    expect(await explorerHasBlock(1, get: answer(200, '{"status":500}')), ExplorerHas.unknown);
    expect(await explorerHasBlock(1, get: (_) async => throw const NetError(netModeError)), ExplorerHas.unknown);
    expect(await explorerHasBlock(1, get: (_) async => throw TimeoutException('slow')), ExplorerHas.unknown);
  });

  test('no record address configured: nothing is asked', () async {
    final saved = hostSettings;
    addTearDown(() => hostSettings = saved);
    hostSettings = saved.withValues({'explorer.indexed': ''});
    expect(await explorerHasBlock(1, get: answer(200, '{"status":200}')), ExplorerHas.unknown);
    expect(asked, isEmpty);
  });
}
