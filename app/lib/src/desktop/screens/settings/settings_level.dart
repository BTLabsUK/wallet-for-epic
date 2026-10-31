// SPDX-License-Identifier: Apache-2.0
/// Settings › Advanced › Change level: the depth dial with its preview, Undercover, Save.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import 'settings_frame.dart';

class SettingsLevelScreen extends ConsumerWidget {
  const SettingsLevelScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const SettingsFrame(route: DeskRoute.settingsLevel, child: SizedBox.shrink());
}
