/// The desktop interface in a browser, on canned data only: a clickable prototype that needs no
/// wallet core. Build with `tool/build_desktop_web.sh`.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/desktop/app/desk_app.dart';
import 'src/web/splash.dart';

void main() {
  runApp(const ProviderScope(child: DeskApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) => removeSplash());
}
