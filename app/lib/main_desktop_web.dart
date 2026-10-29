// SPDX-License-Identifier: Apache-2.0
/// The desktop interface in a browser, on canned data only: a clickable prototype that needs no
/// wallet core. Build with `tool/build_desktop_web.sh`.
library;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/desktop/app/desk_app.dart';
import 'src/settings_file/host_settings.dart';
import 'src/settings_file/settings_providers.dart' show shippedSettingsAsset;
import 'src/web/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The canned data shows the shipped servers; nothing reads or writes a settings file.
  final shipped = HostSettings.fromText(await rootBundle.loadString(shippedSettingsAsset));
  hostSettings = shipped;
  shippedHostSettings = shipped;
  runApp(const ProviderScope(child: DeskApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
}
