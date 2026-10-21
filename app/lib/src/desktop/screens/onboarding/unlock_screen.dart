import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// Placeholder: replaced by the screen's owner.
class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      EPage(title: 'Unlock', child: EEmpty(icon: EIcons.info, title: 'Unlock'));
}
