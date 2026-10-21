import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// Placeholder: replaced by the screen's owner.
class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      EPage(title: 'Receive', child: EEmpty(icon: EIcons.info, title: 'Receive'));
}
