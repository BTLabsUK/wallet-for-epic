// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// Placeholder; the settings redesign fills it.
class SettingsDonateScreen extends ConsumerWidget {
  const SettingsDonateScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SettingsFrame(route: DeskRoute.settingsDonate, child: SizedBox.shrink());
}
