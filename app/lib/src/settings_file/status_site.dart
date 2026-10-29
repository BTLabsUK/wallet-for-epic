// SPDX-License-Identifier: Apache-2.0
/// The status site's host name, for the strings that name it ("Use {site}").
library;

import 'host_settings.dart';

/// The host of `status.directory` in the settings in use; empty when none is configured.
String get statusSiteHost => Uri.tryParse(hostSettings.statusDirectory ?? '')?.host ?? '';

/// Whether `app-config.toml` names a status site: without one, its switch and lines are hidden.
bool get statusSiteConfigured => hostSettings.statusDirectory != null;
