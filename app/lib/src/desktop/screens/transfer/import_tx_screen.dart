import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// Placeholder: replaced by the screen's owner.
class ImportTxScreen extends ConsumerWidget {
  const ImportTxScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      EPage(title: 'Import file', child: EEmpty(icon: EIcons.info, title: 'Import file'));
}
