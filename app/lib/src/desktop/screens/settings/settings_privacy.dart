import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

/// Settings › Node › Privacy: whether status.btlabs.uk is asked ([DeskSettings.useStatusSite]).
/// Off, the node and Epicbox lists are the built-in ones with health from the servers
/// themselves. Applies at once.
class PrivacyGroup extends ConsumerWidget {
  const PrivacyGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(deskProvider.select((s) => s.settings));
    return ESetGroup(
      title: 'Privacy',
      rows: [
        ESetRow(
          title: 'Use status.btlabs.uk',
          text: 'Server health and node lists. Off: only the servers themselves are asked.',
          control: ESwitch(
            value: s.useStatusSite,
            semanticLabel: 'Use status.btlabs.uk',
            onChanged: (v) => ref.read(deskProvider.notifier).saveSettings(s.copyWith(useStatusSite: v)),
          ),
        ),
      ],
    );
  }
}
