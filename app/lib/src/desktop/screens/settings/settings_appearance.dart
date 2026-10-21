import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

class SettingsAppearanceScreen extends ConsumerWidget {
  const SettingsAppearanceScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(deskProvider.select((s) => s.settings));
    final n = ref.read(deskProvider.notifier);
    return SettingsFrame(
      route: DeskRoute.settingsAppearance,
      child: ESetGroup(
        title: 'Appearance',
        rows: [
          ESetRow(
            title: 'Theme',
            text: 'System follows the computer setting.',
            control: ESegmented<ThemeChoice>(
              segments: const [
                ESegment(ThemeChoice.dark, 'Dark', icon: EIcons.moon),
                ESegment(ThemeChoice.light, 'Light', icon: EIcons.sun),
                ESegment(ThemeChoice.system, 'System', icon: EIcons.themeSystem),
              ],
              value: s.theme,
              onChanged: (v) => n.saveSettings(s.copyWith(theme: v)),
            ),
          ),
          ESetRow(
            title: 'Language',
            text: 'Applies at once.',
            control: SizedBox(
              width: 200,
              child: ESelect<String>(
                semanticLabel: 'Language',
                value: s.language,
                items: const [
                  ESelectItem('English', 'English'),
                  ESelectItem('Deutsch', 'Deutsch'),
                  ESelectItem('Polski', 'Polski'),
                  ESelectItem('Čeština', 'Čeština'),
                ],
                onChanged: (v) => n.saveSettings(s.copyWith(language: v)),
              ),
            ),
          ),
          ESetRow(
            title: 'Hide amounts',
            text: 'Blurs balances and amounts until pointed at.',
            control: ESwitch(value: s.hideAmounts, semanticLabel: 'Hide amounts', onChanged: (v) => n.saveSettings(s.copyWith(hideAmounts: v))),
          ),
          ESetRow(
            title: 'Tour',
            text: 'A short walk through the main screens.',
            control: EButton(label: 'Show the tour again', size: EBtnSize.sm, icon: EIcons.restart, onPressed: () => showEToast(context, 'Tour starts on Overview')),
          ),
        ],
      ),
    );
  }
}
