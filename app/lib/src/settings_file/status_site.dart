// SPDX-License-Identifier: Apache-2.0
/// The status site's host name, for the strings that name it ("Use {site}").
library;

import 'host_settings.dart';

/// The host of `status.directory` in the settings in use.
String get statusSiteHost =>
    Uri.tryParse(hostSettings.statusDirectory)?.host ?? '';
