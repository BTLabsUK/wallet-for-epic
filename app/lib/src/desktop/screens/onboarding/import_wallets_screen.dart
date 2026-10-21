import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// Placeholder: replaced by the screen's owner.
class ImportWalletsScreen extends ConsumerWidget {
  const ImportWalletsScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      EPage(title: 'Import wallets', child: EEmpty(icon: EIcons.info, title: 'Import wallets'));
}
