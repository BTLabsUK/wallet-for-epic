// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/feedback.dart';
import 'package:flutter_test/flutter_test.dart';

/// One real report to the support intake. Off unless WFE_SUPPORT_LIVE=1: each run is a report
/// in the developer's inbox. WFE_SUPPORT_LIVE_URL posts to another intake (a local one) instead
/// of https://support.btlabs.uk/v1/report.
void main() {
  test('sends one report to the live intake', () async {
    final id = await HttpOverrides.runWithHttpOverrides(() async {
      final report = buildFeedbackReport(
        message: 'TEST from wfe-01-fixes, ignore. Desktop Report a problem format check.',
        details: const FeedbackDetails(
          appVersion: '0.1.0',
          platform: 'linux test',
          network: 'Mainnet',
          node: 'node.btlabs.uk',
          relay: 'epicbox.stackwallet.com',
          sync: 'test run',
        ),
        log: 'INFO dart.test: a line\nWARN dart.test: to 203.0.113.7:3413\n',
        at: DateTime.now(),
        ui: 'desktop',
      );
      return const PlatformFeedbackOutlet().post(feedbackUrlProviderDefault, report);
    }, _RealHttp());
    // ignore: avoid_print
    print('support report id: $id');
    expect(id, isNotEmpty);
  }, skip: Platform.environment['WFE_SUPPORT_LIVE'] != '1' ? 'set WFE_SUPPORT_LIVE=1: posts a real report to the intake' : false);
}

final feedbackUrlProviderDefault = parseFeedbackUrl(Platform.environment['WFE_SUPPORT_LIVE_URL'] ?? 'https://support.btlabs.uk/v1/report')!;

class _RealHttp extends HttpOverrides {}
