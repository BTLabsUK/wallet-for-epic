/// The desktop interface (design run): every screen on mock data, no wallet core.
/// `flutter run -d linux -t lib/main_desktop.dart`; start on any page with
/// `--dart-define=WFE_DESK_START=<route>` (names in `src/desktop/app/routes.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/desktop/app/desk_app.dart';

void main() {
  runApp(const ProviderScope(child: DeskApp()));
}
