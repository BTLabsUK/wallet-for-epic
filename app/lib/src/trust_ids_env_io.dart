// SPDX-License-Identifier: Apache-2.0
/// `trust_ids_env.dart` off the browser.
library;

import 'dart:io';

/// Set by whoever drives the Linux app through AT-SPI (WFE_TRUST_IDS=1), nowhere else.
final bool trustIdsEnv = Platform.isLinux && Platform.environment['WFE_TRUST_IDS'] == '1';
