import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// Placeholder: replaced by the screen's owner.
class SettingsRescanScreen extends ConsumerWidget {
  const SettingsRescanScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      EPage(title: 'Settings', child: EEmpty(icon: EIcons.info, title: 'Settings'));
}
