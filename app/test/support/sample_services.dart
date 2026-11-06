// SPDX-License-Identifier: Apache-2.0
// A made-up service file for the tests of the hooks. No test of app code reads the bundled
// files: the app works the same with none.
import 'package:epic_wallet/src/services/service_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const String sampleRelay = 'epicbox.exchange.invalid';

const String sampleServiceFile = '''
{
  "schema": 1,
  "id": "sample-exchange",
  "rules": [
    { "kind": "relay_needs_note", "relay": "$sampleRelay", "hint": "exchange_check_note" }
  ]
}
''';

/// The sample file as the rules in use, for this test.
void useSampleServices() {
  serviceRules = ServiceRules.from([parseServiceFile(sampleServiceFile)]);
  addTearDown(() => serviceRules = ServiceRules.none);
}
