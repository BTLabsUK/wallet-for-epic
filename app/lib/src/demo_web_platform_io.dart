// SPDX-License-Identifier: Apache-2.0
/// `demo_web_platform.dart` off the web: the demo runs only in the browser.
library;

import 'package:flutter_riverpod/misc.dart' show Override;

import 'demo_web.dart';

DemoHttp browserDemoHttp() =>
    throw UnsupportedError('the web demo runs only in a browser');

/// Nothing to change off the web.
List<Override> webDemoOverrides() => const [];

/// No demo settings off the web.
Future<String?> demoSettingsText() async => null;
