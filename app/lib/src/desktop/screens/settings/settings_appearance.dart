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
            hint: 'System follows the computer’s setting.',
            control: ERowControl(
              wide: true,
              child: ESegmented<ThemeChoice>(
              stretch: true,
              segments: const [
                ESegment(ThemeChoice.system, 'System', icon: EIcons.themeSystem),
                ESegment(ThemeChoice.dark, 'Dark', icon: EIcons.moon),
                ESegment(ThemeChoice.light, 'Light', icon: EIcons.sun),
              ],
              value: s.theme,
              onChanged: (v) => n.saveSettings(s.copyWith(theme: v)),
            ),
            ),
          ),
          ESetRow(
            title: 'Interface scale',
            hint: 'Text and controls, larger or smaller. Applies at once.',
            control: ERowControl(
              child: ESelect<int>(
                size: EBtnSize.sm,
                semanticLabel: 'Interface scale',
                value: s.scale,
                items: [for (final v in deskScales) ESelectItem(v, '$v%')],
                onChanged: (v) => n.saveSettings(s.copyWith(scale: v)),
              ),
            ),
          ),
          if (DeskFeatures.languages)
          ESetRow(
            title: 'Language',
            hint: 'Applies at once.',
            control: ERowControl(
              child: ESelect<String>(
                size: EBtnSize.sm,
                semanticLabel: 'Language',
                value: s.language,
                // The app's own translations (lib/l10n), as on Setup.
                items: const [
                  ESelectItem('English', 'English'),
                  ESelectItem('Deutsch', 'Deutsch'),
                  ESelectItem('Polski', 'Polski'),
                  ESelectItem('Русский', 'Русский'),
                  ESelectItem('中文', '中文'),
                ],
                onChanged: (v) => n.saveSettings(s.copyWith(language: v)),
              ),
            ),
          ),
          ESetRow(
            title: 'Hide amounts',
            hint: 'Shows dots in place of balances and amounts.',
            control: ESwitch(value: s.hideAmounts, semanticLabel: 'Hide amounts', onChanged: (v) => n.saveSettings(s.copyWith(hideAmounts: v))),
          ),
        ],
      ),
    );
  }
}
